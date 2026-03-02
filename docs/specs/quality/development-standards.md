---
spec_version: "1.0"
type: spec
id: development-standards
title: Development Standards Enforcement
status: active
created: 2026-02-25
domain: quality
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      tdd-discipline skill enforces red-green-refactor cycle (write failing tests first,
      minimal implementation to pass, refactor while green) with AAA test pattern
      (Arrange-Act-Assert with blank line separators), one assertion focus per test,
      no conditional logic in tests, and never modifying tests to make them pass
    status: met
  - id: AC-2
    description: >-
      code-quality skill ensures no hardcoded values (use config/registry), type hints on
      public methods, docstrings for public functions, error handling at boundaries with
      context logging, structured JSON-serializable logging, and security considerations
      (no injection, no sensitive data exposure, input validation at boundaries)
    status: met
  - id: AC-3
    description: >-
      conventional-commits skill produces commit messages in format type(scope): description
      (<50 chars, imperative mood) with optional body, Refs to backlog items, and
      Co-Authored-By attribution; types include feat, fix, docs, refactor, test, chore,
      perf, style, build, ci with breaking change support via ! suffix
    status: met
  - id: AC-4
    description: >-
      debugging skill provides structured 4-phase protocol (Phase 1: Reproduce and Read,
      Phase 2: Pattern Analysis, Phase 3: Hypothesis Testing with one change at a time,
      Phase 4: Implement Fix via TDD) with attempt counter and mandatory escalation
      after 3 failed attempts; red flags trigger immediate stop (shotgun debugging,
      symptom fixing, unexplained passes, escalating complexity, test modification)
    status: met
  - id: AC-5
    description: >-
      /deliver command includes Phase 4: Wiring Check after TDD phases that verifies
      interface implementations exist (not just mocks), components are instantiated in
      service bootstrap, consumers/workers are registered, and no dead code exists without
      a path from an entrypoint. Missing wiring is either implemented or flagged as
      "partially met (logic only)" in the Implementation section.
    status: met
  - id: AC-6
    description: >-
      /discern review checklist includes wiring verification (item 10) that checks for
      real (non-mock) interface implementations, service bootstrap instantiation, event
      handler/consumer registration, and traceable call paths. Mock-only passing tests
      are explicitly insufficient for integration ACs. Calibration exception: never APPROVE
      when integration wiring is missing for end-to-end behavior ACs.
    status: met
  - id: AC-7
    description: >-
      tdd-discipline rule includes Mock Boundary Awareness section distinguishing
      "logic works" (unit tests with mocks) from "feature works" (real implementation +
      service wiring), stating both are required for ACs describing system behavior.
    status: met
---

# Development Standards Enforcement

Six skills enforce development standards automatically during workflows. These skills activate based on context (writing code, committing, defining work, debugging) without explicit invocation. They provide guardrails that ensure consistent quality across all genie work, whether interactive or autonomous.

Skills are complementary to rules: rules (`rules/*.md`) are always loaded; skills activate conditionally based on triggers. Together they ensure that code quality, testing discipline, commit hygiene, and problem framing are maintained regardless of which genie is active.

## Acceptance Criteria

### AC-1: TDD discipline
The `tdd-discipline` skill enforces the red-green-refactor cycle on all code changes. RED: write a failing test defining expected behavior. GREEN: write minimal implementation to pass. REFACTOR: improve code quality while keeping tests green. Tests must follow AAA pattern (Arrange-Act-Assert) with blank line separators between sections. Constraints: one assertion focus per test, no conditional logic (if/else) in tests, never modify tests to make them pass — fix the implementation instead. The skill activates during `/deliver`, feature implementation, bug fixes, and any test-related discussion.

