---
spec_version: "1.0"
type: shaped-work
id: GT-8
title: "/arch:init Command"
status: done
created: 2026-01-27
appetite: small
priority: P2
target_project: genie-team
depends_on: [GT-7]
tags: [architecture, adrs, c4, bootstrapping]
acceptance_criteria:
  - id: AC-1
    description: "/arch:init command file exists at commands/arch-init.md with full behavior specification"
    status: met
  - id: AC-2
    description: "/arch:init reads existing specs/{domain}/ structure and project source to generate C4 diagrams — does NOT re-run spec discovery"
    status: met
  - id: AC-3
    description: "/arch:init creates ADR-000 bootstrapping record if docs/decisions/ADR-000*.md does not exist"
    status: met
  - id: AC-4
    description: "/arch:init generates Level 1 (system-context.md) and Level 2 (containers.md) C4 diagrams with Mermaid syntax, coupling notes, and proper frontmatter"
    status: met
  - id: AC-5
    description: "/arch:init creates architecture/components/ directory for Level 3 diagrams (populated later by /design)"
    status: met
  - id: AC-6
    description: "/arch:init is idempotent — skips artifacts that already exist, warns and continues"
    status: met
  - id: AC-7
    description: "/arch:init appears in /genie:help under a new ARCHITECTURE section"
    status: met
  - id: AC-8
    description: "architecture-awareness SKILL.md updated to reference /arch:init for bootstrapping existing projects"
    status: met
  - id: AC-9
    description: "/context:load recommends /arch:init (not just /spec:init) when specs exist but architecture/ does not"
    status: met
---

# GT-8: /arch:init Command

## Problem

Projects that have already run `/spec:init` have specs but no architecture artifacts. The C4 diagram generation was added to `/spec:init` in GT-7, but that only helps new bootstraps. Running `/spec:init` again on these projects would re-scan capabilities, re-present batches for domain assignment, and skip all existing specs — a lot of redundant interaction just to get to the diagram generation step.

These projects need a direct path to bootstrap:
- `docs/decisions/ADR-000` bootstrapping record
- `architecture/system-context.md` (Level 1)
- `architecture/containers.md` (Level 2)
- `architecture/components/` directory (Level 3 stubs)

The existing domain structure in `specs/` provides all the input needed — no spec discovery required.

## Appetite

Small batch — 1-2 days. One new command file, minor updates to 3 existing files (genie-help, architecture-awareness SKILL, context-load).

## Solution Sketch

### New Command: `/arch:init`

A focused bootstrapping command that reads the existing project structure (especially `specs/{domain}/`) and generates architecture artifacts without touching specs.

**Behavior:**
1. **Pre-check:** Scan for existing architecture artifacts. If `architecture/system-context.md` and `architecture/containers.md` and `docs/decisions/ADR-000*.md` all exist, report "Architecture already bootstrapped" and exit
2. **Read project structure:** CLAUDE.md, README.md, source code directories, config files, `specs/{domain}/` for domain structure
3. **Generate ADR-000:** If `docs/decisions/ADR-000*.md` does not exist, create the bootstrapping record. If it exists, skip and report.
4. **Generate Level 1 — System Context:** Read project docs and config for external actors (APIs, databases, external services). Present diagram to user for confirmation before writing.
5. **Generate Level 2 — Containers:** Infer containers from project structure (e.g., web app, API server, database, workers). Use `specs/{domain}/` to inform domain groupings. Include initial `## Coupling Notes`. Present to user for confirmation.
6. **Create Level 3 directory:** `mkdir architecture/components/`. Note that per-domain component diagrams are created by `/design`.
7. **Summary:** Report what was created, what was skipped, and recommended next steps.

**Key design choices:**
- Interactive — user confirms each diagram before it's written (same pattern as `/spec:init` batches)
- Idempotent — skips artifacts that already exist
- Read-only for specs — never touches `specs/` directory
- Uses existing domain structure from `specs/` but does not require specs to exist (can infer from project structure alone)

### Updates to Existing Files

