---
spec_version: "1.0"
type: shaped-work
id: GT-35
title: "Fix /run Skipping /done Phase and Leaving Stale Statuses"
status: done
created: "2026-02-13"
appetite: small
priority: P1
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
tags: [workflow, autonomous, run, done, field-test]
acceptance_criteria:
  - id: AC-1
    description: >-
      /run command includes explicit phase completion verification: after
      each phase executes, /run checks the phase off its progress tracker
      and confirms the next phase will run. If any phase in the range was
      skipped, the completion summary flags it as INCOMPLETE with the
      skipped phases listed.
    status: pending
  - id: AC-2
    description: >-
      /run reorders the final phases: /done runs BEFORE /commit (not
      after). This means archive updates (status changes, file moves,
      current_work.md) are included in the single delivery commit rather
      than requiring a separate commit. The phase sequence becomes:
      discern → cleanup → done → commit.
    status: pending
---

# Shaped Work Contract: Fix /run Skipping /done Phase

## Problem

The second autonomous `/run` field test on 2hearted (2026-02-13) completed
discover → define → deliver → discern → commit but **silently skipped /done**.
Both backlog items were left in `docs/backlog/` with stale statuses
(`implemented` and `reviewed`) instead of being archived. The operator had to
manually clean up after the run.

This is a reliability issue with two root causes:

1. **Phase ordering:** `/done` is sequenced AFTER `/commit`, which means the
   LLM treats `/commit` as the natural endpoint — the code is committed, the
   work "feels done." The `/done` phase (archiving, status updates) is
   housekeeping that gets dropped under context pressure.

2. **No completion verification:** `/run` doesn't verify that all phases in
   its range actually executed. A run can silently skip phases and still
   report success.

The fix is to reorder `/done` before `/commit` so archiving is part of the
delivery commit, and add phase completion verification to catch any skips.

**Evidence:** 2hearted field test log `run-20260213-1742.log` (334 lines).
The run executed discover, define, deliver, discern, commit (b9dfc14) but
never invoked `/done`. Backlog items left with stale statuses required manual
archiving (commit 7280dc8).

**Who's affected:** Any operator running unattended `/run` — the incomplete
lifecycle leaves debris that accumulates across runs and confuses subsequent
sessions about what work is active vs complete.

## Appetite & Boundaries

- **Appetite:** Small (1 day) — prompt edits to `commands/run.md` only
- **No-gos:**
  - Do NOT modify `commands/done.md` (already has Autonomous Safety section)
  - Do NOT modify `commands/commit.md` (already has safety rules)
  - Do NOT modify `scripts/run-pdlc.sh` (headless runner has its own phase
    tracking)
  - Do NOT add scripts, hooks, or new commands
- **Fixed elements:**
  - `/run` command at `commands/run.md` is the only artifact
  - The existing Progress tracker in State Tracking section is the mechanism

## Goals & Outcomes

Every `/run` invocation either completes ALL phases in its range or explicitly
reports which phases were skipped. No silent phase drops. No stale statuses
left behind without a clear signal to the operator.

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior
- AC-1: /run runs specified phase range without confirmation gates, using
  /discern as the automated quality gate. Phase order is:
  discover → define → design → deliver → discern → commit → done

### Proposed Changes
- AC-1 (no spec wording change): Reorder final phases to
  discern → cleanup → **done** → commit. This puts archiving before the
  commit so all changes land in a single commit, and eliminates the
  natural "commit = done" stopping point. Add phase completion verification
  so skipped phases are flagged.

### Rationale
Field test proved /run can complete 6 of 7 phases and appear successful
while leaving the lifecycle incomplete. The root cause is phase ordering:
/done after /commit makes it feel optional. Moving /done before /commit
makes archiving part of the delivery and eliminates the need for a separate
archive commit (which GT-34 had to work around).

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| LLM drops /done because /commit feels like completion | feasibility | Confirmed by field test — this is the observed behavior |
| Adding "MUST run /done" guidance prevents the skip | feasibility | Run /run on a test project and verify /done executes |
| Phase completion checklist doesn't add excessive verbosity | usability | Check output length with checklist vs without |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Add phase verification + mandatory /done to /run prompt | Targeted, minimal change, matches GT-34 pattern | Relies on LLM following guidance | **Recommended** |
| B: Add post-run hook that checks archival status | Hard gate, impossible to bypass | Over-engineering; hooks can't invoke /done | Not recommended |

## Routing

- [x] **Ready for design** — Single-file prompt edit, well-understood pattern
- [ ] Needs Architect spike

---

# Design

## Overview

Two targeted changes to `commands/run.md`: reorder the final phase sequence
(done before commit) and add phase completion verification. No other files
modified. No ADRs needed — single approach, easily reversible prompt edit.

## Architecture

**Pattern: Phase reorder + completion guard.** The root cause is that /commit
feels like a natural stopping point. Moving /done before /commit makes
archiving part of the delivery flow, and the completion guard catches any
phase that gets silently dropped.

**New phase sequence:**
```
discover → define → design → deliver → discern → done → commit
```

The cleanup step (remove binaries) stays before /done. Staging moves to
after /done so archive file moves are included. The flow becomes:

```
discern (APPROVED) → cleanup (binaries) → /done (archive) → stage → /commit
```

## Component Design

