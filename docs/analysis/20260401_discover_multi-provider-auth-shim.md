---
type: discover
topic: "multi-provider-auth-shim"
reasoning_mode: deep
status: active
created: "2026-04-01"
---

# Opportunity Snapshot: Multi-Provider Auth Shim

## 1. Discovery Question

**Original:** Explore the opportunity space for shimming auth across multiple AI providers (Claude Code, Gemini CLI, OpenAI Codex) in the genie-team project.

**Reframed:** What problems does single-provider dependency create for genie-team users, and what are the actual boundaries of portability given that the orchestrator depends on platform-specific runtime features (tools, hooks, context loading, session management) -- not just model APIs?

The original framing implies the problem is "auth needs to be abstracted." But auth is a thin layer (38 lines of production code in `auth.ts`). The real question is whether the *runtime* is portable -- auth is just the entry door.

### Alternative Framing Considered

I considered framing this as "how do we reduce Claude Code vendor lock-in?" But that assumes lock-in is a problem users are experiencing today. The evidence suggests genie-team's value proposition is *specifically* Claude Code's agentic capabilities. The more productive framing is: what would multi-provider support actually buy users, and at what cost?

## 2. Observed Behaviors / Signals

### Market signals

- **Competitor parity is converging.** As of early 2026, Gemini CLI (`@google/gemini-cli-sdk`), OpenAI Codex (`@openai/codex-sdk`), and Claude Code (`@anthropic-ai/claude-agent-sdk`) all offer programmatic SDKs with: agent loop execution, tool management, hooks/callbacks, session continuity, and project context loading. This is new -- 12 months ago only Claude had this.

- **Multi-provider gateways are mainstream.** LiteLLM (100+ providers), Vercel AI SDK (25+ providers), and similar tools have established the pattern of unified interfaces over multiple LLM providers. However, these abstract the *model API*, not the *agent runtime*.

- **Agent runtime SDKs are provider-specific.** Each agent SDK has its own tool naming, hook lifecycle, context-loading mechanism, and execution model. There is no "OpenAI-compatible" standard for agent runtimes the way there is for chat completions.

- **AGENTS.md is emerging.** OpenAI Codex uses `AGENTS.md` for project context (analogous to `CLAUDE.md`). Gemini CLI uses `GEMINI.md`. The pattern is universal; the filenames are not.

### Codebase signals

- **SDK coupling is narrow.** The `@anthropic-ai/claude-agent-sdk` import appears in exactly ONE production file: `src/core/phase-executor.ts`. The `query()` function is the sole touchpoint. All other modules (auth, config, hooks, execution) are framework-agnostic TypeScript.

- **Auth layer is trivially thin.** `src/environment/auth.ts` is 77 lines, handling only `ANTHROPIC_API_KEY` detection and env-var passthrough. There is no complex auth flow to abstract.

- **Tool names are Claude Code-specific.** Phase configs reference `["Read", "Grep", "Glob", "Write", "Edit", "Bash", "Task", "WebSearch", "WebFetch"]` -- these are Claude Code built-in tool names. Gemini CLI and Codex have equivalent capabilities but different tool names and interfaces.

- **Hooks are SDK-specific.** `PostToolUse` hook shape, the streaming message protocol (`type: "system"`, `type: "result"`), and options like `settingSources`, `permissionMode`, `maxBudgetUsd` are all Claude Agent SDK-specific interfaces.

- **Model tiers are Claude-only.** `genie-config.yaml` defaults reference `claude-opus-4-6`, `claude-sonnet-4-6`, `claude-haiku-4-5` -- no cross-provider model identifiers.

## 3. Pain Points / Friction Areas

### For current users
- **No evidence of user pain from single-provider dependency.** The project is Claude Code-native. Users chose it because they use Claude Code. No issues, discussions, or feedback about wanting to use other providers have been surfaced.

### Hypothetical pain points if multi-provider were needed
- **Cost optimization blocked.** Users cannot route cheaper phases (discover, commit) to less expensive providers while keeping expensive phases (deliver) on Claude.
- **Provider outages are single-point failures.** If Claude Code goes down, the entire workflow stops. No fallback path exists.
- **Model evaluation friction.** Users cannot A/B test different providers for quality on specific phases without rewriting configuration.
- **Enterprise procurement constraints.** Some organizations mandate specific providers or have existing credits with non-Anthropic providers.

