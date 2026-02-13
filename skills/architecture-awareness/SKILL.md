---
name: architecture-awareness
description: Ensures ADR and C4 diagram behaviors during all workflows. Use when loading context, discussing architecture, creating designs, or when "ADR", "architecture decision", "C4", "coupling", "cohesion", or "boundary" are mentioned. Activates during /arch:init, /context:load, /context:refresh, /spec:init, /define, /design, /deliver, /discern, /handoff, /diagnose, and /discover.
allowed-tools: Read, Glob, Grep
---

# Architecture Awareness

Architecture knowledge lives in two artifact types that complement specs:

```
     SPEC (WHAT)
    /           \
   /             \
ADR (HOW+WHY) -- C4 (CONTEXT MAP)
```

- **Specs** describe WHAT the system does (capabilities, acceptance criteria)
- **ADRs** describe HOW the system is built and WHY those technical choices were made
- **C4 Diagrams** provide the CONTEXT MAP — how everything relates structurally

All three are persistent, first-class artifacts. Backlog items are transient; these are not.

## ADR Organization

Architecture Decision Records capture significant technical decisions using the Michael Nygard pattern.

### Directory Structure

```
docs/decisions/
  ADR-000-use-adrs-for-architecture-decisions.md   # bootstrapping record
  ADR-001-{slug}.md
  ADR-002-{slug}.md
```

Flat directory. No subdirectories. The `domain` field in frontmatter provides domain association.

### Frontmatter Schema

> Schema: `schemas/adr.schema.md` v1.0

Required: `adr_version`, `type: adr`, `id` (ADR-NNN), `title`, `status`, `created`, `deciders`
Optional: `domain`, `spec_refs`, `backlog_ref`, `superseded_by`, `supersedes`, `tags`

### ADR Lifecycle

```
/define (proposed) → /design (accepted) → [lives indefinitely]
                                        → /design (superseded by new ADR)
                                        → /design (deprecated if no longer relevant)
```

- **proposed** — Created by `/define` when a behavioral delta involves an architectural choice
- **accepted** — Created or promoted by `/design` after evaluating alternatives
- **deprecated** — Decision no longer relevant (e.g., feature removed). Set by `/design`
- **superseded** — A newer ADR replaces this one. `superseded_by` points to the replacement

### ADR Creation Threshold

Create an ADR ONLY when BOTH conditions are true:

1. **Multiple viable alternatives exist** — There is a genuine choice between approaches
2. **Hard to reverse OR affects multiple domains** — The decision has lasting consequences

Do NOT create ADRs for: trivial decisions, single-option choices, easily reversible choices, or implementation details within a single component.

### Numbering Convention

Sequential 3-digit zero-padded: `ADR-000`, `ADR-001`, `ADR-002`, etc.
To determine the next number: scan `docs/decisions/ADR-*.md` and increment the highest found.

## C4 Diagram Organization

C4 Mermaid diagrams provide the contextual map — how everything relates structurally.

### Directory Structure

```
docs/architecture/
  system-context.md          # Level 1: System and external actors
  containers.md              # Level 2: High-level containers/services
  components/                # Level 3: Per-domain component diagrams
    {domain}.md              # One per domain, parallels docs/specs/{domain}/
```

### Frontmatter Schema

> Schema: `schemas/architecture-diagram.schema.md` v1.0

Required: `diagram_version`, `type: architecture-diagram`, `level` (1-3), `title`, `updated`, `updated_by`
Optional: `domain` (L3 only), `backlog_ref`, `adr_refs`, `tags`

### C4 Levels

| Level | File | Scope |
|-------|------|-------|
| 1 — System Context | `docs/architecture/system-context.md` | System and external actors |
| 2 — Container | `docs/architecture/containers.md` | High-level containers/services |
| 3 — Component | `docs/architecture/components/{domain}.md` | Per-domain components |

Level 4 (Code) is NOT supported. Source code is the code-level diagram.

### Diagram Format

Each diagram file contains:
- YAML frontmatter with `type: architecture-diagram`
- Mermaid flowchart diagram with **Neon Dark** styling (dark backgrounds, neon accent colors)
- Infrastructure context subgraphs (USERS, SYSTEM, EXTERNAL, etc.)
- Nodes with bold titles, responsibility descriptions, and tech stack
- `## Coupling Notes` section — runtime, build-time, and data dependencies
- `## Cohesion Assessment` section — rates domain cohesion (HIGH/MEDIUM/LOW) with justification (Level 3 only)

