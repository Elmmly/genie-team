# /context:load

Initialize session with project context. Run at the start of every session.

---

## Behavior

1. Read core context files:
   - CLAUDE.md (project root)
   - docs/context/system_architecture.md
   - docs/context/recent_decisions.md (last 30 days)
   - docs/context/current_work.md (if exists)

2. Summarize current state briefly

3. Suggest next action based on state

---

## Output Format

```markdown
# Context Loaded

**Project:** [Name from CLAUDE.md]
**Current work:** [In-progress item or "None"]
**Recent decisions:** [Last 3 decisions, one-line each]
**Ready for:** [Suggested next command]
```

---

## Context Operations

**READ:**
- CLAUDE.md
- docs/context/system_architecture.md
- docs/context/recent_decisions.md
- docs/context/current_work.md

**WRITE:**
- None (read-only operation)

---

## Usage Examples

```
/context:load
> Context loaded. No current work. Ready for /discover or /shape.

/context:load
> Context loaded. Current work: P2-auth-improvements (Design phase)
> Last activity: 2 days ago
> Recommended: /design docs/backlog/P2-auth-improvements.md
```

---

## Notes

- This is the first command to run in any session
- Establishes shared understanding before work begins
- Reduces 10-15 min context re-establishment time
- Safe to run multiple times (idempotent)
