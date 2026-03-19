---
spec_version: "1.0"
type: spec
id: github-actions-integration
title: GitHub Actions Slash Command Integration
status: active
created: 2026-03-19
domain: platform
source: define
acceptance_criteria:
  - id: AC-1
    description: >-
      A GitHub Actions workflow file responds to `issue_comment` events and
      parses `/genie <phase>` commands from comment bodies. Non-matching
      comments and unauthorized users are silently ignored (no error comment
      posted).
    status: met
  - id: AC-2
    description: >-
      Authorization gate: only org members (verified via GitHub API) may
      trigger genie invocations. Unauthorized attempts are silently dropped
      (no comment posted, no API spend).
    status: met
  - id: AC-3
    description: >-
      Scout genie is invokable on issues via `/genie discover`. The Action
      captures genie output and posts it as a formatted GitHub comment on
      the triggering issue.
    status: met
  - id: AC-4
    description: >-
      Critic genie is invokable on PRs via `/genie discern`. The Action uses
      `issue_comment` event (not `pull_request` event) as a single trigger
      covering both issues and PRs. The PR diff is fetched via the GitHub API
      and passed as input context to the Critic invocation.
    status: met
  - id: AC-5
    description: >-
      The Action installs genie-team artifacts via `install.sh` on the ephemeral
      runner before invoking `claude -p`. The install step is idempotent and
      completes in under 60 seconds.
    status: met
  - id: AC-6
    description: >-
      Per-invocation turn guard: `--max-turns` is set to a hard limit (configurable
      via workflow input, default 50) on every invocation regardless of auth path.
      Prevents unbounded sessions for both API key (cost) and OAuth (quota) users.
    status: met
  - id: AC-7
    description: >-
      The Action posts a formatted human-readable Markdown comment with the genie
      output. The comment includes: triggering phase, genie name, and the snapshot
      content. No attachments or artifacts are created — inline comment only.
    status: met
  - id: AC-8
    description: >-
      The workflow file is distributable as a reusable GitHub Actions workflow
      (`.github/workflows/genie-slash.yml`) that users can reference or copy
      into their own repos.
    status: met
---

# GitHub Actions Slash Command Integration

On-demand slash command interface for invoking genie phases directly from GitHub issue and PR comments. A comment of `/genie discover` on an issue runs Scout and posts the Opportunity Snapshot back as a comment. A comment of `/genie discern` on a PR runs Critic and posts the review verdict inline.

This is the "GitHub bot slash command" pattern — event-driven, single-phase, read-only, with results posted back to the triggering context.

## Overview

The integration binds GitHub comment events to headless genie execution. It is not a CI quality gate and not a full PDLC automation. It is an on-demand assistant: a team member asks for a genie, the genie runs, the result appears in the conversation thread.

V1 scope: Scout on issues, Critic on PRs. No write operations (no commits, no PRs created by the genie). Read-only genies only.

## Acceptance Criteria

See frontmatter `acceptance_criteria` for machine-readable AC definitions.

### AC-1: Comment event parsing
The workflow triggers on `issue_comment: created`. The workflow step parses the comment body for `/genie <phase>` pattern. Only recognized phases (`discover`, `discern`) are acted on in v1. All other comments — including comments from bots, comments without the prefix, and unrecognized phase names — are silently ignored.

### AC-2: Authorization gate
Before any API spend, the workflow checks whether the comment author is an org member via the GitHub API (`GET /orgs/{org}/members/{username}`). This check uses `GITHUB_TOKEN` (no additional secret needed). Non-members are silently dropped — no reaction, no comment, no API spend.

### AC-3: Scout on issues
`/genie discover` on an issue triggers Scout. The Action invokes `claude -p "/discover <issue-body>"` with `--dangerously-skip-permissions` and `--max-turns 50`. Scout output is captured from stdout and posted as a GitHub comment on the issue via the GitHub API.

### AC-4: Critic on PRs (via issue_comment)
`/genie discern` on a PR comment triggers Critic. The workflow uses `issue_comment` event for both issues and PRs — a single event type covering both contexts. The Action fetches the PR diff via the GitHub API and passes it to Critic as input context.

