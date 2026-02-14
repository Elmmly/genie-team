---
spec_version: "1.0"
type: shaped-work
id: GT-34
title: "Fix Autonomous /run Safety and Observability Issues from Field Test"
status: done
created: "2026-02-13"
appetite: small
priority: P1
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
tags: [workflow, autonomous, run, safety, field-test]
acceptance_criteria:
  - id: AC-1
    description: >-
      /done phase within /run creates a NEW commit for archive updates
      (status changes, current_work.md) rather than amending the delivery
      commit; no git commit --amend or git push --force in autonomous context
    status: pending
  - id: AC-2
    description: >-
      Preflight check reports gh auth status clearly and sets a
      PR_CREATION_MODE flag (auto or manual) that propagates to the commit
      phase; commit phase uses the flag to skip gh pr create and print
      manual URL without attempting and failing
    status: pending
  - id: AC-3
    description: >-
      Commit phase references session-state.md artifacts_written list to
      determine which files to stage; falls back to git diff if session
      state is unavailable; never uses git add -A or stages untracked
      files from previous sessions
    status: pending
  - id: AC-4
    description: >-
      /run command tracks and reports per-phase metrics in its completion
      summary: turn count and artifact count per phase; headless
      run-pdlc.sh already has log_phase_usage — this covers in-session /run
    status: pending
---

# Shaped Work Contract: Fix Autonomous /run Safety and Observability Issues

## Problem

The first field test of `/run` on the 2hearted project (2026-02-13) completed a
full discover-through-done lifecycle successfully ($7.39, 113 turns, APPROVED).
However, the run revealed four issues that would compound in repeated autonomous
use:

1. **Safety violation in /done:** The agent amended an already-pushed commit and
   force-pushed to include archive updates. This violates the project's own
   `autonomous-execution.md` safety rules ("NEVER amend published commits").
   In a parallel worktree scenario, this could destroy another session's work.

2. **Silent PR failure:** Preflight detected `gh auth status` failure but
   continued without propagating the state. The commit phase attempted `gh pr
   create`, failed, and fell back to printing a manual URL. In unattended mode,
   this means the final deliverable (PR) silently didn't happen — no error
   code, no clear signal to the orchestrator.

3. **Cross-session file contamination:** The commit phase had to manually
   exclude untracked files (`autonomy_evaluation.md`, `autonomy_briefing.md`)
   from a previous run. With `git add -A` this would have accidentally included
   them. The session-state.md already tracks `artifacts_written` but the commit
   phase doesn't reference it.

4. **No per-phase metrics in /run output:** The headless `run-pdlc.sh` logs
   per-phase usage via `log_phase_usage`, but the in-session `/run` command
   only shows total cost. Can't identify which phases are expensive without
   parsing the full session log.

**Evidence:** Field test logs at `2hearted/run-20260213-1658.log` (377 lines,
stream-json). Specific occurrences: 2x Edit-before-Read errors (wasted 4
turns), 2x `gh auth status` failures cascading to 6x sibling tool errors,
1x `git commit --amend` + `git push --force-with-lease` in /done phase.

## Appetite & Boundaries

- **Appetite:** Small (1-2 days) — all changes are markdown prompt edits to
  commands, not code changes
- **No-gos:**
  - Do NOT modify `run-pdlc.sh` (headless runner already handles these correctly)
  - Do NOT change the phase sequence or gate behavior
  - Do NOT add new commands or scripts
  - Do NOT modify the spec's acceptance criteria — these are prompt-level fixes
    within the existing AC-1 and AC-6 scope
- **Fixed elements:**
  - `/run` command at `commands/run.md` is the primary artifact
  - `/done` command at `commands/done.md` for archive commit behavior
  - `/commit` command at `commands/commit.md` for staging behavior
  - Session state tracking via `.claude/session-state.md` (existing hook system)

## Goals & Outcomes

Repeated autonomous `/run` executions are safe by default: no force-pushes, no
cross-session contamination, clear signals for PR creation status, and operators
can see per-phase cost without parsing raw logs.

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior

- AC-1: `/run` runs specified phase range without confirmation gates, using
  `/discern` as automated quality gate
- AC-6: Logs token usage and turn counts per phase for transparency (met via
  `run-pdlc.sh` but not in-session `/run`)

### Proposed Changes

- AC-1 (no change to spec wording): Add explicit guidance to `/run` command
  that `/done` phase MUST create a separate commit, never amend. Add explicit
  guidance that `/commit` phase MUST NOT use `--force-with-lease` or `--force`.
- AC-6 (no change to spec wording): Add per-phase metric tracking to in-session
  `/run` command's completion summary, matching the transparency already provided
  by `run-pdlc.sh`'s `log_phase_usage`.

### Additional Changes (not in spec scope)

