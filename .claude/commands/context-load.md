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
   - `docs/specs/**/*.md` — Recursively scan all domain subdirectories for `type: spec` frontmatter. Count by status: `active`, `deprecated`. List domains found. If `docs/specs/` does not exist, report "No specs directory — run /spec:init to bootstrap specs from source code and tests"
   - `docs/backlog/*.md` — Count backlog items (work in progress, separate from specs)
   - Detect test framework (look for `package.json` test scripts, `pytest.ini`, `jest.config.*`, `vitest.config.*`, etc.)
   - Count test files and describe/it blocks
   - Report spec coverage: how many capabilities have specs, how many have tests but no specs

3. Scan for architecture artifacts:
   - `docs/decisions/ADR-*.md` — Count ADRs by status: `proposed`, `accepted`, `deprecated`, `superseded`. If `docs/decisions/` does not exist, report "No ADRs — consider creating ADR-000 via /design"
   - `docs/architecture/**/*.md` — Check `updated` date in frontmatter against 90-day staleness threshold. List diagrams found and staleness status. If `docs/architecture/` does not exist: if `docs/specs/` exists, report "No C4 diagrams — run /arch:init to bootstrap architecture diagrams"; if `docs/specs/` also does not exist, report "No C4 diagrams — run /spec:init to bootstrap specs and diagrams"
   - Report architecture health: ADR count, diagram coverage, staleness warnings

4. Summarize current state briefly

5. Suggest next action based on state

---

## Output Format

```markdown
# Context Loaded

**Project:** [Name from CLAUDE.md]
**Current work:** [In-progress item or "None"]
**Recent decisions:** [Last 3 decisions, one-line each]
**Spec coverage:**
  - Specs: [N active, K deprecated] across [D] domains (from docs/specs/)
  - Backlog: [N items] (from docs/backlog/)
  - Test suites: [N describe blocks, M test cases]
  - Unspecified: [N test suites have no matching spec]
**Architecture:**
  - ADRs: [N accepted, M proposed, K deprecated/superseded] or "No ADRs"
  - C4 Diagrams: [L1: present/missing, L2: present/missing, L3: N domain diagrams] or "No diagrams"
  - Staleness: [N diagrams stale (>90 days)] or "All current"
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
- docs/specs/**/*.md (recursive — scan all domains for `type: spec`)
- docs/backlog/*.md (scan for active work items)
- docs/decisions/ADR-*.md (scan for architecture decisions)
- docs/architecture/**/*.md (scan for C4 diagrams and staleness)
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
