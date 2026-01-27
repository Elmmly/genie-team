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
   - `specs/**/*.md` — Recursively scan all domain subdirectories for `type: spec` frontmatter. Count by status: `active`, `deprecated`. List domains found. If `specs/` does not exist, report "No specs directory — run /spec:init to bootstrap specs from source code and tests"
   - `docs/backlog/*.md` — Count backlog items (work in progress, separate from specs)
   - Detect test framework (look for `package.json` test scripts, `pytest.ini`, `jest.config.*`, `vitest.config.*`, etc.)
   - Count test files and describe/it blocks
   - Report spec coverage: how many capabilities have specs, how many have tests but no specs

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
  - Specs: [N active, K deprecated] across [D] domains (from specs/)
  - Backlog: [N items] (from docs/backlog/)
  - Test suites: [N describe blocks, M test cases]
  - Unspecified: [N test suites have no matching spec]
**Ready for:** [Suggested next command]
```

If spec coverage shows unspecified test suites, recommend:
`Run /spec:init to bootstrap specs from source code and tests`

---

## Context Operations

**READ:**
- CLAUDE.md
- docs/context/system_architecture.md
- docs/context/recent_decisions.md
- docs/context/current_work.md
- specs/**/*.md (recursive — scan all domains for `type: spec`)
- docs/backlog/*.md (scan for active work items)
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
