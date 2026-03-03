---
name: pattern-enforcement
description: Enforces project patterns and architecture conventions. Use when designing systems, implementing features, or reviewing code structure. Ensures consistency with established patterns.
allowed-tools: Read, Glob, Grep
---

# Pattern Enforcement

Ensure code follows established project patterns and conventions.

## Discovery Phase

Before implementing, identify project patterns:

1. **Check CLAUDE.md** for documented conventions
2. **Search for similar code** to understand existing patterns
3. **Look for pattern indicators:**
   - Factory functions
   - Registry patterns
   - Repository pattern for data access
   - Adapter pattern for integrations
   - Strategy pattern for variants

## Common Patterns to Enforce

### Structural Patterns

**Registry Pattern:**

| Language | Idiomatic Form |
|----------|---------------|
| TypeScript | `const registry = new Map<string, Handler>(); registry.set('key', impl);` |
| Go | `var registry = map[string]Handler{}` with `sync.RWMutex` for concurrent access |
| Rust | `lazy_static! { static ref REGISTRY: Mutex<HashMap<String, Box<dyn Handler>>> = ...; }` |
| C# | `services.AddSingleton<IRegistry, Registry>();` via DI container |
| Java | `@Component` with `Map<String, Handler>` injected via Spring |

**Factory Pattern:**

| Language | Idiomatic Form |
|----------|---------------|
| TypeScript | `function createUser(data: UserInput): User { ... }` |
| Go | `func NewUser(data UserInput) (*User, error) { ... }` |
| Rust | `impl User { pub fn new(data: UserInput) -> Result<Self> { ... } }` |
| C# | `public static User Create(UserInput data) { ... }` |
| Java | `public static User create(UserInput data) { ... }` |
| Swift | `static func create(from data: UserInput) -> User { ... }` |
| Kotlin | `fun createUser(data: UserInput): User { ... }` (top-level or companion object) |

### Data Patterns

**Repository Pattern:**

| Language | Idiomatic Form |
|----------|---------------|
| TypeScript | `interface UserRepository { findById(id: string): Promise<User \| null> }` |
| Go | `type UserRepository interface { FindByID(ctx context.Context, id string) (*User, error) }` |
| Rust | `trait UserRepository { async fn find_by_id(&self, id: &str) -> Result<Option<User>>; }` |
| C# | `interface IUserRepository { Task<User?> FindByIdAsync(string id); }` |
| Java | `public interface UserRepository extends JpaRepository<User, String> { }` |

**Error Propagation (cross-cutting):**

| Language | Pattern |
|----------|---------|
| TypeScript | `throw new AppError('context', { cause: error })` |
| Go | `fmt.Errorf("functionName: %w", err)` — always wrap with context |
| Rust | `.context("what failed")?` (anyhow) or custom error types (thiserror) |
| C# | `throw new AppException("context", ex)` — inner exception chaining |
| Java | `throw new AppException("context", e)` — cause chaining |
| Swift | `throw AppError.operationFailed(context: "what failed", cause: error)` |
| Kotlin | `throw AppException("context", cause = e)` — cause chaining |

### Integration Patterns

**Adapter Pattern:**

| Language | Idiomatic Form |
|----------|---------------|
| TypeScript | `class StripeAdapter implements PaymentGateway { async charge(amount: Money) { ... } }` |
| Go | `type stripeAdapter struct { client *stripe.Client }` implementing `PaymentGateway` interface |
| Rust | `struct StripeAdapter { client: StripeClient } impl PaymentGateway for StripeAdapter { ... }` |
| C# | `class StripeAdapter : IPaymentGateway { ... }` registered via DI |
| Java | `@Component class StripeAdapter implements PaymentGateway { ... }` |

## Enforcement Checklist

When reviewing or implementing:

- [ ] Follows existing patterns in codebase
- [ ] No new patterns without justification
- [ ] Consistent naming with existing code
- [ ] Proper layer separation (controller → service → repository)
- [ ] Dependencies injected, not instantiated
- [ ] Configuration externalized
- [ ] Error propagation follows language idiom

## Deviation Handling

If you need to deviate from patterns:

1. **Document the deviation** — Why is this different?
2. **Justify the choice** — What benefit does it provide?
3. **Consider alternatives** — Can the pattern be extended instead?
4. **Flag for review** — Architectural changes need team buy-in

## Anti-Patterns to Catch

| Anti-Pattern | Fix |
|--------------|-----|
| God object | Split into focused classes/structs |
| Spaghetti dependencies | Introduce proper layering |
| Hardcoded integrations | Use adapter pattern |
| Scattered business logic | Centralize in services |
| Direct DB in controllers | Use repository pattern |

## Output When Enforcing

```markdown
## Pattern Analysis

**Existing patterns found:**
- [Pattern 1]: Used in [files]
- [Pattern 2]: Used in [files]

**Recommendation:**
Follow [pattern] as used in [example file].

**If deviating:**
Deviation from [pattern] because [reason].
```
