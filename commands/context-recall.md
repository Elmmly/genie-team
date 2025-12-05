# /context:recall [topic]

Find past work on a specific topic. Use before starting work that might duplicate previous effort.

---

## Arguments

- `topic` - The subject to search for (required)

---

## Behavior

1. Search analysis/ folder for topic
2. Search backlog/ for related items
3. Search recent_decisions.md for mentions
4. Present findings with document links

---

## Output Format

```markdown
# Recall: [Topic]

**Analysis found:**
- docs/analysis/YYYYMMDD_discover_topic.md
- docs/analysis/YYYYMMDD_design_topic.md

**Decisions found:**
- [Date]: [Decision about topic]
- [Date]: [Related decision]

**Backlog items:**
- docs/backlog/P2-topic.md

**Summary:** [Brief synthesis of what was done/decided]
```

---

## Context Operations

**READ:**
- docs/analysis/*
- docs/backlog/*
- docs/decisions/*
- docs/context/recent_decisions.md

**WRITE:**
- None (read-only operation)

---

## Usage Examples

```
/context:recall auth
> Found: 3 analysis docs, 2 decisions, 1 backlog item
>
> Analysis:
> - 20251115_discover_auth.md - Initial auth discovery
> - 20251120_design_auth.md - JWT vs session design
>
> Decisions:
> - Nov 20: Chose JWT for API, session for web
> - Nov 22: Token expiry set to 1 hour
>
> Backlog:
> - P2-auth-refresh.md - Implement refresh tokens

/context:recall "error handling"
> No previous work found on "error handling"
```

---

## When to Use

- Before starting discovery on any topic
- When you think "didn't we discuss this before?"
- To find past decisions that might constrain current work
- To avoid duplicating analysis

---

## Notes

- Prevents re-doing work already completed
- Surfaces constraints from past decisions
- Helps maintain consistency across sessions
- Quick lookup before deeper work
