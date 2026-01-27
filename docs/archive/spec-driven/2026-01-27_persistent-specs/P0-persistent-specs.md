---
spec_version: "1.0"
type: shaped-work
id: GT-4
title: Persistent Specs as Source of Truth
status: done
created: 2026-01-27
appetite: small
priority: P0
target_project: genie-team
depends_on: [GT-1, GT-2, GT-3]
tags: [spec-driven, specs]
acceptance_criteria:
  - id: AC-1
    description: specs/ directory exists as a first-class project location, installed by install.sh
    status: met
  - id: AC-2
    description: /context:refresh writes bootstrapped specs to specs/ (not docs/analysis/)
    status: met
  - id: AC-3
    description: /context:load scans specs/ for coverage reporting
    status: met
  - id: AC-4
    description: spec-awareness skill scans specs/ instead of docs/backlog/
    status: met
  - id: AC-5
    description: Shaped work contracts can reference specs via spec_ref pointing to specs/
    status: met
  - id: AC-6
    description: execute.sh --spec accepts paths in specs/
    status: met
---

# GT-4: Persistent Specs as Source of Truth

## Problem

Specs are currently conflated with backlog items. A shaped work contract in `docs/backlog/` describes **what to change** — it gets archived when the change ships. But a spec should describe **what the system does** — it persists as long as the feature exists, gets updated over time, and serves as the living source of truth.

Today there's no concept of a persistent spec. Everything flows through the backlog lifecycle: shaped -> designed -> implemented -> reviewed -> done -> archived. Once archived, the knowledge is buried. The next person asking "what does auth do?" has to read code or dig through `docs/archive/`.

The current implementation puts bootstrapped specs in `docs/analysis/` (transient research) and expects `/define` to produce backlog items in `docs/backlog/` (also transient — archived when done). Neither location survives as a long-lived source of truth.

## Appetite

Small batch — 2 days. This is a refinement to existing work (GT-1/GT-2/GT-3), not a new system.

## Solution Sketch

**1. Introduce `specs/` as a first-class location**
- `specs/{feature}.md` — persistent, frontmatter-first feature specs
- One spec per feature/capability, not per change
- Specs accumulate ACs over time — each `/deliver` may add ACs, never remove
- Draft specs from bootstrapping have `status: draft` until human review

**2. Redirect bootstrapping output**
- `/context:refresh` writes to `specs/` not `docs/analysis/`
- Bootstrap produces draft specs directly where they'll live

**3. Redirect spec-awareness scanning**
- `/context:load` scans `specs/` for coverage reporting
- spec-awareness skill checks `specs/` for coverage
- `/deliver` reads ACs from specs, not from the backlog item

**4. Backlog items reference specs**
- Shaped work contract gets a `spec_ref` field pointing to `specs/{feature}.md`
- The backlog item describes the **change**; the spec describes the **capability**
- After delivery, the spec is updated; the backlog item is archived

## Rabbit Holes

- Don't create a new schema from scratch — extend or thin-fork the shaped-work-contract schema
- Don't refactor the full workflow — backlog items still drive the 7 D's; specs are the persistent layer underneath
- Don't auto-generate final specs — bootstrapping produces drafts; humans finalize via `/define`
- Don't break execute.sh — it currently reads `--spec` which points to a file path; just change what file it points to

## Why This Matters

- Specs outlive the backlog items that produce them
- `/context:load` can answer "what does this system do?" by reading `specs/`
- New team members or sessions have a persistent map of the system's capabilities
- Bootstrapping has a natural home: `specs/` is where specs live, period

---

# Design: GT-4 Persistent Specs

> Designed: 2026-01-27 | Architect: Claude Opus 4.5

## Design Summary

Introduce `specs/` as a persistent, first-class directory for feature specifications.
Redirect spec bootstrapping and scanning from `docs/analysis/` and `docs/backlog/`
to `specs/`. Minimal changes — 5 files modified, no new code, no schema changes.

## Key Decision: Specs reuse the shaped-work-contract schema

Specs use the same frontmatter structure as shaped work contracts but with
`type: spec` instead of `type: shaped-work`. This means:

- Same `acceptance_criteria` array structure
- Same `id`, `title`, `appetite` fields
- `status` enum differs: `draft` (bootstrapped), `active` (human-reviewed), `deprecated`
- No lifecycle transitions like `designed -> implemented -> reviewed -> done`
- Specs are never archived — they stay in `specs/` and get updated in place

