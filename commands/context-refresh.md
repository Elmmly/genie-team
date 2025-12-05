# /context:refresh

Update context documents from current codebase state. Use when context docs are stale.

---

## Behavior

1. Scan codebase for structural changes
2. Update docs/context/codebase_structure.md
3. Check for new patterns or conventions
4. Flag any drift from documented architecture

---

## Output Format

```markdown
# Context Refreshed

**Codebase structure:** [Updated / No changes]
**New patterns detected:** [List or "None"]
**Architecture drift:** [Issues or "None"]

**Updated files:**
- docs/context/codebase_structure.md
```

---

## Context Operations

**READ:**
- Source code directories
- docs/context/system_architecture.md
- docs/context/codebase_structure.md

**WRITE:**
- docs/context/codebase_structure.md

---

## Triggers

Run /context:refresh when:
- Starting work after significant time away
- After large feature merges
- Before major architectural work
- When context feels stale

---

## Usage Examples

```
/context:refresh
> Codebase structure updated
> New patterns detected:
> - New /services directory added
> - GraphQL resolvers pattern emerging
> Architecture drift: None

/context:refresh
> No structural changes detected
> Context documents are current
```

---

## Notes

- Keeps context aligned with reality
- Detects undocumented changes
- Lighter than full /diagnose
- Complements /context:load
