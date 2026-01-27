---
spec_version: "1.0"
type: design
id: "{ID}"
title: "{Title}"
status: designed
created: "{YYYY-MM-DD}"
spec_ref: "{docs/backlog/Pn-topic.md}"
appetite: "{small|medium|big}"
complexity: "{simple|moderate|complex}"
author: architect
ac_mapping:
  - ac_id: AC-1
    approach: "{How this acceptance criterion will be satisfied}"
    components: ["{path/to/file}"]
  - ac_id: AC-2
    approach: "{How this acceptance criterion will be satisfied}"
    components: ["{path/to/file}"]
components:
  - name: "{Component name}"
    action: "{create|modify|delete}"
    files: ["{path/to/file}"]
---

# Design Document: {Title}

> **Schema:** `schemas/design-document.schema.md` v1.0
>
> All structured data lives in the YAML frontmatter above. The body below
> is free-form narrative for human context. Machines parse frontmatter only.

## Design Overview

[High-level summary of the technical approach -- 2-3 sentences]
[Key design decisions at a glance]

## Architecture

### System Context
[Where this fits in the broader system]

### Component Design
| Component | Responsibility | New/Modified |
|-----------|---------------|--------------|
| [Name] | [What it does] | [New / Modified] |

### Data Flow
```
[ASCII diagram or description of data flow]
```

## Interfaces & Contracts

```python
# Or appropriate language
def function_name(param: Type) -> ReturnType:
    """Description of contract."""
    pass
```

## Pattern Adherence

- **Patterns used:** [Pattern]: [How applied]
- **Deviations:** [If any, with justification]

## Technical Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| [What] | [Alternatives] | [Selected] | [Why] |

## Implementation Guidance

1. [Step 1 -- foundational]
2. [Step 2 -- builds on first]
3. [Step 3 -- integration]

### Key Considerations
- **Must do:** [Critical requirements]
- **Should do:** [Important but flexible]

## Error Handling & Edge Cases

| Scenario | Expected Behavior | Handling |
|----------|-------------------|----------|
| [Error 1] | [What happens] | [How to handle] |

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| [Risk 1] | Low/Med/High | Low/Med/High | [How to mitigate] |

## Testing Strategy

- **Unit:** [What to test]
- **Integration:** [What to test]
- **Key scenarios:** [Critical paths]

## Routing

- [ ] **Crafter** -- Design complete, ready for implementation
- [ ] **Shaper** -- Needs scope clarification
- [ ] **Scout** -- Needs technical spike

**Rationale:** [Why this routing]
