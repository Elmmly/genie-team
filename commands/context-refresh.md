# /context:refresh

Update context documents from current codebase state. Use when context docs are stale.

---

## Behavior

1. Scan codebase for structural changes
2. Update docs/context/codebase_structure.md
3. Check for new patterns or conventions
4. Flag any drift from documented architecture
5. Detect C4 diagram drift:
   - Load `docs/architecture/**/*.md` diagrams (if they exist)
   - Compare diagram containers/components against actual project structure
   - Flag: containers/components in diagram but not in code, code structures not reflected in diagrams
   - Report drift findings with recommended updates

---

## Output Format

```markdown
# Context Refreshed

**Codebase structure:** [Updated / No changes]
**New patterns detected:** [List or "None"]
**Architecture drift:** [Issues or "None"]
**Diagram drift:** [Issues or "None" or "No diagrams to check"]
  - [Container/component] in diagram but not found in code
  - [Code structure] not reflected in any diagram

**Updated files:**
- docs/context/codebase_structure.md
```

---

## Context Operations

**READ:**
- Source code directories
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- docs/architecture/**/*.md (C4 diagrams for drift detection)

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
- For spec creation, use /spec:init instead
