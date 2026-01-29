---
schema_name: execution-report
schema_version: "1.0"
type: schema
description: Defines the frontmatter contract for Execution Report documents
created: 2026-01-27
---

# Execution Report Schema v1.0

> All structured data lives in YAML frontmatter. The markdown body is free-form
> human narrative. Machines parse frontmatter only; they never need to parse the body.

## Required Frontmatter Fields

| Field | Type | Constraint | Description |
|-------|------|------------|-------------|
| `spec_version` | string | semver, e.g. `"1.0"` | Schema version for compatibility |
| `type` | string | `"execution-report"` | Document type discriminator |
| `id` | string | Must match parent spec | Unique identifier, e.g. `"GT-2"` |
| `title` | string | Must match parent spec | Human-readable title |
| `status` | string | enum: `complete`, `partial`, `failed`, `blocked` | Execution outcome |
| `created` | string | ISO 8601 datetime, e.g. `"2026-01-27T14:30:00Z"` | Execution start time |
| `spec_ref` | string | Relative path | Path to parent spec (`docs/specs/`) or shaped work contract (`docs/backlog/`) |
| `design_ref` | string | Relative path | Path to design document |
| `execution_mode` | string | enum: `interactive`, `headless` | How execution was invoked |
| `exit_code` | integer | `0`=success, `1`=partial, `2`=failed, `3`=blocked | Process exit code |
| `confidence` | string | enum: `high`, `medium`, `low` | Crafter's confidence assessment |
| `branch` | string | Git branch name | Branch where changes were committed |
| `commit_sha` | string | 7-40 hex characters | Git commit SHA |
| `files_changed` | array | list of file change objects (see below) | What files were created/modified/deleted |
| `test_results` | object | test summary object (see below) | Test execution results |
| `acceptance_criteria` | array | list of AC result objects (see below) | AC verdict per criterion |

## Optional Telemetry Fields

| Field | Type | Description |
|-------|------|-------------|
| `tokens_input` | integer | Input tokens consumed |
| `tokens_output` | integer | Output tokens produced |
| `model` | string | Model used, e.g. `"claude-opus-4-5-20251101"` |
| `duration_seconds` | integer | Wall clock execution time |
| `updated` | string (ISO datetime) | Completion time |
| `author` | string | Producing genie |
| `parent_run_id` | string | For chained executions |
| `tags` | array of strings | Categorization tags |

## File Change Object

Each item in `files_changed`:

| Field | Type | Constraint |
|-------|------|------------|
| `action` | string | enum: `added`, `modified`, `deleted` |
| `path` | string | File path relative to repo root |
| `purpose` | string | Why this file changed |

## Test Results Object

The `test_results` field:

| Field | Type | Constraint |
|-------|------|------------|
| `passed` | integer | Count of passing tests |
| `failed` | integer | Count of failing tests |
| `skipped` | integer | Count of skipped tests |
| `command` | string | Test command that was run |
| `tests` | array | Individual test objects (optional, see below) |

### Test Object

Each item in `test_results.tests`:

| Field | Type | Constraint |
|-------|------|------------|
| `name` | string | Test name |
| `status` | string | enum: `pass`, `fail`, `skip`, `error` |
| `duration_ms` | integer | Duration in milliseconds |
| `ac_id` | string | (optional) References AC `id` from parent shaped work. Links this test to the acceptance criterion it verifies. |

## AC Result Object

Each item in `acceptance_criteria`:

| Field | Type | Constraint |
|-------|------|------------|
| `id` | string | References AC `id` from parent shaped work |
| `status` | string | enum: `met`, `not_met`, `partial`, `skipped` |
| `evidence` | string | How this was verified, or why it wasn't met |

## Markdown Body

Free-form narrative. No enforced headings or sections. Humans write execution
summaries, implementation decisions, warnings, handoff notes to the Critic.
Machines ignore the body entirely.

## Complete Example

```yaml
---
spec_version: "1.0"
type: execution-report
id: GT-2
title: Stable Spec Schema
status: complete
created: 2026-01-27T14:30:00Z
spec_ref: docs/backlog/P0-spec-driven.md
design_ref: docs/backlog/P0-spec-driven.md
execution_mode: headless
exit_code: 0
confidence: high
branch: feat/gt-2-stable-spec-schema
commit_sha: abc123d
files_changed:
  - action: added
    path: schemas/shaped-work-contract.schema.md
    purpose: Schema definition for shaped work contracts
  - action: added
    path: schemas/design-document.schema.md
    purpose: Schema definition for design documents
  - action: added
    path: schemas/execution-report.schema.md
    purpose: Schema definition for execution reports
  - action: modified
    path: genies/shaper/GENIE.md
    purpose: Added structured frontmatter output instruction
  - action: modified
    path: genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md
    purpose: Restructured to frontmatter-first format
test_results:
  passed: 5
  failed: 0
  skipped: 0
  command: npm test
  tests:
    - name: test_frontmatter_parse
      status: pass
      duration_ms: 120
      ac_id: AC-1
    - name: test_required_fields
      status: pass
      duration_ms: 80
      ac_id: AC-1
acceptance_criteria:
  - id: AC-1
    status: met
    evidence: schemas/shaped-work-contract.schema.md created with field tables
  - id: AC-2
    status: met
    evidence: schemas/design-document.schema.md created with field tables
  - id: AC-3
    status: met
    evidence: genies/shaper/GENIE.md updated to produce structured frontmatter
  - id: AC-4
    status: not_met
    evidence: "Blocked: Crafter headless mode not yet implemented (GT-1)"
  - id: AC-5
    status: met
    evidence: spec_version field required in all three schemas
  - id: AC-6
    status: met
    evidence: Standard YAML parse errors + validation section in each schema
tokens_input: 45000
tokens_output: 12000
model: claude-opus-4-5-20251101
duration_seconds: 342
---

# Execution Report: GT-2 Stable Spec Schema

## Summary

Created schema documentation files for all three spec types and updated
genie templates and behaviors to produce structured frontmatter output.

## Implementation Decisions

- Chose `snake_case` for YAML keys (`spec_version`, `depends_on`) for
  compatibility with languages that use frontmatter keys as object properties.
- Kept markdown body completely free-form to avoid the need for section parsing.

## Warnings

AC-4 (Crafter input validation) could not be fully tested because
headless execution mode is not yet implemented. This is expected --
GT-1 depends on GT-2, and AC-4 will be validated during GT-1 work.
```

## Validation

To validate an execution report, parse the YAML frontmatter with any
standard library and check:

1. All required fields are present
2. `type` equals `"execution-report"`
3. `status` is a valid enum value
4. `exit_code` is an integer (0, 1, 2, or 3)
5. `confidence` is a valid enum value
6. `files_changed` is an array with valid action enums
7. `test_results` has `passed`, `failed`, `skipped`, and `command` fields
8. `acceptance_criteria` is a non-empty array
9. Each AC result has `id`, `status`, and `evidence` fields
