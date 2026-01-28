---
spec_version: "1.0"
type: shaped-work
id: GT-7
title: "ADRs and C4 Architecture Diagrams"
status: done
created: 2026-01-27
appetite: medium
priority: P1
target_project: genie-team
depends_on: [GT-6]
tags: [architecture, adrs, c4, coupling, cohesion]
acceptance_criteria:
  - id: AC-1
    description: "ADR schema and directory structure established — docs/decisions/ with ADR frontmatter schema, numbering convention, and ADR-000 bootstrapping record"
    status: met
  - id: AC-2
    description: "/design creates ADRs at docs/decisions/ADR-{NNN}-{slug}.md when the architect identifies a significant technical decision with multiple viable alternatives"
    status: met
  - id: AC-3
    description: "/define creates proposed ADRs when a behavioral delta involves an architectural choice (HOW to build, not just WHAT changes)"
    status: met
  - id: AC-4
    description: "/deliver and /discern read ADRs — deliver for implementation context, discern for ADR compliance verification"
    status: met
  - id: AC-5
    description: "C4 Mermaid diagrams established in architecture/ directory — system-context, containers, and per-domain component diagrams with coupling notes and cohesion assessments"
    status: met
  - id: AC-6
    description: "/spec:init generates initial C4 diagrams (L1-L2) from discovered domains and capabilities"
    status: met
  - id: AC-7
    description: "/design updates C4 diagrams when design changes structural boundaries"
    status: met
  - id: AC-8
    description: "/diagnose uses C4 diagrams and ADRs to detect coupling violations, cohesion drift, and architectural boundary breaches"
    status: met
  - id: AC-9
    description: "/context:load reports ADR count by status and diagram staleness; /context:refresh detects drift between diagrams and code structure"
    status: met
  - id: AC-10
    description: "architecture-awareness SKILL.md created — documents ADR and C4 lifecycle behaviors across all commands"
    status: met
  - id: AC-11
    description: "install.sh creates docs/decisions/ and architecture/ directories for new projects"
    status: met
---

# GT-7: ADRs and C4 Architecture Diagrams

## Problem

The genie-team workflow tracks WHAT the system does (specs) but not HOW it's built or WHY those technical choices were made. There's no contextual map showing how everything relates structurally.

Three artifacts form a triangle:

```
     SPEC (WHAT)
    /           \
   /             \
ADR (HOW+WHY) -- C4 (CONTEXT MAP)
```

Without ADRs, technical decisions evaporate. A developer asks "why did we use JWT instead of sessions?" and there's no record. The `/design` command already references `docs/decisions/ADR-{N}.md` and the design-document schema has an `adr_refs` field — but neither the directory, the schema, nor the creation behavior exists.

Without C4 diagrams, architectural boundaries are invisible. Coupling creeps in because nobody can see the dependency map. Cohesion degrades because there's no visual showing what belongs together. `/diagnose` checks code health metrics but has no architectural model to validate against.

Both artifacts serve humans AND the system:
- **Humans** review ADRs to understand past decisions and consult C4 diagrams to see the big picture
- **The system** reads ADRs during `/deliver` to respect technical decisions and uses C4 diagrams during `/diagnose` to detect violations

## Appetite

Medium batch — 1 week. Two new artifact types, one new skill, updates to ~8 command files, two new schemas, directory structure additions to install.sh.

## Solution Sketch

### 1. ADRs (Architecture Decision Records)

ADRs capture HOW the system is built technically and WHY those approaches were chosen.

**Location:** `docs/decisions/ADR-{NNN}-{slug}.md` — flat directory with sequential numbering. The `domain` field in frontmatter links to specs when applicable, but ADRs can be cross-cutting.

**ADR frontmatter:**
```yaml
---
adr_version: "1.0"
type: adr
id: ADR-001
title: "JWT refresh strategy over session-based tokens"
status: accepted          # proposed | accepted | deprecated | superseded
created: 2026-01-27
deciders: [architect]
domain: identity          # optional — links to specs/{domain}/
spec_refs:                # which specs this decision affects
  - specs/identity/token-authentication.md
superseded_by: null       # ADR-{NNN} if superseded
tags: [auth, security]
---
```

**ADR body structure** (Michael Nygard pattern):
- **Context** — What is the issue motivating this decision?
- **Decision** — What is the technical approach chosen?
- **Consequences** — What becomes easier or harder?
- **Alternatives Considered** — Table of options with pros/cons/why not

