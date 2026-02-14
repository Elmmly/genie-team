---
spec_version: "1.0"
type: shaped-work
id: GT-31
title: "Lightweight Contract Variants for Mechanical and Correction Work"
status: designed
created: "2026-02-13"
appetite: medium
priority: P2
author: shaper
tags: [schema, shaper, contracts, workflow]
acceptance_criteria:
  - id: AC-1
    description: "Shaped work contract schema supports a work_type field with values: feature (default), migration, correction"
    status: pending
  - id: AC-2
    description: "Migration contracts require: source_of_truth (path) and file_scope (array of globs) in frontmatter; body template recommends grep-verifiable ACs where feasible"
    status: pending
  - id: AC-3
    description: "Correction contracts require: source_of_truth (path) in frontmatter and appetite: small only; drift description is a body template convention, not a validated field"
    status: pending
  - id: AC-4
    description: "Feature contracts retain current full template (problem, appetite, goals, risks, options) unchanged"
    status: pending
  - id: AC-5
    description: "Shaper selects work_type based on input characteristics: spec-driven value replacement → migration, spec-drift fix → correction, everything else → feature"
    status: pending
  - id: AC-6
    description: >-
      Critic review for migration/correction work validates against
      source_of_truth rather than requiring full product-quality review;
      discern command reads work_type and adjusts review scope
    status: pending
  - id: AC-7
    description: "Existing shaped work contracts (work_type absent) validate as feature type (backward compatible)"
    status: pending
---

# Shaped Work Contract: Lightweight Contract Variants

## Problem

The shaped work contract template assumes product discovery: problem framing, JTBD, riskiest assumptions, bet framing. This fits feature work but creates template friction for two common work types that emerged from the brand implementation field report:

1. **Mechanical migrations** — replace N values across M files against a spec (e.g., "migrate 44 hex values to brand tokens"). These are spec-driven, grep-verifiable, and have no outcome hypothesis. 5 of 6 genie-driven brand contracts were this type.

2. **Spec-drift corrections** — a value doesn't match its source of truth (e.g., "CSS variable X doesn't match brand guide value Y"). These are ~20 LOC fixes that required full lifecycle passes because no lighter template existed.

The operator adapted by omitting sections or using them awkwardly ("riskiest assumption: that we find all instances of the old hex value"). It worked but created unnecessary overhead and obscured the mechanical nature of the work.

**Evidence:** Field report — 5/6 brand contracts were mechanical, 2 follow-up corrections required full lifecycle for ~20 LOC each.

## Appetite & Boundaries

- **Appetite:** Medium (3-5 days)
- **In scope:** Schema evolution (`work_type` field + variant-specific fields), Shaper template variants, Critic review adaptation for non-feature work types.
- **No-gos:** No changes to the lifecycle sequence (all work still flows through define→design→deliver→discern). No removal of the existing feature template. No auto-detection that bypasses Shaper judgment.
- **Fixed elements:** Existing contracts without `work_type` must validate unchanged. Schema remains v1.0 (additive change, not breaking).

## Goals & Outcomes

- Mechanical work uses a template that fits: source of truth, file scope, verifiable criteria
- Correction work uses a minimal template: what drifted, fix it, verify
- Feature work is unchanged — full product discovery framing preserved
- Shaper chooses work_type based on input characteristics (not operator override)

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Three work types cover the practical taxonomy | value | Reviewed ~15 archived contracts: all map to feature (majority), migration (P0-consolidate-genies, brand migrations), or correction (follow-up CSS fixes). Cleanup/tidy work uses separate /diagnose→/tidy workflow and doesn't produce shaped contracts. Taxonomy holds. |
| Shaper can reliably distinguish work types from input | feasibility | Test with 5 example inputs: brand migration, CSS fix, new feature, refactor, performance improvement |
| Lighter templates won't encourage skipping important analysis | viability | Correction template still requires source_of_truth reference — cannot be used for genuinely complex work |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: `work_type` field in schema + Shaper template variants | Clean, backward compatible, Shaper-controlled | Requires Shaper prompt changes + schema update + Critic adaptation | Recommended |
| B: Separate `/quickfix` command (distinct from `/bugfix`) | Clear UX separation | Yet another command; risks confusion with `/bugfix` | Not recommended — extend existing contracts instead |
| C: Let operators skip sections manually (no schema change) | Zero effort | No guidance on what to skip; inconsistent contracts; Critic doesn't know to adapt review | Status quo — already proven insufficient |

## Dependencies

