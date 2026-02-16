---
type: backlog
priority: P2
status: done
concept: autonomous-lifecycle
enhancement: batch-operator-hardening
created: 2026-02-15
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
source: https://github.com/npatterson/genie-team/issues/4
tags: [batch, resilience, preflight, worktree, operator]
---

# P2: Batch Operator Hardening

## Problem

Batch runs are expensive ($10-100+) and long-running (hours). When they fail due to avoidable environment issues — unauthenticated `gh`, interactive git hooks blocking headless execution, stale worktree references — the operator discovers the problem only after wasting significant time and tokens. There's no upfront validation, and worktree cleanup has a known gap with `git worktree prune`.

Evidence: Two field reports (2hearted overnight run, osrs-companion calculator batch) both hit environment issues that could have been caught before execution started.

## Appetite

Small batch: 1-2 days. Three discrete, low-risk changes.

## Solution Sketch

### 1. Preflight validation function

Add `preflight_checks()` to `scripts/genies` that runs before any batch or single-item execution. Checks:

- `claude` CLI is on PATH
- `gh auth status` succeeds (if PR mode, skip in trunk-based mode)
- Current directory is a git repo with a clean working tree (or warn)
- No stale lock files (`.claude/session-lock`)
- Common interactive hook tools (lefthook, husky) are detected — warn if `LEFTHOOK=0` / `HUSKY=0` not set

Exit with code 3 (validation error) if any critical check fails. Warnings are non-fatal but logged.

### 2. Add `git worktree prune` to cleanup paths

Add `git worktree prune` to `session_cleanup` and `session_cleanup_item` in `scripts/genie-session`, before attempting branch deletion. This clears stale worktree references when a worktree directory was manually deleted, preventing "fatal: '{path}' is a missing but locked worktree" errors that block branch operations.

### 3. Operator guide for batch execution

Add a section to `commands/run.md` (or a standalone `docs/guides/batch-operations.md`) documenting:

- Environment prep: disable interactive hooks, ensure `gh auth`, prevent machine sleep
- Monitoring: `tail -f` worker logs, check `batch-manifest.json`
- Recovery: `--recover` for leftover branches, `session cleanup` for stale worktrees

## Rabbit Holes

- Don't build a real-time dashboard or TUI — `tail -f` and the batch manifest cover monitoring needs
- Don't auto-disable git hooks — that's operator responsibility, we just warn
- Don't add checkpoints beyond what `--recover` already provides

## Acceptance Criteria

- AC-1: `preflight_checks()` validates claude CLI, gh auth (PR mode only), and git repo state before execution
- AC-2: Preflight failure exits 3 with actionable error message; warnings are non-fatal
- AC-3: `session_cleanup` and `session_cleanup_item` call `git worktree prune` before branch deletion
- AC-4: Operator guide documents environment prep, monitoring, and recovery for batch runs

## Files

- `scripts/genies` — preflight function, called before `run_single` and `run_batch_parallel`
- `scripts/genie-session` — add `git worktree prune` to cleanup functions
- `commands/run.md` or `docs/guides/batch-operations.md` — operator guide
- `tests/test_run_pdlc.sh` — preflight tests
- `tests/test_session.sh` — worktree prune tests

# Design

## Design Summary

Three independent changes that harden the batch execution path. No new components, no architectural decisions — all changes are additions to existing functions.

## Component Design

### 1. `preflight_checks()` in `scripts/genies`

New function, called from `main()` after `parse_args` and before any execution path (batch, single, recover).

```bash
preflight_checks()
```

**Check sequence** (order matters — cheapest/most-likely-to-fail first):

| # | Check | Type | Condition |
|---|-------|------|-----------|
| 1 | `command -v claude` | FATAL | Always |
| 2 | Git repo | FATAL | `git rev-parse --git-dir` succeeds |
| 3 | `gh auth status` | FATAL | Only when `TRUNK_MODE != "true"` (PR mode needs gh) |
| 4 | Dirty working tree | WARN | `git status --porcelain` is non-empty |
| 5 | Lefthook detected | WARN | `command -v lefthook` succeeds AND `LEFTHOOK` env var is unset or not `"0"` |
| 6 | Husky detected | WARN | `.husky/` directory exists AND `HUSKY` env var is unset or not `"0"` |

FATAL checks accumulate errors and exit 3 after all checks run (not on first failure — show all problems at once). WARN checks log with `log_warn` and continue.

**Skipping preflight:** Add `--no-preflight` flag to `parse_args` for environments where the operator knows what they're doing (CI containers, etc.). Default: preflight runs.

