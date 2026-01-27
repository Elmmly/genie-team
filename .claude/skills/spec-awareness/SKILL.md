---
name: spec-awareness
description: Ensures spec-driven behavior during all workflows. Use when loading context, discussing project structure, starting features, or when "spec", "specification", "acceptance criteria", or "bootstrap" are mentioned. Activates during /context:load, /context:refresh, /deliver, and /discover.
allowed-tools: Read, Glob, Grep
---

# Spec Awareness

Spec-driven development is the standard. Every capability should have a persistent
specification in `specs/` (with `type: spec` YAML frontmatter) before implementation begins.
Specs are the persistent source of truth for what the system does. Backlog items in
`docs/backlog/` describe changes to make — they are transient and get archived when done.

## Spec Organization: Domain > Capability

Specs model the **product architecture**, not the code structure. They are organized
by domain (a product-level bounded context) and capability (a specific behavior within
that domain).

### Hierarchy

```
specs/
  {domain}/
    {capability}.md         # active or deprecated spec
  _drafts/
    {capability-slug}.md    # bootstrapped, awaiting human review
```

### Definitions

| Term | Definition | Stability | Example |
|------|-----------|-----------|---------|
| **Domain** | A product-level bounded context — a coherent area of functionality. Domains change on a product-strategy timescale (years). | Very stable | `identity`, `workflow`, `execution` |
| **Capability** | A specific behavior the system provides within a domain. The unit of specification. | Stable | `authentication`, `headless-mode`, `tdd-discipline` |
| **Spec** | A file describing one capability: `specs/{domain}/{capability}.md` | Persistent | `specs/execution/headless-mode.md` |
| **Draft** | A bootstrapped spec awaiting human review: `specs/_drafts/{capability-slug}.md` | Temporary | `specs/_drafts/session-management.md` |

### Naming Convention

- **Domain names:** lowercase kebab-case, product-oriented (not code-oriented). Examples: `identity`, `workflow`, `data-pipeline` — NOT `src-services`, `api`, `frontend`
- **Capability names:** lowercase kebab-case, behavior-oriented. Examples: `authentication`, `headless-mode`, `spec-bootstrapping`
- **Spec files:** `specs/{domain}/{capability}.md`
- **Draft files:** `specs/_drafts/{capability-slug}.md`

### Spec Lifecycle

```
/context:refresh → specs/_drafts/{capability}.md (status: draft)
       ↓
/define → specs/{domain}/{capability}.md (status: active)
       ↓
deprecation → status: deprecated (stays in place, never deleted)
```

- **draft** — Bootstrapped from tests. Lives in `_drafts/`. Awaiting human review.
- **active** — Human-reviewed and organized into a domain. The source of truth.
- **deprecated** — Capability removed or superseded. Stays in place for history.

### Key Principle

Domains are rooted in product architecture, NOT code architecture. Code modules get
refactored; domains persist. Specs organized by domain survive code reorganizations
without needing to be moved.

## When Active

This skill activates during:
- `/context:load` — Report spec coverage
- `/context:refresh` — Bootstrap specs from tests
- `/deliver` — Verify structured acceptance criteria exist
- `/discover` — Surface test-based insights
- Any discussion of project features, specs, or acceptance criteria

## Behaviors

### During /deliver

Before starting implementation, check the backlog item and its spec:

1. Read the frontmatter of the backlog item being delivered
2. Verify `type: shaped-work` is present with `acceptance_criteria`
3. Check if the backlog item has a `spec_ref` field pointing to a spec in `specs/{domain}/`
4. If `spec_ref` is missing: **warn** the user:
   > This backlog item has no spec_ref. Consider linking it to a persistent spec in specs/{domain}/.
5. If `spec_ref` is present, read the referenced spec and verify it exists
6. If no acceptance criteria: **warn** the user:
   > This item lacks structured acceptance criteria. Consider running
   > /context:refresh to bootstrap specs from existing tests.
7. Do NOT block delivery — warn and continue

### During /discover

Surface test-based insights about the project:

1. Scan for test files (*.test.ts, *.test.js, *.spec.ts, *_test.py, test_*.py, etc.)
2. Count test files, describe blocks, and test cases
3. Report: "This project has N tests across M files. K capabilities have tests but no specs."

### During /context:load

Include spec coverage in the context summary:

1. Scan `specs/**/*.md` recursively for `type: spec` in frontmatter
2. Count specs by status: `active`, `draft`, `deprecated`
3. List domains found (subdirectories of `specs/` excluding `_drafts`)
4. Count drafts pending review in `specs/_drafts/`
5. Scan `docs/backlog/*.md` for active work items (separately)
6. Report coverage in the context loaded output

### General

When discussing any feature or component:

1. Check if a spec exists for it in `specs/{domain}/`
2. Check `specs/_drafts/` for draft specs
3. If not specified anywhere, note that the capability is unspecified
4. If tests exist but no spec, note the gap

## What This Skill Does NOT Do

- Does NOT block any workflow — only warns and informs
- Does NOT create specs automatically — that requires human review via /define
- Does NOT modify files — read-only analysis
- Does NOT replace /context:load or /context:refresh — enhances them
- Does NOT decide domain assignments — that is a human decision via /define
