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
- docs/specs/{domain}/ directories (for domain structure — does NOT read spec content for capability discovery)
- docs/decisions/ADR-*.md (to check for existing ADRs)
- docs/architecture/**/*.md (to check for existing diagrams)
- Stack indicator files: `tsconfig.json`, `go.mod`, `Cargo.toml`, `*.csproj`, `pom.xml`, `build.gradle` (for tech stack detection)
- Stack profile templates: `stacks/*.md` (from genie-team install, for generating stack configuration)

**DOES NOT READ:**
- Test files for capability identification (that is /spec:init's job)
- Source code for behavioral analysis (that is /spec:init's job)

---

## Context Writing

**WRITE:**
- docs/decisions/ADR-000-use-adrs-for-architecture-decisions.md (if missing)
- docs/architecture/system-context.md (Level 1 — if missing)
- docs/architecture/containers.md (Level 2 — if missing)
- .claude/rules/stack-{language}.md (per detected stack — if missing)
- CLAUDE.md `## Tech Stack` section (append — if stack detected)
- .claude/settings.json (merge permissions — if stack detected)

**CREATE (if needed):**
- docs/decisions/ directory
- docs/architecture/ directory
- docs/architecture/components/ directory

---

## Diagram Style

All C4 diagrams use the **Neon Dark** flowchart style with:
- Dark muted backgrounds complementing neon accent strokes
- Bold titles with padding, followed by responsibility descriptions and tech stack
- Infrastructure context subgraphs showing runtime boundaries
- Visible neon-colored connector lines

### Theme Configuration

```mermaid
%%{init: {"theme": "base", "themeVariables": {
  "fontFamily": "system-ui, sans-serif",
  "lineColor": "#ff2e97",
  "primaryColor": "#0d2a2a",
  "primaryTextColor": "#ffffff",
  "primaryBorderColor": "#00fff5",
  "secondaryColor": "#120a18",
  "secondaryTextColor": "#ff2e97",
  "secondaryBorderColor": "#ff2e97",
  "tertiaryColor": "#0a1215",
  "tertiaryTextColor": "#9d4edd",
  "tertiaryBorderColor": "#9d4edd"
}}}%%
```

### Color Palette

| Role | Stroke | Fill | Use |
|------|--------|------|-----|
| Actor/Person | `#ff2e97` | `#2a0f1e` | Users, external actors |
| System Core | `#00fff5` | `#0d2a2a` | Main system, primary containers |
| Commands | `#01cdfe` | `#0a2830` | Entry points, APIs |
| Agents/Services | `#b967ff` | `#1f0d2e` | Internal services, workers |
| External | `#9d4edd` | `#1a0d24` | External systems, APIs |
| Output/Success | `#39ff14` | `#0d1f0d` | Outputs, artifacts |

### Node Format

Each node includes three lines with title padding:
```
["<b>Title</b><br/> <br/><span>Responsibility description</span><br/><span>Technology stack</span>"]
```

### Edge Labels

All relationship arrows MUST include labels explaining what flows:
```
actor -->|"invokes"| system
system -->|"reads/writes"| datastore
system -->|"calls"| external_api
```

---

## Specificity Requirements

Diagrams must communicate concrete details, not abstract generalizations. Every node must answer: **"What specifically is this, where does it run, and how does it connect?"**

### Bad vs Good Examples

| Element | BAD (vague) | GOOD (specific) |
|---------|-------------|-----------------|
| Actor interface | "Terminal" | "macOS/Linux Terminal" or "VS Code Integrated Terminal" |
| File storage | "File System" | "Local FS (macOS/Linux)" or "Git Repository" |
| Generic codebase | "Project Codebase" | "Target Project (local git repo)" |
| Cloud service | "Cloud Platform" | "AWS us-east-1" or "Vercel Edge" |
| Database | "Database" | "PostgreSQL 15 (RDS)" or "SQLite (local)" |
| API | "External API" | "Stripe API (HTTPS)" or "GitHub REST API v3" |

### Runtime Environment Specificity

For each node, specify WHERE it runs:
- **CLI tools**: "Developer machine (macOS/Linux)"
- **Web apps**: "Browser (Chrome, Safari, Firefox)"
- **Servers**: "AWS EC2", "Vercel Serverless", "Docker container"
- **Databases**: "AWS RDS", "Local PostgreSQL", "Supabase"

### External System Completeness

Identify ALL external dependencies, including:
- **APIs the system calls** (e.g., "Anthropic API" for Claude-based tools)
- **Authentication providers** (e.g., "Auth0", "GitHub OAuth")
- **Infrastructure services** (e.g., "AWS S3", "Cloudflare CDN")
- **Monitoring/logging** (e.g., "Datadog", "Sentry")

A system that makes HTTP calls to an external API MUST show that API as an external system.

### Technology Stack Specificity

Avoid generic technology names:
| BAD | GOOD |
|-----|------|
| "Node.js" | "Node.js 20 LTS" |
| "React" | "React 18 + TypeScript" |
| "PostgreSQL" | "PostgreSQL 15" |
| "REST API" | "REST API (Express.js)" |

For CLI tools or prompt-based systems, specify the execution model:
| BAD | GOOD |
|-----|------|
| "Prompts" | "Markdown prompt templates" |
| "Commands" | "Claude Code slash commands" |
| "AI" | "Claude API (claude-3-opus)" |

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
   - `docs/specs/{domain}/` subdirectory names for domain awareness (does NOT read spec file contents for capability discovery)

3. **Create ADR-000** (if `docs/decisions/ADR-000*.md` does not exist):
   - Create `docs/decisions/` directory if needed
   - Write ADR-000 bootstrapping record using the template from `schemas/adr.schema.md`
   - Report: "Created docs/decisions/ADR-000-use-adrs-for-architecture-decisions.md"
   - If exists: Report "ADR-000 already exists — skipped"

4. **Generate Level 1 — System Context** (if `docs/architecture/system-context.md` does not exist):
   - Infer: The system itself, external users/actors, external systems (from config, imports, API references)
   - **IMPORTANT:** Identify ALL external APIs the system calls (e.g., if it uses Claude, show "Anthropic API")
   - Present proposed diagram to user:

     ````
     ## Proposed System Context (Level 1)

     ```mermaid
     %%{init: {"theme": "base", "themeVariables": {
       "fontFamily": "system-ui, sans-serif",
       "lineColor": "#ff2e97",
       "primaryColor": "#0d2a2a",
       "primaryTextColor": "#ffffff",
       "primaryBorderColor": "#00fff5",
       "secondaryColor": "#120a18",
       "secondaryTextColor": "#ff2e97",
       "secondaryBorderColor": "#ff2e97",
       "tertiaryColor": "#0a1215",
       "tertiaryTextColor": "#9d4edd",
       "tertiaryBorderColor": "#9d4edd"
     }}}%%
     flowchart TB
         classDef actor fill:#2a0f1e,stroke:#ff2e97,stroke-width:2px,color:#ff2e97
         classDef core fill:#0d2a2a,stroke:#00fff5,stroke-width:3px,color:#00fff5
         classDef external fill:#1a0d24,stroke:#9d4edd,stroke-width:2px,color:#9d4edd

         subgraph users ["USERS"]
             actor1["<b>Actor Name</b><br/> <br/><span>Specific role description</span><br/><span>Specific interface (e.g., macOS Terminal)</span>"]:::actor
         end

         subgraph system_boundary ["SYSTEM NAME"]
             system["<b>System Name</b><br/> <br/><span>Specific responsibility</span><br/><span>Specific tech (e.g., Node.js 20 CLI)</span>"]:::core
         end

         subgraph external_systems ["EXTERNAL"]
             ext1["<b>Specific External System</b><br/> <br/><span>Specific integration purpose</span><br/><span>Specific protocol (e.g., HTTPS REST)</span>"]:::external
         end

         actor1 -->|"action verb"| system
         system -->|"action verb"| ext1
     ```

     Write docs/architecture/system-context.md? [Y/n/edit]
     ````
   - User can accept, skip, or request edits
   - Write with frontmatter: `diagram_version: "2.0"`, `type: architecture-diagram`, `level: 1`, `updated_by: "/arch:init"`
   - If exists: Report "docs/architecture/system-context.md already exists — skipped"

5. **Generate Level 2 — Containers** (if `docs/architecture/containers.md` does not exist):
   - Infer containers from: project directory structure, package.json workspaces, Dockerfile/docker-compose, config files, `docs/specs/{domain}/` groupings
   - **IMPORTANT:** Use specific technology versions, specific deployment targets, and labeled edges
   - Present proposed diagram to user:

     ````
     ## Proposed Container Diagram (Level 2)

     ```mermaid
     %%{init: {"theme": "base", "themeVariables": {
       "fontFamily": "system-ui, sans-serif",
       "lineColor": "#01cdfe",
       "primaryColor": "#1f0d2e",
       "primaryTextColor": "#ffffff",
       "primaryBorderColor": "#b967ff",
       "secondaryColor": "#0f1a1e",
       "secondaryTextColor": "#01cdfe",
       "secondaryBorderColor": "#01cdfe",
       "tertiaryColor": "#0a1612",
       "tertiaryTextColor": "#05ffa1",
       "tertiaryBorderColor": "#05ffa1"
     }}}%%
     flowchart TB
         classDef person fill:#2d1028,stroke:#ff71ce,stroke-width:2px,color:#ff71ce
         classDef container fill:#0a2830,stroke:#01cdfe,stroke-width:2px,color:#01cdfe
         classDef service fill:#1f0d2e,stroke:#b967ff,stroke-width:2px,color:#b967ff
         classDef datastore fill:#0a2418,stroke:#05ffa1,stroke-width:2px,color:#05ffa1
         classDef external fill:#2a2810,stroke:#fffb96,stroke-width:2px,color:#fffb96

         subgraph users ["USERS"]
             user["<b>User Role</b><br/> <br/><span>Specific role description</span><br/><span>Specific interface (e.g., Chrome Browser)</span>"]:::person
         end

         subgraph system ["SYSTEM NAME"]
             subgraph frontend ["FRONTEND"]
                 web["<b>Web App</b><br/> <br/><span>Specific responsibility</span><br/><span>React 18 + TypeScript</span>"]:::container
             end

             subgraph backend ["BACKEND"]
                 api["<b>API Server</b><br/> <br/><span>Specific responsibility</span><br/><span>Node.js 20 + Express</span>"]:::service
             end

             subgraph data ["DATA"]
                 db["<b>Database</b><br/> <br/><span>Specific data owned</span><br/><span>PostgreSQL 15 (AWS RDS)</span>"]:::datastore
             end
         end

         subgraph external ["EXTERNAL"]
             ext["<b>Specific External Service</b><br/> <br/><span>Specific integration purpose</span><br/><span>HTTPS REST API</span>"]:::external
         end

         user -->|"interacts via"| web
         web -->|"calls"| api
         api -->|"reads/writes"| db
         api -->|"sends requests to"| ext
     ```

     Coupling Notes:
     - Runtime: {specific component} depends on {specific component} for {specific reason}
     - Build-time: {specific dependency description}
     - Data: {specific shared data description}

     Write docs/architecture/containers.md? [Y/n/edit]
     ````
   - User can accept, skip, or request edits
   - Write with frontmatter: `diagram_version: "2.0"`, `type: architecture-diagram`, `level: 2`, `updated_by: "/arch:init"`
   - Include `## Coupling Notes` section
   - If exists: Report "docs/architecture/containers.md already exists — skipped"

6. **Create Level 3 directory** (if `docs/architecture/components/` does not exist):
   - `mkdir docs/architecture/components/`
   - Report: "Created docs/architecture/components/ — per-domain component diagrams are created by /design"
   - If exists: Report "docs/architecture/components/ already exists — skipped"

7. **Detect tech stack and generate stack configuration:**

   Scan the project for language/framework indicators. For each detected stack, generate project-specific configuration using the templates in the `stacks/` directory.

   **Detection table:**

   | Indicator File | Stack | Version Source |
   |---------------|-------|----------------|
   | `tsconfig.json` | TypeScript | `package.json` typescript version |
   | `go.mod` | Go | `go` directive in go.mod |
   | `Cargo.toml` | Rust | `edition` field |
   | `*.csproj` / `*.sln` | C# / .NET | `TargetFramework` element |
   | `pom.xml` / `build.gradle` | Java | `maven.compiler.source` / `jvmToolchain` |

   **For each detected stack:**

   a. Read the corresponding stack profile from `stacks/{language}.md` (installed via genie-team). If the stack profile is not available (not installed), skip with a note.

   b. **Generate `.claude/rules/stack-{language}.md`** — Copy the "Rules Content" section from the profile template, substituting the detected version. This file is loaded automatically by Claude Code as session context.
      - If the file already exists: report "Stack rules for {language} already exist — skipped" (unless `--force`)

   c. **Append to CLAUDE.md `## Tech Stack` section** — Add the compact stack summary from the profile's "CLAUDE.md Section". Create the `## Tech Stack` heading if it doesn't exist.
      - If CLAUDE.md already has a section for this language: skip

   d. **Merge settings permissions** — Add the profile's "Settings Permissions" entries to `.claude/settings.json` `permissions.allow` array. Deduplicate entries.

   e. **Present detected stacks to user:**

      ```
      ## Tech Stack Detected

      | Stack | Version | Rules | CLAUDE.md | Settings |
      |-------|---------|-------|-----------|----------|
      | Go | 1.22 | Created | Appended | Updated |
      | TypeScript | 5.4 | Created | Appended | Updated |

      Stack configuration enables:
      - Language-specific quality rules (loaded every session)
      - Build & verification commands (auto-permitted)
      - Anti-pattern enforcement (always in context)

      Proceed with stack configuration? [Y/n]
      ```

   f. If no stack indicators found: silently skip (no message — matches brand-awareness opt-in pattern)

8. **Summary:**

   ```
   ## /arch:init Complete

   **ADR-000:** {Created | Already exists}
   **Level 1 — System Context:** {Created | Already exists | Skipped by user}
   **Level 2 — Containers:** {Created | Already exists | Skipped by user}
   **Level 3 — Components directory:** {Created | Already exists}
   **Tech Stack:** {Go 1.22, TypeScript 5.4 — configured | No stack detected | Skipped by user}

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
> %%{init: {"theme": "base", "themeVariables": {...}}}%%
> flowchart TB
>     classDef actor fill:#2a0f1e,stroke:#ff2e97,stroke-width:2px,color:#ff2e97
>     classDef core fill:#0d2a2a,stroke:#00fff5,stroke-width:3px,color:#00fff5
>     classDef external fill:#1a0d24,stroke:#9d4edd,stroke-width:2px,color:#9d4edd
>
>     subgraph users ["USERS"]
>         customer["<b>Customer</b><br/> <br/><span>End user purchasing products</span><br/><span>Chrome/Safari/Firefox</span>"]:::actor
>         admin["<b>Admin</b><br/> <br/><span>Internal operations staff</span><br/><span>Chrome + Admin Dashboard</span>"]:::actor
>     end
>
>     subgraph system ["MYAPP"]
>         myapp["<b>MyApp</b><br/> <br/><span>E-commerce platform</span><br/><span>Node.js 20 (AWS ECS)</span>"]:::core
>     end
>
>     subgraph external ["EXTERNAL"]
>         sendgrid["<b>SendGrid API</b><br/> <br/><span>Transactional email delivery</span><br/><span>HTTPS REST</span>"]:::external
>         stripe["<b>Stripe API</b><br/> <br/><span>Payment processing</span><br/><span>HTTPS REST + Webhooks</span>"]:::external
>         rds["<b>PostgreSQL 15</b><br/> <br/><span>Primary database</span><br/><span>AWS RDS (us-east-1)</span>"]:::external
>     end
>
>     customer -->|"browses, purchases"| myapp
>     admin -->|"manages inventory"| myapp
>     myapp -->|"sends order confirmations"| sendgrid
>     myapp -->|"processes payments"| stripe
>     myapp -->|"reads/writes data"| rds
> ```
>
> Write docs/architecture/system-context.md? [Y/n/edit]
> > Y
>
> ## Proposed Container Diagram (Level 2)
> ...
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
- Read-only for specs — never touches docs/specs/ directory
- Does not require specs to exist — infers from project structure alone
