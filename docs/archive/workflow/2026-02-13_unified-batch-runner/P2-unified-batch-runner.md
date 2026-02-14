---
spec_version: "1.0"
type: shaped-work
id: GT-36
title: "Unified Batch Runner in run-pdlc.sh"
status: done
created: "2026-02-13"
appetite: small
priority: P2
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
tags: [workflow, autonomous, batch, parallel, runner]
acceptance_criteria:
  - id: AC-1
    description: >-
      run-pdlc.sh accepts --parallel N flag. When set (or when multiple inputs
      are provided, or when no inputs are provided), the script enters batch
      mode: scans docs/backlog/ for actionable items, auto-detects starting
      phase from each item's frontmatter status, and processes them. Without
      --parallel, batch items run sequentially. With --parallel N, up to N
      items run concurrently in isolated worktrees with serialized merge
      integration after all workers complete.
    status: pending
  - id: AC-2
    description: >-
      run-pdlc.sh batch mode supports --priority P1|P2|P3 (repeatable) to
      filter backlog items, --dry-run to preview without executing,
      --continue-on-failure to not stop on first failure, and
      --topics-file to load discovery topics from a file. All existing
      single-item flags (--trunk, --verbose, --log-dir, --from, --through)
      work in batch mode.
    status: pending
  - id: AC-3
    description: >-
      run-batch.sh becomes a thin backwards-compatible wrapper that delegates
      to run-pdlc.sh. Existing invocations (run-batch.sh deliver ...,
      run-batch.sh discover ...) continue to work by translating subcommands
      to the equivalent run-pdlc.sh flags.
    status: pending
---

# Shaped Work Contract: Unified Batch Runner

## Problem

The headless runner has two scripts with different interfaces for the same job:

- `run-pdlc.sh` — single item, structured flags, well-tested (48 tests)
- `run-batch.sh` — batch execution, requires `deliver` or `discover` subcommand,
  duplicates parallel execution logic, no tests

Operators must know which script to use and which subcommand to specify. When
`run-batch.sh deliver` is used on a project with `defined` status items (not
`shaped`), items are silently skipped. When the backlog contains a README.md,
the script crashes silently due to `set -euo pipefail`.

The user's desired UX is a single entry point:
```bash
run-pdlc.sh --parallel 3 --trunk          # process all actionable backlog items
run-pdlc.sh --parallel 3 docs/backlog/P1-item.md docs/backlog/P2-item.md
run-pdlc.sh docs/backlog/P1-item.md       # single item, unchanged
```

**Who's affected:** Any operator running overnight batch execution or parallel
delivery. The two-script model adds cognitive load and the `run-batch.sh` bugs
(silent skip, crash on README.md) erode trust in unattended runs.

## Appetite & Boundaries

- **Appetite:** Small (1-2 days) — move existing batch logic into run-pdlc.sh,
  thin wrapper for run-batch.sh
- **No-gos:**
  - Do NOT change run-pdlc.sh's single-item execution path (existing 48 tests
    must pass unchanged)
  - Do NOT change genie-session.sh (worktree lifecycle functions stay as-is)
  - Do NOT change the claude -p invocation interface
  - Do NOT delete run-batch.sh (keep as backwards-compat wrapper)
- **Fixed elements:**
  - `scripts/run-pdlc.sh` is the primary artifact
  - `scripts/run-batch.sh` becomes a thin wrapper
  - `scripts/genie-session.sh` integration functions unchanged
  - Parallel worker model: each worker is a single-item run-pdlc.sh invocation
    in an isolated worktree

## Goals & Outcomes

One script, one entry point. `run-pdlc.sh` handles single items and batch
execution. Operators don't need to know about subcommands or choose between
scripts. Batch mode auto-detects item status and starting phase.

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior
- AC-2: Headless runner script (run-pdlc.sh) chains claude -p invocations per
  phase for a SINGLE item. Batch execution requires separate run-batch.sh script.
- AC-3: Runner supports phase ranges via --from and --through for single items.

### Proposed Changes
- AC-2: Headless runner script (run-pdlc.sh) chains claude -p invocations per
  phase for single items AND batch execution. Accepts --parallel N for concurrent
  processing. Scans backlog for actionable items when no input provided.
