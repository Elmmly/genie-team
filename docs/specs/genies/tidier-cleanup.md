---
spec_version: "1.0"
type: spec
id: tidier-cleanup
title: Tidier Safe Cleanup
status: active
created: 2026-02-25
domain: genies
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      Tidier genie definition exists at agents/tidier.md with haiku model, read + bash tools
      (Read, Grep, Glob, Bash), plan permission mode, and spec-awareness + code-quality +
      pattern-enforcement skills
    status: met
  - id: AC-2
    description: >-
      /tidy command executes cleanup in safe, test-gated batches (run tests before, make one
      batch of changes, run tests after, repeat or stop) following a Diagnose Report from
      the Architect
    status: met
  - id: AC-3
    description: >-
      Tidier applies Fowler's refactoring catalog (Extract Method, Inline Method, Rename,
      Move, Extract Constant, Remove Dead Code, Simplify Conditional, Replace Magic Number,
      Introduce Parameter Object) and classifies safety (safe to clean / requires care /
      escalate first)
    status: met
  - id: AC-4
    description: >-
      Tidier stops immediately on test failure, documents what was attempted, reverts if
      needed, and reports status; never continues after failures or makes behavioral changes
    status: met
---

# Tidier Safe Cleanup

The Tidier genie performs safe, incremental refactoring combining Kent Beck's Tidy First approach (structural changes before behavior), Martin Fowler's refactoring catalog, Boy Scout Rule (leave it better), and safe change practices (small batches, test-gated progress). It improves structure without changing behavior — same behavior, better structure.

The Tidier runs on haiku for cost efficiency since cleanup analysis benefits from fast iteration. It is activated via `/tidy` after the Architect has produced a Diagnose Report identifying cleanup priorities, or directly via the `/cleanup` shortcut which chains `/diagnose` then `/tidy`.

## Acceptance Criteria

### AC-1: Genie definition with correct configuration
Tidier genie definition at `agents/tidier.md` specifies haiku model for cost-efficient analysis, read + bash tools (Bash restricted to test runners and git commands), plan permission mode, and spec-awareness + code-quality + pattern-enforcement skills.

### AC-2: Test-gated batch execution
The `/tidy` command executes cleanup in safe, reversible batches following the protocol: run tests (must pass) → make one batch of changes → run tests (must pass) → repeat or stop. Batch sizes: Small (single file), Medium (related files), Large (module-level with extra caution). Unrelated changes are never batched together.

### AC-3: Refactoring catalog with safety classification
The Tidier applies refactoring patterns from Fowler's catalog and classifies each cleanup opportunity: Safe to Clean (dead code, unused imports, inconsistent naming, duplicated code), Requires Care (public API changes, configuration changes, database-related code), Escalate First (architectural changes, pattern modifications, security-related code). Effort is estimated as S (<15min), M (15-60min), or L (>1hr).

### AC-4: Failure handling and behavior preservation
On test failure: stop immediately, document what was attempted, revert if needed, and report. The Tidier never continues after failures, never makes behavioral changes, never adds new features during cleanup, and never cleans unrelated code (scope discipline). Cleanup Reports document batches executed, changes made, and verification status.

## Evidence

### Source Code
- `agents/tidier.md`: Genie definition with charter, judgment rules, safety classification, batch protocol
- `genies/tidier/TIDIER_SPEC.md`: Detailed specification
- `genies/tidier/TIDIER_SYSTEM_PROMPT.md`: System prompt
- `genies/tidier/CLEANUP_REPORT_TEMPLATE.md`: Cleanup report template
- `commands/tidy.md`: Slash command definition
- `commands/cleanup.md`: Shortcut command (diagnose → tidy)

### Tests
- `tests/test_execute.sh`: 62 tests covering command execution and genie invocation patterns
