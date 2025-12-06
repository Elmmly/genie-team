---
type: design
concept: {concept}
enhancement: {enhancement}
status: active
created: {YYYY-MM-DD}
---

# Design Document — Architect Genie
### Structured Markdown Output Template

> This template defines the required output sections for the Architect genie.
> All sections should be included. Mark as "N/A" if not applicable.
> Depth should match complexity and appetite.
>
> **Frontmatter:** Replace `{concept}`, `{enhancement}`, and `{YYYY-MM-DD}` with actual values.

---

## 1. Design Overview
[High-level summary of the technical approach - 2-3 sentences]
[Key design decisions at a glance]

**Input:** [Reference to Shaped Work Contract]
**Appetite:** [Time/effort constraint from shaping]
**Complexity:** [Simple / Moderate / Complex]

---

## 2. Architecture

### System Context
[Where this fits in the broader system]
[C4 Level 1-2 context if helpful]

### Component Design
| Component | Responsibility | New/Modified |
|-----------|---------------|--------------|
| [Name] | [What it does] | [New / Modified] |

### Data Flow
```
[ASCII diagram or description of data flow]
[State transitions if applicable]
```

---

## 3. Interfaces & Contracts

### Public Interfaces
```python
# Or appropriate language
def function_name(param: Type) -> ReturnType:
    """
    Description of contract.

    Args:
        param: What this parameter means

    Returns:
        What this returns

    Raises:
        WhatError: When this happens
    """
    pass
```

### Data Structures
```python
@dataclass
class EntityName:
    """Description"""
    field1: Type
    field2: Type
```

### External Integrations
| Integration | Contract | Notes |
|-------------|----------|-------|
| [Service] | [API/Format] | [Notes] |

---

## 4. Pattern Adherence

### Patterns Applied
- **[Pattern Name]:** [How it's used here]
- **[Pattern Name]:** [How it's used here]

### Project Conventions Followed
- [ ] [Convention 1]
- [ ] [Convention 2]
- [ ] [Convention 3]

### Deviations from Convention
| Deviation | Justification |
|-----------|---------------|
| [What's different] | [Why it's justified] |

---

## 5. Technical Decisions

| Decision | Options Considered | Choice | Rationale |
|----------|-------------------|--------|-----------|
| [Decision 1] | A, B, C | B | [Why B] |
| [Decision 2] | X, Y | X | [Why X] |

---

## 6. Implementation Guidance

### Module Structure
```
path/to/
├── new_module.py      # [Purpose]
├── modified_file.py   # [Changes needed]
└── tests/
    └── test_new.py    # [Test coverage]
```

### Implementation Sequence
1. [ ] [First step - foundational]
2. [ ] [Second step - builds on first]
3. [ ] [Third step - integration]
4. [ ] [Fourth step - polish]

### Key Considerations
- **Must do:** [Critical requirements]
- **Should do:** [Important but flexible]
- **Nice to have:** [If time permits]

---

## 7. Error Handling & Edge Cases

| Scenario | Expected Behavior | Handling |
|----------|-------------------|----------|
| [Error 1] | [What happens] | [How to handle] |
| [Edge case 1] | [What happens] | [How to handle] |

### Failure Modes
- **Graceful degradation:** [What to do when X fails]
- **Critical failures:** [What requires alerting]

---

## 8. Performance Considerations

### Expected Load
- [Metric]: [Expected value]

### Potential Bottlenecks
- [Bottleneck 1]: [Mitigation]

### Optimization Opportunities
- [Opportunity]: [When to pursue]

---

## 9. Security Considerations

### Threat Model
- **Data sensitivity:** [What sensitive data is involved]
- **Attack surface:** [What's exposed]

### Security Measures
- [ ] [Measure 1]
- [ ] [Measure 2]

---

## 10. Testing Strategy

### Unit Tests
| Component | Test Focus | Priority |
|-----------|-----------|----------|
| [Component] | [What to test] | [High/Medium/Low] |

### Integration Tests
- [ ] [Integration scenario 1]
- [ ] [Integration scenario 2]

### E2E Tests (if applicable)
- [ ] [E2E scenario]

### Test Data Requirements
- [What test data is needed]

---

## 11. Rollback / Feature Flag Plan

### Feature Flag
- **Name:** `feature_{name}`
- **Default:** off
- **Behavior when off:** [What happens]

### Rollback Procedure
1. [Step 1 to revert]
2. [Step 2 to revert]
3. [Verification step]

### Monitoring
- **Metrics to watch:** [What indicates problems]
- **Alerts:** [What should trigger alerts]

---

## 12. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [How to mitigate] |
| [Risk 2] | Low/Med/High | Low/Med/High | [How to mitigate] |

### Accepted Risks
- [Risk we're accepting]: [Why it's acceptable]

---

## 13. Open Questions for Crafter
- [ ] [Question about implementation detail]
- [ ] [Question about edge case handling]
- [ ] [Flexibility area - Crafter can decide]

---

## 14. Routing

**Recommended route:**
- [ ] **Crafter** - Design complete, ready for implementation
- [ ] **Shaper** - Needs scope clarification
- [ ] **Scout** - Needs technical spike
- [ ] **Navigator** - Needs strategic decision

**Rationale:** [Why this routing]

---

## 15. Artifacts Created

- **Design saved to:** `docs/analysis/YYYYMMDD_design_{topic}.md`
- **ADR created:** [yes/no]
  - If yes: `docs/decisions/ADR-{number}.md`
- **Architecture docs updated:** [yes/no]
  - If yes: What was updated

---

# End of Design Document
