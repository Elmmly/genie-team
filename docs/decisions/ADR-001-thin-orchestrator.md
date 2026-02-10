---
adr_version: "1.0"
type: adr
id: ADR-001
title: "Use Thin Orchestrator for External Portfolio Integration"
status: accepted
created: 2026-02-04
revised: 2026-02-10
deciders: [architect, navigator]
tags: [architecture, integration, orchestration, portfolio]
---

# ADR-001: Use Thin Orchestrator for External Portfolio Integration

## Context

Genie Team is designed to support autonomous execution by external orchestrators —
product portfolio systems, CI/CD pipelines, dashboards, or any tool that dispatches
structured development work across repositories. Two architectural models were
considered:

**Model A: Thin Orchestrator**
- External orchestrator treats genie-team CLI as a black box
- Spawns CLI processes for each job via `claude -p`
- Captures stdout/stderr or `--output-format stream-json` for progress
- No shared runtime state between orchestrator and genies

**Model B: Deep Integration (genie-core extraction)**
- Extract shared library from genie-team
- Orchestrator imports genie-core for in-process execution
- Shared state, direct function calls
- Requires significant refactoring

**Key constraint:** The current CLI must remain stable. Genie-team is open source
and actively used by multiple developers. All changes must be additive.

## Decision

Use Model A: Thin Orchestrator architecture.

External orchestrators spawn Claude Code CLI processes using headless invocation:
```
$ claude -p "/deliver docs/backlog/P1-feature.md" --output-format json
```

The CLI remains unchanged. Genie-team provides the structured workflow (commands,
rules, agents); Claude Code provides the execution runtime; the orchestrator
provides job dispatch, progress monitoring, and approval gates.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│  Portfolio Orchestrator                              │
│  (e.g., Cataliva, CI/CD, custom dashboard)          │
│  ├── Job dispatcher (spawns CLI processes)          │
│  ├── Progress monitoring (captures stream-json)     │
│  └── Approval gates (review before merge)           │
└─────────────────────────────────────────────────────┘
                        ↓ spawns
        $ claude -p "/deliver ..." --output-format json
                        ↓
┌─────────────────────────────────────────────────────┐
│  Genie Team (installed in target project)           │
│  ├── Commands (.claude/commands/) — workflow phases │
│  ├── Rules (.claude/rules/) — safety constraints    │
│  ├── Agents (.claude/agents/) — genie definitions   │
│  └── Skills (.claude/skills/) — auto behaviors      │
└─────────────────────────────────────────────────────┘
                        ↓ extends
┌─────────────────────────────────────────────────────┐
│  Claude Code CLI (execution runtime)                │
│  ├── Native git operations                          │
│  ├── Headless mode (claude -p)                      │
│  └── Structured output (--output-format json/stream)│
└─────────────────────────────────────────────────────┘
                        ↓ operates on
                   Target Repositories
```

## Consequences

### Positive
- Current CLI remains untouched — no risk to existing users
- Any orchestrator can integrate — not coupled to a specific product
- Clear process boundaries simplify debugging
- Easier to reason about: one process = one job
- Workspace isolation per-process is a benefit for parallel execution

### Negative
- Process spawning adds latency (~500ms per job start)
- No shared state between orchestrator and CLI (must parse stdout/JSON)
- Repeated LLM context loading for each process
- Can't share warm connections or caches across jobs

### Neutral
- Progress monitoring uses Claude Code's native `--output-format stream-json`
- Orchestrator is responsible for job queuing, retry logic, and concurrency
- CLI contract documentation (`docs/architecture/cli-contract.md`) defines the integration surface

## Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| Model B: Deep Integration | Shared state, lower latency, in-process calls | Requires foundational CLI changes, breaks stability constraint | High risk to existing users, defers learning |
| MCP Server wrapper | Standard protocol, tool discovery | Adds complexity layer, MCP designed for tools not orchestration | Wrong abstraction level |
| REST API wrapper | Language-agnostic, stateless | HTTP overhead, requires server process | CLI invocation is simpler |

## When to Reconsider

This decision should be revisited when:
- Process spawning latency becomes unacceptable (>2s per job)
- Need shared state between orchestrator and genies (e.g., caching)
- Time/resources available for proper genie-core extraction with tests

## Related Decisions

- ADR-000: Use ADRs to record architecture decisions
- ADR-002: Designer genie integration (commands + skill + agent)
