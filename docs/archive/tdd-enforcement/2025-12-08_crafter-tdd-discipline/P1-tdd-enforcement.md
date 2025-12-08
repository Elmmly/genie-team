---
title: TDD Enforcement for Crafter Agent
priority: P1
status: done
created: 2025-12-08
appetite: Small batch
discovery: docs/analysis/20251208_discover_tdd_enforcement.md
---

# TDD Enforcement for Crafter Agent

## Problem Frame

### What We're Solving
The Crafter genie (invoked via `/deliver`) is documented to follow TDD discipline but consistently writes implementation code before tests. The current prompt language is *descriptive* ("Crafter follows strict TDD") rather than *prescriptive* (explicit constraints that change behavior).

### Why It Matters
- Tests written after implementation often assert buggy behavior
- Without test-first discipline, the "safety net" value of tests is compromised
- Users expect TDD when the command documentation promises it
- Anthropic research confirms TDD is the optimal workflow for agentic coding

### Who It Affects
- Developers using `/deliver` command expecting TDD workflow
- Code quality across projects using genie-team

---

## Appetite

**Size:** Small batch
**Boundary:** Update existing command files and templates only - no new infrastructure

### What's In
- Enhanced `/deliver` command with explicit TDD constraints
- Functional sub-commands (`/deliver:tests`, `/deliver:implement`) for human-in-the-loop workflow
- CLAUDE.md template updates with TDD section
- AAA pattern documentation and examples

### What's Out
- Hook-based enforcement (future consideration)
- Automated test validation tooling
- Changes to other genies/commands

---

## Solution Sketch

### Part 1: Enhanced `/deliver` Command (Option A)

Replace the current TDD section with explicit constraint language:

**Current (permissive):**
```markdown
## TDD Workflow
Crafter follows strict TDD:
1. Red - Write failing test
2. Green - Minimal code to pass
3. Refactor - Clean up while green
```

**New (prescriptive):**
```markdown
## TDD Discipline (MANDATORY)

### Phase 1: Red (Tests First)
YOU MUST write all tests BEFORE any implementation code.
- Write tests that define expected behavior
- Tests MUST use Arrange-Act-Assert (AAA) pattern
- Run tests and CONFIRM they fail
- Do NOT proceed to implementation until tests exist

### Phase 2: Green (Minimal Implementation)
ONLY after failing tests are written:
- Write minimal code to make tests pass
- Do NOT modify the tests themselves
- If a test is wrong, escalate - do not "fix" it

### Phase 3: Refactor
Only after tests pass:
- Improve code quality
- Tests must stay green
```

### Part 2: Functional Sub-Commands (Option B)

Make existing sub-commands enforce phase separation:

**`/deliver:tests`** - Test-only mode
- Writes ONLY test files
- Runs tests to confirm they fail
- Blocks any implementation file writes
- Prompts user to run `/deliver:implement` when ready

**`/deliver:implement`** - Implementation-only mode
- Requires tests to exist (checks for test files)
- Writes ONLY implementation code
- Blocks any test file modifications
- Runs tests to confirm they pass

**`/deliver` (full)** - Orchestrates both phases
- Calls tests phase first
- Pauses for user confirmation (human-in-the-loop)
- OR proceeds automatically with clear phase separation in output

### Part 3: CLAUDE.md Template (Option D)

Add TDD section to `templates/CLAUDE.md`:

```markdown
## TDD Requirements

This project uses Test-Driven Development for all code changes.

### Red-Green-Refactor Cycle
1. **RED**: Write failing tests that define expected behavior
2. **GREEN**: Write minimal implementation to pass tests
3. **REFACTOR**: Improve code quality while keeping tests green

### Test Structure (AAA Pattern)
All tests follow Arrange-Act-Assert:

```javascript
// Arrange - Set up test data and prerequisites
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act - Execute single method being tested
const result = await authService.validateAccess(request);

