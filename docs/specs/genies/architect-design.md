---
spec_version: "1.0"
type: spec
id: architect-design
title: Architect Technical Design
status: active
created: 2026-02-25
domain: genies
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      Architect genie definition exists at agents/architect.md with sonnet model, read + bash
      tools (Read, Grep, Glob, Bash), plan permission mode, and spec-awareness +
      architecture-awareness + pattern-enforcement skills
    status: met
  - id: AC-2
    description: >-
      /design command produces a Design Document appended to the backlog item with YAML
      frontmatter per schemas/design-document.schema.md, including AC mapping, component
      list, risk table, and implementation guidance for the Crafter
    status: met
  - id: AC-3
    description: >-
      /diagnose command scans codebase for coupling violations (undocumented cross-domain
      dependencies), ADR health issues (stale proposals, contradictions), diagram staleness
      (>90 days without update), and test coverage gaps
    status: met
  - id: AC-4
    description: >-
      /arch:init bootstraps ADR-000 and initial C4 diagrams (Level 1 System Context, Level 2
      Container) for existing projects, creating docs/architecture/ directory structure. For
      existing projects, auto-detects tech stack from indicator files. For greenfield projects
      (no indicators), prompts user to select a stack or skip.
    status: met
  - id: AC-5
    description: >-
      /arch --workshop provides an interactive 5-phase architecture workshop (Approach
      Comparison, Technical Decisions, Interface Preview, Risk Prioritization, Consolidation).
      Works in two modes: with a shaped contract (feature mode — produces Design Document
      appended to the backlog item) or without (foundation mode — produces ADRs + workshop
      summary for greenfield bootstrapping). Phase 2 surfaces tech stack selection for
      greenfield projects.
    status: met
---

# Architect Technical Design

The Architect genie creates technical designs within shaped boundaries using Domain-Driven Design (bounded contexts, aggregates), Clean Architecture (dependency inversion, layers), SOLID principles, and pragmatic engineering judgment. It defines interfaces, contracts, and component boundaries; identifies technical risks with likelihood/impact/mitigation analysis; creates ADRs for significant decisions; updates C4 diagrams when boundaries change; and provides implementation guidance for the Crafter.

The Architect also supports: `/diagnose` for codebase health scanning, `/arch:init` for bootstrapping architecture artifacts, and an interactive `/arch --workshop` mode with phases for Approach Comparison, Technical Decisions, Interface Preview, and Risk Prioritization.

## Acceptance Criteria

### AC-1: Genie definition with correct configuration
Architect genie definition at `agents/architect.md` specifies sonnet model for design judgment, tools including Bash (for git log/diff/show only), plan permission mode, and spec-awareness + architecture-awareness + pattern-enforcement skills. The Architect designs contracts and boundaries but does NOT implement them.

### AC-2: Design Document output
The `/design` command produces a Design Document appended to the backlog item. Frontmatter conforms to `schemas/design-document.schema.md` with AC mapping (how each acceptance criterion is addressed and which components implement it), component list (name, action, files), complexity assessment, and risk identification. The body includes architecture overview, interfaces, pattern adherence notes, and implementation guidance with sequence and test scenarios.

### AC-3: Codebase health diagnosis
The `/diagnose` command activates the Architect to scan codebase health. It checks: coupling violations (code imports not documented in C4 diagrams), cohesion drift (cross-domain imports), ADR health (proposed ADRs with no recent design activity, contradictory accepted ADRs), diagram staleness (>90 days since last update), and dead code or pattern violations.

### AC-4: Architecture bootstrapping
The `/arch:init` command bootstraps architecture artifacts for existing projects: creates ADR-000 (bootstrapping record), generates Level 1 System Context diagram and Level 2 Container diagram with user confirmation, creates `docs/architecture/components/` directory for Level 3 diagrams (populated later by `/design`), and reads project structure and existing specs for domain awareness. For existing projects, auto-detects tech stack from indicator files. For greenfield projects (no indicators found), prompts the user to select a stack or skip.

### AC-5: Interactive architecture workshop
The `/arch --workshop` command provides a 5-phase interactive architecture workshop: Approach Comparison (HTML side-by-side panels), Technical Decisions (interactive walk-through with greenfield stack selection), Interface Preview (code-styled HTML), Risk Prioritization (multiSelect mitigation choices), and Consolidation. Works with or without a shaped contract: feature mode (with contract) produces a Design Document appended to the backlog item; foundation mode (without contract) produces ADRs + workshop summary for greenfield bootstrapping. Phase 2 surfaces "Which tech stack?" for greenfield projects and routes to `/arch:init --stack {language}` after the workshop.

## Evidence

### Source Code
- `agents/architect.md`: Genie definition with charter, judgment rules, design document template
- `genies/architect/ARCHITECT_SPEC.md`: Detailed specification
- `genies/architect/ARCHITECT_SYSTEM_PROMPT.md`: System prompt
- `genies/architect/DESIGN_DOCUMENT_TEMPLATE.md`: Structured output template
- `commands/arch.md`: Architecture workshop command
- `commands/design.md`: Design slash command (batch)
- `commands/diagnose.md`: Diagnose slash command
- `commands/arch-init.md`: Architecture bootstrapping command
- `schemas/design-document.schema.md`: Design document schema

### Tests
- `tests/test_execute.sh`: 62 tests covering command execution and genie invocation patterns
