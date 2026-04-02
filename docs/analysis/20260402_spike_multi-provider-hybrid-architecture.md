---
type: spike
question: "What's the hybrid architecture for multi-provider genie execution using agent runtimes (Tier 1) and LLM API SDKs (Tier 2)?"
status: complete
created: "2026-04-02"
verdict: feasible
supersedes: docs/analysis/20260402_spike_multi-provider-phase-executor.md
discovery_ref: docs/analysis/20260401_discover_multi-provider-auth-shim.md
---

# Spike: Multi-Provider Hybrid Architecture

**Question:** How do we support multiple AI providers for genie-team execution, given that agent runtime SDKs vary in maturity but all three providers have production LLM API SDKs with tool calling?

**Verdict:** FEASIBLE via two-tier hybrid architecture.

## Corrected Framing

The first spike incorrectly concluded "not feasible" by only comparing agent runtime SDKs. The correct framing recognizes two layers:

| Layer | What it is | Claude | OpenAI | Google |
|-------|-----------|--------|--------|--------|
| **Tier 1: Agent Runtime** | CLI tool with built-in file access, tools, sessions, hooks | `@anthropic-ai/claude-agent-sdk` (production) | Codex CLI (exists, SDK maturity TBD) | Gemini CLI (exists, SDK maturity TBD) |
| **Tier 2: LLM API** | Model API client with tool/function calling | `@anthropic-ai/sdk` (production) | `openai` (production) | `@google/genai` (production) |

**Strategy:** Use Tier 1 (agent runtime) when a provider offers a programmatic SDK. Fall back to Tier 2 (LLM API with self-managed agent loop) otherwise. Both tiers implement the same `PhaseExecutor` interface.

## Tool Calling Across LLM API SDKs

All three LLM API SDKs support tool/function calling with convergent shapes:

| Dimension | Anthropic (`@anthropic-ai/sdk`) | OpenAI (`openai`) | Google (`@google/genai`) |
|-----------|--------------------------------|-------------------|-------------------------|
| Tool definition | `{ name, description, input_schema }` | `{ type: "function", function: { name, description, parameters } }` | `{ functionDeclarations: [{ name, description, parameters }] }` |
| Tool call in response | `{ type: "tool_use", id, name, input: object }` | `{ tool_calls: [{ id, function: { name, arguments: string } }] }` | `{ functionCall: { name, args: object } }` |
| Tool result submission | Content block with `tool_use_id` | Message with `role: "tool"`, `tool_call_id` | Part with `functionResponse` matched by name |
| Streaming | SSE, typed events | SSE, delta chunks | SSE, candidate parts |
| Usage tracking | `input_tokens`, `output_tokens` | `prompt_tokens`, `completion_tokens` | `promptTokenCount`, `candidatesTokenCount` |

**All dimensions are mappable.** Cataliva proves this — their Go codebase has working adapters for all three providers' tool calling. The key adaptations:
- OpenAI returns tool call arguments as a JSON string (parse it)
- Google doesn't return tool call IDs (generate sequential IDs, match results by name)
- Field name remapping for usage tracking

## Proposed Architecture

```
PhaseExecutor interface
│
├── ClaudeAgentExecutor (Tier 1)
│   └── Wraps @anthropic-ai/claude-agent-sdk query()
│   └── Full fidelity: hooks, sessions, budget, permissions, MCP, subagents
│   └── This is TODAY's runPhase() — zero behavioral change
│
├── GeminiAgentExecutor (Tier 1, future)
│   └── Wraps Gemini CLI programmatic API (when/if SDK matures)
│   └── Fidelity depends on SDK capabilities
│
├── CodexAgentExecutor (Tier 1, future)
│   └── Wraps Codex CLI programmatic API (when/if SDK matures)
│   └── Fidelity depends on SDK capabilities
│
└── LLMApiExecutor (Tier 2, fallback)
    └── Self-managed agent loop: prompt → tool call → execute → result → repeat
    └── Uses LLMClient interface (one impl per provider)
    │   ├── AnthropicLLMClient (wraps @anthropic-ai/sdk)
    │   ├── OpenAILLMClient (wraps openai)
    │   └── GoogleLLMClient (wraps @google/genai)
    └── Uses LocalToolExecutor for Read/Write/Edit/Bash/Glob/Grep
    └── Reduced fidelity: no hooks, no sessions, no MCP, no subagents
    └── But: tool use works, streaming works, cost tracking works
```

## PhaseExecutor Interface

```typescript
interface PhaseExecutor {
  runPhase(phase: PhaseName, input: string, options: PhaseOptions): Promise<PhaseResult>;
  readonly name: string;
  readonly tier: 1 | 2;
}

// PhaseOptions and PhaseResult remain as-is.
// Tier 1 executors use all options.
// Tier 2 executors ignore unsupported options (hooks, sessions)
// and document what's supported.
```

