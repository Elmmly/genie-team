---
id: P1-continuous-overseer
title: Continuous PDLC Overseer
type: feature
status: done
priority: P1
appetite: medium
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
created: 2026-02-26
discovery_ref: null
---

# Shaped Work Contract: Continuous PDLC Overseer

## Problem

The autonomous PDLC pipeline requires constant human babysitting at two failure points, preventing the "walk away and it ships" experience:

1. **Review cycles don't retry.** When `/discern` returns CHANGES REQUESTED, the `genies` CLI stops immediately because `--review-cycles` defaults to `1` (no retry). The deliver-discern fix loop never fires unless the operator remembers to pass `--review-cycles N`. This is the most common stall — the user sees work that was almost done but stopped at the last mile.

2. **Pipeline stops after batch completion.** The `genies` CLI processes all actionable backlog items in one pass, then exits. When the user returns, nothing has happened since that batch finished — even if new work was shaped while the batch was running, or if recovered items became actionable. There's no continuous loop.

3. **No oversight while away.** The operator has no quick way to check what happened while they were gone. They must manually inspect log files, worktree remnants, git branches, and backlog item statuses to reconstruct what the daemon did. There's no dashboard, no status file, no notification.

**Who is affected:** Any operator running `genies` for overnight or while-away execution. The impact compounds with batch size — 3 items means 3 chances to stall at review, 3 sets of artifacts to manually inspect.

**Evidence:** Yesterday's parallel delivery session demonstrated all three issues: P1 stalled with staged-but-uncommitted changes, P2/P3 completed but required manual review/merge/cleanup, and the `bare=true` git config corruption went undetected until this session because there was no status reporting.

## Appetite & Boundaries

- **Appetite:** Medium batch (3-5 days) — meaningful orchestration logic but constrained to bash and the existing `genies` script
- **No-gos:**
  - Do NOT build a web dashboard or notification server
  - Do NOT add cloud infrastructure (no containers, no CI/CD integration yet)
  - Do NOT change the existing `genies` single-run behavior (daemon is additive)
  - Do NOT add aggregate budget tracking across cycles (out of scope — operator responsibility per ADR-001)
  - Do NOT implement topic discovery (auto-generating topics for `/discover`) — the overseer runs what's in the backlog
- **Fixed elements:**
  - Bash script (no Python, Node, or other runtime dependencies)
  - macOS-first (launchd optional, terminal loop primary)
  - The existing `genies` batch/single execution path is unchanged
  - ADR-001 thin orchestrator pattern: the daemon IS the orchestrator

## Goals & Outcomes

- **Primary:** Operator runs `genies daemon` in a terminal, walks away, returns to find completed and merged work with a clear status summary
- **Review cycles resolve:** When critic says CHANGES REQUESTED, crafter fixes and re-submits automatically (up to N cycles) before giving up
- **Continuous operation:** After one batch completes, the daemon sleeps, then scans for newly actionable items and runs another batch — indefinitely until stopped
- **Status at a glance:** A status file (and terminal output) shows: current cycle, items in progress, items completed, items failed, total cost, and last activity timestamp
- **Clean shutdown:** SIGINT/SIGTERM stops the daemon gracefully — finishes current phase, commits work, cleans up worktrees

## Solution Sketch

### 1. `genies daemon` subcommand

A new subcommand that wraps the existing batch execution in a continuous loop:

```
genies daemon [OPTIONS]
  --interval <seconds>    Sleep between cycles (default: 300 = 5 min)
  --max-cycles <N>        Stop after N cycles (default: unlimited)
  --max-cost <dollars>    Stop when cumulative cost exceeds budget (default: unlimited)
  --status-file <path>    Write JSON status to file (default: .genie-daemon-status.json)
  --review-cycles <N>     Review retry cycles (default: 3 in daemon mode)
```

Each cycle: preflight → scan backlog → run batch (parallel or sequential) → write status → sleep → repeat.

### 2. Review cycle default fix

Change `REVIEW_CYCLES` default from `1` to `3` in daemon mode. This means deliver→discern retries up to 3 times on CHANGES REQUESTED before giving up. Keep `1` as default for non-daemon `genies` invocations (backwards compatible).

### 3. Status file

Write a JSON status file after each cycle:

