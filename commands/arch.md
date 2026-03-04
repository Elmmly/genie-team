# /arch [shaped-contract] --workshop

Activate Architect genie for interactive architecture workshops — approach comparison, technical decisions, interface design, and risk prioritization.

Supports two modes:
- **Foundation mode** (no shaped contract) — System-level architecture decisions for greenfield projects. Produces ADRs + workshop summary, routes to `/arch:init`.
- **Feature mode** (shaped contract provided) — Architecture design for a specific backlog item. Produces a Design Document appended to the backlog item.

---

## Arguments

- `shaped-contract` - Path to shaped work contract (optional). If omitted, runs in foundation mode for system-level decisions.
- Required flags:
  - `--workshop` - Run interactive architecture workshop (all 5 phases)

---

## Agent Identity

Read and internalize `.claude/agents/architect.md` for your identity, charter, and judgment rules.

---

## Context Loading

### Foundation Mode (no shaped contract)

**READ (automatic):**
- docs/context/system_architecture.md (if exists)
- docs/context/codebase_structure.md (if exists)
- Project root files (README.md, CLAUDE.md) for project understanding
- Relevant code files (as needed)

**RECALL:**
- Related ADRs (Architecture Decision Records)

**ADR LOADING:**
1. Scan `docs/decisions/ADR-*.md` for any existing `accepted` ADRs
2. If `docs/decisions/` does not exist: Note this is a fresh project — no ADR history yet

**C4 DIAGRAM LOADING:**
1. Check for `docs/architecture/` directory
2. If present: Read `docs/architecture/containers.md` for structural context
3. If missing: Note this is a fresh project — no diagrams yet

**Skip:** Backlog loading, spec loading (no backlog item to reference).

### Feature Mode (shaped contract provided)

**READ (automatic):**
- docs/backlog/{priority}-{topic}.md
- Backlog frontmatter field `spec_ref` → load the linked spec for context (ACs, domain, existing evidence)
- docs/context/system_architecture.md
- docs/context/codebase_structure.md
- Relevant code files (as needed)

**RECALL:**
- Past designs with similar patterns
- Related ADRs (Architecture Decision Records)

**ADR LOADING:**
1. Check for `adr_refs` in the backlog item frontmatter
2. If present: Read each referenced ADR from `docs/decisions/`
3. Scan `docs/decisions/ADR-*.md` for any `proposed` ADRs created by `/define` for this work
4. Load any `accepted` ADRs relevant to the domain (from `domain` field matching)
5. If `docs/decisions/` does not exist: **Warn** and continue without ADR context:
   > No ADRs directory found. Architecture decisions are not being tracked.

**C4 DIAGRAM LOADING:**
1. Check for `docs/architecture/` directory
2. If present: Read `docs/architecture/containers.md` for structural context and `docs/architecture/components/{domain}.md` if domain is known
3. If missing: **Warn** and continue without diagram context:
   > No architecture directory found. C4 diagrams are not being maintained.

**SPEC LOADING:**
1. Read `spec_ref` from backlog item frontmatter
2. If `spec_ref` is present: Read the spec file. Use its acceptance_criteria and any existing evidence as design context.
3. If `spec_ref` is missing: Warn and continue without spec context:
   > This backlog item has no spec_ref. Design will proceed without spec context.
4. If `spec_ref` points to a nonexistent file: Warn and continue:
   > spec_ref points to {path} but file not found. Design will proceed without spec context.

---

## Context Writing

### Foundation Mode (no shaped contract)

**WRITE:**
- `docs/analysis/architecture-workshop-{YYYY-MM-DD}.md` — Workshop summary with all decisions captured
- `docs/decisions/ADR-{NNN}-{slug}.md` — ADRs for significant decisions (omit `backlog_ref` field)

**Do NOT:**
- Append to any backlog item (none exists)
- Update any backlog frontmatter
- Produce a Design Document (no backlog item to attach to)
- Update any spec
- Create C4 diagrams (too early — no concrete containers to diagram yet; `/arch:init` handles this later)

### Feature Mode (shaped contract provided)