### Diagram Style Reference

See `schemas/architecture-diagram.schema.md` for full color palette and node format.

**Node format:**
```
["<b>Title</b><br/> <br/><span>Responsibility</span><br/><span>Technology</span>"]
```

**Key colors:**
- Actors: `#ff2e97` (hot pink) on `#2a0f1e`
- Core system: `#00fff5` (cyan) on `#0d2a2a`
- Services: `#b967ff` (purple) on `#1f0d2e`
- External: `#9d4edd` (violet) on `#1a0d24`

### Staleness Threshold

Diagrams not updated within **90 days** are flagged as potentially stale by `/context:load` and `/diagnose`.

## When Active

This skill activates during:
- `/arch:init` — Bootstrap ADR-000 and initial C4 diagrams for existing projects
- `/context:load` — Report ADR count by status and diagram staleness
- `/context:refresh` — Detect drift between diagrams and code structure
- `/spec:init` — Generate initial C4 diagrams (L1-L2) from discovered domains
- `/define` — Create proposed ADRs when behavioral delta involves an architectural choice
- `/design` — Create accepted ADRs; update C4 diagrams when boundaries change
- `/deliver` — Read ADRs for implementation context (WHY constraints exist)
- `/discern` — Verify ADR compliance; check for boundary violations
- `/handoff` — Inject ADR-specific transition guidance into handoff output
- `/diagnose` — Coupling violations, cohesion drift, ADR health, diagram staleness
- `/discover` — Surface existing ADRs as context for exploration

## Behaviors

### Common: ADR Loading Pattern

All commands that read ADRs follow this pattern:

1. Check for `adr_refs` in the backlog item or design document frontmatter
2. If `adr_refs` is present: Read each referenced ADR file from `docs/decisions/`
3. If `adr_refs` is missing: Scan `docs/decisions/ADR-*.md` for ADRs matching the domain or tags
4. If `docs/decisions/` does not exist: **Warn** and continue:
   > No ADRs directory found. Architecture decisions are not being tracked.
5. **Never block** — ADRs are valuable but optional. All commands warn and continue.

### Common: C4 Diagram Loading Pattern

All commands that read C4 diagrams follow this pattern:

1. Check for `docs/architecture/` directory
2. If present: Read relevant diagram files based on scope (L1-L2 for broad context, L3 for domain-specific)
3. If missing: **Warn** and continue:
   > No architecture directory found. C4 diagrams are not being maintained.
4. **Never block** — diagrams are valuable but optional. All commands warn and continue.

### During /define (AC-3)

Creates proposed ADRs when a behavioral delta involves an architectural choice:

1. While analyzing the behavioral delta, check if the change involves a HOW decision (not just WHAT changes)
2. Apply the **ADR Creation Threshold** — both conditions must be true
3. If threshold met:
   a. Determine next ADR number by scanning `docs/decisions/ADR-*.md`
   b. Create `docs/decisions/ADR-{NNN}-{slug}.md` with `status: proposed`
   c. Fill in **Context** and **Alternatives Considered** sections (captured while the problem is fresh)
   d. Leave **Decision** section with placeholder: "To be determined by /design"
   e. Add `adr_refs` to the backlog item frontmatter
4. If threshold not met: No ADR created. Proceed normally.

**Reads:** `docs/decisions/ADR-*.md` (for numbering and dedup)
**Writes:** `docs/decisions/ADR-{NNN}-{slug}.md` (proposed), backlog frontmatter `adr_refs`

### During /design (AC-2, AC-7)

Creates accepted ADRs and updates C4 diagrams:

**ADR Behavior:**
1. Load existing ADRs via common pattern (especially any `proposed` ADRs from `/define`)
2. For each significant technical decision during design:
   a. Apply ADR Creation Threshold
   b. If a `proposed` ADR exists for this decision: Complete the **Decision** section, update `status: accepted`
   c. If no ADR exists: Create new `docs/decisions/ADR-{NNN}-{slug}.md` with `status: accepted`
   d. If design supersedes an existing decision: Create new ADR, update old ADR with `status: superseded` and `superseded_by`
3. Add `adr_refs` to the design document and backlog item frontmatter

