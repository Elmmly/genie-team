# TDD Discipline

This project uses **Test-Driven Development** for all code changes.

## Red-Green-Refactor Cycle

1. **RED**: Write failing tests that define expected behavior
2. **GREEN**: Write minimal implementation to pass tests
3. **REFACTOR**: Improve code quality while keeping tests green

## Test Structure (AAA Pattern)

All tests MUST follow Arrange-Act-Assert with blank line separators.

**TypeScript (Jest/Vitest):**
```typescript
// Arrange - Set up test data and prerequisites
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act - Execute single method being tested
const result = await authService.validateAccess(request);

// Assert - Verify expected outcome
expect(result.allowed).toBe(true);
expect(result.role).toBe('admin');
```

**Go:**
```go
// Arrange
user := createTestUser(t, "admin")
req := mockRequest(user.ID)

// Act
result, err := authService.ValidateAccess(req)

// Assert
require.NoError(t, err)
assert.True(t, result.Allowed)
assert.Equal(t, "admin", result.Role)
```

**Rust:**
```rust
// Arrange
let user = create_test_user(Role::Admin);
let request = mock_request(user.id);

// Act
let result = auth_service.validate_access(&request).unwrap();

// Assert
assert!(result.allowed);
assert_eq!(result.role, Role::Admin);
```

**C# (xUnit):**
```csharp
// Arrange
var user = CreateTestUser(role: "admin");
var request = MockRequest(userId: user.Id);

// Act
var result = await _authService.ValidateAccess(request);

// Assert
Assert.True(result.Allowed);
Assert.Equal("admin", result.Role);
```

**Java (JUnit 5):**
```java
// Arrange
var user = createTestUser("admin");
var request = mockRequest(user.getId());

// Act
var result = authService.validateAccess(request);

// Assert
assertThat(result.isAllowed()).isTrue();
assertThat(result.getRole()).isEqualTo("admin");
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
