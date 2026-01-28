---
adr_version: "1.0"
type: adr
id: ADR-000
title: "Use ADRs to record architecture decisions"
status: accepted
created: 2026-01-27
deciders: [architect]
tags: [process, documentation]
---

# ADR-000: Use ADRs to record architecture decisions

## Context

Technical decisions evaporate without a record. When developers ask "why did we
choose X over Y?" there is no authoritative answer. Design documents capture
what was designed but not the alternatives that were considered and rejected.

The genie-team workflow tracks WHAT the system does (specs) but not HOW it's
built or WHY those technical choices were made. Three artifacts form a triangle:

```
     SPEC (WHAT)
    /           \
   /             \
ADR (HOW+WHY) -- C4 (CONTEXT MAP)
```

Without ADRs, technical decisions evaporate. Without C4 diagrams, architectural
boundaries are invisible. Both artifacts serve humans AND the system.

## Decision

Use Architecture Decision Records (ADRs) following the Michael Nygard pattern.
ADRs are stored in `docs/decisions/` with sequential numbering. They capture
context, decision, consequences, and alternatives considered.

ADRs are created when: (a) multiple viable alternatives exist AND (b) the
choice is hard to reverse OR affects multiple domains.

The ADR lifecycle integrates with the genie-team workflow:
- `/define` creates `proposed` ADRs when shaping reveals architectural choices
- `/design` creates `accepted` ADRs and completes proposed ones
- `/deliver` reads ADRs for implementation context
- `/discern` verifies ADR compliance
- `/diagnose` checks ADR health and diagram staleness

## Consequences

### Positive
- Decisions are discoverable and searchable
- New team members understand why decisions were made
- `/diagnose` can detect violations of documented decisions
- `/discern` can verify ADR compliance during review

### Negative
- Overhead of writing ADRs for significant decisions
- Risk of ADR proliferation if threshold is not respected

### Neutral
- ADRs complement but do not replace design documents
- ADRs link to specs via `spec_refs` and `domain` fields but are independent artifacts

## Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| Document decisions in design docs | Already exists, no new files | Mixed with implementation details, hard to find later | Decisions get buried in larger documents |
| Wiki pages | Easy to edit, searchable | Not version-controlled, drift from code | Separate from the codebase |
| No formal records | Zero overhead | Decisions lost, repeated debates | Current pain point |
