---
spec_version: "1.0"
type: shaped-work
id: "{ID}"
title: "{Title}"
status: shaped
created: "{YYYY-MM-DD}"
appetite: "{small|medium|big}"
priority: "{P0|P1|P2|P3}"
target_project: "{project-name}"
author: shaper
depends_on: []
tags: []
spec_ref: "docs/specs/{domain}/{capability}.md"
acceptance_criteria:
  - id: AC-1
    description: "{First acceptance criterion}"
    status: pending
  - id: AC-2
    description: "{Second acceptance criterion}"
    status: pending
---

# Shaped Work Contract: {Title}

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> All structured data lives in the YAML frontmatter above. The body below
> is free-form narrative for human context. Machines parse frontmatter only.
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

[Clear, solution-free articulation of the underlying problem or opportunity]

**Original input:** [What was provided]
**Reframed problem:** [Solution-free problem statement]

## Evidence & Insights

- **From Discovery:** [Reference Scout Opportunity Snapshot if available]
- **Behavioral Signals:** [User behavior or telemetry]
- **JTBD:** "When [situation], [user] wants to [motivation] so they can [outcome]"

## Appetite & Boundaries

- **Appetite:** [Small: 1-2d / Medium: 3-5d / Big: 1-2w]
- **Boundaries:** [What's in scope]
- **No-gos:** [Explicitly excluded]
- **Fixed elements:** [Cannot change]

## Goals

**Outcome Hypothesis:** "We believe [doing X] will result in [outcome Y] for [user Z]."

**Success Signals:**
- [Metric or behavioral signal 1]
- [Metric or behavioral signal 2]

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| [Riskiest assumption] | value/usability/feasibility | [How to test cheaply] |

## Options (Ranked)

### Option 1: [Name] (Recommended)
- **Description:** [What this entails]
- **Pros:** [Benefits]
- **Cons:** [Drawbacks]
- **Appetite fit:** [Good / Tight / Exceeds]

### Option 2: [Name]
- **Description:** [What this entails]
- **Pros:** [Benefits]
- **Cons:** [Drawbacks]

## Dependencies

- [Dependency with severity: minor / moderate / blocking]

## Routing

- [ ] **Architect** -- Needs technical design
- [ ] **Crafter** -- Ready for implementation (small, clear scope)
- [ ] **Scout** -- Needs more discovery

**Rationale:** [Why this routing]

## Artifacts

- **Contract saved to:** `docs/backlog/{priority}-{topic}.md`
- **Discovery referenced:** `docs/analysis/YYYYMMDD_discover_{topic}.md`
