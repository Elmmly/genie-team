---
adr_version: "1.0"
type: adr
id: ADR-002
title: "Integrate Designer genie via /brand commands + brand-awareness skill"
status: proposed
created: 2026-02-05
deciders: [architect]
domain: genies
spec_refs:
  - docs/specs/genies/designer.md
backlog_ref: docs/backlog/P1-designer-genie.md
tags: [designer, brand, integration, skill, commands]
---

# ADR-002: Integrate Designer genie via /brand commands + brand-awareness skill

## Context

The Designer genie needs to integrate with the existing genie team workflow. The key question is how: as standalone commands, as a cross-cutting skill, or both.

The existing integration patterns provide precedent:
- **Architect**: `/design` command + `architecture-awareness` skill + `architect` agent
- **Spec system**: No command for specs per-se, but `spec-awareness` skill activates across all commands

The original shaping proposed `/design:brand`, `/design:tokens`, `/design:image`, `/design:review` as sub-commands of `/design`. This creates a namespace collision — `/design` is the Architect's primary command, and adding Designer sub-commands blurs which genie handles which sub-command.

Additionally, brand consistency is a cross-cutting concern: it affects how the Architect designs (brand constraints), how the Crafter implements (design tokens), and how the Critic reviews (brand compliance). A single command can't serve all these touchpoints.

## Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| **A: `/design:*` sub-commands only** | Minimal new commands | Namespace collision with Architect; no cross-cutting brand context in /deliver or /discern | Confusing which genie owns `/design` |
| **B: `brand-awareness` skill only** | Fully passive, no new commands | No way to explicitly create brand specs or generate images | Missing direct user workflows |
| **C: `/brand` commands + `brand-awareness` skill** | Clear ownership, cross-cutting context, follows Architect pattern | Slightly more surface area (3 commands + 1 skill) | **Recommended** |
| **D: Separate `/brand` and `/visual` namespaces** | Fine-grained separation | Over-engineering; one namespace is sufficient | Unnecessary complexity |

## Decision

To be determined by /design.

## Consequences

To be assessed after decision.
