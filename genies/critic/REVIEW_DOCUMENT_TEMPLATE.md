---
spec_version: "1.0"
type: review
id: "{ID}"
title: "{Title}"
verdict: "{APPROVED|CHANGES_REQUESTED|BLOCKED}"
created: "{YYYY-MM-DD}"
spec_ref: "{specs/domain/capability.md or docs/backlog/Pn-topic.md}"
execution_ref: "{docs/backlog/Pn-topic.md}"
confidence: "{high|medium|low}"
author: critic
issues:
  - severity: "{critical|major|minor}"
    location: "{path/to/file:line}"
    description: "{What the issue is}"
    fix: "{Suggested resolution}"
acceptance_criteria:
  - id: AC-1
    status: "{pass|fail}"
    notes: "{Why it passed or failed}"
---

# Review: {Title}

> **Schema:** `schemas/review-document.schema.md` v1.0
>
> All structured data lives in the YAML frontmatter above. The body below
> is free-form narrative for human context. Machines parse frontmatter only.

## Summary

[2-3 sentence assessment of the implementation]

## Acceptance Criteria

| Criterion | Status | Notes |
|-----------|--------|-------|
| [Criterion] | Pass/Fail | [Notes] |

## Code Quality

### Strengths
- [What's done well]

### Issues Found

| Issue | Severity | Location | Fix |
|-------|----------|----------|-----|
| [Issue] | Critical/Major/Minor | `file:line` | [Suggestion] |

## Test Coverage

- **Target:** [%]
- **Achieved:** [%]
- **Missing:** [What's not covered]

## Security Review

- [ ] No sensitive data exposure
- [ ] Input validation present
- [ ] No injection vulnerabilities

## Risk Assessment

| Risk | L | I | Status |
|------|---|---|--------|
| [Risk] | M | H | Addressed/Open |

## Verdict

### If APPROVED:
- Ready for deployment
- Monitor: [What to watch]

### If CHANGES REQUESTED:
| Required Change | Priority | Assigned |
|-----------------|----------|----------|
| [Change] | Must/Should | Crafter |

### If BLOCKED:
- **Reason:** [Critical issue]
- **Resolution:** [What must happen]
- **Escalate to:** [Who]

## Routing
- **APPROVED** → Ready for `/commit`
- **CHANGES REQUESTED** → Back to Crafter
- **BLOCKED** → Escalate to Architect/Navigator