## Components

### Component 1: install.sh — Add `specs/` directory

**File:** `install.sh`
**Change:** Add `specs/` to project install alongside `docs/backlog` and `docs/analysis`

In `cmd_project()`, after `mkdir -p "$project_path/docs/analysis"`:
```bash
mkdir -p "$project_path/specs"
```

No `install_specs()` function needed — the directory is empty at install time.
Specs are created by `/context:refresh` (bootstrap) or `/define` (manual).

**AC mapping:** AC-1

### Component 2: context-refresh.md — Write to `specs/`

**File:** `commands/context-refresh.md` (and `.claude/commands/context-refresh.md`)
**Change:** Redirect bootstrap output from `docs/analysis/` to `specs/`

Specific changes:
- Line 18: `docs/analysis/YYYYMMDD_spec_bootstrap_{project}.md` → `specs/{feature}.md` (one file per feature, not one monolith)
- Line 35: Same path change
- Line 91: Same path change in WRITE section
- Bootstrap output format changes:
  - Each feature gets its own spec file: `specs/{feature-slug}.md`
  - Frontmatter: `type: spec`, `status: draft`
  - ACs derived from test describe blocks
  - If `specs/{feature}.md` already exists, do NOT overwrite — report as "already specified"

**AC mapping:** AC-2

### Component 3: context-load.md — Scan `specs/`

**File:** `commands/context-load.md` (and `.claude/commands/context-load.md`)
**Change:** Scan `specs/` instead of `docs/backlog/` for spec coverage

Specific changes:
- Line 16: Change `docs/backlog/*.md` scan to `specs/*.md` scan
- Look for `type: spec` frontmatter (active specs), not `type: shaped-work`
- Coverage output changes:
  - "Specs: N active, M draft" (from `specs/`)
  - "Backlog: N items" (still scan `docs/backlog/` for work items, separately)
  - "Unspecified: N test suites have no matching spec"
- Add `specs/*.md` to the READ section

**AC mapping:** AC-3

### Component 4: spec-awareness SKILL.md — Scan `specs/`

**File:** `.claude/skills/spec-awareness/SKILL.md`
**Change:** Replace all `docs/backlog/` references with `specs/`

Specific changes:
- Line 28: Check `specs/` not backlog for `type: spec`
- Line 47: Scan `specs/*.md` for coverage
- Line 55: Check `specs/` for feature existence
- During /deliver: Check if backlog item has `spec_ref` pointing to a spec in `specs/`, warn if missing
- General: "Check if a spec exists in `specs/`" not `docs/backlog/`

**AC mapping:** AC-4

### Component 5: shaped-work-contract.schema.md — Document `spec_ref`

**File:** `schemas/shaped-work-contract.schema.md`
**Change:** Add `spec_ref` to optional fields

Add to the Optional Frontmatter Fields table:
```
| `spec_ref` | string | Path to persistent spec in `specs/` that this work modifies |
```

This is documentation only — the schema is a reference doc, not enforced code.

**AC mapping:** AC-5

### No changes needed for execute.sh (AC-6)

`execute.sh --spec` takes an arbitrary file path. It validates frontmatter
(`type: shaped-work`) regardless of location. Paths in `specs/` work
already. The only consideration: specs use `type: spec` not `type: shaped-work`.

**Option A (recommended):** Allow `validate_spec()` to accept both `type: spec` and `type: shaped-work`.
**Option B:** Specs always pass through a backlog item wrapper that has `type: shaped-work`.

Go with Option A — one line change in `validate_spec()`:
```bash
elif [[ "$type_val" != "shaped-work" && "$type_val" != "spec" ]]; then
```

And a corresponding test fixture + test case.

**AC mapping:** AC-6

## Files Changed Summary

