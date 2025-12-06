---
type: review
concept: {concept}
enhancement: {enhancement}
status: active
created: {YYYY-MM-DD}
---

# Review Document — Critic Genie
### Structured Markdown Output Template

> This template documents the review conducted by Critic.
> Include all sections. Clear verdict required.
>
> **Frontmatter:** Replace `{concept}`, `{enhancement}`, and `{YYYY-MM-DD}` with actual values.

---

## 1. Review Summary
[High-level assessment - 2-3 sentences]
[Overall quality impression]

**Implementation:** [Reference to Implementation Report]
**Verdict:** **[APPROVED / CHANGES REQUESTED / BLOCKED]**

---

## 2. Acceptance Criteria Check

| Criterion | Status | Evidence |
|-----------|--------|----------|
| [Criterion 1 from Shaped Contract] | ✅ Met / ❌ Not Met | [How verified] |
| [Criterion 2] | ✅ Met / ❌ Not Met | [How verified] |
| [Criterion 3] | ✅ Met / ❌ Not Met | [How verified] |

**Overall acceptance:** [All Met / Partially Met / Not Met]

---

## 3. Code Quality Assessment

### Strengths
- [What's done well - be specific]
- [Good pattern usage]
- [Clean implementation]

### Issues Found

| # | Issue | Severity | Location | Recommendation |
|---|-------|----------|----------|----------------|
| 1 | [Specific issue] | Critical/Major/Minor | `file.py:123` | [How to fix] |
| 2 | [Specific issue] | Critical/Major/Minor | `file.py:456` | [How to fix] |

### Pattern Adherence
- [x] Follows project conventions
- [x] Uses established patterns
- [x] No hardcoded values
- [ ] Issue: [If any pattern violations]

---

## 4. Test Coverage Review

### Coverage Metrics
| Metric | Target | Actual | Status |
|--------|--------|--------|--------|
| Line coverage | [X]% | [Y]% | ✅/❌ |
| Branch coverage | [X]% | [Y]% | ✅/❌ |

### Test Quality Assessment
- [x] Tests are meaningful (not just coverage)
- [x] Edge cases covered
- [x] Error paths tested
- [ ] Gap: [If any gaps]

### Missing Tests (if any)
| Missing Test | Priority | Why Needed |
|--------------|----------|------------|
| [Scenario not tested] | High/Med/Low | [Risk if untested] |

---

## 5. Security Review

### Checklist
- [x] No sensitive data exposure
- [x] Input validation present
- [x] Auth/authz appropriate
- [x] No injection vulnerabilities
- [x] Secure defaults

### Security Issues (if any)
| Issue | Severity | Recommendation |
|-------|----------|----------------|
| [Issue] | Critical/Major/Minor | [Fix] |

**Security verdict:** [Pass / Concerns / Fail]

---

## 6. Performance Review

### Checklist
- [x] No N+1 query patterns
- [x] Appropriate caching
- [x] No blocking in hot paths
- [x] Resources cleaned up

### Performance Concerns (if any)
| Concern | Impact | Recommendation |
|---------|--------|----------------|
| [Concern] | High/Med/Low | [Action] |

**Performance verdict:** [Pass / Concerns / Fail]

---

## 7. Error Handling Review

### Checklist
- [x] Errors logged with context
- [x] Exceptions not swallowed
- [x] Graceful degradation where appropriate
- [x] User-facing errors are helpful

### Issues (if any)
| Location | Issue | Fix |
|----------|-------|-----|
| `file:line` | [Problem] | [Solution] |

---

## 8. Risk Assessment

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Identified risk 1] | Low/Med/High | Low/Med/High | [How addressed] |
| [Identified risk 2] | Low/Med/High | Low/Med/High | [How addressed] |

### Residual Risks (Accepted)
- [Risks remaining that are acceptable]

---

## 9. Verdict Details

### APPROVED
> Use when: All criteria met, no critical/major issues, tests pass

- **Deployment readiness:** Ready
- **Monitoring:** [What to watch post-deploy]
- **Rollback trigger:** [When to roll back]

### CHANGES REQUESTED
> Use when: Issues found but fixable

| Required Change | Priority | Notes |
|-----------------|----------|-------|
| [Change 1] | Must fix | [Details] |
| [Change 2] | Should fix | [Details] |
| [Change 3] | Nice to have | [Details] |

**Re-review required:** [Yes - for must-fix items / No - for minor items]

### BLOCKED
> Use when: Critical issues that can't proceed

- **Blocking reason:** [Specific critical issue]
- **Required action:** [What must happen]
- **Escalation:** [Who needs to decide]

---

## 10. Follow-up Items

### For Future Cycles (Not Blocking)
- [Tech debt observed]
- [Improvements to consider]
- [Patterns to refine]

### New Backlog Items Created
| Item | Priority | Routing |
|------|----------|---------|
| [Item description] | P1/P2/P3 | Shaper/Architect/Tidier |

---

## 11. Routing

**Current verdict routing:**

If **APPROVED:**
- [x] Notify Navigator
- [ ] Ready for deployment
- [ ] Update backlog item status

If **CHANGES REQUESTED:**
- [ ] Route to Crafter
- [ ] Schedule re-review

If **BLOCKED:**
- [ ] Escalate to: [Architect/Shaper/Navigator]
- [ ] Document blocker in backlog

---

## 12. Artifacts

- **Review saved to:** `docs/analysis/YYYYMMDD_review_{topic}.md`
- **Backlog items created:** [List or "None"]
- **Tech debt logged:** [Yes/No - location]

---

# End of Review Document
