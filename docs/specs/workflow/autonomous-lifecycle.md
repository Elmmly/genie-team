---
spec_version: "1.0"
type: capability-spec
id: autonomous-lifecycle
title: "Autonomous Lifecycle Runner"
status: active
domain: workflow
created: 2026-02-12
updated: 2026-02-12
author: shaper
tags: [workflow, autonomous, lifecycle, runner, cron, orchestration]
acceptance_criteria:
  - id: AC-1
    description: >-
      In-session autonomous mode: /run [--from phase] [--through phase] runs the specified
      phase range without per-phase user confirmation, using /discern as the automated quality
      gate — stops on BLOCKED, continues through APPROVED
    status: met
  - id: AC-2
    description: >-
      Headless runner script chains claude -p invocations per phase, passes artifact paths
      between phases, handles errors with meaningful exit codes (0=success, 1=failure,
      2=merge conflict), and produces structured log output
    status: met
  - id: AC-3
    description: >-
      Runner supports phase ranges via --from and --through flags: --from discover --through
      define runs only discovery and shaping; --from design runs design through done; no flags
      runs full lifecycle. Operates on existing backlog items or new topics.
    status: met
  - id: AC-4
    description: "Runner is cron-compatible: no interactive input, log file output, meaningful exit codes, and a lockfile to prevent overlapping runs on the same item"
    status: met
  - id: AC-5
    description: "Runner implements worktree lifecycle for parallel execution: create worktree before run, cleanup on success, preserve-or-cleanup on failure with retry convention"
    status: unmet
  - id: AC-6
    description: >-
      Runner implements responsible execution: per-phase turn limits from CLI contract
      defaults, automatic single retry with --resume on phase exhaustion, stop-and-report
      when retry also exhausts. Logs token usage and turn counts per phase for transparency.
      Users can override per-phase limits (e.g. --deliver-turns 200).
    status: met
  - id: AC-7
    description: >-
      Documentation describes scheduling patterns (cron, CI/CD, GitHub Actions) with concrete
      examples including: daily discover+define pipeline, human review checkpoint, then
      design+deliver on approved items
    status: met
  - id: AC-8
    description: >-
      Runner supports batch execution: scans backlog for actionable items when no inputs
      provided, auto-detects starting phase from item status, runs items concurrently in
      isolated worktrees with --parallel N, serializes merge integration after all workers
      complete. Supports --priority filtering, --dry-run preview, --continue-on-failure,
      and --topics-file for discovery batches.
    status: met
---

# Autonomous Lifecycle Runner

## Overview

Enable the genie-team PDLC to run in configurable phase ranges — from daily discover+define pipelines to full overnight delivery — both within an interactive Claude session and via external scheduling (cron, CI/CD, GitHub Actions).

## Primary Use Cases

1. **Scheduled phase ranges with human checkpoints:** Daily cron runs discover+define (`--through define`), human reviews shaped contracts, then kicks off design+deliver (`--from design`) on approved items
2. **Full autonomous cycle:** `/run "topic"` runs the entire lifecycle end-to-end with `/discern` as the automated quality gate
3. **Backlog-driven continuation:** Runner receives an existing backlog item path and advances it through the specified phase range

## Phase Range Model

The runner uses `--from` and `--through` to express any contiguous range of the 7 D's:

```
discover → define → design → deliver → discern → commit → done
         ^                           ^
      --from                     --through
```

| Example | Phases Run | Use Case |
|---------|-----------|----------|
| (no flags) | discover → done | Full overnight delivery |
| `--through define` | discover → define | Daily discovery pipeline |
| `--from design --through deliver` | design → deliver | Implement approved items |
| `--from discern` | discern → done | Review and close |
| `--from deliver --through deliver` | deliver | Single phase execution |

## Relationship to Existing Work

| Foundation | What It Provides | What's Missing |
|-----------|------------------|----------------|
| P1-autonomous-execution-readiness (done) | Safety rules, CLI contract, streaming conventions | No actual runner — just documentation |
| P2-parallel-sessions-git-worktrees (done) | Worktree isolation, install.sh detection, parallel safety | No worktree lifecycle management for autonomous runs (cleanup, retry) |
| `/feature` command | Phase chaining with manual gates | No autonomous mode, no phase range support |
| CLI contract (`cli-contract.md`) | Full lifecycle dispatch example | Illustrative only — no error handling, no gate checking, no logging |
| ADR-001 Thin Orchestrator | Architecture: spawn CLI processes per job | Orchestrator logic is the external system's responsibility |

## Constraints