| File | Action | Lines Changed |
|------|--------|---------------|
| `install.sh` | modify | ~1 line (mkdir) |
| `commands/context-refresh.md` | modify | ~15 lines (output paths + format) |
| `commands/context-load.md` | modify | ~10 lines (scan target + output) |
| `.claude/skills/spec-awareness/SKILL.md` | modify | ~10 lines (scan target) |
| `schemas/shaped-work-contract.schema.md` | modify | ~1 line (add spec_ref field) |
| `commands/execute.sh` | modify | ~1 line (accept type: spec) |
| `.claude/commands/context-refresh.md` | sync | mirror of commands/ |
| `.claude/commands/context-load.md` | sync | mirror of commands/ |
| `.claude/commands/execute.sh` | sync | mirror of commands/ |
| `tests/test_execute.sh` | modify | ~5 lines (add spec type test) |
| `tests/fixtures/valid_spec_type.md` | create | test fixture for type: spec |

## What Does NOT Change

- **Backlog workflow** — `docs/backlog/` still drives the 7 D's lifecycle
- **Archive workflow** — `/done` still archives backlog items to `docs/archive/`
- **Schema enforcement** — Schemas are documentation, not runtime validators
- **Genie GENIE.md files** — They reference `docs/backlog/` for workflow context, which is correct
- **Most commands** — They operate on backlog items, not specs directly
- **Discovery** — `/discover` still writes to `docs/analysis/` (research artifacts, not specs)

## Risks & Mitigations

| Risk | Mitigation |
|------|------------|
| Bootstrap creates many small spec files cluttering `specs/` | One spec per feature (group by describe block), not per test file |
| Existing projects have no `specs/` directory | `install.sh` creates it; `/context:refresh` creates it if missing |
| Confusion between spec and shaped-work-contract | Clear naming: specs live in `specs/`, work contracts live in `docs/backlog/` |
| `validate_spec()` accepting two types loosens validation | Both types share the same required fields; the type check is just a discriminator |

## Implementation Guidance

**Order:** AC-1 (install.sh) → AC-6 (execute.sh type check + test) → AC-2 (context-refresh) → AC-3 (context-load) → AC-4 (spec-awareness) → AC-5 (schema doc)

Start with the test for AC-6 (RED), then implement, then the non-code changes.

## Routing

- [x] **Architect** — GT-4 Designed (2026-01-27)
- [x] **Crafter** — GT-4 Implemented (2026-01-27)
- [x] **Critic** — GT-4 Reviewed: APPROVED (2026-01-27)
- [x] **Done** — Archived (2026-01-27)

---

# Implementation: GT-4 Persistent Specs

> Implemented: 2026-01-27 | Crafter: Claude Opus 4.5

## TDD Summary

- **RED:** 3 new failing tests (validate_spec type:spec, CLI dry-run with type:spec, spec id in output)
- **GREEN:** One-line change to `validate_spec()` — accept `type: spec` alongside `type: shaped-work`
- **Tests:** 62/62 passing (59 existing + 3 new)

## Changes Made

### AC-1: install.sh — specs/ directory
- Added `mkdir -p "$project_path/specs/_drafts"` to `cmd_project()` at `install.sh:358`
- Creates both `specs/` and `specs/_drafts/` in one command
- Verified: `install.sh project /tmp/test --force` creates both directories

### AC-2: context-refresh.md — Write to specs/_drafts/
- Redirected bootstrap output from `docs/analysis/YYYYMMDD_spec_bootstrap_{project}.md` to `specs/_drafts/{capability-slug}.md`
- Changed output format: one draft spec per capability (not one monolith)
- Added `type: spec`, `status: draft` frontmatter to bootstrap output template
- Added rule: never overwrite existing specs (check all of `specs/` recursively)
- Drafts stay in `_drafts/` until human organizes into domains via `/define`
- Added `specs/**/*.md` to READ section (recursive)

### AC-3: context-load.md — Scan specs/
- Changed spec scanning from `docs/backlog/*.md` to `specs/**/*.md` (recursive)
- Look for `type: spec` (not `type: shaped-work`)
- Updated output format: "Specs: N active, M draft, K deprecated across D domains" + "Drafts pending review: M" + "Backlog: N items"
- Added `specs/**/*.md` to READ section

### AC-4: spec-awareness SKILL.md — Domain > Capability hierarchy
- Rewrote skill with full spec organization conventions
- Defined hierarchy: `specs/{domain}/{capability}.md` for active specs, `specs/_drafts/{capability-slug}.md` for bootstrapped drafts
- Defined terminology: Domain (product-level bounded context), Capability (specific behavior), Spec (file), Draft (awaiting review)
- Naming convention: lowercase kebab-case, product-oriented (not code-oriented)
- Spec lifecycle: draft (bootstrap) → active (human-reviewed) → deprecated (removed)
- Key principle: domains are rooted in product architecture, not code architecture
- During /deliver: added `spec_ref` checking — warns if backlog item has no spec_ref pointing to `specs/{domain}/`
- During /context:load: scan `specs/**/*.md` recursively, count by status, list domains
- General: check `specs/{domain}/` and `specs/_drafts/` for specs

