---
spec_version: "1.0"
type: shaped-work
id: P1-retry-resilience
title: "Batch Retry Resilience"
status: done
verdict: APPROVED
created: 2026-02-14
appetite: small
priority: P1
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
depends_on:
  - docs/archive/autonomous-lifecycle/2026-02-14_batch-reliability-fixes/P1-always-commit.md
  - docs/archive/autonomous-lifecycle/2026-02-14_batch-reliability-fixes/P1-integration-diagnostics.md
acceptance_criteria:
  - id: AC-1
    description: >-
      Before creating a worktree for a batch item, the runner cleans up any existing
      worktree and branch from a prior failed attempt for the same item slug, so retries
      don't fail on "branch already exists" or "worktree already exists" errors
    status: pending
  - id: AC-2
    description: >-
      Batch mode skips items whose backlog frontmatter status is already "done" or
      "reviewed", logging them as "already complete" rather than re-running expensive
      PDLC phases
    status: pending
  - id: AC-3
    description: >-
      When --lock is used in batch mode, stale lockfiles from prior runs (identified by
      dead PID or age > threshold) are automatically removed before acquiring a new lock,
      rather than blocking with "lock held by running process"
    status: pending
  - id: AC-4
    description: >-
      Existing retry behavior (single-item --lock with stale detection, worktree
      teardown on failure) is unchanged for non-batch single-item runs
    status: pending
---

# Shaped Work Contract: Batch Retry Resilience

## Problem

When a batch run partially fails (some items succeed, some fail), re-running the batch causes a **total wipeout** — zero useful work from the retry. This was observed on the 2hearted overnight batch run (Feb 13-14, 2026): Run 2 produced $0 of useful work because:

1. **Stale lockfiles** from Run 1 blocked re-running the same items (4-hour stale threshold, but retry was within the window)
2. **Leftover worktrees/branches** from Run 1 caused `session_start` to fail ("branch already exists")
3. **Already-completed items** from Run 1 were re-attempted instead of skipped, wasting tokens on items that already succeeded

The batch runner has no retry awareness — it treats every run as a fresh start, ignoring the state left behind by a previous run.

## Evidence

- **2hearted Run 2** (Feb 14): Total wipeout — all items failed during setup phase
- **Root cause**: `session_start` calls `git worktree add` which fails if the branch already exists from Run 1
- **Lock contention**: `acquire_lock` returns exit 3 when lockfile exists from a process that already exited but lockfile wasn't cleaned up (e.g., process killed by OOM, signal, or timeout)
- **Wasted cost**: Run 2 burned tokens on items that Run 1 had already successfully delivered

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days)
- **No-gos:**
  - No cross-worktree coordination protocol
  - No distributed locking (file-based is sufficient)
  - No automatic conflict resolution for integration failures
  - No changes to the `genie-session` library API signatures
- **Fixed elements:**
  - `session_cleanup_item()` already exists and handles worktree + branch removal
  - `get_frontmatter_field()` already exists for reading backlog status
  - Lock stale detection already exists (4-hour threshold, PID check)
  - Batch item resolution via `resolve_batch_items()` already exists

## Goals & Outcomes

- A failed batch run can be re-run immediately without manual cleanup
- Already-completed items are skipped automatically, saving tokens
- Operators don't need to manually remove worktrees, branches, or lockfiles between retries

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| `session_cleanup_item` is safe to call when no prior worktree exists | Feasibility | Unit test — call with nonexistent slug |
| Dead PID detection works cross-platform (macOS + Linux) | Feasibility | Existing `kill -0` check covers both |
| Skipping "done" items won't miss items that need re-review | Value | Check: status transitions are discover→shaped→designed→implemented→reviewed→done — only skip terminal states |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| Pre-cleanup in `worktree_setup` | Simple, contained change, cleanup happens right before creation | Cleanup on every run even when unnecessary | **Recommended** — cleanup is cheap (no-op when nothing exists) |
| Separate `--cleanup-prior` flag | Explicit, opt-in | Another flag to remember, easy to forget | Not recommended |
| Cleanup in batch orchestration loop only | Centralized | Doesn't help single-item --worktree retries | Too narrow |

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior
- AC-5 (unmet): "Runner implements worktree lifecycle for parallel execution: create worktree before run, cleanup on success, preserve-or-cleanup on failure with retry convention"
- AC-8 (met): Batch execution scans backlog, runs items concurrently in worktrees