1. **`commands/genie-help.md`** — Add `/arch:init` under a new ARCHITECTURE section (between SPECS and CONTEXT)
2. **`.claude/skills/architecture-awareness/SKILL.md`** — Add `/arch:init` to the "When Active" list and add a "During /arch:init" behavior section
3. **`commands/context-load.md`** — Change the "No diagrams" recommendation from "run /spec:init" to "run /arch:init to bootstrap architecture diagrams"

## Rabbit Holes

1. **Don't make `/arch:init` generate Level 3 component diagrams.** That's `/design`'s job. `/arch:init` only creates the directory.
2. **Don't scan for ADR-worthy decisions.** `/arch:init` only creates ADR-000 (bootstrapping). Real ADRs come from `/define` and `/design`.
3. **Don't touch specs.** This command reads `specs/` for domain structure but never writes to it.
4. **Don't generate diagrams without user confirmation.** Architecture is too important to auto-generate silently.
5. **Don't fail if specs/ doesn't exist.** The command should work for projects with no specs at all — it infers from project structure.

## Acceptance Criteria

See frontmatter above:

| AC | Scope | Change |
|----|-------|--------|
| AC-1 | New file | Command file with full behavior spec |
| AC-2 | Behavior | Reads specs/{domain}/, does NOT re-run spec discovery |
| AC-3 | Behavior | Creates ADR-000 if missing |
| AC-4 | Behavior | Generates L1 and L2 C4 diagrams with proper schema |
| AC-5 | Behavior | Creates architecture/components/ directory |
| AC-6 | Behavior | Idempotent — skips existing, warns |
| AC-7 | `genie-help.md` | Visible in help under ARCHITECTURE |
| AC-8 | `SKILL.md` | Architecture-awareness references /arch:init |
| AC-9 | `context-load.md` | Recommends /arch:init when specs exist but diagrams don't |

## Handoff

Ready for `/design`. Key design decisions:
- Exact output format for the interactive diagram presentation (before user confirms)
- Whether to present L1 and L2 together or separately for user confirmation
- Exact frontmatter for generated diagrams (`updated_by: "/arch:init"`)

# Design

## Design Summary

4 files affected (1 new, 3 modified). All markdown instruction changes — no executable code.

## File Inventory

| # | File | Action | ACs |
|---|------|--------|-----|
| 1 | `commands/arch-init.md` | Create | AC-1, AC-2, AC-3, AC-4, AC-5, AC-6 |
| 2 | `commands/genie-help.md` | Modify | AC-7 |
| 3 | `.claude/skills/architecture-awareness/SKILL.md` | Modify | AC-8 |
| 4 | `commands/context-load.md` | Modify | AC-9 |

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Present L1 and L2 separately | Separate confirmation for each level | Each diagram has different inputs; user may want to adjust one without redoing the other |
| `updated_by` value | `"/arch:init"` | Consistent with `/spec:init` and `/design` provenance tracking |
| Genie invoked | **Architect** (not Scout) | This is structural inference, not capability discovery |
| ADR-000 content | Same template as `schemas/adr.schema.md` bootstrapping template | Consistent across all projects |

## New File

### 1. `commands/arch-init.md` (AC-1 through AC-6)

Full command file following the pattern of `commands/spec-init.md`:

