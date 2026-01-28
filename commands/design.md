# /design [shaped-contract]

Activate Architect genie to create technical design within shaped boundaries.

---

## Arguments

- `shaped-contract` - Path to shaped work contract (required)
- Optional flags:
  - `--interfaces` - Just interface definitions
  - `--spike` - Feasibility investigation only
  - `--review` - Review existing design

---

## Genie Invoked

**Architect** - Technical designer combining:
- Clean Architecture principles
- Interface-first design
- Pattern enforcement

---

## Context Loading

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
1. Check for `architecture/` directory
2. If present: Read `architecture/containers.md` for structural context and `architecture/components/{domain}.md` if domain is known
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

**UPDATE:**
- Backlog item: Append "# Design" section before "# End of Shaped Work Contract"
- Backlog frontmatter: `status: shaped` → `status: designed`
- Backlog frontmatter: add `adr_refs` array if ADRs were created or accepted
- docs/context/system_architecture.md (if architecture changes)
- docs/decisions/ADR-{NNN}-{slug}.md (create accepted ADRs, complete proposed ADRs — see ADR Behavior below)
- architecture/*.md (update C4 diagrams when boundaries change — see C4 Diagram Updates below)
- **Spec (if spec_ref exists):** Append or update "## Design Constraints" section in the spec body (see below)

> **Note:** Design content is appended directly to the backlog item rather than creating a separate analysis file. This keeps all work context in one living document.

**SPEC UPDATE (when spec_ref is present):**

After completing the design, update the linked spec:

1. **Append "## Design Constraints" section** to the spec body (or update if it already exists):
   ```markdown
   ## Design Constraints
   <!-- Updated by /design on {YYYY-MM-DD} from {backlog-item-id} -->
   - {constraint 1 from design}
   - {constraint 2 from design}
   ```
2. **Refine acceptance_criteria in frontmatter** if the design reveals new behavioral requirements:
   - Append new AC entries (never remove or rewrite existing ones)
   - New ACs get `status: pending`
   - Preserve original AC numbering; new ACs continue the sequence
3. **Do NOT change spec status** — the spec stays `active`

---

## Output

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
| `/design:interfaces [contract]` | Just interface definitions |
| `/design:spike [question]` | Feasibility investigation only |
| `/design:review [design]` | Architect reviews existing design |

---

## ADR Behavior

`/design` is the primary creator and manager of Architecture Decision Records.

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

`/design` updates C4 diagrams when design changes structural boundaries.

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
5. Update frontmatter: `updated: {YYYY-MM-DD}`, `updated_by: "/design"`, `backlog_ref: {path}`
6. Add `adr_refs` to diagram frontmatter if the boundary change is documented in an ADR

---

## Usage Examples

```
/design docs/backlog/P2-auth-improvements.md
> [Architect produces Design]
> Appended to docs/backlog/P2-auth-improvements.md
> Status updated: shaped → designed
>
> Components:
> - TokenService (new)
> - AuthMiddleware (modified)
> - RefreshController (new)
>
> Architecture Decisions:
> - ADR-015-jwt-refresh-strategy.md (accepted — completed from proposed)
> - ADR-016-refresh-token-storage.md (accepted — new)
>
> Diagram Updates:
> - architecture/containers.md — Added Auth Service container
> - architecture/components/identity.md — Added TokenService, RefreshController
>
> Next: /deliver docs/backlog/P2-auth-improvements.md

/design:spike "can we use WebSockets for notifications?"
> Feasibility: Yes, with caveats
> - Need Redis for pub/sub
> - Consider connection limits
> - Alternative: SSE for simpler cases
```

---

## Routing

After design:
- If ready for implementation: `/handoff design deliver`
- If significant decision: Create ADR, get Navigator approval
- If complexity exceeds appetite: Escalate to Shaper

---

## Notes

- Operates WITHIN shaped boundaries (not expanding scope)
- Creates clear implementation guidance
- Maintains architectural consistency
- Interfaces first, details second
