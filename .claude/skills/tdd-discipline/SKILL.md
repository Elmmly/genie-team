---
name: tdd-discipline
description: Enforces test-driven development with Red-Green-Refactor cycle. Use when writing new code, implementing features, fixing bugs, or when tests are mentioned. Ensures tests are written before implementation.
allowed-tools: Read, Write, Edit, Bash(npm test*), Bash(npm run test*), Bash(pytest*), Bash(jest*), Bash(cargo test*)
---

# TDD Discipline

You MUST follow strict test-first development. This is NOT optional.

## The Cycle

```
RED → GREEN → REFACTOR → (repeat)
```

## Phase 1: RED (Write Failing Tests)

Write ALL tests BEFORE any implementation code.

**Requirements:**
- Tests define expected behavior from requirements/design
- Use Arrange-Act-Assert (AAA) pattern
- Run tests and CONFIRM they fail
- Do NOT write implementation during this phase

**AAA Pattern:**
```javascript
// Arrange - Set up test data
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act - Execute single method
const result = await authService.validateAccess(request);

// Assert - Verify outcome
expect(result.allowed).toBe(true);
```

**AAA Rules:**
- Separate phases with blank lines
- One action per test
- Specific assertions (not just "not null")
- No conditional logic in tests

## Phase 2: GREEN (Minimal Implementation)

ONLY after tests are confirmed failing:

- Write minimal code to pass tests
- Do NOT modify tests to make them pass
- If a test is wrong, STOP and ask — never "fix" the test
- Focus on green, not perfect

## Phase 3: REFACTOR (Clean Up)

ONLY after all tests pass:

- Improve code quality
- Tests MUST stay green
- If tests fail, revert and retry

## Anti-Patterns to Catch

| Pattern | Response |
|---------|----------|
| Writing implementation first | STOP — write tests first |
| Modifying tests to pass | STOP — fix implementation instead |
| Skipping the red phase | STOP — run tests, confirm failure |
| Complex test setup | Simplify — tests should be readable |

## Output Format

When implementing with TDD, structure your work:

```
=== PHASE 1: RED ===
Writing tests...
[test file changes]
Running tests: X failed (expected)

=== PHASE 2: GREEN ===
Writing implementation...
[implementation changes]
Running tests: X passed

=== PHASE 3: REFACTOR ===
[any cleanup]
Tests still passing: X passed
```
