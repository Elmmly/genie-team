---
spec_version: "1.0"
type: shaped-work
id: systematic-debugging
title: "Add Systematic Debugging Skill"
status: shaped
created: "2026-02-13"
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [skills, debugging, discipline, crafter]
acceptance_criteria:
  - id: AC-1
    description: "A new systematic-debugging skill exists at skills/systematic-debugging/SKILL.md with proper frontmatter"
    status: pending
  - id: AC-2
    description: "The skill defines a 4-phase root cause investigation protocol: (1) reproduce and read error, (2) pattern analysis comparing working vs broken, (3) hypothesis testing with one change at a time, (4) implementation via failing test first"
    status: pending
  - id: AC-3
    description: "The skill includes a hard escalation rule: 3+ failed fix attempts triggers a STOP and requires the agent to question its architectural assumptions before continuing"
    status: pending
  - id: AC-4
    description: "The skill includes a RED FLAGS section blocking common debugging anti-patterns: 'shotgun debugging' (changing multiple things), 'fix the symptom' (without root cause), 'it works now' (without understanding why)"
    status: pending
  - id: AC-5
    description: "The skill description uses trigger-context framing ('Use when...') without summarizing the debugging process"
    status: pending
  - id: AC-6
    description: "The Crafter agent definition (agents/crafter.md) lists systematic-debugging in its skills array"
    status: pending
  - id: AC-7
    description: "The skill is installed to .claude/skills/systematic-debugging/SKILL.md via install.sh"
    status: pending
---

# Shaped Work Contract: Add Systematic Debugging Skill

## Problem

When the Crafter encounters failures during `/deliver`, there is no structured debugging protocol.
The agent improvises — sometimes productively, sometimes spiraling into repeated failed fix
attempts. Without a protocol:

- Agents try multiple fixes without isolating root cause
- Agents change multiple things simultaneously (shotgun debugging)
- Agents fix symptoms without understanding underlying causes
- Agents keep retrying the same approach beyond a reasonable threshold
- There is no escalation path when debugging isn't converging

**Evidence:** Searching for debugging protocols across all agents, commands, rules, and skills
returns zero matches for attempt counting, escalation thresholds, or root cause protocols. TDD
discipline assumes implementation will eventually succeed — no protocol for when it doesn't.
`/deliver` says "fix before proceeding" — that's the entire guidance. Agents spiral into
increasingly complex fixes without stepping back.

**Who's affected:** The Crafter genie during `/deliver`, especially during autonomous headless
execution where no human is present to say "stop — try a different approach."

## Appetite & Boundaries

- **Appetite:** Small (1 day) — single new skill file, one agent definition update
- **No-gos:**
  - Do NOT modify the existing TDD discipline (debugging is a separate concern from test-first)
  - Do NOT modify `/diagnose` command (that's codebase health scanning, not in-flight debugging)
  - Do NOT add debugging logic to the Crafter agent definition itself (keep it modular as a skill)
- **Fixed elements:**
  - Must integrate with TDD discipline — Phase 4 (implementation) uses failing-test-first
  - Must include the 3-strike escalation rule
  - Must include rationalization blocking

## Goals & Outcomes

Agents encountering failures during implementation follow a structured root cause investigation
instead of improvising. Failed fix spirals are caught at 3 attempts with a mandatory stop-and-reflect.
The Crafter produces better-understood fixes with clear root cause documentation.

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|---|---|---|
| Agents actually spiral into failed fixes | feasibility | Review past `/deliver` sessions for repeated fix attempts |
| A structured protocol improves debugging outcomes | feasibility | Compare structured vs unstructured debugging in a sample /deliver session |
| 3 attempts is the right escalation threshold | usability | Start with 3, adjust based on experience |
| Debugging skill and TDD skill complement each other | usability | Verify Phase 4 of debugging naturally flows into TDD's RED phase |

## Solution Sketch

New skill file with:
- Trigger: Activates when a test fails unexpectedly, an implementation error occurs, or a previous fix attempt didn't resolve the issue
- 4 phases: Reproduce → Analyze patterns → Hypothesis test → Implement (via TDD)
- Escalation: 3 failed attempts → mandatory STOP → re-read the error, question assumptions, consider asking for help
- RED flags: Shotgun debugging, symptom-fixing, "it works now" without understanding why

## Options

| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| Standalone skill on Crafter | Clean separation, modular, composable with TDD | Crafter must know to use both skills | **Recommended** |
| Embed in Crafter agent definition | Always present | Can't reuse for other genies, clutters agent definition | Not recommended |
| Add as section in tdd-discipline | Single skill | Overloads TDD with debugging concern | Not recommended |

## Routing

- [x] **Crafter** — Small appetite, single skill creation, no design needed
- [ ] **Architect** — Not needed