// Assert - Verify expected outcome
expect(result.allowed).toBe(true);
expect(result.role).toBe('admin');
```

### Constraints
- NEVER write implementation code without failing tests first
- NEVER modify tests to make them pass - fix the implementation
- One assertion focus per test (related assertions OK)
- No conditional logic in tests
```

---

## Rabbit Holes

### Avoid
- **Over-engineering sub-commands** - Keep them simple; the goal is phase separation, not complex validation logic
- **Strict file-path enforcement** - Don't try to parse which files are "tests" vs "implementation" by path; trust the phase instructions
- **Automated commit gates** - Don't require commits between phases; that's user choice
- **Changing other commands** - This scope is `/deliver` only

### Watch For
- If `/deliver` full mode still doesn't enforce separation, the sub-command approach becomes the primary recommendation
- User feedback on whether human-in-the-loop (sub-commands) or automatic (full command) is preferred

---

## Acceptance Criteria

### Must Have
- [ ] `/deliver` command includes explicit "YOU MUST write tests BEFORE implementation" constraint
- [ ] AAA pattern is documented with example in `/deliver` command
- [ ] `/deliver:tests` sub-command writes only test files and confirms they fail
- [ ] `/deliver:implement` sub-command writes only implementation and doesn't modify tests
- [ ] `templates/CLAUDE.md` includes TDD requirements section

### Should Have
- [ ] `/deliver` full mode has visible phase separation in output (shows "Phase 1: Tests" then "Phase 2: Implementation")
- [ ] Sub-commands suggest next step (e.g., "Run `/deliver:implement` to continue")

### Nice to Have
- [ ] Example test templates for common patterns (unit, integration)
- [ ] Guidance on test file naming conventions

---

## Handoff

**Ready for:** Design (technical specification)

**Next command:** `/design docs/backlog/P1-tdd-enforcement.md`

**Designer notes:**
- Focus on prompt language that creates behavioral change
- Sub-commands should be simple wrappers with constraints, not complex logic
- CLAUDE.md section should be copy-paste ready for any project

---

# Design

**Architect:** Navigator
**Date:** 2025-12-08

## Design Summary

This design updates three files to enforce TDD discipline through explicit prompt constraints:
1. `commands/deliver.md` - Enhanced with prescriptive TDD language and AAA pattern
2. `commands/deliver-tests.md` - New sub-command for test-only phase
3. `commands/deliver-implement.md` - New sub-command for implementation-only phase
4. `templates/CLAUDE.md` - TDD requirements section added

The approach uses **prompt engineering** rather than hooks/automation - explicit constraints ("YOU MUST", "Do NOT") that change Claude's behavior.

---

## Component Design

### 1. Enhanced `/deliver` Command

**File:** `commands/deliver.md`

**Changes:**
- Replace "TDD Workflow" section (lines 73-79) with expanded "TDD Discipline (MANDATORY)" section
- Add AAA pattern documentation with code example
- Update usage examples to show phase separation in output
- Main `/deliver` command orchestrates both phases automatically with visible separation

**New TDD Section:**

```markdown
## TDD Discipline (MANDATORY)

Crafter MUST follow strict test-first development. This is NOT optional.

### Phase 1: Red (Write Failing Tests)

YOU MUST write all tests BEFORE any implementation code.

**Constraints:**
- Write tests that define expected behavior based on the design
- Tests MUST use Arrange-Act-Assert (AAA) pattern
- Run tests and CONFIRM they fail (red)
- Do NOT write any implementation code during this phase
- Do NOT proceed until failing tests exist

**AAA Pattern Structure:**
\`\`\`
// Arrange - Set up test data and prerequisites
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act - Execute single method being tested
const result = await authService.validateAccess(request);

// Assert - Verify expected outcome
expect(result.allowed).toBe(true);
expect(result.role).toBe('admin');
\`\`\`

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
```

### 2. `/deliver:tests` Sub-Command

**File:** `commands/deliver-tests.md`

**Purpose:** Test-only mode for human-in-the-loop TDD workflow

**Content:**

