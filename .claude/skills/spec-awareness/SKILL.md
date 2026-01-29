---
name: spec-awareness
description: Ensures spec-driven behavior during all workflows. Use when loading context, discussing project structure, starting features, or when "spec", "specification", "acceptance criteria", or "bootstrap" are mentioned. Activates during /context:load, /context:refresh, /spec:init, /define, /design, /deliver, /discern, /done, and /discover.
allowed-tools: Read, Glob, Grep
---

# Spec Awareness

Spec-driven development is the standard. Every capability should have a persistent
specification in `docs/specs/` (with `type: spec` YAML frontmatter) before implementation begins.
Specs are the persistent source of truth for what the system does. Backlog items in
`docs/backlog/` describe changes to make — they are transient and get archived when done.

## Spec Organization: Domain > Capability

Specs model the **product architecture**, not the code structure. They are organized
by domain (a product-level bounded context) and capability (a specific behavior within
that domain).

### Hierarchy

```
docs/specs/
  {domain}/
    {capability}.md         # active or deprecated spec
```

### Definitions

| Term | Definition | Stability | Example |
|------|-----------|-----------|---------|
| **Domain** | A product-level bounded context — a coherent area of functionality. Domains change on a product-strategy timescale (years). | Very stable | `identity`, `workflow`, `execution` |
| **Capability** | A specific behavior the system provides within a domain. The unit of specification. | Stable | `authentication`, `headless-mode`, `tdd-discipline` |
| **Spec** | A file describing one capability: `docs/specs/{domain}/{capability}.md` | Persistent | `docs/specs/execution/headless-mode.md` |

### Naming Convention

- **Domain names:** lowercase kebab-case, product-oriented (not code-oriented). Examples: `identity`, `workflow`, `data-pipeline` — NOT `src-services`, `api`, `frontend`
- **Capability names:** lowercase kebab-case, behavior-oriented. Examples: `authentication`, `headless-mode`, `spec-bootstrapping`
- **Spec files:** `docs/specs/{domain}/{capability}.md`

### Spec Lifecycle

```
/spec:init → docs/specs/{domain}/{capability}.md (status: active)   [bulk — existing project]
/define    → docs/specs/{domain}/{capability}.md (status: active)   [incremental — new capability]
       ↓
deprecation → status: deprecated (stays in place, never deleted)
```

- **active** — Created by `/spec:init` (bulk from existing project) or `/define` (incremental for new capability). The source of truth.
- **deprecated** — Capability removed or superseded. Stays in place for history.

### Key Principle

Domains are rooted in product architecture, NOT code architecture. Code modules get
refactored; domains persist. Specs organized by domain survive code reorganizations
without needing to be moved.

## When Active

This skill activates during:
- `/context:load` — Report spec coverage
- `/context:refresh` — Detect drift (does NOT create specs)
- `/spec:init` — Bootstrap rich specs from existing project source code, tests, and docs
- `/define` — Link to existing spec with behavioral delta, or create new spec for new capability
- `/design` — Load spec for context, write back design constraints
- `/deliver` — Load spec ACs for TDD, write back implementation evidence
- `/discern` — Verify implementation against spec ACs, update AC statuses
- `/done` — Preserve spec on archive
- Any discussion of project features, specs, or acceptance criteria

## Behaviors

### Common: Spec Loading Pattern

All commands that read specs follow this pattern:

1. Read `spec_ref` from backlog item frontmatter
2. If `spec_ref` is present: Read the referenced spec file
3. If `spec_ref` is missing: **Warn** and continue without spec context:
   > This backlog item has no spec_ref. Consider linking it to a persistent spec in docs/specs/{domain}/.
4. If `spec_ref` points to a nonexistent file: **Warn** and continue:
   > spec_ref points to {path} but file not found. Proceeding without spec context.
5. **Never block** — specs are valuable but optional. All commands warn and continue.

### During /spec:init

Bootstraps rich specs from an existing project:

1. Deep scan source code, test files, project docs (README, CLAUDE.md), config files, and directory structure
2. Identify behavioral capabilities — grouped by what the system does, not by file or directory boundaries
3. Check for existing specs in `docs/specs/**/*.md` — skip capabilities that already have specs
4. Present capabilities in batches (up to 5) with: name, description, evidence, proposed ACs
5. Ask the user for domain assignment per batch (present existing domains, allow new ones)
6. User can merge, skip, rename, or accept capabilities
7. Write directly to `docs/specs/{domain}/{capability}.md` with `status: active`
8. Output summary of everything created

**Reads:** Source code, test files, project docs, config files, `docs/specs/**/*.md`
**Writes:** `docs/specs/{domain}/{capability}.md`

### During /define

Links to existing specs with behavioral delta, or creates new specs:

