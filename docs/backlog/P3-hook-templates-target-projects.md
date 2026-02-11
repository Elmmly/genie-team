---
spec_version: "1.0"
type: shaped-work
id: hook-templates-target-projects
title: "Claude Hook & Git Hook Templates for Target Projects"
status: shaped
created: 2026-02-11
appetite: small
priority: P3
target_project: genie-team
author: shaper
depends_on: []
tags: [hooks, git-hooks, target-projects, formatting, templates]
acceptance_criteria:
  - id: AC-1
    description: "A recommended Claude hook configuration exists for target projects: PostToolUse on Write/Edit that runs the project's configured formatter (prettier, black, gofmt, etc.) — with a detection mechanism or user-configured formatter path"
    status: pending
  - id: AC-2
    description: "A recommended git hook configuration exists for target projects: commit-msg hook with commitlint validation matching the conventional-commits skill's format"
    status: pending
  - id: AC-3
    description: "Templates are distributed via install.sh as an optional target (--hooks flag or similar), not installed by default"
    status: pending
  - id: AC-4
    description: "Documentation explains which hooks genie-team recommends, why, and how they complement the behavioral system (rules + skills)"
    status: pending
---

# Shaped Work Contract: Hook Templates for Target Projects

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Problem:** Target projects that consume genie-team get behavioral enforcement (rules + skills) but no deterministic tooling. Two specific gaps exist:

1. **Code formatting.** Claude spends tokens getting formatting right. A PostToolUse hook that auto-runs the project's formatter after every Write/Edit would make formatting deterministic and save tokens — Claude can focus on logic, the formatter handles style.

2. **Commit message validation.** The `conventional-commits` skill guides Claude toward proper format, but nothing validates the final message. A git commit-msg hook with commitlint provides defense-in-depth — catching the rare case where the skill's guidance isn't followed perfectly.

**Who benefits:** Developers using genie-team in application projects (not genie-team itself — it's a prompt engineering project with no code to format).

**Value proposition — honest assessment:**
- Auto-format hook: **Medium value.** Saves tokens on formatting round-trips. The amount saved depends on how much formatting work Claude currently does. Deterministic formatting is a genuine quality improvement for code consistency.
- Git hooks: **Low-medium value.** Defense-in-depth for commit messages. The behavioral skill handles this well; the git hook is a safety net for the rare miss. Standard tooling (commitlint, husky) already exists — genie-team would provide a recommended config, not a novel tool.

## Evidence & Insights

- **Discovery:** `docs/analysis/20260211_discover_claude_hooks_vs_git_hooks.md` — Section 3A identified auto-formatting as the one genuine software quality hook; Section 4 mapped commit validation to git hooks
- **Token saving hypothesis:** Claude currently spends tokens on formatting corrections. Exact savings unknown (evidence gap), but auto-format eliminates the concern entirely.
- **Standard tooling exists:** commitlint, husky, lint-staged, prettier — the templates configure existing tools, not build new ones

## Appetite & Boundaries

- **Appetite:** Small (1-2 days)
- **Boundaries:**
  - Claude hook template: `.claude/settings.json` snippet with PostToolUse auto-format hook
  - Git hook template: commitlint config + husky setup instructions
  - Documentation: when to use which, how they complement behavioral enforcement
  - Optional install via `install.sh` (new `--hooks` flag)
- **No-gos:**
  - Not installed by default (opt-in only — target projects choose their own tooling)
  - No bundling of formatter binaries (project provides its own prettier/black/etc.)
  - No custom validation logic (use standard tools)
  - No enforcement for genie-team itself (it's a prompt engineering project)
- **Fixed elements:**
  - Must work with any formatter (configurable path/command)
  - Must not break projects that don't opt in
  - Must document trade-offs honestly (latency cost of hooks, maintenance of configs)

## Goals

**Outcome hypothesis:** "Target projects that install hook templates get deterministic formatting and commit validation as a complement to behavioral enforcement — reducing token spend on formatting and providing defense-in-depth on commit messages."

**Success signals:**
- A target project can install templates and see auto-formatting working on next `/deliver`
- Commit messages that don't match conventional format are rejected at git level
- Templates are simple enough to customize (not opinionated frameworks)

## Risks & Assumptions

| Assumption | Type | Confidence | Test |
|------------|------|------------|------|
| Auto-formatting saves meaningful tokens | Value | Medium | Measure token spend on formatting in a representative `/deliver` session with and without the hook |
| Projects have a formatter already configured | Feasibility | High | Most modern projects use prettier/black/gofmt — the hook calls whatever's configured |
| PostToolUse hook latency is acceptable | Usability | Medium | Measure wall-clock time of running prettier on a typical file via hook |
| Git hooks don't interfere with genie workflow | Feasibility | Medium | Test commitlint hook with genie-produced commit messages |

## Options (Ranked)

### Option 1: Template files + documentation (Recommended)

- **Description:** Provide `.claude/hooks/` scripts and `.husky/` configs as templates in `templates/hooks/`. Document in CLI contract.
- **Pros:** Simple, standard tooling, opt-in, easy to customize
- **Cons:** Templates may drift from tool updates; maintenance burden
- **Appetite fit:** Small — templates + docs

### Option 2: install.sh auto-detection

- **Description:** `install.sh` detects project language/tooling and generates appropriate hooks automatically.
- **Pros:** Zero-config for users
- **Cons:** Complex detection logic; many edge cases; over-engineering for templates
- **Appetite fit:** Too big — detection logic is a rabbit hole

## Dependencies

- None — uses standard tooling (prettier, commitlint, husky)

## Routing

- [ ] **Architect** — Design template structure and install.sh integration
- [x] **Crafter** — Straightforward template creation, minimal design needed

**Rationale:** This is template/documentation work, not architectural. The templates wrap standard tools with recommended configurations. Direct to Crafter.

## Artifacts

- **Contract saved to:** `docs/backlog/P3-hook-templates-target-projects.md`
- **Discovery ref:** `docs/analysis/20260211_discover_claude_hooks_vs_git_hooks.md`

---

# End of Shaped Work Contract