- `/run` command preflight section: Change gh auth behavior from "warn but
  continue" to "warn, set PR_CREATION_MODE=manual, propagate to commit phase"
- `/run` command cleanup section: Reference session-state.md artifact list for
  staging decisions
- `/commit` command: Add guidance for autonomous context staging
- `/done` command: Add explicit "no amend" rule

### Rationale

Field test proved the system works end-to-end but revealed prompt gaps where the
LLM made unsafe choices (amend, force-push) and inefficient choices (blind
staging, redundant gh attempts) that aren't caught by the existing guidance.

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Adding "never amend" guidance to /done prevents the behavior | feasibility | Run /run on a test project and verify /done creates separate commit |
| PR_CREATION_MODE flag persists across phases in single session | feasibility | Test that preflight state propagates to commit phase in /run |
| Session-state.md is reliably populated by track-artifacts hook | feasibility | Verify hook fires for all Write/Edit calls during /deliver |
| Per-phase metrics don't require tool support (just text tracking) | feasibility | Verify /run can count phases and list artifacts without special tooling |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Update command prompts (run, done, commit) | Minimal change, targeted fixes, no code | Relies on LLM following guidance | **Recommended** |
| B: Add pre-commit hook to block amend+force-push | Hard gate, impossible to bypass | Over-engineering for a prompt fix; blocks legitimate amend use | Not recommended |
| C: Split /done archive into separate /archive command | Clean separation of concerns | New command, more complexity, solves only issue #1 | Not recommended |

## Routing

- [x] **Ready for design** — Changes are well-scoped prompt edits
- [ ] Needs Architect spike

**Next:** `/deliver docs/backlog/P1-run-field-test-fixes.md`

---

# Design

## Overview

Four targeted prompt edits to three command files (`commands/run.md`,
`commands/commit.md`, `commands/done.md`) that close safety and observability
gaps found in the 2hearted field test. No scripts, no code, no new files — just
stronger guidance in the prompts that drive autonomous behavior.

## Architecture

**Pattern: Prompt-level guardrails.** All four issues stem from the LLM making
reasonable-but-wrong choices where the command prompts were silent or ambiguous.
The fix is explicit guidance in the right places, following the same pattern as
the existing "Cleanup Before Commit" and "Gate Behavior" sections in `/run`.

No architectural changes. No new components. The existing session-state.md hook
system and preflight check structure are sufficient — they just need to be
wired into the command prompts.

## Component Design

### 1. `commands/run.md` — Preflight + Cleanup + Metrics (AC-2, AC-3, AC-4)

**Preflight section (existing, modify):**

Add after the `gh` row in the Required Tools table:

```markdown
### Preflight state propagation

After running preflight checks, set these session variables that later phases
reference:

| Variable | Source | Used By |
|----------|--------|---------|
| `PR_CREATION_MODE` | `gh auth status` exit code: 0 → `auto`, non-zero → `manual` | `/commit` phase |

When `PR_CREATION_MODE` is `manual`, note this in the preflight output:
> ⚠ gh not authenticated — PR creation will be manual. Branch will be pushed,
> manual PR URL printed.
```

**Cleanup Before Commit section (existing, modify):**

Replace item 2 ("Stage ALL artifacts") with artifact-aware staging:

```markdown
2. **Stage artifacts from this session** — Use the `artifacts_written` list
   from `.claude/session-state.md` (populated by the track-artifacts hook) to
   determine which files to stage. For each path in the list, run `git add`.
   Then check `git diff --name-only` for any modified tracked files not in the
   list (e.g., files modified by build tools) and stage those too.
   **Never use `git add -A` or `git add .`** — this risks staging untracked
   files from previous sessions. If session-state.md is unavailable, fall back
   to `git diff --name-only HEAD` for tracked changes only.
```

**New section: Phase Metrics (add after Cleanup Before Commit):**

```markdown
## Phase Metrics

Track metrics as each phase completes. At the end of the run, include a
summary table:

| Phase | Artifacts | Notes |
|-------|-----------|-------|
| discover | docs/analysis/... | |
| define | docs/backlog/... | |
| design | (appended to backlog) | |
| deliver | 5 files changed | 17 tests pass |
| discern | APPROVED | |
| commit | abc1234 | |
| done | 2 archived | |

This gives operators per-phase visibility without parsing raw logs.
```

### 2. `commands/commit.md` — Autonomous Staging + Safety (AC-1, AC-2, AC-3)

**Safety Rules section (existing, modify):**

Add two rules:

```markdown
- **Artifact-aware staging in /run context** — When invoked as part of `/run`,
  use the `artifacts_written` list from `.claude/session-state.md` to stage
  files. Never use `git add -A` or `git add .` in autonomous context.
- **No force push** — NEVER use `git push --force` or `--force-with-lease`.
  If a push fails, report the error; do not force.
- **Respect PR_CREATION_MODE** — If preflight set `PR_CREATION_MODE=manual`,
  skip `gh pr create` entirely. Push the branch and print the manual PR URL.
  Do not attempt `gh pr create` when gh is known to be unauthenticated.
```

