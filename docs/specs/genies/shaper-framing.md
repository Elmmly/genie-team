---
spec_version: "1.0"
type: spec
id: shaper-framing
title: Shaper Problem Framing
status: active
created: 2026-02-25
domain: genies
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      Shaper genie definition exists at agents/shaper.md with sonnet model, read-only tools
      (Read, Grep, Glob), plan permission mode, and spec-awareness + problem-first skills
    status: met
  - id: AC-2
    description: >-
      /define command activates Shaper to produce a Shaped Work Contract at
      docs/backlog/P{N}-{topic}.md with YAML frontmatter per schemas/shaped-work-contract.schema.md
    status: met
  - id: AC-3
    description: >-
      Shaped contracts include appetite (small/medium/big), acceptance criteria with
      id/description/status, boundaries (no-gos, fixed elements), risk assumptions with
      fastest tests, and routing recommendations
    status: met
  - id: AC-4
    description: >-
      Shaper detects anti-patterns (solution-masquerading problems, tech tasks posing as
      product work, vague requests, scope creep) and reframes appropriately before shaping
    status: met
---

# Shaper Problem Framing

The Shaper genie frames problems into actionable work using Ryan Singer's Shape Up methodology (appetite boundaries, fixed time / variable scope), Teresa Torres (discovery integration), Marty Cagan (product sense), and Melissa Perri (outcome-over-output). It shapes problems — it does NOT design or implement solutions. The Shaper defines the shape of the hole, not what fills it.

The Shaper also supports an interactive `--workshop` mode with 4 phases: Problem Framing (choose from 2-3 solution-free reframings), Appetite Explorer (visual HTML comparison of Small/Medium/Big scope tiers), Option Exploration (side-by-side solution directions with tradeoff ratings), and Scope Negotiation (in/out boundaries, no-gos, rabbit holes).

## Acceptance Criteria

### AC-1: Genie definition with correct configuration
Shaper genie definition at `agents/shaper.md` specifies sonnet model for judgment quality, read-only tools (Read, Grep, Glob) to prevent code changes, plan permission mode, and spec-awareness + problem-first skills. The Shaper proactively activates when users describe feature requests, solution-loaded problems, or say "we should add" or "let's build."

### AC-2: Shaped Work Contract output
The `/define` command activates Shaper to produce a Shaped Work Contract written to `docs/backlog/P{N}-{topic}.md`. The contract has YAML frontmatter conforming to `schemas/shaped-work-contract.schema.md` with required fields: spec_version, type ("shaped-work"), id, title, status ("shaped"), created, appetite, acceptance_criteria. Optional fields include spec_ref, adr_refs, brand_ref, priority, tags.

### AC-3: Complete contract structure
Shaped contracts include: appetite as a constraint (Small 1-2d / Medium 3-5d / Big 1-2w), acceptance criteria as a YAML array with id/description/status fields, boundary definitions (no-gos and fixed elements), risk assumptions with type categorization and fastest test identification, ranked options with recommendations, and routing recommendations to the next phase.

### AC-4: Anti-pattern detection and reframing
The Shaper automatically detects and corrects common anti-patterns: solution-masquerading problems (rewritten as problems), tech tasks posing as product work (routed to appropriate genie), vague requests (clarifying questions asked), and scope creep (appetite boundaries enforced). Contract size is monitored — contracts exceeding ~8 ACs or ~200 lines signal the problem may not be well-shaped yet.

## Evidence

### Source Code
- `agents/shaper.md`: Genie definition with charter, judgment rules, anti-pattern detection, template
- `genies/shaper/SHAPER_SPEC.md`: Detailed specification
- `genies/shaper/SHAPER_SYSTEM_PROMPT.md`: System prompt
- `genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md`: Structured output template
- `commands/define.md`: Slash command definition
- `schemas/shaped-work-contract.schema.md`: YAML frontmatter contract schema

### Tests
- `tests/test_execute.sh`: 62 tests covering command execution and genie invocation patterns
