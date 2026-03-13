---
adr_version: "1.0"
type: adr
id: ADR-005
title: "SDK-Integrated Orchestrator (Revises ADR-001)"
status: accepted
created: 2026-03-12
deciders: [architect, navigator]
tags: [architecture, orchestration, sdk, typescript, migration]
supersedes: ADR-001
---

# ADR-005: SDK-Integrated Orchestrator (Revises ADR-001)

## Context

ADR-001 established the Thin Orchestrator pattern: external orchestrators spawn `claude -p` CLI processes with no shared runtime. This served genie-team well through initial development, but three changes motivate revision:

1. **Shell scripting ceiling.** The core orchestrator (`scripts/genies`, 2,567 lines) uses hand-rolled YAML parsing via sed chains, a polling-based parallel worker pool, and non-atomic frontmatter updates. Every new feature increases fragility.

2. **Agent SDK availability.** The Claude Agent SDK (TypeScript) provides programmatic capabilities that CLI spawning cannot match: hooks for execution governance, per-session budget caps (`maxBudgetUsd`), session resume across phases, structured output validation, and real-time streaming callbacks.

3. **Enterprise governance needs.** Cost control, audit logging, and quality enforcement during autonomous execution require intercepting the agent loop mid-stream — impossible with CLI spawning, native with SDK hooks.

### Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| Keep ADR-001 (shell + CLI spawning) | No migration cost; proven stable | No SDK governance; shell fragility worsens; capability ceiling | Defers the inevitable |
| Go rewrite (keep CLI spawning) | Single binary; proper types/testing | Loses all SDK capabilities (hooks, budget, sessions, structured output) | CLI spawning ceiling remains |
| TypeScript via Agent SDK | SDK governance; same runtime as Claude Code; npm distribution | Takes on Node.js dependency; revises ADR-001 | **Recommended** |
| Python via Agent SDK | SDK available in Python too | TS SDK more mature (17 vs 11 hooks); distribution harder (pip/venv) | Less mature SDK |

## Decision

**Accepted.** Migrate from Thin Orchestrator (CLI spawning) to SDK-Integrated Orchestrator (programmatic `query()` calls via `@anthropic-ai/claude-agent-sdk`). TypeScript as implementation language.

Design constraints resolved:
- Shell `genies` wrapper delegates to compiled TypeScript `genies-core` via exit-code-127 fallback pattern
- Incremental 4-phase migration: shell and TS coexist, each phase ships independently
- Claude Code hooks remain shell scripts (platform requirement) — SDK hooks handle execution governance separately
- CLI contract (`docs/architecture/cli-contract.md`) preserved — external orchestrators continue to invoke `genies`
- ADR-001's process isolation preserved via SDK session isolation and per-phase `query()` calls

Full design: `docs/backlog/P0-typescript-sdk-migration.md` (Design section).

## Consequences

**Positive:**
- Programmatic execution governance via SDK hooks (PostToolUse for artifact tracking, Stop for cost logging, maxBudgetUsd for per-session caps)
- Session resume across genie phases via SDK `resume` parameter — context preservation without re-prompting
- Typed YAML/JSON parsing via `js-yaml` with `proper-lockfile` — eliminates sed chain fragility and race conditions
- Async parallel execution via `Promise.allSettled` with semaphore — replaces bash polling-based worker pool
- Vitest testing replaces ~7,000 lines of custom bash test framework
- Auth mode control (`--auth oauth|apikey`) enables capped billing path for headless execution
- Model tier routing via `genie-config.yaml` — cost optimization by matching model capability to task complexity

**Negative:**
- Migration effort (~6 weeks across 4 phases) — mitigated by incremental delivery with shell fallback
- Two-language codebase during transition (TS + shell hooks) — resolved at Phase 3
- SDK version dependency (must track Anthropic releases) — mitigated by pinning version and abstracting behind `PhaseExecutor` interface
- Node.js runtime assumption — mitigated: Claude Code already requires Node.js

**Neutral:**
- Claude Code hooks remain shell scripts (platform requirement) — this won't change regardless of orchestrator language
- CLI contract is preserved — external integrations unaffected

## Related Decisions

- ADR-001: Thin Orchestrator (superseded by this ADR)
- ADR-003: Extended Thinking (must be preserved in SDK migration)
- P0-typescript-sdk-migration: Implementation backlog item
