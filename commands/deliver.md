# /deliver [backlog-item]

Activate Crafter genie to implement the technical design with TDD discipline.

---

## Arguments

- `backlog-item` - Path to backlog item (contains design section) (required)
- Optional flags:
  - `--tests` - Write tests only (TDD start)
  - `--implement` - Implementation only (tests exist)
  - `--instrument` - Add telemetry only

---

## Genie Invoked

**Crafter** - TDD implementer combining:
- Kent Beck (TDD, XP)
- Minimal implementation
- Clean code practices

---

## Context Loading

**READ (automatic):**
- docs/backlog/{priority}-{topic}.md (contains shaped contract + design)
- Backlog frontmatter field `spec_ref` → load the linked spec (ACs drive TDD targets)
- Target code files
- Related test files
- docs/context/codebase_structure.md

**RECALL:**
- Similar implementations in codebase
- Related test patterns

**ADR LOADING:**
1. Check for `adr_refs` in the backlog item or design section frontmatter
2. If present: Read each referenced ADR from `docs/decisions/`
3. If `docs/decisions/` does not exist: **Warn** and continue without ADR context
4. Surface relevant decisions that constrain implementation:
   - Technology choices (e.g., "ADR-001 specifies JWT refresh tokens, not sessions")
   - Boundary constraints (e.g., "ADR-003 requires auth to stay in its own service")
   - Read component diagram from `docs/architecture/components/{domain}.md` (if exists) for dependency directions
5. If implementation would violate an accepted ADR: **Warn prominently**
6. Note: `/deliver` reads ADRs and diagrams but does NOT create or modify them

**SPEC LOADING:**
1. Read `spec_ref` from backlog item frontmatter
2. If `spec_ref` is present: Read the spec file. Use its acceptance_criteria as TDD test targets in the RED phase. Each spec AC with `status: pending` should map to at least one test case.
3. If `spec_ref` is missing: Warn and continue:
   > This backlog item has no spec_ref. Consider linking it to a persistent spec in docs/specs/{domain}/. Proceeding with backlog ACs only.
4. If `spec_ref` points to a nonexistent file: Warn and continue:
   > spec_ref points to {path} but file not found. Proceeding with backlog ACs only.

---

## Context Writing

**WRITE:**
- Code changes
- Test files

**UPDATE:**
- Backlog item: Append "# Implementation" section before "# End of Shaped Work Contract"
- Backlog frontmatter: `status: designed` → `status: implemented`
- **Spec (if spec_ref exists):** Append or update "## Implementation Evidence" section in the spec body (see below)

> **Note:** Implementation notes are appended directly to the backlog item rather than creating a separate report file.

**SPEC UPDATE (when spec_ref is present):**

After completing implementation, update the linked spec:

1. **Append "## Implementation Evidence" section** to the spec body (or update if it already exists):
   ```markdown
   ## Implementation Evidence
   <!-- Updated by /deliver on {YYYY-MM-DD} from {backlog-item-id} -->

   ### Test Coverage
   - {test-file-path}: {N} test cases covering AC-1, AC-2
   - {test-file-path}: {N} test cases covering AC-3

   ### Implementation Files
   - {source-file-path}: {brief description}
   - {source-file-path}: {brief description}
   ```
2. **Do NOT modify spec acceptance_criteria statuses** — that is /discern's job
3. **Do NOT change spec status** — the spec stays `active`

---

## Output

Produces:
1. **Code** - Implementation following design
2. **Tests** - Comprehensive test coverage
3. **Implementation Report** - What was built, decisions made

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/deliver:tests [design]` | Write tests only (TDD start) |
| `/deliver:implement [design]` | Implementation only (tests exist) |
| `/deliver:instrument [files]` | Add telemetry only |

---

## TDD Discipline (MANDATORY)

Crafter MUST follow strict test-first development. This is NOT optional.

### Phase 1: Red (Write Failing Tests)

YOU MUST write all tests BEFORE any implementation code.

**Spec-Driven Test Targets:**
When a spec is loaded via `spec_ref`, use its acceptance_criteria to guide test writing:
- Each spec AC with `status: pending` should have at least one corresponding test
- Test descriptions should reference the AC id (e.g., "AC-1: should issue refresh tokens on login")
- Spec ACs complement (not replace) the design section's implementation guidance

**Constraints:**
- Write tests that define expected behavior based on the design
- Tests MUST use Arrange-Act-Assert (AAA) pattern
- Run tests and CONFIRM they fail (red)
- Do NOT write any implementation code during this phase
- Do NOT proceed until failing tests exist

**AAA Pattern Structure:**
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

**AAA Best Practices:**
- Separate phases with blank lines for readability
- One action per test (no Act-Assert-Act-Assert chains)
- Specific assertions (not just "not null")
- No conditional logic (if/else) in tests

### Phase 2: Green (Minimal Implementation)

ONLY after failing tests are written and confirmed failing:

**Constraints:**
- Write minimal code to make tests pass
- Do NOT modify the tests themselves
- If a test is wrong, STOP and escalate to user - do not "fix" the test
- Focus on making tests green, not on perfect code

### Phase 3: Refactor (Clean Up)

ONLY after all tests pass:

**Constraints:**
- Improve code quality (naming, structure, duplication)
- Tests MUST stay green throughout refactoring
- If tests fail during refactor, revert and try again

---

## Usage Examples

```
/deliver docs/backlog/P2-auth-improvements.md
> [Crafter implements with TDD]
>
> === PHASE 1: RED (Writing Tests) ===
> Writing tests based on design specification...
>
> Tests written:
> - tests/services/TokenService.test.ts (12 test cases)
> - tests/integration/auth.test.ts (8 test cases)
>
> Running tests to confirm RED state...
> Test run: 20 tests, 0 passed, 20 failed (RED - as expected)
>
> === PHASE 2: GREEN (Implementation) ===
> Writing minimal implementation to pass tests...
>
> Implementation complete:
> - src/services/TokenService.ts (new)
> - src/middleware/auth.ts (modified)
> - src/controllers/RefreshController.ts (new)
>
> Running tests to confirm GREEN state...
> Test run: 20 tests, 20 passed, 0 failed (GREEN)
>
> === PHASE 3: REFACTOR ===
> No refactoring needed - code is clean.
>
> Appended to docs/backlog/P2-auth-improvements.md
> Status updated: designed → implemented
>
> Next: /discern docs/backlog/P2-auth-improvements.md

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

After delivery:
- If implementation complete: `/handoff deliver discern`
- If tests failing: Fix before proceeding
- If design questions arise: Escalate to Architect

---

## Notes

- Tests FIRST, then implementation
- Minimal implementation (no gold plating)
- Stays within design boundaries
- Reports implementation decisions
- Scope discipline - only what's specified
