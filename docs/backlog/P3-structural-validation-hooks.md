---
spec_version: "1.0"
type: shaped-work
id: structural-validation-hooks
title: "Structural Validation Hooks for Genie-Team Artifacts"
status: shaped
created: 2026-02-11
appetite: small
priority: P3
target_project: genie-team
author: shaper
depends_on: []
tags: [hooks, validation, frontmatter, quality, structural]
acceptance_criteria:
  - id: AC-1
    description: "PostToolUse hook on Write validates YAML frontmatter of docs/ files against schema requirements (required fields present, valid status values, cross-references point to existing files)"
    status: pending
  - id: AC-2
    description: "PreToolUse hook on Write/Edit blocks modifications to installed paths (.claude/rules/, .claude/skills/, .claude/commands/) when the source file exists in the canonical source directory"
    status: pending
  - id: AC-3
    description: "Stop hook verifies that the current command produced expected artifacts (e.g., /define created a file in docs/backlog/, /discover created a file in docs/analysis/)"
    status: pending
---

# Shaped Work Contract: Structural Validation Hooks

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Problem:** Genie-team's document artifacts (backlog items, specs, ADRs, analysis docs) have structural requirements — YAML frontmatter with required fields, valid status values, cross-references to existing files. Currently, compliance is behavioral (rules and skills tell Claude what to include). Nothing validates the output.

**Honest assessment from discovery:** This is a **marginal value proposition**. The discovery (`docs/analysis/20260211_discover_claude_hooks_vs_git_hooks.md`) found:

- **Frontmatter validation catches rare issues.** Claude Code's rules system has high compliance. Missing frontmatter fields happen occasionally, not frequently. The `/discern` review step already catches these.
- **Protected path blocking addresses a rare problem.** Claude editing installed `.claude/` files directly (instead of editing the source) happens infrequently. When it does, it's usually because the user asked for it.
- **Artifact completeness is nice but redundant.** If `/define` doesn't create a backlog file, the user notices immediately. The Stop hook would catch what's already obvious.

**The real trade-off:** Each hook adds complexity (scripts to maintain, configuration to distribute, latency on every tool call it matches) for enforcement that the behavioral system mostly handles. The question is whether "mostly" is good enough, or whether the remaining gap justifies the cost.

**This item exists so the Navigator can make an informed decision to build, park, or discard it.**

## Evidence & Insights

- **Discovery verdict:** "Marginal value. The real documentation problems are content problems." (Section 3B)
- **No telemetry on compliance rate.** The key unknown is how often rules/skills are actually followed vs. ignored. If compliance is 99%, these hooks catch 1 issue per 100 writes. If compliance is 80%, they catch 20.
- **Latency cost is real.** A PostToolUse hook on Write fires on every file write. In a `/deliver` session with 30+ writes, even a 200ms hook adds 6 seconds of cumulative latency.
- **Maintenance cost is real.** Hook scripts need to track schema changes. When a new required frontmatter field is added, the validation script must be updated.

## Appetite & Boundaries

- **Appetite:** Small (1-2 days) if built
- **Boundaries:**
  - Frontmatter validation script (bash + yq/grep)
  - Protected path blocking script (bash, path matching)
  - Artifact completeness script (bash, file existence checks)
  - Hook configuration for `.claude/settings.json`
- **No-gos:**
  - No prompt or agent hooks (no LLM cost for structural checks)
  - No content quality validation (that's judgment, not structure)
  - No blocking on non-critical issues (warn via stderr, don't block)
- **Fixed elements:**
  - Must not slow down interactive workflow noticeably (<500ms per hook invocation)
  - Must be bypassable (user can disable hooks if they interfere)
  - Must work without external dependencies beyond bash and jq

## Goals

**Outcome hypothesis:** "Structural validation hooks catch frontmatter errors, path violations, and missing artifacts at write-time — reducing the `/discern` review burden for structural issues and ensuring document consistency."

**Honest counter-hypothesis:** "The behavioral system already catches most structural issues, and the hooks add complexity and latency for marginal improvement. The maintenance cost of hook scripts exceeds the value of the rare catches."

**Success signals (if built):**
- At least 1 structural issue caught per 20 sessions that the behavioral system missed
- Hook latency under 500ms per invocation
- No false positives that block legitimate work

## Risks & Assumptions

| Assumption | Type | Confidence | Test |
|------------|------|------------|------|
| Behavioral compliance is imperfect enough to justify hooks | Value | **Low** | Run 10 sessions, audit frontmatter compliance rate. If >95%, hooks aren't worth it. |
| Hook latency is acceptable | Usability | Medium | Benchmark frontmatter validation script on representative docs |
| yq/jq is available in developer environments | Feasibility | Medium | Survey target environments; fallback to grep-based validation if needed |
| Hook maintenance cost is manageable | Viability | Medium | Track schema changes over 3 months; count required hook updates |

## Options (Ranked)

### Option 1: Park until evidence exists (Recommended)

- **Description:** Don't build yet. Instead, manually audit frontmatter compliance over the next 10-20 sessions. If compliance is below 90%, revisit. If above 95%, discard.
- **Pros:** No wasted effort; evidence-based decision; zero complexity added
- **Cons:** Delays potential improvement; manual audit is tedious
- **Appetite fit:** Zero — just observation

### Option 2: Build lightweight validation only

- **Description:** Build only the frontmatter validation hook (PostToolUse on Write to `docs/`). Skip protected paths and artifact completeness.
- **Pros:** Narrowest scope; addresses the most common structural issue; can evaluate value before expanding
- **Cons:** Still adds latency and maintenance for marginal value
- **Appetite fit:** Small — one script + configuration

### Option 3: Build all three hooks

- **Description:** Frontmatter validation + protected path blocking + artifact completeness.
- **Pros:** Complete structural enforcement layer
- **Cons:** Highest complexity and maintenance; artifact completeness is redundant with user observation; protected paths is a rare problem
- **Appetite fit:** Small but unnecessary breadth

## Dependencies

- None

## Routing

- [ ] **Navigator Decision** — Park (Option 1) vs Build (Option 2 or 3)

**Rationale:** The discovery found marginal value. The Shaper's recommendation is Option 1 (park until evidence justifies building). But this is a Navigator call — if the experience of working with genie-team shows structural drift is a real problem, Option 2 becomes worthwhile.

## Artifacts

- **Contract saved to:** `docs/backlog/P3-structural-validation-hooks.md`
- **Discovery ref:** `docs/analysis/20260211_discover_claude_hooks_vs_git_hooks.md`

---

# End of Shaped Work Contract