- **Complements GT-33** (P3-spec-driven-bugfix): The `correction` work type here is for the full lifecycle path (`/define → /deliver`). GT-33's `/bugfix --spec` is the fast path for the same class of work. They're complementary — when GT-33 lands, `/bugfix --spec` could optionally produce a correction contract. Neither blocks the other.

## Behavioral Delta

**Spec:** schemas/shaped-work-contract.schema.md

### Current Behavior
- All contracts use the same required fields: `appetite`, `acceptance_criteria`, `type: shaped-work`
- No `work_type` discriminator — template is one-size-fits-all

### Proposed Changes
- Add optional `work_type` field: enum `feature` | `migration` | `correction` (default: `feature`)
- Add optional `source_of_truth` field: path to spec, brand guide, or ADR that defines correct values
- Add optional `file_scope` field: array of file globs defining the migration surface
- Migration variant: body template focuses on source reference, file map, grep-verifiable ACs
- Correction variant: body template focuses on drift description, fix, verification

### Rationale
Template friction for mechanical work creates process overhead disproportionate to the change. Discriminated variants let the Shaper match template to work type.

## Routing

- [x] **Ready for design** — Schema evolution is additive; no architectural unknowns
- [ ] Needs Architect spike

**Next:** `/deliver docs/backlog/P2-lightweight-contract-variants.md`

---

# Design

## Overview

Add a `work_type` discriminator to the shaped work contract schema with three variants: `feature` (default, current template), `migration` (spec-driven bulk change), and `correction` (spec-drift fix). Update the Shaper's template to produce variant-appropriate contracts, and update the Critic's review behavior for non-feature work.

## Architecture

**Pattern: Discriminated schema with shared base.** All work types share the same required base fields (`spec_version`, `type`, `id`, `title`, `status`, `appetite`, `acceptance_criteria`). The `work_type` field (optional, defaults to `feature`) enables variant-specific optional fields and body templates. This is additive — existing contracts without `work_type` validate unchanged as `feature`.

## Component Design

### 1. Schema — `schemas/shaped-work-contract.schema.md`

**Add to Optional Frontmatter Fields table:**

| Field | Type | Description |
|-------|------|-------------|
| `work_type` | string, enum: `feature`, `migration`, `correction` | Work type discriminator (default: `feature`) |
| `source_of_truth` | string | Path to authoritative spec, brand guide, or ADR (required for migration/correction) |
| `file_scope` | array of strings | File globs defining the change surface (migration only) |

**Add new section: "Work Type Variants"**

```markdown
## Work Type Variants

### Feature (default)
Standard product discovery contract. Full problem framing, appetite, goals, risks, options.
No additional required fields beyond base.

### Migration
Spec-driven bulk change. Replace/update values across files against a source of truth.
- `source_of_truth` required — path to the spec defining correct values
- `file_scope` required — globs identifying files to change
- `appetite` constrained to `small` or `medium`
- Body template: Source Reference, File Map, Change Description, Verification Method
- ACs should be grep-verifiable where possible (e.g., "grep for old value returns 0 results")

### Correction
Spec-drift fix. A specific value doesn't match its source of truth.
- `source_of_truth` required — path to the spec defining the correct value
- `appetite` constrained to `small` only
- Body template: Drift Description (expected vs actual), Fix, Verification
- Minimal framing — no problem discovery, no options, no bet framing
```

**Add to Validation section:**

```markdown
7. If `work_type` is `migration` or `correction`: `source_of_truth` must be present
8. If `work_type` is `migration`: `file_scope` must be a non-empty array
9. If `work_type` is `correction`: `appetite` must be `small`
10. If `work_type` is absent: treat as `feature` (backward compatible)
```

### 2. Shaper agent — `agents/shaper.md`

**Add to Judgment Rules section, after "Appetite Setting":**

```markdown
### Work Type Selection

Select work type based on input characteristics:
- **migration** — Input references a source of truth (spec, brand guide) and describes bulk value replacement across multiple files. Key signal: "replace X with Y across N files."
- **correction** — Input describes a specific value that doesn't match its source of truth. Key signal: "value X should be Y per spec Z."
- **feature** — Everything else. Problem discovery framing applies.

When uncertain, default to `feature`. Only use `migration` or `correction` when the mechanical/spec-driven nature is clear.
```

**Add migration and correction templates after the existing Shaped Work Contract Template:**

```markdown
### Migration Contract Template

---
work_type: migration
source_of_truth: "{path to spec/brand guide/ADR}"
file_scope: ["{glob1}", "{glob2}"]
---

## Source Reference
{What the source of truth says — quote relevant values}

## File Map
{List of files in scope with what changes in each}

## Change Description
{What value(s) change from what to what}

## Verification
{How to verify: grep patterns, test commands, visual checks}
```

