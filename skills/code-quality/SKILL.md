---
name: code-quality
description: Enforces code quality standards when writing or editing code. Use when implementing features, fixing bugs, or refactoring. Ensures error handling, no hardcoded values, proper patterns, and security considerations.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Code Quality Standards

Apply these standards when writing or editing code.

## Core Principles

### No Hardcoded Values
```javascript
// Bad
const timeout = 5000;
const apiUrl = "https://api.example.com";

// Good
const timeout = config.timeout;
const apiUrl = process.env.API_URL;
```

### Proper Error Handling
```javascript
// Bad - swallowing errors
try {
  await riskyOperation();
} catch (e) {
  // silent failure
}

// Good - meaningful handling
try {
  await riskyOperation();
} catch (error) {
  logger.error('Operation failed', { error, context });
  throw new OperationError('Failed to complete operation', { cause: error });
}
```

### Type Safety
- Type hints on public methods
- Interfaces for data structures
- Avoid `any` type

### Naming Conventions
- Descriptive, intention-revealing names
- Consistent casing (camelCase for variables, PascalCase for classes)
- No abbreviations unless universal (URL, ID, etc.)

## Error Handling Checklist

- [ ] External calls wrapped in try/catch
- [ ] Meaningful error messages
- [ ] Errors logged with context
- [ ] Graceful degradation where appropriate
- [ ] Fail fast on invalid state

## Security Considerations

- [ ] No sensitive data in logs
- [ ] Input validation at boundaries
- [ ] No injection vulnerabilities (SQL, command, etc.)
- [ ] Authentication/authorization checks
- [ ] Secure defaults

## Instrumentation

Add observability:
```javascript
logger.info('Operation completed', {
  operation: 'createUser',
  userId: user.id,
  duration: endTime - startTime
});
```

**Logging levels:**
- DEBUG: Detailed flow
- INFO: Key events
- WARNING: Recoverable issues
- ERROR: Failures requiring attention

## When Reviewing Your Code

Before finishing, verify:
1. No hardcoded values
2. Error handling complete
3. Types defined
4. Edge cases handled
5. Logging in place