```json
{
  "daemon_pid": 12345,
  "started_at": "2026-02-26T10:00:00Z",
  "current_cycle": 3,
  "last_cycle_at": "2026-02-26T10:15:00Z",
  "cumulative_cost_usd": 12.50,
  "items_completed": ["P1-auth.md", "P2-search.md"],
  "items_failed": ["P3-cache.md"],
  "items_in_progress": [],
  "next_scan_at": "2026-02-26T10:20:00Z",
  "status": "sleeping"
}
```

### 4. Graceful shutdown

Trap SIGINT/SIGTERM. When received:
- If between cycles (sleeping): exit immediately
- If mid-cycle: set a flag, let current item's current phase finish, commit work, clean up worktree, then exit
- Write final status with `"status": "stopped"`

### 5. Terminal status line

During operation, print a one-line status update every 30 seconds:
```
[daemon] Cycle 3 | 2 completed, 1 in progress, 0 failed | $12.50 spent | next scan in 4m
```

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior
- AC-2: Runner chains claude -p per phase, handles errors, produces logs
- AC-8: Runner supports batch execution with --parallel N, scans backlog

### Proposed Changes
- AC-2: No change to single-run behavior
- AC-8: No change to batch behavior
- AC-NEW-1: `genies daemon` subcommand runs continuous cycles of batch execution with configurable interval, cycle limits, and cost budget
- AC-NEW-2: Daemon writes JSON status file after each cycle showing completed/failed/in-progress items, cumulative cost, and next scan time
- AC-NEW-3: Daemon handles SIGINT/SIGTERM gracefully — finishes current phase, commits work, cleans up, writes final status
- AC-NEW-4: Review cycles default to 3 in daemon mode (vs 1 in single-run mode) so CHANGES REQUESTED triggers automatic deliver→discern retry
- AC-NEW-5: `genies daemon stop` reads the status file PID and sends SIGTERM for clean shutdown

### Rationale
The `genies` CLI already handles one-shot batch execution well. The missing piece is the outer loop that makes it continuous, plus the review cycle defaults that make it self-healing. These changes make the autonomous PDLC genuinely autonomous — the operator's involvement drops from "kick off each batch and babysit review cycles" to "start the daemon and check status when convenient."

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| 3 review cycles is sufficient for most CHANGES REQUESTED verdicts | value | Monitor first few daemon runs; if >50% of items exhaust 3 cycles, increase default |
| 5-minute scan interval balances responsiveness with cost | usability | Observe API cost per daemon-hour; adjust interval if cost exceeds expectations |
| Graceful shutdown via SIGTERM is reliable in bash | feasibility | Test: send SIGTERM during each phase type; verify cleanup completes |
| Operators will run this in a terminal (not launchd) initially | usability | Start with terminal; add launchd plist later if demand exists |
| Cumulative cost tracking from `total_cost_usd` in claude JSON output is accurate enough | feasibility | Compare accumulated costs with Anthropic dashboard after a full daemon session |

## Acceptance Criteria

- id: AC-1
  description: >-
    `genies daemon` subcommand starts a continuous loop that scans the backlog
    for actionable items, runs a batch, sleeps for --interval seconds, and
    repeats until stopped or --max-cycles reached
  status: pending

- id: AC-2
  description: >-
    Daemon writes a JSON status file (default .genie-daemon-status.json) after
    each cycle containing: daemon_pid, cycle count, timestamps, cumulative cost,
    completed/failed/in-progress item lists, and daemon status
  status: pending

- id: AC-3
  description: >-
    SIGINT and SIGTERM trigger graceful shutdown: daemon finishes current phase,
    commits any uncommitted work, cleans up worktrees, writes final status with
    status "stopped", and exits 0
  status: pending

- id: AC-4
  description: >-
    Review cycles default to 3 in daemon mode so CHANGES REQUESTED verdicts
    automatically retry deliver→discern up to 3 times; non-daemon genies
    invocations retain the existing default of 1
  status: pending

- id: AC-5
  description: >-
    `genies daemon stop` reads the PID from the status file and sends SIGTERM
    for clean remote shutdown; errors clearly if no daemon is running
  status: pending

- id: AC-6
  description: >-
    --max-cost flag stops the daemon when cumulative cost exceeds the budget;
    the final status file shows the cost that triggered the stop and the
    status is "budget_exceeded"
  status: pending

- id: AC-7
  description: >-
    Daemon prints a one-line terminal status update periodically showing
    cycle count, items completed/failed/in-progress, cost spent, and time
    until next scan
  status: pending

