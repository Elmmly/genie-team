---
spec_version: "1.0"
type: spec
id: spec-aware-test-generation
title: Spec-Aware Test Generation
status: active
created: 2026-02-25
domain: genies
source: define
acceptance_criteria:
  - id: AC-1
    description: >-
      When /deliver:tests is invoked with a spec that has acceptance_criteria
      frontmatter, Crafter performs a spec-to-stub mapping pass before any
      other test writing — producing one failing test stub per AC minimum
    status: pending
  - id: AC-2
    description: >-
      Each generated stub includes an ac_id comment (e.g., # ac_id: AC-3) linking
      the test to its source acceptance criterion
    status: pending
  - id: AC-3
    description: >-
      Each generated stub follows the AAA pattern with a TODO marker in the
      Act section and a failing assertion (e.g., fail("not implemented"),
      assert False, or equivalent) in the Assert section
    status: pending
  - id: AC-4
    description: >-
      After the spec-to-stub mapping pass, Crafter adds edge-case tests beyond
      the direct AC stubs; the final test file contains more tests than ACs
    status: pending
  - id: AC-5
    description: >-
      At the end of RED phase, Crafter outputs a coverage table mapping each
      AC id to its test stub name(s) and coverage type (direct / edge-case)
    status: pending
  - id: AC-6
    description: >-
      When a spec has no acceptance_criteria frontmatter, Crafter logs a warning
      ("no ACs found; proceeding with manual test writing") and continues with
      existing RED phase behavior — no regression
    status: pending
  - id: AC-7
    description: >-
      The spec-to-stub behavior is documented in agents/crafter.md under the
      TDD Cycle section so Crafter follows it consistently across all invocations
    status: pending
---

# Spec-Aware Test Generation

## Overview

The spec-aware test generation capability adds a structured "spec-to-stub mapping pass" to Crafter's TDD RED phase. Before writing any free-form tests, Crafter maps every acceptance criterion in the spec's `acceptance_criteria` frontmatter to at least one named, failing test stub with an explicit `ac_id` comment linking test to AC. This makes AC coverage explicit, traceable, and auditable from the start of the RED phase rather than being discovered (or missed) during Critic review.

The capability is a Crafter-only enhancement (prompt instruction in `agents/crafter.md`). It does not change the test file format, the AAA pattern, the Execution Report schema, or any other workflow artifact.

## Design Constraints
<!-- Updated by /design on 2026-02-25 from P2-spec-aware-test-generation -->
- Implementation is Option A (prompt instruction in `agents/crafter.md`); no new files, no new skill, no new command
- The spec-to-stub mapping pass is a sub-section within the existing RED phase in `agents/crafter.md` TDD Cycle section — not a replacement of the existing RED phase behavior
- `ac_id` comment syntax adapts to the target test framework's comment character (# for Python/Bash, // for JS/TS/Go)
- Stub format follows existing AAA pattern: Arrange/Act with TODO markers, Assert with language-appropriate failing assertion
- Coverage table is output as narration (part of Execution Report Summary), not written as a separate file
- Guard clause: if spec has no `acceptance_criteria` frontmatter, Crafter logs a warning and proceeds with manual test writing — no regression
- When AC count >10, Crafter groups related ACs into describe/class blocks to prevent excessively large stub files
- Edge-case tests are written AFTER the mapping pass is complete — "at least one edge-case test per AC" instruction ensures total tests > AC count
- Changes are limited to `agents/crafter.md` (three additive edits: mapping pass sub-section, coverage table instruction, headless mode clarification)

## Implementation Evidence
<!-- Updated by /deliver on 2026-02-25 from P2-spec-aware-test-generation -->

### Test Coverage
- tests/test_spec_aware_stubs.sh: 36 test cases covering AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7

### Implementation Files
- agents/crafter.md: Added Spec-to-Stub Mapping Pass sub-section in TDD Cycle, coverage table instruction, and headless mode clarification

## Review Verdict

_To be populated by Critic during /discern phase._