### AC-2: Code quality standards
The `code-quality` skill ensures: no hardcoded values (use config/registry), type hints on public methods, docstrings for public functions, consistent naming conventions, error handling at boundaries (log errors with context, propagate meaningful exceptions, don't swallow errors silently, fail fast on invalid state). Instrumentation: structured logging at boundaries, metrics for key operations, JSON-serializable log payloads. Security: no sensitive data exposure, input validation at boundaries, no injection vulnerabilities, secure defaults. The `pattern-enforcement` skill additionally checks structural (registry, factory, strategy), data (repository, DTO, entity), and integration (adapter, gateway) patterns.

### AC-3: Conventional commit messages
The `conventional-commits` skill produces commit messages following commitlint standards: `type(scope): concise description` (under 50 chars, imperative mood) with optional body explaining what and why. Supported types: feat, fix, docs, refactor, test, chore, perf, style, build, ci. Breaking changes append `!` after type/scope with BREAKING CHANGE footer. References to backlog items via `Refs:` line. Genie attribution via `Co-Authored-By:` line. Safety rules: never commit without explicit user request, check git status first, don't use --force or --no-verify.

### AC-4: Systematic debugging protocol
The `debugging` skill provides a structured 4-phase investigation protocol when tests fail unexpectedly. Phase 1: Reproduce and Read (run failing test, read every line of error, identify expected vs actual). Phase 2: Pattern Analysis (git diff, compare with passing tests, look for simplest explanation). Phase 3: Hypothesis Testing (ONE hypothesis, ONE change, run test — if wrong, revert before next). Phase 4: Implement Fix (revert hack, write failing test for root cause, implement proper fix). Attempt counter triggers mandatory escalation after 3 failed attempts: re-read original error, question all assumptions, read code path from entry to failure. Red flags trigger immediate stop: shotgun debugging, symptom fixing, unexplained passes, escalating complexity, test modification.

### AC-5: Integration wiring check in /deliver
The `/deliver` command includes a mandatory Phase 4: Wiring Check after TDD phases (red-green-refactor). This phase verifies: (1) every interface defined in the design has a concrete implementation, not just a mock; (2) new components are instantiated and injected in service startup code; (3) async consumers/workers are registered; (4) no dead code exists without a path from an entrypoint. Missing wiring must be either implemented or explicitly flagged as "partially met (logic only)" in the Implementation section. For pure library/utility/prompt work with no service bootstrap, the phase notes "N/A — no service wiring required."

### AC-6: Wiring verification in /discern review
The `/discern` review checklist includes item 10: Wiring verification. For ACs describing system behavior (triggers, syncs, pushes, sends), the Critic verifies a code path exists from the running application to the implemented logic. Checks: real (non-mock) interface implementations, service bootstrap instantiation, event handler/consumer registration, traceable call paths from handlers to business logic to external effects. Mock-only results mark the AC as unmet. The calibration section includes an exception: never APPROVE when integration wiring is missing for end-to-end behavior ACs — this warrants CHANGES REQUESTED regardless of unit test coverage.

### AC-7: Mock boundary awareness in TDD discipline
The `tdd-discipline` rule includes a Mock Boundary Awareness section that distinguishes: unit tests with mocks = "logic works" (algorithm correctness); real implementation + service wiring = "feature works" (users can reach it). Both are required for ACs that describe system behavior. Mock-only delivery is explicitly called out as incomplete — "a library with no caller."

## Evidence

### Source Code
- `skills/tdd-discipline/SKILL.md`: TDD enforcement with AAA pattern and red-green-refactor
- `skills/code-quality/SKILL.md`: Code quality standards and instrumentation
- `skills/pattern-enforcement/SKILL.md`: Structural, data, and integration pattern checking
- `skills/conventional-commits/SKILL.md`: Commit message formatting with safety rules
- `skills/problem-first/SKILL.md`: Solution-to-problem reframing with JTBD
- `skills/debugging/SKILL.md`: 4-phase debugging protocol with escalation

### Documentation
- `rules/tdd-discipline.md`: Always-on TDD rule (complements the skill)
- `rules/code-quality.md`: Always-on code quality rule (complements the skill)

## Implementation Evidence
<!-- Updated by /deliver on 2026-03-02 from P1-integration-wiring-verification -->

### Implementation Files
- `commands/deliver.md`: Phase 4: Wiring Check added after TDD Phase 3 (AC-5)
- `commands/discern.md`: Review checklist item 10 + calibration exception (AC-6)
- `rules/tdd-discipline.md`: Mock Boundary Awareness section (AC-7)

## Review Verdict
<!-- Updated by /discern on 2026-03-02 from P1-integration-wiring-verification -->

**Verdict:** APPROVED
**ACs verified:** 7/7 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | TDD discipline enforced by skill (previously verified) |
| AC-2 | met | Code quality enforced by skill (previously verified) |
| AC-3 | met | Conventional commits enforced by skill (previously verified) |
| AC-4 | met | Debugging protocol enforced by skill (previously verified) |
| AC-5 | met | `commands/deliver.md` Phase 4: Wiring Check with 4 verification points |
| AC-6 | met | `commands/discern.md` checklist item 10 + calibration exception |
| AC-7 | met | `rules/tdd-discipline.md` Mock Boundary Awareness section |
