---
spec_version: "1.0"
type: spec
id: sdk-orchestrator
title: SDK-Integrated Orchestrator
status: active
created: 2026-03-12
domain: platform
source: define
acceptance_criteria:
  - id: AC-1
    description: >-
      TypeScript project with @anthropic-ai/claude-agent-sdk, vitest, and
      genies-core CLI entry point. Shell genies wrapper delegates to
      genies-core when available.
    status: pending
  - id: AC-2
    description: >-
      genies check implemented in TypeScript as SDK pilot. Full environment
      health check with OK/WARN/FAIL reporting.
    status: pending
  - id: AC-3
    description: >-
      Core runPhase() using SDK query() with tool allowlisting, max turns,
      max budget, model override, and session resume.
    status: pending
  - id: AC-4
    description: >-
      SDK settingSources and systemPrompt configured to load CLAUDE.md,
      rules, skills, and agent definitions.
    status: pending
  - id: AC-5
    description: >-
      Cross-phase session continuity via SDK resume parameter.
    status: pending
  - id: AC-6
    description: >-
      Auth mode control (--auth oauth|apikey) with billing mode detection.
    status: pending
  - id: AC-7
    description: >-
      Model tier configuration via genie-config.yaml with per-genie
      assignments and genies models subcommand.
    status: pending
  - id: AC-8
    description: >-
      Async batch execution with configurable concurrency replacing bash
      polling worker pool.
    status: pending
  - id: AC-9
    description: >-
      SDK hooks for artifact tracking, cost logging, and budget enforcement.
    status: pending
---

# SDK-Integrated Orchestrator

TypeScript orchestration layer using the Claude Agent SDK to replace shell-based CLI spawning. Provides programmatic execution governance (hooks, budget caps, structured output), typed YAML/JSON parsing, async parallel execution, and session continuity across genie phases.

This capability subsumes and replaces the shell-based orchestration in `scripts/genies` and delivers the environment health features from P1-environment-health within the TypeScript migration.

## Acceptance Criteria

### AC-1: TypeScript project structure
TypeScript project initialized with `@anthropic-ai/claude-agent-sdk` dependency, vitest for testing, and `genies-core` as the compiled CLI entry point. The existing `genies` shell script is preserved as a thin wrapper that delegates to `genies-core` when it's available on PATH, falling back to bash implementation for backward compatibility.

### AC-2: genies check (SDK pilot)
The `genies check` subcommand is the first TypeScript-implemented feature, validating the toolchain end-to-end. Checks Claude CLI availability, auth method and billing mode, GitHub CLI auth, MCP server status, global/project install completeness, git state, and genie-config.yaml validity.

### AC-3: Core runPhase() via SDK
The central `runPhase()` function uses Agent SDK `query()` instead of spawning `claude -p`. Accepts phase name, input path, tool allowlist (array), max turns, max budget USD, model override, and session ID for resume. Returns a typed result object with session ID, token counts, cost, output text, and artifacts detected.

### AC-4: Project context loading
Every SDK invocation sets `settingSources: ["project"]` and `systemPrompt: { type: "preset", preset: "claude_code" }` to load CLAUDE.md, rules, skills, and agent definitions. Validated by automated test confirming project context is active.

### AC-5: Cross-phase session continuity
Session IDs from completed phases are passed to subsequent phases via SDK `resume` parameter, preserving conversation context across the genie workflow. `--no-resume` flag starts fresh sessions.

### AC-6: Auth mode control
`--auth oauth` unsets `ANTHROPIC_API_KEY` in child environment to force subscription billing. `--auth apikey` requires the key. Default detects and warns. Preflight reports billing mode.

### AC-7: Model tier configuration
`genie-config.yaml` defines tiers (reasoning/default/fast) mapped to model IDs with per-genie assignments. `genies models` displays config. Project-scoped config overrides global.

### AC-8: Async batch execution
Batch mode uses `Promise.all()` with configurable concurrency limit, replacing the bash polling-based worker pool. Each worker gets an isolated git worktree. Errors collected and reported after all workers complete.

### AC-9: SDK execution hooks
`PostToolUse` tracks artifact creation in real-time. `Stop` logs phase completion with cost. `maxBudgetUsd` enforces per-session spending caps. Hook events written to structured JSONL log.

## Design Constraints
<!-- Updated by /design on 2026-03-12 from P0-typescript-sdk-migration -->
- Shell `genies` wrapper delegates to `genies-core` via exit-code-127 fallback — unrecognized subcommands fall through to bash during migration
- SDK invocations MUST set both `settingSources: ["project"]` and `systemPrompt: { type: "preset", preset: "claude_code" }` — omitting either silently drops CLAUDE.md/rules/skills
- All file writes use `proper-lockfile` + temp file + rename pattern for atomicity — eliminates race conditions in batch mode
- All git operations via `execa` — no Node.js git libraries (behavioral parity with shell)
- Diagnostic output to stderr; stdout reserved for programmatic consumers
- `genies-core` exit code 127 signals "not handled" to shell wrapper — other exit codes propagate directly
- `genie-config.yaml` search order: project `.claude/` → global `~/.claude/` → built-in defaults
- Auth mode detection: `ANTHROPIC_API_KEY` presence is primary signal, `claude auth status` is secondary
- SDK hooks handle execution governance (artifact tracking, cost logging, budget enforcement) — Claude Code hooks remain shell scripts per platform contract

## Evidence

### Discovery
- Language migration and SDK feasibility analysis (discovery session 2026-03-12)

### Architecture
- `docs/decisions/ADR-005-sdk-integrated-orchestrator.md` (accepted)
- `docs/decisions/ADR-001-thin-orchestrator.md` (superseded)
