---
name: tdd-discipline
description: Enforces test-driven development with Red-Green-Refactor cycle. Use when writing new code, implementing features, fixing bugs, or when tests are mentioned. Ensures tests are written before implementation.
allowed-tools: Read, Write, Edit, Bash(npm test*), Bash(npm run test*), Bash(npx vitest*), Bash(pytest*), Bash(jest*), Bash(cargo test*), Bash(cargo check*), Bash(cargo clippy*), Bash(go test*), Bash(go vet*), Bash(go build*), Bash(dotnet test*), Bash(dotnet build*), Bash(mvn test*), Bash(mvn compile*), Bash(gradle test*), Bash(gradle build*), Bash(./gradlew *), Bash(swift build*), Bash(swift test*), Bash(xcodebuild *), Bash(make test*), Bash(make check*)
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

**AAA Pattern by Language:**

**TypeScript (Jest/Vitest):**
```typescript
// Arrange
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act
const result = await authService.validateAccess(request);

// Assert
expect(result.allowed).toBe(true);
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
```

**Swift (XCTest):**
```swift
// Arrange
let user = createTestUser(role: .admin)
let request = mockRequest(userId: user.id)

// Act
let result = try await authService.validateAccess(request)

// Assert
XCTAssertTrue(result.allowed)
```

**Kotlin (JUnit 5):**
```kotlin
// Arrange
val user = createTestUser(role = "admin")
val request = mockRequest(userId = user.id)

// Act
val result = authService.validateAccess(request)

// Assert
assertThat(result.allowed).isTrue()
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
