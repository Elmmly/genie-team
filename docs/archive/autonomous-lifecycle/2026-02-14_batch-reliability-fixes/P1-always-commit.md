---
spec_version: "1.0"
type: shaped-work
id: always-commit
title: "Always Commit at End of Run"
status: done
verdict: APPROVED
created: "2026-02-14"
appetite: small
priority: P1
target_project: genie-team
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
depends_on: []
tags: [workflow, autonomous, commit, worktree, reliability]
acceptance_criteria:
  - id: AC-1
    description: >-
      --from discover --through discover in worktree mode commits discovery
      artifacts before worktree teardown
    status: pending
  - id: AC-2
    description: >-
      --from discover --through define commits both analysis and backlog files
    status: pending
  - id: AC-3
    description: >-
      Full lifecycle (--through done) behavior unchanged — commit still runs in
      its normal position
    status: pending
  - id: AC-4
    description: >-
      No double-commit when --through commit or --through done
    status: pending
---

# Shaped Work Contract: Always Commit at End of Run

## Problem

When `--through` is set to a phase before `commit` (e.g., `--through define`, `--through discover`), the commit phase (index 5) is never reached. The phase loop in `run-pdlc.sh` runs from `from_idx` to `through_idx` only. In worktree mode, artifacts written to the worktree filesystem are lost when the worktree is removed after the run completes.

**Evidence:** 2hearted batch run (Feb 13-14, 2026) — Batch 4 ran 3 discovery items (`--through discover`) at ~$10 total cost. All three completed discovery and wrote analysis artifacts to their worktrees. Because `--through discover` stops at phase index 0 and commit is phase index 5, the artifacts were never committed. When the worktrees were cleaned up, the work was lost.

**Root cause:** The PDLC treats commit as a lifecycle phase gated by `--through`, but commit is actually a utility that completes any stage. A discovery run that doesn't commit is incomplete — it did the expensive work (Claude API calls, analysis) but lost the output.

## Appetite & Boundaries

- **Appetite:** Small (1 day) — one script change, one command doc update
- **No-gos:**
  - Do NOT change the phase ordering or indexing in the `PHASES` array
  - Do NOT make commit run between phases (only after the phase loop)
  - Do NOT remove commit from the `PHASES` array (it must still be addressable via `--from commit`)
- **Fixed elements:**
  - Must work in single-item, worktree, and batch worker modes equally
  - Must not double-commit when `--through commit` or `--through done`
  - The `git status --porcelain` check is the gate — no changes means no commit

## Goals & Outcomes

Every PDLC run that produces artifacts commits them before exiting, regardless of `--through` value. No more silent work loss in worktree or batch modes.

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|---|---|---|
| Artifacts exist as uncommitted files after phase execution | feasibility | Run `--through discover` and check `git status` |
| Commit phase is idempotent (safe to run even if nothing changed) | feasibility | Run commit with clean working tree — should no-op |
| Double-commit protection works via `git status --porcelain` | feasibility | Run `--through commit` and verify only one commit |
| Worktree teardown happens after the phase loop | feasibility | Read `run-pdlc.sh` worktree lifecycle flow |

## Solution Sketch

After the phase loop completes in `run-pdlc.sh`, always run commit if there are uncommitted changes (`git status --porcelain`) — regardless of `--through` value. Skip if `--through` already included the commit phase (index >= 5) to avoid double-commit.

Specifically:
1. After the `for phase in ...` loop exits, check if `through_idx < commit_idx`
2. If so, check `git status --porcelain` for uncommitted changes
3. If changes exist, run the commit phase as a post-loop utility
4. In `commands/run.md`, document that commit always runs as a post-phase utility

This is a ~10-line change in the phase loop exit path plus a documentation update.

## Options

| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| Post-loop commit utility (proposed) | Simple, predictable, no phase reordering | Commit runs outside the normal phase loop | **Recommended** |
| Move commit to always run via flag | Explicit | Adds complexity to phase range parsing | Not recommended |
| Commit inside each phase exit | Granular | Violates single-responsibility; messy | Not recommended |

## Routing

- [x] **Crafter** — Small appetite, single script + doc change
- [ ] **Architect** — Not needed (no design unknowns)

---

# Design

## Overview

Add a post-loop utility commit to `run-pdlc.sh` that fires after the phase range completes whenever `--through` didn't already include the commit phase. The commit is gated by `git status --porcelain` — no changes means no commit. This applies to single-item mode; batch workers already use single-item mode via `$SELF` recursion so they inherit the behavior automatically.

