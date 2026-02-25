---
id: P2-spec-aware-test-generation
title: Spec-Aware Test Generation Factory for Crafter RED Phase
type: feature
status: implemented
priority: P2
appetite: medium
spec_ref: docs/specs/genies/spec-aware-test-generation.md
adr_refs: []
created: 2026-02-25
discovery_ref: docs/analysis/20260225_discover_ai_pdlc_trends.md
---

# Shaped Work Contract: Spec-Aware Test Generation Factory for Crafter RED Phase

## Problem

When Crafter begins the TDD RED phase, it reads the spec's `acceptance_criteria` frontmatter and writes failing tests manually — one by one, from memory of the ACs it just read, without any structured mapping between AC ids and test cases.

The problem is not that tests are written badly. The problem is that the mapping from spec ACs to test stubs is invisible, manual, and easy to miss. In practice:

1. **AC coverage is accidental.** When a spec has AC-1 through AC-6, Crafter writes tests in whatever order it processes the ACs. There is no artifact confirming "every AC has at least one test stub." Coverage gaps are discovered later (in Critic review or in failing /discern verdicts), not at the beginning of the RED phase when they are cheapest to fix.

2. **The spec already contains everything needed.** Each AC has an `id`, a `description`, and an implicit test contract (the description describes a behavior that can be directly inverted into a test name and stub). Crafter is not mining this structure — it is re-reading prose and re-deriving test names from scratch.

3. **RED phase time scales with AC count, not complexity.** Writing 8 test stubs manually for a spec with 8 ACs takes roughly the same wall time regardless of whether those ACs are trivially simple or genuinely complex. If the stub-writing step were automated, Crafter's attention could focus entirely on the genuinely novel parts: edge cases, interaction effects, and complex setup.

4. **Spec drift is hard to catch.** When ACs are added or changed between shaping and delivery, Crafter has no structural way to detect that the test file no longer mirrors the spec. A factory that generates stubs from the spec's current AC list would make spec-test divergence visible immediately.

**Who is affected:** Crafter during every /deliver or /deliver:tests invocation that uses a spec with defined ACs. The problem is larger when AC count is high (6+) or when the spec has recently been updated.

**Evidence from discovery:** Discovery doc section 2.5 identifies "test generation from specs + design documents as emerging best practice." Section 7 names "Spec-First Test Generation" as opportunity area #1. The spec-awareness skill already loads AC ids and descriptions into the context — the data is there, the factory is not.

## Appetite & Boundaries

- **Appetite:** Medium batch (3-5 days)
- **No-gos:**
  - Do NOT generate implementation code (this is test stub generation only — RED phase, not GREEN)
  - Do NOT change the Execution Report schema or format
  - Do NOT generate tests for specs without `acceptance_criteria` frontmatter (graceful skip)
  - Do NOT require an external tool, API call, or new dependency — this is a prompt engineering change
  - Do NOT modify the test structure convention (AAA pattern stays; stubs are pre-filled AAA skeletons)
  - Do NOT auto-run tests (Crafter still runs the test suite to confirm RED state)
- **Fixed elements:**
  - Each test stub must reference its source AC id (e.g., `# ac_id: AC-3` comment in the stub)
  - Stubs must be failing by design — they are not implementations; the Act and Assert sections contain `TODO` markers or `fail("not implemented")` equivalents
  - The existing `/deliver:tests` command is enhanced, not replaced
  - AAA pattern (Arrange-Act-Assert with blank line separators) is preserved in all stubs

## Goals & Outcomes

- When Crafter begins the RED phase for a spec with defined ACs, it produces a test file where every AC has at least one named, linked test stub — before writing a single line of implementation
- The mapping from spec AC to test stub is explicit and traceable (ac_id comment in each test)
- Crafter's attention during RED phase shifts from "write boilerplate stub structure" to "review the generated stubs for coverage gaps and add edge-case tests"
- A navigator reviewing a test file can trace every test back to the spec AC it covers
- When the spec changes (ACs added/updated), Crafter can regenerate stubs for new ACs without touching existing ones