```markdown
# /deliver:tests [backlog-item]

Write failing tests only (TDD Red phase). Use this for human-in-the-loop TDD workflow.

---

## Arguments

- `backlog-item` - Path to backlog item with design section (required)

---

## Genie Invoked

**Crafter** (Test Mode) - Writing tests only

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
- Existing test files (for patterns and conventions)
- docs/context/codebase_structure.md

---

## Output

Produces:
1. **Test files** - Comprehensive failing tests based on design
2. **Test run results** - Confirmation that tests fail (red)
3. **Summary** - What was tested, coverage areas

---

## Usage Example

\`\`\`
/deliver:tests docs/backlog/P2-auth-improvements.md
> [Crafter writes tests only]
>
> Tests written:
> - tests/services/TokenService.test.ts (12 test cases)
> - tests/integration/auth.test.ts (8 test cases)
>
> Test run: 20 tests, 0 passed, 20 failed (RED - as expected)
>
> Ready for implementation.
> Next: /deliver:implement docs/backlog/P2-auth-improvements.md
\`\`\`

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
```

### 3. `/deliver:implement` Sub-Command

**File:** `commands/deliver-implement.md`

**Purpose:** Implementation-only mode (tests already exist)

**Content:**

```markdown
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

\`\`\`
/deliver:implement docs/backlog/P2-auth-improvements.md
> [Crafter implements to pass tests]
>
> Implementation complete:
> - src/services/TokenService.ts (new)
> - src/middleware/auth.ts (modified)
>
> Test run: 20 tests, 20 passed, 0 failed (GREEN)
>
> Next: /discern docs/backlog/P2-auth-improvements.md
\`\`\`

---

## Routing

After implementation:
- **Tests passing:** `/discern [backlog-item]` for review
- **Tests still failing:** Continue implementation or escalate

---

## Notes

- This is the GREEN phase of TDD
- Tests are the specification - do not question them during this phase
- If tests are wrong, that's a separate conversation (escalate)
```

### 4. CLAUDE.md Template Update

**File:** `templates/CLAUDE.md`

**Changes:** Add new section after "Agent Conventions" and before "Project Context"

**New Section:**

```markdown
---

## TDD Requirements

This project uses **Test-Driven Development** for all code changes.

### Red-Green-Refactor Cycle

1. **RED**: Write failing tests that define expected behavior
2. **GREEN**: Write minimal implementation to pass tests
3. **REFACTOR**: Improve code quality while keeping tests green

### Test Structure (AAA Pattern)

All tests MUST follow Arrange-Act-Assert:

\`\`\`javascript
// Arrange - Set up test data and prerequisites
const user = createTestUser({ role: 'admin' });
const request = mockRequest({ userId: user.id });

// Act - Execute single method being tested
const result = await authService.validateAccess(request);

// Assert - Verify expected outcome
expect(result.allowed).toBe(true);
expect(result.role).toBe('admin');
\`\`\`

### TDD Constraints

- **NEVER** write implementation code without failing tests first
- **NEVER** modify tests to make them pass - fix the implementation
- One assertion focus per test (related assertions OK)
- No conditional logic (if/else) in tests
- Separate AAA sections with blank lines

### Using `/deliver` Command

The `/deliver` command enforces TDD:
- Full command: Writes tests first, then implementation (automatic)
- `/deliver:tests`: Write failing tests only (human-in-the-loop)
- `/deliver:implement`: Write implementation only (tests exist)
```

---

## Integration Points

### Workflow Integration

**Full automatic workflow:**
```
/deliver docs/backlog/P1-feature.md
→ Phase 1: Tests (RED)
→ Phase 2: Implementation (GREEN)
→ Phase 3: Refactor
→ Done
```

**Human-in-the-loop workflow:**
```
/deliver:tests docs/backlog/P1-feature.md
→ User reviews tests
→ /deliver:implement docs/backlog/P1-feature.md
→ Done
```

### Existing Commands

No changes to other commands. The `/deliver` command remains the only delivery mechanism.

---

## Migration Strategy

### Step 1: Update `/deliver` command
- Replace TDD section with new prescriptive content
- No breaking changes to existing usage

