---
adr_version: "1.0"
type: adr
id: ADR-006
title: "Use issue_comment Event for GitHub Actions Genie Slash Commands"
status: accepted
created: 2026-03-19
revised: 2026-03-19
deciders: [shaper, navigator, architect]
tags: [architecture, github-actions, security, integration]
---

# ADR-006: Use issue_comment Event for GitHub Actions Genie Slash Commands

## Context

The GitHub Actions slash command integration must choose an event type to trigger
genie execution from both issue comments and PR comments. Two viable options exist:

**Option A: `issue_comment` event**
- Fires on all comments on both issues AND pull requests (PRs are issues in GitHub's model)
- Single event type covers both contexts — one workflow handles `/genie discover` on
  issues and `/genie discern` on PRs
- Always has access to repository secrets for same-repo PRs and issues
- Requires detecting PR vs issue context via `github.event.issue.pull_request`
  and fetching PR diff separately via the GitHub API
- Standard pattern for slash-command bots (e.g., `/lgtm`, Prow commands, ClowderBot)

**Option B: Two separate events (`issue_comment` for issues + `pull_request` for PRs)**
- `pull_request` event fires on PR open/sync/review; diff is in the payload natively
- Would require two separate workflow files or a complex merged trigger
- Adds workflow maintenance surface for what is functionally one feature
- For same-repo PRs (forks are out of scope), `pull_request` event has full secret access

**Scope note:** Forked repos are explicitly out of scope for v1. The fork secret
restriction that historically made `pull_request` event infeasible for open-source
repos does not apply here.

## Decision

Use `issue_comment` event for all genie slash command triggers.

The workflow detects context from `github.event.issue.pull_request` to determine
whether to run in issue mode (Scout) or PR mode (Critic). PR diff and metadata are
fetched via the GitHub API using `GITHUB_TOKEN` within the workflow step.

Rationale: a single event type handling both issues and PRs is simpler to distribute
and maintain than two separate workflow triggers. The extra API call to fetch a PR diff
is a minor cost. This is the accepted industry pattern for slash-command-style bots on GitHub.

## Consequences

### Positive
- `ANTHROPIC_API_KEY` is always accessible — no secret restriction from fork PRs
- Single event type handles both issues and PRs — one workflow, two modes
- Industry-standard pattern — well-documented, low implementation surprise
- The authorization gate (org membership check) is straightforward: comment author
  is always the event actor, and the org API is accessible via `GITHUB_TOKEN`

### Negative
- PR diff is not in the event payload — must be fetched separately via
  `GET /repos/{owner}/{repo}/pulls/{pull_number}` with `Accept: application/vnd.github.diff`
- This adds one extra API call per Critic invocation
- The event includes all comments (not just slash commands) — the workflow must parse
  and filter early to avoid unnecessary execution
- Comments from bots (including the genie response comment itself) must be explicitly
  filtered to prevent feedback loops

### Neutral
- The `issue_comment` event does not fire on PR review thread comments
  (inline code comments) — only top-level PR comments. This is acceptable for v1.
- `GITHUB_TOKEN` permissions must include `pull-requests: write` and `issues: write`
  for posting result comments, and `members: read` for the org membership check

## Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| Two separate events: `issue_comment` (issues) + `pull_request` (PRs) | Natural fit for PR context; diff in payload for PR path | Two workflow triggers or complex merged file; higher maintenance surface | Single event type is simpler to distribute; one workflow file is the v1 distribution model |
| `workflow_dispatch` (manual trigger) | Always has secret access; explicit invocation | No comment-based UX; requires navigating Actions UI; defeats the slash command purpose | Wrong UX model |
| Repository dispatch + webhook bridge | Can forward any event with secret context | Requires additional infrastructure (webhook handler); out of scope for v1 | Over-engineered for v1 |

## When to Reconsider

- If forked repo support is added in a future version — fork PRs cannot access secrets
  via `pull_request` event, which would require `pull_request_target` (different security
  tradeoffs) or keeping `issue_comment` as-is
- If the integration is extended to respond to PR review thread comments (inline),
  which would require `pull_request_review_comment` event in addition to `issue_comment`
- If v2 adds write operations (commit, push) triggered from PRs — would require
  explicit security review of event type and permission model

## Related Decisions

- ADR-001: Thin Orchestrator (the `claude -p` spawning pattern used by this integration)
- ADR-005: SDK-Integrated Orchestrator (future migration path; v2 would use `genies-core`)
- P2-github-actions-slash-commands: Implementation backlog item