```markdown
### Correction Contract Template

---
work_type: correction
source_of_truth: "{path to spec/brand guide/ADR}"
---

## Drift
- **Expected** (per {source_of_truth}): {value}
- **Actual** (in implementation): {value}
- **Location:** {file:line or CSS variable name}

## Fix
{What to change}

## Verification
{How to verify the fix matches the source of truth}
```

### 3. Critic review adaptation — `agents/critic.md`

**Add to the review behavior (or the discern command):**

```markdown
### Work Type Review Adaptation

- **feature** — Full review: ACs, code quality, test coverage, security, performance, ADR/brand compliance
- **migration** — Source-of-truth review: Verify all values match source, verify file_scope coverage (no files missed), run grep verification from ACs. Skip: problem framing quality, bet assessment, strategic alignment.
- **correction** — Drift review: Verify the specific value now matches source_of_truth. Verify no regression. Skip: code quality deep-dive, architecture review.
```

### 4. Discern command — `commands/discern.md`

**Add to Context Loading section (after "READ (automatic)"):**

```markdown
- Backlog frontmatter field `work_type` → adapt review scope (see Review Checklist)
```

**Add to Review Checklist section, before item 1:**

```markdown
0. Read `work_type` from backlog frontmatter (default: `feature` if absent)
```

**Add after Review Checklist:**

```markdown
### Work Type Review Scope

- **feature** — Full checklist (items 1-9 above)
- **migration** — Items 1-2 (ACs + spec ACs), plus: verify all values match source_of_truth, verify file_scope coverage (no files missed), run grep verification from ACs. Skip: items 5-6 (security/performance deep-dive), item 8 (risk assessment).
- **correction** — Items 1-2 (ACs + spec ACs), plus: verify the specific value now matches source_of_truth, verify no regression. Skip: items 3-8 (code quality deep-dive, security, performance, error handling, risk assessment).
```

### 5. Precommit validation — `scripts/validate/validate-frontmatter.sh`

**Add validation for new fields:**
- If `work_type` present: validate enum value
- If `work_type` is `migration` or `correction`: validate `source_of_truth` is present
- If `work_type` is `migration`: validate `file_scope` is present and non-empty array
- If `work_type` is `correction`: validate `appetite` is `small`

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Add `work_type` enum to schema optional fields + validation rules | `schemas/shaped-work-contract.schema.md` |
| AC-2 | Migration variant requires `source_of_truth` + `file_scope` | `schemas/shaped-work-contract.schema.md` |
| AC-3 | Correction variant requires `source_of_truth`, constrains `appetite: small` | `schemas/shaped-work-contract.schema.md` |
| AC-4 | Feature template unchanged; `work_type` defaults to `feature` when absent | `schemas/shaped-work-contract.schema.md` |
| AC-5 | Shaper Work Type Selection judgment rule with input signal detection | `agents/shaper.md` |
| AC-6 | Critic Work Type Review Adaptation section + discern command review scope | `agents/critic.md`, `commands/discern.md` |
| AC-7 | Validation: missing `work_type` treated as `feature` | `schemas/shaped-work-contract.schema.md`, `scripts/validate/validate-frontmatter.sh` |

## Implementation Guidance

**Sequence:**
1. `schemas/shaped-work-contract.schema.md` — add fields, variants, validation rules
2. `agents/shaper.md` — add work type selection judgment rule + templates
3. `agents/critic.md` — add work type review adaptation
4. `commands/discern.md` — add work_type context loading + review scope adaptation
5. `scripts/validate/validate-frontmatter.sh` — add conditional validation for new fields

**Validation script note:** The current script does flat checks (required-per-type, enum values). Conditional validation ("if `work_type` is `migration` then `source_of_truth` must be present") requires a new function pattern — e.g., `conditional_required_for()` keyed on `type:work_type` pairs. This is a structural expansion, not a trivial addition.

**Test strategy:**
- Validate existing contracts (no `work_type`) still pass schema validation
- Create a migration contract with `source_of_truth` + `file_scope` → passes
- Create a correction contract without `source_of_truth` → fails validation
- Create a correction contract with `appetite: medium` → fails validation

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Shaper selects wrong work type | Med | Low | Default to `feature` when uncertain. Wrong type = more overhead, not less quality. |
| Correction template too minimal for edge cases | Low | Med | Operator can always use `feature` type. Correction is an option, not mandatory. |
| Schema validation breaks existing tooling | Low | High | All new fields are optional. Absent `work_type` = `feature`. Pure additive change. |

## Routing

Ready for Crafter. Schema evolution is additive; all changes are markdown edits.