### Pain points that multi-provider auth would NOT solve
- **Tool incompatibility.** Even with unified auth, `Read`/`Write`/`Edit`/`Bash` tool names and behaviors differ across runtimes.
- **Context loading differences.** `CLAUDE.md` vs `AGENTS.md` vs `GEMINI.md` -- each runtime loads project context differently.
- **Hook lifecycle differences.** `PostToolUse` in Claude SDK has no direct equivalent in Gemini's `onActivity` callback or Codex's hook model.
- **Prompt engineering portability.** Genie system prompts (agents/*.md) are tuned for Claude's instruction-following characteristics.

## 4. JTBD / User Moments

**Primary Job:** "When setting up genie-team for my team, I want to use whatever AI provider we already have budget/approval for so I can adopt structured workflows without a new vendor approval process."

**Secondary Job:** "When running autonomous genie phases, I want to route different phases to different models so I can optimize cost without sacrificing quality on critical phases."

**Tertiary Job:** "When a provider has an outage, I want the workflow to fallback to an alternative provider so I can maintain delivery momentum."

## 5. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| Users want multi-provider support | Value | Low | General market trend toward multi-provider; enterprise procurement patterns | Zero user requests; project explicitly markets as Claude Code extension; README says "extending Claude Code" |
| Auth is the main barrier to multi-provider | Feasibility | Low | Auth *is* different per provider (API keys, OAuth2, service accounts) | Auth is 77 lines of code. The real barriers are tool naming, hook lifecycles, context loading, prompt tuning -- all much harder |
| Competitor agent SDKs are mature enough | Feasibility | Moderate | Gemini CLI SDK and Codex SDK both exist with tool management, hooks, and programmatic APIs as of 2026 | SDK maturity varies; Gemini CLI SDK is newer; Codex SDK documentation is thin; hook parity is unclear |
| Cross-provider tool naming can be mapped | Feasibility | Moderate | All three runtimes have equivalent capabilities (file read/write, shell exec, search) | Tool schemas, error handling, and behavioral nuances differ; mapping is possible but lossy |
| Genie prompts work across providers | Usability | Low | LLMs generally follow similar instruction patterns | Prompts are specifically tuned for Claude's behavior; system prompt loading differs per runtime; prompt quality would degrade |
| Cost savings justify the effort | Viability | Low | Cheaper models exist for simple phases | Engineering cost of abstraction layer + maintenance of three provider paths likely exceeds model cost savings for months |

### Evidence grade justifications

- **"Users want multi-provider" rated Low:** No direct user signal. Market trend is real but applies to API-level abstraction (LiteLLM/Vercel AI SDK), not agent-runtime abstraction. The project's README and CLAUDE.md explicitly position it as a Claude Code extension.

- **"Auth is the main barrier" rated Low:** The auth module is 77 lines with one env var check. Abstracting it is trivial. But auth abstraction without runtime abstraction accomplishes nothing -- you cannot authenticate to Gemini CLI and then send Claude Code SDK `query()` calls.

- **"Competitor SDKs are mature" rated Moderate:** Both `@google/gemini-cli-sdk` and `@openai/codex-sdk` exist and are documented. However, SDK maturity for *programmatic embedding* (not just CLI usage) is less proven. The Gemini CLI SDK has `GeminiCliAgent` with `ToolRegistry` and `onActivity` callbacks. Codex SDK has `startThread()`/`run()`. Feature parity with Claude's `query()` options (settingSources, systemPrompt, permissionMode, maxBudgetUsd, resume, hooks) is unconfirmed.

- **"Genie prompts work across providers" rated Low:** The genie prompt files (agents/*.md) are engineered for Claude's instruction-following and tool-use patterns. Each provider has different system prompt semantics, tool calling conventions, and behavioral characteristics. Prompt portability is the largest hidden cost.

## 6. Technical Signals

- **Feasibility:** complex
- **Constraints:**
  - SDK coupling in `phase-executor.ts` is narrow (one import, one function call) -- good isolation point
  - Tool allowlists in `phase-config.ts` are Claude Code-specific tool names
  - Hook interfaces (`PostToolUse`, streaming message types) are SDK-specific
  - `settingSources: ["user", "project"]` and `systemPrompt: { type: "preset", preset: "claude_code" }` are Claude-specific context loading
  - Session continuity via `resume` parameter is SDK-specific
  - `buildAuthEnv()` manipulates `ANTHROPIC_API_KEY` specifically
  - Model identifiers in `genie-config.ts` defaults are all Claude models
- **Needs Architect spike:** yes -- if this proceeds, the key technical question is whether a provider abstraction at the `runPhase()` boundary can preserve genie workflow semantics across runtimes

### Layered coupling analysis

The coupling is not uniform. Sorted by difficulty to abstract:

1. **Easy:** Auth (env var names differ, but the pattern is identical: detect key, build env)
2. **Easy:** Model identifiers (string mapping, already configurable via genie-config.yaml)
3. **Moderate:** SDK entry point (query() vs GeminiCliAgent.run() vs codex.thread.run())
4. **Moderate:** Result shape (streaming messages vs callbacks vs promises)
5. **Hard:** Tool naming and allowlisting (Read/Write/Edit vs provider equivalents)
6. **Hard:** Hook lifecycle (PostToolUse vs onActivity vs Codex hooks)
7. **Hard:** Context loading (CLAUDE.md/settingSources vs GEMINI.md vs AGENTS.md)
8. **Very Hard:** Prompt engineering portability (behavioral tuning per model family)

## 7. Opportunity Areas (Unshaped)

1. **Provider-abstracted execution boundary.** The `runPhase()` function in `phase-executor.ts` is already a natural seam. The problem space: can this seam become a provider-agnostic interface without losing the governance features (hooks, budget caps, session resume) that motivated the SDK migration in the first place?

2. **Configuration-driven provider selection.** The `genie-config.yaml` already maps genies to model tiers. The problem space: extending this to include provider selection (not just model selection) so users can express preferences like "use Gemini for discover, Claude for deliver."

3. **Context file portability.** Three runtimes, three project context files. The problem space: users maintaining `CLAUDE.md`, `AGENTS.md`, and `GEMINI.md` is unsustainable. Is there a way to maintain one source of truth that feeds all three?

4. **Auth credential management across providers.** The problem space: users juggling `ANTHROPIC_API_KEY`, `GEMINI_API_KEY`, `OPENAI_API_KEY` with different auth models (API key, OAuth, service accounts). Not about abstracting auth code -- about reducing the operational burden of credential management for multi-provider setups.

5. **Graceful degradation / fallback.** The problem space: when a provider is unavailable or a budget is exhausted, can the system try an alternative provider rather than failing? This is a resilience concern independent of "multi-provider support."

## 7b. Internal Prior Art: Cataliva

Elmmly's Cataliva project (user-facing web app) already implements multi-provider AI support across Anthropic, OpenAI, and Google. Key patterns worth noting:

**Provider interface (Go, `/pkg/llm/provider.go`):**
```go
type Provider interface {
    Complete(ctx, req) → (resp, error)
    Stream(ctx, req) → (chan StreamEvent, error)
    Name() string
    Models() []ModelInfo
    ValidateKey(ctx, apiKey) error
}
```

**What Cataliva solved:**
- **Unified tool schema** — `Tool { Name, Description, InputSchema }` and `ToolCall { ID, Name, Input }` work across all three providers. Each provider adapter maps to/from provider-specific formats (Anthropic `tool_use` blocks, OpenAI `tool_calls` array, Google `functionCall` parts).
- **Registry + Factory** — Providers register themselves. New providers are additive.
- **Gateway pattern** — Resolves (tenantID, providerName, model) → concrete Provider instance. Supports per-context defaults.
- **Auth per provider** — Encrypted credential storage with per-tenant key derivation. API keys stored encrypted, decrypted at provider instantiation.

**What Cataliva does NOT solve (for our purposes):**
- **Agent runtime abstraction.** Cataliva abstracts the *model API* (completion/streaming). Genie-team needs to abstract the *agent runtime* (tool execution, file access, session management, project context loading). These are different layers.
- **Hook lifecycle.** Cataliva has no equivalent to SDK PostToolUse hooks — it manages tool calls at the application level, not delegated to an agent runtime.
- **Context loading.** No CLAUDE.md/AGENTS.md/GEMINI.md handling — context is managed by the web app.

**Portable patterns for genie-team:**
- Provider interface shape (Complete/Stream + metadata)
- Registry + Factory for extensible provider management
- Unified tool schema (Name, Description, InputSchema as JSON Schema)
- Gateway/resolver for provider + model selection
- Auth: env-var-based for CLI (skip the encryption layer, that's multi-tenant web concern)

**Assessment:** Cataliva proves the *model API* abstraction is well-understood within Elmmly. The gap for genie-team is one layer up: abstracting the *agent runtime*, which none of the three CLI SDKs have standardized yet. Cataliva's tool schema pattern is directly reusable; the provider interface shape is inspirational but would need a different contract for agent execution.

## 8. Evidence Gaps

- **No user demand signal.** Zero feature requests, issues, or feedback asking for multi-provider support. This is the largest gap -- we may be solving a problem nobody has.

- **SDK feature parity unknown.** Gemini CLI SDK and Codex SDK documentation exists, but detailed comparison of hook capabilities, tool schemas, and session management features against Claude Agent SDK has not been done.

- **Prompt portability cost unknown.** No testing of genie system prompts on non-Claude models. The quality degradation (or lack thereof) is entirely unmeasured.

- **User profile unclear.** Who would use genie-team with a non-Claude provider? Enterprise users with procurement constraints? Cost-optimizers? Curious experimenters? The user segment matters for prioritization.

- **Maintenance burden unquantified.** Supporting N providers means N provider paths to maintain, test, and debug. The ongoing cost vs. the one-time build cost is unknown.

## 9. Routing Recommendation

- [ ] **Continue Discovery** -- More exploration needed
- [ ] **Ready for Shaper** -- Problem understood
- [x] **Needs Architect Spike** -- Technical feasibility unclear
- [x] **Needs Navigator Decision** -- Strategic question

**Rationale:**

This discovery reveals a significant framing mismatch. The topic asks about "shimming auth" -- but auth is a 77-line module and the *easiest* part of multi-provider support. The hard parts are tool abstraction, hook lifecycle mapping, context loading, and prompt portability.

More fundamentally, there is **no evidence of user demand** for multi-provider support. The project explicitly positions itself as a Claude Code extension. Multi-provider support would be a strategic pivot, not an incremental feature.

Before investing in shaping or architecture, two things need to happen:

1. **Navigator decision on strategic intent.** Is multi-provider support:
   - (a) A defensive moat against vendor lock-in concerns?
   - (b) A market expansion play (reach Gemini/Codex users)?
   - (c) A cost optimization lever (cheaper models for some phases)?
   - (d) Not worth pursuing given the coupling depth?

   Each answer leads to very different scoping. Option (c) is achievable without full runtime abstraction -- you could use cheaper Claude models (already supported via genie-config.yaml tiers) rather than switching providers entirely.

2. **Architect spike on SDK parity.** If the Navigator decides multi-provider is worth pursuing, the next step is a hands-on spike comparing `query()`, `GeminiCliAgent.run()`, and `codex.thread.run()` at the API surface level. The spike would answer: can a common `PhaseExecutor` interface preserve the governance features (hooks, budget, session resume) across all three?

**Updated after Cataliva review:** The discovery phase is complete — we now understand the problem space, the coupling layers, and have internal prior art to draw from. The remaining questions are strategic (is this worth doing?) and feasibility (can agent runtimes be abstracted?), not discovery questions. Changed routing from "Continue Discovery" to "Needs Architect Spike."

If the Navigator decides to proceed, the architect spike should:
1. Compare `query()`, `GeminiCliAgent.run()`, and `codex.thread.run()` at the API surface level
2. Prototype a `PhaseExecutor` interface inspired by Cataliva's `Provider` pattern but operating at the agent-runtime layer
3. Test one genie prompt (e.g., `/discover`) against all three runtimes to measure quality degradation
4. Answer: can governance features (hooks, budget caps, session resume) survive the abstraction?

Do not proceed to shaping until both the strategic question and the feasibility question are answered.
