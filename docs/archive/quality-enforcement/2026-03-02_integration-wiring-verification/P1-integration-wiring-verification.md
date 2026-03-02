---
spec_version: "1.0"
type: shaped-work
id: P1-integration-wiring-verification
title: "Integration Wiring Verification"
status: done
verdict: APPROVED
created: 2026-03-02
appetite: small
priority: P1
author: shaper
spec_ref: docs/specs/quality/development-standards.md
acceptance_criteria:
  - id: AC-1
    description: >-
      /deliver command includes a Phase 4: Wiring Check after TDD phases that verifies
      interface implementations exist (not just mocks), components are instantiated in
      service bootstrap, consumers/workers are registered, and no dead code exists without
      a path from an entrypoint. Missing wiring is either implemented or flagged as
      "partially met (logic only)" in the Implementation section.
    status: pending
  - id: AC-2
    description: >-
      /discern review checklist includes a wiring verification item that checks for real
      (non-mock) interface implementations, service bootstrap instantiation, event
      handler/consumer registration, and traceable call paths from entrypoints to business
      logic. Mock-only passing tests are explicitly insufficient evidence for integration ACs.
    status: pending
  - id: AC-3
    description: >-
      /discern calibration section includes an exception: never APPROVE when integration
      wiring is missing for ACs that describe end-to-end behavior (triggers, syncs, pushes,
      sends). Missing wiring warrants CHANGES REQUESTED regardless of unit test coverage.
    status: pending
  - id: AC-4
    description: >-
      tdd-discipline rule includes a Mock Boundary Awareness section that distinguishes
      "logic works" (unit tests with mocks) from "feature works" (real implementation +
      service wiring), stating both are required for ACs that describe system behavior.
    status: pending
---

# Shaped Work Contract: Integration Wiring Verification

## Problem

Genies deliver code that passes all unit tests against mocks but isn't wired into the running system. ACs describing system behavior ("auto-trigger," "writes to repo," "pushes to") pass `/discern` review because mock-passing tests satisfy the checklist — even when there's no code path from any entrypoint to the implemented logic.

The root cause: neither `/deliver` nor `/discern` has the concept of "wiring" as a distinct deliverable. TDD phases prove logic correctness against interfaces, but no phase verifies that interfaces have real implementations or that components are reachable from service bootstrap.

This is a P1 because it's a systematic blind spot — every integration-heavy delivery has this gap. The fix is four targeted prompt changes, not new infrastructure.

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days)
- **No-gos:**
  - No new commands, skills, or genies
  - No changes to the autonomous runner (`scripts/genies`)
  - No test infrastructure changes
  - No changes to the Architect or Scout flows
- **Fixed elements:**
  - Existing TDD phases 1-3 in `/deliver` stay exactly as-is
  - Existing review checklist items 1-9 in `/discern` stay as-is
  - Calibration guidance for style/pedantic issues stays as-is

## Goals & Outcomes

After this change, genies working autonomously via `/run`:
1. **Crafter** checks wiring after TDD phases and either wires the code or explicitly flags what's missing
2. **Critic** catches mock-only implementations during review and rejects them for integration ACs
3. **Both genies** understand the distinction between "logic works" and "feature works"

The result: no more features that pass review but don't actually run.

## Behavioral Delta

**Spec:** docs/specs/quality/development-standards.md

### Current Behavior
- AC-1 (TDD discipline): Covers red-green-refactor cycle and test patterns — no mention of integration wiring
- No AC exists for wiring verification or mock boundary awareness

### Proposed Changes
- AC-1: No change (TDD phases stay as-is; wiring check is additive)
- AC-NEW (AC-5): `/deliver` includes Phase 4 wiring check after TDD
- AC-NEW (AC-6): `/discern` includes wiring verification in review checklist with calibration exception
- AC-NEW (AC-7): `tdd-discipline` rule distinguishes mock-passing from system-wired

