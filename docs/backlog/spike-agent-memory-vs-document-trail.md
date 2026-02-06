---
spec_version: "1.0"
type: spike
id: spike-agent-memory-vs-document-trail
title: "Spike: Agent Persistent Memory vs Document Trail"
status: shaped
created: 2026-02-05
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [spike, agents, memory, document-trail, knowledge-management]
acceptance_criteria:
  - id: AC-1
    description: "Scout agent defined in .claude/agents/scout.md with memory: project enabled"
    status: pending
  - id: AC-2
    description: "3 discovery sessions run across separate conversations, testing whether the agent recalls findings from previous sessions via persistent memory"
    status: pending
  - id: AC-3
    description: "Findings document answers: What does the agent store in memory vs what belongs in docs/analysis/? Does memory complement or conflict with the document trail? Is recall quality sufficient for cross-session continuity?"
    status: pending
---

# Spike: Agent Persistent Memory vs Document Trail

**Date:** 2026-02-05
**Question:** Does the native `memory: project` feature replace, complement, or conflict with genie-team's document trail (`docs/analysis/`, `docs/backlog/`, etc.)?

---

## Context

Genie-team's knowledge management is built on a **document trail** — persistent markdown files in `docs/` that accumulate project knowledge:

- `docs/analysis/` — Discovery findings (Opportunity Snapshots)
- `docs/backlog/` — Living work items (shaped → designed → implemented → reviewed)
- `docs/specs/` — Persistent capability specifications
- `docs/decisions/` — Architecture Decision Records
- `docs/archive/` — Completed work

The new `.claude/agents/` format offers `memory: project` which gives each agent a persistent memory directory (`.claude/agent-memory/<agent-name>/`) with a `MEMORY.md` that's auto-injected into the system prompt (first 200 lines).

These two systems serve potentially different purposes:
- **Document trail:** Human-readable project knowledge, version-controlled, shared with the team
- **Agent memory:** Agent-private learning, potentially not version-controlled, optimized for agent recall

Or they might overlap — both are "things the AI should remember between sessions."

---

## Test Plan

### Step 1: Create memory-enabled scout agent

Write `.claude/agents/scout.md` with:

```yaml
---
name: scout
description: "Discovery specialist for exploring problems, surfacing assumptions, and mapping opportunities. Use for research-heavy discovery."
model: sonnet
tools: Read, Grep, Glob, WebFetch, WebSearch
memory: project
---
```

Body contains the Scout system prompt with an added instruction: "After each discovery session, update your MEMORY.md with key findings, patterns noticed, and cross-references to related topics."

### Step 2: Run 3 discovery sessions

Each in a **separate conversation** (to test cross-session memory):

1. **Session 1:** Discover authentication patterns in the codebase
2. **Session 2:** Discover error handling patterns (related but different topic)
3. **Session 3:** Discover testing patterns

After each session, the agent should both:
- Write a standard Opportunity Snapshot to `docs/analysis/` (current pattern)
- Update its `MEMORY.md` (new pattern)

### Step 3: Test recall

In a **4th session**, ask the scout agent:
- "What patterns have you noticed across this codebase?"
- "Are there any cross-cutting concerns you've identified?"
- "What should I investigate next based on what you've seen?"

### Step 4: Document findings

Compare:
- **What went to memory vs docs:** Did the agent store different things in `MEMORY.md` vs `docs/analysis/`? Or did it duplicate?
- **Recall quality:** In session 4, did the agent recall findings from sessions 1-3 via memory? How did this compare to loading `docs/analysis/` files?
- **Memory size management:** The 200-line injection limit means memory must be curated. Did the agent manage this well or did it bloat?
- **Version control:** Is `.claude/agent-memory/` in `.gitignore`? Should it be? Does the team need to share agent memory?
- **Complementary or conflicting:** Do both systems serve different purposes, or does one subsume the other?

---

## Expected Outcomes

**If memory complements docs:** Agent memory stores *meta-knowledge* (patterns across sessions, lessons learned, what to watch for) while docs store *project knowledge* (specific findings, decisions, specs). Both are valuable.

**If memory replaces docs for agents:** The agent recalls better from its own memory than from reading `docs/analysis/` files. But the document trail still serves humans — it's the team's shared record.

**If memory conflicts:** The agent gets confused by having two sources of truth, or memory drifts from what's in docs. Need to choose one or define clear boundaries.

---

## Implications for Genie-Team

If memory is complementary, every genie agent could benefit from `memory: project`:
- **Scout:** Remembers past discoveries, avoids re-exploring known territory
- **Critic:** Learns common issues in this codebase, gets sharper over time
- **Architect:** Remembers past design decisions and patterns chosen
- **Crafter:** Learns project-specific implementation patterns

This would be a significant enhancement to genie-team's value proposition — agents that get better at *your specific project* over time.

---

## Appetite

**Small batch (1 day).** One agent file, 4 short sessions, comparison analysis.

---

# End of Spike