### 3. `commands/done.md` — No Amend Rule (AC-1)

**Add new section "Autonomous Safety" after Error Handling:**

```markdown
## Autonomous Safety

When `/done` runs within an autonomous `/run` lifecycle:

- **NEVER amend a previous commit.** Archive updates (status changes,
  `current_work.md` updates, file moves) go in a NEW commit:
  `chore(docs): archive {item-id}`. This is non-negotiable — amending a
  pushed commit and force-pushing violates safety rules and can destroy
  parallel session work.
- **NEVER force-push.** If the branch has already been pushed, create a new
  commit and push normally. If the push fails, report the error.
- **Stage only archive-related changes** — status field updates in frontmatter,
  file moves to `docs/archive/`, and `current_work.md` updates. Do not
  re-stage delivery artifacts.
```

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Add "no amend, no force-push" rule to /done and /commit | `commands/done.md`, `commands/commit.md` |
| AC-2 | Add PR_CREATION_MODE propagation to /run preflight, reference in /commit | `commands/run.md`, `commands/commit.md` |
| AC-3 | Add session-state.md artifact-aware staging to /run cleanup and /commit | `commands/run.md`, `commands/commit.md` |
| AC-4 | Add Phase Metrics section to /run with per-phase summary table | `commands/run.md` |

## Implementation Guidance

**Sequence:**
1. `commands/done.md` — Add "Autonomous Safety" section (AC-1, simplest change)
2. `commands/commit.md` — Add safety rules for autonomous context (AC-1, AC-2, AC-3)
3. `commands/run.md` — Update preflight, cleanup, add phase metrics (AC-2, AC-3, AC-4)

**Key considerations:**
- All changes are additive — no existing sections are removed or rewritten
- The existing preflight table already has a `gh` row that says "warn but
  continue" — update this row's "Why" column and add the propagation section
- The session-state.md artifact list is already populated by the
  `track-artifacts.sh` hook — no hook changes needed
- Per-phase metrics are text-only (the LLM tracks them as it goes) — no
  tooling or script support required

**Test strategy:**
- Run `/run --through define "test topic"` on a test project and verify:
  - Preflight reports PR_CREATION_MODE
  - Cleanup references session-state.md
  - Completion summary includes per-phase metrics table
- Run `/run --from discern` on existing delivery and verify:
  - /done creates a NEW commit (not amend)
  - /commit doesn't attempt `gh pr create` when gh is unauthenticated
  - /commit stages only tracked artifacts (no cross-session contamination)

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| LLM ignores "no amend" guidance under context pressure | Low | High | Obligation language (MUST, NEVER), placed at top of section |
| Session-state.md not populated for all artifacts | Low | Med | Fallback to `git diff --name-only HEAD` |
| Phase metrics table adds clutter to /run output | Low | Low | Table is compact (7 rows); operators can ignore |
| Preflight state doesn't persist across context compaction | Med | Med | Variables are referenced in the same session; compaction preserves key state |

## Routing

Ready for Crafter. All changes are markdown prompt edits — no design unknowns.

---

# Implementation

## Summary

All four ACs implemented as targeted prompt edits to three command files.
No code changes, no new files, no scripts modified.

## Changes

### 1. `commands/done.md` (AC-1)

Added "Autonomous Safety" section after Error Handling:
- NEVER amend a previous commit — archive updates go in a NEW commit
- NEVER force-push — if push fails, report the error
- Stage only archive-related changes — do not re-stage delivery artifacts

### 2. `commands/commit.md` (AC-1, AC-2, AC-3)

Extended Safety Rules section with three new rules:
- **Artifact-aware staging in /run context** — use session-state.md artifact
  list, never `git add -A`, fallback to `git diff --name-only HEAD`
- **No force push** — strengthened from "warn if attempting" to NEVER
- **Respect PR_CREATION_MODE** — skip `gh pr create` when `manual`, print
  manual PR URL instead

### 3. `commands/run.md` (AC-2, AC-3, AC-4)

Three additions:
- **Preflight state propagation** (AC-2) — new subsection after gh auth check
  that sets `PR_CREATION_MODE` (auto/manual) and warns when manual
- **Artifact-aware staging** (AC-3) — replaced "Stage ALL artifacts" with
  session-state.md-driven staging, explicit `git add -A` prohibition,
  fallback to `git diff --name-only HEAD`
- **Phase Metrics** (AC-4) — new section after Cleanup with per-phase summary
  table template (phase, artifacts, notes)

## Validation

- `make lint` — clean (shellcheck passes)
- `make test` — 271 tests pass across all 5 test suites
- No frontmatter changes, no YAML to validate
