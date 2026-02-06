---
spec_version: "1.0"
type: capability-spec
id: designer-genie
title: "Designer Genie"
status: active
domain: genies
created: 2026-02-04
updated: 2026-02-05
author: shaper
tags: [genie, designer, brand, visual-design, mcp, gemini]
acceptance_criteria:
  - id: AC-1
    description: "Designer genie directory exists at genies/designer/ with GENIE.md, DESIGNER_SPEC.md, DESIGNER_SYSTEM_PROMPT.md"
    status: met
  - id: AC-2
    description: "Designer outputs Brand Guide at docs/brand/{name}.md with YAML frontmatter per schemas/brand-spec.schema.md"
    status: met
  - id: AC-3
    description: "Designer outputs Design Tokens at docs/brand/tokens.json in W3C Design Tokens format"
    status: met
  - id: AC-4
    description: "/brand command runs interactive design workshop (identity → colors → typography → imagery → target examples → consolidation)"
    status: met
  - id: AC-5
    description: "/brand:tokens command generates Design Tokens JSON from existing brand guide"
    status: met
  - id: AC-6
    description: "/brand:image generates brand-consistent image via cost-tiered Gemini routing, logs to assets/manifest.md"
    status: met
  - id: AC-6a
    description: "/brand:image with no brand guide redirects user to /brand interview before proceeding"
    status: met
  - id: AC-7
    description: "/brand:image falls back to prompt-only output when no MCP or API key is configured"
    status: met
  - id: AC-8
    description: "Designer is opt-in in workflow; projects without brand guide skip it entirely"
    status: met
  - id: AC-9
    description: "brand-awareness skill activates during /design, /deliver, /discern to inject brand context via brand_ref"
    status: met
  - id: AC-10
    description: "designer agent available via Task tool for autonomous brand analysis"
    status: met
  - id: AC-11
    description: "Brand guide is a persistent artifact (never archived) with lifecycle: draft → active → deprecated"
    status: met
  - id: AC-12
    description: "Backlog items support brand_ref field linking to brand guide, parallel to spec_ref and adr_refs"
    status: met
---

# Designer Genie Capability Specification

## Overview

The Designer genie is a specialized agent for brand strategy, visual design systems, and AI-assisted asset generation. It operates between Shaper and Architect in the workflow, transforming brand requirements into machine-readable specifications that guide downstream work.

The Designer manages the **third pillar** of persistent project knowledge:

```
     SPEC (WHAT)          BRAND (HOW IT LOOKS)
    /           \        /
   /             \      /
ADR (HOW+WHY) -- C4 (CONTEXT MAP)
```

## Workflow Position

```
Scout → Shaper → Designer (opt-in) → Architect → Crafter → Critic → Tidier
```

Designer is opt-in. Projects without brand/design requirements skip directly to Architect.

## Persona

Expert visual designer combining:
- **Brand Strategy** — Identity, voice, positioning, values
- **Design Systems** — Tokens, components, patterns, consistency
- **Visual Language** — Color theory, typography, imagery, composition
- **AI-Native Workflows** — Prompt engineering for image generation

## Brand Guide: Persistent Artifact

The Designer's primary persistent artifact is the **Brand Guide** — a living document that captures and evolves brand knowledge.

### Artifact Parallel

| Concern | Genie | Artifact | Location | Bootstrap | Lifecycle |
|---------|-------|----------|----------|-----------|-----------|
| WHAT | Shaper | Specs | `docs/specs/{domain}/` | `/spec:init` | active → deprecated |
| HOW/WHY | Architect | ADRs + C4 | `docs/decisions/` + `docs/architecture/` | `/arch:init` | proposed → accepted → superseded |
| HOW IT LOOKS | Designer | Brand Guide + Tokens | `docs/brand/` | `/brand` | draft → active → deprecated |

### Directory Structure

```
docs/brand/
  {brand-name}.md              # Brand Guide (YAML frontmatter + design guide narrative)
  tokens.json                  # W3C Design Tokens (derived, machine-readable)
  assets/                      # Generated assets
    manifest.md                # Asset catalog with provenance
    *.png / *.jpg              # Generated files
```

### Brand Guide Format

The Brand Guide uses the same dual-format as specs:

