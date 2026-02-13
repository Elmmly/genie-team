---
spec_version: "1.0"
type: shaped-work
id: systematic-debugging
title: "Add Systematic Debugging Skill"
status: reviewed
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

---

# Design

## Overview

Create a new `systematic-debugging` skill at `.claude/skills/systematic-debugging/SKILL.md` following the existing skill pattern (YAML frontmatter + markdown body). The skill defines a 4-phase root cause investigation protocol, a 3-strike escalation rule, and a RED FLAGS section blocking common anti-patterns. Add the skill to the Crafter's skills array in `agents/crafter.md`.

## Architecture

**Pattern: Standalone composable skill.** Follows the same structure as `tdd-discipline/SKILL.md` — frontmatter with `name`, `description`, `allowed-tools`, then markdown body with protocol phases, rules, and anti-pattern tables. The skill complements TDD discipline: TDD handles the build-test-refactor cycle; systematic-debugging handles what happens when that cycle encounters unexpected failures.

**Relationship to TDD:** Phase 4 of the debugging protocol ("Implement the Fix") hands off to TDD's RED phase — write a failing test that captures the root cause, then fix it. The two skills are sequential, not overlapping.

## Component Design

### 1. Skill file — `.claude/skills/systematic-debugging/SKILL.md`

**Frontmatter:**

```yaml
---
name: systematic-debugging
description: "Structured root cause investigation when tests fail unexpectedly or fixes don't resolve the issue. Use when a test fails that you expected to pass, when a previous fix attempt didn't work, or when an error occurs during implementation."
allowed-tools: Read, Grep, Glob, Bash(npm test*), Bash(npm run test*), Bash(pytest*), Bash(jest*), Bash(cargo test*), Bash(make test*), Bash(git diff*), Bash(git log*)
---
```

Key design choices:
- `description` uses trigger-context framing ("Use when...") per AC-5 — this is what Claude Code reads to decide when to activate the skill
- `allowed-tools` matches tdd-discipline plus `git diff`/`git log` for pattern analysis and `Grep`/`Glob` for searching related code

**Body structure:**

```markdown
# Systematic Debugging

When a test fails unexpectedly or a fix attempt doesn't work, follow this protocol.
Do NOT improvise. Do NOT try random changes.

## Attempt Counter

Track your fix attempts. Each time you modify code to fix the issue, increment the counter.

- **Attempt 1-3:** Follow the 4-phase protocol below
- **Attempt 3+ (ESCALATION):** STOP. See Escalation Protocol.

## Phase 1: Reproduce and Read

1. Run the failing test in isolation. Capture the EXACT error message.
2. Read the error message completely — every line, every stack frame.
3. Identify: What was expected? What actually happened? Where did execution diverge?
4. Do NOT attempt a fix yet.

**Output:** A 1-2 sentence root cause hypothesis based on reading the error.

## Phase 2: Pattern Analysis

1. Compare working code vs broken code. What changed?
   - `git diff` to see recent changes
   - Compare with a similar test that passes
2. Look for the SIMPLEST explanation first:
   - Typo? Wrong variable name?
   - Missing import? Wrong path?
   - Stale state? Missing setup?
3. Check if the error matches a known pattern:
   - "Cannot find module" → import path or missing dependency
   - "undefined is not a function" → wrong method name or missing mock
   - "expected X received Y" → logic error or wrong test data

**Output:** Refined hypothesis with specific location (file:line).

## Phase 3: Hypothesis Testing

1. Form ONE hypothesis about the root cause
2. Make ONE change to test that hypothesis
3. Run the test
4. If it passes: Go to Phase 4
5. If it fails: Return to Phase 1 with the NEW error message
   (Increment attempt counter)

**Rules:**
- ONE change at a time. Never change multiple things.
- If the hypothesis was wrong, REVERT the change before trying the next one.
- Each failed hypothesis is data — write down what you learned.

## Phase 4: Implement the Fix

Once root cause is confirmed:

1. REVERT the hypothesis test change (if it was a hack)
2. Write a failing test that captures the root cause (TDD RED phase)
3. Implement the proper fix (TDD GREEN phase)
4. Verify all tests pass (including the original failing test)

This phase hands off to the tdd-discipline skill.

## Escalation Protocol

**TRIGGERED AT: 3 failed fix attempts.**

STOP. Do not attempt another fix. Instead:

1. Re-read the ORIGINAL error message (not the latest one — you may have drifted)
2. Question your assumptions:
   - "Am I looking at the right file?"
   - "Am I understanding the error correctly?"
   - "Is my mental model of how this code works actually correct?"
   - "Could the problem be in test setup rather than implementation?"
   - "Could this be an environmental issue (dependency version, config)?"
3. Read the code path from entry point to failure — don't skim, READ
4. If still stuck: Ask for help (interactive) or document the block and stop (headless)

**In headless mode:** After escalation, set execution report status to `blocked`
with a clear description of what was tried and what failed.

## RED FLAGS — Stop Immediately

| Anti-Pattern | Signal | Response |
|--------------|--------|----------|
| Shotgun debugging | You're changing multiple things at once | STOP. Revert all. Pick ONE hypothesis. |
| Symptom fixing | Your fix suppresses the error without understanding why it occurs | STOP. Return to Phase 1. Find root cause. |
| "It works now" | Tests pass but you can't explain why your change fixed it | STOP. Revert and reproduce. Understand the mechanism. |
| Escalating complexity | Each fix attempt is more complex than the last | STOP. Trigger escalation — your mental model is wrong. |
| Test modification | You're tempted to change the test to match your code | STOP. The test defines expected behavior. Fix implementation. |
```