**Lifecycle:**
```
/define (proposed) → /design (accepted) → [lives indefinitely]
                                        → /design (superseded by new ADR)
                                        → /design (deprecated if no longer relevant)
```

**When to create an ADR:** Only when (a) there are multiple viable technical alternatives AND (b) the choice is hard to reverse OR affects multiple domains. Not every design decision warrants an ADR.

**When NOT to create an ADR:** Trivial decisions, single-option choices, easily reversible choices, implementation details within a single component.

### 2. C4 Mermaid Diagrams

C4 diagrams provide the contextual map — how everything relates structurally.

**Location:** Top-level `architecture/` directory (first-class citizenship alongside `specs/` and `docs/`):
```
architecture/
  system-context.md        # Level 1: System and external actors
  containers.md            # Level 2: High-level containers/services
  components/              # Level 3: Per-domain component diagrams
    {domain}.md            # One per domain, parallels specs/{domain}/
```

**Diagram format:** Mermaid C4 extension (`C4Context`, `C4Container`, `C4Component`). Renders natively in GitHub and VS Code. No external tooling.

**Each diagram file includes:**
- YAML frontmatter with `type: architecture-diagram`, `level`, `updated`, `updated_by`
- Mermaid C4 diagram in a fenced code block
- `## Coupling Notes` section — documents runtime, build-time, and data dependencies
- `## Cohesion Assessment` section — rates domain cohesion (HIGH/MEDIUM/LOW) with justification

**C4 levels supported:** Levels 1-3 only. Level 4 (Code) is too volatile and already represented by source code.

### 3. Lifecycle Integration

| Command | ADRs | C4 Diagrams |
|---------|------|-------------|
| `/spec:init` | — | **Creates** initial L1-L2 diagrams from discovered domains |
| `/discover` | Reads existing ADRs for context | — |
| `/define` | Creates `proposed` ADR when behavioral delta involves architectural choice | — |
| `/design` | **Creates** `accepted` ADRs; may supersede old ones | **Updates** diagrams when boundaries change |
| `/deliver` | Reads ADRs for implementation context (WHY constraints exist) | Reads component diagram for dependency directions |
| `/discern` | Verifies ADR compliance (checklist item) | Checks for boundary violations |
| `/diagnose` | Scans for stale/contradicting ADRs | **Primary consumer** — coupling violations, cohesion drift |
| `/context:load` | Reports ADR count by status | Reports diagram staleness |
| `/context:refresh` | — | Detects drift between diagrams and code structure |

### 4. Coupling and Cohesion Tracking

**Coupling tracking:**
- Container diagrams declare `Rel()` arrows between containers
- Component diagrams declare `Rel()` arrows between components
- Each diagram has `## Coupling Notes` documenting dependency types
- `/diagnose` compares diagram declarations against actual import graphs to detect undocumented coupling

**Cohesion tracking:**
- Component diagrams group components by domain (matching `specs/{domain}/`)
- Each domain diagram has `## Cohesion Assessment`
- `/diagnose` checks whether components import mostly within their domain (high cohesion) or heavily across domains (cohesion concern)

**ADRs explain boundaries:**
- When `/diagnose` detects a new dependency crossing a boundary, it references the ADR that established that boundary
- ADRs provide the "why" that makes coupling violations actionable

### 5. New Files for genie-team

| File | Purpose |
|------|---------|
| `schemas/adr.schema.md` | ADR frontmatter schema |
| `schemas/architecture-diagram.schema.md` | C4 diagram frontmatter schema |
| `.claude/skills/architecture-awareness/SKILL.md` | Skill documenting ADR and C4 lifecycle behaviors |
| `install.sh` update | Creates `docs/decisions/` and `architecture/` directories |

## Rabbit Holes

1. **Don't auto-generate ADRs for every design.** Clear threshold: multiple viable alternatives AND hard to reverse. ADR proliferation makes them noise.
2. **Don't require C4 diagrams before work starts.** They're valuable but optional. Warn-never-block. A project can start with zero diagrams.
3. **Don't try to auto-sync diagrams with code.** Drift is detected, not prevented. `/context:refresh` and `/diagnose` report drift. Humans and `/design` update diagrams.
4. **Don't support C4 Level 4 (Code).** Too volatile. Source code is the code-level diagram.
5. **Don't put ADRs inside specs.** Different lifecycle, different purpose. ADRs explain HOW+WHY; specs describe WHAT. They link via `spec_refs` and `domain` fields.
6. **Don't auto-detect domains for component diagrams.** Same principle as specs — domain is a human decision.
7. **Don't make Mermaid C4 syntax validation a blocker.** If the diagram doesn't render, it's a warning, not a workflow block.

