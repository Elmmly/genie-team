---
spec_version: "1.0"
type: shaped-work
id: rationalization-blocking
title: "Add Rationalization Blocking to Enforcement Skills"
status: shaped
created: "2026-02-13"
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [skills, enforcement, discipline, quality]
acceptance_criteria:
  - id: AC-1
    description: "tdd-discipline skill includes an excuse/reality table with at least 4 entries countering predictable rationalizations (e.g., 'tests after achieve same goal', 'too simple to test')"
    status: pending
  - id: AC-2
    description: "code-quality skill includes a RED FLAGS section listing specific thoughts that should trigger an agent to stop and re-read the skill"
    status: pending
  - id: AC-3
    description: "problem-first skill includes rationalization blocking that counters common excuses for skipping problem framing (e.g., 'the user already told me the solution', 'this is too simple to reframe')"
    status: pending
  - id: AC-4
    description: "pattern-enforcement skill includes an excuse/reality table countering deviations (e.g., 'this pattern doesn't apply here', 'it's simpler without the pattern')"
    status: pending
  - id: AC-5
    description: "All rationalization-blocking content uses obligation language ('you MUST', 'STOP'), not suggestion language ('consider', 'should')"
    status: pending
  - id: AC-6
    description: "Source skills in skills/ directory are updated and synced to .claude/skills/ via install.sh"
    status: pending
---

# Shaped Work Contract: Add Rationalization Blocking to Enforcement Skills

## Problem

Genie-team's 8 skills vary widely in enforcement strength. Only `tdd-discipline` has an
"Anti-Patterns to Catch" table with STOP directives that counter specific rationalizations.
The remaining enforcement skills — `code-quality`, `problem-first`, `pattern-enforcement` — state
rules but don't anticipate the specific excuses agents generate under context pressure.

**Evidence:** Side-by-side comparison of all enforcement skills confirms the gap (see
`docs/analysis/20260213_discover_skill_enforcement_gaps.md`, Section 8A). Agents under context
pressure generate predictable rationalizations ("tests after achieve same goal", "too simple to
test", "this is different because..."). Excuse/reality tables and RED flag patterns using obligation
language (MUST, STOP, NEVER) counter these rationalizations. `tdd-discipline` is the only skill
that partially implements this pattern.

**Who's affected:** All genies operating under enforcement skills, especially during autonomous
headless execution (ADR-001) where no human is present to catch corner-cutting.

## Appetite & Boundaries

- **Appetite:** Small (1-2 days) — these are markdown prompt edits, not code changes
- **No-gos:**
  - Do NOT change `brand-awareness` or `spec-awareness` (these are knowledge skills, not enforcement skills)
  - Do NOT change `conventional-commits` (procedural, not enforcement)
  - Do NOT change `architecture-awareness` (already has hard rules section)
  - Do NOT restructure skill file format or frontmatter
- **Fixed elements:**
  - Existing skill behavior must be preserved — additions only
  - The excuse/reality table pattern from `tdd-discipline` is the model
  - Obligation language (MUST, STOP, NEVER) — not suggestion language

## Goals & Outcomes

Agents encountering context pressure during implementation, quality checks, or problem framing
will hit explicit cognitive guardrails that counter predictable rationalizations — reducing
silent discipline violations without human oversight.

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|---|---|---|
| Agents actually generate predictable rationalizations | feasibility | Review past session logs for pattern violations |
| Excuse/reality tables change agent behavior | feasibility | A/B test a skill with and without blocking |
| Obligation language is more effective than suggestion language | feasibility | Compare `tdd-discipline` (strong enforcement) effectiveness vs `code-quality` (moderate guidance) |
| Adding content won't push skills past character budget | feasibility | Measure skill char footprint before and after |

## Solution Sketch

For each of the 4 target skills, add two sections:

1. **Excuse/Reality Table** — 4-6 entries mapping predictable excuses to reality checks
2. **RED FLAGS** — Bullet list of thoughts that should trigger "stop and re-read"

Pattern to follow (modeled on `tdd-discipline` anti-pattern table):
```markdown
## Rationalization Blocking

| Excuse | Reality |
|---|---|
| "Tests after achieve same goal" | No — tests-first defines "should be"; tests-after validates "what is" |
| "Too simple to test" | Simple code breaks. A 30-second test proves it works. Write the test. |

### RED FLAGS — If you're thinking any of these, STOP:
- "I'll just write the code first, then add tests"
- "This is different because..."
- "It's too simple/obvious to need X"
```

## Options

| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| Add tables to all 4 enforcement skills | Consistent coverage, closes all gaps | More content to maintain | **Recommended** |
| Add only to `code-quality` and `problem-first` (weakest) | Faster, targeted | Leaves `pattern-enforcement` exposed | Not recommended |
| Create a shared "rationalization-blocking" include skill | DRY, single source | Claude may not follow cross-references between skills | Not recommended |

## Routing

- [x] **Crafter** — Small appetite, well-understood changes, no design needed
- [ ] **Architect** — Not needed (no architectural choice)