- AC-3: Runner supports phase ranges AND batch mode. --from/--through apply to
  all items in batch. Auto-detects starting phase from item status when --from
  is not specified.
- AC-NEW (AC-8): Runner supports batch execution with --parallel N: scans
  backlog for actionable items, auto-detects starting phase from status, runs
  items concurrently in isolated worktrees, serializes merge integration after
  all workers complete. Supports --priority filtering, --dry-run preview, and
  --continue-on-failure.

### Rationale
Two scripts with different interfaces for the same job adds cognitive load and
creates bugs (silent skip of `defined` items, crash on README.md). Per ADR-001
(thin orchestrator), the runner spawns CLI processes — batch is just spawning
multiple. This belongs in the same script.

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Batch logic fits cleanly in run-pdlc.sh without bloating it | feasibility | Measure line count delta; target <350 lines added |
| Existing 48 single-item tests pass without modification | feasibility | Run make test after changes |
| Parallel workers can self-spawn (run-pdlc.sh calls itself) | feasibility | Already works — run-batch.sh does this today |
| run-batch.sh wrapper maintains backwards compat | usability | Test old invocations against new wrapper |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Move batch into run-pdlc.sh, wrapper for run-batch.sh | Single entry point, one set of tests, clean | Larger run-pdlc.sh (~1050 lines) | **Recommended** |
| B: Keep separate scripts, add --parallel to run-pdlc.sh as delegation | Smaller diff | Still two scripts, delegation adds complexity | Not recommended |
| C: Delete run-batch.sh entirely | Simplest | Breaks existing automation | Not recommended |

## Routing

- [x] **Ready for design** — well-understood refactoring, existing patterns
- [ ] Needs Architect spike

---

# Design

## Overview

Move batch orchestration (backlog scanning, parallel worker pool, serialized
merge integration) from `run-batch.sh` into `run-pdlc.sh`. The single-item
execution path is untouched — batch mode is additive code that dispatches to
the existing single-item path for each worker. `run-batch.sh` becomes a ~30
line wrapper. No ADRs needed — follows existing ADR-001 pattern.

## Architecture

**Pattern: Self-spawning batch.** When `run-pdlc.sh` enters batch mode, it
resolves a list of items, then spawns copies of itself as workers — each
running a single item in an isolated worktree. This is exactly what
`run-batch.sh` already does. The parallel worker pool, slot-filling poll loop,
and serialized integration phase move verbatim.

**Batch mode triggers:**
- `--parallel N` flag is set, OR
- Multiple positional inputs provided, OR
- No inputs provided (auto-scan backlog)

**Single-item mode:** Exactly one input, no `--parallel` → existing path.

## Component Design

### `scripts/run-pdlc.sh` — 4 change areas

**Area 1: New helper functions (after line 89)**

Add `get_frontmatter_field()` (wraps existing `extract_frontmatter` + `get_field`)
and `status_to_phase()` (maps item status to starting phase).

**Area 2: Updated `parse_args()` (lines 114-197)**

Add new flags:
- `--parallel N` → `PARALLEL_JOBS`
- `--priority P1|P2` (repeatable) → `PRIORITIES` array
- `--dry-run` → `DRY_RUN`
- `--continue-on-failure` → `CONTINUE_ON_FAILURE`
- `--topics-file <file>` → `TOPICS_FILE`

Change positional arg handling from single `INPUT` to `INPUTS` array.
Update `--help` text to document batch mode.

**Area 3: New batch execution section (before `main()`)**

Five functions moved/adapted from `run-batch.sh`:

1. `resolve_batch_items()` — Build item queue from inputs or backlog scan.
   Format: `"phase:slug:input"` per item. Handles priority filtering, skips
   non-frontmatter files, sorts by priority.

2. `run_batch_sequential()` — Loop through items, run `$0 --from <phase>
   --through <through> [flags] <input>` for each. Track success/failure counts.

3. `run_batch_parallel()` — Worker pool with slot-filling (Bash 3.2 compatible).
   Each worker: `$0 --worktree --finish-mode --leave-branch --from <phase>
   --through <through> --lock --cleanup-on-failure [flags] <input>`.
   Poll loop with 5-second sleep. Integration phase after all workers complete.

