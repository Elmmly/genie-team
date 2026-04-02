---
type: spike
question: "Can a common PhaseExecutor interface abstract across Claude Agent SDK, Gemini CLI SDK, and OpenAI Codex SDK?"
status: complete
created: "2026-04-02"
verdict: not-feasible-as-framed
discovery_ref: docs/analysis/20260401_discover_multi-provider-auth-shim.md
---

# Spike: Multi-Provider PhaseExecutor Feasibility

**Question:** Can a common PhaseExecutor interface abstract across Claude Agent SDK, Gemini CLI SDK, and OpenAI Codex SDK while preserving genie workflow semantics?

**Verdict:** NOT FEASIBLE as framed. The three "SDKs" are not comparable. Reframed recommendation below.

## Critical Finding: SDK Parity Does Not Exist

| Product | Programmatic SDK | Status |
|---------|-----------------|--------|
| Claude Code | `@anthropic-ai/claude-agent-sdk` — published npm, full types, 22 hook events, sessions, budget caps | Production |
| Gemini CLI | **No SDK.** CLI binary only. No programmatic API | CLI-only |
| OpenAI Codex CLI | **No SDK.** CLI binary only. Project appears dormant | CLI-only |

A "multi-provider abstraction" would wrap one real SDK and two `child_process.spawn()` calls with stdout parsing.

## Dimension Comparison

| Capability | Claude SDK | Gemini CLI | Codex CLI | Parity |
|-----------|-----------|-----------|----------|--------|
| Entry point | `query()` → `AsyncGenerator<SDKMessage>` | `spawn("gemini", args)` → stdout | `spawn("codex", args)` → stdout | Lossy |
| Typed result | `SDKResultSuccess` with cost, usage, turns | Unstructured JSON via `--json` | Plain text | Lossy |
| Streaming | 21+ typed message types | Raw text to stdout | Raw text to stdout | Lossy |
| Tool configuration | `allowedTools[]`, `disallowedTools[]`, MCP | Fixed built-in tools | Fixed built-in tools | Lossy |
| Hooks (22 events) | `PreToolUse`, `PostToolUse`, `Stop`, etc. | None | None | Lossy |
| Sessions | `resume`, `sessionId`, `forkSession` | None (stateless) | None (stateless) | Lossy |
| Budget/turns | `maxBudgetUsd`, `maxTurns` | None | None | Lossy |
| Permissions | Granular per-tool callbacks | `--auto-approve` boolean | `--approve-all` boolean | Lossy |
| Context loading | `settingSources`, `systemPrompt` (programmatic) | Reads `GEMINI.md` (convention) | Reads `AGENTS.md` (convention) | Mappable |
| Auth | `ANTHROPIC_API_KEY` or OAuth | `GEMINI_API_KEY` | `OPENAI_API_KEY` | Mappable |
| Subagents | Full `agents` config with per-agent tools/model | None | None | Lossy |
| Structured output | `outputFormat: { type: 'json_schema' }` | None | None | Lossy |

**10 of 12 dimensions are "Lossy"** — the common denominator is "send prompt, get text back."

## Why a Unified Interface Would Fail

A lowest-common-denominator PhaseExecutor would look like:

```typescript
interface PhaseExecutor {
  execute(prompt: string): Promise<{ output: string }>;
}
```

This discards: hooks, budget caps, session resume, tool configuration, permission control, structured output, streaming events, cost tracking, turn limits, subagents, and sandbox settings. These are the features that motivated ADR-005's decision to adopt the SDK in the first place.

## Recommendation: Two-Tier Architecture

Instead of a unified agent abstraction, separate the problem into two layers:

### Tier 1: Agent Runtime (Claude SDK, full fidelity)
The primary execution path. Uses `@anthropic-ai/claude-agent-sdk` directly. All governance features preserved: hooks, budget, sessions, permissions, structured output. This is what `runPhase()` does today.

### Tier 2: LLM Provider (Cataliva pattern, multi-provider)
For use cases that don't need agent-runtime features:
- Model comparison / evaluation
- Simple prompt-response workflows
- Cost optimization (route to cheaper providers for simple phases)

Cataliva's existing `Provider` interface (Complete/Stream) works here. Port to TypeScript or wrap via API.

### What This Enables for Open-Source Users

- **Claude Code users** (primary): Full genie workflow with all SDK features
- **Other provider users**: Can use genie-team's workflow structure (discover → deliver) with Tier 2 execution. Reduced fidelity (no hooks, no sessions) but the workflow orchestration still works
- **Contributors**: Can add new Tier 2 providers by implementing one interface. Tier 1 only grows if another vendor ships a real agent SDK

## If Gemini or OpenAI Ship Agent SDKs

Re-evaluate. The two-tier architecture accommodates adding new Tier 1 providers. The `PhaseExecutor` interface for Tier 1 would be:

```typescript
interface AgentExecutor {
  runPhase(phase: PhaseName, input: string, options: AgentOptions): Promise<PhaseResult>;
}

interface AgentOptions {
  model?: string;
  maxTurns?: number;
  maxBudgetUsd?: number;
  cwd?: string;
  systemPrompt?: string;
  onToolUse?: (event: ToolUseEvent) => void;
  onResult?: (result: PhaseResult) => void;
}
```

Today, only `ClaudeAgentExecutor` would implement this. The interface exists for future extensibility, not current multi-provider.

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Building Tier 2 before validating user demand | High | Medium | Defer Tier 2 until a real user requests non-Claude execution |
| Codex CLI is dormant — any integration is wasted | High | Low | Skip Codex entirely until project shows signs of life |
| Gemini ships a real SDK, invalidating subprocess approach | Medium | Low | Two-tier architecture accommodates this; Tier 1 grows |

## Next Steps

1. **Extract `AgentExecutor` interface** from `runPhase()` in `phase-executor.ts`. Single implementation (`ClaudeAgentExecutor`) wrapping current `query()` logic. No behavioral change — just an abstraction seam for future providers.
2. **Defer Tier 2** until there's a real user request for non-Claude execution.
3. **Monitor** Gemini CLI SDK and Codex SDK for programmatic API releases.
4. **Update ADR-005** to note the multi-provider assessment and two-tier decision.
