---
adr_version: "1.0"
type: adr
id: ADR-002
title: "Integrate Designer genie via /brand commands + brand-awareness skill"
status: accepted
created: 2026-02-05
deciders: [architect]
domain: genies
spec_refs:
  - docs/specs/genies/designer.md
backlog_ref: docs/archive/designer/2026-02-05_designer-genie/P1-designer-genie.md
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

**Alternative C: `/brand` commands + `brand-awareness` skill + `designer` agent.**

The Designer genie integrates via three mechanisms, mirroring the Architect's triple-mechanism pattern:

1. **Commands** (`/brand`, `/brand:image`, `/brand:tokens`) — Explicit user-invoked workflows for brand creation, image generation, and token extraction. Own the `/brand` namespace with no collision with Architect's `/design`.

2. **Skill** (`brand-awareness`) — Cross-cutting behavior that injects brand context into `/design` (Architect), `/deliver` (Crafter), and `/discern` (Critic). Follows the identical loading pattern as `spec-awareness` and `architecture-awareness`: check `brand_ref` → scan `docs/brand/` → silently continue if missing.

3. **Agent** (`designer`) — Autonomous subagent for brand analysis, prompt crafting, and consistency evaluation via `Task(subagent_type='designer')`.

The `/design:review` sub-command from the original shaping is eliminated — brand compliance checking is handled by the `brand-awareness` skill during `/discern`, exactly as ADR compliance is handled by `architecture-awareness`.

## Consequences

### Positive

- **Clear ownership** — `/brand` namespace unambiguously belongs to Designer; `/design` remains Architect's domain
- **Cross-cutting reach** — `brand-awareness` skill enriches Architect, Crafter, and Critic without those genies needing brand-specific code
- **Pattern consistency** — Follows the exact integration pattern established by Architect (command + skill + agent), reducing cognitive load for contributors
- **Opt-in by default** — `brand-awareness` skill silently skips when no brand guide exists, adding zero overhead to projects without brand requirements
- **Parallel to established artifacts** — Brand guide joins Specs and ADRs as a persistent, first-class project artifact with its own loading pattern

### Negative

- **Surface area** — Adds 3 new commands, 1 skill, and 1 agent (9 new files total). This is the same surface area as adding any new genie.
- **Skill proliferation** — Now 3 awareness skills (spec, architecture, brand). If more genies follow this pattern, skill loading could add context overhead. Mitigated by the silent-skip design — each skill adds zero cost when its artifact doesn't exist.

### Neutral

- **No existing behavior changes** — All new files; no modifications to existing genie behavior or command signatures
- **Install.sh requires no new functions** — Existing `install_genies()` and `install_skills()` handle new directories automatically
