---
adr_version: "1.0"
type: adr
id: ADR-003
title: "Deep reasoning as default for Scout and Architect"
status: accepted
created: 2026-02-25
decided: 2026-02-25
deciders: [navigator]
domain: genies
spec_refs:
  - docs/specs/genies/extended-thinking.md
backlog_ref: docs/backlog/P1-extended-thinking-integration.md
tags: [extended-thinking, scout, architect, reasoning, model-selection]
---

# ADR-003: Deep reasoning as default for Scout and Architect

## Context

Claude Code already has extended thinking enabled by default and provides effort-level controls (low/medium/high) on Opus 4.6 via adaptive reasoning. Genie-team's agents run within Claude Code but do not leverage these capabilities intentionally — Scout runs on haiku (cheapest, shallowest reasoning), Architect runs on sonnet.

The spike (`docs/analysis/20260225_spike_extended_thinking_feasibility.md`) confirmed:
- Extended thinking **cannot** be set in agent YAML frontmatter (no `thinking` field exists)
- Claude Code **already enables** extended thinking by default for all models
- Effort level is controllable via `CLAUDE_CODE_EFFORT_LEVEL` env var or `/model` UI
- Haiku 4.5 supports thinking but has the weakest reasoning capability
- Thinking tokens cost the same as output tokens (no premium)

The Navigator's decision: **Scout and Architect should always think deeper unless toggled off.** The original "opt-in `--deep` flag" approach (Alternative A) is rejected in favor of always-on deep reasoning with opt-out.

## Alternatives Considered

| Alternative | Pros | Cons | Risk |
|-------------|------|------|------|
| **A: Explicit `--deep` flag (opt-in)** | Zero surprise, user controls cost | Capability stays undiscovered; users forget to use it | Low |
| **B: Automatic heuristic trigger** | Low friction, educates by example | False positives; harder to explain | Medium |
| **C: Always-on deep reasoning (opt-out)** | Maximum quality by default; reasoning depth matches task importance | Higher baseline cost for Scout (haiku → sonnet) | Medium |

## Decision

**Alternative C: Always-on deep reasoning with opt-out.**

### Implementation

1. **Scout model upgrade: haiku → sonnet.** Sonnet provides significantly deeper reasoning for discovery tasks. The cost increase is justified — shallow discovery leads to shallow products. Scout's role (research, assumption surfacing, evidence analysis) benefits most from reasoning depth.

2. **Architect stays on sonnet.** Already on the right model. Add prompt instructions reinforcing thorough reasoning for design decisions.

3. **Deep reasoning prompt instructions** added to both Scout and Architect agent definitions. These instructions direct the model to reason thoroughly through assumptions, evidence quality, and edge cases before producing output. This complements Claude Code's built-in thinking (which is already enabled) with domain-specific reasoning guidance.

4. **Opt-out via `--fast` flag** on `/discover` and `/design` commands. When passed, the command includes a prompt instruction to prioritize speed over depth — skip exhaustive evidence analysis, use heuristic judgment, produce concise output. The model stays the same (sonnet); only the reasoning instructions change.

5. **Reasoning mode tracking.** Scout's Opportunity Snapshot and Architect's Design Document include `reasoning_mode: deep` (default) or `reasoning_mode: fast` (when `--fast` is passed) in frontmatter for traceability.

### Why not upgrade to Opus?

Opus provides the deepest reasoning and adaptive thinking, but at ~10x the cost of sonnet. Sonnet with deep reasoning instructions is the right cost/quality balance. Users on Opus (via `/model` or `CLAUDE_CODE_EFFORT_LEVEL=high`) automatically get even deeper reasoning — no genie-team changes needed.

### Mechanism: prompt instructions (not API parameter)

The spike confirmed that `thinking` cannot be set in agent YAML. However, Claude Code already enables thinking at the runtime level. Our role is to provide **domain-specific reasoning guidance** via prompt instructions — telling Scout and Architect *what* to reason deeply about, not *whether* to reason deeply (that's already on).

## Consequences

### Positive
- Scout produces deeper discovery analysis by default — better assumption surfacing, richer evidence grading
- Architect produces more thorough designs — better risk identification, more considered tradeoffs
- Reasoning depth is visible in output frontmatter (`reasoning_mode: deep|fast`)
- Users who want speed have a clear escape hatch (`--fast`)
- No API changes required — pure prompt engineering

### Negative
- Scout cost increases (haiku → sonnet): ~5x per-token cost increase
- Scout latency increases: sonnet is slower than haiku
- Users accustomed to fast Scout responses may notice the change

### Mitigations
- `--fast` flag provides explicit speed/cost escape hatch
- Sonnet's deeper analysis should reduce rework downstream (fewer missed assumptions = fewer late-stage surprises)
- Cost is still modest: sonnet discovery sessions are ~$0.50-2.00 each

## When to Revisit

- If sonnet costs become prohibitive for high-volume discovery workflows → consider tiered model selection
- If Claude Code adds `thinking` or `effortLevel` to agent YAML frontmatter → leverage native controls
- If usage data shows `--fast` is used on >50% of invocations → reconsider the default
