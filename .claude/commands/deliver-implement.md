# /deliver:implement [backlog-item]

Write implementation to pass existing tests (TDD Green phase). Tests must already exist.

---

## Arguments

- `backlog-item` - Path to backlog item with design section (required)

---

## Agent Identity

Read and internalize `.claude/agents/crafter.md` for your identity, charter, and judgment rules. You are in **Implementation Mode** — writing implementation only.

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
- Backlog frontmatter field `spec_ref` → load the linked spec for context
- Existing test files (the contract to satisfy)
- Target implementation files
- docs/context/codebase_structure.md

**SPEC LOADING:**
1. Read `spec_ref` from backlog item frontmatter
2. If `spec_ref` is present: Read the spec file for implementation context.
3. If `spec_ref` is missing: Warn and continue:
   > This backlog item has no spec_ref. Proceeding without spec context.
4. If `spec_ref` points to a nonexistent file: Warn and continue:
   > spec_ref points to {path} but file not found. Proceeding without spec context.

**SPEC UPDATE (after implementation is GREEN):**
When spec_ref is present, update the linked spec with implementation evidence:
1. Append or update "## Implementation Evidence" section with test file paths and implementation file paths
2. Do NOT modify spec AC statuses — that is /discern's job

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