## Behavioral Delta Against Existing Specs

**Affected spec:** `docs/specs/genies/crafter-implementation.md`

**Current Behavior (AC-3):**
> /deliver:tests writes failing tests only (TDD RED phase); /deliver:implement writes implementation only when tests already exist (TDD GREEN phase). Tests use the AAA pattern with blank line separators, one assertion focus per test, and no conditional logic.

**Proposed Change to AC-3:**
> AC-3 updated to add: Before writing any test, Crafter performs a spec-to-stub mapping pass — for each AC in the spec's acceptance_criteria frontmatter, it generates a named test stub with ac_id comment, AAA skeleton with TODO markers in Act and Assert sections, and a failing assertion. After the mapping pass, Crafter adds edge-case and interaction-effect tests beyond the AC-direct stubs. All stubs are written before any implementation begins.

**Current Behavior (AC-4):**
> Crafter operates in headless mode without interactive prompts, reading spec and design from file paths, parsing acceptance_criteria from spec frontmatter.

**Proposed Change to AC-4:**
> AC-4 updated to clarify: In headless mode, the spec-to-stub mapping pass is automatic (no interactive prompts). If a spec has no acceptance_criteria, Crafter logs a warning and proceeds with manual test writing (existing behavior). The stub mapping pass is a preamble to the RED phase, not a replacement of it.

