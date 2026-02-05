---
adr_version: "1.0"
type: adr
id: ADR-001
title: "Use Thin Orchestrator (Model A) for Cataliva Integration"
status: accepted
created: 2026-02-04
deciders: [architect, navigator]
tags: [architecture, integration, cataliva, orchestration]
---

# ADR-001: Use Thin Orchestrator (Model A) for Cataliva Integration

## Context

Genie Team is evolving to support multi-product orchestration through Cataliva, a
dashboard application that dispatches work across multiple repositories. Two
architectural models were considered:

**Model A: Thin Orchestrator**
- Cataliva treats genie-team CLI as a black box
- Spawns CLI processes for each job
- Captures stdout/stderr for progress streaming
- No shared runtime state between orchestrator and genies

**Model B: Deep Integration (genie-core extraction)**
- Extract shared library from genie-team
- Cataliva imports genie-core for in-process orchestration
- Shared state, direct function calls
- Requires significant refactoring

**Key constraint:** The current CLI must remain stable. Genie-team is open source
and actively used by multiple developers. All changes must be additive.

## Decision

Use Model A: Thin Orchestrator architecture.

Cataliva will spawn genie-team CLI processes using shell execution:
```
$ claude "genie-team /deliver docs/backlog/P1-feature.md"
```

The CLI remains unchanged. New capabilities (Designer genie, Worker execution mode)
are additive — opt-in features that don't modify existing behavior.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────┐
│  Cataliva (dashboard + orchestration)               │
│  ├── Job dispatcher (spawns CLI processes)          │
│  ├── Progress streaming (captures CLI output)       │
│  └── Batch approval UX                              │
└─────────────────────────────────────────────────────┘
                        ↓ spawns
              $ claude "genie-team /deliver ..."
                        ↓
┌─────────────────────────────────────────────────────┐
│  Genie-team CLI (unchanged, stable)                 │
│  ├── Existing genies (Scout, Shaper, Architect...)  │
│  ├── NEW: Designer genie (additive)                 │
│  └── NEW: Worker execution mode (additive)          │
└─────────────────────────────────────────────────────┘
                        ↓ operates on
                   Repositories
                  (2hearted, etc.)
```

## Consequences

### Positive
- Current CLI remains untouched — no risk to existing users
- Lower implementation complexity for initial integration
- Clear process boundaries simplify debugging
- Easier to reason about: one process = one job
- Learning loop: real usage informs eventual genie-core design

### Negative
- Process spawning adds latency (~500ms per job start)
- No shared state between Cataliva and CLI (must parse stdout)
- Repeated LLM context loading for each process
- Can't share warm connections or caches across jobs

### Neutral
- LLM provider abstraction (Gemini support) deferred until genie-core extraction
- Progress streaming requires structured stdout (existing skill pattern)
- Workspace isolation per-process is actually a benefit for parallel execution

## Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| Model B: Deep Integration | Shared state, lower latency, in-process calls | Requires foundational CLI changes, breaks stability constraint | High risk to existing users, defers learning |
| MCP Server wrapper | Standard protocol, tool discovery | Adds complexity layer, MCP designed for tools not orchestration | Wrong abstraction level |
| REST API wrapper | Language-agnostic, stateless | HTTP overhead, requires server process | CLI invocation is simpler for MVP |

## When to Reconsider

This decision should be revisited when:
- Process spawning latency becomes unacceptable (>2s per job)
- Need shared state between Cataliva and genies (e.g., caching)
- Want to support multiple LLM providers (Gemini, etc.) in same session
- Time/resources available for proper genie-core extraction with tests

## Related Decisions

- ADR-000: Use ADRs to record architecture decisions
- (Future) ADR-002: Designer genie workflow position
- (Future) ADR-003: Worker execution credential management
