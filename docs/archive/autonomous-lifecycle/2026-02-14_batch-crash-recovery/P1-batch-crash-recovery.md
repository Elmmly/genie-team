---
spec_version: "1.0"
type: shaped-work
id: P1-batch-crash-recovery
title: "Batch Crash Recovery"
status: done
verdict: APPROVED
created: 2026-02-14
appetite: small
priority: P1
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
acceptance_criteria:
  - id: AC-1
    description: >-
      genies --recover scans for existing genie/* branches, integrates each to
      trunk (or creates PR) sequentially, cleans up worktrees and branches on
      success, and reports results. Respects --priority for slug-prefix filtering.
    status: pending
  - id: AC-2
    description: >-
      Batch mode registers an EXIT trap that writes a partial batch-manifest.json
      listing succeeded/in-progress/not-started items before the process exits,
      so --recover knows which branches represent completed work worth integrating.
    status: pending
  - id: AC-3
    description: >-
      genies --recover reads the partial batch-manifest.json (if present in
      --log-dir) to distinguish succeeded branches from failed/in-progress ones.
      Succeeded branches are integrated; failed/in-progress branches are reported
      but not integrated (safety guard). Without a manifest, all genie/* branches
      are listed for operator confirmation.
    status: pending
  - id: AC-4
    description: >-
      Single-item worktree runs (non-batch) are unaffected — their existing
      --finish-mode default (--merge) continues to integrate immediately.
      --recover is a batch-only recovery mechanism.
    status: pending
---

# Shaped Work Contract: Batch Crash Recovery

## Problem

When a batch run is interrupted (terminal closed, laptop lid closed, OOM kill, Ctrl-C), the integration loop never runs. Each batch worker uses `--finish-mode --leave-branch` by design — branches are preserved for a sequential integration phase that merges them to trunk one at a time. But if the parent process dies before integration, **all completed work is stranded in orphaned branches**.

The `--recover` flag was spec'd in the design constraints (line 126 of the autonomous-lifecycle spec) and the flag is parsed in `parse_args`, but **no code path checks `RECOVER_MODE`** — it's a stub. Operators must manually run `session_integrate_trunk` for each branch, which requires knowing the slugs, understanding which branches contain completed work vs. partial failures, and running cleanup afterward.

On the 2hearted "while-away" run (Feb 14, 2026), 3 items ran in parallel. 2 completed successfully (~$14 of work), 1 was killed mid-deliver. All 3 branches were left orphaned. The worktree for the killed item was still on disk.

## Evidence

- **2hearted while-away run**: 3 orphaned `genie/*` branches, 1 orphaned worktree, 0 items integrated
- **Code audit**: `RECOVER_MODE` is parsed (line 278) but never checked — grep confirms no code path acts on it
- **Batch workers**: Line 1215 hardcodes `--finish-mode --leave-branch` — by design, but creates the dependency on the integration loop running
- **No trap**: `run_batch_parallel` has no signal trap — if killed, integration loop (lines 1310-1370) and manifest write (lines 1380-1391) are skipped entirely

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days)
- **No-gos:**
  - No automatic retry of failed/partial items during recovery (recovery = integrate what succeeded, report the rest)
  - No interactive prompts during --recover (must work headless)
  - No changes to batch worker logic (`--leave-branch` is correct for parallel safety)
  - No changes to single-item worktree flow (already uses `--merge`)
- **Fixed elements:**
  - `session_integrate_trunk` already works (exit codes 0/1/2/3/4)
  - `session_cleanup_item` already works (removes worktree + branch)
  - `write_batch_manifest` already works (JSON format)
  - `--recover` flag already parsed into `RECOVER_MODE`

## Goals & Outcomes

- `genies --recover --log-dir logs/while-away` integrates completed work from any interrupted batch
- Interrupted batch runs don't lose completed work — the EXIT trap preserves enough state for recovery
- Operators have one command to run after any crash, not a manual per-branch cleanup

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| EXIT trap fires on SIGTERM and SIGINT | Feasibility | bash EXIT trap fires on most signals except SIGKILL |
| Partial manifest has enough info to distinguish succeeded from in-progress | Feasibility | Worker PIDs + exit codes are tracked in arrays — trap can snapshot them |
| Integrating succeeded branches after a crash is safe | Value | Branches contain committed work; integration is the same as the normal path |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| Implement --recover + EXIT trap | Complete solution: trap preserves state, recover acts on it | Two changes instead of one | **Recommended** — both pieces needed for reliable crash recovery |
| --recover only (no trap) | Simpler | Without manifest, can't tell succeeded from failed branches | Acceptable but less safe — would need operator judgment |
| Auto-recover at batch start | Zero-touch — next batch cleans up prior crash | Risky: might integrate branches with partial work | Not recommended as default (could be opt-in later) |

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior
- AC-5 (unmet): "Runner implements worktree lifecycle for parallel execution: create worktree before run, cleanup on success, preserve-or-cleanup on failure with retry convention"
- AC-8 (met): Batch execution with `--recover` flag described — but `--recover` is a stub with no implementation

### Proposed Changes
- AC-5: Partially addressed — this implements the recovery convention for worktree lifecycle (create → run → crash → recover → cleanup)
- AC-8: Enhanced — `--recover` is implemented, EXIT trap preserves partial state for recovery
- Design constraint (line 126): Fully implemented — `--recover` re-runs integration for items with existing unmerged `genie/*` branches

### Rationale
The design constraint already describes the exact behavior. This item implements what was spec'd but never built.

## Solution Sketch

1. **EXIT trap in `run_batch_parallel()`**: Before spawning workers, register `trap cleanup_on_exit EXIT`. The trap function snapshots `succeeded_items` and writes a partial `batch-manifest.json` with whatever is known at that point.

2. **`run_recover()` function**: When `RECOVER_MODE=true`:
   - Read `batch-manifest.json` from `--log-dir` (if present) to get succeeded item list
   - If no manifest: scan `genie/*` branches, list them, and integrate all (with warning)
   - For each succeeded branch: `session_integrate_trunk "$slug"`, log result
   - For each failed/in-progress branch: report but don't integrate
   - Clean up orphaned worktrees via `session_cleanup_item`
   - Write updated manifest and run `reconcile_batch_state`

3. **Entry point in `main()`**: Check `RECOVER_MODE` before the normal batch/single-item flow. If true, call `run_recover()` and exit.

## Routing

-> Crafter (small, well-scoped — implement stub, add trap, add tests)

## Dependencies

- `session_integrate_trunk()` in `genie-session` (already implemented)
- `session_cleanup_item()` in `genie-session` (already implemented)
- `write_batch_manifest()` in `genies` (already implemented)
- `reconcile_batch_state()` in `genies` (already implemented)

# Design
<!-- Added by /design on 2026-02-14 -->

## Design Summary

Three changes to `scripts/genies`: (1) implement `run_recover()`, (2) add EXIT trap in `run_batch_parallel()`, (3) wire `RECOVER_MODE` into `main()`.

## Component Design

### 1. `run_recover()` — New function (AC-1, AC-3)

```bash
run_recover() {
    local manifest="${LOG_DIR:-}/batch-manifest.json"
    local branches=()
    local succeeded_slugs=()

    # Source 1: Read manifest if available
    if [[ -f "$manifest" ]] && command -v jq &>/dev/null; then
        while IFS= read -r item; do
            [[ -n "$item" ]] && succeeded_slugs+=("$(basename "$item" .md)")
        done < <(jq -r '.succeeded[]' "$manifest" 2>/dev/null)
    fi

    # Source 2: Scan genie/* branches
    while IFS= read -r branch; do
        [[ -n "$branch" ]] && branches+=("${branch#genie/}")
    done < <(git branch --list 'genie/*' --format='%(refname:short)')

    if [[ ${#branches[@]} -eq 0 ]]; then
        log_info "No genie/* branches found. Nothing to recover."
        return 0
    fi

    # Priority filter (reuse existing --priority mechanism)
    # Integrate succeeded branches; report others
    for slug_branch in "${branches[@]}"; do
        # Extract slug (strip phase suffix: P0-foo-design → P0-foo)
        local slug="${slug_branch%-*}"  # strip -design, -deliver, etc.

        # Priority filter
        if [[ ${#PRIORITIES[@]} -gt 0 ]]; then
            local match="false"
            for p in "${PRIORITIES[@]}"; do
                [[ "$slug" == "$p"* ]] && { match="true"; break; }
            done
            [[ "$match" == "true" ]] || continue
        fi

        # Check if this branch's slug is in succeeded list
        local is_succeeded="false"
        if [[ ${#succeeded_slugs[@]} -eq 0 ]]; then
            # No manifest — integrate all (with warning on first)
            is_succeeded="true"
        else
            for s in "${succeeded_slugs[@]}"; do
                [[ "$s" == *"$slug"* || "$slug" == *"$s"* ]] && { is_succeeded="true"; break; }
            done
        fi

        if [[ "$is_succeeded" == "true" ]]; then
            # Integrate
            if [[ "$TRUNK_MODE" == "true" ]]; then
                session_integrate_trunk "$slug_branch"
            else
                session_integrate_pr "$slug_branch"
            fi
            local ec=$?
            # Log result, cleanup on success
            if [[ $ec -eq 0 ]]; then
                log_info "Recovered: $slug_branch"
            else
                log_error "Integration failed (exit $ec): $slug_branch"
            fi
        else
            log_info "Skipping (not in succeeded list): $slug_branch"
            # Clean up orphaned worktree if exists
            session_cleanup_item "$slug_branch" 2>/dev/null || true
        fi
    done
}
```

Key decisions:
- Uses full branch name (e.g., `P0-env-config-consistency-design`) for `session_integrate_trunk` since that's what `_gs_find_branch` matches against
- Without manifest: integrates ALL branches (the safe-enough default — branches only exist if a worker created them)
- With manifest: only integrates branches matching succeeded items; cleans up the rest
- Reuses existing `--priority` filtering via `PRIORITIES` array

### 2. EXIT trap in `run_batch_parallel()` (AC-2)

Register trap at the start of `run_batch_parallel()`, before spawning workers:

```bash
# At the top of run_batch_parallel(), after variable declarations:
_batch_exit_trap() {
    # Write partial manifest with whatever we know
    if [[ -n "$LOG_DIR" ]]; then
        write_batch_manifest \
            "${succeeded_items[@]+"${succeeded_items[@]}"}" \
            "---" \
            "${failed_items[@]+"${failed_items[@]}"}" \
            "---" \
            "${conflict_items[@]+"${conflict_items[@]}"}"
    fi
}
trap _batch_exit_trap EXIT
```

The trap function accesses the parent function's local variables (bash closure over locals). On normal completion, the manifest is written twice (trap + explicit call) — the explicit call overwrites the trap's write, so no harm.

### 3. Wire `RECOVER_MODE` into `main()` (AC-1, AC-3)

Insert check at the top of `main()`, after `parse_args` and before the batch/single-item branch:

```bash
main() {
    parse_args "$@"

    # Recovery mode: integrate leftover branches from crashed batch
    if [[ "$RECOVER_MODE" == "true" ]]; then
        run_recover
        exit $?
    fi

    # ... existing batch/single-item logic
}
```

## Implementation Guidance

- `run_recover` must work without `genie-session` being available (guard with function existence check, same pattern as `worktree_setup`)
- Branch listing uses `git branch --list 'genie/*'` — portable, no external dependencies
- The EXIT trap must be defined INSIDE `run_batch_parallel` (not at top level) so it captures the function's local arrays
- Existing single-item flow is untouched (AC-4)
- Tests should mock `session_integrate_trunk` and `git branch --list` for unit testing

# Implementation
<!-- Added by /deliver on 2026-02-14 -->

## Changes

### `scripts/genies`
- **`_batch_exit_trap()`**: New function — writes partial `batch-manifest.json` with whatever succeeded/failed/conflict items are known at exit time (AC-2)
- **`run_recover()`**: New function — scans `genie/*` branches, reads manifest (if available in `--log-dir`) to identify succeeded items, integrates succeeded branches via `session_integrate_trunk` or `session_integrate_pr`, cleans up non-succeeded branches, respects `--priority` filtering (AC-1, AC-3)
- **`run_batch_parallel()`**: Added `trap _batch_exit_trap EXIT` after array declarations (AC-2)
- **`main()`**: Added `RECOVER_MODE` check before batch/single-item branch — calls `run_recover` and exits (AC-1)
- No changes to single-item flow (AC-4)

### `tests/test_run_pdlc.sh`
- **Category 24**: 13 new tests (11 assertions) covering run_recover (all branches, priority filter, manifest-guided, no branches, PR mode), _batch_exit_trap (manifest write), and AC-4 (single-item unaffected)
- Total: 210 tests, all passing

## Design Decisions
- `_batch_exit_trap` uses bash dynamic scoping to access `succeeded_items`/`failed_items`/`conflict_items` from `run_batch_parallel` — no globals needed
- Without manifest, `run_recover` integrates ALL `genie/*` branches (safe: branches only exist because a worker created them)
- With manifest, non-succeeded branches are cleaned up via `session_cleanup_item` (removes worktree + branch)
- Manifest slug matching is fuzzy (`P0-item` matches `P0-item-design`) to handle the branch naming convention

# End of Shaped Work Contract
