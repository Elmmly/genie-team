---
spec_version: "1.0"
type: shaped-work
id: trim-duplicated-rules
title: "Trim Duplicated Rules from Genie System Prompts"
status: done
completed: 2026-02-09
completed_by: "consolidate-genies-to-native-agents (1d558da)"
created: 2026-02-06
appetite: small
priority: P0
target_project: genie-team
author: shaper
depends_on: []
tags: [cost, optimization, prompts, rules]
acceptance_criteria:
  - id: AC-1
    description: "Genie system prompts reference .claude/rules/ by name instead of restating their content"
    status: met
  - id: AC-2
    description: "Each system prompt is reduced by 30-40% in line count"
    status: met
  - id: AC-3
    description: "No behavioral change — genies produce identical output quality after trimming"
    status: met
  - id: AC-4
    description: "Cross-cutting concerns (TDD, code quality, pattern enforcement) appear ONCE in rules, not duplicated in each system prompt"
    status: met
---

# Shaped Work Contract: Trim Duplicated Rules from Genie System Prompts

**Date:** 2026-02-06
**Input:** Audit showing ~1,500 lines of duplicated content between `.claude/rules/` and `genies/*/SYSTEM_PROMPT.md`.

---

## Problem / Opportunity Statement

Rules in `.claude/rules/` are automatically loaded into every Claude Code session. Genie system prompts then restate the same guidance — TDD discipline, code quality standards, pattern enforcement, error handling. This duplication adds ~1,500 tokens per genie invocation for zero additional value.

The duplication also creates a maintenance burden — when a rule changes, it must be updated in both `.claude/rules/` and every system prompt that restates it.

## Evidence

Cross-cutting rules duplicated across system prompts:
- **TDD discipline** — restated in Crafter system prompt (already in `.claude/rules/tdd-discipline.md`)
- **Code quality** — restated in Crafter, Architect system prompts (already in `.claude/rules/code-quality.md`)
- **Pattern enforcement** — restated in Architect system prompt (already in `.claude/skills/pattern-enforcement.md`)
- **Error handling** — restated in Crafter, Architect (already in `.claude/rules/code-quality.md`)

## Appetite & Boundaries

- **Appetite:** Small batch (1 day)
- **In scope:** Trim duplicated content from all 7 genie system prompts; replace with references
- **Out of scope:** Changing what the rules say; adding new rules; restructuring commands

## Solution Sketch

For each genie system prompt, replace duplicated sections with:

```markdown
## Cross-Cutting Standards

This genie follows the project's established rules (loaded automatically):
- **TDD Discipline** — see `.claude/rules/tdd-discipline.md`
- **Code Quality** — see `.claude/rules/code-quality.md`
- **Pattern Enforcement** — see `.claude/skills/pattern-enforcement.md`

The sections below cover ONLY this genie's unique judgment rules.
```

Then remove the restated content, keeping only genie-specific judgment rules.

## Risks

| Risk | Mitigation |
|------|-----------|
| Genie behavior degrades without explicit restated rules | Rules are still loaded — they're in `.claude/rules/`. Test with before/after comparison on same input. |
| Future contributors don't realize rules exist | The reference section makes them discoverable |

## Routing

- [x] **Crafter** — Systematic text reduction across 7 files

---

# End of Shaped Work Contract