**UPDATE:**
- Backlog item: Append "# Design" section before "# End of Shaped Work Contract"
- Backlog frontmatter: `status: shaped` → `status: designed`
- Backlog frontmatter: add `adr_refs` array if ADRs were created or accepted
- docs/context/system_architecture.md (if architecture changes)
- docs/decisions/ADR-{NNN}-{slug}.md (create accepted ADRs, complete proposed ADRs — see ADR Behavior below)
- docs/architecture/*.md (update C4 diagrams when boundaries change — see C4 Diagram Updates below)
- **Spec (if spec_ref exists):** Append or update "## Design Constraints" section in the spec body (see below)
- docs/specs/{domain}/README.md (per Domain README Format, when spec_ref exists)

> **Note:** Design content is appended directly to the backlog item rather than creating a separate analysis file. This keeps all work context in one living document.

**SPEC UPDATE (when spec_ref is present):**

After completing the design, update the linked spec:

1. **Append "## Design Constraints" section** to the spec body (or update if it already exists):
   ```markdown
   ## Design Constraints
   <!-- Updated by /arch --workshop on {YYYY-MM-DD} from {backlog-item-id} -->
   - {constraint 1 from design}
   - {constraint 2 from design}
   ```
2. **Refine acceptance_criteria in frontmatter** if the design reveals new behavioral requirements:
   - Append new AC entries (never remove or rewrite existing ones)
   - New ACs get `status: pending`
   - Preserve original AC numbering; new ACs continue the sequence
3. **Do NOT change spec status** — the spec stays `active`
4. **Regenerate `docs/specs/{domain}/README.md`** per spec-awareness Domain README Format

---

## Output

### Foundation Mode

Produces:
- **Workshop summary** at `docs/analysis/architecture-workshop-{YYYY-MM-DD}.md` — Decisions captured, approaches considered, risks identified
- **ADRs** at `docs/decisions/ADR-{NNN}-{slug}.md` — For each significant decision (no `backlog_ref`)

Does NOT produce a Design Document or C4 diagrams (too early — `/arch:init` handles diagrams once decisions are materialized).

### Feature Mode

Produces a **Design Document** containing:
1. Design Summary - What we're building
2. Component Design - Interfaces, modules, interactions
3. Data Design - Models, storage, flows
4. Integration Points - External dependencies
5. Migration Strategy - How to get there from here
6. Risks & Mitigations - Technical risks
7. Implementation Guidance - For Crafter handoff
8. Architecture Decisions - ADRs created or accepted during design (if any)
9. Diagram Updates - C4 diagram changes made (if any)

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/arch:init` | Bootstrap architecture artifacts (ADR-000, C4 diagrams, stack config) |

---

## ADR Behavior

`/arch --workshop` is a primary creator and manager of Architecture Decision Records.

### When to Create an ADR

Apply the **ADR Creation Threshold** — both conditions must be true:
1. **Multiple viable alternatives exist** — There is a genuine choice between approaches
2. **Hard to reverse OR affects multiple domains** — The decision has lasting consequences

Do NOT create ADRs for: trivial decisions, single-option choices, easily reversible choices, or implementation details within a single component.

### ADR Workflow

1. **Complete proposed ADRs from /define:**
   - If `/define` created a `proposed` ADR, complete the **Decision** section with the chosen approach
   - Update `status: proposed` → `status: accepted`
   - Fill in **Consequences** section

2. **Create new accepted ADRs:**
   - For significant decisions discovered during design that had no proposed ADR
   - Create `docs/decisions/ADR-{NNN}-{slug}.md` with `status: accepted`
   - Fill in all sections: Context, Decision, Consequences, Alternatives Considered
   - Determine next number by scanning `docs/decisions/ADR-*.md`

3. **Supersede existing ADRs:**
   - If design replaces a previous decision: Create new ADR, then update old ADR:
     - Old: `status: superseded`, add `superseded_by: ADR-{NNN}`
     - New: add `supersedes: ADR-{NNN}`

4. **Update references:**
   - Add `adr_refs` to backlog item and design document frontmatter
   - Reference ADR ids in the Design section narrative

### ADR Template

```yaml
---
adr_version: "1.0"
type: adr
id: ADR-{NNN}
title: "{Decision title — verb phrase preferred}"
status: accepted
created: {YYYY-MM-DD}
deciders: [architect]
domain: {domain}
spec_refs:
  - {spec path if applicable}
backlog_ref: {backlog item path}
tags: [{relevant tags}]
---
```

Body follows Michael Nygard pattern: Context, Decision, Consequences (Positive/Negative/Neutral), Alternatives Considered (table).

---

## C4 Diagram Updates

`/arch --workshop` updates C4 diagrams when design changes structural boundaries.

### When to Update

Update diagrams when design introduces:
- New containers or services (Level 2)
- New components within a domain (Level 3)
- Changed relationships (`Rel()` arrows) between existing elements
- New external system dependencies

Do NOT update diagrams for: internal implementation changes, code refactoring within a component, or changes that don't affect the structural map.

### Update Workflow

1. Identify which diagram level(s) are affected
2. Update the Mermaid C4 diagram in the affected file(s)
3. Update `## Coupling Notes` section to reflect new/changed dependencies
4. Update `## Cohesion Assessment` if domain boundaries shifted (Level 3)
5. Update frontmatter: `updated: {YYYY-MM-DD}`, `updated_by: "/arch --workshop"`, `backlog_ref: {path}`
6. Add `adr_refs` to diagram frontmatter if the boundary change is documented in an ADR

---

## Workshop Phase 1: Approach Comparison

**MANDATORY: You MUST produce a viewable HTML artifact. Do NOT describe architecture approaches in a text table.**

### Foundation Mode

1. **Open with "What are we building?"** — Use AskUserQuestion to gather project context:
   - "Describe the system you're building — what problem does it solve, who are the users, what's the scale?"
   - Gather enough context to generate meaningful architectural alternatives
2. **Generate 2-3 system-level architectural approaches** — each should be a genuinely different way to structure the system (e.g., monolith vs microservices, serverless vs containerized, event-driven vs request-response)

### Feature Mode

1. **Read** the shaped work contract and load all context (ADRs, C4 diagrams, specs) per the standard Context Loading section above
2. **Generate 2-3 architectural approaches** — each should be a genuinely different way to solve the problem within the shaped appetite

### Both Modes
3. **Write** an HTML file to the scratchpad directory using the Write tool:

   **File path:** `{scratchpad}/workshop/approach-comparison.html`

   The HTML file MUST be self-contained (inline CSS, no external dependencies) and show **side-by-side approach panels**:

   **If C4 diagrams exist**, include a "Current Architecture" summary section at the top showing the relevant existing structure before the comparison panels.

   Each approach panel includes:
   - **Approach name** and 2-3 sentence summary
   - **Component list** with count (e.g., "3 new components, 2 modified")
   - **Dependency overview** — simplified text-based view showing what depends on what (indented list, not Mermaid)
   - **Evaluation table** with visual indicators for:
     - Complexity — Simple / Moderate / Complex (green → yellow → red)
     - Risk — Low / Medium / High
     - Maintainability — High / Medium / Low (green → yellow → red)
     - Performance — High / Medium / Low
     - Reversibility — Easy / Moderate / Hard
   - **Pros** — bullet list
   - **Cons** — bullet list

   Layout: Panels sit side-by-side for direct visual comparison. Minimum 320px per panel. Light background, clear section headers, color-coded evaluation indicators.

4. **Tell the user** to open the file: `open {scratchpad}/workshop/approach-comparison.html`
5. **Use AskUserQuestion:** "Which architectural approach?" with options for each approach plus "Hybrid / refine"
6. If user wants a hybrid or refinement: **Regenerate the HTML** with the refined approach and tell user to refresh

**Output:** Locked architectural approach for the design.

---

## Workshop Phase 2: Technical Decisions

Walk through each significant technical decision interactively.

1. **Greenfield stack check:** Before identifying technical decisions, check whether a tech stack is configured:
   a. Scan `.claude/rules/stack-*.md` for existing stack profiles
   b. Scan for stack indicator files (`tsconfig.json`, `go.mod`, `Cargo.toml`, `*.csproj`, `pom.xml`, `build.gradle`, `mix.exs`, `Package.swift`, `build.gradle.kts`)
   c. If NEITHER profiles NOR indicators exist (greenfield): **Prepend "Which tech stack?"** to the qualifying decisions:
      - Present as: "Which primary tech stack should this project use?"
      - Options: Available profiles from `stacks/*.md` plus "Other / no stack profile needed"
      - Include Architect's recommendation based on project requirements, team signals, and problem domain
      - If user selects a supported stack: Record the decision for Phase 5 routing
      - If user selects "Other": Note it; no stack config will be generated
   d. If profiles or indicators already exist: Skip silently (stack is determined)
2. **Identify** all technical decisions that meet the multi-option threshold:
   - Multiple viable alternatives exist
   - Hard to reverse OR affects multiple components
3. **For each qualifying decision**, use AskUserQuestion:
   - Present the decision as a clear question (e.g., "How should we store session state?")
   - Options are the viable alternatives, each with a 1-sentence tradeoff description
   - Include the Architect's recommendation as the first option with "(Recommended)" suffix
4. **Decisions that don't meet the threshold** (single viable approach, easily reversible, internal to one component) are made autonomously — mention them briefly but don't ask
5. **Capture** each decision with the user's choice and rationale

**Output:** Completed Technical Decisions table for the design document.

---

## Workshop Phase 3: Interface Preview

**MANDATORY: You MUST produce a viewable HTML artifact. Do NOT describe interfaces in a text/markdown code block only.**

### Foundation Mode

1. **Based on** the chosen approach and technical decisions, define **system-level boundaries** — API contracts between containers, service interfaces, and integration points. Focus on how major system components communicate, not feature-specific internal interfaces.

### Feature Mode

1. **Based on** the chosen approach and technical decisions, define the key interfaces

### Both Modes
2. **Write** an HTML file to the scratchpad directory using the Write tool:

   **File path:** `{scratchpad}/workshop/interface-preview.html`

   The HTML file MUST be self-contained (inline CSS) and show interface definitions in a **code-styled layout**:

   For each component/module:
   - **Component name** as a section header
   - **Interface signatures** in a monospace code block with basic syntax highlighting (inline CSS):
     - Function/method names in blue
     - Types in green
     - Parameters in default color
     - Comments in gray
   - **Usage example** beneath each interface — a realistic code snippet showing how callers would use it
   - **Design notes** as callout boxes explaining key choices (e.g., "Returns a Result type instead of throwing to make error handling explicit")

   Layout: Single-column, code-first. Dark background for code blocks (like a code editor). Light background for design notes. Group interfaces by component.

3. **Tell the user** to open the file: `open {scratchpad}/workshop/interface-preview.html`
4. **Use AskUserQuestion:** "Do these interfaces feel right?" with options:
   - "Yes, proceed"
   - "Adjust signatures"
   - "Adjust naming"
   - "Rethink structure"
5. If user wants changes: Discuss adjustments, **regenerate the HTML**, tell user to refresh

**Output:** Locked interface definitions for the design document.

---

## Workshop Phase 4: Risk Prioritization

Present the risk matrix and let the user decide which mitigations are worth the investment.

1. **Identify** all technical risks from the chosen approach:
   - For each risk: Likelihood (Low/Medium/High), Impact (Low/Medium/High), Proposed Mitigation, Mitigation Cost
2. **Use AskUserQuestion** with multiSelect enabled:
   - **Foundation mode:** "Which risks should we actively mitigate?" — No appetite constraint; ask user for mitigation budget or priority level
   - **Feature mode:** "Which risks should we actively mitigate? Each mitigation has a cost within the appetite budget."
   - Options are the risks with their mitigation descriptions and costs
   - Let user select which mitigations to invest in (some risks may be accepted without mitigation)
3. **Capture** which mitigations are accepted and which risks are accepted as-is

**Output:** Risks & Mitigations table with user-approved mitigation decisions.

---

## Workshop Phase 5: Consolidation

### Foundation Mode

Write a workshop summary and ADRs — no Design Document (no backlog item to attach to).

1. **Write ADRs** for each significant decision made during the workshop:
   - Create `docs/decisions/ADR-{NNN}-{slug}.md` with `status: accepted`
   - Omit the `backlog_ref` field (no backlog item exists)
   - Fill in all sections: Context, Decision, Consequences, Alternatives Considered
2. **Write workshop summary** to `docs/analysis/architecture-workshop-{YYYY-MM-DD}.md`:
   - System overview (from Phase 1 context gathering)
   - Chosen architectural approach and alternatives considered
   - Technical decisions made (interactive and autonomous)
   - Interface boundaries defined
   - Risk mitigations prioritized
   - ADRs created (list with paths)
3. **Stack configuration routing:** If a tech stack was chosen in Phase 2:
   - Capture the stack choice as an ADR
   - Include in completion report:
     > **Stack Decision:** {Language} selected in workshop
     > **Next:** Run `/arch:init --stack {language}` to generate C4 diagrams, stack rules, and project configuration
4. **Report completion:**
   - List all artifacts created (workshop summary, ADRs)
   - Route to `/arch:init --stack {language}` as the next step

**Output:** Workshop summary + ADRs. No Design Document.

### Feature Mode

Write the standard Design Document using all decisions captured in Phases 1-4.

1. **Append** the Design Document to the backlog item before "# End of Shaped Work Contract" using the same template and format as batch mode
2. The design MUST include all standard sections (Design Summary, Component Design, Data Design, Integration Points, Risks & Mitigations, Implementation Guidance, etc.)
3. **Additionally**, note in the design narrative which decisions were made interactively:
   - "Architecture approach chosen from {N} alternatives in workshop"
   - "{N} technical decisions made interactively, {M} made autonomously"
   - "Interfaces confirmed after workshop preview"
   - "Risk mitigations prioritized: {accepted list}; risks accepted: {unmitigated list}"
4. Follow all standard ADR Behavior, C4 Diagram Updates, and Spec Updates from the batch flow
5. **Update** backlog frontmatter: `status: shaped` → `status: designed`
6. **Report completion** as in batch mode
7. **Stack configuration routing:** If a tech stack was chosen in Phase 2 (greenfield) AND no stack configuration exists yet:
   - Include in completion report:
     > **Stack Decision:** {Language} selected in workshop
     > **Next:** Run `/arch:init --stack {language}` to generate stack rules, CLAUDE.md section, and settings permissions
   - Capture the stack choice as an ADR (meets threshold: multiple alternatives, hard to reverse, affects all components)
   - Do NOT generate stack config directly — that is `/arch:init`'s responsibility

**Output:** Standard Design Document — identical format to batch mode.

---

## Usage Examples

### Foundation Mode (no shaped contract — greenfield bootstrapping)

```
/arch --workshop
> [Architect loads project context, ADRs, and C4 diagrams if they exist]
>
> Phase 1: Approach Comparison
> "What are we building?" → User describes the system
> Generated approach-comparison.html with 3 system-level alternatives
> open {scratchpad}/workshop/approach-comparison.html
> Which architectural approach? → "Modular monolith"
>
> Phase 2: Technical Decisions
> - Which tech stack? → Elixir (greenfield)
> - Which database? → PostgreSQL (Recommended)
> - Which deployment target? → Fly.io
> 3 decisions made interactively, 2 made autonomously
>
> Phase 3: Interface Preview
> Generated interface-preview.html — system-level API boundaries
> open {scratchpad}/workshop/interface-preview.html
> Do these interfaces feel right? → "Yes, proceed"
>
> Phase 4: Risk Prioritization
> 3 risks identified, 2 mitigations selected
>
> Phase 5: Consolidation
> Workshop summary written to docs/analysis/architecture-workshop-2026-03-04.md
> ADR-001-modular-monolith.md (accepted)
> ADR-002-elixir-stack-selection.md (accepted)
> ADR-003-postgresql-database.md (accepted)
>
> Stack Decision: Elixir selected in workshop
> Next: Run /arch:init --stack elixir to generate C4 diagrams, stack rules, and project configuration
```

### Feature Mode (shaped contract provided)

```
/arch --workshop docs/backlog/P1-first-feature.md
> [Architect reads shaped contract, loads ADRs and C4 diagrams]
>
> Phase 1: Approach Comparison
> Generated approach-comparison.html with 3 alternatives
> open {scratchpad}/workshop/approach-comparison.html
> Which architectural approach? → "Event-driven"
>
> Phase 2: Technical Decisions
> - Which tech stack? → Elixir (greenfield)
> - How should we store session state? → Redis
> - Which message broker? → NATS (Recommended)
> 3 decisions made interactively, 2 made autonomously
>
> Phase 3: Interface Preview
> Generated interface-preview.html
> open {scratchpad}/workshop/interface-preview.html
> Do these interfaces feel right? → "Yes, proceed"
>
> Phase 4: Risk Prioritization
> 4 risks identified, 2 mitigations selected
>
> Phase 5: Consolidation
> Design Document appended to docs/backlog/P1-first-feature.md
> Status updated: shaped → designed
> ADR-001-event-driven-architecture.md (accepted)
> ADR-002-elixir-stack-selection.md (accepted)
>
> Stack Decision: Elixir selected in workshop
> Next: Run /arch:init --stack elixir to generate stack rules
>
> Next: /arch:init --stack elixir, then /deliver docs/backlog/P1-first-feature.md
```

---

## Routing

### Foundation Mode

After workshop:
- → `/arch:init --stack {language}` to materialize decisions (C4 diagrams, stack config, ADR-000)
- After init: → `/discover` + `/define` to shape the first feature against the established foundation

### Feature Mode

After workshop:
- If ready for implementation: `/handoff design deliver`
- If significant decision: Create ADR, get Navigator approval
- If complexity exceeds appetite: Escalate to Shaper
- If stack was chosen in workshop (greenfield): Run `/arch:init --stack {language}` before `/deliver`
- For batch (non-interactive) design: `/design [contract]`

---

## Notes

- Operates WITHIN shaped boundaries (not expanding scope)
- Creates clear implementation guidance
- Maintains architectural consistency
- Interfaces first, details second
- Interactive workshop mode — user participates in key architectural decisions

ARGUMENTS: $ARGUMENTS