### 2. Crafter agent — `agents/crafter.md`

**Modify: skills array (L7-12)**

Add `systematic-debugging` after `tdd-discipline`:

```yaml
skills:
  - spec-awareness
  - architecture-awareness
  - code-quality
  - tdd-discipline
  - systematic-debugging
  - pattern-enforcement
```

Placement after `tdd-discipline` is intentional — it signals the conceptual relationship (TDD for building, debugging for when building hits problems).

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Create skill file with proper YAML frontmatter (name, description, allowed-tools) | `.claude/skills/systematic-debugging/SKILL.md` |
| AC-2 | Body defines 4 phases: Reproduce and Read → Pattern Analysis → Hypothesis Testing → Implement the Fix (via TDD) | `.claude/skills/systematic-debugging/SKILL.md` |
| AC-3 | Attempt Counter section + Escalation Protocol section triggered at 3 attempts with assumption-questioning checklist | `.claude/skills/systematic-debugging/SKILL.md` |
| AC-4 | RED FLAGS table with: Shotgun debugging, Symptom fixing, "It works now", Escalating complexity, Test modification | `.claude/skills/systematic-debugging/SKILL.md` |
| AC-5 | description field uses trigger-context: "Use when a test fails unexpectedly, when a previous fix attempt didn't work, or when an error occurs during implementation" | `.claude/skills/systematic-debugging/SKILL.md` |
| AC-6 | Add `systematic-debugging` to skills array after `tdd-discipline` | `agents/crafter.md` |
| AC-7 | Skill lives in `.claude/skills/systematic-debugging/` — `install_skills()` in install.sh copies this directory automatically | No install.sh changes needed |

## Implementation Guidance

**Sequence:**
1. `.claude/skills/systematic-debugging/SKILL.md` — create the skill file
2. `agents/crafter.md` — add to skills array

**Key considerations:**
- AC-7 requires no install.sh changes. The existing `install_skills()` function (L299-304) calls `copy_dir` on the entire `.claude/skills/` directory tree, so any new subdirectory is automatically included.
- The skill's `allowed-tools` includes `Bash(git diff*)` and `Bash(git log*)` for Phase 2 pattern analysis — verify these are appropriate for the target project's test runner.
- Phase 4 explicitly references the tdd-discipline skill, creating a known handoff point.
- The Escalation Protocol has different behavior for interactive vs headless mode — in headless mode it produces a `blocked` execution report instead of asking for help.

**Test strategy:**
- Verify the skill file has valid YAML frontmatter (parseable `name`, `description`, `allowed-tools`)
- Verify `agents/crafter.md` lists `systematic-debugging` in its skills array
- Run `./install.sh project /tmp/test-install` and verify `.claude/skills/systematic-debugging/SKILL.md` is present in the output
- Run `make lint && make test` to verify no regressions

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Skill is too verbose — agents ignore it | Low | Med | Keep each phase to 3-5 actionable steps. Anti-pattern table is scannable. |
| 3-strike threshold too aggressive for complex bugs | Low | Low | Start with 3; the contract says "adjust based on experience." Can be tuned later. |
| Skill conflicts with tdd-discipline on test modification | Low | Low | Both skills agree: never modify tests to make them pass. Consistent messaging. |

## Routing

Ready for Crafter. Single skill file creation + one-line agent definition change.

---

# Implementation

## Summary

Created the systematic-debugging skill and integrated it with the Crafter genie. All 7 acceptance criteria met.

## Files Changed

