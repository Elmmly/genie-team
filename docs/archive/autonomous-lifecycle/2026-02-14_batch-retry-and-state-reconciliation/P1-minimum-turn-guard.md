---
spec_version: "1.0"
type: shaped-work
id: P1-minimum-turn-guard
title: "Minimum-Turn Phase Validation"
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
      After a phase completes, the runner checks whether the turn count meets a
      minimum threshold for that phase; if below minimum, the phase is flagged as
      anomalous in the structured log with a warning message
    status: pending
  - id: AC-2
    description: >-
      The deliver phase has a minimum turn threshold of 3 turns; completion below
      this threshold triggers a single automatic retry (fresh session, not --resume)
      to give Claude a second chance at meaningful work
    status: pending
  - id: AC-3
    description: >-
      If the retry also completes below the minimum threshold, the runner logs an
      error and treats the phase as failed (exit 1), preventing silent waste
    status: pending
  - id: AC-4
    description: >-
      Minimum turn thresholds are configurable per phase via the existing per-phase
      override mechanism (e.g., --deliver-min-turns 5), with sensible defaults only
      for deliver (3 turns); other phases default to 0 (no minimum)
    status: pending
---

# Shaped Work Contract: Minimum-Turn Phase Validation

## Problem

The autonomous runner has no way to detect when a phase completes without doing meaningful work. On the 2hearted batch run, the deliver phase for one item completed in **1 turn** — Claude read the input context (~$15 of input tokens) but produced no code, no tests, and no artifacts. The runner treated this as a successful delivery and continued to the discern phase, which then failed because there was nothing to review.

This is a silent waste pattern: expensive input context is consumed, but no value is produced. The runner can't distinguish "deliver completed quickly because the work was trivial" from "deliver read context and immediately exited without acting."

## Evidence

- **2hearted Batch 3**: P2-personality-profiler-onboarding deliver phase completed in 1 turn with high token cost (input context read, no output)
- **Cost**: ~$15 wasted on input tokens with zero useful work
- **Downstream effect**: Discern phase had nothing to review, cascading failure
- **Pattern**: Deliver is the most expensive phase (50-65% of total run cost) and the most impactful to validate

## Appetite & Boundaries

- **Appetite:** Small batch (1 day)
- **No-gos:**
  - No content analysis of phase output (too complex, fragile)
  - No per-phase cost tracking (separate concern)
  - No modification to `claude -p` invocation (runner can only observe turn count)
  - No minimum thresholds for discover/define/discern/done/commit (these phases legitimately complete in 1-2 turns)
- **Fixed elements:**
  - `PHASE_NUM_TURNS` is already captured after each `run_phase` call
  - `retry_phase()` already exists for turn-exhaustion retries
  - `log_phase_usage()` already logs turn counts

## Goals & Outcomes

- The deliver phase is validated for minimum meaningful work before continuing
- Anomalous completions trigger one retry before failing
- Operators see clear warnings in logs when phases complete suspiciously fast

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| 1-turn deliver is always anomalous (never legitimate) | Value | Review: deliver must at minimum write tests + implementation — 1 turn can't do that |
| 3 turns is a safe minimum for deliver | Value | Review: even a tiny delivery needs test write + run + implement — 3 is conservative |
| Fresh session retry (not --resume) is more effective for anomalous exits | Feasibility | --resume would continue the same stuck context; fresh gives a clean start |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| Post-phase turn count check with retry | Simple, uses existing infrastructure, catches the observed failure mode | Doesn't detect all anomalies (e.g., many turns but no artifacts) | **Recommended** — addresses the observed problem directly |
| Output content analysis (check for test files, code changes) | More thorough detection | Fragile, complex, different per phase | Over-engineered for now |
| Pre-set minimum in claude -p invocation | Prevents the problem at source | No such flag exists in claude CLI | Not feasible |

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior
- AC-6: "Runner implements responsible execution: per-phase turn limits... automatic single retry with --resume on phase exhaustion"