## Architecture

**Pattern: Post-loop utility.** The commit phase remains in the `PHASES` array at index 5 (addressable via `--from commit`), but a second code path runs it as a utility after the phase loop when it wasn't included in the range. The `git status --porcelain` gate prevents double-commits and no-op commits.

**Phase index reference:**
```
PHASES=(discover define design deliver discern commit "done")
         0        1      2       3       4       5      6
```

**Double-commit prevention logic:**
- `--through done` → `through_idx=6 >= commit_idx=5` → utility commit skipped (commit already ran in loop)
- `--through commit` → `through_idx=5 >= commit_idx=5` → utility commit skipped
- `--through discern` → `through_idx=4 < commit_idx=5` → utility commit fires if changes exist
- `--through discover` → `through_idx=0 < commit_idx=5` → utility commit fires if changes exist

## Component Design

### 1. `scripts/run-pdlc.sh` — Post-loop utility commit (single-item mode)

**Location:** After the phase loop `done` (line ~1263), before the worktree teardown block (line ~1266).

**Insert the following block:**

```bash
    # ── Post-loop utility commit ──
    # Commit is a utility that completes any stage, not a lifecycle phase
    # gated by --through. If the phase range didn't include commit, run it
    # now to prevent artifact loss (especially critical in worktree mode).
    local commit_idx
    commit_idx=$(phase_index "commit")
    if [[ "$through_idx" -lt "$commit_idx" ]]; then
        if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
            log_info "[commit] Running post-phase utility commit"
            local commit_start
            commit_start=$(date +%s)

            run_phase "commit" "${item_path:-${analysis_path:-$INPUT}}"
            local commit_ec=$?

            local commit_end commit_duration
            commit_end=$(date +%s)
            commit_duration=$((commit_end - commit_start))
            log_phase_usage "commit" "${PHASE_NUM_TURNS:-0}" "${PHASE_TOKENS:-0}" "$commit_duration"

            if [[ $commit_ec -ne 0 ]]; then
                log_error "[commit] Utility commit failed (exit $commit_ec)"
                # Non-fatal: the phase work succeeded, commit failure shouldn't
                # cause worktree cleanup to destroy artifacts
            fi
        else
            log_debug "No uncommitted changes — skipping utility commit"
        fi
    fi
```

**Key decisions:**
- Commit failure is logged but non-fatal — the phase work succeeded and we don't want a commit prompt failure to trigger `--cleanup-on-failure` worktree removal (which would destroy the very artifacts we're trying to save)
- Input resolution: `item_path` for define+ phases, `analysis_path` for discover-only, `INPUT` as final fallback
- `git status --porcelain` is the gate — zero-cost when nothing changed

### 2. `scripts/run-pdlc.sh` — Batch parallel workers

**No changes needed.** Each batch worker invokes `$SELF` with `--worktree --finish-mode --leave-branch`, which enters `main()` → single-item mode. The post-loop utility commit fires inside each worker's subprocess before `--leave-branch` detaches the worktree.

### 3. `commands/run.md` — Documentation update

**Modify the Phase Range Model section** to add a note:

After the phase range table, add:

```markdown
**Commit as utility:** Regardless of `--through`, the runner always commits
any uncommitted artifacts after the phase range completes. This prevents
work loss in worktree and batch modes where artifacts would otherwise be
destroyed on teardown. If `--through` already includes `commit` or `done`,
no extra commit is made (double-commit protection via `git status`).
```

**Modify the Workflow diagram** to show the utility commit:

After the existing `/commit` entry, update the diagram comment to indicate the utility behavior:

```markdown
    └─→ /commit [item_path]       ◄── always runs (utility, not gated by --through)
        └─→ Create conventional commit (single commit for everything)
```

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Post-loop utility commit fires when `through_idx < commit_idx` and `git status --porcelain` has output. Worktree mode: commit runs before `worktree_teardown_success`. | `scripts/run-pdlc.sh` |
| AC-2 | Same mechanism — discover writes to `docs/analysis/`, define writes to `docs/backlog/`. Both produce uncommitted files detected by `git status --porcelain`. | `scripts/run-pdlc.sh` |
| AC-3 | When `--through done`, `through_idx=6 >= commit_idx=5`, so `through_idx < commit_idx` is false → utility commit skipped. Commit already ran in the normal loop at index 5. | `scripts/run-pdlc.sh` |
| AC-4 | Same check: `--through commit` → `through_idx=5`, not less than `commit_idx=5` → skipped. `--through done` → `through_idx=6` → skipped. `git status --porcelain` as secondary gate catches edge cases where commit ran but nothing changed. | `scripts/run-pdlc.sh` |