```markdown
# /arch:init

Activate Architect genie to bootstrap architecture artifacts (ADR-000 and C4 diagrams) for an existing project.

---

## Arguments

- No required arguments
- Optional flags:
  - `--dry-run` - Show what would be created without writing files

---

## Genie Invoked

**Architect** - Structural analysis combining:
- C4 model inference from project structure
- Domain awareness from existing specs
- ADR bootstrapping

---

## Context Loading

**READ (automatic):**
- CLAUDE.md
- README.md
- Source code directories (for container/service inference)
- Config files (for external system detection — database configs, API keys, service URLs)
- specs/{domain}/ directories (for domain structure — does NOT read spec content for capability discovery)
- docs/decisions/ADR-*.md (to check for existing ADRs)
- architecture/**/*.md (to check for existing diagrams)

**DOES NOT READ:**
- Test files for capability identification (that is /spec:init's job)
- Source code for behavioral analysis (that is /spec:init's job)

---

## Context Writing

**WRITE:**
- docs/decisions/ADR-000-use-adrs-for-architecture-decisions.md (if missing)
- architecture/system-context.md (Level 1 — if missing)
- architecture/containers.md (Level 2 — if missing)

**CREATE (if needed):**
- docs/decisions/ directory
- architecture/ directory
- architecture/components/ directory

---

## Behavior

1. **Pre-check:** Scan for existing architecture artifacts:
   - Check `docs/decisions/ADR-000*.md` — exists or missing?
   - Check `architecture/system-context.md` — exists or missing?
   - Check `architecture/containers.md` — exists or missing?
   - Check `architecture/components/` — exists or missing?
   - If ALL exist: Report "Architecture already bootstrapped. Use /design to evolve diagrams and create ADRs." and exit.
   - If SOME exist: Report which exist (will be skipped) and which will be created. Continue.

2. **Read project structure:**
   - CLAUDE.md and README.md for project overview
   - Source code top-level directories for container inference
   - Config files for external system detection (database connections, API URLs, third-party services)
   - `specs/{domain}/` subdirectory names for domain awareness (does NOT read spec file contents for capability discovery)

3. **Create ADR-000** (if `docs/decisions/ADR-000*.md` does not exist):
   - Create `docs/decisions/` directory if needed
   - Write ADR-000 bootstrapping record using the template from `schemas/adr.schema.md`
   - Report: "Created docs/decisions/ADR-000-use-adrs-for-architecture-decisions.md"
   - If exists: Report "ADR-000 already exists — skipped"

4. **Generate Level 1 — System Context** (if `architecture/system-context.md` does not exist):
   - Infer: The system itself, external users/actors, external systems (from config, imports, API references)
   - Present proposed diagram to user:

     ```
     ## Proposed System Context (Level 1)

     System: {project name}
     External Actors:
     - {actor 1}: {description}
     - {actor 2}: {description}
     External Systems:
     - {system 1}: {description}
     - {system 2}: {description}

     Write architecture/system-context.md? [Y/n/edit]
     ```
   - User can accept, skip, or request edits
   - Write with frontmatter: `diagram_version: "1.0"`, `type: architecture-diagram`, `level: 1`, `updated_by: "/arch:init"`
   - If exists: Report "architecture/system-context.md already exists — skipped"

5. **Generate Level 2 — Containers** (if `architecture/containers.md` does not exist):
   - Infer containers from: project directory structure, package.json workspaces, Dockerfile/docker-compose, config files, `specs/{domain}/` groupings
   - Present proposed diagram to user:

     ```
     ## Proposed Container Diagram (Level 2)

     Containers:
     - {container 1}: {technology} — {description}
     - {container 2}: {technology} — {description}
     Relationships:
     - {from} → {to}: {description}

     Coupling Notes:
     - {runtime dependency}
     - {build-time dependency}

     Write architecture/containers.md? [Y/n/edit]
     ```
   - User can accept, skip, or request edits
   - Write with frontmatter: `diagram_version: "1.0"`, `type: architecture-diagram`, `level: 2`, `updated_by: "/arch:init"`
   - Include `## Coupling Notes` section
   - If exists: Report "architecture/containers.md already exists — skipped"

6. **Create Level 3 directory** (if `architecture/components/` does not exist):
   - `mkdir architecture/components/`
   - Report: "Created architecture/components/ — per-domain component diagrams are created by /design"
   - If exists: Report "architecture/components/ already exists — skipped"

7. **Summary:**

   ```
   ## /arch:init Complete

   **ADR-000:** {Created | Already exists}
   **Level 1 — System Context:** {Created | Already exists | Skipped by user}
   **Level 2 — Containers:** {Created | Already exists | Skipped by user}
   **Level 3 — Components directory:** {Created | Already exists}

   ### Recommended Next Steps
   1. Review generated diagrams in architecture/
   2. Use /design to create component diagrams for specific domains
   3. Use /define and /design to create ADRs as architectural decisions arise
   ```

---

## Sub-Commands

None. This is a one-shot bootstrapping command.

---

## Usage Examples