- id: AC-8
  description: >-
    Daemon supports --projects flag accepting multiple local repo paths,
    scanning each project's backlog independently per cycle; single-project
    mode (no flag) defaults to the current working directory
  status: pending

- id: AC-9
  description: >-
    Finisher pass runs after each batch cycle, scanning genie/* branches
    across all managed projects, reading backlog item status from each branch,
    and re-entering at the correct phase to complete stalled work (e.g.,
    re-run discern for "implemented" items, deliver→discern for CHANGES
    REQUESTED items, commit→done for APPROVED items with uncommitted changes)
  status: pending

## Routing

- **Next genie:** Crafter — design is complete, ready for TDD implementation
- **After Crafter:** Critic — verify on a real batch run with 2+ items that the daemon cycles, retries reviews, and shuts down cleanly

---

# Design

## Design Summary

Two additions to `scripts/genies`: a `daemon` subcommand providing a continuous outer loop with multi-project support, and a `finisher` function providing state-aware re-entry for stalled worktree branches. These compose with the existing batch/single execution paths — all current behavior is unchanged.

The metaphor: the daemon is the **head chef** orchestrating across restaurants (projects). Each `claude -p` session is a **sous chef** executing in its own worktree. The **finisher** is the head chef's quality pass — scanning all stations for incomplete plates and either finishing them or calling the sous chef back.

No new files. No new runtime dependencies. One file modified: `scripts/genies` (~200-300 lines additive). The existing test infrastructure (`tests/test_run_pdlc.sh`) extends with new test categories.

## Architecture

```
genies daemon --projects ~/code/project-a ~/code/project-b
        │
        ▼
┌──────────────────────────────────────────────────┐
│  Daemon Loop (run_daemon)                        │
│                                                  │
│  while not DAEMON_STOPPING:                      │
│    for each project:                             │
│      ├── cd $project_path                        │
│      ├── preflight_checks()                      │
│      ├── resolve_batch_items()                   │
│      └── run_batch_parallel() or _sequential()   │
│                                                  │
│    run_finisher()          ← head chef pass      │
│      for each project:                           │
│        scan genie/* branches                     │
│        for each stalled branch:                  │
│          read status → determine phase           │
│          re-run stalled phases                   │
│          integrate on success                    │
│                                                  │
│    write_daemon_status()                         │
│    interruptible_sleep($INTERVAL)                │
│                                                  │
│  write_daemon_status("stopped")                  │
└──────────────────────────────────────────────────┘
```

Data flow: daemon loop → per-project batch dispatch → existing `run_phase()` → `claude -p` → artifact output → verdict detection → next phase or finisher pickup.

The daemon does NOT modify the single-item PDLC path (`main()`) or the batch functions (`run_batch_parallel`, `run_batch_sequential`). It calls them as-is, wrapping them in the outer loop. The finisher is a new function that reuses `run_phase()` for phase execution and `session_integrate_trunk()` / `session_finish()` for merge.

### Alternatives Considered

**Alternative A: Cron wrapper (rejected).** A crontab entry running `genies --parallel 3 --trunk` every 5 minutes. Zero new code, but no finisher (stalled work stays stalled), no multi-project coordination, no graceful shutdown, no status aggregation, no cost tracking. Cron also doesn't handle long-running cycles overlapping with the next trigger (the lockfile helps but doesn't solve status). Rejected because it doesn't solve the core problems — just re-triggers the same one-shot execution that already stalls.

**Alternative B: Separate orchestrator script (rejected).** A standalone `genie-overseer` script outside of `scripts/genies`. Cleaner separation of concerns, but duplicates infrastructure (arg parsing, logging, session management, worktree handling all live in `genies`). Violates the recent consolidation into `genies` as the single CLI entry point (per P3-genies-subcommands). Rejected because it fragments the CLI surface and doubles maintenance.

**Alternative C: Daemon subcommand + finisher in existing script (chosen).** Adds `genies daemon` and `genies daemon stop` as subcommands alongside existing `genies session` and `genies quality`. The daemon function calls existing batch infrastructure. The finisher extends `run_recover()` with state-aware re-entry. All code stays in one file, reuses existing functions, and follows the established subcommand pattern.

## Component Design

| Component | Action | Location | What Changes |
|-----------|--------|----------|--------------|
| DaemonLoop | create | `scripts/genies` | `run_daemon()` — outer while loop, multi-project iteration, sleep, signal handling |
| DaemonCycle | create | `scripts/genies` | `run_daemon_cycle()` — one scan+batch pass across all projects, returns cycle results |
| Finisher | create | `scripts/genies` | `run_finisher()` — scan genie/* branches, determine state, re-enter stalled phases |
| StatusWriter | create | `scripts/genies` | `write_daemon_status()` — JSON status file writer |
| DaemonStop | create | `scripts/genies` | `run_daemon_stop()` — PID lookup + SIGTERM |
| InterruptibleSleep | create | `scripts/genies` | `interruptible_sleep()` — sleep that exits immediately on DAEMON_STOPPING |
| DaemonArgParsing | modify | `scripts/genies` | Extend `parse_args()` with daemon-specific flags; add daemon subcommand dispatch |
| ReviewCycleDefault | modify | `scripts/genies` | Set `REVIEW_CYCLES=3` when `DAEMON_MODE=true` |
| HealthCheck | create | `scripts/genies` | `project_health_check()` — verify git state before scanning (catches `bare=true` and similar corruption) |

## Interfaces

### `run_daemon()`

Entry point for daemon mode. Called from subcommand dispatch.

```bash
# Globals read: DAEMON_PROJECTS[], DAEMON_INTERVAL, DAEMON_MAX_CYCLES,
#               DAEMON_MAX_COST, DAEMON_STATUS_FILE, PARALLEL_JOBS,
#               TRUNK_MODE, REVIEW_CYCLES
# Globals written: DAEMON_STOPPING, DAEMON_CYCLE, DAEMON_COST
# Exit: 0 on clean stop, 1 on fatal error
run_daemon() {
    DAEMON_STOPPING=false
    DAEMON_CYCLE=0
    DAEMON_COST=0
    trap 'DAEMON_STOPPING=true; log_info "[daemon] Shutdown requested..."' INT TERM

    write_daemon_status "starting"

    while [[ "$DAEMON_STOPPING" != "true" ]]; do
        DAEMON_CYCLE=$((DAEMON_CYCLE + 1))

        # Cycle limit check
        if [[ -n "$DAEMON_MAX_CYCLES" && "$DAEMON_CYCLE" -gt "$DAEMON_MAX_CYCLES" ]]; then
            break
        fi

        run_daemon_cycle   # dispatches batch per project
        run_finisher       # head chef pass: complete stalled work

        # Cost limit check
        if [[ -n "$DAEMON_MAX_COST" ]] && (( $(echo "$DAEMON_COST > $DAEMON_MAX_COST" | bc -l) )); then
            write_daemon_status "budget_exceeded"
            break
        fi

        write_daemon_status "sleeping"
        interruptible_sleep "$DAEMON_INTERVAL"
    done

    write_daemon_status "stopped"
}
```

### `run_finisher()`

Scans all managed projects for stalled `genie/*` branches and completes them. This is the "head chef" pass.

```bash
# For each project in DAEMON_PROJECTS:
#   1. List genie/* branches
#   2. For each branch:
#      a. Extract item slug from branch name
#      b. Create/reuse worktree
#      c. Read backlog item status from branch
#      d. Determine next phase based on status
#      e. Run phases until complete or failed
#      f. Integrate to main on success
#      g. Clean up worktree
# Returns: 0 always (failures are logged, not fatal)
run_finisher()
```

State-to-phase mapping for the finisher (extends existing `status_to_phase()`):

| Branch Status | Frontmatter `status` | Frontmatter `verdict` | Uncommitted Changes | Action |
|---------------|---------------------|-----------------------|--------------------|--------|
| Has code | `implemented` | (none) | no | Run discern → commit → done |
| Has code | `implemented` | (none) | yes | Run commit first, then discern → commit → done |
| Reviewed | `reviewed` | `APPROVED` | no | Run done |
| Reviewed | `reviewed` | `APPROVED` | yes | Run commit → done |
| Reviewed | `reviewed` | `CHANGES_REQUESTED` | — | Run deliver → discern (review cycle) |
| Designed | `designed` | — | — | Run deliver → discern → commit → done |
| Other | — | — | yes | Run commit (utility commit) |

### `write_daemon_status(status)`

Writes JSON status file. Atomic write via temp file + mv.

```bash
# status: "starting" | "scanning" | "running" | "finishing" | "sleeping" | "stopped" | "budget_exceeded"
write_daemon_status() {
    local status="$1"
    local tmpfile="${DAEMON_STATUS_FILE}.tmp"
    # ... write JSON to tmpfile, then mv to DAEMON_STATUS_FILE
}
```

Status file schema:

```json
{
  "daemon_pid": 12345,
  "started_at": "2026-02-26T10:00:00Z",
  "current_cycle": 3,
  "last_cycle_at": "2026-02-26T10:15:00Z",
  "cumulative_cost_usd": 12.50,
  "status": "sleeping",
  "next_scan_at": "2026-02-26T10:20:00Z",
  "projects": [
    {
      "path": "/Users/nolan/code/project-a",
      "items_completed": ["P1-auth.md"],
      "items_failed": [],
      "items_stalled": [],
      "last_scan_at": "2026-02-26T10:15:00Z"
    }
  ],
  "totals": {
    "completed": 2,
    "failed": 1,
    "stalled": 0,
    "finisher_recovered": 1
  }
}
```

### `interruptible_sleep(seconds)`

Sleeps in 1-second increments, checking `DAEMON_STOPPING` each second. Returns immediately when flag is set.

```bash
interruptible_sleep() {
    local remaining="$1"
    while [[ "$remaining" -gt 0 && "$DAEMON_STOPPING" != "true" ]]; do
        sleep 1
        remaining=$((remaining - 1))
    done
}
```

### `project_health_check(project_path)`

Validates a project's git state before scanning. Returns 0 if healthy, 1 if broken.

Checks: `git rev-parse --is-inside-work-tree`, verifies `core.bare != true`, checks for index lock files.

### CLI Interface

```
genies daemon [OPTIONS] [--projects <path>...]
  --projects <path>...    Local repos to manage (default: current directory)
  --interval <seconds>    Sleep between cycles (default: 300)
  --max-cycles <N>        Stop after N cycles (default: unlimited)
  --max-cost <dollars>    Stop when cumulative cost exceeds this (default: unlimited)
  --status-file <path>    JSON status file path (default: ~/.genie-daemon-status.json)
  --parallel <N>          Workers per project batch (default: 3)
  --trunk                 Use trunk-based mode (default)
  --review-cycles <N>     Review retry limit (default: 3 in daemon mode)

genies daemon stop [--status-file <path>]
  Reads PID from status file, sends SIGTERM.

genies daemon status [--status-file <path>]
  Pretty-prints the current daemon status file.
```

## Pattern Adherence

This design follows all established patterns:

- **Subcommand pattern:** `genies daemon` follows the existing `genies session` and `genies quality` dispatch pattern in the `case` statement at the bottom of `scripts/genies`.
- **Function naming:** `run_daemon()`, `run_finisher()` follow the `run_batch_parallel()`, `run_batch_sequential()`, `run_recover()` naming convention.
- **Signal handling pattern:** Bash trap + flag variable is the standard approach for bash daemons. The existing `acquire_lock()` / `release_lock()` trap pattern in `main()` demonstrates this.
- **Status file pattern:** JSON status follows the `batch-manifest.json` pattern already used by `write_batch_manifest()`.
- **Phase execution:** The finisher reuses `run_phase()` for all phase execution — no new execution path.
- **Worktree lifecycle:** The finisher reuses `session_start()`, `session_finish()`, `session_cleanup_item()` from `genie-session`.

No deviations from established patterns.

## Risks

| Risk | Scenario | L | I | Mitigation |
|------|----------|---|---|------------|
| Signal race during `claude -p` | SIGTERM arrives while `claude -p` is running. The bash trap sets `DAEMON_STOPPING=true` but `claude` doesn't receive the signal because it's a child of the subshell capturing output. The daemon hangs waiting for `claude` to finish. | M | M | After setting the flag, if the current phase doesn't finish within 60s, send SIGTERM to the `claude` process group. Claude Code handles SIGTERM gracefully (writes partial output). |
| Stale status file after crash | Daemon crashes (OOM, power loss) without writing final status. Status file still shows "running" with old PID. Next `genies daemon` start reads the stale file. | M | L | `run_daemon()` checks for stale PID on startup (same pattern as `acquire_lock()`). If PID is dead, overwrite status and start fresh. |
| Finisher creates worktree for a branch that already has one | The finisher tries to `session_start()` for a branch that already has a worktree from a crashed batch. | L | L | Already handled: `worktree_setup()` calls `session_cleanup_item()` before `session_start()` to remove prior attempts. |
| Multi-project contention on shared resources | Two projects use the same MCP server (e.g., imagegen). Claude Code's MCP is per-session, so no contention. But if both projects modify `~/.claude/agent-memory/`, last-write-wins. | L | L | Agent memory contention is already documented as acceptable (parallel-sessions spec). No mitigation needed. |
| Unbounded cost when `--max-cost` is not set | Operator forgets `--max-cost`, daemon runs overnight, generates $500 in API costs. | M | H | The daemon logs cumulative cost after each cycle. A `WARN` log at $25, $50, $100 thresholds provides increasing urgency. Consider requiring `--max-cost` (no default unlimited) in v2 if field testing shows operators forget. |

Rollback: The daemon subcommand is purely additive. Removing it doesn't affect any existing `genies` functionality. The review cycle default change (3 in daemon mode) only applies when `DAEMON_MODE=true`, which only the daemon sets.

## AC Mapping

| AC | Approach | Components |
|----|----------|------------|
| AC-1 | `run_daemon()` while loop with `DAEMON_STOPPING` flag, `DAEMON_CYCLE` counter, `DAEMON_MAX_CYCLES` check | DaemonLoop |
| AC-2 | `write_daemon_status()` writes JSON with per-project item lists, cost, timestamps. Atomic write via tmp+mv | StatusWriter |
| AC-3 | `trap 'DAEMON_STOPPING=true' INT TERM` in `run_daemon()`. `interruptible_sleep()` exits on flag. Post-loop cleanup calls `write_daemon_status("stopped")` | DaemonLoop, InterruptibleSleep |
| AC-4 | In daemon arg parsing: `DAEMON_MODE=true` → `REVIEW_CYCLES=3` unless explicitly overridden by `--review-cycles` | DaemonArgParsing, ReviewCycleDefault |
| AC-5 | `run_daemon_stop()` reads `daemon_pid` from status file JSON, validates PID is alive, sends `kill -TERM $pid` | DaemonStop |
| AC-6 | After each `run_daemon_cycle()`, accumulate cost from batch results. Compare against `DAEMON_MAX_COST`. Write `"budget_exceeded"` status on breach. | DaemonLoop |
| AC-7 | `log_daemon_status_line()` called from `interruptible_sleep()` every 30 seconds. Prints one-line summary to stderr. | DaemonLoop, InterruptibleSleep |
| AC-8 | `DAEMON_PROJECTS[]` array from `--projects` flags. Default: `(.)`. `run_daemon_cycle()` iterates and `cd`s into each. `project_health_check()` validates git state. | DaemonCycle, HealthCheck |
| AC-9 | `run_finisher()` scans `genie/*` branches per project. State-to-phase mapping table determines re-entry point. Reuses `run_phase()`, `session_start()`, `session_finish()`. | Finisher |

## Implementation Guidance

**Sequence for Crafter (ordered by dependency):**

1. **Daemon arg parsing** (~30 lines)
   - Add `daemon` case to the subcommand dispatch block (alongside `session`, `quality`)
   - Parse daemon-specific flags: `--projects`, `--interval`, `--max-cycles`, `--max-cost`, `--status-file`
   - Set `DAEMON_MODE=true` and `REVIEW_CYCLES=3` (unless overridden)
   - Handle `daemon stop` and `daemon status` sub-subcommands

2. **`interruptible_sleep()`** (~10 lines)
   - While loop sleeping 1 second at a time, checking `DAEMON_STOPPING`
   - Call `log_daemon_status_line()` every 30 iterations

3. **`write_daemon_status()`** (~40 lines)
   - Follow `write_batch_manifest()` pattern for JSON construction (printf, no jq dependency)
   - Atomic write: write to `${file}.tmp`, then `mv`
   - Include all fields from the schema above

4. **`project_health_check()`** (~15 lines)
   - `git rev-parse --is-inside-work-tree` check
   - `git config core.bare` check (the `bare=true` issue)
   - Return 1 if unhealthy, log specific error

5. **`run_daemon_cycle()`** (~40 lines)
   - For each project in `DAEMON_PROJECTS`: cd → health check → resolve_batch_items → if items found, run batch → accumulate results
   - Track per-project completed/failed lists for status file
   - Return to original directory after each project

6. **`run_finisher()`** (~80 lines, most complex)
   - For each project: `cd` → list `genie/*` branches → for each branch:
     - Extract slug: `branch=${ref#genie/}; slug=${branch%-*}`
     - Create worktree if not exists: `session_start "$slug" "finisher"`
     - `cd` into worktree, read backlog item, determine state (use mapping table)
     - Execute needed phases via `run_phase()`
     - On success: `session_finish "$slug" --merge` (trunk) or `--pr` (PR mode)
     - On failure: log, skip (don't clean up — preserve for debugging)
   - Return to original directory

7. **`run_daemon()`** (~30 lines)
   - The main loop: trap signals → while not stopping: cycle → finisher → status → sleep
   - Cost accumulation and limit check after each cycle

8. **`run_daemon_stop()`** (~20 lines)
   - Read status file, extract `daemon_pid`, validate PID is alive, send SIGTERM
   - If PID not running: clean up stale status file, report

9. **`log_daemon_status_line()`** (~10 lines)
   - One-line stderr output: cycle count, completed/failed/stalled, cost, next scan ETA

**Test scenarios for Critic:**
- Unit: `interruptible_sleep` returns immediately when `DAEMON_STOPPING=true`
- Unit: `write_daemon_status` produces valid JSON with all required fields
- Unit: `project_health_check` detects `core.bare=true`
- Unit: Daemon arg parsing sets `REVIEW_CYCLES=3` in daemon mode
- Unit: Finisher state-to-phase mapping for each status combination
- Integration: `genies daemon --max-cycles 1 --projects .` runs one cycle and exits cleanly
- Integration: `genies daemon stop` sends SIGTERM to running daemon PID

## Routing

Ready for Crafter. No architectural decisions require ADRs — the daemon subcommand follows established patterns (ADR-001 thin orchestrator), and the finisher is the natural evolution of `--recover`. Implementation is ~200-300 lines of additive bash in `scripts/genies` plus ~40-60 test cases.

# Implementation

## Implementation Summary

All 9 ACs implemented via TDD in `scripts/genies` (~280 lines additive) with 58 new test assertions in `tests/test_run_pdlc.sh`.

### Functions Added

| Function | Lines | Purpose |
|----------|-------|---------|
| `log_daemon_status_line()` | 4 | One-line stderr status during sleep |
| `interruptible_sleep()` | 10 | Sleep with DAEMON_STOPPING check per second |
| `write_daemon_status()` | 45 | Atomic JSON status file writer (printf, no jq) |
| `project_health_check()` | 15 | Git state validation (bare repo, index.lock) |
| `parse_daemon_args()` | 45 | Daemon-specific flag parsing, sets REVIEW_CYCLES=3 |
| `finisher_state_to_phases()` | 25 | Pure function: status+verdict → phase list |
| `run_finisher()` | 80 | Head chef pass: scan genie/* branches, complete stalled work |
| `run_daemon_cycle()` | 45 | One scan+batch pass across all projects |
| `run_daemon()` | 40 | Main loop: signal handling, cost/cycle limits |
| `run_daemon_stop()` | 22 | PID lookup + SIGTERM from status file |

### Minor Changes to Existing Code

- `run_phase()`: Promoted `cost` local to `PHASE_COST` global for daemon cost tracking
- `parse_args()` help text: Added daemon subcommand to usage
- Subcommand dispatch: Added `daemon)` case with sub-subcommands (stop, status, start)

### Test Categories Added (58 assertions)

| Category | Tests | Component |
|----------|-------|-----------|
| 32 | 10 | `parse_daemon_args` |
| 33 | 4 | `interruptible_sleep` |
| 34 | 3 | `log_daemon_status_line` |
| 35 | 7 | `write_daemon_status` |
| 36 | 5 | `project_health_check` |
| 37 | 8 | `finisher_state_to_phases` |
| 38 | 8 | `run_daemon` loop control |
| 39 | 4 | `run_daemon_stop` |
| 40 | 5 | Daemon subcommand dispatch |
| 41 | 4 | `run_daemon_cycle` |

### AC Status

All 9 acceptance criteria implemented. Full test suite: 331 assertions, 0 failures.

## Routing

Ready for Critic. Verify via: `bash tests/test_run_pdlc.sh` (all 331 pass), `shellcheck scripts/genies` (clean), and `genies daemon --help` for CLI smoke test.

# End of Shaped Work Contract
