---
spec_version: "1.0"
type: shaped-work
id: precommit-validation-pipeline
title: "Pre-commit Validation Pipeline by Determinism Tier"
status: shaped
created: 2026-02-11
appetite: medium
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [pre-commit, linting, validation, quality, git-hooks]
acceptance_criteria:
  - id: AC-1
    description: "Tier 1 (deterministic linters): YAML, JSON, and shell scripts are validated by language-specific linters on pre-commit — invalid syntax is rejected before it enters the repo"
    status: pending
  - id: AC-2
    description: "Tier 2 (structural consistency): frontmatter schema validation checks required fields, valid enum values, and naming conventions on docs/ files — missing or invalid fields are rejected on pre-commit"
    status: pending
  - id: AC-3
    description: "Tier 3 (referential integrity): cross-references in frontmatter (spec_ref, adr_refs, backlog_ref) are validated to point to existing files — broken references are rejected on pre-commit"
    status: pending
  - id: AC-4
    description: "Tier 4 (architectural alignment): source/installed copy sync is validated — changes to .claude/commands/, .claude/rules/, etc. without corresponding source changes are flagged on pre-commit"
    status: pending
  - id: AC-5
    description: "Pipeline is standard tooling (pre-commit framework or husky + custom scripts), not Claude-specific hooks — works for any contributor or tool, not just Claude sessions"
    status: pending
---

# Shaped Work Contract: Pre-commit Validation Pipeline

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Problem:** Genie-team produces structured artifacts (YAML frontmatter, JSON configs, shell scripts, cross-referenced markdown docs) but has no deterministic validation. Quality enforcement relies entirely on Claude's behavioral system (rules + skills) and human review (`/discern`). Both are judgment-based — they catch most issues but can't guarantee structural correctness.

**What this misses:**
- A malformed YAML frontmatter field silently breaks downstream tools (the post-compaction hooks depend on parseable frontmatter)
- A broken `spec_ref` pointing to a nonexistent file means `/design` and `/deliver` load nothing and proceed without spec context
- Editing `.claude/commands/commit.md` instead of `commands/commit.md` causes silent drift that's lost on next `install.sh --sync`
- A shell script with a syntax error in `.claude/hooks/` fails silently at runtime

**Why pre-commit, not Claude hooks:** These checks should catch issues from ANY source — Claude, human edits, automated scripts. Pre-commit runs on exactly the files being committed, adds zero latency during the working session, and uses standard tooling that any contributor understands.

**Organizing principle — determinism tiers:**

| Tier | What it checks | Determinism | Tools |
|------|---------------|-------------|-------|
| 1. Syntax linting | Valid YAML, JSON, shell syntax | Fully deterministic | yamllint, jsonlint, shellcheck |
| 2. Schema validation | Required frontmatter fields, valid enum values, naming conventions | Deterministic against schema | Custom script (bash + yq/grep) |
| 3. Referential integrity | Cross-references resolve to existing files | Deterministic (file existence) | Custom script (bash) |
| 4. Architectural alignment | Source/installed copy sync, folder structure matches conventions | Semi-deterministic (pattern matching) | Custom script (bash + diff) |

Each tier builds on the previous. Tier 1 is standard tooling with zero custom code. Tier 4 is project-specific logic. The boundary between "what pre-commit can check" and "what requires judgment" falls after Tier 4 — anything beyond (content quality, design coherence, AC coverage) belongs in `/discern`.

## Evidence & Insights

- **Discovery:** `docs/analysis/20260211_discover_claude_hooks_vs_git_hooks.md` — identified that deterministic checks belong in git hooks, not Claude hooks
- **Session evidence:** Source/installed copy drift happened in this session (manual sync of `commands/` -> `dist/` -> `.claude/commands/` required)
- **Post-compaction hooks dependency:** The context re-injection hooks (`track-command.sh`) parse frontmatter with `sed`/`grep`. Malformed YAML = silent degradation of context tracking.
- **Standard practice:** Most software projects have linting in pre-commit. Genie-team is unusual in having zero — it's a prompt engineering project, but it produces structured artifacts that benefit from the same discipline.

## Appetite & Boundaries

