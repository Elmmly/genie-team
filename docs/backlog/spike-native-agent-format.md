---
spec_version: "1.0"
type: spike
id: spike-native-agent-format
title: "Spike: Native .claude/agents/ Format for Genie Definitions"
status: shaped
created: 2026-02-05
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [spike, agents, claude-code, architecture]
acceptance_criteria:
  - id: AC-1
    description: "Critic genie is defined as .claude/agents/critic.md with tool restrictions, permission mode, skills injection, model selection, and persistent memory"
    status: pending
  - id: AC-2
    description: "Side-by-side comparison of /discern via current pattern vs native agent on the same implementation, documenting differences in behavior, enforcement, and output quality"
    status: pending
  - id: AC-3
    description: "Findings document answers: Does tool restriction prevent Critic from accidentally editing files? Does persistent memory improve review quality? Does skills injection work as expected?"
    status: pending
---

# Spike: Native .claude/agents/ Format for Genie Definitions

**Date:** 2026-02-05
**Question:** Does converting a genie to `.claude/agents/` format provide better enforcement and ergonomics than the current multi-file prompt pattern?

---

## Context

Claude Code now supports `.claude/agents/` — custom subagent definitions as single markdown files with YAML frontmatter. This provides native support for capabilities that genie-team currently achieves through prompt engineering across multiple files:

| Capability | Current Genie Pattern | `.claude/agents/` Native |
|---|---|---|
| Model selection | Hardcoded or inherited | `model: sonnet` in frontmatter |
| Tool restrictions | Honor system (prompt says "don't write") | `tools: Read, Grep, Glob` enforced |
| Persistent memory | Document trail in `docs/` | `memory: project` with auto-injected MEMORY.md |
| Auto-delegation | Must invoke `/command` explicitly | `description` field triggers automatic use |
| Permission control | Inherited from parent | `permissionMode: plan` (read-only) |
| Hooks | None per-agent | `hooks:` in frontmatter |
| Skills injection | Manual context loading in command file | `skills: [spec-awareness]` in frontmatter |

Current Critic genie lives across 3+ files:
- `genies/critic/GENIE.md` (identity)
- `genies/critic/CRITIC_SPEC.md` (detailed spec)
- `genies/critic/CRITIC_SYSTEM_PROMPT.md` (judgment rules)
- `.claude/commands/discern.md` (command that invokes it)

---

## Test Plan

### Step 1: Create native agent

Write `.claude/agents/critic.md` with:

```yaml
---
name: critic
description: "Code review specialist for acceptance criteria verification, pattern compliance, and quality assessment. Use when reviewing implementations against specs and designs."
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
skills:
  - spec-awareness
  - architecture-awareness
  - brand-awareness
memory: project
---
```

Body contains the Critic system prompt content (consolidated from GENIE.md + CRITIC_SYSTEM_PROMPT.md).

### Step 2: Run comparison

Pick a recent implementation (or the workshop mode changes from this session). Run review two ways:

1. **Current pattern:** `/discern docs/backlog/P2-workshop-mode-shaper-architect.md`
2. **Native agent:** `Task(subagent_type='critic', prompt='Review the workshop mode implementation...')`

### Step 3: Document findings

Compare:
- Did tool restriction (`tools: Read, Grep, Glob, Bash`) prevent the Critic from using Write/Edit?
- Did `permissionMode: plan` enforce read-only access?
- Did `skills` injection load spec-awareness, architecture-awareness, brand-awareness automatically?
- Did `memory: project` create a persistent memory directory? What did it store?
- Was the output quality comparable to the current multi-file pattern?
- What was the token cost difference?

---

## Expected Outcomes

**If native format is better:** Path toward consolidating genie definitions from multi-file prompt pattern to single-file `.claude/agents/` format. The command files (`.claude/commands/`) would become thin wrappers that invoke native agents with workflow context.

**If native format is equivalent:** No migration needed, but persistent memory and tool restrictions may be worth adopting selectively.

**If native format is worse:** Document why — likely context loading or output formatting limitations. The current multi-file pattern may provide richer context than a single frontmatter + body can.

---

## Appetite

**Small batch (half day).** One file to create, one review to run both ways, findings to document.

---

# End of Spike
