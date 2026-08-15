---
title: Opportunity Snapshot — GitHub Actions Integration
date: 2026-03-19
topic: building a github action that allows us to leverage genie-team directly from github actions
reasoning_mode: deep
status: draft
updated: 2026-03-19
---

# Opportunity Snapshot — GitHub Actions Integration

## Discovery Question

**Original:** Build a GitHub Action that allows us to leverage genie-team directly
from GitHub Actions — specifically to invoke individual genies/phases from issues
and PRs.

**Reframed:** How can a team member invoke a specific genie phase on-demand from
a GitHub issue or PR comment, receive results inline, and do so safely without
exposing billing, secrets, or write permissions to unauthorized actors?

**Clarification (2026-03-19):** The use case is not full PDLC automation triggered
by CI events. It is an **on-demand slash-command interface**: a user comments
`/genie discover` on an issue or `/genie discern` on a PR, a GitHub Action runs
the requested genie phase in a headless Claude session, and posts the result back
as a comment. This is the "GitHub bot slash command" pattern used broadly in the
GitHub ecosystem.

---

## Context Summary

**Project state:** Genie-team is a prompt engineering framework — commands, agents,
skills, rules — that extends Claude Code with structured product workflows. It
distributes via `install.sh` and is heading toward npm distribution (P2-plugin-
distribution). The core orchestrator (`scripts/genies`) is mid-migration from shell
to TypeScript via the Claude Agent SDK (P0-typescript-sdk-migration, status:
designed, not yet delivered).

**Relevant ADRs:**
- ADR-001: Thin Orchestrator (superseded) — established `claude -p` spawning as the
  external integration surface. Still describes the stable CLI contract.
- ADR-005: SDK-Integrated Orchestrator (accepted) — migrates to TypeScript, adds
  programmatic governance (budget caps, hooks, session continuity). The
  `genies-core` binary is the emerging distribution target.

**Related backlog:**
- P0-typescript-sdk-migration (designed): SDK migration providing auth control,
  budget enforcement, model routing — prerequisites for safe CI execution.
- P2-plugin-distribution (shaped): npm distribution, Claude Code plugin marketplace
  — the natural install mechanism for a GitHub Action.

**Prior discovery:**
- 2026-02-27: Autonomous loops discovery found that headless execution works but
  needs cost instrumentation and per-phase governance.
- 2026-03-17: PDLC skill boundary bug discovery confirmed that headless execution
  has a known failure mode — skills contain lifecycle advancement guidance that
  executes in `-p` mode, corrupting state when used with `--through` ranges.

**Spec coverage relevant to this topic:**
- `docs/specs/platform/sdk-orchestrator.md` — 9 ACs covering runPhase(), auth
  control, budget enforcement, SDK hooks. All pending.
- `docs/specs/platform/installation-system.md` — covers install.sh; pending update
  for npm distribution.

---

## Observed Behaviors / Signals

### What users do today to run genie-team in CI-like contexts

1. **Manual headless invocation.** Users run `claude -p "/deliver docs/backlog/P1.md"
   --output-format json` from a terminal or cron job. This is the documented
   "thin orchestrator" pattern (ADR-001). No GitHub-native event binding exists.

2. **`genies` script as the entry point.** `scripts/genies` is the wrapper that
   mediates headless execution — `genies run`, `genies daemon`, `genies --parallel`.
   This is the CLI contract that ADR-005 preserves. Any GH Action would invoke this.

3. **`--dangerously-skip-permissions` is required.** Claude Code in headless mode
   prompts for tool-use approvals unless `--dangerously-skip-permissions` is set.
   All CI invocations require this flag — there is no human present to approve.
   This is currently a blunt instrument with no per-tool granularity.

4. **Auth via API key only.** GitHub Actions secrets provide `ANTHROPIC_API_KEY` as
   the auth mechanism. OAuth (subscription billing with capped spending) requires
   an interactive login that CI cannot perform. This means CI runs are always
   API-key mode = uncapped billing.

5. **No install path for CI.** `install.sh` copies files to `~/.claude/` — a
   global path that doesn't survive ephemeral CI runners. A GH Action would need
   to re-install on every run or use a container with pre-installed artifacts.
   npm distribution (P2) would change this, but P2 is not yet built.

6. **The PDLC boundary bug exists in headless mode.** `/discern` tells the Critic
   to call `/done` as routing guidance. In interactive mode this is a suggestion.
   In `-p` mode Claude follows it, archiving the backlog item before `detect_verdict`
   can read its frontmatter. This bug is confirmed, unresolved, and would manifest
   in any CI automation that runs `discern`.

---

## Pain Points / Friction Areas

### F1: No event-binding between GitHub events and genie workflows

