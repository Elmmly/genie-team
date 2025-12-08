# /deliver:implement [backlog-item]

Write implementation to pass existing tests (TDD Green phase). Tests must already exist.

---

## Arguments

- `backlog-item` - Path to backlog item with design section (required)

---

## Genie Invoked

**Crafter** (Implementation Mode) - Writing implementation only

---

## Prerequisites

- Failing tests MUST already exist (from `/deliver:tests` or manual creation)
- If no tests exist, STOP and instruct user to run `/deliver:tests` first

---

## Constraints (CRITICAL)

YOU MUST follow these constraints exactly:

1. **ONLY write implementation code** - Do NOT modify test files
2. **Make tests pass** - Write minimal code to turn tests green
3. **Do NOT modify tests** - If a test seems wrong, STOP and escalate
4. **Minimal implementation** - No gold plating, no extra features

**Forbidden Actions:**
- Modifying test files
- Adding tests
- Deleting or skipping tests
- "Fixing" tests to make them pass

---

## Context Loading

**READ (automatic):**
- Backlog item (contains design specification)
- Existing test files (the contract to satisfy)
- Target implementation files
- docs/context/codebase_structure.md

---

## Output

Produces:
1. **Implementation code** - Minimal code to pass tests
2. **Test run results** - Confirmation that tests pass (green)
3. **Summary** - What was implemented, decisions made

---

## Usage Example

```
/deliver:implement docs/backlog/P2-auth-improvements.md
> [Crafter implements to pass tests - GREEN phase]
>
> Implementation complete:
> - src/services/TokenService.ts (new)
> - src/middleware/auth.ts (modified)
>
> Test run: 20 tests, 20 passed, 0 failed (GREEN)
>
> Next: /discern docs/backlog/P2-auth-improvements.md
```

---

## Routing

After implementation:
- **Tests passing:** `/discern [backlog-item]` for review
- **Tests still failing:** Continue implementation or escalate

---

## Notes

- This is the GREEN phase of TDD
- Tests are the specification - do not question them during this phase
- If tests are wrong, that's a separate conversation (escalate to user)
- Write the minimum code necessary to pass tests