## Implementation Guidance

**Sequence:**
1. Add post-loop utility commit block to `run-pdlc.sh` (between phase loop and worktree teardown)
2. Add tests to `tests/test_run_pdlc.sh` for each AC
3. Update `commands/run.md` documentation

**Test strategy:**
- Test utility commit fires: source `run-pdlc.sh`, mock `run_phase` and `git status --porcelain`, set `through_idx=0`, verify `run_phase "commit"` is called
- Test utility commit skipped when `--through done`: set `through_idx=6`, verify `run_phase "commit"` is NOT called
- Test utility commit skipped when `--through commit`: set `through_idx=5`, verify NOT called
- Test utility commit skipped when no changes: mock `git status --porcelain` to return empty, verify NOT called

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Commit phase fails in utility mode | Low | Low | Non-fatal — log error, don't trigger cleanup |
| `git status --porcelain` misses staged changes | Low | Low | The check catches both staged and unstaged — covers all cases |
| Claude `/commit` prompt expects full lifecycle context | Low | Med | The commit command works with just an artifact path — no lifecycle context needed |

## Routing

Ready for Crafter. No architectural unknowns — single insertion point in the phase loop exit path.

# Review

<!-- Appended by /discern on 2026-02-14 -->

**Verdict:** APPROVED

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | designed | Post-loop utility commit fires when `through_idx < commit_idx` and `git status --porcelain` has output. Worktree mode: commit runs before teardown. |
| AC-2 | designed | Same mechanism — discover writes `docs/analysis/`, define writes `docs/backlog/`. Both produce uncommitted files detected by `git status --porcelain`. |
| AC-3 | designed | When `--through done`, `through_idx=6 >= commit_idx=5` → utility commit skipped. Commit already ran in the normal loop at index 5. |
| AC-4 | designed | Double-commit prevention: `through_idx >= commit_idx` → skip utility commit. `git status --porcelain` as secondary gate for edge cases. |

## Code Quality

- Single insertion point between phase loop and worktree teardown — minimal blast radius
- Commit failure is non-fatal — prevents cleanup from destroying artifacts
- Input resolution chain: `item_path` → `analysis_path` → `INPUT` covers all phase ranges
- Batch workers inherit behavior automatically via `$SELF` recursion

## Notes

No blocking issues. Design is minimal and focused — exactly what's needed to prevent artifact loss in worktree/batch modes.

# Implementation

<!-- Appended by /deliver on 2026-02-14 -->

## Changes

| File | Change |
|------|--------|
| `scripts/run-pdlc.sh` | Added `maybe_utility_commit()` function — checks `through_idx < commit_idx` and `git status --porcelain`, runs commit as post-phase utility |
| `scripts/run-pdlc.sh` | Inserted `maybe_utility_commit` call after phase loop, before worktree teardown |
| `commands/run.md` | Added "Commit as utility" note to Phase Range Model section |
| `tests/test_run_pdlc.sh` | 4 new tests: fires when through < commit with changes, skipped when through=done, skipped when through=commit, skipped when no changes |

## Test Results

- 148 tests total in `tests/test_run_pdlc.sh`, all passing
- Commit failure is non-fatal — logged but doesn't trigger cleanup

# Review (Implementation)

<!-- Appended by /discern on 2026-02-14 -->

**Verdict:** APPROVED

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `maybe_utility_commit` at line 1420 fires after phase loop, before worktree teardown. `through_idx=0 < commit_idx=5` triggers commit. Test confirms. |
| AC-2 | met | Same mechanism — both `item_path` and `analysis_path` resolve correctly via input chain `${item_path:-${analysis_path:-$input}}` |
| AC-3 | met | `through_idx=6 >= commit_idx=5` → utility commit skipped. Commit runs in normal loop at index 5. Test confirms. |
| AC-4 | met | `through_idx=5` and `through_idx=6` both `>= commit_idx=5` → skipped. `git status --porcelain` as secondary gate. Both cases tested. |

## Code Quality

- Single insertion point between phase loop and worktree teardown — minimal blast radius
- Commit failure is non-fatal — prevents cleanup from destroying artifacts
- Input resolution chain covers all phase ranges
- 4 tests with clear mocking of `run_phase` and `git status`
