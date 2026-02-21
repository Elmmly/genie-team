# /spec:init [scope]

Activate Scout genie to produce rich capability specifications from an existing project's source code, tests, and documentation.

---

## Arguments

- `scope` - What to scan (optional, defaults to entire project)
  - Path to a directory: Scan only that subtree
  - Feature name: Focus on a specific area
  - No argument: Full project scan
- Optional flags:
  - `--domain [name]` - Pre-assign all discovered capabilities to this domain
  - `--dry-run` - List discovered capabilities without writing specs

---

## Genie Invoked

**Scout** - Discovery specialist combining:
- Deep code reading (source, tests, config, docs)
- Capability identification and grouping
- Evidence-grounded description writing

---

## Context Loading

**READ (automatic):**
- CLAUDE.md
- README.md
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- Source code files (by directory structure and imports)
- Test files (*.test.ts, *.test.js, *.spec.ts, *_test.py, test_*.py, etc.)
- Test config files (package.json, pytest.ini, jest.config.*, vitest.config.*, etc.)
- Config files (for understanding system boundaries)
- docs/specs/**/*.md (to avoid duplicating existing specs)
- docs/backlog/*.md (to cross-reference with capabilities)

**RECALL:**
- Past discovery on related topics
- Existing domain structure in docs/specs/

---

## Context Writing

**WRITE:**
- docs/specs/{domain}/{capability}.md (one per capability, status: active)
- docs/specs/{domain}/README.md (per Domain README Format, for each domain that received new specs)
- docs/architecture/system-context.md (Level 1 C4 diagram — system and external actors)
- docs/architecture/containers.md (Level 2 C4 diagram — high-level containers)

**CREATE (if needed):**
- docs/specs/{domain}/ directories (one per domain assigned by user)
- docs/architecture/components/ directory (Level 3 files created later by `/design`)

---

## Behavior

1. **Deep scan:** Read source code, test files, project docs (README, CLAUDE.md), config files, and directory structure to understand what the system does
2. **Identify capabilities:** Group by behavioral capability — what the system does, not by file or directory boundaries. One top-level behavior = one capability.
3. **Check for existing specs:** Scan `docs/specs/**/*.md` for `type: spec` in frontmatter. If a spec already exists for a capability (matching by id or clear behavioral overlap), skip it and report as "already specified"
4. **Present capabilities in batches:** Show the user a batch of discovered capabilities (up to 5 at a time) with:
   - Proposed capability name
   - Brief description of what it does
   - Key evidence (source files, test files)
   - Suggested acceptance criteria
5. **Ask for domain assignment per batch:** For each batch, present existing domains found in `docs/specs/` subdirectories and ask:
   > Which domain do these capabilities belong to? Existing domains: [{list}]. Or enter a new domain name. You can also assign different domains per capability by number.
6. **Allow user adjustments:** The user can:
   - **Merge** capabilities ("combine 2 and 3")
   - **Skip** capabilities ("skip 4 — not worth a spec")
   - **Rename** capabilities ("rename 1 to session-management")
   - **Adjust descriptions** ("update the description for 2")
   - **Accept as-is** ("looks good" or just provide the domain name)
7. **Write specs:** After user confirms each batch, write spec files directly to `docs/specs/{domain}/{capability}.md` with `status: active`
8. **Generate C4 diagrams:** After all spec batches are processed:
   a. **Level 1 — System Context** (`docs/architecture/system-context.md`): Create diagram showing the system and discovered external actors (from imports, configs, API integrations). Set `updated_by: "/spec:init"`
   b. **Level 2 — Containers** (`docs/architecture/containers.md`): Create diagram showing high-level containers inferred from project structure (e.g., web app, API server, database, background workers). Include initial `## Coupling Notes` from observed dependencies. Set `updated_by: "/spec:init"`
   c. **Level 3 directory** — Create `docs/architecture/components/` directory. Component diagrams are created later by `/design` as domain boundaries become clearer.
   d. These are initial diagrams — `/design` refines them as architecture evolves
   e. **Domain READMEs** — For each domain that received new specs, generate `docs/specs/{domain}/README.md` per the spec-awareness Domain README Format
9. **Summary:** After all batches and diagrams are processed, output a summary of what was created

---

## Output Format

### Per-Batch Presentation

```markdown
## Discovered Capabilities (Batch 1 of N)

### 1. {capability-name}
**Description:** {Rich description of what this capability does, why it exists, and its boundaries}
**Evidence:** {source-file-1}, {source-file-2} | Tests: {test-file} ({N} tests)
**Proposed ACs:**
- AC-1: {behavioral outcome grounded in code and tests}
- AC-2: {behavioral outcome grounded in code and tests}

### 2. {capability-name}
...

**Existing domains:** [{domain-1}, {domain-2}] or "None yet"
**Which domain for this batch?** (or assign per capability: "1:identity, 2:workflow")
```

