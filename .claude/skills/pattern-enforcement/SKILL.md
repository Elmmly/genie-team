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
```javascript
// Check for existing registries
const registry = getRegistry();
registry.register('key', implementation);

// NOT: scattered singletons or globals
```

**Factory Pattern:**
```javascript
// Use factories for object creation
const user = createUser(data);

// NOT: direct instantiation scattered everywhere
new User(data);
```

### Data Patterns

**Repository Pattern:**
```javascript
// Centralized data access
const user = await userRepository.findById(id);

// NOT: direct database calls in business logic
const user = await db.query('SELECT * FROM users WHERE id = ?', [id]);
```

**DTO Pattern:**
```javascript
// Transform at boundaries
const userDTO = toUserDTO(userEntity);
return res.json(userDTO);

// NOT: exposing internal entities directly
```

### Integration Patterns

**Adapter Pattern:**
```javascript
// Wrap external services
const paymentAdapter = new StripeAdapter(stripeClient);
await paymentAdapter.charge(amount);

// NOT: direct API calls scattered in business logic
```

## Enforcement Checklist

When reviewing or implementing:

- [ ] Follows existing patterns in codebase
- [ ] No new patterns without justification
- [ ] Consistent naming with existing code
- [ ] Proper layer separation (controller → service → repository)
- [ ] Dependencies injected, not instantiated
- [ ] Configuration externalized

## Deviation Handling

If you need to deviate from patterns:

1. **Document the deviation** — Why is this different?
2. **Justify the choice** — What benefit does it provide?
3. **Consider alternatives** — Can the pattern be extended instead?
4. **Flag for review** — Architectural changes need team buy-in

## Anti-Patterns to Catch

| Anti-Pattern | Fix |
|--------------|-----|
| God object | Split into focused classes |
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
