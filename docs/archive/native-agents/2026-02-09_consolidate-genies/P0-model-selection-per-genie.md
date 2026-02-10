---
spec_version: "1.0"
type: shaped-work
id: model-selection
title: "Add Model Selection Guidance Per Genie"
status: done
completed: 2026-02-09
completed_by: "consolidate-genies-to-native-agents (1d558da)"
created: 2026-02-06
appetite: small
priority: P0
target_project: genie-team
author: shaper
depends_on: []
tags: [cost, optimization, models, commands]
acceptance_criteria:
  - id: AC-1
    description: "Each command file includes a Model Selection section specifying the recommended model tier (haiku/sonnet/opus) with rationale"
    status: met
  - id: AC-2
    description: "Scout and Tidier commands recommend haiku for cost efficiency on breadth-over-depth tasks"
    status: met
  - id: AC-3
    description: "Architect, Crafter, Critic, and Shaper commands recommend sonnet as the default for judgment-intensive tasks"
    status: met
  - id: AC-4
    description: "No command defaults to opus — opus is reserved for user override when maximum capability is needed"
    status: met
---

# Shaped Work Contract: Add Model Selection Guidance Per Genie

**Date:** 2026-02-06
**Input:** Cost analysis showing full workflows consume 300-400K tokens at opus pricing when most genie tasks perform equally well on cheaper models.

---

## Problem / Opportunity Statement

Every genie invocation currently runs on whatever model the user's session uses — typically opus. But most genie tasks don't need opus-level reasoning:
- Scout discovery is breadth-over-depth scanning — haiku handles this
- Tidier cleanup analysis is mechanical pattern matching — haiku handles this
- Crafter TDD is methodical step-following — sonnet handles this
- Critic review is checklist-driven — sonnet handles this

Only ambiguous judgment calls (complex shaping, novel architecture) benefit from opus. Running everything on opus is 10-20x more expensive than necessary.

## Appetite & Boundaries

- **Appetite:** Small batch (half day)
- **In scope:** Add model recommendation to each command file; guidance is advisory, not enforced
- **Out of scope:** Enforced model selection (that requires `.claude/agents/` migration — separate item)

## Solution Sketch

Add a `## Model Selection` section to each command file:

```markdown
## Model Selection

**Recommended:** sonnet
**Rationale:** Pattern enforcement and structured output don't require opus-level reasoning.
**Override:** Use opus for novel architectural decisions or when sonnet produces insufficient quality.
```

| Genie | Recommended | Rationale |
|-------|-------------|-----------|
| Scout (/discover) | haiku | Breadth scanning, link following, summarization |
| Shaper (/define) | sonnet | Judgment needed for problem reframing and appetite |
| Architect (/design) | sonnet | Pattern enforcement, structured design output |
| Crafter (/deliver) | sonnet | TDD is methodical; code quality needs attention |
| Critic (/discern) | sonnet | Checklist-driven review against ACs |
| Designer (/brand) | sonnet | Workshop facilitation, visual judgment |
| Tidier (/tidy) | haiku | Mechanical cleanup scanning |
| Diagnostician (/diagnose) | haiku | Codebase health scanning |

## Routing

- [x] **Crafter** — Straightforward text additions to command files

---

# End of Shaped Work Contract