### Proposed Changes
- AC-6: Enhanced — responsible execution now includes minimum-turn validation in addition to maximum-turn limits. Turn count below minimum triggers retry with fresh session (not --resume), then failure if retry also below minimum.
- New design constraint: Minimum turn thresholds per phase (deliver=3, all others=0)

### Rationale
AC-6 focuses on the ceiling (max turns) but not the floor (min turns). Both are needed for responsible execution — max-turns prevents runaway cost, min-turns prevents silent waste.

## Solution Sketch

1. **Add `MIN_TURNS` array** alongside existing `DEFAULT_TURNS`: `MIN_TURNS=(0 0 0 3 0 0 0)` (only deliver has a minimum)
2. **Post-phase check** after `run_phase` returns success: if `PHASE_NUM_TURNS < MIN_TURNS[phase]`, log warning and retry with `--no-resume` (fresh session)
3. **Retry check**: if retry also below minimum, log error and exit 1
4. **Override flags**: `--deliver-min-turns N` for operator tuning

## Routing

→ Crafter (small, well-scoped — add array, add check after run_phase, add override flag)

## Dependencies

- `PHASE_NUM_TURNS` variable (already captured per phase)
- `retry_phase()` function (already exists, may need `--no-resume` variant)

# Implementation

## Changes

### `scripts/genies`
- **`MIN_TURNS` array**: Added alongside `DEFAULT_TURNS`: `(0 0 0 3 0 0 0)` — only deliver has a minimum (AC-1, AC-2)
- **`get_min_turns()`**: Returns minimum turns for a phase, checking per-phase override then default (AC-4)
- **`check_min_turns()`**: Returns 0 if `PHASE_NUM_TURNS >= minimum`, returns 1 if below with warning log (AC-1)
- **`--deliver-min-turns` flag**: Parsed in `parse_args`, stored in `DELIVER_MIN_TURNS`, read by `get_min_turns` (AC-4)
- **Phase loop min-turn check**: After successful `run_phase`, calls `check_min_turns`. If below minimum, retries with fresh session (`SESSION_ID=""` before `run_phase`). If retry also below minimum, exits 1 (AC-2, AC-3)

### `tests/test_run_pdlc.sh`
- **Category 22**: 13 new tests covering MIN_TURNS defaults, get_min_turns, check_min_turns, --deliver-min-turns override
- Total: 197 tests, all passing

## Design Decisions
- Fresh session retry (clear SESSION_ID) instead of `--resume` — avoids continuing the same stuck context
- Only deliver has a non-zero minimum (3 turns) — other phases legitimately complete in 1-2 turns
- The min-turn check runs AFTER the phase succeeds (exit 0) — failed phases are handled by the existing error path

# Review
<!-- Added by /discern on 2026-02-14 -->

**Verdict:** APPROVED
**ACs verified:** 4/4 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `check_min_turns()` (line 546) logs warning via `log_info` when `PHASE_NUM_TURNS < min`. Phase loop calls `check_min_turns` after successful `run_phase` (line 1527). 2 tests cover pass/fail cases. |
| AC-2 | met | Deliver minimum is 3 (`MIN_TURNS=(0 0 0 3 0 0 0)` line 23). Below-minimum triggers retry with fresh session (`SESSION_ID=""` line 1529, then `run_phase` line 1530). Test verifies default. |
| AC-3 | met | If retry also below minimum, `log_error` and `exit 1` (lines 1540-1546). Worktree cleanup handled on failure path. |
| AC-4 | met | `--deliver-min-turns` flag parsed (line 286), stored in `DELIVER_MIN_TURNS`, read by `get_min_turns` (line 532). Test confirms override. Other phases default to 0 (no minimum). |

**Code quality:** Good. Clean separation: `get_min_turns` for lookup, `check_min_turns` for validation, phase loop for orchestration. Fresh session retry (clear `SESSION_ID`) is the right approach — avoids continuing stuck context.
**Test coverage:** 13 new tests, all passing.
**Security:** No concerns.
**Performance:** Negligible — comparison of two integers.

# End of Shaped Work Contract
