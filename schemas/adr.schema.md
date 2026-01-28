---
schema_name: adr
schema_version: "1.0"
type: schema
description: Defines the frontmatter contract for Architecture Decision Record (ADR) documents
created: 2026-01-27
---

# ADR Schema v1.0

> All structured data lives in YAML frontmatter. The markdown body is free-form
> human narrative. Machines parse frontmatter only; they never need to parse the body.

## Required Frontmatter Fields

| Field | Type | Constraint | Description |
|-------|------|------------|-------------|
| `adr_version` | string | semver, e.g. `"1.0"` | Schema version for compatibility |
| `type` | string | `"adr"` | Document type discriminator |
| `id` | string | `/^ADR-\d{3}$/`, e.g. `"ADR-001"` | Sequential identifier with zero-padded 3-digit number |
| `title` | string | max 100 chars | Describes the decision (verb phrase preferred, e.g. "Use JWT refresh over session tokens") |
| `status` | string | enum: `proposed`, `accepted`, `deprecated`, `superseded` | Decision lifecycle status |
| `created` | string | ISO 8601 date, e.g. `"2026-01-27"` | Date the ADR was created |
| `deciders` | array of strings | At least one entry | Who made or proposed this decision (genie names or people) |

## Optional Frontmatter Fields

| Field | Type | Description |
|-------|------|-------------|
| `updated` | string (ISO date) | Date of last status change |
| `domain` | string | Product domain this decision relates to (matches `specs/{domain}/`) |
| `spec_refs` | array of strings | Paths to specs this decision affects |
| `backlog_ref` | string | Path to the backlog item that triggered this ADR |
| `superseded_by` | string | ADR id (e.g. `"ADR-005"`) if this ADR has been superseded |
| `supersedes` | string | ADR id this ADR replaces |
| `tags` | array of strings | Categorization tags |

## Status Lifecycle

```
proposed → accepted → [lives indefinitely]
                    → superseded (superseded_by points to replacement)
                    → deprecated (no longer relevant)
```

- **proposed** — Created by `/define` when a behavioral delta involves an architectural choice. Needs `/design` to evaluate and accept.
- **accepted** — Created or promoted by `/design` after evaluating alternatives. The authoritative record.
- **deprecated** — The decision is no longer relevant (e.g., the feature was removed). Set by `/design`.
- **superseded** — A newer ADR replaces this one. `superseded_by` points to the replacement. Set by `/design`.

## ADR Creation Threshold

Create an ADR ONLY when BOTH conditions are true:

1. **Multiple viable alternatives exist** — There is a genuine choice between approaches
2. **Hard to reverse OR affects multiple domains** — The decision has lasting consequences

Do NOT create ADRs for: trivial decisions, single-option choices, easily reversible choices, or implementation details within a single component.

## Numbering Convention

ADRs use sequential 3-digit zero-padded numbers: `ADR-000`, `ADR-001`, `ADR-002`, etc.

To determine the next number: scan `docs/decisions/ADR-*.md` and increment the highest number found. If no ADRs exist, start with `ADR-001` (after the bootstrapping `ADR-000`).

## Directory Structure

```
docs/decisions/
  ADR-000-use-adrs-for-architecture-decisions.md   # bootstrapping record
  ADR-001-{slug}.md
  ADR-002-{slug}.md
```

Flat directory. No subdirectories. The `domain` field in frontmatter provides domain association.

## Markdown Body

The body follows the Michael Nygard ADR pattern:

```markdown
# ADR-{NNN}: {Title}

## Context

What is the issue that motivates this decision? What forces are at play?

## Decision

What is the technical approach chosen? Be specific about the implementation direction.

## Consequences

What becomes easier or harder as a result of this decision?

### Positive
- {positive consequence}

### Negative
- {negative consequence}

### Neutral
- {neutral consequence}

## Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| {Option A} | {pros} | {cons} | {reason rejected} |
| {Option B} | {pros} | {cons} | {reason rejected} |
```

## ADR-000 Bootstrapping Template

Every project using ADRs starts with ADR-000:

```yaml
---
adr_version: "1.0"
type: adr
id: ADR-000
title: "Use ADRs to record architecture decisions"
status: accepted
created: {YYYY-MM-DD}
deciders: [architect]
tags: [process, documentation]
---

# ADR-000: Use ADRs to record architecture decisions

## Context

Technical decisions evaporate without a record. When developers ask "why did we
choose X over Y?" there is no authoritative answer. Design documents capture
what was designed but not the alternatives that were considered and rejected.

## Decision

Use Architecture Decision Records (ADRs) following the Michael Nygard pattern.
ADRs are stored in `docs/decisions/` with sequential numbering. They capture
context, decision, consequences, and alternatives considered.

ADRs are created when: (a) multiple viable alternatives exist AND (b) the
choice is hard to reverse OR affects multiple domains.

## Consequences

### Positive
- Decisions are discoverable and searchable
- New team members understand why decisions were made
- /diagnose can detect violations of documented decisions

### Negative
- Overhead of writing ADRs for significant decisions
- Risk of ADR proliferation if threshold is not respected

### Neutral
- ADRs complement but do not replace design documents

## Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| Document decisions in design docs | Already exists, no new files | Mixed with implementation details, hard to find later | Decisions get buried in larger documents |
| Wiki pages | Easy to edit, searchable | Not version-controlled, drift from code | Separate from the codebase |
| No formal records | Zero overhead | Decisions lost, repeated debates | Current pain point |
```

## Complete Example

```yaml
---
adr_version: "1.0"
type: adr
id: ADR-001
title: "Use JWT refresh tokens over session-based authentication"
status: accepted
created: 2026-01-27
updated: 2026-01-27
deciders: [architect]
domain: identity
spec_refs:
  - specs/identity/token-authentication.md
backlog_ref: docs/backlog/P2-auth-improvements.md
tags: [auth, security, tokens]
---

# ADR-001: Use JWT refresh tokens over session-based authentication

## Context

Users experience frequent session timeouts requiring re-authentication. The current
15-minute token expiry with no renewal mechanism causes 40% of support tickets.

## Decision

Use short-lived JWT access tokens (15 min) paired with long-lived refresh tokens
(7-day absolute expiry, sliding window). Refresh tokens are rotated on each use.

## Consequences

### Positive
- Users stay authenticated for up to 7 days without re-login
- Refresh token rotation limits damage from token theft

### Negative
- More complex token lifecycle management
- Need server-side refresh token storage

### Neutral
- Existing JWT validation middleware unchanged for access tokens

## Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| Extend access token to 24h | Simple | Large abuse window | Security risk |
| Server-side sessions | Simple model | Not stateless | Contradicts JWT architecture |
| OAuth2 external IdP | Standards-compliant | Complex setup | Over-engineered for scale |
```

## Validation

To validate an ADR, parse the YAML frontmatter with any standard library and check:

1. All required fields are present
2. `type` equals `"adr"`
3. `id` matches `/^ADR-\d{3}$/`
4. `status` is a valid enum value
5. `deciders` is a non-empty array
6. If `status` is `superseded`, `superseded_by` must be present
7. If `superseded_by` is present, it must match `/^ADR-\d{3}$/`