| Action | File | Purpose |
|--------|------|---------|
| added | `.claude/skills/systematic-debugging/SKILL.md` | New skill with 4-phase debugging protocol, escalation rule, RED FLAGS |
| modified | `agents/crafter.md` | Added `systematic-debugging` to skills array (after `tdd-discipline`) |
| added | `tests/test_systematic_debugging.sh` | 24 tests covering all 7 ACs |

## Test Results

```
Tests: 24 | Passed: 24 | Failed: 0
```

Full suite: `make lint && make test` — 245 tests pass, lint clean.

## Acceptance Criteria Evidence

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `.claude/skills/systematic-debugging/SKILL.md` exists with `name`, `description`, `allowed-tools` frontmatter |
| AC-2 | met | Phases 1-4: Reproduce and Read, Pattern Analysis, Hypothesis Testing, Implement the Fix (via TDD) |
| AC-3 | met | Attempt Counter + Escalation Protocol triggered at 3 attempts with 5-point assumption checklist |
| AC-4 | met | RED FLAGS table: Shotgun debugging, Symptom fixing, "It works now", Escalating complexity, Test modification |
| AC-5 | met | Description: "Use when a test fails that you expected to pass, when a previous fix attempt didn't work, or when an error occurs during implementation" |
| AC-6 | met | `agents/crafter.md` skills array includes `systematic-debugging` after `tdd-discipline` |
| AC-7 | met | Skill lives in `.claude/skills/systematic-debugging/` — `install_skills()` copies automatically |

## Handoff to Critic

**Ready for review:** Yes
**Test command:** `make lint && make test`

---

# Review

## Summary

Clean implementation of a standalone debugging skill that complements the existing TDD discipline. All 7 acceptance criteria are met with 24 passing tests. The skill follows established patterns (matching tdd-discipline/SKILL.md structure), integrates cleanly with the Crafter agent, and requires no install.sh changes.

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Pass | `.claude/skills/systematic-debugging/SKILL.md` exists with valid frontmatter: `name`, `description`, `allowed-tools` |
| AC-2 | Pass | 4 phases verified: Phase 1 (Reproduce and Read), Phase 2 (Pattern Analysis), Phase 3 (Hypothesis Testing with "ONE change" enforcement), Phase 4 (Implement the Fix via "failing test" TDD handoff) |
| AC-3 | Pass | Attempt Counter section + Escalation Protocol at 3 attempts. STOP directive present. 5-point assumption-questioning checklist. Headless mode produces `blocked` execution report. |
| AC-4 | Pass | RED FLAGS table with 5 anti-patterns: Shotgun debugging, Symptom fixing, "It works now", Escalating complexity, Test modification. Each has Signal + Response columns. |
| AC-5 | Pass | Description uses trigger-context: "Use when a test fails that you expected to pass, when a previous fix attempt didn't work, or when an error occurs during implementation." Does NOT summarize the 4-phase process. |
| AC-6 | Pass | `agents/crafter.md` L12: `- systematic-debugging` (placed after `tdd-discipline`, before `pattern-enforcement`) |
| AC-7 | Pass | Skill at `.claude/skills/systematic-debugging/SKILL.md` — `install_skills()` copies `.claude/skills/` tree automatically. No install.sh changes needed. |

## Code Quality

### Strengths
- Follows existing skill pattern precisely (frontmatter schema, markdown body structure)
- Phase 4 creates a clean handoff to tdd-discipline ("This phase hands off to the tdd-discipline skill")
- Escalation Protocol distinguishes interactive vs headless behavior
- RED FLAGS table is scannable with consistent Signal/Response format
- Each phase specifies an explicit "Output" requirement
- Test file follows project conventions (bash harness, assert_* helpers, AC-tagged sections)

### Issues Found

No critical or major issues.

## Test Coverage

- **Tests:** 24/24 passing
- **Coverage:** All 7 ACs have dedicated test sections
- **Negative test:** AC-5 verifies description does NOT summarize the process
- **Full suite:** 293 tests pass across 7 test files

## Security Review

- N/A — prompt engineering artifact, no application code

## Risk Assessment

| Risk | L | I | Status |
|------|---|---|--------|
| Skill too verbose for agents to follow | Low | Med | Addressed — each phase is 3-5 actionable steps, table is scannable |
| 3-strike threshold too aggressive | Low | Low | Accepted — start with 3, tune based on experience |
| Conflict with tdd-discipline | Low | Low | Addressed — both skills agree on never modifying tests |

## Verdict

**Decision: APPROVED**

All acceptance criteria met. Implementation is clean, well-tested, and follows established patterns. No issues found.

## Routing

Ready for `/commit` and `/done`.
