---
spec_version: "1.0"
type: shaped-work
id: skill-description-audit
title: "Audit Skill Descriptions to Prevent Short-Circuit Reading"
status: shaped
created: "2026-02-13"
appetite: small
priority: P3
target_project: genie-team
author: shaper
depends_on: []
tags: [skills, optimization, descriptions, meta]
acceptance_criteria:
  - id: AC-1
    description: "All 8 skill descriptions (plus any new skills from concurrent work) have been audited for functional summaries that could cause short-circuit reading"
    status: pending
  - id: AC-2
    description: "Descriptions that embed functional summaries ('Ensures X', 'Enforces Y and Z') have been rewritten to focus on activation context ('Use when...') without summarizing what the skill does"
    status: pending
  - id: AC-3
    description: "No skill description exceeds 200 characters — keeping them trigger-focused and concise"
    status: pending
  - id: AC-4
    description: "Total combined skill description character count is measured and documented, confirming all skills fit within Claude Code's ~15k character budget for the system prompt skill listing"
    status: pending
  - id: AC-5
    description: "Source skills in skills/ directory are updated and synced to .claude/skills/ via install.sh"
    status: pending
---

# Shaped Work Contract: Audit Skill Descriptions to Prevent Short-Circuit Reading

## Problem

Skill descriptions that summarize what the skill does — rather than only describing when to
activate — can cause Claude to follow the summary instead of reading the full skill content.

Example:
- **Bad:** "Dispatches subagent per task with code review" — Claude does ONE review based on the description
- **Good:** "Use when executing independent tasks" — Claude reads the full skill for details

The principle: descriptions should describe **when to activate** (trigger context), never
**what the skill does** (functional summary). When Claude reads a functional summary and thinks
it "knows" what the skill does, it may skip the full SKILL.md content — missing the anti-pattern
tables, RED flags, and detailed guidance.

**Current state:** Genie-team's 8 skill descriptions total ~1,942 characters (well within budget).
All include trigger context ("Use when...") but several also embed functional summaries:

| Skill | Issue |
|---|---|
| `code-quality` | "Ensures error handling, no hardcoded values, proper patterns, and security considerations" — summarizes what it enforces |
| `tdd-discipline` | "Ensures tests are written before implementation" — summarizes the key rule |
| `pattern-enforcement` | "Ensures consistency with established patterns" — summarizes the outcome |

**Evidence:** 7 of 8 skill descriptions contain functional summaries alongside their trigger
context. Whether this is actively causing short-circuit reading in genie-team is uncertain
(see `docs/analysis/20260213_discover_skill_enforcement_gaps.md`, Section 8D), but the fix
is low-cost and low-risk.

## Appetite & Boundaries

- **Appetite:** Small (half day) — reviewing and rewriting 8 short description strings
- **No-gos:**
  - Do NOT change skill content or behavior — descriptions only
  - Do NOT change skill frontmatter fields other than `description`
  - Do NOT change command or agent descriptions (different mechanism)
- **Fixed elements:**
  - Descriptions must still be accurate about activation context
  - Must measure and document total character footprint

## Goals & Outcomes

Claude reliably reads full skill content instead of short-circuiting on description summaries.
Skills trigger correctly based on context, and agents follow the detailed guidance inside each
skill rather than approximating from the description.

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|---|---|---|
| Claude actually short-circuits on functional descriptions | feasibility | Known failure mode with skill descriptions; test with before/after comparison |
| Shorter trigger-only descriptions improve skill usage | usability | Compare agent behavior before/after on same task |
| ~15k char budget applies to genie-team's Claude Code version | feasibility | Check Claude Code documentation or test empirically |

## Solution Sketch

For each skill, rewrite description from:
```
"Enforces X when Y. Ensures A, B, and C."
```
To:
```
"Use when Y or when A, B, C are mentioned."
```

Example transformations:
- `code-quality`: "Enforces code quality standards when writing or editing code..." → "Use when writing, editing, or reviewing code."
- `tdd-discipline`: "Enforces test-driven development with Red-Green-Refactor cycle..." → "Use when writing new code, implementing features, or fixing bugs."
- `pattern-enforcement`: "Enforces project patterns and architecture conventions..." → "Use when designing, implementing, or reviewing code structure."

## Options

| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| Rewrite all 8 descriptions | Consistent, comprehensive | Tiny risk of breaking working triggers | **Recommended** |
| Rewrite only the 3 worst offenders | Lower risk | Inconsistent, leaves potential issues | Not recommended |

## Routing

- [x] **Crafter** — Small appetite, well-understood changes
- [ ] **Architect** — Not needed
