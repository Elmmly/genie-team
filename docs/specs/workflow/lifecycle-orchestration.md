---
spec_version: "1.0"
type: spec
id: lifecycle-orchestration
title: Lifecycle Phase Orchestration
status: active
created: 2026-02-25
domain: workflow
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      /feature chains discover → define → design → deliver → discern with manual gates
      at each transition, allowing the user to redirect, refine, or reject before the
      next phase begins
    status: met
  - id: AC-2
    description: >-
      /bugfix runs light shape → deliver → discern for quick fixes; /spike runs time-boxed
      technical investigation producing analysis output; /cleanup runs diagnose → tidy for
      safe debt reduction
    status: met
  - id: AC-3
    description: >-
      /commit produces conventional commit messages with backlog item references and genie
      attribution (Co-Authored-By); /done archives completed work to docs/archive/ while
      preserving specs, ADRs, and brand guides as persistent knowledge
    status: met
  - id: AC-4
    description: >-
      Context management commands maintain session awareness: /context:load initializes
      session with spec/ADR/brand/backlog status; /context:summary produces end-of-session
      handoff; /context:recall searches past work; /context:refresh detects drift between
      artifacts and codebase
    status: met
---

# Lifecycle Phase Orchestration

The workflow orchestration system chains genies through the 7 D's lifecycle (discover → define → design → deliver → discern → commit → done) via multiple modes depending on the level of control desired. It provides guided execution with manual gates (`/feature`), quick workflow shortcuts (`/bugfix`, `/spike`, `/cleanup`), git workflow integration (`/commit`), work archival (`/done`), explicit phase transitions (`/handoff`), and session context management (`/context:*`).

This capability covers the interactive orchestration layer. The autonomous lifecycle runner (headless `genies` CLI and in-session `/run`) is separately specified in `docs/specs/workflow/autonomous-lifecycle.md`.

## Acceptance Criteria

### AC-1: Guided lifecycle via /feature
The `/feature` command runs the full lifecycle (discover → define → design → deliver → discern) with manual gates at each phase transition. At each gate, the user reviews the output and can: proceed to the next phase, redirect (change approach), refine (adjust the current output), or reject (stop the workflow). This is the recommended mode for learning the workflow or for complex features where steering is needed.

### AC-2: Quick workflow shortcuts
`/bugfix` runs a compressed flow (light shape → deliver → discern) for well-understood bug fixes with clear reproduction steps. `/spike` runs a time-boxed technical investigation producing analysis output to `docs/analysis/` — no backlog item or code changes. `/cleanup` chains `/diagnose` (Architect scans codebase health) then `/tidy` (Tidier executes safe cleanup) for debt reduction.

### AC-3: Git workflow and work archival
`/commit` produces conventional commit messages following commitlint standards (type(scope): description) with backlog item references (Refs: docs/backlog/{item}.md) and genie attribution (Co-Authored-By: {Genie Name}). `/done` archives completed work: moves the backlog item to `docs/archive/`, but never archives specs, ADRs, or brand guides — these persist as permanent project knowledge.

### AC-4: Context management commands
`/context:load` initializes a session by scanning for existing specs (count by status, domains), ADRs (count by status, staleness), brand guides (status, tokens sync), and active backlog items, then recommends next steps. `/context:summary` produces an end-of-session handoff document. `/context:recall` searches past work in docs/analysis/, docs/archive/, and docs/backlog/. `/context:refresh` detects drift between diagrams and code structure, between brand guide and tokens, and reports unspecified capabilities.

## Evidence

### Source Code
- `commands/feature.md`: Guided lifecycle command
- `commands/bugfix.md`: Quick fix shortcut
- `commands/spike.md`: Technical investigation
- `commands/cleanup.md`: Debt reduction shortcut
- `commands/commit.md`: Conventional commit command
- `commands/done.md`: Work archival command
- `commands/handoff.md`: Explicit phase transition
- `commands/context-load.md`: Session initialization
- `commands/context-summary.md`: Session handoff
- `commands/context-recall.md`: Past work search
- `commands/context-refresh.md`: Drift detection
- `commands/genie-help.md`: Command reference
- `commands/genie-status.md`: Current work status

### Tests
- `tests/test_execute.sh`: 62 tests covering command execution patterns