```
/arch:init
> [Architect reads project structure]
>
> Pre-check:
> - ADR-000: missing (will create)
> - Level 1 System Context: missing (will generate)
> - Level 2 Containers: missing (will generate)
> - Level 3 Components directory: missing (will create)
>
> Created docs/decisions/ADR-000-use-adrs-for-architecture-decisions.md
>
> ## Proposed System Context (Level 1)
> System: MyApp
> External Actors:
> - Customer: End user accessing via browser
> - Admin: Internal operations staff
> External Systems:
> - SendGrid: Email delivery
> - Stripe: Payment processing
> - PostgreSQL: Primary database
>
> Write architecture/system-context.md? [Y/n/edit]
> > Y
>
> ## Proposed Container Diagram (Level 2)
> Containers:
> - Web App: React — Single-page application
> - API Server: Node.js/Express — REST API
> - Background Worker: Node.js — Async job processing
> - Database: PostgreSQL — Persistent storage
> - Cache: Redis — Session and cache storage
> Relationships:
> - Web App → API Server: HTTPS/JSON
> - API Server → Database: SQL
> - API Server → Cache: Redis protocol
> - Background Worker → Database: SQL
>
> Write architecture/containers.md? [Y/n/edit]
> > Y
>
> Created architecture/components/
>
> ## /arch:init Complete
> ADR-000: Created
> Level 1: Created
> Level 2: Created
> Level 3 directory: Created
>
> Next: /design to create component diagrams and ADRs

/arch:init
> Pre-check:
> - ADR-000: exists (skipped)
> - Level 1 System Context: exists (skipped)
> - Level 2 Containers: exists (skipped)
> - Level 3 Components directory: exists (skipped)
>
> Architecture already bootstrapped. Use /design to evolve diagrams and create ADRs.

/arch:init --dry-run
> [Architect reads project structure]
>
> Dry run — no files will be written:
> - ADR-000: would be created
> - Level 1 System Context: would be generated (2 actors, 3 external systems)
> - Level 2 Containers: would be generated (5 containers, 4 relationships)
> - Level 3 Components directory: would be created
```

---

## Triggers

Run /arch:init when:
- Project has specs (from /spec:init) but no architecture/ directory
- /context:load reports "No C4 diagrams" with existing specs
- Onboarding architecture tracking to an established project
- After installing genie-team on a project that already has code

---

## Routing

After /arch:init:
- If diagrams need refinement: Edit them directly or use /design
- If ADRs needed: Arise naturally from /define and /design
- If specs missing: Run /spec:init first

---

## Notes

