---
spec_version: "1.0"
type: shaped-work
id: GT-33
title: "Spec-Driven Bugfix Path"
status: designed
created: "2026-02-13"
appetite: small
priority: P3
author: shaper
tags: [bugfix, workflow, spec-awareness, corrections]
acceptance_criteria:
  - id: AC-1
    description: "/bugfix accepts optional --spec flag with a path to a spec, brand guide, or ADR"
    status: pending
  - id: AC-2
    description: "When --spec is provided, /bugfix auto-populates the problem statement by comparing spec values against implementation"
    status: pending
  - id: AC-3
    description: "Spec-driven bugfix light shaping includes source_of_truth reference and specific drift description"
    status: pending
  - id: AC-4
    description: "/bugfix without --spec continues to work exactly as before (backward compatible)"
    status: pending
  - id: AC-5
    description: "Spec-driven bugfix review (/discern) validates the fix against the spec values, not just regression tests"
    status: pending
---

# Shaped Work Contract: Spec-Driven Bugfix Path

## Problem

When a fix is "value X doesn't match spec Y," the only paths are the full `/feature` lifecycle (disproportionate overhead) or `/bugfix` (doesn't reference specs). The `/bugfix` command accepts an issue description and produces a light shape (problem/expected/actual/scope/acceptance), but it has no mechanism to reference a source of truth — no `--spec` flag, no auto-population from drift detection.

This means spec-drift corrections (~20 LOC each in the field report) require the operator to either:
1. Run full lifecycle (discover→define→design→deliver→discern) — disproportionate
2. Use `/bugfix` and manually describe the drift — disconnected from the spec system

**Evidence:** Field report — 2 follow-up fix contracts (4 visual issues, ~20 CSS lines each) required full lifecycle because `/bugfix` couldn't reference the brand guide as source of truth.

## Appetite & Boundaries

- **Appetite:** Small (1-2 days)
- **In scope:** Adding `--spec <path>` flag to `/bugfix`. Auto-populating problem statement from spec comparison. Critic adaptation for spec-driven review.
- **No-gos:** No automatic drift detection (operator must identify the drift). No changes to `/bugfix --urgent` or `--test-only` paths. No expansion of `/bugfix` into a "mini-feature" command.
- **Fixed elements:** `/bugfix` remains the fast path for bugs. The `--spec` flag is additive; all existing behavior preserved.

## Goals & Outcomes

- Operator can fix spec-drift issues through `/bugfix --spec docs/brand/guide.md "accent color wrong"` instead of full lifecycle
- Problem statement auto-populates with: source of truth path, expected value, where the drift was found
- Review validates fix against the spec, closing the loop

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| `/bugfix --spec` is meaningfully faster than full lifecycle for corrections | value | Time a spec-drift fix both ways; compare |
| Operators will remember to use `--spec` flag when appropriate | usability | Could be mitigated by GT-30 (transition guidance) suggesting it |
| Auto-populating problem statement from spec comparison is feasible for different spec types (brand, capability, ADR) | feasibility | Test with brand guide (YAML values), capability spec (AC descriptions), ADR (decision text) |

## Dependencies

- **Benefits from GT-31** (lightweight contract variants): If `correction` work_type exists, `/bugfix --spec` could produce a correction contract instead of a light shape. But this is an enhancement, not a blocker.
- **Benefits from GT-30** (transition guidance): brand-awareness could suggest `/bugfix --spec` when it detects drift during `/context:refresh`.

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Add `--spec` flag to `/bugfix` command | Minimal change, additive, backward compatible | Operator must know to use the flag | Recommended |
| B: Create separate `/correct` command | Clear UX separation for spec-drift work | Another command to learn; overlaps with `/bugfix` | Not recommended |
| C: Auto-detect spec drift in `/bugfix` (no flag needed) | Magic experience | Complex; requires scanning all specs against all code; slow | Over-engineering |

## Routing

- [x] **Ready for design** — Small scope, no architectural unknowns
- [ ] Needs Architect spike

**Next:** `/deliver docs/backlog/P3-spec-driven-bugfix.md`

---

# Design

## Overview

Add a `--spec <path>` flag to the `/bugfix` command that loads a source-of-truth document (spec, brand guide, or ADR) and auto-populates the light shaping with drift context. The fix is then reviewed against the source of truth rather than just regression tests.

## Architecture

**Minimal extension.** `/bugfix` remains a single command file. The `--spec` flag adds one behavior branch: load the referenced document, extract relevant values, and inject them into the light shaping template. No new commands, no new skills, no schema changes.

## Component Design

### 1. `/bugfix` command — `.claude/commands/bugfix.md`

**Modify: Arguments section (L7-12)**

Add:

```markdown
  - `--spec <path>` - Path to source of truth (spec, brand guide, or ADR) for spec-drift fixes
```

**Modify: Workflow section (L18-35)**

Add a `--spec` branch:

```markdown
/bugfix --spec docs/brand/guide.md "accent color wrong in dark theme"
    │
    ├─→ Load Source of Truth
    │   └─→ Read spec/brand guide/ADR at provided path
    │   └─→ Extract relevant values (colors, ACs, decisions)
    │
    ├─→ Spec-Drift Light Shaping
    │   └─→ Auto-populated problem (expected vs actual from spec)
    │   └─→ Source reference
    │   └─→ Acceptance criteria: value matches spec
    │
    ├─→ /deliver (bug fix mode)
    │   └─→ Fix the drift
    │   └─→ Verify value matches spec
    │
    └─→ /discern (spec-validated)
        └─→ Value matches source of truth?
        └─→ No regression?
```

**Modify: Light Shaping Output section (L39-53)**

Add spec-drift variant:

```markdown
### Spec-Drift Light Shaping Output (when --spec provided)

# Spec-Drift Fix: [Issue]

**Source of truth:** [path from --spec flag]
**Problem:** [Value X doesn't match spec Y]
**Expected** (per spec): [value from source document]
**Actual** (in implementation): [current value found in code]
**Location:** [file:line or variable name]
**Scope:** [What we will/won't touch — constrained to the drift]

**Acceptance:**
- [ ] Value matches source of truth
- [ ] No regression in related behavior
- [ ] All tests pass
```

**Modify: Usage Examples (L57-83)**

Add spec-driven example:

```markdown
/bugfix --spec docs/brand/theoatrix.md "accent color wrong in dark theme"
> Spec-drift fix started
>
> Source: docs/brand/theoatrix.md
> Expected (dark theme accent): #4DB6AC
> Actual (CSS variable --accent): #26A69A
> Location: src/theme/dark.css:14
>
> Proceeding to fix...
>
> [Crafter updates CSS variable]
> Value now matches brand guide
>
> [Critic spec-validated review]
> Verdict: APPROVED
> Value matches source of truth, no regression
```

**Modify: Routing section (L87-92)**

Add:

```markdown
- **Spec drift**: Use `--spec` with path to source of truth
```

**Modify: Notes section (L96-102)**

Add:

```markdown
- `--spec` loads source of truth for drift-based fixes
- Spec-drift fixes are validated against the source document, not just tests
```

### 2. Critic review adaptation

The `/discern` command (or brand-awareness/spec-awareness skills) already validates against specs and brand guides when `spec_ref` or `brand_ref` are present. For `--spec` bugfixes, the light shaping output includes the source of truth path, which the Critic uses for validation. No separate Critic changes needed — the existing brand compliance and spec AC checking cover this.

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Add `--spec <path>` to Arguments section | `.claude/commands/bugfix.md` |
| AC-2 | Auto-populate light shaping: read spec, extract values, compare to implementation | `.claude/commands/bugfix.md` |
| AC-3 | Spec-Drift Light Shaping Output template with source_of_truth, expected, actual | `.claude/commands/bugfix.md` |
| AC-4 | Existing workflow section unchanged when `--spec` not provided | `.claude/commands/bugfix.md` |
| AC-5 | Existing Critic brand compliance + spec AC validation handles source-of-truth checking | No changes needed |

## Implementation Guidance

**Sequence:**
1. `.claude/commands/bugfix.md` — all changes are in this one file

**Key considerations:**
- The `--spec` flag accepts any path — spec, brand guide, or ADR. The command reads the document and extracts relevant structured data (YAML frontmatter) to populate the problem statement.
- For brand guides: extract color values from `visual.colors` or `visual.colors.themes`
- For capability specs: extract relevant AC descriptions
- For ADRs: extract the Decision section
- The auto-populated problem statement is a starting point — the operator can refine it before the Crafter proceeds

**Test strategy:**
- Run `/bugfix "login broken"` without `--spec` → verify unchanged behavior
- Run `/bugfix --spec docs/brand/guide.md "wrong accent"` → verify source of truth loaded and light shaping auto-populated
- Run `/bugfix --spec docs/specs/domain/cap.md "AC-3 not met"` → verify spec ACs extracted

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Source document parsing varies by type (brand vs spec vs ADR) | Med | Low | All use YAML frontmatter — standard parsing. The genie reads the document and extracts what's relevant. |
| `--spec` adds complexity to a deliberately simple command | Low | Med | Additive — all existing paths unchanged. `--spec` is opt-in. |

## Routing

Ready for Crafter. Single file change, no architectural unknowns.