There is no mechanism today to say "when a PR is opened against `main`, run Scout
on the diff" or "when a backlog issue is labeled `genie-ready`, run the full PDLC."
All execution is manually initiated. The only way to automate is a cron-based daemon
or a custom shell script — neither of which is GitHub-native.

### F2: CI is untrusted but genie execution requires broad trust

`--dangerously-skip-permissions` disables all tool-use approval gates. In a CI
environment this means the genie can read/write/execute anything in the workspace
with no human checkpoint. There is no per-phase or per-tool permission scope. For
a GH Action that responds to external PRs (from forks, community contributors), this
is a significant security surface.

### F3: Billing is uncapped in CI

Every CI run via API key is uncapped billing. The P0 SDK migration adds
`maxBudgetUsd` per-session budget enforcement — but P0 is not yet delivered. Today,
a misconfigured GH Action workflow could spawn multiple genie sessions per PR at
$5-15 each with no limit.

### F4: Installation on ephemeral CI runners is fragile

`install.sh` is a bash script that copies markdown files to `~/.claude/`. This must
run at the start of every CI job. It has no version pinning — whatever is in the git
checkout is what gets installed, which may not match the user's installed version.
npm (`npm install -g genie-team`) would be the right solution but P2 hasn't shipped yet.

### F5: The PDLC skill boundary bug makes end-to-end CI automation risky

Running `genies run --through discern` in CI today means `/discern` may internally
call `/done`, archive the backlog item, and leave the runner unable to find the item
for verdict detection. The 2026-03-17 discovery confirmed this failure mode. Any CI
automation that runs more than a single phase is exposed to this bug.

### F6: No session continuity across CI jobs

GitHub Actions jobs are ephemeral. Session IDs from one job cannot be passed to a
subsequent job to resume context. The P0 SDK migration adds session resume via the
`resume` parameter, but even then, session IDs would need to be passed via job
outputs or artifacts between jobs.

---

## JTBD / User Moments

**Primary Job:**
"When a PR is opened or a backlog item is labeled `genie-ready` in GitHub, a team
wants genie workflows to run automatically on that event so they can receive
AI-assisted review, discovery output, or delivery without manually opening Claude."

**Secondary Jobs:**

- **CI quality gate job:** "When code is pushed to a feature branch, a developer
  wants the Critic genie to review the diff so they can catch quality issues before
  the PR is approved without a separate workflow."

- **Discovery on issue job:** "When a GitHub issue is created with a structured
  problem description, a team lead wants Scout to run automatically so they can
  have an Opportunity Snapshot ready before the next planning session."

- **Delivery automation job:** "When a backlog item reaches `designed` status, an
  operator wants genies to automatically run delivery and create a PR so they can
  accelerate throughput without babysitting the queue."

- **Cost-aware CI job:** "When genie workflows run in CI, a team lead wants
  per-run cost reporting so they can understand what the automation is spending
  and set limits before a spike shows up on the bill."

---

## Opportunity Areas (Unshaped)

**1. The trust and permission surface in CI is poorly defined.**
CI environments are not equivalent to interactive sessions. The current
`--dangerously-skip-permissions` flag is all-or-nothing. There is no mechanism to
scope tool permissions per phase or per genie type. For public repo PRs (fork-sourced
events), this is a significant attack surface. The problem is not "how do we enable
CI" but "what trust boundary does a genie need in order to run safely without a human
present?"

**2. Billing governance is a prerequisite for CI, not a follow-on.**
Uncapped API key billing in CI is a risk that makes adoption dangerous, not slow.
Teams cannot safely enable automated genie invocations on every PR event without
per-run cost limits. The P0 SDK migration provides `maxBudgetUsd` — but P0 is not
yet delivered. The question is whether GH Actions integration should be sequenced
after P0, or whether a simpler cost guard (e.g., hard-coded max-turn limit) is
sufficient to unblock early adoption.

**3. Installation on ephemeral runners has no good solution today.**
A GH Action needs a reliable, version-pinned way to install genie-team in a CI
environment. `install.sh` is fragile, unversioned, and slow. `npm install` is the
right answer but requires P2-plugin-distribution to ship first. The opportunity is
not "how do we document install.sh for CI" but "what is the minimum viable
distribution mechanism that makes GH Actions adoption safe and reproducible?"

**4. The PDLC skill boundary bug is a blocking defect for multi-phase CI runs.**
Any CI automation that runs more than a single isolated genie phase (e.g., `discern`)
is exposed to the skill boundary bug where lifecycle advancement happens inside the
phase. A GH Action that runs `--through discern` would silently archive backlog items
mid-execution. The question is whether the skill boundary fix needs to ship before
GH Actions integration is designed.

**5. GitHub event semantics and genie workflow semantics don't naturally align.**
A GitHub Action is triggered by an event (PR opened, issue labeled, push). Genie
workflows are triggered by backlog items (a structured document with `status:
shaped`). The mapping between GitHub events and genie workflow inputs is not defined.
A PR opened event has a diff, a title, a description — not a backlog item. The
opportunity is to understand what kind of event-to-input translation is needed,
and whether it's a one-time mapping or a recurring design problem.

