---
adr_version: "1.0"
type: adr
id: ADR-007
title: "Multi-Provider Phase Execution via Two-Tier Architecture"
status: accepted
created: 2026-04-02
deciders: [architect, navigator]
tags: [architecture, multi-provider, sdk, openai, google, abstraction]
---

# ADR-007: Multi-Provider Phase Execution via Two-Tier Architecture

## Context

Genie-team is an open-source toolkit. ADR-005 chose the Claude Agent SDK as the orchestration runtime, coupling execution to a single provider. As an open-source project, consumers should be able to bring their own AI provider rather than being locked into Anthropic.

Three providers were evaluated: Anthropic (Claude), OpenAI (GPT-4o), and Google (Gemini). The key finding from the spike (docs/analysis/20260402_spike_multi-provider-hybrid-architecture.md): these providers offer capabilities at different layers:

- **Agent Runtime SDKs** (embedded agent loop with tools, hooks, sessions): Only Claude has a mature one (`@anthropic-ai/claude-agent-sdk`). OpenAI has `@openai/agents` (generic framework, not coding-specific). Google has no official embeddable agent SDK.
- **LLM API SDKs** (model API with tool/function calling): All three have production TypeScript SDKs (`@anthropic-ai/sdk`, `openai`, `@google/genai`). Tool calling shapes are convergent and mappable. Cataliva (internal prior art) proves this mapping works in production.

### Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| Unified agent SDK abstraction | Single interface for all providers | Only Claude has a real agent SDK; others would be subprocess wrappers discarding 10 of 12 governance features | Lowest-common-denominator kills the value proposition |
| Claude-only (status quo) | Simple, full fidelity | Locks out non-Anthropic users; open-source adoption limited | Conflicts with consumer choice goal |
| LLM API only (drop agent SDK) | True multi-provider parity | Loses Claude Agent SDK governance (hooks, sessions, budget, permissions, MCP, subagents) | Throws away ADR-005's rationale |
| **Two-tier hybrid** | Full fidelity on Claude, functional on others, extensible | Two code paths to maintain; Tier 2 has reduced features | **Recommended** |

## Decision

**Accepted.** Multi-provider execution via a two-tier `PhaseExecutor` interface.

### Tier 1: Agent Runtime (full fidelity)

Wraps a provider's embeddable agent SDK. The SDK manages the agent loop, tool execution, hooks, sessions, and permissions. Today only `ClaudeAgentExecutor` exists.

Capabilities: hooks (PostToolUse), session resume, budget caps, turn limits, MCP servers, subagents, permission system, sandbox, structured output.

### Tier 2: LLM API + Self-Managed Agent Loop (functional, reduced fidelity)

Wraps a provider's LLM API SDK. Genie-team manages its own agent loop: send prompt → model returns tool calls → `LocalToolExecutor` executes them → send results back → repeat.

Capabilities: tool use (Read/Write/Edit/Bash/Glob/Grep), turn limits, budget tracking (token-based), onToolUse hooks, verbose output.

Not supported: session resume, MCP servers, subagents, provider-native permissions, sandbox.

### Provider Map

| Provider | Tier 1 | Tier 2 | CLI flag |
|----------|--------|--------|----------|
| Anthropic/Claude | `ClaudeAgentExecutor` (default) | Could add `AnthropicLLMClient` | `--provider claude` |
| OpenAI | Could add if `@openai/agents` matures | `OpenAILLMClient` | `--provider openai` |
| Google | None (no SDK) | `GoogleLLMClient` | `--provider google` |

### Interface

```typescript
interface PhaseExecutor {
  readonly name: string;
  readonly tier: 1 | 2;
  runPhase(phase: PhaseName, input: string, options?: PhaseOptions): Promise<PhaseResult>;
}
```

PhaseOptions and PhaseResult are shared across tiers. Tier 2 executors ignore unsupported options (sessions, MCP) and document what's supported.

### Unified LLM Types

Inspired by Cataliva's `pkg/llm/provider.go`:

```typescript
interface LLMClient {
  readonly name: string;
  complete(messages: Message[], options: CompletionOptions): Promise<CompletionResponse>;
}

interface ToolExecutor {
  execute(name: string, input: Record<string, unknown>): Promise<string>;
  availableTools(): Tool[];
}
```

Each provider adapter maps between these types and the provider's SDK types. The mapping is well-understood — Cataliva has working Go implementations for all three.

## Consequences

**Positive:**
- Open-source users can choose their provider via `--provider` flag
- Claude users get full Tier 1 fidelity (no regression from ADR-005)
- Adding a new Tier 2 provider requires ~100 lines (implement `LLMClient`)
- If OpenAI or Google ship mature agent SDKs, Tier 1 can grow without changing the interface
- Tool calling abstraction proven by Cataliva in production

**Negative:**
- Two code paths (Tier 1 and Tier 2) to maintain and test
- Tier 2 prompt quality may degrade on non-Claude models (genie prompts are Claude-tuned)
- Tier 2 cost tracking is token-based (no provider-reported cost like Claude SDK)
- LocalToolExecutor runs unsandboxed (no permission system in Tier 2)

**Risks:**
- Building Tier 2 before validating user demand (mitigated: interface extraction is zero-cost; provider impls are ~100 lines each)
- Prompt portability across models (mitigated: documented as reduced fidelity; community can tune prompts per model)