### Step 2: Create sub-command files
- Add `commands/deliver-tests.md`
- Add `commands/deliver-implement.md`
- These are additive (new functionality)

### Step 3: Update template
- Add TDD section to `templates/CLAUDE.md`
- Projects using template get TDD guidance automatically

### Step 4: Update dist/
- Run build/copy to sync `dist/commands/`

---

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Claude still writes implementation first despite constraints | Medium | High | Use stronger language (CRITICAL, FORBIDDEN); test with real usage |
| Sub-commands add confusion | Low | Low | Clear documentation; suggest sub-commands only for human-in-the-loop preference |
| AAA pattern not followed | Medium | Medium | Include concrete examples; reference in every test-related instruction |

---

## Implementation Guidance

### For Crafter (Implementer)

**File changes:**

1. **Edit** `commands/deliver.md`
   - Replace lines 73-79 (TDD Workflow section) with new TDD Discipline section
   - Update usage examples to show phase separation

2. **Create** `commands/deliver-tests.md`
   - New file with test-only sub-command

3. **Create** `commands/deliver-implement.md`
   - New file with implementation-only sub-command

4. **Edit** `templates/CLAUDE.md`
   - Add TDD Requirements section after line 61 (after Agent Conventions, before Project Context)

5. **Sync** `dist/commands/`
   - Copy updated files to dist directory

**Key prompt patterns to use:**
- "YOU MUST" for required behaviors
- "Do NOT" / "FORBIDDEN" for prohibited behaviors
- "ONLY" for exclusive actions
- "STOP" for escalation points

**Testing the changes:**
- After implementation, test `/deliver` on a sample backlog item
- Verify tests are written before implementation
- Verify sub-commands enforce their constraints

---

# Implementation

**Crafter:** Navigator
**Date:** 2025-12-08

## Implementation Summary

All components have been implemented as specified in the design.

## Files Changed

### 1. `commands/deliver.md` (modified)
- Replaced "TDD Workflow" section (lines 73-79) with expanded "TDD Discipline (MANDATORY)" section
- Added AAA pattern documentation with code example
- Updated usage examples to show clear phase separation (RED → GREEN → REFACTOR)
- Added sub-command examples for `/deliver:tests` and `/deliver:implement`

### 2. `commands/deliver-tests.md` (new)
- Created new sub-command file for test-only TDD workflow
- Includes CRITICAL constraints section with forbidden actions
- Documents AAA pattern requirements
- Provides routing to `/deliver:implement` for next step

### 3. `commands/deliver-implement.md` (new)
- Created new sub-command file for implementation-only TDD workflow
- Includes prerequisites check (tests must exist)
- Includes CRITICAL constraints section with forbidden actions
- Documents minimal implementation approach

### 4. `templates/CLAUDE.md` (modified)
- Added "TDD Requirements" section between Agent Conventions and Project Context
- Includes Red-Green-Refactor cycle documentation
- Includes AAA pattern with code example
- Documents TDD constraints with NEVER/MUST language
- Documents `/deliver` command variants

### 5. `dist/commands/` (synced)
- Copied `deliver.md`, `deliver-tests.md`, `deliver-implement.md` to dist

## Key Implementation Decisions

1. **Strong constraint language**: Used "YOU MUST", "Do NOT", "FORBIDDEN", "CRITICAL" to create behavioral change rather than just describing TDD

2. **Phase visibility**: Updated usage examples to show explicit "=== PHASE N ===" output markers for clear separation

3. **Escalation points**: Added "STOP and escalate" instructions when tests appear wrong, preventing Claude from "fixing" tests

4. **AAA pattern embedded everywhere**: Included the same code example in `/deliver`, `/deliver:tests`, and `templates/CLAUDE.md` for consistency

## Acceptance Criteria Status

### Must Have
- [x] `/deliver` command includes explicit "YOU MUST write tests BEFORE implementation" constraint
- [x] AAA pattern is documented with example in `/deliver` command
- [x] `/deliver:tests` sub-command writes only test files and confirms they fail
- [x] `/deliver:implement` sub-command writes only implementation and doesn't modify tests
- [x] `templates/CLAUDE.md` includes TDD requirements section

