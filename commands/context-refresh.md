# /context:refresh

Update context documents from current codebase state. Use when context docs are stale.

---

## Behavior

1. Scan codebase for structural changes
2. Update docs/context/codebase_structure.md
3. Check for new patterns or conventions
4. Flag any drift from documented architecture
5. **Spec bootstrapping:** Scan test files and project artifacts to produce AC candidates
   - Detect test framework from config files (package.json, pytest.ini, jest.config.*, etc.)
   - Scan test files for describe/it blocks (or equivalent per framework)
   - Group tests by feature (one describe block = one behavioral feature = one AC candidate)
   - Scan docs/ (README, CLAUDE.md) and code structure for feature boundaries
   - Produce AC candidates document at `docs/analysis/YYYYMMDD_spec_bootstrap_{project}.md`
   - Individual tests within a describe block are evidence, not separate ACs

---

## Output Format

```markdown
# Context Refreshed

**Codebase structure:** [Updated / No changes]
**New patterns detected:** [List or "None"]
**Architecture drift:** [Issues or "None"]
**Spec bootstrap:** [N AC candidates from M test files / "No test files found"]

**Updated files:**
- docs/context/codebase_structure.md
- docs/analysis/YYYYMMDD_spec_bootstrap_{project}.md (if tests found)
```

### Spec Bootstrap Output Format

When test files are found, the bootstrap document uses this structure:

```yaml
---
type: spec-bootstrap
project: {project-name}
created: {YYYY-MM-DD}
test_framework: {jest|pytest|vitest|mocha|etc}
test_files_scanned: {N}
describe_blocks: {N}
test_cases: {N}
ac_candidates: {N}
---

# Spec Bootstrap: {project-name}

## Test-Derived AC Candidates

### Feature: {ComponentName} ({test-file-path})

| AC Candidate | Source Tests | Confidence |
|--------------|-------------|------------|
| {behavioral outcome} | {N} tests in "{describe}" | {high|medium|low} |

## Unspecified Behavior

Test suites without matching specs:
- {test-file-path} ({N} tests) — No backlog item covers {feature}

## Recommended Next Steps

1. Review AC candidates above
2. Create shaped work contracts for unspecified features via /define
3. Link existing backlog items to test suites
```

---

## Context Operations

**READ:**
- Source code directories
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- Test files (*.test.ts, *.test.js, *.spec.ts, *_test.py, test_*.py, etc.)
- Test config files (package.json, pytest.ini, jest.config.*, vitest.config.*, etc.)
- docs/backlog/*.md (to cross-reference with test-derived features)
- README.md, CLAUDE.md (for project context)

**WRITE:**
- docs/context/codebase_structure.md
- docs/analysis/YYYYMMDD_spec_bootstrap_{project}.md (when test files found)

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