### Rationale
Field observations from autonomous `/run` sessions show features passing all tests and review, then not being callable from the running application. The gap is in the instructions, not the tooling.

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Genies will follow the wiring check instructions | feasibility | Deliver a feature with integration ACs after this change and verify wiring |
| The check won't cause false positives on pure-logic items | value | Items without integration ACs should pass Phase 4 trivially |
| Calibration exception won't make Critic too aggressive | value | Review a mock-only delivery and verify it gets CHANGES REQUESTED, not BLOCKED |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| Prompt-only changes (4 files) | Minimal, no code, immediately effective | Relies on genie compliance | **Recommended** |
| Add automated wiring detection script | Machine-verifiable | Over-engineered for prompt project; language-specific | Not recommended |

## Scope of Changes

Four files, additive changes only:

1. **`commands/deliver.md`** — Add Phase 4: Wiring Check section after Phase 3: Refactor
2. **`commands/discern.md`** — Add checklist item 10 (wiring verification) + calibration exception
3. **`rules/tdd-discipline.md`** — Add "Mock Boundary Awareness" section
4. **`docs/specs/quality/development-standards.md`** — Add AC-5, AC-6, AC-7 to spec

## Routing

Ready for direct delivery — small batch, clear scope, no design needed.

**Next:** `/deliver docs/backlog/P1-integration-wiring-verification.md`

# Implementation

Delivered on 2026-03-02. Four additive prompt changes, no code.

## Changes

### 1. `commands/deliver.md` — Phase 4: Wiring Check (AC-1)
Added a mandatory Phase 4 after TDD Phase 3: Refactor. The phase verifies:
- Interface implementations exist (not just mocks)
- Components are instantiated in service bootstrap
- Consumers/workers are registered
- No dead code without a path from an entrypoint

Missing wiring must be implemented or flagged as "partially met (logic only)." For pure library/prompt work, the phase notes "N/A — no service wiring required."

### 2. `commands/discern.md` — Checklist Item 10: Wiring Verification (AC-2)
Added review checklist item 10 with specific checks: real interface implementations, service bootstrap instantiation, event handler registration, traceable call paths from entrypoints. Mock-only tests are explicitly insufficient for integration ACs.

### 3. `commands/discern.md` — Calibration Exception (AC-3)
Added exception to the calibration section: never APPROVE when integration wiring is missing for ACs describing end-to-end behavior (triggers, syncs, pushes, sends). Missing wiring warrants CHANGES REQUESTED regardless of unit test coverage.

### 4. `rules/tdd-discipline.md` — Mock Boundary Awareness (AC-4)
Added section distinguishing "logic works" (unit tests with mocks) from "feature works" (real implementation + service wiring). Both are required for ACs that describe system behavior.

### 5. `docs/specs/quality/development-standards.md` — Spec Update
Added AC-5, AC-6, AC-7 to frontmatter and body. Added Implementation Evidence section.

## Phase 4: Wiring Check
N/A — no service wiring required. These are prompt-only changes to markdown instruction files.

# Review

Reviewed on 2026-03-02.

## Verdict: APPROVED

**Acceptance criteria: 4/4 met**
**Spec ACs: 7/7 met (4 previously met + 3 new)**

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `commands/deliver.md:176-189` — Phase 4 present with all 4 checks (interfaces, bootstrap, consumers, dead code) + "partially met (logic only)" flag + trivial-case escape |
| AC-2 | met | `commands/discern.md:122-127` — Checklist item 10 with 4 sub-checks; "Mock-passing tests are NOT sufficient" explicit |
| AC-3 | met | `commands/discern.md:216` — Calibration exception: "Never APPROVE when integration wiring is missing" for end-to-end ACs; warrants CHANGES REQUESTED |
| AC-4 | met | `rules/tdd-discipline.md:36-44` — "logic works" / "feature works" distinction; "both are required"; "library with no caller" |

## Boundary Compliance

All no-gos respected:
- No new commands, skills, or genies
- No changes to `scripts/genies`
- No test infrastructure changes
- Existing TDD phases 1-3 unchanged
- Existing checklist items 1-9 unchanged
- Existing calibration guidance preserved (exception is additive)

## Observations (informational)

The trivial-case escape hatch ("Phase 4: N/A — no service wiring required") is well-placed. Without it, pure prompt/library deliveries would need to awkwardly justify why they have no bootstrap code. This delivery itself demonstrates the pattern correctly.

**Next:** `/done docs/backlog/P1-integration-wiring-verification.md`
