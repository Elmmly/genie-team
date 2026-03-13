---
spec_version: "1.0"
type: shaped-work
id: P1-observability-telemetry
title: "Observability via OTel and Structured Logging"
status: shaped
created: 2026-03-12
appetite: medium
priority: P1
author: shaper
discovery_ref: null
depends_on:
  - docs/backlog/P0-typescript-sdk-migration.md
acceptance_criteria:
  - id: AC-1
    description: >-
      SDK hooks write structured execution events (phase start, phase end,
      tool use, cost checkpoint, verdict, error) to JSONL log files in a
      configurable log directory. Each event includes timestamp, session ID,
      phase, genie name, and relevant metrics.
    status: pending
  - id: AC-2
    description: >-
      `genies status` subcommand reads JSONL logs and displays: active
      sessions, completed phases with cost/duration/turns, cumulative cost
      across a batch or daemon cycle, and last error with context. Works
      for both single-item and batch/daemon modes.
    status: pending
  - id: AC-3
    description: >-
      OTel telemetry opt-in: when CLAUDE_CODE_ENABLE_TELEMETRY=1 and an
      OTel collector endpoint is configured, execution metrics (cost per
      phase, tokens, duration, verdict, error rate) are exported as OTel
      spans. Works with standard collectors (Bindplane, SigNoz, Grafana).
    status: pending
  - id: AC-4
    description: >-
      Phase cost summary printed after each batch/daemon cycle showing
      per-phase breakdown (genie, model used, turns, tokens, cost, duration)
      and aggregate totals. Includes comparison to budget limits if configured.
    status: pending
---

# Shaped Work Contract: Observability via OTel and Structured Logging

## Problem

When running genies autonomously (batch, daemon, parallel worktrees), there's no visibility into what's happening, what it costs, or where failures occur. The $7.39 field test cost was only discovered after the fact by checking Anthropic Console. Daemon cycles that fail mid-run leave no structured trace. There's no way to answer "which phase is most expensive?" or "what's the error rate on critic reviews?"

**Evidence:**
- Field test lessons (Feb 2026): per-phase cost tracking identified as needed enhancement (strong)
- Claude Code already emits OTel signals with `CLAUDE_CODE_ENABLE_TELEMETRY=1` (strong)
- SDK hooks provide real-time cost and event data programmatically (strong — from SDK spike)
- `ccusage` CLI and Bindplane/SigNoz reference architectures exist (moderate)

## Appetite & Boundaries

- **Appetite:** Medium batch (3-5 days)
- **No-gos:**
  - No custom dashboard UI — use existing tools (terminal output, Grafana, ccusage)
  - No mandatory telemetry — always opt-in
  - No data sent to third parties without explicit configuration
  - No historical analysis or trend tracking (deferred to self-improvement item)
- **Fixed elements:**
  - JSONL log format (append-only, grep-friendly)
  - OTel standard (not custom metrics format)
  - SDK hooks as the data source (not log file parsing)

## Goals & Outcomes

1. **Cost visibility:** Know exactly what each batch/daemon cycle costs, broken down by phase and genie
2. **Real-time status:** See what's running and how far along it is without waiting for completion
3. **Failure diagnosis:** Structured error logs with context, not grep through raw output
4. **Enterprise readiness:** OTel export enables integration with existing monitoring infrastructure

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| SDK hooks provide cost data at the right granularity (per-phase, not just per-session) | Feasibility | Validate during P0-SDK-migration Phase 1 |
| OTel export from Claude Code sessions works with standard collectors | Feasibility | Quick test with `CLAUDE_CODE_ENABLE_TELEMETRY=1` + local collector |
| JSONL logs are sufficient for single-team use without a dashboard | Usability | User testing during delivery |

## Routing

**Next:** `/design` after P0-SDK-migration Phase 1 delivers `runPhase()` with hooks. Observability hooks layer on top of the SDK integration.
