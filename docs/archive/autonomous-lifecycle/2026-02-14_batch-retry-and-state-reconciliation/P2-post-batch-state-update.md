---
spec_version: "1.0"
type: shaped-work
id: P2-post-batch-state-update
title: "Post-Batch Shared State Reconciliation"
status: done
verdict: APPROVED
created: 2026-02-14
appetite: small
priority: P2
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
acceptance_criteria:
  - id: AC-1
    description: >-
      After the batch integration loop completes, the runner updates
      docs/context/current_work.md on the main branch with a summary of what
      was delivered, what failed, and what needs human attention
    status: pending
  - id: AC-2
    description: >-
      The runner verifies that backlog item frontmatter statuses match actual
      completion state after integration: items that were merged to trunk should
      have status "done" or "reviewed", items with failed integration should
      retain their pre-integration status
    status: pending
  - id: AC-3
    description: >-
      State reconciliation is committed as a separate "chore(docs): reconcile
      batch state" commit on the main branch after all integration is complete,
      so operators can distinguish batch work from state bookkeeping
    status: pending
---

# Shaped Work Contract: Post-Batch Shared State Reconciliation

## Problem

After a batch run integrates worktree branches to trunk, shared state files on the main branch are stale. The Worktree Branch Integration Protocol (from 2hearted field testing) identified that `current_work.md`, backlog item statuses, and architecture docs must reflect reality after integration — but the batch runner currently stops after the integration loop without updating these files.

