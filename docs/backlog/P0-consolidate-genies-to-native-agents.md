---
spec_version: "1.0"
type: shaped-work
id: consolidate-genies
title: "Consolidate Genie Definitions into .claude/agents/ Format"
status: shaped
created: 2026-02-06
appetite: medium
priority: P0
target_project: genie-team
author: shaper
depends_on:
  - spike-P0-native-agent-format
  - P0-trim-duplicated-rules
tags: [architecture, agents, cost, optimization, consolidation]
acceptance_criteria:
  - id: AC-1
    description: "Each genie (Scout, Shaper, Architect, Crafter, Critic, Tidier, Designer) has a single .claude/agents/{name}.md file that replaces the multi-file genies/ definition"
    status: pending
  - id: AC-2
    description: "Tool restrictions are enforced via frontmatter (Critic can't Write/Edit, Scout can't Write/Edit)"
    status: pending
  - id: AC-3
    description: "Model selection is specified per agent in frontmatter (haiku for Scout/Tidier, sonnet for others)"
    status: pending
  - id: AC-4
    description: "Persistent memory is enabled per agent via memory: project"
    status: pending
  - id: AC-5
    description: "Skills injection works via frontmatter (spec-awareness, architecture-awareness, brand-awareness)"
    status: pending
  - id: AC-6
    description: "Command files invoke native agents instead of loading genies/ system prompts"
    status: pending
  - id: AC-7
    description: "genies/ directory is deprecated — install.sh no longer copies it"
    status: pending
  - id: AC-8
    description: "Output quality is equivalent to multi-file pattern (verified by running same inputs through both)"
    status: pending
---

# Shaped Work Contract: Consolidate Genie Definitions into .claude/agents/

**Date:** 2026-02-06
**Input:** Architecture review showing 5,555 lines across 27 genie files (4 files per genie) when Claude Code now supports single-file agent definitions with native enforcement.

---

## Problem / Opportunity Statement

Each genie currently lives across 4 files:
```
genies/{name}/GENIE.md              (~50 lines - identity)
genies/{name}/{NAME}_SPEC.md        (~370 lines - detailed spec)
genies/{name}/{NAME}_SYSTEM_PROMPT.md (~120 lines - judgment rules)
genies/{name}/{TEMPLATE}.md         (~100 lines - output template)
```

Claude Code's `.claude/agents/` format collapses this into one file with native features the current pattern fakes:

| Capability | Current (honor system) | Native (enforced) |
|---|---|---|
| Tool restrictions | "You MUST NOT write files" in prompt | `tools: Read, Grep, Glob` in frontmatter |
| Model selection | Inherited from session | `model: haiku` in frontmatter |
| Persistent memory | Document trail in docs/ | `memory: project` auto-injected |
| Permission mode | Inherited | `permissionMode: plan` for read-only agents |

**Cost impact:** Eliminating ~3,300 lines of redundant genie content saves ~15K tokens per full workflow. Model selection (haiku for Scout/Tidier) saves 10-20x per invocation on those agents.

## Appetite & Boundaries

- **Appetite:** Medium batch (1 week)
- **Depends on:** spike-P0-native-agent-format confirming the format works; P0-trim-duplicated-rules completing first
- **In scope:** All 7 genies migrated; command files updated; install.sh updated; genies/ deprecated
- **Out of scope:** Changing genie behavior or output formats; proactive delegation (separate spike)

## Solution Sketch

Each genie becomes `.claude/agents/{name}.md`:

```yaml
---
name: critic
description: "Code review specialist. Reviews implementations against acceptance criteria, pattern compliance, and quality standards."
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
skills:
  - spec-awareness
  - architecture-awareness
  - brand-awareness
memory: project
---

# Critic — System Prompt

[Unique judgment rules only — no duplicated cross-cutting rules]
[Output template embedded or referenced]
```

Command files change from "load SYSTEM_PROMPT.md + SPEC.md" to "invoke the native agent."

## Migration Sequence

1. **Create `.claude/agents/` files** — one per genie, consolidating identity + judgment rules + template
2. **Update command files** — reference native agents instead of loading genies/ files
3. **Update install.sh** — install agents instead of genies; deprecate genies/ copy
4. **Verify** — run same inputs through old and new patterns, compare output quality
5. **Remove genies/** — or keep as reference documentation only

## Risks

| Risk | Mitigation |
|------|-----------|
| Native format doesn't support all genie behaviors | Spike validates this first |
| Output quality degrades with shorter prompts | Before/after comparison on identical inputs |
| Memory accumulates noise over sessions | Add memory curation guidance in agent prompts |

## Routing

- [x] **Architect** — Needs technical design for agent file structure and migration path
- Blocked by: spike-P0-native-agent-format, P0-trim-duplicated-rules

---

# End of Shaped Work Contract