- **YAML frontmatter** = machine-readable (colors, typography, imagery rules) per `schemas/brand-spec.schema.md`
- **Markdown body** = human-readable product design guide:
  - Design principles and philosophy
  - Logo usage guidelines
  - Color application rules
  - Typography hierarchy
  - Imagery guidelines (style, mood, dos/don'ts)
  - Component guidance (buttons, cards, forms)
  - Content voice and tone

### Persistence Rules

Same as specs and ADRs:
- **Never archived** — even when backlog items are `/done`
- **Accumulates knowledge** — new sections, updated tokens, asset history
- **Source of truth** — for how the product looks; backlog items are transient changes
- **One per brand** — multi-brand projects have one guide per brand in `docs/brand/`

### Lifecycle

```
/brand (create) → draft → /brand --activate → active → deprecated
                              ↑
                    /brand --evolve (update)
```

### Cross-Reference: brand_ref

Backlog items link to brand guides via `brand_ref`, parallel to `spec_ref` and `adr_refs`:

```yaml
spec_ref: docs/specs/marketing/landing-page.md
adr_refs: [docs/decisions/ADR-005-ssr-strategy.md]
brand_ref: docs/brand/acme.md
```

### Asset Catalog

Each `/brand:image` generation appends to `docs/brand/assets/manifest.md`:

```markdown
## hero-landing-001.png
- **Generated:** 2026-02-05
- **Model:** gemini-3-pro-image-preview (premium)
- **Brand guide:** docs/brand/acme.md
- **Prompt:** "Professional hero image for landing page..."
- **Augmented:** colors, mood, style from brand guide
```

## Brand Interview: Interactive Design Workshop

The `/brand` command runs a facilitated design workshop — not a form to fill out, but a collaborative session where the Designer generates visual options and the user reacts.

### Workshop Phases

| Phase | Activity | Output | Image Gen |
|-------|----------|--------|-----------|
| 1. Identity | Conversational discovery: name, mission, audience, personality | Brand identity section | None |
| 2. Colors | Generate 2-3 palette swatch options, user picks/remixes | Color palette | Flash (exploration) |
| 3. Typography | Suggest font pairings, show UI mockup with chosen colors | Typography section | Flash (mockup) |
| 4. Imagery | Same prompt in 3 styles (photo/illustration/abstract), user picks | Imagery guidelines | Flash (comparison) |
| 5. Target Examples | Generate reference images with finalized brand; user can `--pro` any | Asset catalog entries | Flash (default), Pro on `--pro` |
| 6. Consolidation | Write brand guide, generate tokens, save assets | `docs/brand/{name}.md` + `tokens.json` | None |

### Design Principles

- **Show, don't just ask** — generate visual options at each phase
- **Iterate, don't finalize** — each phase allows remixing and refinement
- **Use Flash for exploration, Pro for target examples** — cost-tiered routing in action
- **Capture decisions** — every choice becomes part of the brand guide narrative (why this palette, why photography)
- **Target examples are the north star** — the visual standard all future generations aim to match

### Guard Rail

If `/brand:image` is called without an existing brand guide:

```
> No brand guide found at docs/brand/.
> Would you like to:
>   1. Start the brand interview (/brand)
>   2. Generate without brand context (one-off)
```

### Evolution Mode

`/brand docs/brand/{name}.md --evolve "adding dark mode"` re-enters specific workshop phases for the change being made (e.g., color exploration for a dark palette variant).

## Integration Model

The Designer integrates via three mechanisms:

### 1. Commands (user-invoked)

| Command | Purpose |
|---------|---------|
| `/brand [input]` | Create brand guide via interview or evolve existing guide |
| `/brand:image [prompt]` | Generate brand-consistent image (cost-tiered) |
| `/brand:tokens [brand-guide]` | Generate W3C Design Tokens from brand guide |

### 2. Skill (auto-activated: brand-awareness)

Cross-cutting behavior that enriches other workflow phases when a brand guide exists:

| During | Behavior | Parallel |
|--------|----------|----------|
| `/design` | Inject brand constraints as Architect context | `architecture-awareness` injects ADRs |
| `/deliver` | Surface tokens for Crafter (theming, colors) | `spec-awareness` surfaces ACs for TDD |
| `/discern` | Add brand compliance to Critic review | `architecture-awareness` adds ADR compliance |
| `/context:load` | Report brand guide status | `spec-awareness` reports spec coverage |

Loading pattern (same as spec-awareness and architecture-awareness):
1. Check backlog frontmatter for `brand_ref`
2. If present: load the brand guide, inject context
3. If missing: scan `docs/brand/*.md` for any brand guide
4. If none found: silently continue (no overhead)
5. **Never block** — brand is valuable but optional

### 3. Agent (Task tool: designer)

Autonomous brand analysis available via `Task(subagent_type='designer', ...)`.

## Image Generation: Cost-Tiered Routing

| Tier | Model | Trigger |
|------|-------|---------|
| Default | Gemini 2.5 Flash (`gemini-2.5-flash-image`) | All requests (drafts, target examples, exploration) |
| Premium | Gemini 3 Pro (`gemini-3-pro-image-preview`) | Explicit `--pro` flag only |

Pro is always opt-in. Flash handles everything by default. User upgrades specific images when they want production quality: `/brand:image "hero for landing page" --pro`

## Graceful Degradation

| Environment | Behavior |
|-------------|----------|
| Full (API key + MCP) | Generate images via cost-tiered Gemini |
| Basic (MCP, no key) | Warn, output optimized prompt only |
| Prompt-only (nothing) | Craft brand-aware prompt for free tools (Gemini web, ChatGPT, Ideogram) |

## Outputs

| Output | Format | Location | Consumer |
|--------|--------|----------|----------|
| Brand Guide | YAML + Markdown | `docs/brand/{name}.md` | All genies via brand-awareness |
| Design Tokens | JSON (W3C) | `docs/brand/tokens.json` | Crafter, external tools |
| Generated Image | PNG/JPG + manifest | `docs/brand/assets/` | User |
| Optimized Prompt | Text (fallback) | stdout / file | User → free tools |

## Integration Points

### Receives From
- **Shaper**: Brand requirements, visual constraints in shaped work
- **User**: Raw brand guidelines, examples, descriptions

### Provides To
- **Architect**: Design context (tokens, constraints) via `brand-awareness` skill
- **Crafter**: Design tokens for implementation theming via `brand-awareness` skill
- **Critic**: Brand guide for compliance checking via `brand-awareness` skill

## Constraints

- Designer does NOT write code
- Designer does NOT make architectural decisions
- Designer does NOT generate images without MCP (outputs prompt instead)
- Designer does NOT modify existing genie behavior
- Brand-awareness skill is passive — adds no overhead when no brand guide exists
- Brand guides are **never archived** — they persist as project knowledge

## Design Constraints
<!-- Updated by /design on 2026-02-05 from designer-genie -->
- Designer genie has read-only tools (Read, Glob, Grep) when running as subagent; file writing is done by orchestrator
- Prompt augmentation must include "No text overlay" default to suppress Gemini brand name hallucination (observed in spike T3/T6)
- MCP detection uses tool listing (check for `mcp__imagegen__image_generate_gemini`), not environment variable checking
- brand-awareness skill uses silent-skip (not warn) when no brand guide exists — distinguishes from spec-awareness which warns
- Cost-tiered routing uses explicit `--pro` flag only — no heuristic-based model selection
- Token regeneration is explicit via `/brand:tokens` only — not auto-triggered on brand guide changes
- Multiple brand guides resolved by asking user to specify `--brand [path]` — no auto-selection heuristic
- Integration mechanism: ADR-002 (commands + skill + agent, `/brand` namespace)

## Implementation Evidence
<!-- Updated by /deliver on 2026-02-05 from designer-genie -->

### Implementation Files
- `genies/designer/GENIE.md`: Designer genie identity, charter, core behaviors
- `genies/designer/DESIGNER_SPEC.md`: Detailed specification with workshop process
- `genies/designer/DESIGNER_SYSTEM_PROMPT.md`: System prompt with judgment rules
- `.claude/commands/brand.md`: 6-phase interactive brand workshop command
- `.claude/commands/brand-image.md`: Cost-tiered image generation command
- `.claude/commands/brand-tokens.md`: W3C Design Token extraction command
- `.claude/skills/brand-awareness/SKILL.md`: Cross-cutting brand context injection skill
- `agents/designer.md`: Autonomous brand analysis subagent
- `schemas/shaped-work-contract.schema.md`: Added brand_ref optional field
