---
type: cleanup
concept: {concept}
enhancement: {enhancement}
status: active
created: {YYYY-MM-DD}
---

# Cleanup Report — Tidier Genie
### Structured Markdown Output Template

> This template documents cleanup work done by Tidier.
> Include all sections. Update defrag-progress.md alongside.
>
> **Frontmatter:** Replace `{concept}`, `{enhancement}`, and `{YYYY-MM-DD}` with actual values.

---

## 1. Cleanup Summary
[What was cleaned - high level]
[Overall progress status]

**Input:** [Diagnose Report reference]
**Status:** [Complete / In Progress / Blocked]
**Batches completed:** [N of M]

---

## 2. Pre-Cleanup Verification

### Test Status Before Starting
| Test Suite | Status | Notes |
|------------|--------|-------|
| Unit tests | ✅ Pass | Ready to proceed |
| Integration | ✅ Pass | Ready to proceed |

**Cleared to proceed:** [Yes / No - reason]

---

## 3. Batches Executed

### Batch 1: [Description]
**Scope:** [What this batch addresses]
**Status:** ✅ Complete / ❌ Failed / ⏸ Stopped

| Change | File | Type | Lines |
|--------|------|------|-------|
| [What changed] | `path/file.py` | Remove/Refactor/Rename | +N/-M |

**Tests after batch:** ✅ All pass / ❌ [Failure details]

---

### Batch 2: [Description]
**Scope:** [What this batch addresses]
**Status:** ✅ Complete / ❌ Failed / ⏸ Stopped

| Change | File | Type | Lines |
|--------|------|------|-------|
| [What changed] | `path/file.py` | Remove/Refactor/Rename | +N/-M |

**Tests after batch:** ✅ All pass / ❌ [Failure details]

---

### Batch N: [Continue as needed]
...

---

## 4. Changes Summary

### Dead Code Removed
| File | Removed | Reason | Lines |
|------|---------|--------|-------|
| `file.py` | `unused_function()` | Never called | -25 |
| `file.py` | `DEAD_CONSTANT` | No references | -3 |

### Code Refactored
| File | Before | After | Reason |
|------|--------|-------|--------|
| `file.py` | `old_name()` | `better_name()` | Clarity |
| `module/` | [Structure] | [New structure] | Organization |

### Imports Cleaned
| File | Removed Imports |
|------|-----------------|
| `file.py` | `unused_module`, `old_dep` |

### Dependencies Updated
| Dependency | Action | Reason |
|------------|--------|--------|
| `old-package` | Removed | Unused |

---

## 5. Verification Summary

### Final Test Status
| Test Suite | Before | After | Status |
|------------|--------|-------|--------|
| Unit tests | ✅ Pass | ✅ Pass | ✅ Good |
| Integration | ✅ Pass | ✅ Pass | ✅ Good |

### Behavior Verification
- [x] No behavioral changes (refactor only)
- [x] All tests still pass
- [x] No new warnings introduced
- [x] Linting passes

---

## 6. Progress Against Diagnose Report

### Completed Items
| Item | Batch | Notes |
|------|-------|-------|
| [Item from diagnose] | Batch 1 | ✅ Done |
| [Item from diagnose] | Batch 2 | ✅ Done |

### Remaining Items
| Item | Priority | Next Batch |
|------|----------|------------|
| [Item from diagnose] | High | Batch N+1 |
| [Item from diagnose] | Medium | Batch N+2 |

### Blocked Items
| Item | Blocker | Resolution |
|------|---------|------------|
| [Item] | [Why blocked] | [What would unblock] |

---

## 7. Findings During Cleanup

### New Issues Discovered
| Finding | Severity | Recommendation |
|---------|----------|----------------|
| [Found during cleanup] | Low/Med/High | [Log for future] |

### Tech Debt for Future
| Debt Item | Priority | Notes |
|-----------|----------|-------|
| [New debt found] | P2 | Add to next diagnose |

---

## 8. Metrics

### Lines Changed
- **Added:** +N lines
- **Removed:** -M lines
- **Net:** [+/-] K lines

### Files Touched
- **Modified:** X files
- **Deleted:** Y files

### Test Coverage Impact
- **Before:** N%
- **After:** M%
- **Change:** [+/-] K%

---

## 9. Next Steps

### If Continuing
- [ ] Batch N+1: [Description]
- [ ] Batch N+2: [Description]

### If Complete
- [x] All diagnose items addressed
- [ ] Update defrag-progress.md to complete
- [ ] Notify Navigator

### If Blocked
- [ ] Document blocker
- [ ] Escalate to: [Architect/Navigator]

---

## 10. Routing

**Current status routing:**

If **Complete:**
- [ ] Mark cleanup complete in defrag-progress.md
- [ ] Notify Navigator
- [ ] Archive diagnose report

If **In Progress:**
- [ ] Update defrag-progress.md
- [ ] Continue with next session

If **Blocked:**
- [ ] Document in defrag-progress.md
- [ ] Escalate to: [Who]

---

## 11. Artifacts

- **Report saved to:** `docs/cleanup/YYYYMMDD_cleanup_{area}.md`
- **Progress file:** `docs/cleanup/defrag-progress.md` [Updated]
- **Code changes:** [Branch/commit reference]

---

# End of Cleanup Report