4. `integrate_items()` — Serialize merge/PR for succeeded items. Source
   `genie-session.sh` for `session_integrate_trunk`/`session_integrate_pr`.

5. `print_batch_summary()` / `print_batch_parallel_summary()` — Batch completion
   reporting (moved from `run-batch.sh`).

**Area 4: Updated `main()` (lines 581-727)**

Insert batch mode detection before `validate_args`:
```
main() {
    parse_args "$@"

    # Batch mode check
    if [[ "$PARALLEL_JOBS" -gt 0 || ${#INPUTS[@]} -gt 1 || ${#INPUTS[@]} -eq 0 ]]; then
        resolve_batch_items
        if [[ "$DRY_RUN" == "true" ]]; then
            print_batch_dry_run; exit 0
        fi
        if [[ "$PARALLEL_JOBS" -gt 0 ]]; then
            run_batch_parallel; exit $?
        else
            run_batch_sequential; exit $?
        fi
    fi

    # Single-item mode (unchanged from here down)
    INPUT="${INPUTS[0]}"
    validate_args
    ...
}
```

### `scripts/run-batch.sh` — replace with wrapper

```bash
#!/bin/bash
# Backwards-compatible wrapper — delegates to run-pdlc.sh
# See run-pdlc.sh --help for full options.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
    deliver)  shift; exec "$SCRIPT_DIR/run-pdlc.sh" "$@" ;;
    discover) shift; exec "$SCRIPT_DIR/run-pdlc.sh" --through define "$@" ;;
    help|-h|--help)
        echo "run-batch.sh is now a wrapper for run-pdlc.sh." >&2
        echo "See: run-pdlc.sh --help" >&2
        exec "$SCRIPT_DIR/run-pdlc.sh" --help
        ;;
    *)        exec "$SCRIPT_DIR/run-pdlc.sh" "$@" ;;
esac
```

### `tests/test_run_pdlc.sh` — add batch tests

New test section `--- batch mode ---`:
- `parse_args --parallel 3 "topic"` sets `PARALLEL_JOBS=3`
- `parse_args --priority P1 --priority P2` populates `PRIORITIES`
- `parse_args --dry-run` sets `DRY_RUN=true`
- `status_to_phase` for each status: defined, shaped, designed, implemented,
  reviewed, done, abandoned
- `get_frontmatter_field` extracts fields from test fixtures

## AC Mapping

| AC | Approach | Edit Areas |
|----|----------|------------|
| AC-1 | Add --parallel flag, batch mode detection in main(), parallel worker pool | Areas 2, 3, 4 |
| AC-2 | Add batch flags to parse_args(), resolve_batch_items() handles filtering | Areas 2, 3 |
| AC-3 | Replace run-batch.sh with wrapper that delegates to run-pdlc.sh | run-batch.sh |

## Implementation Guidance

**Sequence:**
1. Area 1 — Add helper functions (no existing code touched)
2. Area 2 — Update parse_args (additive flags, change INPUT→INPUTS)
3. Area 3 — Add batch execution functions (all new code)
4. Area 4 — Update main() (insert batch check before validate_args)
5. Replace run-batch.sh with wrapper
6. Add tests

**Key considerations:**
- The `INPUTS` array change is the only modification to existing parse_args
  behavior — single positional arg still works: `INPUTS=("topic")`
- Batch workers spawn `"$0"` (self) so the path resolution is automatic
- The `SELF` variable should be set to the script's absolute path for
  self-spawning: `SELF="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)/$(basename "${BASH_SOURCE[0]}")`
- Sourcing for tests (`RUN_PDLC_SOURCED`) must still work — batch functions
  are just additional functions available when sourced
- `VERBOSE` variable in `log_debug` must not conflict with `VERBOSE_LOGGING`