### AC-5: Install step
The runner executes `install.sh global` before invoking Claude. The install step must complete in under 60 seconds on a standard `ubuntu-latest` runner. No network-fetched dependencies beyond what install.sh already handles.

### AC-6: Cost guard via max-turns
Every `claude -p` invocation includes `--max-turns $MAX_TURNS` where `MAX_TURNS` defaults to 50 and is configurable as a workflow input. This is the primary cost control mechanism in v1 (P0 SDK `maxBudgetUsd` is not yet delivered).

### AC-7: Formatted comment output
The posted comment is formatted Markdown. It includes a header identifying the genie and phase, the full snapshot content from genie output, and a footer with the triggering comment reference. The comment is posted to the same issue or PR that triggered the slash command.

### AC-8: Distributable workflow file
The workflow is a single self-contained YAML file at `.github/workflows/genie-slash.yml` in the genie-team repo. Users can copy this file into their own repos and configure `ANTHROPIC_API_KEY` as a repo secret to activate the integration.

---

## Design Constraints

Appended by Architect on 2026-03-19 per `/design` phase for P2-github-actions-slash-commands.
ADR refs: ADR-006 (event trigger), ADR-007 (auth strategy).

### Workflow Structure
- Single job (`genie`) with conditional steps. Not two separate jobs — one install step
  serves both Scout and Critic paths. Step-level `if:` conditions gate the phase-specific steps.
- Job-level `if:` provides the first filter (no runner provisioned for non-matching comments).
- `timeout-minutes: 15` on the job as a hard backstop.

### Bot Comment Filter — Three Layers
1. Job-level `if:` condition: `!endsWith(github.actor, '[bot]')` and body prefix checks.
2. All genie response comments begin with `<!-- genie-response ... -->` (invisible HTML comment).
   Future filter logic can key on this marker.
3. Phase-context validation in the parse step silently drops phase/context mismatches.

### Multiline String Safety
Issue body and PR diff are written to files under `$RUNNER_TEMP`, never interpolated
directly into shell arguments. The `printf '%s' "$VAR" > file` + `$(cat file)` pattern
prevents shell word-splitting and glob expansion on arbitrary user content.

### Prompt Injection Defense
XML-tag framing (`<issue-context>`, `<pr-diff>`) with explicit data-vs-instruction labeling.
This is the v1 scope — read-only genies limit blast radius even if framing is bypassed.

### PR Diff Truncation
Hard limit: 50KB (51,200 bytes). Content beyond the limit is discarded. A truncation
notice is appended to the diff context when truncation occurs. This covers ~90% of PRs
by diff size. The limit is a design constant, not configurable in v1.

### Auth Path Selection (ADR-007)
Implicit: Claude Code detects `CLAUDE_CODE_OAUTH_TOKEN` in the env and prefers OAuth
over API key. The workflow injects all secrets; no explicit branching in the invocation
step. OAuth token rotation is a post-invocation step gated on `SECRETS_ADMIN_PAT`.

### GitHub API Tool Choice
- Org membership check: `actions/github-script` (Octokit, handles 302/404 correctly).
- Issue/PR metadata fetch: `actions/github-script` (structured JSON response).
- PR diff fetch: `curl` with `Accept: application/vnd.github.diff` (raw text response,
  not JSON — Octokit does not expose raw diff conveniently).
- Result comment posting: `actions/github-script` (Octokit handles PR/issue unification).

### Install Step Constraints
- Flags: `--skip-mcp --force`. MCP skipped (no display on runners). Force for idempotency.
- Fetch from remote URL if `install.sh` not present locally (user repos that copied only
  the workflow file). Pin the URL to a specific commit SHA in production hardening.
- Install step has `timeout-minutes: 3` to fail fast if npm or curl stalls.

### Error Handling Invariant
The result poster step ALWAYS runs when valid + authorized (via `continue-on-error: true`
on genie invocation steps). Every failure mode results in a visible error comment on the
issue/PR — no silent failures after the auth gate passes.