## Acceptance Criteria

See frontmatter above:

| AC | Scope | Change |
|----|-------|--------|
| AC-1 | New schema + directory | ADR infrastructure — schema, directory, ADR-000 |
| AC-2 | `design.md` | /design creates ADRs for significant decisions |
| AC-3 | `define.md` | /define creates proposed ADRs for architectural choices in behavioral delta |
| AC-4 | `deliver.md`, `discern.md` | Read ADRs for context and compliance |
| AC-5 | New directory + schema | C4 diagram infrastructure — directory, schema, templates |
| AC-6 | `spec-init.md` | /spec:init generates initial C4 diagrams |
| AC-7 | `design.md` | /design updates C4 diagrams when boundaries change |
| AC-8 | `diagnose.md` | /diagnose uses diagrams and ADRs for coupling/cohesion analysis |
| AC-9 | `context-load.md`, `context-refresh.md` | Report ADR count, diagram staleness, drift |
| AC-10 | New skill file | architecture-awareness SKILL.md |
| AC-11 | `install.sh` | Create new directories |

## Handoff

Ready for `/design`. Key design decisions needed:
- Exact ADR template content (how detailed should the Alternatives Considered table be?)
- C4 diagram templates for each level (working Mermaid C4 syntax examples)
- How `/diagnose` performs coupling analysis (import graph parsing vs. heuristic)
- Whether `/define` should create a full ADR document or just flag "ADR needed" for `/design`
- Exact threshold wording for "when to create an ADR" in command files

# Design

## Design Summary

13 files affected (3 new, 10 modified). All markdown instruction changes plus `install.sh` directory additions.

## File Inventory

| # | File | Action | ACs |
|---|------|--------|-----|
| 1 | `schemas/adr.schema.md` | Create | AC-1 |
| 2 | `schemas/architecture-diagram.schema.md` | Create | AC-5 |
| 3 | `.claude/skills/architecture-awareness/SKILL.md` | Create | AC-10 |
| 4 | `commands/design.md` | Modify | AC-2, AC-7 |
| 5 | `commands/define.md` | Modify | AC-3 |
| 6 | `commands/deliver.md` | Modify | AC-4 |
| 7 | `commands/discern.md` | Modify | AC-4 |
| 8 | `commands/diagnose.md` | Modify | AC-8 |
| 9 | `commands/discover.md` | Modify | AC-2 context |
| 10 | `commands/spec-init.md` | Modify | AC-6 |
| 11 | `commands/context-load.md` | Modify | AC-9 |
| 12 | `commands/context-refresh.md` | Modify | AC-9 |
| 13 | `install.sh` | Modify | AC-11 |

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| ADR numbering | Sequential 3-digit zero-padded (ADR-001) | Matches existing conventions (AC-1, GT-7); easy to scan and increment |
| ADR directory | `docs/decisions/` flat | Shaped contract specifies; `domain` field in frontmatter provides grouping |
| C4 directory | `architecture/` top-level | First-class alongside `specs/` and `docs/` |
| `/define` ADR behavior | Full proposed ADR with incomplete Decision section | Captures alternatives while fresh; `/design` completes |
| Coupling analysis | Heuristic directory + import pattern scanning | Language-agnostic; full AST too complex for instruction files |
| Staleness threshold | 90 days | Balances signal vs. noise for architectural diagrams |
| ADR version field | `adr_version` (not `spec_version`) | Distinct artifact type; independent schema evolution |
| Diagram version field | `diagram_version` | Same rationale as ADR version |

## New Files

### 1. `schemas/adr.schema.md`
- Frontmatter schema following `shaped-work-contract.schema.md` pattern
- Required: `adr_version`, `type: adr`, `id` (ADR-NNN), `title`, `status`, `created`, `deciders`
- Optional: `domain`, `spec_refs`, `backlog_ref`, `superseded_by`, `supersedes`, `tags`
- Status lifecycle: proposed → accepted → [superseded | deprecated]
- ADR creation threshold documented in schema
- Michael Nygard body pattern: Context, Decision, Consequences, Alternatives Considered
- ADR-000 bootstrapping record template included

