# /context:summary

Create a handoff summary of current work state. Run at end of session or before switching genies.

---

## Behavior

1. Gather recent work from analysis/ folder
2. Summarize key decisions and outputs
3. Identify open items and blockers
4. Write to docs/context/current_work.md

---

## Output Format

```markdown
# Work Summary

**Last activity:** [What was done]
**Key outputs:** [Documents created]
**Open items:** [What's pending]
**Blockers:** [What's stuck]
**Recommended next:** [Suggested action]
```

---

## Context Operations

**READ:**
- docs/analysis/* (recent files)
- docs/backlog/* (in-progress items)
- Current session activity

**WRITE:**
- docs/context/current_work.md

---

## Usage Examples

```
/context:summary
> Summary written to docs/context/current_work.md
>
> Last activity: Completed discovery on auth improvements
> Key outputs: docs/analysis/20251203_discover_auth.md
> Open items: Shape auth improvements, decide on token strategy
> Recommended next: /shape docs/analysis/20251203_discover_auth.md
```

---

## When to Use

- End of work session
- Before switching to different genie
- Before taking a break
- When handing off to another person

---

## Notes

- Creates clean resumption point
- Persists context that would otherwise be lost
- Enables async collaboration
- Complements /context:load
