---
type: spike
question: "Can extended thinking budget be set in agent YAML frontmatter for Claude Code agents?"
status: complete
date: 2026-02-25
backlog_ref: docs/archive/agents/2026-02-25_extended-thinking-integration/P1-extended-thinking-integration.md
adr_ref: docs/decisions/ADR-003-extended-thinking-activation-strategy.md
---

# Spike: Extended Thinking Feasibility for Claude Code Agents

## Question

Can extended thinking budget be configured in agent YAML frontmatter (`.claude/agents/*.md` files) to activate extended thinking at the agent definition level, or must it be passed as an API parameter on each request?

This determines whether P1-extended-thinking-integration can be implemented as a prompt-engineering-only solution (YAML frontmatter + agent instructions) or requires code-level API changes to the claude CLI.

## Findings

### 1. Extended Thinking is an API-Level Parameter Only

**Verdict: NOT expressible in agent YAML frontmatter.**

Extended thinking is **strictly an API-level feature**. The `thinking` parameter is passed in the HTTP request body to the Claude API's `/messages` endpoint, not configured in system prompts or agent definitions.

### 1.1 API Parameter Syntax

The thinking parameter requires this JSON structure in the API request:

```json
{
  "thinking": {
    "type": "enabled",
    "budget_tokens": 1024
  }
}
```

Or for newer models (Opus 4.6, Sonnet 4.6):

```json
{
  "thinking": {
    "type": "adaptive"
  }
}
```

**Source:** [Building with extended thinking - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/extended-thinking)

### 1.2 Agent YAML Frontmatter Schema

Claude Code agent definitions support only these frontmatter fields:
- `name`, `description` (required)
- `tools`, `disallowedTools`
- `model` (sonnet, opus, haiku, or inherit)
- `permissionMode`
- `maxTurns`
- `skills`
- `mcpServers`
- `hooks`
- `memory`
- `background`
- `isolation`

**There is NO `thinking`, `budget_tokens`, or `reasoning` field in agent YAML frontmatter.**