### 2. `schemas/architecture-diagram.schema.md`
- Required: `diagram_version`, `type: architecture-diagram`, `level` (1-3), `title`, `updated`, `updated_by`
- Optional: `domain` (L3 only), `backlog_ref`, `adr_refs`, `tags`
- Body template: Title, Mermaid diagram, Coupling Notes, Cohesion Assessment
- Mermaid C4 syntax reference for all 3 levels

### 3. `.claude/skills/architecture-awareness/SKILL.md`
- Parallel structure to `spec-awareness/SKILL.md`
- Covers: ADR Organization, C4 Diagram Organization, When Active, per-command Behaviors
- Common loading patterns for ADRs and C4 diagrams
- Architecture Update Rules (7 rules matching the 6 spec update rules)

## Command Modifications

### 4. `commands/design.md` (AC-2, AC-7)
- Add ADR LOADING and C4 DIAGRAM LOADING subsections to Context Loading
- Expand Context Writing to detail ADR creation/acceptance and C4 diagram update behavior
- Add output items 8 (Architecture Decisions) and 9 (Diagram Updates)
- New "ADR Behavior" section: when to create, workflow (proposed→accepted, supersede), threshold
- New "C4 Diagram Updates" section: when to update, which levels, frontmatter changes
- Updated usage example showing ADR and diagram output

### 5. `commands/define.md` (AC-3)
- Add ADR scanning to Context Loading READ
- Add proposed ADR to Context Writing
- New "Architectural Decision Detection" section with threshold check, full workflow, examples
- New usage example showing proposed ADR creation

### 6. `commands/deliver.md` (AC-4)
- Add ADR LOADING subsection to Context Loading (from design `adr_refs`)
- Surface relevant decisions constraining implementation
- Notes: reads ADRs, does NOT create or modify them

### 7. `commands/discern.md` (AC-4)
- Add ADR LOADING subsection to Context Loading
- Add item 9 to Review Checklist: "ADR compliance?"
- Add ADR Compliance table format to Output
- Updated usage example showing compliance output

### 8. `commands/diagnose.md` (AC-8)
- Add architecture file loading to Context Loading
- Add output item 7: Architecture Health
- New "Architecture Analysis" section: Coupling Analysis, Cohesion Analysis, ADR Health, Diagram Staleness
- Rebalance Health Metrics: add Architecture (10%), reduce others proportionally
- Updated usage example showing architecture findings

### 9. `commands/discover.md`
- Add ADR scanning to Context Loading
- Add output item 6: Architecture Context
- Note about surfacing relevant ADRs

### 10. `commands/spec-init.md` (AC-6)
- Add C4 diagram files to Context Writing
- New step 9 in Behavior: C4 diagram generation (L1 system-context, L2 containers, prepare L3 directory)
- Add C4 section to Summary Output
- Updated usage example showing diagram generation

### 11. `commands/context-load.md` (AC-9)
- New behavior step 3: architecture artifact scanning (ADR count, diagram staleness)
- Add Architecture section to Output Format
- Recommendations for missing/stale diagrams
- Add architecture files to READ operations

### 12. `commands/context-refresh.md` (AC-9)
- New behavior step 5: C4 diagram drift detection
- Add "Diagram drift" to Output Format
- Add architecture files to READ operations
- New usage example showing drift findings

### 13. `install.sh` (AC-11)
- Add `mkdir -p "$project_path/docs/decisions"` and `mkdir -p "$project_path/architecture/components"`
- Update success message to mention architecture directories

## Implementation Order

1. Create schemas (AC-1, AC-5) — foundational
2. Create skill file (AC-10) — canonical reference
3. Update install.sh (AC-11) — simple
4. Modify /design (AC-2, AC-7) — heaviest change
5. Modify /define (AC-3)
6. Modify /deliver (AC-4 read side)
7. Modify /discern (AC-4 compliance side)
8. Modify /diagnose (AC-8)
9. Modify /spec:init (AC-6)
10. Modify /discover (context)
11. Modify /context:load (AC-9)
12. Modify /context:refresh (AC-9)
13. Create ADR-000 bootstrapping record (dog-food)
14. Sync all commands to `.claude/commands/`
15. Verify coherence

# Implementation

## Implementation Summary