**C4 Diagram Behavior:**
1. Load existing diagrams via common pattern
2. If design changes structural boundaries (new containers, new components, changed relationships):
   a. Update the affected diagram file(s)
   b. Update flowchart arrows (`-->`) to reflect new dependencies
   c. Update `## Coupling Notes` section
   d. Update frontmatter: `updated` date, `updated_by: "/design"`, `backlog_ref`
3. If no structural changes: Leave diagrams unchanged

**Reads:** `docs/decisions/ADR-*.md`, `docs/architecture/**/*.md`
**Writes:** `docs/decisions/ADR-{NNN}-{slug}.md`, `docs/architecture/**/*.md` frontmatter and body

### During /deliver (AC-4)

Reads ADRs for implementation context — does NOT create or modify them:

1. Load ADRs via common pattern (from design `adr_refs` or domain scan)
2. Surface relevant decisions that constrain implementation:
   - Technology choices (e.g., "ADR-001 specifies JWT refresh tokens, not sessions")
   - Boundary constraints (e.g., "ADR-003 requires auth to stay in its own service")
3. Reference ADR ids in implementation notes when decisions guide choices
4. If an implementation approach would violate an accepted ADR: **Warn** prominently
5. **Transition guidance** (conditional):
   a. If `adr_refs` exist in backlog item frontmatter:
      > **ADR compliance:** This work references {N} architecture decision(s). Ensure the approach aligns with each accepted decision. Violations will be flagged during /discern review.

**Reads:** `docs/decisions/ADR-*.md`, `docs/architecture/components/{domain}.md`
**Writes:** Nothing (read-only for architecture artifacts)

### During /discern (AC-4)

Verifies ADR compliance and checks for boundary violations:

1. Load ADRs via common pattern
2. Add **ADR Compliance** to the review checklist:
   - For each referenced ADR: Does the implementation follow the decision?
   - Flag any violations (implementation contradicts accepted ADR)
3. Load component diagram for the domain (if exists)
4. Check for boundary violations: Does the implementation introduce dependencies not documented in the diagram?
5. Output ADR Compliance table:

```
| ADR | Decision | Compliant? | Notes |
|-----|----------|------------|-------|
| ADR-001 | JWT refresh tokens | YES | Implemented as specified |
| ADR-003 | Auth service boundary | VIOLATION | Direct DB access bypasses service |
```

**Reads:** `docs/decisions/ADR-*.md`, `docs/architecture/components/{domain}.md`
**Writes:** Nothing (compliance output goes in the review document, not in ADRs)

### During /diagnose (AC-8)

Primary consumer of architecture artifacts for health analysis:

**Coupling Analysis:**
1. Load container diagram (`docs/architecture/containers.md`) and component diagrams
2. Parse flowchart arrows (`-->`) from Mermaid diagrams to build declared dependency graph
3. Scan source code for actual import/dependency patterns (heuristic: directory + import scanning)
4. Compare: Flag undocumented dependencies (code imports not in diagram) and stale dependencies (diagram arrows with no code evidence)

**Cohesion Analysis:**
1. Load component diagrams for each domain
2. Check whether components import mostly within their domain (high cohesion) or heavily across domains
3. Compare against `## Cohesion Assessment` ratings — flag mismatches

**ADR Health:**
1. Scan all ADRs in `docs/decisions/`
2. Flag: proposed ADRs with no recent `/design` activity, contradictory accepted ADRs, superseded ADRs still referenced by active code

**Diagram Staleness:**
1. Check `updated` field in each diagram's frontmatter
2. Flag diagrams not updated within 90 days as potentially stale

**Reads:** `docs/decisions/ADR-*.md`, `docs/architecture/**/*.md`, source code imports
**Writes:** Nothing (findings go in the diagnose report)

### During /spec:init (AC-6)

Generates initial C4 diagrams from discovered domains:

1. After domain discovery and spec creation, generate C4 diagrams:
   a. **Level 1** — `docs/architecture/system-context.md`: System and discovered external actors
   b. **Level 2** — `docs/architecture/containers.md`: High-level containers inferred from project structure
   c. **Level 3 directory** — `mkdir docs/architecture/components/` (files created later by `/design`)
2. Set frontmatter: `updated_by: "/spec:init"`, current date
3. Include `## Coupling Notes` with initial observations from project structure
4. These are initial diagrams — `/design` refines them as architecture evolves

**Reads:** Project structure, discovered domains
**Writes:** `docs/architecture/system-context.md`, `docs/architecture/containers.md`, `docs/architecture/components/` directory

