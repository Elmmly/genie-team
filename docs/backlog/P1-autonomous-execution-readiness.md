---
spec_version: "1.0"
type: shaped-work
id: autonomous-execution-readiness
title: "Autonomous Execution Readiness for Cataliva Integration"
status: shaped
created: 2026-02-10
appetite: small
priority: P1
target_project: genie-team
author: shaper
depends_on: []
consolidates:
  - docs/archive/backlog-review/2026-02-10_platform-reality-check/P1-progress-streaming-protocol.md
  - docs/archive/backlog-review/2026-02-10_platform-reality-check/P1-repo-aware-execution.md
  - docs/archive/backlog-review/2026-02-10_platform-reality-check/P2-cataliva-integration.md
adr_refs:
  - docs/decisions/ADR-001-thin-orchestrator.md
tags: [cataliva, autonomous, streaming, safety, cli-contract]
acceptance_criteria:
  - id: AC-1
    description: "Safety rules for autonomous git operations exist in .claude/rules/ — branch naming (genie/{item}-{phase}), no force push, no push to main/master, conventional commit format with genie attribution"
    status: pending
  - id: AC-2
    description: "Streaming conventions document maps genie workflow phases to native Claude Code stream-json events, defining which events signal phase_start, phase_complete, and artifact creation"
    status: pending
  - id: AC-3
    description: "CLI contract document specifies how an orchestrator (Cataliva) invokes genie-team commands, what output to parse, expected exit codes, and artifact locations"
    status: pending
  - id: AC-4
    description: "Machine-readable completion signal convention defined — final stream event structure that Cataliva can parse to determine success/failure and locate output artifacts"
    status: pending
---

# Shaped Work Contract: Autonomous Execution Readiness

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Original input:** Cataliva needs to dispatch genie-team commands across a product portfolio and understand the results programmatically.

**Reframed problem:** Genie-team commands were designed for interactive human use. For autonomous execution by an orchestrator like Cataliva, the CLI needs: safety guardrails for unsupervised git operations, streaming conventions that map workflow phases to parseable events, and a documented contract for how to invoke and interpret results.

**Key insight (2026-02-10 backlog review):** Claude Code now provides native `--output-format stream-json` (NDJSON streaming), full git workflow support (clone, branch, commit, push, PR), and headless execution modes. Genie-team doesn't need to BUILD infrastructure — it needs to DOCUMENT conventions and ADD safety rules on top of native platform capabilities.

## Evidence & Insights

