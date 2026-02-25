---
spec_version: "1.0"
type: spec
id: crafter-implementation
title: Crafter TDD Implementation
status: active
created: 2026-02-25
domain: genies
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      Crafter genie definition exists at agents/crafter.md with sonnet model, full tool access
      (Read, Grep, Glob, Bash, Write, Edit), default permission mode, and spec-awareness +
      architecture-awareness + code-quality + tdd-discipline + debugging + pattern-enforcement skills
    status: met
  - id: AC-2
    description: >-
      /deliver command activates Crafter to implement a design using strict TDD (red-green-refactor),
      producing code changes and an Execution Report appended to the backlog item with YAML
      frontmatter per schemas/execution-report.schema.md
    status: met
  - id: AC-3
    description: >-
      /deliver:tests writes failing tests only (TDD RED phase); /deliver:implement writes
      implementation only when tests already exist (TDD GREEN phase)
    status: met
  - id: AC-4
    description: >-
      Crafter operates in headless mode without interactive prompts, reading spec and design
      from file paths, parsing acceptance_criteria from spec frontmatter, and producing
      execution reports as structured output
    status: met
---

# Crafter TDD Implementation

The Crafter genie implements designs with strict test-first discipline combining Kent Beck (TDD, XP, simple design), Martin Fowler (refactoring, clean code), Dave Thomas & Andy Hunt (pragmatic programming), and SOLID principles. It writes tests FIRST, implements minimal code to pass tests, refactors for clarity while tests stay green, follows project patterns, adds instrumentation, and stays within design boundaries.

The Crafter is the only genie with write access to source code (Write, Edit tools) and the only one running in default permission mode (not plan mode). It supports both interactive delivery and headless execution for autonomous lifecycle runs.

## Acceptance Criteria

### AC-1: Genie definition with correct configuration
Crafter genie definition at `agents/crafter.md` specifies sonnet model for implementation judgment, full tool access (Read, Grep, Glob, Bash, Write, Edit), default permission mode (the only genie not in plan mode), and the most skills of any genie: spec-awareness, architecture-awareness, code-quality, tdd-discipline, debugging, and pattern-enforcement.

### AC-2: TDD implementation with Execution Report
The `/deliver` command activates Crafter to implement a design using the mandatory TDD cycle: RED (write failing test for requirement), GREEN (write minimal code to pass), REFACTOR (clean up while tests pass). Output is an Execution Report appended to the backlog item with frontmatter per `schemas/execution-report.schema.md` including files_changed, test_results (passed/failed/skipped), and acceptance_criteria status per AC.

### AC-3: Split delivery commands
`/deliver:tests` writes failing tests only (the RED phase of TDD) for situations where tests should be reviewed before implementation. `/deliver:implement` writes implementation only when tests already exist (the GREEN phase). Tests use the AAA pattern (Arrange-Act-Assert) with blank line separators, one assertion focus per test, and no conditional logic.

### AC-4: Headless execution mode
In headless mode (invoked via `claude -p`), the Crafter reads spec and design from file paths, parses `acceptance_criteria` from spec frontmatter, executes the TDD cycle autonomously within design boundaries, and produces the execution report as the only output. No interactive prompts are issued — all decisions stay within spec and design boundaries.

## Evidence

### Source Code
- `agents/crafter.md`: Genie definition with charter, TDD cycle, AAA pattern, scope discipline rules
- `genies/crafter/CRAFTER_SPEC.md`: Detailed specification
- `genies/crafter/CRAFTER_SYSTEM_PROMPT.md`: System prompt
- `genies/crafter/IMPLEMENTATION_REPORT_TEMPLATE.md`: Execution report template
- `commands/deliver.md`: Full delivery command
- `commands/deliver-tests.md`: Tests-only delivery
- `commands/deliver-implement.md`: Implementation-only delivery
- `schemas/execution-report.schema.md`: Execution report schema

### Tests
- `tests/test_execute.sh`: 62 tests covering command execution and genie invocation patterns
