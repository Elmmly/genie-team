# /tidy [diagnose-report]

Activate Tidier genie to execute cleanup in safe, tested batches.

---

## Arguments

- `diagnose-report` - Path to diagnose report (required)
- Optional flags:
  - `--batch N` - Execute only batch N
  - `--dry-run` - Show what would change without changing

---

## Agent Identity

Read and internalize `.claude/agents/tidier.md` for your identity, charter, and judgment rules.

---

## Context Loading

**READ (automatic):**
- Diagnose report
- Target code files
- Test files
- docs/cleanup/defrag-progress.md

---

## Context Writing

**WRITE:**
- docs/cleanup/YYYYMMDD_cleanup_{area}.md

**UPDATE:**
- docs/cleanup/defrag-progress.md
- Code files (cleanup changes)

---

## Output

Produces a **Cleanup Report** containing:
1. Cleanup Summary - What was cleaned
2. Batches Executed - Each batch with results
3. Changes Made - Detailed change list
4. Verification - Test results
5. Progress Tracking - Items completed vs remaining

---

## Safety Protocol

Tidier follows strict safety rules:
1. Verify tests pass BEFORE starting
2. Execute in small batches
3. Run tests AFTER each batch
4. STOP immediately on test failure
5. Never change behavior (refactor only)

---

## Usage Examples

```
/tidy docs/cleanup/20251203_diagnose_full.md
> [Tidier executes cleanup in batches]
>
> Pre-check: All tests passing
>
> Batch 1: Remove dead code
> - Removed unused_function() from utils.ts
> - Removed DEAD_CONSTANT from config.ts
> Tests: Pass
>
> Batch 2: Clean imports
> - Removed 3 unused imports from services/
> Tests: Pass
>
> Progress: 2/5 batches complete
> Saved to docs/cleanup/20251203_cleanup_full.md
>
> Continue with /tidy --batch 3

/tidy --dry-run docs/cleanup/20251203_diagnose_full.md
> Dry run - no changes made
>
> Would execute:
> - Batch 1: Remove 2 dead functions (-45 lines)
> - Batch 2: Clean 3 imports
> - Batch 3: Rename inconsistent functions
```

---

## Batch Strategy

| Batch Type | Risk | Approach |
|------------|------|----------|
| Dead code removal | Low | Multiple in one batch |
| Import cleanup | Low | Multiple in one batch |
| Rename refactors | Medium | One at a time |
| Structural changes | High | Very carefully, one at a time |

---

## Routing

During cleanup:
- **Tests pass**: Continue to next batch
- **Tests fail**: Stop, report, escalate
- **Blocked**: Document and escalate to Architect

After cleanup:
- **Complete**: Update defrag-progress.md, notify Navigator
- **In progress**: Continue in next session

---

## Notes

- NEVER changes behavior
- Test-gated progress only
- Safe to stop and resume
- Creates audit trail of changes
- Scope discipline - only what's in diagnose report