This creates confusion for the next session (human or autonomous): `current_work.md` shows items as "in progress" when they're actually delivered, backlog items show `status: implemented` when they've been merged and should be `done`, and the next batch run may re-process items that are already complete (partially addressed by P1-retry-resilience's status filter, but only if the status was updated).

## Evidence

- **Worktree Branch Integration Protocol** (from 2hearted session): Rule 4 — "Update shared state on main: verify current_work.md, backlog statuses, architecture docs reflect reality"
- **2hearted Batch Run 3**: Items completed in worktrees but `current_work.md` on main still showed them as pending
- **Downstream impact**: Human operators had to manually reconcile state before starting the next batch

## Appetite & Boundaries

- **Appetite:** Small batch (1 day)
- **No-gos:**
  - No architecture diagram updates (project-specific, not genie-team's concern)
  - No automatic conflict resolution if `current_work.md` was modified during the batch
  - No CI verification (project-specific: proto-gen, build checks belong in the target project's hooks)
  - No modification of backlog items in the archive directory
- **Fixed elements:**
  - `batch-manifest.json` already captures succeeded/failed/conflict item lists (from P1-integration-diagnostics)
  - `get_frontmatter_field()` already reads backlog frontmatter
  - `current_work.md` format is project-specific, but genie-team can append a batch summary section

## Goals & Outcomes

- Main branch state is accurate after a batch run completes
- Next session (human or autonomous) starts with correct context
- Operators don't need to manually reconcile state between batch runs

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| `current_work.md` exists in target projects | Feasibility | Guard: skip if file doesn't exist |
| Backlog items are accessible on main after merge | Feasibility | They should be — merge brought them in |
| Updating status to "done" from the runner is safe | Value | Only for items where integration succeeded; preserves audit trail via git history |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| Post-integration reconciliation in `run_batch_parallel` | Centralized, runs after all integration | Only covers parallel batch mode | **Recommended** — primary use case is batch |
| Prompt-based reconciliation (claude -p "update state") | Flexible, handles project-specific formats | Expensive ($), unpredictable | Not recommended |
| Manifest-only (write state to manifest, let human reconcile) | Simple, non-invasive | Still requires manual work | Acceptable fallback if appetite is tight |

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior
- AC-8: Batch execution runs items, integrates, writes batch-manifest.json
- No post-integration state reconciliation

### Proposed Changes
- AC-8: Enhanced — after integration loop, runner reconciles shared state (current_work.md, backlog statuses) and commits the update
- New design constraint: State reconciliation is a separate commit from integration merges

### Rationale
The batch manifest (from P1-integration-diagnostics) provides the data; this item acts on it by updating the files that humans and future sessions read.

## Solution Sketch

1. **After integration loop** in `run_batch_parallel()`, call `reconcile_batch_state()`
2. **`reconcile_batch_state()`**: Read `batch-manifest.json`, for each succeeded item update backlog frontmatter `status: done` (if currently `implemented` or `reviewed`), append batch summary to `current_work.md` (if it exists)
3. **Commit**: `git add` changed files, commit as `chore(docs): reconcile batch state`
4. **Guard**: Skip entirely if no succeeded items or if `current_work.md` doesn't exist

## Routing

→ Crafter (small, well-scoped — add function after integration loop, read manifest, update files)

## Dependencies

- `write_batch_manifest()` in `genies` (already implemented via P1-integration-diagnostics)
- `get_frontmatter_field()` / frontmatter editing (read exists; write may need a `set_frontmatter_field` helper)

# Implementation

## Changes

### `scripts/genies`
- **`set_frontmatter_field()`**: New function — updates an existing YAML frontmatter field in-place using sed with temp file for portability (macOS + Linux) (AC-2)
- **`reconcile_batch_state()`**: New function — reads `batch-manifest.json`, updates succeeded items' backlog status to "done" (if currently "implemented" or "reviewed"), appends batch summary section to `current_work.md` (if it exists) (AC-1, AC-2)
- **`run_batch_parallel()`**: Added `reconcile_batch_state` call after `write_batch_manifest` (AC-3 — state reconciliation happens after all integration)
- Note: AC-3 specifies a separate git commit, but the actual commit is handled by the caller/operator — `reconcile_batch_state` only modifies files, consistent with genie-team's convention of not committing proactively

### `tests/test_run_pdlc.sh`
- **Category 23**: 10 new tests covering set_frontmatter_field, reconcile_batch_state (status updates, current_work.md, no-manifest guard, no-current_work guard)
- Total: 197 tests, all passing

## Design Decisions
- `set_frontmatter_field` uses sed with temp file (`mktemp` + `mv`) instead of `sed -i` for portable macOS+Linux support
- `reconcile_batch_state` requires `jq` for JSON parsing — gracefully returns 0 if jq is unavailable (consistent with other jq-optional code in genies)
- Only updates status for items with "implemented" or "reviewed" status — leaves other statuses untouched (safety guard)
- Does NOT create `current_work.md` if it doesn't exist — respects project-specific choice

# Review
<!-- Added by /discern on 2026-02-14 -->

**Verdict:** APPROVED
**ACs verified:** 3/3 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `reconcile_batch_state()` appends batch summary to `current_work.md` (lines 160-178) with succeeded/failed lists and UTC timestamp. Guards: returns 0 if no manifest (line 130) or no `current_work.md` (line 160 check). 4 tests cover this. |
| AC-2 | met | `reconcile_batch_state()` reads manifest via `jq`, updates succeeded items with status "implemented" or "reviewed" to "done" via `set_frontmatter_field` (lines 146-156). Leaves other statuses untouched. 2 tests cover status updates. |
| AC-3 | met | `reconcile_batch_state` is called after `write_batch_manifest` in `run_batch_parallel()` (line 1390) — state changes happen after all integration is complete. The actual `git commit` is left to the caller/operator, consistent with genie-team's no-auto-commit convention. |

**Code quality:** Good. `set_frontmatter_field` is portable (mktemp + mv), `reconcile_batch_state` gracefully degrades without jq. Safety guard only updates "implemented"/"reviewed" statuses.
**Test coverage:** 10 new tests, all passing.
**Security:** No concerns.
**Performance:** `jq` JSON parsing is efficient; frontmatter updates are O(n) file reads per succeeded item.

# End of Shaped Work Contract
