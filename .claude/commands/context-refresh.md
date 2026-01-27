# /context:refresh

Update context documents from current codebase state. Use when context docs are stale.

---

## Behavior

1. Scan codebase for structural changes
2. Update docs/context/codebase_structure.md
3. Check for new patterns or conventions
4. Flag any drift from documented architecture
5. **Spec bootstrapping:** Scan test files and project artifacts to produce draft specs
   - **Create `specs/_drafts/` if it does not exist** (self-provisioning — no installer required)
   - Detect test framework from config files (package.json, pytest.ini, jest.config.*, etc.)
   - Scan test files for describe/it blocks (or equivalent per framework)
   - Group tests by capability (one top-level describe block = one behavioral capability = one draft spec)
   - Scan docs/ (README, CLAUDE.md) and code structure for capability boundaries
   - Produce one draft spec per capability at `specs/_drafts/{capability-slug}.md`
   - If a spec already exists anywhere in `specs/` (including `specs/{domain}/`) with a matching id, do NOT overwrite — report as "already specified"
   - Draft specs use frontmatter `type: spec`, `status: draft`
   - Individual tests within a describe block are evidence, not separate ACs
   - Drafts stay in `_drafts/` until a human organizes them into a domain via `/define`

---

## Output Format

```markdown
# Context Refreshed

**Codebase structure:** [Updated / No changes]
**New patterns detected:** [List or "None"]
**Architecture drift:** [Issues or "None"]
**Spec bootstrap:** [N draft specs written to specs/_drafts/, M already specified / "No test files found"]

**Updated files:**
- docs/context/codebase_structure.md
- specs/_drafts/{capability-slug}.md (one per capability, if tests found)
```

### Spec Bootstrap Output Format

When test files are found, each capability produces an individual draft spec in `specs/_drafts/`:

```yaml
---
spec_version: "1.0"
type: spec
id: {capability-slug}
title: {Capability Name}
status: draft
created: {YYYY-MM-DD}
appetite: small
source: bootstrap
test_framework: {jest|pytest|vitest|mocha|etc}
acceptance_criteria:
  - id: AC-1
    description: {behavioral outcome derived from describe/it blocks}
    status: pending
---

# {Capability Name}

> Draft spec bootstrapped from test files. Review and promote to a domain via /define.

## Evidence

- {test-file-path}: {N} tests in "{describe}" block
```

**Rules:**
- One spec per capability (grouped by top-level describe block), not per test file
- If a spec with the same id already exists anywhere in `specs/` (including domain subdirectories), skip it and report as "already specified"
- Draft specs stay in `specs/_drafts/` until a human reviews and organizes them into `specs/{domain}/` via `/define`

### Bootstrap Summary Output

After writing draft specs, output a summary:

```markdown
## Spec Bootstrap Summary

- **Test framework:** {framework}
- **Test files scanned:** {N}
- **Draft specs written:** {N} (to specs/_drafts/)
- **Already specified:** {M} (skipped)
- **Unspecified test suites:** {K}

### Unspecified Behavior

Test suites without matching specs:
- {test-file-path} ({N} tests) — No spec covers {capability}

### Recommended Next Steps

1. Review draft specs in specs/_drafts/
2. Organize drafts into domains via /define (moves to specs/{domain}/{capability}.md)
3. Create shaped work contracts for unspecified capabilities
```

---

## Context Operations

**READ:**
- Source code directories
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- Test files (*.test.ts, *.test.js, *.spec.ts, *_test.py, test_*.py, etc.)
- Test config files (package.json, pytest.ini, jest.config.*, vitest.config.*, etc.)
- specs/**/*.md (recursive — check all domains and _drafts/ for existing specs)
- docs/backlog/*.md (to cross-reference with test-derived capabilities)
- README.md, CLAUDE.md (for project context)

**WRITE:**
- docs/context/codebase_structure.md
- specs/_drafts/{capability-slug}.md (one per capability, when test files found — never overwrite existing)

---

## Triggers

Run /context:refresh when:
- Starting work after significant time away
- After large feature merges
- Before major architectural work
- When context feels stale
- When onboarding a project that has code and tests but no specs
- When /context:load reports unspecified test suites

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