**When changing an existing capability:**
1. Discover the existing spec via `spec_ref` or by searching `docs/specs/` with user confirmation
2. Document the **behavioral delta** in the shaped work contract:
   - **Current Behavior:** Quote the affected spec ACs as they exist today
   - **Proposed Changes:** What each AC will change to, plus any new ACs being added
   - **Rationale:** Why the changes are needed (from discovery or problem statement)
3. Tag affected ACs, set `spec_ref` on the backlog item

**When creating a new capability:**
1. Ask the user which domain the capability belongs to (present existing domains)
2. Create new spec at `docs/specs/{domain}/{capability}.md` with `status: active`
3. Set `spec_ref: docs/specs/{domain}/{capability}.md` in the backlog item frontmatter

**Reads:** `docs/specs/` domain directories, existing spec ACs
**Writes:** `docs/specs/{domain}/{capability}.md` (new capability only), backlog frontmatter `spec_ref`

### During /design

Loads spec for design context and writes back constraints:

1. Load spec via `spec_ref` (using common pattern above)
2. Use spec ACs and existing evidence as design input
3. After design: Append "## Design Constraints" section to spec body
4. If design reveals new behavioral requirements: Append new ACs to spec frontmatter (never remove existing)

**Reads:** Spec ACs, existing evidence sections
**Writes:** Spec body "## Design Constraints" section, spec frontmatter `acceptance_criteria` (append only)

### During /deliver

Loads spec ACs for TDD and writes back implementation evidence:

1. Load spec via `spec_ref` (using common pattern above)
2. Use spec ACs as TDD test targets — each pending AC maps to at least one test case
3. Test descriptions reference AC ids (e.g., "AC-1: should issue refresh tokens")
4. After implementation: Append "## Implementation Evidence" section to spec body with test file paths and implementation file paths
5. Do NOT update AC statuses — that is /discern's job

**Reads:** Spec acceptance_criteria
**Writes:** Spec body "## Implementation Evidence" section

### During /discern

Verifies implementation against spec ACs and updates statuses:

1. Load spec via `spec_ref` (using common pattern above)
2. Evaluate each spec AC against the implementation
3. Update spec frontmatter: `status: pending` → `met` or `unmet` for each AC
4. Append "## Review Verdict" section to spec body with verdict and AC status table
5. Never remove or rewrite AC descriptions — only change status fields

**Reads:** Spec acceptance_criteria, implementation evidence
**Writes:** Spec frontmatter AC statuses, spec body "## Review Verdict" section

### During /done

Preserves spec when archiving backlog:

1. Archive backlog item as normal (move to `docs/archive/`)
2. **Never archive the spec** — specs are persistent knowledge
3. Spec retains all accumulated knowledge (constraints, evidence, verdicts)

**Reads:** Spec status
**Writes:** Nothing (spec preservation is passive — just don't archive it)

### During /discover

Surface test-based insights about the project:

1. Scan for test files (*.test.ts, *.test.js, *.spec.ts, *_test.py, test_*.py, etc.)
2. Count test files, describe blocks, and test cases
3. Report: "This project has N tests across M files. K capabilities have tests but no specs."

**Reads:** Test files, docs/specs/
**Writes:** Nothing (read-only)

### During /context:load

Include spec coverage in the context summary:

1. Scan `docs/specs/**/*.md` recursively for `type: spec` in frontmatter
2. Count specs by status: `active`, `deprecated`
3. List domains found (subdirectories of `docs/specs/`)
4. Scan `docs/backlog/*.md` for active work items (separately)
5. Report coverage in the context loaded output

**Reads:** `docs/specs/**/*.md`, `docs/backlog/*.md`
**Writes:** Nothing (read-only)

### General

When discussing any feature or component:

1. Check if a spec exists for it in `docs/specs/{domain}/`
2. If not specified anywhere, note that the capability is unspecified
3. If tests exist but no spec, note the gap

## Spec Update Rules (All Commands)

These rules apply to ALL commands that write to specs:

1. **Append only** — Never remove or rewrite existing ACs, sections, or evidence
2. **Frontmatter is machine-readable** — AC statuses and structural fields go in YAML frontmatter
3. **Body is human-readable** — Narrative sections (Design Constraints, Implementation Evidence, Review Verdict) go in the markdown body
4. **Warn, never block** — Missing or broken spec_ref is a warning, not a workflow blocker
5. **Domain is a human decision** — Always ask the user; never guess or infer the domain
6. **Specs persist** — Never archive, delete, or move specs out of `docs/specs/`. Only backlog items are transient.

## What This Skill Does NOT Do

- Does NOT block any workflow — only warns and informs
- Does NOT create specs during /context:refresh — use /spec:init for bulk bootstrapping or /define for incremental creation
- Does NOT decide domain assignments — that is always a human decision via /define or /spec:init
- Does NOT delete or archive specs — specs are permanent
- Does NOT modify AC descriptions — only statuses change
