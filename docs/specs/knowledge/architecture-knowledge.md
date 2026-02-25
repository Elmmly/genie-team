---
spec_version: "1.0"
type: spec
id: architecture-knowledge
title: Architecture Knowledge Management
status: active
created: 2026-02-25
domain: knowledge
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      ADR lifecycle managed across commands: /define creates proposed ADRs when behavioral
      delta involves an architectural choice (strict creation threshold: multiple viable
      alternatives AND hard to reverse or cross-domain), /design creates or accepts ADRs
      after evaluating alternatives
    status: met
  - id: AC-2
    description: >-
      C4 Mermaid diagrams at Levels 1-3 with Neon Dark flowchart styling, infrastructure
      context subgraphs, node format with bold title + responsibility + tech stack,
      Coupling Notes section, and Cohesion Assessment section (Level 3)
    status: met
  - id: AC-3
    description: >-
      /discern checks ADR compliance (does implementation follow accepted decisions) and
      boundary violations (undocumented cross-domain dependencies); /diagnose performs
      coupling analysis, cohesion drift, ADR health, and diagram staleness detection
      (>90 days threshold)
    status: met
  - id: AC-4
    description: >-
      ADR and diagram schemas defined with required/optional frontmatter fields and
      validation rules per schemas/adr.schema.md (ADR-NNN format, status lifecycle,
      supersession) and schemas/architecture-diagram.schema.md (C4 levels, Neon Dark
      styling, provenance tracking)
    status: met
---

# Architecture Knowledge Management

The architecture-awareness skill manages two complementary artifact types that explain HOW the system is built: Architecture Decision Records (ADRs) capture significant technical decisions using the Michael Nygard pattern (Context, Decision, Consequences, Alternatives Considered), while C4 Mermaid diagrams provide the structural context map showing how everything relates.

Together with specs (WHAT the system does), ADRs and C4 diagrams form the three pillars of persistent project knowledge. All three survive backlog item archival and accumulate knowledge over time.

## Acceptance Criteria

### AC-1: ADR lifecycle across commands
ADRs follow a strict creation threshold: create ONLY when multiple viable alternatives exist AND the choice is hard to reverse or affects multiple domains. `/define` creates proposed ADRs (context and alternatives filled, decision placeholder). `/design` accepts or creates ADRs (completes the decision section). Status lifecycle: proposed → accepted → superseded/deprecated. ADRs use sequential 3-digit numbering (ADR-000, ADR-001, etc.) and live in `docs/decisions/`.

### AC-2: C4 Mermaid diagrams with Neon Dark styling
Three levels of diagrams: Level 1 System Context (`docs/architecture/system-context.md`), Level 2 Container (`docs/architecture/containers.md`), Level 3 Component (`docs/architecture/components/{domain}.md`). All use Neon Dark flowchart styling with specific color palette (actors: hot pink, core: cyan, services: purple, external: violet, data: mint). Each node includes bold title, responsibility description, and technology stack. Diagrams include Coupling Notes (runtime, build-time, data dependencies) and Cohesion Assessment (Level 3 only).

### AC-3: Compliance checking and health scanning
`/discern` adds ADR Compliance to the review checklist — for each referenced ADR, checks whether implementation follows the decision and flags violations. `/diagnose` performs comprehensive health analysis: coupling violations (code imports not in diagrams), cohesion drift (cross-domain imports), ADR health (stale proposals, contradictions, superseded ADRs still referenced), and diagram staleness (>90 days since last update per frontmatter `updated` field).

### AC-4: Schema definitions for ADRs and diagrams
`schemas/adr.schema.md` defines: required fields (adr_version, type: "adr", id: ADR-NNN, title, status, created, deciders), optional fields (domain, spec_refs, backlog_ref, superseded_by, supersedes, tags), status enum (proposed/accepted/deprecated/superseded), and validation rules (superseded requires superseded_by). `schemas/architecture-diagram.schema.md` defines: required fields (diagram_version, type: "architecture-diagram", level 1-3, title, updated, updated_by), optional fields (domain for L3, backlog_ref, adr_refs), and Neon Dark color palette specification.

## Evidence

### Source Code
- `skills/architecture-awareness/SKILL.md`: Full skill definition with per-command behaviors and architecture update rules
- `commands/arch-init.md`: Architecture bootstrapping command
- `schemas/adr.schema.md`: ADR frontmatter schema with validation rules
- `schemas/architecture-diagram.schema.md`: C4 diagram schema with Neon Dark styling specification

### Documentation
- `docs/decisions/ADR-000-use-adrs-for-architecture-decisions.md`: Bootstrapping record
- `docs/decisions/ADR-001-thin-orchestrator.md`: Example accepted ADR
- `docs/decisions/ADR-002-designer-integration-commands-plus-skill.md`: Example accepted ADR
- `docs/architecture/system-context.md`: Level 1 diagram
- `docs/architecture/containers.md`: Level 2 diagram