### Spec Output Format

Each accepted capability produces a spec file:

```yaml
---
spec_version: "1.0"
type: spec
id: {capability-slug}
title: {Capability Name}
status: active
created: {YYYY-MM-DD}
domain: {domain}
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: {behavioral description grounded in code/tests}
    status: pending
  - id: AC-2
    description: {behavioral description grounded in code/tests}
    status: pending
---

# {Capability Name}

{Rich description of what this capability does, why it exists, and its boundaries. Written as product documentation — what behavior the user or system relies on, not implementation details.}

## Acceptance Criteria

### AC-1: {short title}
{Narrative expansion with context — what this criterion means, edge cases, boundaries}

### AC-2: {short title}
{Narrative expansion with context}

## Evidence

### Source Code
- {source-file}: {what it implements}
- {source-file}: {what it implements}

### Tests
- {test-file}: {N} tests covering {behaviors}

### Documentation
- {doc-file}: {relevant context found}
```

### Summary Output

```markdown
## /spec:init Complete

**Project scanned:** {project name}
**Capabilities discovered:** {N total}
**Specs written:** {M} (to docs/specs/{domain}/)
**Already specified:** {K} (skipped)
**Skipped by user:** {J}

### Specs Created
| Capability | Domain | ACs | Evidence Files |
|------------|--------|-----|----------------|
| {name} | {domain} | {N} | {M} |

### Domains
- {domain}: {N} capabilities

### C4 Diagrams Created
| Level | File | Elements |
|-------|------|----------|
| 1 — System Context | docs/architecture/system-context.md | {N} systems, {M} external actors |
| 2 — Container | docs/architecture/containers.md | {N} containers, {M} relationships |
| 3 — Component | docs/architecture/components/ | Directory created (populated by /design) |

### Recommended Next Steps
1. Review specs in docs/specs/{domain}/ for accuracy
2. Review C4 diagrams in docs/architecture/ for completeness
3. Use /define to shape work that changes these capabilities
4. Use /design to create component diagrams and refine containers
5. Use /discover to explore gaps not covered by existing code
```

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/spec:init [scope]` | Full interactive spec initialization |
| `/spec:init --dry-run` | List discovered capabilities without writing |
| `/spec:init --domain [name]` | Pre-assign all capabilities to one domain |

---

## Usage Examples

```
/spec:init
> [Scout scans entire project]
>
> ## Discovered Capabilities (Batch 1 of 3)
>
> ### 1. token-authentication
> **Description:** Issues and validates JWT tokens for API authentication...
> **Evidence:** src/auth/token.ts, src/middleware/auth.ts | Tests: tests/auth.test.ts (12 tests)
> **Proposed ACs:**
> - AC-1: Issues JWT tokens with configurable expiry
> - AC-2: Validates token signatures and expiry on each request
>
> ### 2. session-management
> **Description:** Manages user sessions with cookie-based tracking...
> **Evidence:** src/auth/session.ts | Tests: tests/session.test.ts (8 tests)
> **Proposed ACs:**
> - AC-1: Creates sessions on successful login
> - AC-2: Invalidates sessions on logout
>
> **Existing domains:** None yet
> **Which domain for this batch?**
> > identity
>
> Writing docs/specs/identity/token-authentication.md
> Writing docs/specs/identity/session-management.md
>
> ## Discovered Capabilities (Batch 2 of 3)
> ...

/spec:init src/payments --domain billing
> [Scout scans src/payments/ only, assigns all to "billing" domain]
> Writing docs/specs/billing/payment-processing.md
> Writing docs/specs/billing/refund-handling.md

/spec:init --dry-run
> [Scout lists capabilities without writing]
> Found 8 capabilities across project
> 2 already have specs (skipped)
> 6 would be created
```

---

## Triggers

Run /spec:init when:
- Onboarding a project that has code and tests but no specs
- After a major feature area has been built without spec-first workflow
- When /context:load reports many unspecified capabilities
- When establishing spec-driven development on an existing codebase

---

## Routing

After /spec:init:
- If specs need refinement: Edit them directly
- If work needs shaping: `/define` (will load the spec and document behavioral delta)
- If more discovery needed: `/discover [topic]`

---

## Notes

- Produces rich specs — not thin test inventories
- Reads source code, tests, AND docs for complete understanding
- Interactive — user controls domain assignment, merging, and skipping
- Writes directly to `docs/specs/{domain}/` with `status: active` — no staging area
- Idempotent — skips capabilities that already have specs
- Does not require specs before work starts — incremental adoption is fine