### AC-5: shaped-work-contract.schema.md — spec_ref field
- Added `spec_ref` (string) to Optional Frontmatter Fields table
- Description: "Path to persistent spec in `specs/` that this work modifies"

### AC-6: execute.sh — Accept type: spec
- Changed `validate_spec()` type check from `!= "shaped-work"` to `!= "shaped-work" && != "spec"`
- Updated error message to mention both accepted types
- Added test fixture `valid_spec_type.md` with `type: spec` frontmatter
- 3 new tests: validate_spec accepts spec type, CLI dry-run accepts spec type, output includes spec id

### Synced files
- `.claude/commands/execute.sh` — synced from `commands/execute.sh`
- `.claude/commands/context-refresh.md` — synced from `commands/context-refresh.md`
- `.claude/commands/context-load.md` — synced from `commands/context-load.md`

## Files Changed

| File | Action | AC |
|------|--------|----|
| `install.sh` | modified | AC-1 |
| `commands/context-refresh.md` | modified | AC-2 |
| `commands/context-load.md` | modified | AC-3 |
| `.claude/skills/spec-awareness/SKILL.md` | modified | AC-4 |
| `schemas/shaped-work-contract.schema.md` | modified | AC-5 |
| `commands/execute.sh` | modified | AC-6 |
| `.claude/commands/execute.sh` | synced | AC-6 |
| `.claude/commands/context-refresh.md` | synced | AC-2 |
| `.claude/commands/context-load.md` | synced | AC-3 |
| `tests/test_execute.sh` | modified | AC-6 |
| `tests/fixtures/valid_spec_type.md` | created | AC-6 |

---

# Review: GT-4 Persistent Specs

> Reviewed: 2026-01-27 | Critic: Claude Opus 4.5

## Verdict: APPROVED (after fixes applied)

All 6 acceptance criteria met. Two issues found and resolved in-review:

### Issues Found & Fixed

| Severity | Issue | Fix |
|----------|-------|-----|
| Major | All 6 AC statuses were `pending` in frontmatter despite `status: implemented` | Updated all to `status: met` |
| Major | Schema examples showed `docs/backlog/` for `spec_ref` instead of `specs/` | Updated `spec_ref` descriptions in design-document, execution-report, and review-document schemas to show both options |
| Minor | Genie templates showed only `docs/backlog/` for `spec_ref` | Updated all 3 templates to show `specs/domain/capability.md or docs/backlog/Pn-topic.md` |

### AC Verdicts

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | pass | `install.sh:358` creates `specs/_drafts/` (and parent `specs/`) via `mkdir -p` |
| AC-2 | pass | `context-refresh.md` writes to `specs/_drafts/{capability-slug}.md`, never overwrites existing |
| AC-3 | pass | `context-load.md` scans `specs/**/*.md` recursively, reports domains + drafts |
| AC-4 | pass | `spec-awareness SKILL.md` defines domain > capability hierarchy with naming conventions |
| AC-5 | pass | `shaped-work-contract.schema.md` has `spec_ref` optional field |
| AC-6 | pass | `validate_spec()` accepts `type: spec` alongside `type: shaped-work`, 62/62 tests pass |

### Additional Changes (review fixes)

| File | Change |
|------|--------|
| `schemas/design-document.schema.md` | `spec_ref` description shows both `specs/` and `docs/backlog/` |
| `schemas/execution-report.schema.md` | `spec_ref` description shows both options |
| `schemas/review-document.schema.md` | `spec_ref` description shows both options |
| `genies/architect/DESIGN_DOCUMENT_TEMPLATE.md` | `spec_ref` placeholder shows both options |
| `genies/crafter/IMPLEMENTATION_REPORT_TEMPLATE.md` | `spec_ref` placeholder shows both options |
| `genies/critic/REVIEW_DOCUMENT_TEMPLATE.md` | `spec_ref` placeholder shows both options |
