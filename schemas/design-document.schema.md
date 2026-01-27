---
schema_name: design-document
schema_version: "1.0"
type: schema
description: Defines the frontmatter contract for Design Document specs
created: 2026-01-27
---

# Design Document Schema v1.0

> All structured data lives in YAML frontmatter. The markdown body is free-form
> human narrative. Machines parse frontmatter only; they never need to parse the body.

## Required Frontmatter Fields

| Field | Type | Constraint | Description |
|-------|------|------------|-------------|
| `spec_version` | string | semver, e.g. `"1.0"` | Schema version for compatibility |
| `type` | string | `"design"` | Document type discriminator |
| `id` | string | Must match parent spec | Unique identifier, e.g. `"GT-2"` |
| `title` | string | Must match parent spec | Human-readable title |
| `status` | string | enum: `designed`, `superseded` | Design lifecycle status |
| `created` | string | ISO 8601 date | Creation date |
| `spec_ref` | string | Relative path to parent spec or shaped work | e.g. `"specs/execution/headless-mode.md"` or `"docs/backlog/P0-topic.md"` |
| `appetite` | string | enum: `small`, `medium`, `big` | Inherited from shaped work |
| `complexity` | string | enum: `simple`, `moderate`, `complex` | Architect's complexity assessment |
| `ac_mapping` | array | list of AC mapping objects (see below) | Traceability from AC to design |
| `components` | array | list of component objects (see below) | Files to create/modify/delete |

## Optional Frontmatter Fields

| Field | Type | Description |
|-------|------|-------------|
| `updated` | string (ISO date) | Last modified date |
| `author` | string | Producing genie or person |
| `adr_refs` | array of strings | Related Architecture Decision Records |
| `tags` | array of strings | Categorization tags |

## AC Mapping Object

Each item in `ac_mapping` traces an acceptance criterion to its design approach:

| Field | Type | Constraint |
|-------|------|------------|
| `ac_id` | string | References AC `id` from parent shaped work |
| `approach` | string | How this AC will be satisfied by the design |
| `components` | array of strings | File paths involved in satisfying this AC |

## Component Object

Each item in `components` describes a file-level change:

| Field | Type | Constraint |
|-------|------|------------|
| `name` | string | Human-readable component name |
| `action` | string | enum: `create`, `modify`, `delete` |
| `files` | array of strings | File paths relative to repo root |

## Markdown Body

Free-form narrative. No enforced headings or sections. Humans write design
overviews, architecture diagrams, interface definitions, implementation
guidance, risks, technical decisions. Machines ignore the body entirely.

## Complete Example

```yaml
---
spec_version: "1.0"
type: design
id: GT-2
title: Stable Spec Schema
status: designed
created: 2026-01-27
spec_ref: docs/backlog/P0-spec-driven.md
appetite: small
complexity: moderate
author: architect
ac_mapping:
  - ac_id: AC-1
    approach: Schema documentation file defines required/optional frontmatter fields
    components: [schemas/shaped-work-contract.schema.md]
  - ac_id: AC-2
    approach: Schema documentation file defines required/optional frontmatter fields
    components: [schemas/design-document.schema.md]
  - ac_id: AC-3
    approach: Shaper GENIE.md updated to produce structured frontmatter
    components: [genies/shaper/GENIE.md]
  - ac_id: AC-4
    approach: Crafter GENIE.md updated to validate frontmatter on intake
    components: [genies/crafter/GENIE.md]
  - ac_id: AC-5
    approach: spec_version field required in all schemas
    components: [schemas/shaped-work-contract.schema.md, schemas/design-document.schema.md, schemas/execution-report.schema.md]
  - ac_id: AC-6
    approach: Standard YAML parse errors surface missing/invalid fields naturally
    components: []
components:
  - name: Schema documentation files
    action: create
    files:
      - schemas/shaped-work-contract.schema.md
      - schemas/design-document.schema.md
      - schemas/execution-report.schema.md
  - name: Genie behavior updates
    action: modify
    files:
      - genies/shaper/GENIE.md
      - genies/architect/GENIE.md
      - genies/crafter/GENIE.md
      - genies/critic/GENIE.md
  - name: Template restructuring
    action: modify
    files:
      - genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md
      - genies/architect/DESIGN_DOCUMENT_TEMPLATE.md
      - genies/crafter/IMPLEMENTATION_REPORT_TEMPLATE.md
---

# Design: GT-2 Stable Spec Schema

## Overview

Introduces a frontmatter-first specification system. All structured data
lives in YAML frontmatter. Markdown body is pure narrative for humans.

Standard frontmatter-aware markdown libraries (gray-matter, python-frontmatter)
parse all machine-readable data without custom tooling.

## Architecture

The design document inherits `id` and `title` from its parent shaped work
contract (referenced via `spec_ref`). The `ac_mapping` array creates
traceability from each acceptance criterion to the design components that
satisfy it.

## Implementation Guidance

1. Create schema documentation files (reference docs, not validators)
2. Restructure templates to move structured data into frontmatter
3. Update genie behavior files to produce the new format
```

## Validation

To validate a design document, parse the YAML frontmatter with any
standard library and check:

1. All required fields are present
2. `type` equals `"design"`
3. `status` is a valid enum value
4. `complexity` is a valid enum value
5. `spec_ref` points to an existing file
6. `ac_mapping` is a non-empty array
7. Each AC mapping has `ac_id`, `approach`, and `components` fields
8. `components` is a non-empty array
9. Each component has `name`, `action`, and `files` fields