### Proposed Changes
- AC-5: Partially addressed — this item adds the "retry convention" part (prior attempt cleanup before worktree creation)
- AC-8: Enhanced — batch `resolve_batch_items` now filters out terminal-status items (done, reviewed)
- Design constraint (line 120): "including prior failed attempt cleanup" — this item implements that constraint

### Rationale
The design constraints already specify prior failed attempt cleanup (line 120) and the `--cleanup-on-failure` opt-in (line 121). The missing piece is the implementation in `worktree_setup` and `resolve_batch_items`.

## Solution Sketch

1. **Pre-cleanup in `worktree_setup()`**: Before calling `session_start`, call `session_cleanup_item "$item_slug" 2>/dev/null || true` to remove any prior worktree/branch
2. **Status filter in `resolve_batch_items()`**: After reading backlog items, skip those with `status: done` or `status: reviewed` (log as "skipping: already complete")
3. **Stale lock auto-cleanup in `acquire_lock()`**: When a stale lock is detected (dead PID or age > threshold), remove it and proceed instead of returning exit 3

## Routing

→ Architect (for design) or directly to Crafter (small, well-scoped changes in existing functions)

## Dependencies

- `session_cleanup_item()` in `genie-session` (already implemented)
- `get_frontmatter_field()` in `genies` (already implemented)
- `acquire_lock()` in `genies` (already implemented)

# Implementation

## Changes

### `scripts/genies`
- **`worktree_setup()`**: Added `session_cleanup_item "$item_slug" 2>/dev/null || true` before `session_start` to clean up prior failed attempts (AC-1)
- **`status_to_phase()`**: Removed `reviewed` → `done` mapping; "reviewed" now returns empty string, making it non-actionable in batch resolution (AC-2)
- Both `resolve_batch_items` code paths (backlog scan and explicit inputs) inherit the filter via `status_to_phase` — no separate changes needed
- **`acquire_lock()`**: Already handles dead PID (overwrite) and stale age > 4h (overwrite); only blocks on live PID within threshold (AC-3 already met)
- No changes to single-item `--worktree` mode or `--lock` behavior (AC-4)

### `tests/test_run_pdlc.sh`
- **Category 21**: 8 new tests covering all 4 ACs
- Updated existing `status_to_phase` test: `reviewed → done` changed to `reviewed → (skipped)`
- Total: 197 tests, all passing

## Design Decisions
- Pre-cleanup is unconditional (runs on every `worktree_setup` call, not just retries) — `session_cleanup_item` is a no-op when nothing exists, so the overhead is negligible
- "reviewed" items are skipped in batch mode rather than running `/done` — operators can use single-item mode to archive specific items if needed

# Review
<!-- Added by /discern on 2026-02-14 -->

**Verdict:** APPROVED
**ACs verified:** 4/4 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `worktree_setup()` calls `session_cleanup_item "$item_slug" 2>/dev/null \|\| true` before `session_start` (line 803). Test confirms cleanup is called. |
| AC-2 | met | `status_to_phase()` returns empty for "reviewed" and "done" — both are non-actionable. Both `resolve_batch_items` code paths (backlog scan line 870 and explicit inputs line 896) skip items with empty phase. 3 tests cover this. |
| AC-3 | met | `acquire_lock()` already handles dead PID (via `kill -0`) and stale age > 4h threshold — overwrites in both cases. Only blocks on live PID within threshold. Existing lockfile tests confirm behavior. |
| AC-4 | met | No changes to single-item `--worktree` or `--lock` behavior. Existing worktree/lock tests continue to pass. |

**Code quality:** Good. Pre-cleanup is unconditional (no-op when nothing exists) — clean and simple.
**Test coverage:** 8 new tests + 1 updated, all passing.
**Security:** No concerns.
**Performance:** `session_cleanup_item` is a no-op when nothing exists — negligible overhead.

# End of Shaped Work Contract
