---
spec_version: "1.0"
type: shaped-work
id: verification-gate
title: "Add Verification Gate Skill"
status: shaped
created: "2026-02-13"
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [skills, verification, quality, completeness]
acceptance_criteria:
  - id: AC-1
    description: "A new verification-gate skill exists at skills/verification-gate/SKILL.md with proper frontmatter (name, description, allowed-tools)"
    status: pending
  - id: AC-2
    description: >-
      The skill enforces that NO completion claim (task done, phase complete, ready for review)
      is valid without a fresh test run executed in the current session after the last code
      change
    status: pending
  - id: AC-3
    description: "The skill includes a RED FLAGS section blocking rationalizations like 'tests passed earlier', 'I only changed comments', 'the change is trivial'"
    status: pending
  - id: AC-4
    description: "The skill description uses trigger-context framing ('Use when...') without summarizing the verification process"
    status: pending
  - id: AC-5
    description: "The Crafter agent definition (agents/crafter.md) lists verification-gate in its skills array"
    status: pending
  - id: AC-6
    description: "The skill is installed to .claude/skills/verification-gate/SKILL.md via install.sh"
    status: pending
---

# Shaped Work Contract: Add Verification Gate Skill

## Problem

Genie-team enforces test-first development via `tdd-discipline` but has no gate preventing
completion claims without fresh verification. The gap sits between `/deliver` (Crafter completes
work) and `/discern` (Critic reviews). An agent could:

1. Write tests and implementation (TDD discipline satisfied)
2. Pass all tests
3. Make further changes (refactoring, cleanup, edge case fixes)
4. Claim "done" and hand off to Critic — without re-running tests after step 3

The Critic reviews code quality and spec compliance but may not catch stale test results.
In headless autonomous execution (ADR-001), there's no human to ask "did you re-run the tests?"

**Evidence:** Tracing the completion path through Crafter → execution report → Critic confirms the
gap: TDD discipline enforces RED→GREEN but NOT "re-verify GREEN after REFACTOR." The execution
report schema requires `test_results` but has no freshness mechanism. The Critic can run tests but
its agent definition says to "parse" existing results. Agents treat early test passes as permanent
proof of correctness.

## Appetite & Boundaries

- **Appetite:** Small (1 day) — single new skill file, one agent definition update
- **No-gos:**
  - Do NOT modify existing TDD discipline skill (orthogonal concern)
  - Do NOT add verification logic to the `/discern` command (Critic's job is review, not verification)
  - Do NOT require specific test frameworks — skill must be framework-agnostic
- **Fixed elements:**
  - Must work for both interactive and headless execution modes
  - Must trigger automatically (not require explicit invocation)
  - Must include rationalization blocking (RED flags + excuse/reality table)

## Goals & Outcomes

Every completion claim in genie-team is backed by a fresh, passing test run executed after the
last code change. Stale results never reach the Critic. Agents can't claim "done" without proving it.

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|---|---|---|
| Agents actually skip re-running tests before claiming done | feasibility | Review past session transcripts |
| A skill can enforce "fresh" verification (after last change) | feasibility | Test with Crafter on a sample delivery |
| This doesn't create annoying redundancy with TDD discipline | usability | Verify the skills are orthogonal — TDD = write tests first; verification = run tests last |
| Adding one more skill stays within character budget | feasibility | Measure skill footprint |

## Solution Sketch

New skill file with:
- Trigger: Activates when any genie is about to claim task completion, phase completion, or readiness for review
- Gate: Require fresh test execution (actual `npm test`, `pytest`, etc.) after the last file modification
- Blocking: Excuse/reality table + RED flags for common rationalizations
- Output: Include test results in the completion claim

## Options

| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| Standalone skill on Crafter | Clean separation, modular | Only covers Crafter | **Recommended** — Crafter is the only genie that writes code |
| Add verification section to tdd-discipline | No new file | Overloads tdd-discipline with two concerns (write-first + run-last) | Not recommended |
| Add to `/discern` command | Critic verifies | Changes Critic from reviewer to verifier — role confusion | Not recommended |

## Routing

- [x] **Crafter** — Small appetite, single skill creation, no design needed
- [ ] **Architect** — Not needed
