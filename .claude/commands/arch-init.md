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
- docs/architecture/**/*.md (to check for existing diagrams)

**DOES NOT READ:**
- Test files for capability identification (that is /spec:init's job)
- Source code for behavioral analysis (that is /spec:init's job)

---

## Context Writing

**WRITE:**
- docs/decisions/ADR-000-use-adrs-for-architecture-decisions.md (if missing)
- docs/architecture/system-context.md (Level 1 — if missing)
- docs/architecture/containers.md (Level 2 — if missing)

**CREATE (if needed):**
- docs/decisions/ directory
- docs/architecture/ directory
- docs/architecture/components/ directory

---

## Behavior

1. **Pre-check:** Scan for existing architecture artifacts:
   - Check `docs/decisions/ADR-000*.md` — exists or missing?
   - Check `docs/architecture/system-context.md` — exists or missing?
   - Check `docs/architecture/containers.md` — exists or missing?
   - Check `docs/architecture/components/` — exists or missing?
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

4. **Generate Level 1 — System Context** (if `docs/architecture/system-context.md` does not exist):
   - Infer: The system itself, external users/actors, external systems (from config, imports, API references)
   - Present proposed diagram to user:

     ````
     ## Proposed System Context (Level 1)

     ```mermaid
     C4Context
         title System Context - {project name}

         Person({actor_alias}, "{Actor}", "{description}")

         System({system_alias}, "{Project Name}", "{description}")

         System_Ext({ext_alias}, "{External System}", "{description}")

         Rel({from}, {to}, "{label}")
     ```

     Write docs/architecture/system-context.md? [Y/n/edit]
     ````
   - User can accept, skip, or request edits
   - Write with frontmatter: `diagram_version: "1.0"`, `type: architecture-diagram`, `level: 1`, `updated_by: "/arch:init"`
   - If exists: Report "docs/architecture/system-context.md already exists — skipped"

5. **Generate Level 2 — Containers** (if `docs/architecture/containers.md` does not exist):
   - Infer containers from: project directory structure, package.json workspaces, Dockerfile/docker-compose, config files, `specs/{domain}/` groupings
   - Present proposed diagram to user:

     ````
     ## Proposed Container Diagram (Level 2)

     ```mermaid
     C4Container
         title Container Diagram - {project name}

         Person({actor_alias}, "{Actor}", "{description}")

         System_Boundary({boundary}, "{Project Name}") {
             Container({alias}, "{Name}", "{Technology}", "{description}")
             ContainerDb({alias}, "{Name}", "{Technology}", "{description}")
         }

         System_Ext({ext_alias}, "{External System}", "{description}")

         Rel({from}, {to}, "{label}", "{protocol}")
     ```

     Coupling Notes:
     - {runtime dependency}
     - {build-time dependency}

     Write docs/architecture/containers.md? [Y/n/edit]
     ````
   - User can accept, skip, or request edits
   - Write with frontmatter: `diagram_version: "1.0"`, `type: architecture-diagram`, `level: 2`, `updated_by: "/arch:init"`
   - Include `## Coupling Notes` section
   - If exists: Report "docs/architecture/containers.md already exists — skipped"

6. **Create Level 3 directory** (if `docs/architecture/components/` does not exist):
   - `mkdir docs/architecture/components/`
   - Report: "Created docs/architecture/components/ — per-domain component diagrams are created by /design"
   - If exists: Report "docs/architecture/components/ already exists — skipped"

7. **Summary:**

   ```
   ## /arch:init Complete

   **ADR-000:** {Created | Already exists}
   **Level 1 — System Context:** {Created | Already exists | Skipped by user}
   **Level 2 — Containers:** {Created | Already exists | Skipped by user}
   **Level 3 — Components directory:** {Created | Already exists}

   ### Recommended Next Steps
   1. Review generated diagrams in docs/architecture/
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
>
> ```mermaid
> C4Context
>     title System Context - MyApp
>
>     Person(customer, "Customer", "End user accessing via browser")
>     Person(admin, "Admin", "Internal operations staff")
>
>     System(myapp, "MyApp", "Main application")
>
>     System_Ext(sendgrid, "SendGrid", "Email delivery")
>     System_Ext(stripe, "Stripe", "Payment processing")
>     SystemDb(postgres, "PostgreSQL", "Primary database")
>
>     Rel(customer, myapp, "Uses", "HTTPS")
>     Rel(admin, myapp, "Manages", "HTTPS")
>     Rel(myapp, sendgrid, "Sends emails", "SMTP")
>     Rel(myapp, stripe, "Processes payments", "HTTPS")
>     Rel(myapp, postgres, "Reads/writes", "SQL")
> ```
>
> Write docs/architecture/system-context.md? [Y/n/edit]
> > Y
>
> ## Proposed Container Diagram (Level 2)
>
> ```mermaid
> C4Container
>     title Container Diagram - MyApp
>
>     Person(customer, "Customer", "End user")
>
>     System_Boundary(myapp, "MyApp") {
>         Container(web, "Web App", "React", "Single-page application")
>         Container(api, "API Server", "Node.js/Express", "REST API")
>         Container(worker, "Background Worker", "Node.js", "Async job processing")
>         ContainerDb(db, "Database", "PostgreSQL", "Persistent storage")
>         ContainerDb(cache, "Cache", "Redis", "Session and cache storage")
>     }
>
>     Rel(customer, web, "Uses", "HTTPS")
>     Rel(web, api, "Calls", "HTTPS/JSON")
>     Rel(api, db, "Reads/writes", "SQL")
>     Rel(api, cache, "Sessions", "Redis protocol")
>     Rel(worker, db, "Reads/writes", "SQL")
> ```
>
> Coupling Notes:
> - Runtime: Web App → API Server (synchronous HTTPS)
> - Runtime: API Server → Database, Cache (synchronous)
> - Async: Background Worker → Database (polling)
>
> Write docs/architecture/containers.md? [Y/n/edit]
> > Y
>
> Created docs/architecture/components/
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
- Project has specs (from /spec:init) but no docs/architecture/ directory
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
