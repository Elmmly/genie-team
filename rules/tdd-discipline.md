# TDD Discipline

This project uses **Test-Driven Development** for all code changes.

## Red-Green-Refactor Cycle

1. **RED**: Write failing tests that define expected behavior
2. **GREEN**: Write minimal implementation to pass tests
3. **REFACTOR**: Improve code quality while keeping tests green

## Test Structure (AAA Pattern)

All tests MUST follow Arrange-Act-Assert with blank line separators:

```javascript
// Arrange - Set up test data and prerequisites
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act - Execute single method being tested
const result = await authService.validateAccess(request);

// Assert - Verify expected outcome
expect(result.allowed).toBe(true);
expect(result.role).toBe('admin');
```

## Constraints

- **NEVER** write implementation code without failing tests first
- **NEVER** modify tests to make them pass — fix the implementation
- One assertion focus per test (related assertions OK)
- No conditional logic (if/else) in tests
- Separate AAA sections with blank lines

## Mock Boundary Awareness

Unit tests against mocks prove logic correctness, NOT system integration. When delivering work that uses interfaces (stores, queues, external services):

- **Unit tests with mocks** = "logic works" — the algorithm is correct
- **Real implementation + service wiring** = "feature works" — users can reach it
- **Both are required** for ACs that describe system behavior (triggers, syncs, pushes, sends)

If you only have mock-passing tests and no real implementation wired into the running system, the feature is not delivered — it's a library with no caller.

## Using /deliver Command

The `/deliver` command enforces TDD:
- Full command: Writes tests first, then implementation
- `/deliver:tests`: Write failing tests only
- `/deliver:implement`: Write implementation only (tests exist)