## What Tier 2 Gains vs Loses

| Capability | Tier 1 (Agent Runtime) | Tier 2 (LLM API + Self-Managed Loop) |
|-----------|----------------------|--------------------------------------|
| Tool use (Read/Write/Edit/Bash) | Built-in to runtime | We implement tool execution |
| Streaming | Typed event stream | SSE from LLM API |
| Cost tracking | SDK provides total_cost_usd | We compute from usage tokens + pricing |
| Hooks (PostToolUse etc.) | SDK hook system | We call hooks in our tool loop (full control) |
| Budget caps | SDK enforces maxBudgetUsd | We enforce in our tool loop |
| Turn limits | SDK enforces maxTurns | We enforce in our tool loop |
| Session resume | SDK manages sessions | Not available (stateless) |
| CLAUDE.md / context loading | SDK loads via settingSources | We read and prepend to system prompt |
| MCP servers | SDK manages MCP lifecycle | Not available |
| Subagents | SDK Agent tool | Not available |
| Permissions | SDK permission callbacks | We implement in tool executor |
| Sandbox | SDK sandbox settings | We implement (or skip) |

**Key insight:** Several capabilities listed as "Tier 1 only" (hooks, budget, turns, context loading, permissions) can actually be implemented in Tier 2's self-managed loop — we just do it ourselves instead of delegating to the SDK. The truly Tier 1-only features are: session resume, MCP servers, and subagents.

## Self-Managed Agent Loop (Tier 2)

```typescript
async function* runAgentLoop(
  client: LLMClient,
  toolExecutor: ToolExecutor,
  prompt: string,
  options: AgentLoopOptions,
): AsyncGenerator<AgentEvent> {
  const messages: Message[] = [{ role: "user", content: prompt }];
  let turns = 0;
  let totalCost = 0;

  while (turns < (options.maxTurns ?? 100)) {
    const response = await client.complete(messages, options.tools);
    totalCost += computeCost(response.usage, options.model);
    turns++;

    if (totalCost > (options.maxBudgetUsd ?? Infinity)) {
      yield { type: "exhausted", reason: "budget" };
      break;
    }

    // Check for tool calls
    const toolCalls = response.toolCalls;
    if (!toolCalls || toolCalls.length === 0) {
      yield { type: "result", output: response.text, cost: totalCost, turns };
      break;
    }

    // Execute tools and collect results
    messages.push({ role: "assistant", content: response.raw });
    for (const call of toolCalls) {
      options.onToolUse?.({ toolName: call.name, toolInput: call.input });
      const result = await toolExecutor.execute(call.name, call.input);
      messages.push({ role: "tool", toolCallId: call.id, content: result });
    }
  }
}
```

This is ~50 lines and gives us tool use, budget enforcement, turn limits, and hook callbacks across any LLM provider.

## Implementation Phases

### Phase 1: Extract interface (now, zero risk)
- Extract `PhaseExecutor` interface from `runPhase()`
- Create `ClaudeAgentExecutor` wrapping current `query()` logic
- Add `provider` field to `genie-config.yaml` (default: "claude")
- No behavioral change. Just an abstraction seam.

### Phase 2: LLM types + tool executor (on demand)
- Define unified `LLMClient`, `Tool`, `ToolCall`, `ToolResult` types (port from Cataliva)
- Implement `LocalToolExecutor` for Read/Write/Edit/Bash/Glob/Grep
- These are reusable across all Tier 2 providers

### Phase 3: First non-Claude provider (on demand)
- Implement one `LLMApiExecutor` (likely OpenAI, best SDK)
- Self-managed agent loop with LocalToolExecutor
- Validate prompt portability on one phase (e.g., /discover)

### Phase 4: Additional providers
- Google, others
- Community contributions welcome via the LLMClient interface

## Risks

| Risk | Likelihood | Impact | Mitigation |
|------|-----------|--------|------------|
| Prompt quality degradation on non-Claude models | High | Medium | Document Tier 2 as reduced fidelity; let community tune prompts per model |
| Tool executor security (Bash without sandbox) | Medium | High | Implement tool allowlist in LocalToolExecutor |
| Scope creep — building a full agent framework | Medium | High | Strict scope: PhaseExecutor interface + one implementation at a time |
| Gemini/Codex ship real agent SDKs, invalidating Tier 2 impls | Medium | Low | Architecture accommodates Tier 1 growth; Tier 2 becomes fallback |

## Next Step

Phase 1: Extract `PhaseExecutor` interface. This is the foundation for everything else and has zero risk — it's a refactor of existing code with no behavioral change.
