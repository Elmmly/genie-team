---
spec_version: "1.0"
type: spec
id: scout-discovery
title: Scout Discovery
status: active
created: 2026-02-25
domain: genies
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      Scout genie definition exists at agents/scout.md with haiku model, read-only tools
      (Read, Grep, Glob, WebFetch, WebSearch), plan permission mode, and spec-awareness +
      problem-first skills
    status: met
  - id: AC-2
    description: >-
      /discover command activates Scout to explore a topic and produce an Opportunity Snapshot
      at docs/analysis/YYYYMMDD_discover_{topic}.md with YAML frontmatter (type: discover)
    status: met
  - id: AC-3
    description: >-
      Scout reframes solution-loaded questions as problems using JTBD framing ("When [situation],
      [user] wants to [motivation] so they can [outcome]") and surfaces assumptions categorized
      by type (value/usability/feasibility/viability) with evidence levels (strong/moderate/weak/missing)
    status: met
  - id: AC-4
    description: >-
      Scout outputs routing recommendations (Continue Discovery / Ready for Shaper / Needs
      Architect Spike / Needs Navigator Decision) and hands off Opportunity Snapshot to Shaper
    status: met
---

# Scout Discovery

The Scout genie is the discovery specialist combining Teresa Torres' Continuous Discovery Habits, Clayton Christensen & Tony Ulwick's Jobs-to-be-Done framework, evidence-based product thinking, and opportunity mapping. It explores problem spaces without jumping to solutions, surfaces stated and unstated assumptions with evidence levels, maps pain points and friction areas, and produces structured Opportunity Snapshots.

Scout runs on the haiku model for cost efficiency (10-20x cheaper than sonnet) since its work is research-heavy and benefits from fast iteration over deep judgment. It has read-only tools plus web access for external research.

## Acceptance Criteria

### AC-1: Genie definition with correct configuration
Scout genie definition at `agents/scout.md` specifies haiku model for cost-efficient research, read-only tools (Read, Grep, Glob, WebFetch, WebSearch) to prevent accidental code changes, plan permission mode, and the spec-awareness and problem-first skills for cross-cutting behaviors.

### AC-2: Opportunity Snapshot output
The `/discover` command activates Scout to explore a user-provided topic. Output is a structured Opportunity Snapshot written to `docs/analysis/YYYYMMDD_discover_{topic}.md` with YAML frontmatter including `type: discover`, topic, status, and creation date. The snapshot follows a 9-section template: Discovery Question, Observed Behaviors, Pain Points, JTBD, Assumptions & Evidence, Technical Signals, Opportunity Areas, Evidence Gaps, and Routing Recommendation.

### AC-3: Problem-first framing with JTBD and assumption surfacing
Scout reframes solution-loaded questions into problem-focused versions (e.g., "We should add caching" becomes "What performance problems are users experiencing?"). It applies JTBD framing and categorizes assumptions by type (value, usability, feasibility, viability) with evidence grounding levels (strong, moderate, weak, missing).

### AC-4: Routing recommendations and handoff
Each Opportunity Snapshot ends with a routing recommendation: Continue Discovery (more exploration needed), Ready for Shaper (problem understood), Needs Architect Spike (technical feasibility unclear), or Needs Navigator Decision (strategic question). The handoff to Shaper includes the evidence summary.

## Evidence

### Source Code
- `agents/scout.md`: Genie definition with model, tools, permissions, skills, charter, judgment rules, templates
- `genies/scout/SCOUT_SPEC.md`: Detailed specification
- `genies/scout/SCOUT_SYSTEM_PROMPT.md`: System prompt with judgment rules
- `genies/scout/OPPORTUNITY_SNAPSHOT_TEMPLATE.md`: Structured output template
- `commands/discover.md`: Slash command definition

### Tests
- `tests/test_execute.sh`: 62 tests covering command execution and genie invocation patterns