---

## Assumption Map

| Assumption | Type | Evidence | Impact if Wrong | Risk Priority |
|------------|------|----------|-----------------|---------------|
| Teams want genie workflows triggered by GitHub events, not just run manually | Value | Weak — stated in the topic, no user feedback or usage data exists | If wrong, the GH Action is a distribution artifact nobody uses — effort wasted | 1 |
| `--dangerously-skip-permissions` is acceptable for CI (security risk is managed) | Feasibility | Weak — no security analysis done; public repo fork events could exploit broad tool permissions | If wrong, the GH Action is a security incident waiting to happen | 1 |
| API key auth (uncapped billing) is acceptable for CI | Viability | Weak — no cost baseline for per-PR genie runs; estimated $5-15 per discovery topic at scale | If wrong, early adopters get surprise bills and churn | 2 |
| The PDLC skill boundary bug won't affect the targeted GH Action use cases | Feasibility | Weak — depends entirely on which phases the GH Action runs; no phase scope decision made | If wrong, CI runs silently corrupt backlog state and report false errors | 1 |
| P2 npm distribution is the right install mechanism (or install.sh is acceptable as stop-gap) | Feasibility | Moderate — P2 is shaped and rationale is strong; P2 not yet built | If wrong or P2 delayed, the GH Action install step is fragile and unversioned | 2 |
| Session continuity across CI jobs is not needed for initial value | Value | Missing — depends on which phases the GH Action runs; not yet defined | If wrong, the GH Action cannot deliver intended value without SDK session resume (P0 dep) | 2 |
| Teams will accept genie-generated PRs / artifacts from CI as trustworthy | Value | Missing — no user research; teams may distrust AI-generated code changes without human review gates | If wrong, the GH Action produces outputs that are rejected in practice | 3 |

---

## Evidence Gaps

### Critical (blocks design)

1. **What specific GitHub event → genie workflow mappings are wanted?**
   The topic doesn't specify what triggers what. PR opened → Critic review? Issue
   created → Scout? Backlog item merged → Crafter? Without this, there is no
   well-defined scope to design against.

2. **What is the acceptable security model for CI execution?**
   Is this for private repos only? Does it respond to fork PRs? Are write operations
   (commit, push) in scope? `--dangerously-skip-permissions` in a public repo CI is
   a security decision that needs an explicit answer before design.

3. **What phases are in scope for CI?**
   Single-phase read-only (Scout, Critic on a diff) vs. multi-phase write (Crafter
   through Discern with commit and PR). These have radically different risk,
   feasibility, and sequencing dependencies.

### Moderate (affects confidence in routing)

4. **Is P0 SDK migration a prerequisite?**
   P0 provides `maxBudgetUsd` (CI safety), auth mode control, and session resume
   (multi-job continuity). If GH Actions needs any of these, P0 ships first. If the
   use case is single-phase read-only, P0 may not be required.

5. **Is the PDLC skill boundary bug a blocker?**
   If CI scope is read-only single phases (Scout, Critic), the boundary bug doesn't
   manifest. If it's multi-phase with `discern`, it does. The answer to gap #3
   resolves this.

6. **What does the install step look like?**
   `install.sh` in a CI step is a known pattern but brittle. `npm install -g
   genie-team` would be cleaner but requires P2. A GitHub Action Docker image would
   bundle everything but adds maintenance. The preferred install mechanism affects
   the design of the Action itself.

---

## Technical Signals

**Feasibility:** moderate — but with strong sequencing dependencies

The raw mechanics of invoking `claude -p` or `genies run` from a GH Actions step
are straightforward. The complications are:

- **Auth:** `ANTHROPIC_API_KEY` as a secret works today. OAuth is not feasible in CI.
- **Permissions:** `--dangerously-skip-permissions` is required. No scoped alternative exists today.
- **Install:** `install.sh` works in CI but is unversioned. npm is the right path but requires P2.
- **Budget:** No per-run cost cap exists until P0 Phase 2 (SDK hooks + `maxBudgetUsd`).
- **PDLC bug:** Manifest risk for multi-phase runs until the 2026-03-17 skill boundary fix ships.
- **Git operations:** GH Actions provides `GITHUB_TOKEN` for push and PR creation, but the
  genie PR creation flow uses `gh` CLI — needs `GH_TOKEN` secret and appropriate repo
  write permissions.

**Constraints:**
- GH Actions runner environments are ephemeral (`ubuntu-latest`, clean per run)
- No GUI, no interactive mode — headless only
- Environment variables are the only auth mechanism
- GitHub's fork PR security model restricts secret access on fork events (critical for public repos)

---