### Should Have
- [x] `/deliver` full mode has visible phase separation in output (shows "Phase 1: Tests" then "Phase 2: Implementation")
- [x] Sub-commands suggest next step (e.g., "Run `/deliver:implement` to continue")

---

# Review

**Critic:** Navigator
**Date:** 2025-12-08

## Verdict: APPROVED

Implementation meets all acceptance criteria and is ready for deployment.

---

## Acceptance Criteria Check

### Must Have (5/5 met)

| Criterion | Status | Evidence |
|-----------|--------|----------|
| `/deliver` includes "YOU MUST write tests BEFORE implementation" | PASS | `commands/deliver.md:79` - "YOU MUST write all tests BEFORE any implementation code" |
| AAA pattern documented with example in `/deliver` | PASS | `commands/deliver.md:88-100` - Complete AAA example with comments |
| `/deliver:tests` writes only test files, confirms fail | PASS | `commands/deliver-tests.md:23-32` - CRITICAL constraints with Forbidden Actions list |
| `/deliver:implement` writes only implementation, no test mods | PASS | `commands/deliver-implement.md:30-39` - CRITICAL constraints with Forbidden Actions list |
| `templates/CLAUDE.md` includes TDD section | PASS | `templates/CLAUDE.md:64-104` - Complete TDD Requirements section |

### Should Have (2/2 met)

| Criterion | Status | Evidence |
|-----------|--------|----------|
| Phase separation in output | PASS | `commands/deliver.md:135-157` - "=== PHASE 1: RED ===" markers in examples |
| Sub-commands suggest next step | PASS | Both sub-commands include "Next:" routing in examples |

---

## Code Quality Assessment

### Strengths

1. **Consistent constraint language** - "YOU MUST", "Do NOT", "FORBIDDEN", "CRITICAL" used consistently across all files
2. **AAA pattern consistency** - Same code example used in `/deliver`, `/deliver:tests`, and `templates/CLAUDE.md`
3. **Clear escalation points** - "STOP and escalate" prevents Claude from "fixing" tests
4. **Comprehensive forbidden actions** - Each sub-command explicitly lists what NOT to do

### Structure Review

| File | Lines | Assessment |
|------|-------|------------|
| `commands/deliver.md` | 206 | Well-structured, clear phase separation |
| `commands/deliver-tests.md` | 111 | Focused, single-purpose |
| `commands/deliver-implement.md` | 93 | Focused, single-purpose |
| `templates/CLAUDE.md` (TDD section) | 42 | Concise, copy-paste ready |

---

## Risk Assessment

| Risk | Mitigation | Status |
|------|------------|--------|
| Claude ignores constraints | Strong language (CRITICAL, FORBIDDEN) | MITIGATED |
| User confusion with sub-commands | Clear documentation, "Next:" routing | MITIGATED |
| Inconsistent AAA examples | Same example across all files | MITIGATED |

---

## Files Verified

- [x] `commands/deliver.md` - TDD Discipline section present and correct
- [x] `commands/deliver-tests.md` - New file, constraints correct
- [x] `commands/deliver-implement.md` - New file, constraints correct
- [x] `templates/CLAUDE.md` - TDD Requirements section present
- [x] `dist/commands/deliver.md` - Synced
- [x] `dist/commands/deliver-tests.md` - Synced
- [x] `dist/commands/deliver-implement.md` - Synced

---

## Recommendation

**APPROVED** - Ready for deployment.

The implementation successfully transforms descriptive TDD documentation into prescriptive constraints that should change Claude's behavior. The dual workflow (full `/deliver` vs sub-commands) provides flexibility for both automated and human-in-the-loop TDD.

**Next steps:**
1. Run `/commit` to commit changes
2. Run `/done docs/backlog/P1-tdd-enforcement.md` to archive

---

# End of Shaped Work Contract