- Genie-team is a prompt engineering project — the runner script is bash, not application code
- Per ADR-001, the runner is a thin orchestrator that spawns `claude -p` processes
- In-session mode uses prompt chaining (single conversation), not process spawning
- Runner must work with existing genie-team commands — no command modifications required
- Runner handles ONE lifecycle at a time — parallelism is via multiple instances in separate worktrees

## Design Constraints
<!-- Updated by /design on 2026-02-12 from autonomous-lifecycle-runner -->
- In-session command is `/run` (NOT `/feature --auto`) — `/feature` remains the interactive shortcut with manual gates; `/run` is the autonomous equivalent with no gates
- Headless runner chains `claude -p` per phase using `--resume` for context continuity within a single run; `--no-resume` flag available for fresh sessions per phase
- Artifact path resolution between phases: regex parse output text for `docs/analysis/*.md` and `docs/backlog/*.md` paths; fallback to `git diff --name-only`
- Gate detection: regex parse `/discern` output for APPROVED/BLOCKED/CHANGES REQUESTED; stop on no-match (safe default)
- Responsible execution: per-phase `--max-turns` defaults from CLI contract (50/50/50/100/50/10/20), automatic single retry with `--resume` on phase exhaustion, stop-and-report on double exhaustion. No aggregate budget — the lifecycle phases self-regulate. Users override via `--deliver-turns`, `--turns-per-phase`, etc.
- Lockfile: file-based per input hash (SHA of topic/path), 4-hour stale threshold, PID stored for debugging
- Worktree: default preserve-on-failure; explicit `--cleanup-on-failure` flag for automated environments
- Runner requires only bash + jq — no Python, Node, or other runtime dependencies
- State tracking uses two variables: `analysis_path` (discover → define) and `item_path` (define → all subsequent phases)
- The backlog item's frontmatter `status` field is the source of truth for phase progression
- Worktree isolation integrates with P2 parallel-sessions conventions: branch naming (`genie/{item}-run-{date}`), safety rules, memory symlink, MCP scope. Runner manages full worktree lifecycle (create → run → PR → cleanup) including prior failed attempt cleanup.
- Worktree teardown: cleanup on success, preserve on failure (default), `--cleanup-on-failure` opt-in for automated environments
- Global genie-team install (`~/.claude/`) works in worktrees automatically. Project-level install: tracked `.claude/` files appear via git.
- Commit is a post-phase utility, not a lifecycle phase gated by `--through`. After the phase range completes, run commit if uncommitted changes exist and `--through` didn't already include the commit phase. Prevents artifact loss in worktree/batch modes.
- Gate detection primary source: read `verdict:` field from backlog item frontmatter (written by `/discern`). Fallback: regex parse output for APPROVED/BLOCKED/CHANGES REQUESTED. Frontmatter approach is structured, auditable, and survives output format changes.
- Integration exit codes: `session_integrate_trunk` returns distinct codes (0=success, 1=no branch, 2=rebase conflict, 3=checkout failed, 4=merge failed). Integration loop logs specific failure reason per code. Batch completion writes `batch-manifest.json` to log directory.
- `--recover` flag re-runs just the integration phase for items with existing unmerged `genie/*` branches, with optional `--priority` slug-prefix filtering. Runs sequentially (integration modifies shared state). Enables recovery without re-running expensive PDLC phases.
- PATH command naming: `genies` (lifecycle runner), `genie-session` (session manager), `genie-quality` (quality checks). No `.sh` extensions for PATH commands. Internal `scripts/validate/*.sh` keep extensions.

## Implementation Evidence
<!-- Appended by /deliver on 2026-02-12 -->

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Met | `commands/run.md` — `/run` command with `--from`/`--through`, no confirmation gates, `/discern` as automated gate |
| AC-2 | Met | `scripts/genies` — chains `claude -p` per phase, parses JSON output, exit codes 0/1/2/3, structured JSON logging |
| AC-3 | Met | Phase range via `phase_index()` + `PHASES` array; validated by 8 parse_args + 3 validate_args tests |
| AC-4 | Met | `--log-dir` (JSON logging), `--lock` (lockfile with stale detection), no interactive input, exit codes; validated by 4 lockfile tests |
| AC-5 | Partial | Worktree stubs with TODO markers in `genies`; will source `genie-session` from P2-session-management |
| AC-6 | Met | `DEFAULT_TURNS` array, `get_max_turns()` with per-phase overrides, `retry_phase()` with single retry; validated by retry tests + run_phase max-turns test |
| AC-7 | Met | Scheduling patterns in shaped contract (cron, CI/CD examples with `--through define`, `--from design`, `--lock`, `--log-dir`) |

**Test suite:** 48 tests in `tests/test_run_pdlc.sh`, all passing. `shellcheck` clean.

