# Implementation Report — Crafter Genie
### Structured Markdown Output Template

> This template documents the implementation work done by Crafter.
> Include all sections. Mark as "N/A" if not applicable.

---

## 1. Implementation Summary
[What was built - 2-3 sentences]
[Key decisions made during implementation]

**Design reference:** [Link to Design Document]
**Status:** [Complete / Partial / Blocked]
**Scope adherence:** [On scope / Minor deviation / Scope question]

---

## 2. Test Cases

### Unit Tests
| Test | Description | Status |
|------|-------------|--------|
| `test_name_1` | [What it verifies] | ✅ Pass |
| `test_name_2` | [What it verifies] | ✅ Pass |

### Integration Tests
| Test | Description | Status |
|------|-------------|--------|
| `test_integration_1` | [What it verifies] | ✅ Pass |

### Test Coverage
- **Target:** [From design]
- **Achieved:** [Actual percentage]
- **Gaps:** [What's not covered and why]

### Test Commands
```bash
# Run all tests
pytest path/to/tests/

# Run specific test
pytest path/to/tests/test_file.py::test_name
```

---

## 3. Code Changes

### Files Created
| File | Purpose | Lines |
|------|---------|-------|
| `path/to/new_file.py` | [What it does] | ~N |
| `path/to/test_new_file.py` | [Tests for above] | ~N |

### Files Modified
| File | Changes | Lines Changed |
|------|---------|---------------|
| `path/to/existing.py` | [What changed] | +N/-M |

### Dependencies Added
| Dependency | Version | Reason |
|------------|---------|--------|
| [package] | [version] | [Why needed] |

---

## 4. Key Implementation Details

### Approach
[Brief description of implementation approach]

### Notable Decisions
- **[Decision 1]:** [What and why]
- **[Decision 2]:** [What and why]

### Code Snippets (if helpful)
```python
# Key implementation pattern used
def example_function():
    pass
```

---

## 5. Pattern Adherence

### Conventions Followed
- [x] No hardcoded values (used config/registry)
- [x] Type hints on public methods
- [x] Docstrings for public functions
- [x] Consistent naming conventions
- [x] Error handling in place
- [x] Logging added

### Patterns Used
- **[Pattern]:** [How it was applied]

### Deviations
| Deviation | Reason | Flagged? |
|-----------|--------|----------|
| [What] | [Why necessary] | Yes/No |

---

## 6. Error Handling

### Errors Handled
| Error Scenario | Handling | Test Coverage |
|----------------|----------|---------------|
| [Scenario 1] | [How handled] | ✅ |
| [Scenario 2] | [How handled] | ✅ |

### Error Messages
- All error messages include: [context provided]
- Logging level: [ERROR/WARNING as appropriate]

---

## 7. Edge Cases

| Edge Case | Handling | Test |
|-----------|----------|------|
| [Case 1] | [Behavior] | `test_edge_case_1` |
| [Case 2] | [Behavior] | `test_edge_case_2` |

---

## 8. Instrumentation & Telemetry

### Logging Added
| Log Point | Level | Payload |
|-----------|-------|---------|
| [Where] | INFO/DEBUG/etc | [What's logged] |

### Metrics Added
| Metric | Type | Description |
|--------|------|-------------|
| [Name] | counter/gauge/histogram | [What it measures] |

---

## 9. Quality Checklist

- [ ] All tests written and passing
- [ ] Type hints on public methods
- [ ] No hardcoded values
- [ ] Error handling complete
- [ ] Edge cases covered
- [ ] Telemetry/logging instrumented
- [ ] Non-obvious code documented
- [ ] Linting passes
- [ ] Security considerations addressed
- [ ] Design boundaries respected

---

## 10. Open Items

### Blockers
| Blocker | Impact | Escalation |
|---------|--------|------------|
| [Issue] | [Impact] | [Who to escalate to] |

### Questions for Critic
- [Question 1]
- [Question 2]

### Future Considerations (Out of Scope)
- [Thing noticed but not addressed - per scope discipline]

---

## 11. Handoff to Critic

**Ready for review:** [Yes / No]

If No, reason: [What's blocking]

**Review focus areas:**
- [Area 1 to pay attention to]
- [Area 2 to pay attention to]

**How to test:**
```bash
# Steps to verify the implementation
1. [Step 1]
2. [Step 2]
```

---

## 12. Artifacts

- **Branch/Commit:** [Reference]
- **Test results:** [Pass/Fail summary]
- **Coverage report:** [Location if generated]

---

# End of Implementation Report
