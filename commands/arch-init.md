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
