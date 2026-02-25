---
spec_version: "1.0"
type: spec
id: spec-driven-development
title: Spec-Driven Development
status: active
created: 2026-02-25
domain: knowledge
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      All commands follow the common spec loading pattern: read spec_ref from backlog
      frontmatter, warn on missing or broken ref, never block workflow — specs are
      valuable but optional
    status: met
  - id: AC-2
    description: >-
      /spec:init bootstraps rich specs from existing source code, tests, and docs with
      interactive batch presentation (up to 5 at a time), user-controlled domain assignment,
      and support for merging, skipping, and renaming capabilities
    status: met
  - id: AC-3
    description: >-
      /define links to existing specs with behavioral delta (current behavior quoted from
      spec ACs, proposed changes documented, rationale provided) or creates new specs for
      new capabilities with user-chosen domain assignment
    status: met
  - id: AC-4
    description: >-
      /deliver loads spec ACs as TDD test targets; /discern updates spec AC statuses
      (pending to met or unmet) and appends Review Verdict section; /done preserves specs
      on archive (specs are never archived, deleted, or moved)
    status: met
  - id: AC-5
    description: >-
      After any spec write, the affected domain's README.md is auto-regenerated with
      capability count, AC summary (met/total with pending/unmet breakdown), and one-line
      description per capability, sorted alphabetically
    status: met
---

# Spec-Driven Development

The spec-awareness skill ensures spec-driven behavior across all workflow commands. Specs are the persistent source of truth for what the system does — organized by domain (product-level bounded context) and capability (specific behavior within a domain). Backlog items describe transient changes; specs persist.

Specs follow a dual-format convention: YAML frontmatter for machine-readable data (acceptance criteria with id/description/status) and markdown body for human-readable narrative (design constraints, implementation evidence, review verdicts). The skill manages the full spec lifecycle from creation through `/spec:init` or `/define`, through AC tracking via `/deliver` and `/discern`, to preservation on `/done`.

## Acceptance Criteria

### AC-1: Common spec loading pattern
All commands that read specs follow the same pattern: (1) read `spec_ref` from backlog item frontmatter, (2) if present, read the referenced spec file, (3) if missing, warn and continue, (4) if pointing to nonexistent file, warn and continue, (5) never block — specs are valuable but optional. This pattern is used by `/design`, `/deliver`, `/discern`, `/handoff`, `/done`, and `/context:load`.

### AC-2: Spec bootstrapping via /spec:init
The `/spec:init` command performs a deep scan of source code, test files, project docs, config files, and directory structure. It identifies behavioral capabilities (grouped by what the system does, not file boundaries), checks for existing specs to avoid duplication, presents discoveries in batches of up to 5 with name, description, evidence, and proposed ACs. Users control domain assignment per batch and can merge, skip, rename, or accept capabilities.

### AC-3: Behavioral delta in /define
When changing an existing capability, `/define` discovers the existing spec via `spec_ref` or search, then documents the behavioral delta: current behavior (quoted from spec ACs), proposed changes (what each AC will change to plus new ACs), and rationale. When creating a new capability, it asks for domain assignment and creates the spec at `docs/specs/{domain}/{capability}.md` with `status: active`.

### AC-4: AC lifecycle across commands
`/deliver` loads spec ACs as TDD test targets — each pending AC maps to at least one test case. `/discern` evaluates each AC against implementation and updates frontmatter statuses (pending → met or unmet), appending a Review Verdict section. `/done` archives the backlog item but never the spec — specs retain all accumulated knowledge (constraints, evidence, verdicts).

### AC-5: Auto-generated Domain READMEs
After any write to a spec, the skill regenerates `docs/specs/{domain}/README.md`. The README lists capabilities alphabetically with title, status, AC counts (met/total with pending/unmet breakdown), and a one-line summary extracted from the spec body. The README header shows total capability count and aggregate AC status. READMEs are fully generated — never hand-edited.

## Evidence

### Source Code
- `skills/spec-awareness/SKILL.md`: Full skill definition with per-command behaviors, spec update rules, and Domain README format
- `commands/spec-init.md`: Spec bootstrapping command with batch presentation protocol
- `commands/define.md`: Work shaping with spec linking and behavioral delta

### Documentation
- `docs/specs/workflow/`: Example domain with active specs
- `docs/specs/genies/`: Example domain with designer spec
