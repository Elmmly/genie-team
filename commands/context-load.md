# /context:load

Initialize session with project context. Run at the start of every session.

---

## Behavior

1. Read core context files:
   - CLAUDE.md (project root)
   - docs/context/system_architecture.md
   - docs/context/recent_decisions.md (last 30 days)
   - docs/context/current_work.md (if exists)

2. Scan for spec coverage:
   - `docs/backlog/*.md` — Check frontmatter for `type: shaped-work` (structured specs)
   - Count backlog items with structured frontmatter vs legacy (no frontmatter)
   - Detect test framework (look for `package.json` test scripts, `pytest.ini`, `jest.config.*`, `vitest.config.*`, etc.)
   - Count test files and describe/it blocks
   - Report spec coverage: how many features have specs, how many have tests but no specs

3. Summarize current state briefly

4. Suggest next action based on state

---

## Output Format

```markdown
# Context Loaded

**Project:** [Name from CLAUDE.md]
**Current work:** [In-progress item or "None"]
**Recent decisions:** [Last 3 decisions, one-line each]
**Spec coverage:**
  - Backlog items: [N shaped, M legacy (no frontmatter)]
  - Test suites: [N describe blocks, M test cases]
  - Unspecified: [N describe blocks have no matching AC in any spec]
**Ready for:** [Suggested next command]
```

If spec coverage shows unspecified test suites, recommend:
`Run /context:refresh to bootstrap specs from existing tests`

---

## Context Operations

**READ:**
- CLAUDE.md
- docs/context/system_architecture.md
- docs/context/recent_decisions.md
- docs/context/current_work.md
- docs/backlog/*.md (scan frontmatter for `type: shaped-work`)
- Test config files (package.json, pytest.ini, jest.config.*, vitest.config.*, etc.)

**WRITE:**
- None (read-only operation)

---

## Usage Examples

```
/context:load
> Context loaded. No current work. Ready for /discover or /define.

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
