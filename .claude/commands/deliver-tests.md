# /deliver:tests [backlog-item]

Write failing tests only (TDD Red phase). Use this for human-in-the-loop TDD workflow.

---

## Arguments

- `backlog-item` - Path to backlog item with design section (required)

---

## Agent Identity

Read and internalize `.claude/agents/crafter.md` for your identity, charter, and judgment rules. You are in **Test Mode** — writing tests only.

---

## Constraints (CRITICAL)

YOU MUST follow these constraints exactly:

1. **ONLY write test files** - Do NOT write any implementation code
2. **Tests MUST fail** - Run tests after writing to confirm they fail (red)
3. **Use AAA pattern** - All tests follow Arrange-Act-Assert structure
4. **Stop when done** - After tests are written and confirmed failing, STOP

**Forbidden Actions:**
- Writing to source/implementation files
- Creating stub implementations
- Modifying existing implementation code
- Writing code to make tests pass

---

## Context Loading

**READ (automatic):**
- Backlog item (contains design specification)
- Backlog frontmatter field `spec_ref` → load the linked spec (ACs drive test targets)
- Existing test files (for patterns and conventions)
- docs/context/codebase_structure.md

**SPEC LOADING:**
1. Read `spec_ref` from backlog item frontmatter
2. If `spec_ref` is present: Load spec and use acceptance_criteria as test targets. Each spec AC with `status: pending` should map to at least one test case. Reference AC ids in test descriptions.
3. If `spec_ref` is missing: Warn and continue:
   > This backlog item has no spec_ref. Proceeding with backlog ACs only.
4. If `spec_ref` points to a nonexistent file: Warn and continue:
   > spec_ref points to {path} but file not found. Proceeding with backlog ACs only.

---

## AAA Pattern Structure

All tests MUST follow Arrange-Act-Assert:

```
// Arrange - Set up test data and prerequisites
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act - Execute single method being tested
const result = await authService.validateAccess(request);

// Assert - Verify expected outcome
expect(result.allowed).toBe(true);
expect(result.role).toBe('admin');
```

**Best Practices:**
- Separate phases with blank lines for readability
- One action per test (no Act-Assert-Act-Assert chains)
- Specific assertions (not just "not null")
- No conditional logic (if/else) in tests

---

## Output

Produces:
1. **Test files** - Comprehensive failing tests based on design
2. **Test run results** - Confirmation that tests fail (red)
3. **Summary** - What was tested, coverage areas

---

## Usage Example

```
/deliver:tests docs/backlog/P2-auth-improvements.md
> [Crafter writes tests only - RED phase]
>
> Tests written:
> - tests/services/TokenService.test.ts (12 test cases)
> - tests/integration/auth.test.ts (8 test cases)
>
> Test run: 20 tests, 0 passed, 20 failed (RED - as expected)
>
> Ready for implementation.
> Next: /deliver:implement docs/backlog/P2-auth-improvements.md
```

---

## Routing

After tests written:
- **Ready for implementation:** `/deliver:implement [backlog-item]`
- **Design questions:** Escalate to Architect

---

## Notes

- This is the RED phase of TDD
- Human reviews tests before proceeding to implementation
- Tests define the contract - implementation must satisfy them
- Do NOT proceed to implementation in this command