## Architecture Context

### ADR-005: SDK-Integrated Orchestrator (current, accepted)
The TypeScript `genies-core` binary is the emerging integration surface for external
orchestrators. GH Actions would invoke `genies-core` (once P0 ships) rather than
the shell `genies` script directly, gaining auth mode control, budget caps, and
structured output. This makes P0 a soft prerequisite for a production-ready GH Action.

### ADR-001: Thin Orchestrator (superseded but still the current state)
Today, external integrations spawn `claude -p` processes. GH Actions can use this
pattern today, without waiting for P0. The tradeoff: no budget enforcement, no
session continuity, shell fragility.

### P2-plugin-distribution (shaped, not designed)
npm is the right install mechanism for CI. `npm install -g genie-team && genies run`
is a clean CI step. But P2 hasn't shipped. Until it does, `install.sh` is the only
option.

### PDLC skill boundary bug (2026-03-17 discovery, not yet shaped)
Blocking risk for multi-phase CI runs. Needs to be shaped and fixed before GH
Actions integration can safely run `--through discern` or `--through done`.

---

## Revised Assessment (2026-03-19 clarification)

The clarified use case changes the risk profile significantly:

### What drops off the critical path

- **PDLC skill boundary bug** — was High risk for `--through` multi-phase runs.
  Single-phase on-demand invocations (`/genie discover`, `/genie discern`) do not
  use `--through` ranges. Risk drops to Low unless the invocation syntax allows
  chaining phases.

- **Session continuity across CI jobs** — irrelevant for single-phase on-demand
  invocations. Each comment trigger is a self-contained session.

- **Full PDLC event automation complexity** — the event-to-backlog-item mapping
  problem mostly disappears. Issues and PRs provide natural context; the invocation
  comment specifies the genie; Claude receives the issue/PR body as input.

### What remains on the critical path

- **Authorization model (now #1 risk):** Who is allowed to trigger genies via
  comment? Any commenter on a public repo could write `/genie deliver` and
  consume significant API budget. This needs an allowlist mechanism (org members
  only, specific users, specific labels) before any public-facing deployment.

- **Result posting:** Genies produce markdown documents. The Action needs to
  capture stdout/output from `claude -p` and post it back as a GitHub comment
  via `GITHUB_TOKEN`. This is straightforward but needs explicit design — the
  current `genies` script doesn't have a "post to GitHub" output mode.

- **Billing** — still a concern but more manageable for single phases ($1-5 per
  invocation vs $5-15 for full discovery). A max-turns limit or a hard per-run
  cost warning is sufficient at this scope. P0's `maxBudgetUsd` is nice-to-have,
  not blocking.

- **Fork PR secret restriction:** GitHub Actions cannot access secrets (`ANTHROPIC_API_KEY`)
  on pull_request events from forks. For PR slash commands, the workflow must use
  `issue_comment` event (which fires on PR comments too) rather than `pull_request`
  event. This is a known pattern with a known solution but needs explicit handling.

- **Install step** — `install.sh` on each runner still works and is the only option
  today. The single-phase scope makes per-run install more acceptable (30-second
  setup amortized over a $2-3 genie run). P2 npm distribution would improve this
  but is not blocking for an initial version.

---

## Routing Recommendation

- [ ] **Continue Discovery**
- [ ] **Needs Navigator Decision**
- [x] **Ready for Shaper**

**Rationale:**

The clarified scope — on-demand slash commands on issues and PRs, single phases,
results posted back as comments — is well-understood and buildable today. The risk
profile has shifted from "needs sequencing decisions about P0/P2" to "needs
authorization model and output format decisions," both of which are design-time
choices.

**Remaining questions to answer during shaping:**

1. **Invocation syntax:** Is it `issue_comment` event with `/genie <phase>` pattern,
   or label-triggered, or both?
2. **Authorization:** Org members only? Collaborators? A specific allowlist? This
   is the primary safety valve.
3. **Output format:** Comment the full snapshot inline? Comment a summary + attach
   the full doc as an artifact? Link to a generated PR?
4. **Write operations:** Are genies allowed to push commits/PRs from CI, or is this
   read-and-report only? (Crafter in CI would need push permissions.)
5. **Which genies/phases are in scope for v1?** Scout + Critic (read-only,
   lower risk) vs. including Crafter/Architect (write operations, higher risk).

**Recommendation:** Shape with appetite of 2 weeks. Start with Scout (on issues)
and Critic (on PRs) as the v1 scope — read-only, no push, lower billing risk,
natural fit for the event types. Crafter and full-phase invocations are v2.

Next: `/define "github actions slash command interface for genie-team"`

---

*Saved: docs/analysis/20260319_discover_github-actions-integration.md*
*Updated: 2026-03-19 — scope clarification, routing changed from "Needs Navigator Decision" to "Ready for Shaper"*
