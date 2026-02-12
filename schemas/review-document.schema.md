---
schema_name: review-document
schema_version: "1.0"
type: schema
description: Defines the frontmatter contract for Review Document outputs from the Critic genie
created: 2026-01-27
---

# Review Document Schema v1.0

> All structured data lives in YAML frontmatter. The markdown body is free-form
> human narrative. Machines parse frontmatter only; they never need to parse the body.

## Required Frontmatter Fields

| Field | Type | Constraint | Description |
|-------|------|------------|-------------|
| `spec_version` | string | semver, e.g. `"1.0"` | Schema version for compatibility |
| `type` | string | `"review"` | Document type discriminator |
| `id` | string | Must match parent spec | Unique identifier, e.g. `"GT-2"` |
| `title` | string | Must match parent spec | Human-readable title |
| `verdict` | string | enum: `APPROVED`, `CHANGES_REQUESTED`, `BLOCKED` | GO/NO-GO decision |
| `created` | string | ISO 8601 date, e.g. `"2026-01-27"` | Review date |
| `spec_ref` | string | Relative path | Path to parent spec (`docs/specs/`) or shaped work contract (`docs/backlog/`) |
| `execution_ref` | string | Relative path or inline reference | Path to execution report being reviewed |
| `issues` | array | list of issue objects (see below) | Issues found during review |
| `acceptance_criteria` | array | list of AC verdict objects (see below) | Per-criterion pass/fail verdicts |

## Optional Frontmatter Fields

| Field | Type | Description |
|-------|------|-------------|
| `confidence` | string (enum: `high`, `medium`, `low`) | Reviewer's confidence in verdict |
| `author` | string | Producing genie or person |
| `tags` | array of strings | Categorization tags |

## Issue Object

Each item in `issues`:

| Field | Type | Constraint |
|-------|------|------------|
| `severity` | string | enum: `critical`, `major`, `minor` |
| `location` | string | File path and line reference, e.g. `"src/auth.ts:42"` |
| `description` | string | What the issue is |
| `fix` | string | Suggested resolution |

## AC Verdict Object

Each item in `acceptance_criteria`:

| Field | Type | Constraint |
|-------|------|------------|
| `id` | string | References AC `id` from parent shaped work |
| `status` | string | enum: `pass`, `fail` |
| `notes` | string | Why it passed or failed |

## Verdict Definitions

| Verdict | Meaning | Routing |
|---------|---------|---------|
| `APPROVED` | All critical issues resolved, ACs met | `/done` to archive |
| `CHANGES_REQUESTED` | Non-blocking issues need fixes | Back to Crafter |
| `BLOCKED` | Critical issue prevents merge | Escalate to Architect/Navigator |

## Markdown Body

Free-form narrative. No enforced headings or sections. Humans write review
summaries, code quality notes, security assessments, risk analysis, and
routing recommendations. Machines ignore the body entirely.

## Complete Example

```yaml
---
spec_version: "1.0"
type: review
id: GT-2
title: Stable Spec Schema
verdict: APPROVED
created: 2026-01-27
spec_ref: docs/backlog/P0-spec-driven.md
execution_ref: docs/backlog/P0-spec-driven.md
confidence: high
author: critic
issues:
  - severity: major
    location: "schemas/execution-report.schema.md:27"
    description: "exit_code enum missing value 3 (blocked)"
    fix: "Add 3=blocked to exit_code constraint"
  - severity: minor
    location: "genies/critic/GENIE.md:89"
    description: "Output template missing spec_version field"
    fix: "Add spec_version to review frontmatter"
acceptance_criteria:
  - id: AC-1
    status: pass
    notes: Schema files created with field tables
  - id: AC-2
    status: pass
    notes: Design document schema complete
  - id: AC-3
    status: pass
    notes: Genies updated to produce structured frontmatter
  - id: AC-4
    status: pass
    notes: Templates restructured to frontmatter-first
  - id: AC-5
    status: pass
    notes: spec_version required in all schemas
  - id: AC-6
    status: pass
    notes: Validation checklists in each schema
---

# Review: GT-2 Stable Spec Schema

## Summary

Implementation covers all six acceptance criteria. Three schema documentation
files created, four genie GENIE.md files updated, three templates restructured
to frontmatter-first format.

## Code Quality

### Strengths
- Consistent snake_case naming across all schemas
- Clear field tables with type constraints
- Complete examples in every schema

### Issues Found

| Issue | Severity | Location | Fix |
|-------|----------|----------|-----|
| exit_code missing value 3 | Major | schemas/execution-report.schema.md | Add 3=blocked |
| Critic template no spec_version | Minor | genies/critic/GENIE.md | Add spec_version field |

## Verdict

APPROVED with required fixes applied.
```

## Validation

To validate a review document, parse the YAML frontmatter with any
standard library and check:

1. All required fields are present
2. `type` equals `"review"`
3. `verdict` is a valid enum value
4. `issues` is an array with valid severity enums
5. `acceptance_criteria` is a non-empty array
6. Each AC verdict has `id`, `status`, and `notes` fields
