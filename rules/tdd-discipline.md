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

## Using /deliver Command

The `/deliver` command enforces TDD:
- Full command: Writes tests first, then implementation
- `/deliver:tests`: Write failing tests only
- `/deliver:implement`: Write implementation only (tests exist)