**Source:** [Create custom subagents - Claude Code Docs](https://code.claude.com/docs/en/sub-agents#supported-frontmatter-fields)

### 2. Model Support for Extended Thinking

**Verdict: Haiku 4.5 supports extended thinking. Sonnet and Opus fully support it.**

Extended thinking is available on:

| Model | Support | Notes |
|-------|---------|-------|
| **Claude Haiku 4.5** | YES | First Haiku to support extended thinking |
| **Claude Sonnet 4.6** | YES | Supports both manual (`type: "enabled"`) and adaptive (`type: "adaptive"`) modes |
| **Claude Sonnet 4.5** | YES | Manual mode only |
| **Claude Opus 4.6** | YES | Adaptive thinking only (manual deprecated) |
| **Claude Opus 4.5** | YES | Manual mode |

**Cost implication for Scout:** Scout currently runs on Haiku. Extended thinking is supported on Haiku 4.5, so no model upgrade is required.

**Source:** [Building with extended thinking - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/extended-thinking#supported-models)

### 3. Prompt-Based Alternatives to API-Level Thinking

**Verdict: Partial feasibility. System prompt instructions can approximate extended thinking but are NOT true extended thinking.**

#### 3.1 What System Prompts Cannot Do

A system prompt instruction like "think step by step" or "reason carefully" does NOT activate Claude's native extended thinking feature. It only **instructs the model to show visible reasoning steps**—similar to chain-of-thought (CoT) prompting.

**Difference:**
- **API-level extended thinking** (`thinking` parameter): Hidden reasoning budget tracked by Claude's system, `<thinking>` content blocks in output, explicit token budget control, interleaved thinking loops
- **Prompt-based CoT**: Visible reasoning in regular output, no separate thinking budget, model must allocate output tokens to reasoning, no interleaved Think-Act-Think loops

#### 3.2 When Prompt Instructions Help

System prompts can still improve reasoning quality by:
- Instructing the model to "reason thoroughly before answering"
- Using `<thinking>` tags in few-shot examples to show the pattern
- Requesting explicit step-by-step derivation of answers
- Using structured tags like `<reasoning>` and `<answer>`

But this is **NOT a replacement for true extended thinking** — it trades off output token efficiency (reasoning consumes output tokens) for slightly deeper reasoning.

**Source:** [Extended thinking tips - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/prompt-engineering/extended-thinking-tips)

### 4. Cost Implications

**Verdict: Extended thinking uses output tokens at the same rate as regular output.**

#### 4.1 Thinking Tokens Pricing

Extended thinking tokens are **billed as output tokens**, not at a premium:

- **Claude Haiku**: Same as standard output tokens
- **Claude Sonnet**: Same as standard output tokens
- **Claude Opus**: Same as standard output tokens

**Example pricing (Anthropic 2026):**
- Input: $3 / 1M tokens
- Output (including thinking tokens): $15 / 1M tokens for Sonnet

#### 4.2 Token Budget and Cost

When you set a thinking budget:
- **Minimum budget**: 1,024 tokens
- **Actual usage**: Model typically uses less than the budget allocated
- **Cost predictability**: Set `budget_tokens: 5000` to limit thinking cost; Claude decides how much to actually use

**Scout impact:** If Scout runs 100 discovery sessions per month on haiku, and 20% of them activate extended thinking with a 5,000-token budget:
- 20 sessions × 5,000 thinking tokens = 100,000 thinking output tokens
- Cost: ~$1.50/month (negligible)

The real cost is not thinking tokens themselves but the latency increase (more computation = slower responses).

**Source:** [Pricing - Claude API Docs](https://platform.claude.com/docs/en/about-claude/pricing)

### 5. Interleaved Thinking (Think-Act-Think Loops)

**Verdict: Available via API but not expressible in agent YAML.**

Interleaved thinking (where Claude thinks, acts, observes, thinks again within a single request) is a separate capability from extended thinking. It's activated via:

```
Beta header: interleaved-thinking-2025-05-14
Supported models: Sonnet 4.5+, Opus 4.5+
Not yet supported: Haiku
```

This requires **API-level control** — it cannot be set in agent YAML or system prompts.

**Source:** [Building with extended thinking - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/extended-thinking#interleaved-thinking-beta)

### 6. Claude Code CLI Support for Thinking Parameter

**Verdict: Claude Code CLI does NOT expose thinking parameter in agent definitions or CLI flags.**

#### 6.1 What We Searched For

- Searched: "claude code --thinking-budget", "--thinking", "--effort"
- Searched: Claude Code agent YAML `thinking` field support
- Result: **No CLI flags or agent frontmatter fields for extended thinking found.**

#### 6.2 How Claude Code Could Use Thinking (Theoretical)

If Claude Code's internal API layer supported a thinking parameter, it would be passed when the CLI makes API requests. But there is **no public documentation of:**
- A `--thinking-budget` flag for `claude` CLI
- A `thinking` field in agent YAML
- Support for passing `effort` parameter in agent definitions

#### 6.3 Current Claude Code Behavior

Claude Code does support the `effort` parameter on Opus 4.6 for **adaptive thinking**, but:
- This is NOT expressible in agent YAML
- It is NOT controllable via CLI flags in the current documentation
- It is only available through API-level configuration

**Source:** [Adaptive thinking - Claude API Docs](https://platform.claude.com/docs/en/build-with-claude/adaptive-thinking)

## Feasibility Verdict

### Can extended thinking be set in agent YAML frontmatter?

**NO — NOT FEASIBLE with current Claude Code.**

Extended thinking is an API-level parameter that cannot be expressed in agent YAML frontmatter. The Claude Code platform does not expose `thinking` or `budget_tokens` fields in agent definitions.

### What ARE the feasible options?

| Option | Feasibility | Mechanism | Constraints |
|--------|-------------|-----------|-------------|
| **A1: Prompt instruction (CoT)** | YES, NOW | System prompt + few-shot examples | Not true extended thinking; trades output tokens for reasoning depth |
| **A2: API-level thinking via CLI flag** | BLOCKED | Would require `claude --thinking-budget` flag | Not currently supported by Claude Code CLI |
| **B: Always-on thinking with model override** | UNKNOWN | Scout switches to Sonnet + thinking parameter for all runs | Would require code changes to claude CLI; breaks haiku cost model |
| **C: Waiting for Claude Code feature** | FUTURE | Claude Code adds `thinking` field to agent YAML | Roadmap unknown; may or may not happen |

## Recommendation for ADR-003

**ADR-003 must choose between two viable paths:**

### Path 1: Prompt-Based Approximation (Recommended for v1)

Use **Option A1: Prompt instruction + CoT** as a fallback:

1. Scout agent adds system prompt instruction: "For complex discovery questions (containing keywords: strategic, riskiest, defensible, why), reason through assumptions step-by-step before finalizing your Opportunity Snapshot."
2. Scout Opportunity Snapshot includes a note: `reasoning_mode: enhanced` (not `extended`, to be clear about limitation)
3. No API changes required; works today
4. Limitation: Not true extended thinking; reasoning consumes output tokens

**Pros:**
- Implementable immediately in agent YAML + system prompt
- Transparent limitation (clearly marked as "enhanced" not "extended")
- Still improves reasoning depth for complex discoveries

**Cons:**
- Not the "game changer" that true extended thinking would be
- Reasoning efficiency is worse (output tokens used for reasoning)
- No visible `<thinking>` blocks in output

### Path 2: Wait for Claude Code CLI Feature

Push for Claude Code to expose a `thinking` field in agent YAML:

```yaml
---
name: scout
thinking:
  type: "enabled"
  budget_tokens: 5000
---
```

This would require an upstream request to Anthropic's Claude Code team.

**Pros:**
- True extended thinking with full capabilities
- Cost-controlled via budget_tokens
- Visible reasoning in output

**Cons:**
- Blocks on Claude Code feature development
- Timeline uncertain
- Requires out-of-scope changes to claude CLI

## Impact on P1 Shaped Contract

### Required Changes

1. **AC-1 (Feasibility):** REVISED
   - Original: "Extended thinking is expressible in agent YAML frontmatter"
   - Revised: "Scout and Crafter can activate reasoning via prompt instruction (CoT) or will use true extended thinking if Claude Code adds `thinking` field support"

2. **AC-2 (Reasoning Mode Tracking):** REVISED
   - Original: `reasoning_mode: extended`
   - Revised: `reasoning_mode: enhanced` (for prompt-based v1) or `reasoning_mode: extended` (if true extended thinking becomes available)

3. **Cost Estimate Confidence:** UPGRADED from "medium" to "HIGH"
   - Thinking tokens cost the same as output tokens
   - Budget is fully controllable
   - No surprise cost multipliers

### New Constraints

- **Cannot be implemented as true extended thinking** until Claude Code CLI supports `thinking` field in agent YAML
- **Can be implemented as prompt-instructed CoT** using only agent YAML + system prompt (no code changes)
- **Scout's haiku model can remain unchanged** if using prompt-based CoT (haiku 4.5 supports extended thinking, but we won't use it without API support)

## Technical Signals

### Feasibility Assessment

- **Prompt-based CoT:** straightforward / low risk
- **True extended thinking API integration:** blocked / requires upstream feature
- **Interleaved thinking:** blocked / not exposed in Claude Code

### Needs Architect Spike?

**NO** — This is a platform limitation, not an architecture question. The spike itself has answered the question: extended thinking cannot be set in agent YAML. The Crafter can proceed with prompt-based CoT implementation immediately if the team decides to pursue Path 1.

## Evidence Gaps

- **Claude Code CLI roadmap:** When will `thinking` field be added to agent YAML? (Requires asking Anthropic)
- **Real-world CoT performance:** How much does prompt-instructed reasoning improve Scout's analysis vs. baseline? (Requires testing after implementation)
- **Interleaved thinking on Haiku:** Will Haiku 4.6 support interleaved mode? (Requires Anthropic roadmap visibility)

## Evidence Summary

| Evidence | Type | Confidence | Status |
|----------|------|-----------|--------|
| Extended thinking is API-only | API documentation | HIGH | Verified: multiple sources |
| No `thinking` field in agent YAML | Claude Code docs | HIGH | Verified: official subagent schema |
| Haiku 4.5 supports extended thinking | Model capability matrix | HIGH | Verified: API docs |
| Thinking tokens cost = output tokens | Pricing docs | HIGH | Verified: official pricing |
| Prompt-based CoT works without API changes | Prompt engineering docs | HIGH | Verified: examples provided |
| Claude Code CLI doesn't expose `--thinking-budget` | CLI documentation search | MODERATE | No docs found; may be undocumented feature |

## Routing Recommendation

- [ ] **Continue Discovery** — Problem is fully understood
- [x] **Ready for ADR-003 Decision** — Architect and Navigator can now decide between Path 1 (prompt-based v1) and Path 2 (wait for Claude Code feature)
- [ ] **Needs Architect Spike** — Technical feasibility already determined by this spike
- [x] **Needs Navigator Decision** — Strategic choice between paths

**Rationale:** The technical feasibility question has been fully answered. Extended thinking cannot be set in agent YAML frontmatter under the current Claude Code platform. The team must now decide whether to implement a prompt-based approximation (Path 1, viable immediately) or request the feature from Anthropic (Path 2, roadmap-dependent). This is a product/strategic decision, not a technical unknown.

## Next Steps for ADR-003

1. **Navigator decision:** Choose Path 1 or Path 2
2. **If Path 1:** Crafter can implement immediately
   - Revise Scout agent system prompt with CoT instruction
   - Add complexity heuristics for keyword detection
   - Update Opportunity Snapshot frontmatter to use `reasoning_mode: enhanced`
   - Test and measure impact on analysis depth
3. **If Path 2:** Request feature from Anthropic Claude Code team
   - File feature request for `thinking` field in agent YAML
   - Estimate timeline
   - Proceed with Path 1 as interim solution
4. **Future:** Monitor Anthropic announcements for Claude Code CLI updates

## Related Documents

- **ADR-003:** docs/decisions/ADR-003-extended-thinking-activation-strategy.md
- **Shaped Contract:** docs/backlog/P1-extended-thinking-integration.md
- **Claude API Extended Thinking Docs:** https://platform.claude.com/docs/en/build-with-claude/extended-thinking
- **Claude Code Agent Schema:** https://code.claude.com/docs/en/sub-agents