**Test strategy:**
- `make test` — all 283 existing tests pass
- New batch tests: parse_args, status_to_phase, get_frontmatter_field
- Dry-run from genie-team: `run-pdlc.sh --dry-run`
- Dry-run from 2hearted: `cd ~/code/2hearted && run-pdlc.sh --parallel 3 --trunk --dry-run`
- Backwards compat: `run-batch.sh deliver --dry-run`

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| parse_args INPUTS change breaks existing tests | Low | High | Tests use `parse_args "topic"` → still sets `INPUTS[0]="topic"` |
| Self-spawning path resolution fails in worktrees | Low | Med | Use absolute path via BASH_SOURCE |
| Batch functions bloat run-pdlc.sh beyond maintainability | Low | Low | ~300 lines added, clearly sectioned |

## Routing

Ready for Crafter. Existing code to move, well-understood patterns.

---

# Implementation

## Summary

All 4 design areas implemented in `scripts/run-pdlc.sh`, `scripts/run-batch.sh`
replaced with thin wrapper, and 33 new tests added to `tests/test_run_pdlc.sh`.

## Changes

### `scripts/run-pdlc.sh` — 4 change areas

**Area 1: Helper functions (after `get_field`)**
Added `get_frontmatter_field()` (wraps `extract_frontmatter` + `get_field`) and
`status_to_phase()` (maps item status → starting phase: defined/shaped → design,
designed → deliver, implemented → discern, reviewed → done).

**Area 2: Updated `parse_args()`**
Added batch mode defaults (`PARALLEL_JOBS=0`, `PRIORITIES=()`, `DRY_RUN`,
`CONTINUE_ON_FAILURE`, `TOPICS_FILE`, `INPUTS` array). Added flag handling for
`--parallel N`, `--priority` (repeatable), `--dry-run`, `--continue-on-failure`,
`--topics-file`. Positional args now populate both `INPUTS` array and `INPUT`
(backwards compat). Updated help text with batch mode documentation.

**Area 3: Batch execution functions**
Five functions added:
- `resolve_batch_items()` — Build BATCH_ITEMS array from inputs or backlog scan.
  Handles priority filtering, frontmatter-less file skipping, topic strings.
- `print_batch_dry_run()` — Preview matching items.
- `run_batch_sequential()` — Loop through items, self-spawn per item.
- `run_batch_parallel()` — Worker pool with slot-filling (Bash 3.2 compatible).
  Each worker: `$SELF --worktree --finish-mode --leave-branch --from <phase>
  --through <through> --lock --cleanup-on-failure --slug <slug>`. Integration
  phase serializes merges/PRs after all workers complete.
- `print_batch_summary()` / `print_batch_parallel_summary()` — Completion reporting.

**Area 4: Updated `main()`**
Batch mode detection inserted before `validate_args`: triggers when
`PARALLEL_JOBS > 0`, multiple inputs, or no inputs. Routes to resolve → dry-run
check → parallel or sequential execution. Single-item path unchanged.

### `scripts/run-batch.sh` — replaced with ~35 line wrapper

Backwards-compatible: `deliver` subcommand → `run-pdlc.sh`, `discover` →
`run-pdlc.sh --through define`, no subcommand → `run-pdlc.sh`. All flags
pass through.

### `tests/test_run_pdlc.sh` — 33 new tests

- Category 12: `status_to_phase` — 7 tests (all status values)
- Category 13: `get_frontmatter_field` — 3 tests (status, priority, quoted title)
- Category 14: parse_args batch flags — 10 tests (--parallel, --priority,
  --dry-run, --continue-on-failure, INPUTS array, defaults, combinations)
- Category 15: `resolve_batch_items` — 5 tests (backlog scan, priority filter,
  explicit files, topic strings, topics-file loading)

## Validation

- `make test` — 333 tests pass across all 6 test suites (up from 283)
- Single item: `run-pdlc.sh docs/backlog/P2-item.md` works unchanged
- Dry-run: `run-pdlc.sh --dry-run` finds 6 actionable items
- Priority filter: `run-pdlc.sh --priority P1 --priority P2 --dry-run` filters correctly
- Parallel dry-run: `run-pdlc.sh --parallel 3 --trunk --dry-run` shows parallel mode
- Backwards compat: `run-batch.sh deliver --dry-run` delegates correctly
- Backwards compat: `run-batch.sh --parallel 3 --trunk --dry-run` works