Delivered 16 files (3 new, 13 modified/created) implementing ADRs and C4 architecture diagrams across the entire genie-team lifecycle.

## Files Created

| # | File | ACs |
|---|------|-----|
| 1 | `schemas/adr.schema.md` | AC-1 |
| 2 | `schemas/architecture-diagram.schema.md` | AC-5 |
| 3 | `.claude/skills/architecture-awareness/SKILL.md` | AC-10 |
| 4 | `docs/decisions/ADR-000-use-adrs-for-architecture-decisions.md` | AC-1 (dogfooding) |

## Files Modified

| # | File | ACs |
|---|------|-----|
| 5 | `commands/design.md` | AC-2, AC-7 |
| 6 | `commands/define.md` | AC-3 |
| 7 | `commands/deliver.md` | AC-4 |
| 8 | `commands/discern.md` | AC-4 |
| 9 | `commands/diagnose.md` | AC-8 |
| 10 | `commands/discover.md` | context |
| 11 | `commands/spec-init.md` | AC-6 |
| 12 | `commands/context-load.md` | AC-9 |
| 13 | `commands/context-refresh.md` | AC-9 |
| 14 | `install.sh` | AC-11 |

## Directories Created

| Directory | Purpose |
|-----------|---------|
| `docs/decisions/` | ADR storage (flat, sequential numbering) |
| `architecture/components/` | Level 3 component diagrams (populated by /design) |

## Coherence Verification

Critic agent verified all 11 ACs met. Cross-reference checks passed:
- Consistent directory paths across all 16 files
- Consistent ADR numbering convention (ADR-NNN, 3-digit zero-padded)
- Consistent C4 levels (1-3, no Level 4)
- Consistent staleness threshold (90 days)
- Consistent ADR creation threshold wording
- Warn-never-block principle maintained across all commands

## Minor Fixes Applied Post-Verification

1. Added C4 diagram loading note to `deliver.md` (SKILL.md referenced it but command file didn't)
2. Narrowed `discover.md` output to "Relevant ADRs" (not C4 diagrams, matching SKILL.md)
3. Standardized "Warn and continue" wording in `design.md` ADR/C4 loading (was "Note... Continue")
4. Added graceful-absence handling to `diagnose.md` for missing architecture artifacts

## Known Issue

`dist/commands/` directory contains stale pre-GT-7 versions. The installer reads from source directories directly, so this doesn't affect functionality. Should be addressed in a cleanup pass.

# Review

## Verdict: APPROVED

**Date:** 2026-01-27
**ACs verified:** 11/11 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `schemas/adr.schema.md` with full frontmatter schema, numbering, ADR-000 template. `docs/decisions/ADR-000` conforms to schema. |
| AC-2 | met | `commands/design.md` ADR Behavior section with threshold, proposed→accepted workflow, supersession, template |
| AC-3 | met | `commands/define.md` Architectural Decision Detection section with threshold check, proposed workflow, examples |
| AC-4 | met | `commands/deliver.md` ADR LOADING (read-only). `commands/discern.md` ADR LOADING + checklist item 9 + compliance table |
| AC-5 | met | `schemas/architecture-diagram.schema.md` with C4 levels 1-3, Mermaid syntax, coupling/cohesion templates |
| AC-6 | met | `commands/spec-init.md` step 8 generates L1-L2 diagrams, C4 section in summary output |
| AC-7 | met | `commands/design.md` C4 Diagram Updates section with when-to-update criteria and 6-step workflow |
| AC-8 | met | `commands/diagnose.md` Architecture Analysis section (coupling, cohesion, ADR health, staleness) + 10% metric |
| AC-9 | met | `commands/context-load.md` step 3 + Architecture output. `commands/context-refresh.md` step 5 + drift output |
| AC-10 | met | `.claude/skills/architecture-awareness/SKILL.md` — 332 lines covering all 9 commands, loading patterns, 7 update rules |
| AC-11 | met | `install.sh` creates `docs/decisions/` and `architecture/components/` + directory listing in success message |

## Cross-Reference Consistency

All checks passed: directory paths, ADR numbering, C4 levels, staleness threshold (90 days), creation threshold wording, warn-never-block principle, read-only constraints for /deliver and /discern.

## Minor Notes

- `dist/commands/` contains stale pre-GT-7 versions — address in cleanup pass
- No spec_ref on this backlog item (GT-7 is framework infrastructure, not a product capability)

# End of Shaped Work Contract