**Call site:** Insert in `main()` at line ~1520, after `parse_args` and before the recovery/batch/single branch:

```bash
main() {
    parse_args "$@"

    # Preflight environment validation
    if [[ "${NO_PREFLIGHT:-false}" != "true" ]]; then
        preflight_checks
    fi

    # Recovery mode...
```

### 2. `git worktree prune` in `scripts/genie-session`

Add a single line to `session_cleanup_item()` before the worktree remove + branch delete sequence. The prune clears git's internal tracking of worktrees whose directories no longer exist on disk.

```bash
session_cleanup_item() {
    local item="${1:?Usage: session_cleanup_item <item>}"
    local worktree_dir branch repo_root

    repo_root=$(_gs_repo_root 2>/dev/null) || { _gs_log "Cleaned up: $item"; return 0; }

    # Prune stale worktree references before cleanup
    git -C "$repo_root" worktree prune 2>/dev/null || true

    worktree_dir=$(_gs_worktree_dir "$item" 2>/dev/null) || true
    branch=$(_gs_find_branch "$item" 2>/dev/null) || true
    # ... rest unchanged
```

Not added to `session_cleanup()` separately — it calls `session_cleanup_item` per item, so prune runs naturally. Adding it there too would be redundant.

### 3. Operator guide section in `commands/run.md`

Append an `## Operator Guide: Batch Execution` section to the existing `/run` command documentation. This keeps all runner docs in one place rather than creating a separate file.

Contents:
- **Before running**: environment checklist (gh auth, hooks, sleep, disk space)
- **Monitoring**: `tail -f` worker logs, `batch-manifest.json` structure
- **Recovery**: `--recover`, `genies session cleanup`, manual branch cleanup

## Integration Points

- `preflight_checks` reads `TRUNK_MODE` which is already set by `parse_args`
- `preflight_checks` uses existing `log_error` and `log_warn` helpers
- `git worktree prune` is a standard git command, no dependencies
- Operator guide is documentation only

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| `gh auth status` is slow (network call) | Low | Low preflight delay | It's typically <1s; acceptable for a preflight that prevents hours of wasted work |
| False positive hook detection (lefthook installed globally but not configured for this repo) | Low | Noisy warning | Warn only, non-fatal. Operator can use `--no-preflight` |

## Implementation Guidance

### Order of implementation

1. **Worktree prune** (AC-3) — one line, test it
2. **Preflight function** (AC-1, AC-2) — function + flag + tests
3. **Operator guide** (AC-4) — documentation, no code

### Test design

**Preflight tests** (`tests/test_run_pdlc.sh`):
- `preflight: passes when claude and git available` — mock `command -v` to succeed
- `preflight: fails exit 3 when claude missing` — mock `command -v claude` to fail
- `preflight: fails exit 3 when not in git repo` — run in temp dir without .git
- `preflight: warns on dirty working tree` — create uncommitted file, check log output
- `preflight: warns on lefthook without LEFTHOOK=0` — mock `command -v lefthook` to succeed
- `preflight: skipped with --no-preflight` — verify function not called
- `preflight: skips gh check in trunk mode` — set TRUNK_MODE=true, mock gh to fail, verify no error

**Worktree prune tests** (`tests/test_session.sh`):
- `session_cleanup_item: prunes stale worktree references` — create worktree, manually `rm -rf` the directory (simulating crash), verify cleanup succeeds without "locked worktree" error

### Scope discipline

- No changes to phase execution, batch logic, or integration
- Preflight is strictly pre-execution validation
- Worktree prune is a one-liner in an existing function
- Guide is appended to existing docs

# Implementation

## Changes

### 1. Preflight validation (AC-1, AC-2)

- `scripts/genies`: Added `log_warn()` helper, `preflight_checks()` function with 4 checks (3 fatal: claude, git, gh; 1 warn: dirty tree), `--no-preflight` flag, wired into `main()` before all execution paths
- `tests/test_run_pdlc.sh`: 6 new tests covering flag parsing, pass/fail scenarios, trunk mode gh skip

### 2. Worktree prune (AC-3)

- `scripts/genie-session`: Added `git worktree prune` to `session_cleanup_item()` before worktree removal and branch deletion
- `tests/test_session.sh`: 2 new tests — verifies stale reference exists, then verifies cleanup succeeds despite it

### 3. Operator guide (AC-4)

- `commands/run.md`: Appended "Operator Guide: Batch Execution" section with environment prep, monitoring, and recovery instructions

# End of Shaped Work Contract