### During /arch:init

Bootstraps architecture artifacts for existing projects:

1. Pre-check for existing architecture artifacts (ADR-000, L1, L2, components/)
2. Read project structure and `docs/specs/{domain}/` for domain awareness
3. Create ADR-000 bootstrapping record if missing
4. Generate Level 1 (System Context) and Level 2 (Container) diagrams with user confirmation
5. Create `docs/architecture/components/` directory
6. Does NOT touch specs — reads domain structure only

**Reads:** CLAUDE.md, README.md, source directories, config files, `docs/specs/{domain}/` (directory names only)
**Writes:** `docs/decisions/ADR-000-*.md`, `docs/architecture/system-context.md`, `docs/architecture/containers.md`, `docs/architecture/components/` directory

### During /discover

Surfaces existing ADRs as context for exploration:

1. Scan `docs/decisions/ADR-*.md` for ADRs related to the discovery topic
2. Include relevant ADR summaries in the Architecture Context section of output
3. Note: Does not create or modify ADRs

**Reads:** `docs/decisions/ADR-*.md`
**Writes:** Nothing (read-only)

### During /handoff

Injects ADR-specific transition guidance into handoff output:

1. Load ADRs via common pattern
2. If ADRs found relevant to the work:
   a. For `design → deliver` handoff:
      > **ADR context for Crafter:** {N} architecture decision(s) constrain this work: {list ADR ids + 1-line summaries}. Implementation must align with these decisions.
   b. For `deliver → discern` handoff:
      > **ADR context for Critic:** {If adr_refs exist: "Verify ADR compliance for: {list ADR ids}. Check for boundary violations."}
3. If no ADRs: Silently continue (no guidance injected)

**Reads:** `docs/decisions/ADR-*.md`
**Writes:** Nothing (read-only — guidance injection only)

### During /context:load (AC-9)

Reports architecture artifact status:

1. Scan `docs/decisions/ADR-*.md` — count by status (proposed, accepted, deprecated, superseded)
2. Scan `docs/architecture/**/*.md` — check `updated` dates against 90-day threshold
3. Report in Architecture section of output:
   - ADR count by status
   - Diagram staleness warnings
   - Recommendations: "No ADRs found — consider creating ADR-000 via /design"

**Reads:** `docs/decisions/ADR-*.md`, `docs/architecture/**/*.md`
**Writes:** Nothing (read-only)

### During /context:refresh (AC-9)

Detects drift between diagrams and code structure:

1. Load C4 diagrams
2. Compare diagram containers/components against actual project structure
3. Flag drift: new directories/services not in diagrams, diagram elements with no code evidence
4. Report in Diagram Drift section of output:
   - Containers/components in diagram but not in code
   - Code structures not reflected in diagrams
   - Recommended updates

**Reads:** `docs/architecture/**/*.md`, project directory structure
**Writes:** Nothing (read-only — drift is reported, humans and `/design` fix it)

## Architecture Update Rules (All Commands)

These rules apply to ALL commands that interact with architecture artifacts:

1. **Warn, never block** — Missing ADRs or diagrams are warnings, not workflow blockers
2. **ADR threshold is strict** — Only create ADRs when both conditions are met (multiple alternatives AND hard to reverse or cross-domain)
3. **Diagrams are updated by /design only** — Other commands read diagrams but do not modify them. `/spec:init` and `/arch:init` create initial diagrams.
4. **ADR statuses are managed by /define and /design only** — `/define` creates `proposed`, `/design` creates `accepted` or changes status
5. **Domain is a human decision** — Same as specs. Never auto-assign domains for component diagrams
6. **Drift is detected, not prevented** — `/context:refresh` and `/diagnose` report drift. Humans and `/design` update diagrams
7. **ADRs explain boundaries** — When `/diagnose` detects coupling violations, reference the ADR that established that boundary

## What This Skill Does NOT Do

- Does NOT block any workflow — only warns and informs
- Does NOT auto-generate ADRs for every design decision — strict threshold applies
- Does NOT auto-sync diagrams with code — drift is detected, not prevented
- Does NOT support C4 Level 4 (Code) — source code is the code-level diagram
- Does NOT put ADRs inside specs — different lifecycle, different purpose
- Does NOT auto-detect domains for component diagrams — domain is a human decision
- Does NOT validate Mermaid syntax — rendering issues are warnings, not blockers