- **Platform capabilities (Feb 2026):** Claude Code provides `--output-format stream-json`, native git operations, `Co-Authored-By` attribution, and headless/programmatic invocation
- **ADR-001:** Thin Orchestrator — Cataliva spawns CLI processes, captures stdout, no shared runtime
- **Superseded items:** P1-progress-streaming-protocol (native streaming exists), P1-repo-aware-execution (native git exists), P2-cataliva-integration (orchestration is Cataliva's responsibility)
- **JTBD:** "When Cataliva dispatches `/deliver` to a target repo, I want to know it will create a safe feature branch, produce parseable progress, and signal completion with artifact locations."

## Appetite & Boundaries

- **Appetite:** Small (1 day)
- **Boundaries:**
  - Safety rules as `.claude/rules/` markdown files
  - Streaming conventions as a documentation artifact
  - CLI contract as a documentation artifact
  - Completion signal convention
- **No-gos:**
  - No application code (genie-team is prompt engineering)
  - No worker pool, job queue, or retry logic (Cataliva's responsibility)
  - No dashboard or UI (Cataliva's responsibility)
  - No changes to existing command behavior
- **Fixed elements:**
  - Must use native Claude Code capabilities, not custom implementations
  - Must follow ADR-001 Thin Orchestrator architecture
  - Must be additive (no breaking changes to interactive use)

## Goals

**Outcome Hypothesis:** "We believe that safety rules + streaming conventions + a CLI contract will make genie-team ready for autonomous execution by Cataliva, without changing any existing commands."

**Success Signals:**
- Cataliva can invoke `claude --output-format stream-json "/deliver docs/backlog/P1-feature.md"` and parse progress
- Autonomous git operations respect branch naming and safety constraints
- CLI contract document is sufficient for a Cataliva developer to integrate without genie-team expertise

## Deliverables

### 1. Safety Rules (`.claude/rules/autonomous-execution.md`)

Rules that activate during autonomous (headless) execution:

```markdown
# Autonomous Execution Safety

When running in autonomous/headless mode (no interactive user):

## Git Safety
- Create feature branches with naming: `genie/{backlog-item}-{phase}`
- NEVER force push
- NEVER push to main/master/default branch
- NEVER delete branches
- Always create PR (no direct merge)
- Include Co-Authored-By with genie name

## Commit Format
- Use conventional commits: `type(scope): description`
- Include backlog item reference in commit body
- Include genie attribution

## Workspace
- Operate only within the target repository
- Do not modify files outside the repo root
- Clean up temporary files on completion
```

### 2. Streaming Conventions (`docs/architecture/streaming-conventions.md`)

Maps genie workflow phases to native `stream-json` events:

| Genie Phase | Stream Signal | How to Detect |
|-------------|---------------|---------------|
| Phase start | First `assistant` message mentioning phase name | Parse text for "## Phase: discover/define/design/deliver/discern" |
| Tool call | `tool_use` event with tool name | Native stream-json `tool_use` blocks |
| Artifact created | `tool_use` event with `Write` tool | Parse `file_path` parameter for `docs/` paths |
| Phase complete | Final `assistant` message with routing | Parse text for "Ready for:" or "Next:" |
| Completion | Stream ends (process exit) | Exit code 0 = success |

### 3. CLI Contract (`docs/architecture/cli-contract.md`)

How Cataliva invokes genie-team:

```bash
# Invoke a specific workflow phase
claude --output-format stream-json "/deliver docs/backlog/P1-feature.md"

# Invoke with print mode (no streaming, final output only)
claude --print "/deliver docs/backlog/P1-feature.md"

# Expected exit codes
# 0 = success (artifacts written)
# 1 = failure (error in execution)
```

Expected artifact locations after each phase:

| Command | Output Artifact | Location |
|---------|-----------------|----------|
| `/discover` | Opportunity Snapshot | `docs/analysis/` |
| `/define` | Shaped Work Contract | `docs/backlog/` |
| `/design` | Design Document + ADR | `docs/backlog/` + `docs/decisions/` |
| `/deliver` | Code changes + tests | Target repo files |
| `/discern` | Review verdict | `docs/backlog/` (status updated) |

### 4. Completion Signal Convention

Final text block in stream includes structured completion:

```
## Completion
- **Status:** success | failure | blocked
- **Artifacts:** [list of files written]
- **Next:** [recommended next command]
```

## Options (Ranked)

### Option 1: Documentation + Rules (Recommended)

- **Description:** Add safety rules as `.claude/rules/` file, conventions as `docs/architecture/` files
- **Pros:** No code changes, additive, follows existing patterns, small appetite
- **Cons:** Conventions are advisory (not enforced by code)
- **Appetite fit:** Perfect — small batch, prompt engineering only

### Option 2: Structured Output Wrapper

- **Description:** Build a bash wrapper that adds structured JSON envelope around genie output
- **Pros:** Machine-parseable output guaranteed
- **Cons:** Requires code, adds maintenance, duplicates native stream-json
- **Appetite fit:** Too big for the value add

## Dependencies

- None — uses existing platform capabilities

## Routing

- [x] **Architect** — Design streaming convention mapping and CLI contract

**Rationale:** Conventions need careful design to be useful for Cataliva integration without over-engineering.

## Artifacts

- **Contract saved to:** `docs/backlog/P1-autonomous-execution-readiness.md`
- **Consolidates:** P1-progress-streaming-protocol, P1-repo-aware-execution, P2-cataliva-integration (genie-team side)
- **ADR referenced:** `docs/decisions/ADR-001-thin-orchestrator.md`

---

# End of Shaped Work Contract