## Review Verdict
<!-- Updated by /discern on 2026-02-12 from autonomous-lifecycle-runner -->

**Verdict:** APPROVED
**ACs verified:** 6/7 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `/run` command with `--from`/`--through`, no confirmation gates, stop-on-BLOCKED |
| AC-2 | met | `genies` chains `claude -p`, parses JSON, exit codes 0/1/2/3, JSON logging |
| AC-3 | met | `PHASES` array + `phase_index()`, 11 tests for args + validation |
| AC-4 | met | `--log-dir`, `--lock`, no interactive input, 4 lockfile tests |
| AC-5 | unmet | Worktree stubs only — P2-session-management dependency not yet delivered |
| AC-6 | met | `DEFAULT_TURNS`, `get_max_turns()`, `retry_phase()`, override flags, 2 retry tests |
| AC-7 | met | Scheduling patterns in shaped contract with cron, CI/CD, GitHub Actions examples |

## Implementation Evidence (Field Test Fixes)
<!-- Appended by /deliver on 2026-02-13 from GT-34 -->

Prompt-level safety and observability fixes from first autonomous field test:

| Backlog AC | Spec AC | Files Changed | Description |
|------------|---------|---------------|-------------|
| GT-34/AC-1 | AC-1 | `commands/done.md`, `commands/commit.md` | No-amend, no-force-push rules for autonomous context |
| GT-34/AC-2 | AC-1 | `commands/run.md`, `commands/commit.md` | PR_CREATION_MODE propagation from preflight to commit |
| GT-34/AC-3 | AC-1 | `commands/run.md`, `commands/commit.md` | Artifact-aware staging via session-state.md |
| GT-34/AC-4 | AC-6 | `commands/run.md` | Per-phase metrics table in /run completion summary |

## Implementation Evidence (Phase Completion)
<!-- Appended by /deliver on 2026-02-13 from GT-35 -->

Phase reorder and completion verification fixes from second autonomous field test:

| Backlog AC | Spec AC | Files Changed | Description |
|------------|---------|---------------|-------------|
| GT-35/AC-1 | AC-1 | `commands/run.md` | Phase completion verification — checks all phases in range executed, reports INCOMPLETE with skipped phase list |
| GT-35/AC-2 | AC-1 | `commands/run.md` | Reordered final phases to discern → done → commit; archive changes included in single delivery commit |

## Implementation Evidence (Unified Batch Runner)
<!-- Appended by /deliver on 2026-02-13 from GT-36 -->

Batch execution unified into `genies` as a single entry point:

### Test Coverage
- `tests/test_run_pdlc.sh`: 33 new tests covering AC-8 (status_to_phase, get_frontmatter_field, batch parse_args flags, resolve_batch_items)
- Total: 119 tests in genies suite, 333 across all suites

### Implementation Files
- `scripts/genies`: Added ~380 lines — helper functions (get_frontmatter_field, status_to_phase), batch parse_args flags, resolve_batch_items, sequential/parallel batch execution, integration phase, summary reporting

## Implementation Evidence (Batch Reliability Fixes)
<!-- Appended by /deliver on 2026-02-14 from P1-always-commit, P1-verdict-structured-output, P1-integration-diagnostics -->

Three reliability fixes from 2hearted batch run post-mortem (Feb 13-14, 2026):

### P1-always-commit (utility commit)
- `scripts/genies`: Added `maybe_utility_commit()` — post-loop utility commit that fires when `--through` didn't include commit phase and uncommitted changes exist
- `commands/run.md`: Documented commit-as-utility behavior in Phase Range Model section
- 4 new tests in `tests/test_run_pdlc.sh`

### P1-verdict-structured-output (frontmatter verdict)
- `scripts/genies`: Updated `detect_verdict()` with optional `item_path` parameter; reads frontmatter `verdict` field as primary source, falls back to regex
- `commands/discern.md`: Added `verdict:` field to Context Writing UPDATE list
- 9 new tests in `tests/test_run_pdlc.sh`

### P1-integration-diagnostics (exit codes, manifest, recovery)
- `scripts/genie-session`: `session_integrate_trunk` returns exit 3 (checkout fail) and 4 (merge fail) instead of generic exit 1
- `scripts/genies`: Integration loop uses `case` statement for diagnostic messages; added `write_batch_manifest()`; added `--recover` flag
- 2 new tests in `tests/test_session.sh`, 7 new tests in `tests/test_run_pdlc.sh`

### Test Coverage
- `tests/test_run_pdlc.sh`: 148 tests (20 new), all passing
- `tests/test_session.sh`: 54 tests (2 new), all passing
