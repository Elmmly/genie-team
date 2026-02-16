---
spec_version: "1.0"
type: shaped-work
id: anemic-test-cleanup
title: "Clean Up Anemic Tests"
status: done
created: "2026-02-13"
done: "2026-02-13"
appetite: small
priority: P2
target_project: genie-team
author: architect
depends_on: []
tags: [tests, quality, maintenance]
acceptance_criteria:
  - id: AC-1
    description: "test_debugging.sh (formerly test_systematic_debugging.sh) is deleted — its tests only validate markdown string presence, not behavioral enforcement"
    status: completed
  - id: AC-2
    description: "test_transition_guidance.sh is deleted — its tests only validate markdown string presence, not behavioral enforcement"
    status: completed
  - id: AC-3
    description: "test_worktree.sh lines testing git's own worktree detection (not genie-team logic) are removed"
    status: deferred
    note: "Deferred — negative case strengthening split to separate future item. ROI questionable for shell tests guarding prompt engineering artifacts."
  - id: AC-4
    description: "test_execute.sh has negative case tests for malformed YAML (missing closing ---, tabs, empty files) and build_prompt tests verify structure/ordering, not just substring presence"
    status: deferred
    note: "Deferred — negative case strengthening split to separate future item."
  - id: AC-5
    description: "test_hooks.sh has at least one concurrent write test and one filesystem failure simulation"
    status: deferred
    note: "Deferred — negative case strengthening split to separate future item."
  - id: AC-6
    description: "test_session.sh has at least one git command failure simulation (non-zero exit from git)"
    status: deferred
    note: "Deferred — negative case strengthening split to separate future item."
  - id: AC-7
    description: "test_worktree.sh documentation-presence tests are replaced with behavioral enforcement tests (e.g., install.sh creates expected structure)"
    status: deferred
    note: "Deferred — negative case strengthening split to separate future item."
  - id: AC-8
    description: "All existing passing tests in test_run_pdlc.sh and test_precommit.sh continue to pass (regression guard)"
    status: completed
---

# Shaped Work Contract: Clean Up Anemic Tests and Strengthen Test Suite

## Problem

An architect audit of the test suite found that 2 of 8 test files are completely anemic — they only validate that markdown strings exist in documentation files, providing zero behavioral coverage and false confidence. Additionally, 5 of the remaining 6 files lack negative case testing entirely: no malformed input, no filesystem failures, no git command failures.

The test suite currently has two tiers:

1. **Strong behavioral tests** (test_run_pdlc.sh, test_precommit.sh, test_hooks.sh) — these test shell script logic with proper mocking and contract verification
2. **Anemic documentation validators** (test_systematic_debugging.sh, test_transition_guidance.sh) — these grep for markdown headings and contribute nothing

The anemic tests were created to cover prompt engineering artifacts (skills), which is a valid impulse, but the implementation tests *documentation content* rather than *enforceable behavior*. The precommit validators already enforce frontmatter schemas — these files add no value beyond that.

**Evidence:** Architect audit (2026-02-13) reviewed all 8 test files, classifying each test by anemia pattern (tautological, smoke-only, overly loose, missing negative cases). Two files scored CRITICAL (100% anemic), five scored HIGH for missing negative cases.

## Appetite & Boundaries

- **Appetite:** Medium (3-5 days) — deletions are fast, strengthening existing tests requires understanding each test's behavioral contract
- **No-gos:**
  - Do NOT add tests for markdown content in skill files (that's the precommit validator's job)
  - Do NOT rewrite test_run_pdlc.sh — it's the gold standard, leave it alone
  - Do NOT add tests that require external services or network access
- **Fixed elements:**
  - All existing passing tests in non-deleted files must continue to pass
  - New tests follow the project's AAA pattern with blank line separators
  - test_run_pdlc.sh serves as the reference pattern for quality behavioral tests

## Goals & Outcomes

- Eliminate false confidence from anemic tests
- Add meaningful negative case coverage to the 5 remaining shell script test files
- Establish a clear boundary: tests cover *shell script behavior*, not *markdown content*

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| test_systematic_debugging.sh and test_transition_guidance.sh provide no unique value beyond precommit validation | feasibility | Verify precommit validators cover the same structural checks |
| Concurrent write tests can be implemented in bash without flakiness | feasibility | Prototype a background-process race condition test |
| Git command failure simulation works reliably with function mocking | feasibility | Review test_run_pdlc.sh's existing mock pattern |

## Audit Findings Summary

### CRITICAL — Delete entirely

| File | Tests | Issue |
|------|-------|-------|
| `test_systematic_debugging.sh` | ~15 | Every test is `assert_grep` on markdown. Tests that section headings exist, not that the 4-phase protocol or 3-strike escalation work. |
| `test_transition_guidance.sh` | ~34 | Every test is string/regex matching in markdown. Tests section ordering and string presence, not that guidance appears in command output. |

### HIGH — Missing negative cases

| File | What's Missing |
|------|----------------|
| `test_execute.sh` | Malformed YAML (missing `---`, tabs), prompt structure validation |
| `test_hooks.sh` | Concurrent writes to session-state.md, filesystem failures |
| `test_session.sh` | Git command failures, remote push rejection |
| `test_worktree.sh` | Safety rule enforcement, install.sh behavioral tests |
| `test_precommit.sh` | Large file stress, non-UTF-8 encoding |

### MEDIUM — Overly loose assertions

| File | Location | Issue |
|------|----------|-------|
| `test_execute.sh` | L337-344 | `build_prompt` checks substring presence, not structure |
| `test_execute.sh` | L96-114 | Tautological YAML extraction tests |
| `test_worktree.sh` | L239-266 | Grepping for strings in rules files, not testing enforcement |

### Gold standard (no changes needed)

| File | Why |
|------|-----|
| `test_run_pdlc.sh` | Comprehensive mocking, behavioral contracts, retry logic, exit code propagation |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Delete anemic files, strengthen the rest | Removes false confidence, adds real coverage | Loses structural tests (minor — precommit covers this) | **Recommended** |
| B: Rewrite anemic files as behavioral integration tests | Preserves test count | Hard to test prompt behavior in bash; may produce new anemic tests | Not recommended — no enforceable behavior to test |
| C: Only delete, don't strengthen | Minimal effort | Doesn't address the negative case gap | Insufficient |

## Routing

- [x] **Crafter** — Medium appetite, test file deletions + new test authoring
- [ ] **Architect** — Not needed (audit already complete)
