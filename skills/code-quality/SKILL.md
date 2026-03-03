---
name: code-quality
description: Enforces code quality standards when writing or editing code. Use when implementing features, fixing bugs, or refactoring. Ensures error handling, no hardcoded values, proper patterns, and security considerations.
allowed-tools: Read, Write, Edit, Grep, Glob
---

# Code Quality Standards

Apply these standards when writing or editing code.

## Core Principles

### No Hardcoded Values

| Language | Bad | Good |
|----------|-----|------|
| TypeScript | `const timeout = 5000;` | `const timeout = config.timeout;` |
| Go | `url := "https://api.example.com"` | `url := cfg.APIURL` |
| Rust | `let port = 8080;` | `let port = config.port;` |
| C# | `var connStr = "Server=localhost";` | `var connStr = configuration["ConnectionString"];` |
| Java | `int timeout = 5000;` | `int timeout = appConfig.getTimeout();` |

### Proper Error Handling

Errors must be logged with context and propagated meaningfully. Never swallow errors silently.

| Language | Pattern |
|----------|---------|
| TypeScript | `try { ... } catch (error) { logger.error('context', { error }); throw new AppError('message', { cause: error }); }` |
| Go | `if err != nil { return fmt.Errorf("functionName: %w", err) }` — NEVER bare `return err` |
| Rust | `operation().context("what failed")?` or `operation().map_err(\|e\| AppError::new(e))?` |
| C# | `catch (Exception ex) { logger.LogError(ex, "context"); throw new AppException("message", ex); }` |
| Java | `catch (Exception e) { log.error("context", e); throw new AppException("message", e); }` |

### Type Safety
- Type hints on public methods
- Interfaces/traits for data structures
- Avoid escape hatches (`any` in TS, `interface{}` in Go, `Object` in Java)

### Naming Conventions
- Descriptive, intention-revealing names
- Follow language idiom: camelCase (TS/Java), snake_case (Rust), MixedCaps (Go), PascalCase (C#)
- No abbreviations unless universal (URL, ID, etc.)

## Language-Specific Anti-Patterns

### Go
| Anti-Pattern | Fix |
|--------------|-----|
| Bare `return err` | `return fmt.Errorf("context: %w", err)` |
| Manual loops for `slices` operations (Go 1.21+) | Use `slices.Contains`, `slices.Sort`, etc. |
| `interface{}` (Go 1.18+) | Use `any` |
| `if a > b { return a }` (Go 1.21+) | Use `max(a, b)` |
| Unbounded goroutines | Use `errgroup.Group` for bounded concurrency |
| Missing `context.Context` | Always pass as first parameter |

### Rust
| Anti-Pattern | Fix |
|--------------|-----|
| `.unwrap()` in library code | Use `?` operator with proper error types |
| `.clone()` to escape borrow checker | Restructure ownership or use references |
| Manual error types without `thiserror` | Use `thiserror` for library, `anyhow` for apps |
| Blocking in async context | Use `tokio::spawn_blocking` |

### TypeScript
| Anti-Pattern | Fix |
|--------------|-----|
| `any` type | Use proper types or `unknown` with type guards |
| `@ts-ignore` / `@ts-expect-error` | Fix the type error properly |
| Not running `tsc --noEmit` | Always verify types compile |
| `== null` without strictNullChecks | Enable strict mode in tsconfig |

### C#
| Anti-Pattern | Fix |
|--------------|-----|
| `new HttpClient()` per request | Use `IHttpClientFactory` |
| `Startup.cs` on .NET 6+ | Use minimal hosting with `WebApplication.CreateBuilder` |
| `Task.Result` / `Task.Wait()` | Use `await` — blocking on async causes deadlocks |
| Nullable warnings ignored | Enable `<Nullable>enable</Nullable>` |

### Java
| Anti-Pattern | Fix |
|--------------|-----|
| JPA entities in WebFlux pipelines | Use R2DBC for reactive data access |
| `javax.*` on Jakarta EE 10+ | Use `jakarta.*` namespace |
| Raw `@Autowired` field injection | Use constructor injection |
| Catching `Exception` broadly | Catch specific exception types |

## Error Handling Checklist

- [ ] External calls wrapped in error handling
- [ ] Meaningful error messages with context
- [ ] Errors logged with structured data
- [ ] Graceful degradation where appropriate
- [ ] Fail fast on invalid state

## Security Considerations

- [ ] No sensitive data in logs
- [ ] Input validation at boundaries
- [ ] No injection vulnerabilities (SQL, command, etc.)
- [ ] Authentication/authorization checks
- [ ] Secure defaults

## Instrumentation

Add observability with structured logging at boundaries:

| Language | Example |
|----------|---------|
| TypeScript | `logger.info('operation completed', { operation: 'createUser', userId, duration })` |
| Go | `slog.Info("operation completed", "operation", "createUser", "userId", userId, "duration", duration)` |
| Rust | `tracing::info!(operation = "create_user", user_id = %id, duration = ?elapsed, "operation completed")` |
| C# | `logger.LogInformation("Operation {Op} completed for {UserId} in {Duration}ms", op, userId, duration)` |
| Java | `log.info("Operation {} completed for userId={} in {}ms", op, userId, duration)` |

**Logging levels:**
- DEBUG: Detailed flow
- INFO: Key events
- WARNING: Recoverable issues
- ERROR: Failures requiring attention

## When Reviewing Your Code

Before finishing, verify:
1. No hardcoded values
2. Error handling complete (language-idiomatic)
3. Types defined (no escape hatches)
4. Edge cases handled
5. Logging in place
