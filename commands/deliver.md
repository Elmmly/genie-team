# /deliver [design-doc]

Activate Crafter genie to implement the technical design with TDD discipline.

---

## Arguments

- `design-doc` - Path to design document (required)
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
- docs/analysis/YYYYMMDD_design_{topic}.md
- Target code files
- Related test files
- docs/context/codebase_structure.md

**RECALL:**
- Similar implementations in codebase
- Related test patterns

---

## Context Writing

**WRITE:**
- Code changes
- Test files
- Implementation report (inline or separate)

**UPDATE:**
- docs/backlog/{priority}-{topic}.md (progress notes)

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

## TDD Workflow

Crafter follows strict TDD:
1. Red - Write failing test
2. Green - Minimal code to pass
3. Refactor - Clean up while green

---

## Usage Examples

```
/deliver docs/analysis/20251203_design_auth.md
> [Crafter implements with TDD]
>
> Implementation complete:
> - src/services/TokenService.ts (new)
> - src/middleware/auth.ts (modified)
> - src/controllers/RefreshController.ts (new)
>
> Tests:
> - tests/services/TokenService.test.ts
> - tests/integration/auth.test.ts
>
> All tests passing: 47 pass, 0 fail
>
> Next: /handoff deliver discern

/deliver:tests docs/analysis/20251203_design_auth.md
> Test scaffolding complete
> 12 test cases written (all failing - ready for implementation)
> Next: /deliver:implement
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