### `commands/run.md` — 6 edit locations

**Edit 1: Opening line (line 3)**
Change phase sequence from `discern → commit → done` to `discern → done → commit`.

**Edit 2: Workflow diagram (lines 39-73)**
Reorder the final three blocks:
```markdown
    ├─→ /discern [item_path]     ◄── AUTOMATED QUALITY GATE
    │   ├─→ APPROVED → continue
    │   └─→ BLOCKED → STOP, report failure
    │
    ├─→ [cleanup] Remove binaries
    │
    ├─→ /done [item_path]
    │   └─→ Archive completed work, update statuses
    │
    ├─→ [stage + commit]
    │   └─→ Stage all session artifacts, create conventional commit
```

**Edit 3: Phase Range Model (line 82 and examples)**
Update all sequence references from `discern → commit → done` to
`discern → done → commit`.

**Edit 4: Gate Behavior table (line 221)**
Change `APPROVED | Continue to /commit → /done` to
`APPROVED | Continue to /done → /commit`.

**Edit 5: Cleanup Before Commit section (lines 230-245)**
Rename to "Cleanup and Staging" and split into two steps:
1. **Before /done:** Remove compiled binaries (`go clean`, etc.)
2. **After /done, before /commit:** Stage artifacts using session-state.md
   list (this now includes archive file moves from /done)

**Edit 6: New section — Phase Completion Verification (after Phase Metrics)**
```markdown
## Phase Completion Verification

After the final phase completes, verify ALL phases in the range executed.
Use the Progress tracker to check:

1. Every phase between `--from` and `--through` has a [x] checkmark
2. If any phase shows [ ] (unchecked), report it in the completion summary:

   > ⚠ INCOMPLETE: The following phases were in range but did not execute:
   > - [phase name]
   >
   > Backlog item may have stale status. Run `/done [item_path]` manually.

3. The completion summary MUST include the verification result:
   - **All phases complete** — report normally
   - **Phases skipped** — report as INCOMPLETE with the list above

This verification runs even if the run appears successful. A committed
codebase with unarrchived backlog items is an incomplete lifecycle.
```

## AC Mapping

| AC | Approach | Edit Locations |
|----|----------|----------------|
| AC-1 | Add Phase Completion Verification section; verify all phases ran after final phase | Edit 6 (new section) |
| AC-2 | Reorder phase sequence to discern → done → commit; split cleanup/staging around /done | Edits 1-5 (sequence references + cleanup restructure) |

## Implementation Guidance

**Sequence:**
1. Edits 1-4 — Update all phase sequence references (mechanical find-and-replace)
2. Edit 5 — Restructure Cleanup section into pre-done and post-done steps
3. Edit 6 — Add Phase Completion Verification section

**Key considerations:**
- The Phase Range Model examples still work — `--from discern` now means
  `discern → done → commit` instead of `discern → commit → done`
- The Progress tracker in State Tracking already has the checklist format —
  just reorder done/commit there too
- GT-34's "Autonomous Safety" section in done.md (NEVER amend) is still
  valid for interactive use but becomes moot in /run context since archiving
  is now part of the main commit

**Test strategy:**
- `make lint` to verify no frontmatter issues
- `make test` to verify no regressions
- Manual review: read commands/run.md end-to-end and confirm the new
  sequence is consistent throughout

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| LLM ignores reordered sequence under context pressure | Low | Med | Obligation language + workflow diagram is the primary reference |
| /done fails mid-archive, leaving partial state before /commit | Low | Med | /commit still runs; partial archive is better than no archive |
| Reorder confuses interactive users reading the command | Low | Low | /run is autonomous-only; interactive users use /feature |

## Routing

Ready for Crafter. All changes are prompt edits to one file.

---

# Implementation

## Summary

All changes are prompt edits to `commands/run.md` — 6 edit locations as specified
in the design. No other files modified. No code changes, no scripts.

## Changes

### `commands/run.md` — 6 edits

**Edit 1: Opening line (line 3)**
Updated phase sequence from `discern → commit → done` to
`discern → done → commit`.

**Edit 2: Workflow diagram (lines 39-75)**
Reordered final blocks: cleanup → /done → stage → /commit. Archive changes
(file moves, status updates from /done) are now included in the staging step
before /commit, producing a single delivery commit.

**Edit 3: Phase Range Model + State Tracking + Usage Examples + Phase Metrics**
Updated all sequence references to `discover → define → design → deliver →
discern → done → commit`. Updated examples to show /done before /commit.

**Edit 4: Gate Behavior table**
Changed APPROVED action from "Continue to /commit → /done" to
"Continue to /done → /commit".

**Edit 5: Cleanup and Staging section**
Renamed from "Cleanup Before Commit" and split into two steps around /done:
1. **Before /done:** Remove compiled binaries
2. **After /done, before /commit:** Stage all artifacts (now includes archive
   file moves and status updates from /done)

**Edit 6: Phase Completion Verification (new section)**
Added after Phase Metrics. Checks that all phases in the `--from`/`--through`
range have `[x]` checkmarks in the Progress tracker. Reports INCOMPLETE with
skipped phase list if any are unchecked.

## Validation

- `make lint` — clean
- `make test` — 283 tests pass across all test suites
- Manual review: read `commands/run.md` end-to-end, confirmed new sequence is
  consistent throughout all sections
