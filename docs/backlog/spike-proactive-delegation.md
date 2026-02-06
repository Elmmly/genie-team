---
spec_version: "1.0"
type: spike
id: spike-proactive-delegation
title: "Spike: Proactive Agent Delegation vs Explicit /commands"
status: shaped
created: 2026-02-05
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [spike, agents, claude-code, workflow, delegation]
acceptance_criteria:
  - id: AC-1
    description: "Shaper agent defined in .claude/agents/shaper.md with proactive delegation description that triggers on solution-loaded requests"
    status: pending
  - id: AC-2
    description: "Side-by-side comparison of explicit /define invocation vs natural language request with proactive delegation, documenting whether structured workflow is preserved"
    status: pending
  - id: AC-3
    description: "Findings document answers: Does auto-delegation preserve the Shaped Work Contract output format? Does the 7 D's sequence hold without explicit commands? Where does the workflow degrade?"
    status: pending
---

# Spike: Proactive Agent Delegation vs Explicit /commands

**Date:** 2026-02-05
**Question:** Could genie-team's explicit `/command` workflow be replaced by agents that auto-activate based on what you're asking?

---

## Context

The new `.claude/agents/` format supports a `description` field that Claude uses for automatic delegation. Including "proactively" in the description tells Claude to delegate without the user explicitly requesting it.

This raises a fundamental question for genie-team: if agents can auto-activate based on conversational context, do users still need explicit `/discover`, `/define`, `/design` commands? Or does the workflow happen naturally?

Example: Instead of `/define "add dark mode"`, the user just says "I want to add dark mode" and Claude auto-delegates to the Shaper agent, which produces a Shaped Work Contract.

---

## Test Plan

### Step 1: Create proactive shaper agent

Write `.claude/agents/shaper.md` with:

```yaml
---
name: shaper
description: "Problem framing specialist. Proactively activates when the user describes a feature request, solution-loaded problem, or says 'we should add' or 'let's build'. Reframes solutions as problems and produces Shaped Work Contracts."
model: sonnet
tools: Read, Grep, Glob, WebSearch
skills:
  - spec-awareness
  - architecture-awareness
  - problem-first
memory: project
---
```

Body contains the Shaper system prompt.

### Step 2: Test natural conversations

Run 3 test conversations without using any slash commands:

1. **"I want to add dark mode to the app"** — Does Claude delegate to shaper? Does a Shaped Work Contract get produced?
2. **"We should build a notification system"** — Does the problem-first skill trigger reframing?
3. **"The login page is slow"** — Does this get treated as discovery (Scout) or shaping (Shaper)?

### Step 3: Compare with explicit workflow

For the same 3 topics, run:

1. `/define "add dark mode"`
2. `/define "build a notification system"`
3. `/discover "login page performance"`

### Step 4: Document findings

Compare:
- Was the Shaped Work Contract output format preserved in auto-delegation?
- Did the Shaper's judgment rules (anti-pattern detection, appetite setting, option ranking) still apply?
- Was the spec lifecycle behavior (finding existing specs, creating new ones) triggered?
- Did the user lose control over which genie was invoked? (e.g., did "login page is slow" go to Shaper when it should have gone to Scout?)
- Was the 7 D's sequence preserved, or did steps get skipped?

---

## Expected Outcomes

**If proactive delegation works:** The explicit command layer becomes optional — power users can skip it while the structured output still happens. Commands remain as explicit overrides when you want to force a specific genie.

**If proactive delegation partially works:** Some genies (problem-first Shaper) benefit from auto-activation, but the workflow sequence (discover before define, define before design) requires explicit commands to maintain ordering.

**If proactive delegation doesn't work:** The workflow structure is the core value — auto-delegation loses the intentionality that makes genie-team effective. Commands stay as the primary interface.

---

## Key Tension

Genie-team's explicit commands encode two things:
1. **Which genie** to invoke (Shaper vs Scout vs Architect)
2. **Where in the workflow** you are (discover → define → design → deliver)

Proactive delegation can handle #1 (match request to agent) but may lose #2 (workflow position and sequencing). This spike tests whether that matters.

---

## Appetite

**Small batch (half day).** One agent file, 6 test conversations (3 natural + 3 explicit), findings document.

---

# End of Spike