- **Appetite:** Medium (3-5 days) — Tier 1 is quick (standard tools), Tiers 2-4 need custom scripts and test coverage
- **Boundaries:**
  - Pre-commit framework setup (`.pre-commit-config.yaml` or `package.json` + husky)
  - Tier 1: yamllint config, shellcheck integration
  - Tier 2: Custom frontmatter validation script with schema definitions
  - Tier 3: Custom cross-reference checker
  - Tier 4: Custom source/installed sync checker
  - Test suite for custom scripts
- **No-gos:**
  - No content quality checks (that's judgment, not structure)
  - No Claude-specific hooks for validation (pre-commit only)
  - No blocking CI pipeline (pre-commit is local; CI is a separate concern)
  - No runtime dependencies beyond bash, jq, and standard linters
- **Fixed elements:**
  - Must use standard pre-commit tooling (not a custom framework)
  - Must be incremental — each tier works independently, can ship Tier 1 without Tier 4
  - Must have clear error messages that explain what's wrong and how to fix it
  - Must be bypassable (`--no-verify` for exceptional cases)

## Goals

**Outcome hypothesis:** "A tiered pre-commit pipeline catches structural issues at commit time — from basic syntax errors to broken cross-references to source/installed drift — reducing the `/discern` review burden for mechanical issues and letting review focus on content and design quality."

**Success signals:**
- `yamllint` catches a YAML syntax error that would have silently broken frontmatter parsing
- Cross-reference check catches a `spec_ref` pointing to a moved/renamed file
- Source/installed sync check catches an edit to `.claude/commands/` that missed the canonical `commands/` source

## Risks & Assumptions

| Assumption | Type | Confidence | Test |
|------------|------|------------|------|
| Standard linters (yamllint, shellcheck) are easy to configure for this project | Feasibility | High | These are mature tools with well-documented configs |
| Custom validation scripts can run fast enough for pre-commit (<2s total) | Usability | High | Frontmatter parsing + file existence checks are simple shell operations |
| Tier 4 (sync check) can be reliably detected | Feasibility | Medium | Comparing file contents between source/ and installed/ is straightforward; detecting "which is canonical" requires convention |
| Pre-commit doesn't interfere with genie workflow | Usability | High | Standard git hooks; Claude Code respects pre-commit hooks by default |

## Options (Ranked)

### Option 1: Incremental tiers, Tier 1 first (Recommended)

- **Description:** Ship each tier independently. Start with Tier 1 (standard linters — zero custom code). Add Tiers 2-4 incrementally as custom scripts.
- **Pros:** Immediate value from Tier 1; each tier is independently useful; can stop at any tier if diminishing returns
- **Cons:** Multiple iterations; Tier 2-4 need custom scripts with their own test/maintenance burden
- **Appetite fit:** Medium — Tier 1 is 1 day, Tiers 2-4 add 1-2 days each

### Option 2: All tiers at once

- **Description:** Design and build the full pipeline in one pass.
- **Pros:** Coherent design; single review cycle
- **Cons:** Larger batch; risk of over-engineering the later tiers before learning from the earlier ones
- **Appetite fit:** Medium — tighter but doable

## Dependencies

- None — uses standard tooling

## Routing

- [x] **Architect** — Design the validation schema for Tier 2, define source/installed canonical mapping for Tier 4
- [ ] **Crafter** — Build and test the pipeline

**Rationale:** Tier 1 is standard tooling (no design needed). Tiers 2-4 need design decisions: which frontmatter fields are required per doc type, what naming conventions to enforce, how to define the source→installed mapping.

## Supersedes

This item replaces two previous backlog items that were framed around the wrong mechanism (Claude hooks instead of pre-commit):
- `P3-hook-templates-target-projects.md` — the valuable kernel (deterministic linting) is captured here; the Claude auto-format hook and commitlint template are dropped as low-value
- `P3-structural-validation-hooks.md` — frontmatter validation and path protection are captured here as pre-commit checks; artifact completeness is dropped as redundant

## Artifacts

- **Contract saved to:** `docs/backlog/P2-precommit-validation-pipeline.md`
- **Discovery ref:** `docs/analysis/20260211_discover_claude_hooks_vs_git_hooks.md`

---

# End of Shaped Work Contract
