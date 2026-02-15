---
type: backlog
priority: P2
status: shaped
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

- AC-1: `preflight_checks()` validates claude CLI, gh auth (PR mode only), git repo state, and interactive hook detection before execution
- AC-2: Preflight failure exits 3 with actionable error message; warnings are non-fatal
- AC-3: `session_cleanup` and `session_cleanup_item` call `git worktree prune` before branch deletion
- AC-4: Operator guide documents environment prep, monitoring, and recovery for batch runs

## Files

- `scripts/genies` — preflight function, called before `run_single` and `run_batch_parallel`
- `scripts/genie-session` — add `git worktree prune` to cleanup functions
- `commands/run.md` or `docs/guides/batch-operations.md` — operator guide
- `tests/test_run_pdlc.sh` — preflight tests
- `tests/test_session.sh` — worktree prune tests

# End of Shaped Work Contract