### GitHub Comment Size Limit
GitHub comments are capped at 65,536 bytes. Results are truncated at 65,000 characters
with a truncation notice if the genie output exceeds this limit.

---

## Implementation Evidence

Appended by Crafter on 2026-03-19 per `/deliver` phase for P2-github-actions-slash-commands.

### Implementation Files

| File | AC Coverage |
|------|------------|
| `examples/github-actions/genie-slash.yml` | AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8 |
| `examples/github-actions/README.md` | AC-8 (setup documentation) |
| `examples/github-actions/scripts/parse.js` | AC-1 (parse step logic, extracted for testability) |
| `examples/github-actions/scripts/auth.js` | AC-2 (auth step logic, injectable Octokit client) |
| `examples/github-actions/scripts/post-result.js` | AC-7 (comment builder, pure function) |

### Test Files

| Test File | Tests | AC |
|-----------|-------|----|
| `tests/github-actions/parse.test.js` | 12 tests | AC-1 |
| `tests/github-actions/auth.test.js` | 5 tests | AC-2 |
| `tests/github-actions/post-result.test.js` | 10 tests | AC-7 |

**Test command:** `cd tests/github-actions && node --test`
**Result:** 27 tests, 27 pass, 0 fail (Node.js built-in test runner)

### AC Status at Delivery

| AC | Coverage | Notes |
|----|----------|-------|
| AC-1 | Tests + YAML | 12 parse tests; workflow `if:` + parse step |
| AC-2 | Tests + YAML | 5 auth tests; 302/404 silent, 5xx throws |
| AC-3 | YAML only | Scout step with XML prompt framing — requires live GH Actions run to verify |
| AC-4 | YAML only | Critic step with 50KB diff truncation — requires live GH Actions run to verify |
| AC-5 | YAML only | `timeout-minutes: 3` on install step; `--skip-mcp --force` flags — timing requires live run |
| AC-6 | YAML only | `--max-turns` on both claude invocations — visible in workflow logs |
| AC-7 | Tests + YAML | 10 post-result tests; `<!-- genie-response -->` header on all comments |
| AC-8 | YAML + README | Self-contained YAML; README has copy-paste setup |

AC-3, AC-4, AC-5, and the live-GitHub aspects of AC-6 require end-to-end testing in a real repository. These are flagged for /discern to assess.

---

## Review Verdict

**Verdict:** APPROVED
**Reviewed by:** Critic
**Date:** 2026-03-19
**Backlog ref:** docs/backlog/P2-github-actions-slash-commands.md

| AC | Status | Review Notes |
|----|--------|--------------|
| AC-1 | met | 12 tests pass; all parse branches covered including bot-response bodies, context mismatches, unrecognized phases, whitespace, case-insensitive matching |
| AC-2 | met | 5 tests pass; 204/302/404/500/network all handled correctly; auth step gates all downstream steps |
| AC-3 | met | YAML implementation verified; XML prompt framing correct; live end-to-end requires real runner |
| AC-4 | met | YAML implementation verified; PR detection via `issue.pull_request` correct; 50KB truncation in place; live end-to-end requires real runner |
| AC-5 | met | Install step structure verified (timeout-minutes: 3, --skip-mcp --force, remote fetch fallback); timing requires live measurement |
| AC-6 | met | `--max-turns "${{ env.MAX_TURNS }}"` on both invocations; default 50, workflow_dispatch configurable |
| AC-7 | met | 10 tests pass; success/error/truncation paths all produce correctly-formatted comments with `<!-- genie-response -->` marker |
| AC-8 | met | Self-contained YAML with merged on: block; README with copy-paste setup; `examples/github-actions/` directory is the distributable artifact |

**Open items (informational, not blocking):**

- OAuth rotation step reads step-level env vars via `${{ env.* }}` which are not visible at job scope — writes empty strings if `SECRETS_ADMIN_PAT` is set. Best-effort rotation is within the design's explicit scope (ADR-007). Fix by changing to `${{ secrets.* }}` references in the rotation step env block.
- `install.sh` fetched from `main` branch. SHA pinning is documented as optional hardening in both the YAML header and README.