- Bootstrapping only — does NOT evolve existing diagrams (that is /design's job)
- Interactive — user confirms each diagram before writing
- Idempotent — safe to run multiple times, skips existing artifacts
- Read-only for specs — never touches specs/ directory
- Does not require specs to exist — infers from project structure alone
```

## Modifications

### 2. `commands/genie-help.md` (AC-7)

Add ARCHITECTURE section between SPECS and CONTEXT:

**Insert after SPECS section (after line 37), before CONTEXT:**
```
│                                                                 │
│  ARCHITECTURE                                                   │
│  ────────────                                                   │
│  /arch:init          Bootstrap ADRs and C4 diagrams             │
```

### 3. `.claude/skills/architecture-awareness/SKILL.md` (AC-8)

Two changes:

**a. Update description frontmatter (line 3):** Add `/arch:init` to the activates list.

**b. Add to "When Active" list (after line 121):**
```
- `/arch:init` — Bootstrap ADR-000 and initial C4 diagrams for existing projects
```

**c. Add "During /arch:init" behavior section (after the "/spec:init" section, before "/discover"):**
```markdown
### During /arch:init

Bootstraps architecture artifacts for existing projects:

1. Pre-check for existing architecture artifacts (ADR-000, L1, L2, components/)
2. Read project structure and `specs/{domain}/` for domain awareness
3. Create ADR-000 bootstrapping record if missing
4. Generate Level 1 (System Context) and Level 2 (Container) diagrams with user confirmation
5. Create `architecture/components/` directory
6. Does NOT touch specs — reads domain structure only

**Reads:** CLAUDE.md, README.md, source directories, config files, `specs/{domain}/` (directory names only)
**Writes:** `docs/decisions/ADR-000-*.md`, `architecture/system-context.md`, `architecture/containers.md`, `architecture/components/` directory
```

**d. Update Architecture Update Rule 3 (line 317):**
Change from: "Diagrams are updated by /design only — Other commands read diagrams but do not modify them. `/spec:init` creates initial diagrams."
To: "Diagrams are updated by /design only — Other commands read diagrams but do not modify them. `/spec:init` and `/arch:init` create initial diagrams."

### 4. `commands/context-load.md` (AC-9)

**Change line 24** from:
```
If `architecture/` does not exist, report "No C4 diagrams — run /spec:init to generate initial diagrams"
```
To:
```
If `architecture/` does not exist: if `specs/` exists, report "No C4 diagrams — run /arch:init to bootstrap architecture diagrams"; if `specs/` also does not exist, report "No C4 diagrams — run /spec:init to bootstrap specs and diagrams"
```

## Implementation Order

1. Create `commands/arch-init.md` (AC-1 through AC-6)
2. Update `commands/genie-help.md` (AC-7)
3. Update `.claude/skills/architecture-awareness/SKILL.md` (AC-8)
4. Update `commands/context-load.md` (AC-9)
5. Sync to `.claude/commands/`
6. Verify coherence

# Implementation

## Implementation Summary

4 files delivered (1 new, 3 modified). All markdown instruction files.

## Files Created

| # | File | ACs |
|---|------|-----|
| 1 | `commands/arch-init.md` | AC-1, AC-2, AC-3, AC-4, AC-5, AC-6 |

## Files Modified

| # | File | ACs |
|---|------|-----|
| 2 | `commands/genie-help.md` | AC-7 — Added ARCHITECTURE section with /arch:init |
| 3 | `.claude/skills/architecture-awareness/SKILL.md` | AC-8 — Added /arch:init to When Active, description, behavior section, and update rule 3 |
| 4 | `commands/context-load.md` | AC-9 — Smart recommendation: /arch:init when specs exist, /spec:init when nothing exists |

## Synced

- `commands/arch-init.md` → `.claude/commands/arch-init.md`
- `commands/genie-help.md` → `.claude/commands/genie-help.md`
- `commands/context-load.md` → `.claude/commands/context-load.md`

# Review

## Verdict: APPROVED

All 9 acceptance criteria met. Reviewed by Critic genie.

## AC Verification

| AC | Description | Verdict | Evidence |
|----|-------------|---------|----------|
| AC-1 | Command file at commands/arch-init.md | MET | 251-line file with Arguments, Genie Invoked, Context Loading, Context Writing, Behavior (7 steps), Sub-Commands, Usage Examples, Triggers, Routing, Notes |
| AC-2 | Reads specs/{domain}/ without re-running spec discovery | MET | Context Loading has explicit "DOES NOT READ" section excluding test files and source code behavioral analysis; reads `specs/{domain}/` for domain structure only |
| AC-3 | Creates ADR-000 if missing | MET | Behavior step 3 creates ADR-000 using `schemas/adr.schema.md` template, skips if exists |
| AC-4 | Generates L1 and L2 C4 diagrams with frontmatter | MET | Behavior steps 4-5 generate system-context.md (L1) and containers.md (L2) with `diagram_version`, `type`, `level`, `updated_by` frontmatter; L2 includes Coupling Notes |
| AC-5 | Creates architecture/components/ directory | MET | Behavior step 6 creates directory with note that per-domain diagrams are created by /design |
| AC-6 | Idempotent — skips existing, warns | MET | Behavior step 1 pre-checks all 4 artifacts; "ALL exist" exits early; "SOME exist" skips existing and creates missing; each step has "If exists" skip clause |
| AC-7 | Visible in /genie:help under ARCHITECTURE | MET | ARCHITECTURE section added between SPECS and CONTEXT in genie-help.md |
| AC-8 | architecture-awareness SKILL.md references /arch:init | MET | 4 changes: description frontmatter, When Active list, "During /arch:init" behavior section, update rule 3 |
| AC-9 | context-load recommends /arch:init when specs exist | MET | Conditional logic: specs exist + no diagrams → /arch:init; neither exists → /spec:init |

## Notes

- Command spec uses text outline format for diagram presentation (not inline Mermaid blocks). This is appropriate — the Architect genie generates actual Mermaid syntax at runtime using architecture-awareness SKILL.md as its reference.
- All 3 synced command files verified present in `.claude/commands/`.

# End of Shaped Work Contract