**New AC for Crafter spec:**
> AC-5: Crafter produces a spec-to-stub coverage table at the end of the RED phase listing each AC id, test stub name(s) covering it, and coverage status (direct/edge-case/missing)

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Spec ACs are written with enough specificity to generate meaningful stub names | value | Sample 5 existing specs and evaluate whether AC descriptions naturally yield test names |
| Generating stubs first (vs. integrated writing) doesn't conflict with Crafter's reasoning flow | feasibility | Prototype the stub-generation step as a prompt instruction; verify output quality vs. manual writing |
| The ac_id comment convention doesn't conflict with existing test frameworks (jest, pytest, bats) | feasibility | Review test framework comment handling; ensure `# ac_id: AC-1` is valid syntax in target languages |
| Edge-case tests beyond AC stubs are still written (stub generation doesn't crowd out creative testing) | value | Instruction design: "after completing stubs for all ACs, add at least one edge-case test per AC" |
| Specs with many ACs (8+) don't produce overwhelming stub files before implementation | usability | Cap stub generation: if AC count > 10, prompt Crafter to group related ACs into shared test suites |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Prompt instruction in agents/crafter.md (spec-to-stub pass first) | Pure prompt engineering; no new files; fits existing architecture | Instruction must be precise or Crafter may skip the pass when busy | Recommended — aligns with prompt-engineering-only constraint |
| B: New skill: `test-generation` | Encapsulated, reusable, clean separation | Adds a new skill file; slightly more surface area; skills are for cross-cutting behavior, not genie-specific logic | Avoid — test generation is Crafter-specific, not cross-cutting |
| C: New command: `/deliver:stubs` | Explicit step, user-visible | Adds workflow step; users must know to call it; fragments the RED phase | Avoid — should be integrated into /deliver:tests, not a new command |
| D: Enhance spec-awareness skill to inject stub templates during /deliver | Spec-awareness already loads ACs; natural extension | Spec-awareness is read-focused; writing stubs is Crafter's job, not the skill's | Avoid — wrong layer |

**Recommendation:** Option A. The change is a prompt instruction in `agents/crafter.md` adding an explicit "spec-to-stub mapping pass" before the open-ended test writing phase. Minimal surface area, correct ownership, prompt-engineering-only.

## Acceptance Criteria

- id: AC-1
  description: >-
    When /deliver:tests is invoked with a spec that has acceptance_criteria
    frontmatter, Crafter performs a spec-to-stub mapping pass before any
    other test writing — producing one failing test stub per AC minimum
  status: pending

- id: AC-2
  description: >-
    Each generated stub includes an ac_id comment (e.g., # ac_id: AC-3) linking
    the test to its source acceptance criterion
  status: pending

- id: AC-3
  description: >-
    Each generated stub follows the AAA pattern with a TODO marker in the
    Act section and a failing assertion (e.g., fail("not implemented"),
    assert False, or equivalent) in the Assert section
  status: pending

- id: AC-4
  description: >-
    After the spec-to-stub mapping pass, Crafter adds edge-case tests beyond
    the direct AC stubs; the final test file contains more tests than ACs
  status: pending

- id: AC-5
  description: >-
    At the end of RED phase, Crafter outputs a coverage table mapping each
    AC id to its test stub name(s) and coverage type (direct / edge-case)
  status: pending

- id: AC-6
  description: >-
    When a spec has no acceptance_criteria frontmatter, Crafter logs a warning
    ("no ACs found; proceeding with manual test writing") and continues with
    existing RED phase behavior — no regression
  status: pending

- id: AC-7
  description: >-
    The spec-to-stub behavior is documented in agents/crafter.md under the
    TDD Cycle section so Crafter follows it consistently across all invocations
  status: pending

## Routing

- **Next genie:** Crafter — this is a prompt engineering change (edit to `agents/crafter.md` + possibly the tdd-discipline skill). No Architect spike needed; feasibility is clear.
- **Crafter scope:** Edit `agents/crafter.md` TDD Cycle section to add the spec-to-stub mapping pass instruction; verify with a sample run against an existing spec
- **After Crafter:** Critic to review whether generated stubs meet the AAA convention and ac_id linking requirement

---

# Design

## Design Summary

A single targeted edit to `agents/crafter.md` — specifically to the TDD Cycle section — adds a "Spec-to-Stub Mapping Pass" as a mandatory first step of the RED phase when a spec with `acceptance_criteria` is present. The pass is a structured loop: for each AC in the spec frontmatter, Crafter generates one named, failing test stub with an `ac_id` comment linking it to the source AC. After the pass, Crafter continues with the existing RED phase behavior (edge-case tests). The pass ends with a coverage table. No new files, no new commands, no changes to the `tdd-discipline` skill or `commands/deliver.md`.

The shaped work contract evaluated four options (A through D) and selected Option A: prompt instruction in `agents/crafter.md`. This design implements that decision.

## Architecture

```
agents/crafter.md
  └── ## TDD Cycle (Mandatory)
        └── Phase 1: RED
              [NEW] Spec-to-Stub Mapping Pass (before existing test writing)
              │
              ├── For each AC in spec.acceptance_criteria:
              │     → emit one stub with # ac_id: AC-N comment
              │     → AAA skeleton: Arrange (TODO), Act (TODO), Assert (fail)
              │
              └── [EXISTING] Edge-case tests (after all stubs written)
              └── [NEW] Coverage table at end of RED phase
```

The `/deliver` command (`commands/deliver.md`) already contains the Phase 1: Red section with spec-driven test targets. That section instructs Crafter to use spec ACs as targets. The new mapping pass is a structural addition *within* the RED phase — it precedes the existing free-form test writing, not replaces it.

The `skills/tdd-discipline/SKILL.md` skill describes the RED-GREEN-REFACTOR cycle at a general level. It does NOT need changes: the mapping pass is Crafter-specific behavior (the shaped work contract explicitly rejected adding this to a skill because test generation is Crafter's job, not a cross-cutting behavior).

The `commands/deliver.md` file already has a "Phase 1: Red" section that mentions spec-driven test targets. No changes needed there — the source of truth for Crafter's TDD behavior is `agents/crafter.md`, and the command defers to the agent.

## Component Design

| Component | Action | File | What Changes |
|-----------|--------|------|--------------|
| CrafterTDDCycle | modify | `agents/crafter.md` | Add Spec-to-Stub Mapping Pass sub-section within existing RED phase |
| CrafterHeadless | modify | `agents/crafter.md` | Add explicit note that mapping pass is automatic in headless mode |
| tdd-discipline skill | no change | `skills/tdd-discipline/SKILL.md` | Not modified — mapping is Crafter-specific |
| deliver command | no change | `commands/deliver.md` | Not modified — command defers to agent |

## AC Mapping

| AC | Approach | Components |
|----|----------|------------|
| AC-1 | Spec-to-Stub Mapping Pass is the first sub-step of RED phase in `agents/crafter.md`; produces one stub per AC before other tests | `agents/crafter.md` |
| AC-2 | Each stub in the mapping pass includes `# ac_id: AC-N` comment — instruction is explicit in the mapping pass loop | `agents/crafter.md` |
| AC-3 | Stub template specifies AAA skeleton: Arrange/Act with `# TODO: implement` markers, Assert with language-appropriate failing assertion | `agents/crafter.md` |
| AC-4 | After mapping pass completes, Crafter proceeds to existing open-ended test writing (edge cases, interactions) — explicit "then add edge-case tests" instruction ensures total test count exceeds AC count | `agents/crafter.md` |
| AC-5 | Coverage table instruction added as the closing step of the RED phase section — Crafter emits table before transitioning to GREEN | `agents/crafter.md` |
| AC-6 | Guard clause at top of mapping pass: "If spec has no acceptance_criteria frontmatter, log warning and proceed to manual test writing" — existing behavior unchanged | `agents/crafter.md` |
| AC-7 | The mapping pass lives in `agents/crafter.md` under the TDD Cycle section, making it part of Crafter's governing instruction set for all invocations | `agents/crafter.md` |

## Interfaces

### Spec-to-Stub Mapping Pass

The mapping pass is added as a named sub-section within the existing `### Phase 1: RED` section in `agents/crafter.md`. It follows the existing structure pattern (numbered constraints with code examples).

**Pass algorithm (prose description for Crafter's instruction):**

```
Before writing any free-form tests, perform the spec-to-stub mapping pass:

1. Guard: Check if the loaded spec has acceptance_criteria in frontmatter.
   - If NO acceptance_criteria: Log "No ACs found; proceeding with manual test writing" and skip to free-form tests.
   - If YES: Proceed with the mapping pass.

2. For each acceptance criterion in spec.acceptance_criteria (in order):
   a. Derive the test name from the AC description:
      - Pattern: "{AC-id}: {behavior phrase from AC description}"
      - Example: AC-1 "Scout uses model: sonnet" → test name: "AC-1: Scout agent uses sonnet model"
   b. Write one failing test stub:
      - First line: ac_id comment (e.g., # ac_id: AC-1  or  // ac_id: AC-1)
      - Arrange section: # TODO: set up test data relevant to this AC
      - Act section: # TODO: invoke the behavior under test
      - Assert section: language-appropriate failing assertion
        - Python: assert False, "AC-1 not yet implemented"
        - JavaScript/TypeScript: fail("AC-1 not yet implemented") or expect(false).toBe(true)
        - Bash/bats: false  # AC-1 not yet implemented
        - Go: t.Fatal("AC-1 not yet implemented")

3. After all AC stubs are written, continue with edge-case tests (existing behavior).
   Instruction: "For each AC stub, add at least one edge-case or boundary test that is not directly stated in the AC description."

4. At the end of RED phase, before running tests, output the coverage table:

| AC | Test Name(s) | Coverage Type |
|----|-------------|---------------|
| AC-1 | "AC-1: Scout uses sonnet model" | direct |
| AC-1 | "AC-1 edge: model field with whitespace" | edge-case |
| AC-2 | "AC-2: Deep Reasoning section present" | direct |
...
```

### `ac_id` Comment Syntax by Framework

The comment format adapts to the target test framework's comment syntax:

| Framework | ac_id comment syntax |
|-----------|---------------------|
| Python (pytest) | `# ac_id: AC-1` |
| JavaScript (jest) | `// ac_id: AC-1` |
| TypeScript (jest/vitest) | `// ac_id: AC-1` |
| Bash (bats) | `# ac_id: AC-1` |
| Go (testing) | `// ac_id: AC-1` |
| Ruby (rspec) | `# ac_id: AC-1` |

The comment is placed as the first line inside the test function/block, before Arrange.

### Coverage Table Format

The table is emitted as markdown in Crafter's output (not written to a file — it is part of the execution narration, visible in the Execution Report's Summary section):

```markdown
## Spec-to-Stub Coverage Table
| AC | Test Stub Name(s) | Coverage Type |
|----|-----------------|---------------|
| AC-1 | AC-1: {behavior} | direct |
| AC-1 | AC-1 edge: {boundary} | edge-case |
| AC-2 | AC-2: {behavior} | direct |
```

"Missing" coverage type is used if an AC was not stubbed (should not happen in normal operation, but guards against skip errors).

### Large Spec Guard (>10 ACs)

Per shaped contract risk assumption: if `acceptance_criteria` count exceeds 10, Crafter groups related ACs into shared test suites (describe/class blocks) rather than individual top-level functions. Instruction: "If AC count > 10, group ACs by theme into describe blocks (e.g., 'Model Configuration', 'Output Format') and write stubs within those blocks."

## Pattern Adherence

- **Constraint pattern:** The mapping pass instruction follows the existing constraint pattern in `agents/crafter.md` — numbered rules with code examples showing the target syntax.
- **Headless mode pattern:** The existing Headless Execution Mode section already says "Tag each test with `ac_id` linking it to the acceptance criterion it verifies." This is an existing weak convention; the mapping pass formalizes it. The `agents/crafter.md` Headless section adds one sentence: "The spec-to-stub mapping pass is automatic — no prompts issued; warnings go to execution narration."
- **AAA pattern:** Existing pattern (already mandated by `tdd-discipline` skill and `agents/crafter.md`). The stub template is a pre-filled AAA skeleton, not a deviation from it.
- **No new file pattern:** Consistent with P1 and the project's prompt-engineering-only constraint. One file, one section, additive changes.

No deviations from established patterns.

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Generated stub names are generic/unhelpful if AC descriptions are vague | M | L | Instruction emphasizes deriving test name from AC description's behavior phrase; Critic verifies stub name quality |
| Crafter skips edge-case tests after mapping pass (satisfied by stubs alone) | M | M | Explicit "add at least one edge-case test per AC" instruction after the mapping pass loop |
| Coverage table is emitted to wrong location (file vs. stdout) | L | L | Instruction specifies table is part of execution narration, not a file write |
| `ac_id` comment conflicts with linting rules (e.g., "no arbitrary comments" rule) | L | L | `ac_id` follows standard comment syntax for each language; unlikely to trigger linters |
| Specs with >10 ACs produce excessively large stub files before implementation | L | M | Grouping instruction at >10 ACs mitigates stub file bloat |

Rollback: Single additive edit to `agents/crafter.md`. If the mapping pass degrades output quality, remove the Spec-to-Stub Mapping Pass sub-section — all other Crafter behavior is unchanged.

## Implementation Guidance

**Sequence for Crafter (single file, ordered within the file):**

1. **`agents/crafter.md` — Spec-to-Stub Mapping Pass sub-section**
   - Location: Within the existing `### TDD Cycle (Mandatory)` section, inside `Phase 1: RED`
   - Add as the FIRST sub-step of RED phase, before the existing "Write tests that define expected behavior" constraint
   - Sub-section title: `#### Spec-to-Stub Mapping Pass (RED Phase Preamble)`
   - Content: Guard clause, mapping loop, edge-case instruction (see Interfaces above)

2. **`agents/crafter.md` — Coverage table instruction**
   - Location: End of the `Phase 1: RED` section (after edge-case test instruction, before Phase 2)
   - Instruction: "After writing all stubs and edge-case tests, output the Spec-to-Stub Coverage Table listing each AC, its test stub name(s), and coverage type (direct/edge-case/missing)"

3. **`agents/crafter.md` — Headless mode clarification**
   - Location: The existing `## Headless Execution Mode` section
   - Add one sentence to the existing bullet list: "The spec-to-stub mapping pass is automatic in headless mode — warnings are included in execution narration, not issued as interactive prompts"

**Test scenarios for Critic:**
- `/deliver:tests` on a spec with 3 ACs produces at least 3+3=6 tests (3 direct stubs + at least 3 edge-case tests)
- Each test stub has an `ac_id` comment as the first line inside the test body
- The coverage table appears in Crafter's output narration after all stubs are written
- `/deliver:tests` on a spec with NO `acceptance_criteria` produces a warning line and proceeds to manual test writing
- Test stub names follow the pattern "AC-N: {behavior phrase}" derived from the AC description

**Note:** This is a prompt engineering change. "Testing" in this context means running `/deliver:tests` against a real spec with defined ACs and verifying Crafter's output meets the AC requirements. The `tests/test_execute.sh` suite tests command invocation patterns; Critic verifies output quality.

## Routing

Ready for Crafter. Option A is selected (prompt instruction in `agents/crafter.md`). Implementation is a single file, three targeted additions (mapping pass sub-section, coverage table instruction, headless mode note). All decisions are made — no ADR needed (no architectural alternatives with lasting consequences).

# Implementation

## Summary

Implemented the spec-to-stub mapping pass as three targeted additions to `agents/crafter.md`, following Option A from the shaped work contract. No new files, commands, or skills were created.

## Changes

### 1. `agents/crafter.md` — Spec-to-Stub Mapping Pass (lines 55–104)

Added `#### Spec-to-Stub Mapping Pass (RED Phase Preamble)` sub-section within the existing TDD Cycle section, as the first sub-step of Phase 1: RED. Contains:

- **Guard clause** (AC-6): When no `acceptance_criteria` in spec, logs "No ACs found; proceeding with manual test writing" and skips to existing behavior
- **Mapping loop** (AC-1, AC-2, AC-3): For each AC, generates a named failing test stub with `ac_id` comment as first line, AAA skeleton with TODO markers in Arrange/Act, and language-appropriate failing assertion in Assert
- **`ac_id` syntax table** (AC-2): Documents comment syntax for Python, JavaScript, TypeScript, Bash, Go, and Ruby
- **Edge-case instruction** (AC-4): After all AC stubs, add at least one edge-case test per AC; final test count MUST exceed AC count
- **Large spec guard** (AC-1 edge): When AC count exceeds 10, group into describe/class blocks by theme
- **Coverage table instruction** (AC-5): Output Spec-to-Stub Coverage Table at end of RED phase with AC, test stub names, and coverage type (direct/edge-case/missing)

### 2. `agents/crafter.md` — Headless Mode Clarification (line 223)

Added one bullet to Headless constraints: "In headless mode, the spec-to-stub mapping pass is automatic — warnings are included in execution narration, not issued as interactive prompts"

### 3. `tests/test_spec_aware_stubs.sh` (new file)

36 tests covering all 7 ACs plus edge cases. Tests validate the content of `agents/crafter.md` to ensure all required instructions are present and correctly structured.

## Decisions

- **No changes to `commands/deliver.md`**: The command already defers TDD behavior to the agent. The design explicitly ruled this out.
- **No changes to `skills/tdd-discipline/SKILL.md`**: The mapping pass is Crafter-specific, not cross-cutting. The shaped contract explicitly rejected adding this to a skill.
- **Test strategy**: Content-based validation of `agents/crafter.md` using bash grep patterns, matching the existing test infrastructure pattern (`tests/test_execute.sh`).

## Test Results

- `tests/test_spec_aware_stubs.sh`: 36 tests, 36 passed, 0 failed
- `tests/test_execute.sh`: 62 tests, 62 passed, 0 failed (no regression)
