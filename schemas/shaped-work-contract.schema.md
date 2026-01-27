---
schema_name: shaped-work-contract
schema_version: "1.0"
type: schema
description: Defines the frontmatter contract for Shaped Work Contract documents
created: 2026-01-27
---

# Shaped Work Contract Schema v1.0

> All structured data lives in YAML frontmatter. The markdown body is free-form
> human narrative. Machines parse frontmatter only; they never need to parse the body.

## Required Frontmatter Fields

| Field | Type | Constraint | Description |
|-------|------|------------|-------------|
| `spec_version` | string | semver, e.g. `"1.0"` | Schema version for compatibility |
| `type` | string | `"shaped-work"` | Document type discriminator |
| `id` | string | `/^[A-Z]+-\d+$/` | Unique identifier, e.g. `"GT-2"` |
| `title` | string | max 100 chars | Human-readable title |
| `status` | string | enum: `shaped`, `designed`, `implemented`, `reviewed`, `done`, `abandoned` | Lifecycle status |
| `created` | string | ISO 8601 date, e.g. `"2026-01-27"` | Creation date |
| `appetite` | string | enum: `small`, `medium`, `big` | Scope constraint (Shape Up) |
| `acceptance_criteria` | array | list of AC objects (see below) | Machine-trackable success criteria |

## Optional Frontmatter Fields

| Field | Type | Description |
|-------|------|-------------|
| `updated` | string (ISO date) | Last modified date |
| `depends_on` | array of strings | IDs of blocking items |
| `target_project` | string | Target project name |
| `tags` | array of strings | Categorization tags |
| `author` | string | Producing genie or person |
| `priority` | string (e.g. `"P0"`) | Priority level |

## Acceptance Criteria Object

Each item in `acceptance_criteria` has:

| Field | Type | Constraint |
|-------|------|------------|
| `id` | string | `/^AC-\d+$/`, e.g. `"AC-1"` |
| `description` | string | Human-readable criterion |
| `status` | string | enum: `pending`, `met`, `not_met`, `partial`, `skipped` |

## Status Lifecycle

```
shaped → designed → implemented → reviewed → done
                                           ↘ abandoned (any stage)
```

## Markdown Body

Free-form narrative. No enforced headings or sections. Humans write whatever
context is useful: problem statements, evidence, solution sketches, risks,
options, routing recommendations. Machines ignore the body entirely.

## Complete Example

```yaml
---
spec_version: "1.0"
type: shaped-work
id: GT-2
title: Stable Spec Schema
status: shaped
created: 2026-01-27
appetite: small
priority: P0
target_project: genie-team
author: shaper
depends_on: []
tags: [schema, infrastructure]
acceptance_criteria:
  - id: AC-1
    description: Shaped Work Contract has a defined schema with required/optional fields
    status: pending
  - id: AC-2
    description: Design Document has a defined schema with required/optional fields
    status: pending
  - id: AC-3
    description: Shaper output validates against schema
    status: pending
  - id: AC-4
    description: Crafter input validates against schema
    status: pending
  - id: AC-5
    description: Schema version field present in frontmatter
    status: pending
  - id: AC-6
    description: Invalid specs produce clear validation errors
    status: pending
---

# GT-2: Stable Spec Schema

## Problem

Shaped Work Contract and Design Document templates are markdown conventions.
They work for human-genie interaction but are fragile for machine-to-machine
handoff. Field names, section ordering, and required content are not enforced.

## Appetite & Boundaries

- **Appetite:** Small (3 days)
- **In scope:** Schema definition, template updates, genie behavior changes
- **No-gos:** Runtime schema migration, GUI schema editor

## Solution Sketch

All structured data moves into YAML frontmatter. Acceptance criteria become
a YAML array with id/description/status fields. Any frontmatter-aware
markdown library can parse the structured data without custom tooling.

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| YAML frontmatter is sufficient for structured data | feasibility | Parse with gray-matter |
| Genies can reliably produce valid YAML | feasibility | Test template output |

## Routing

- [x] **Architect** — Needs technical design
```

## Validation

To validate a shaped work contract, parse the YAML frontmatter with any
standard library and check:

1. All required fields are present
2. `type` equals `"shaped-work"`
3. `status` is a valid enum value
4. `appetite` is a valid enum value
5. `acceptance_criteria` is a non-empty array
6. Each AC object has `id`, `description`, and `status` fields
