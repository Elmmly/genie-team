---
spec_version: "1.0"
type: shaped-work
id: designer-genie
title: "Designer Genie for Brand-Consistent Asset Generation"
status: done
created: 2026-02-04
reshaped: 2026-02-05
appetite: medium
priority: P1
target_project: genie-team
author: shaper
depends_on: []
tags: [designer, genie, brand, design-tokens, mcp, image-generation, gemini]
spec_ref: docs/specs/genies/designer.md
adr_refs:
  - docs/decisions/ADR-002-designer-integration-commands-plus-skill.md
spike_ref: docs/analysis/20260205_spike_image_mcp_results.md
acceptance_criteria:
  - id: AC-1
    description: "Designer genie directory exists with GENIE.md, DESIGNER_SPEC.md, DESIGNER_SYSTEM_PROMPT.md"
    status: met
  - id: AC-2
    description: "Brand Spec schema defined in schemas/brand-spec.schema.md with W3C Design Tokens format"
    status: met
  - id: AC-3
    description: "/brand command runs interactive design workshop (identity → colors → typography → imagery → target examples → consolidation)"
    status: met
  - id: AC-4
    description: "/brand:tokens command generates Design Tokens artifact from brand guide"
    status: met
  - id: AC-5
    description: "/brand:image generates brand-consistent images via cost-tiered Gemini routing, logs to assets/manifest.md"
    status: met
  - id: AC-6
    description: "/brand:image gracefully degrades to prompt-only output when no MCP or API key is configured"
    status: met
  - id: AC-6a
    description: "/brand:image with no brand guide redirects user to /brand interview before proceeding"
    status: met
  - id: AC-7
    description: "brand-awareness skill activates during /design, /deliver, and /discern to inject brand context via brand_ref"
    status: met
  - id: AC-8
    description: "Existing workflow unchanged — Designer is opt-in; projects without brand guide skip it entirely"
    status: met
  - id: AC-9
    description: "designer agent available via Task tool for autonomous brand analysis"
    status: met
  - id: AC-10
    description: "Brand guide is a persistent artifact (never archived) with lifecycle: draft → active → deprecated"
    status: met
  - id: AC-11
    description: "Backlog items support brand_ref field linking to brand guide, parallel to spec_ref and adr_refs"
    status: met
---

# Shaped Work Contract: Designer Genie

**Date:** 2026-02-04 (reshaped 2026-02-05)
**Shaper:** Problem shaping
**Input:** `docs/analysis/20260203_discover_ux_design_agent.md`
**Spike:** `docs/analysis/20260205_spike_image_mcp_results.md`

---

## 1. Problem / Opportunity Statement

**Reframed as problem:** How do we enable solo developers and small teams to create brand-consistent visual assets without hiring a designer for every image, while maintaining professional quality and visual identity coherence?

**Evidence from Discovery:**
- Claude Code can analyze images but cannot generate them natively
- Manual asset creation is time-consuming and inconsistent
- Brand guidelines exist as tribal knowledge, not machine-readable specs
- MCP servers bridge Claude to image generation APIs (production-ready)

**Evidence from Spike (2026-02-05):**
- Gemini 2.5 Flash: precise prompt following, good for illustrations/isometric (lower cost)
- Gemini 3 Pro: best photorealism, text rendering, brand alignment (higher cost)
- OpenAI DALL-E 3: lost all 6 tests, critical text rendering failures
- Single MCP server (`@fastmcp-me/imagegen-mcp`) handles all providers
- Brand constraints noticeably improve output quality (T3 test validated)

---

## 2. Evidence & Insights

- **From Discovery:** `docs/analysis/20260203_discover_ux_design_agent.md`
- **From Spike:** `docs/analysis/20260205_spike_image_mcp_results.md`
  - Gemini 2.5 Flash won 2/6 tests (flat illustration, isometric — style precision)
  - Gemini 3 Pro won 4/6 tests (photography, logos, text, brand alignment)
  - DALL-E 3 rendered "LAUH DAY" instead of "LAUNCH DAY" — critical text failure
  - Cost-tiered routing validated: Flash for drafts/iteration, Pro for production

- **JTBD:**
  - Primary: "When I'm building a new product, I want to capture my brand identity once so all generated assets maintain visual consistency automatically."
  - Secondary: "When creating marketing assets, I want brand-consistent images without leaving my CLI."

---

## 3. Strategic Alignment

- Fills the design gap in the 7 D's workflow
- Follows ADR-001 Thin Orchestrator: additive, opt-in, no breaking changes
- Supports Cataliva multi-product orchestration
- Persona: Solo developers, small teams without dedicated designers

---

## 4. Appetite (Scope Box)

- **Appetite:** Medium batch (1-2 weeks)
  - Spike eliminated provider uncertainty, but interactive workshop adds depth
  - 6-phase interview generates visual options at each step (prompts, image gen calls, user interaction)
  - Known patterns: follows existing genie/skill/command structure
  - MCP server is already installed and working

- **Boundaries (in scope):**
  - New Designer genie persona and prompts
  - 3 new commands: `/brand`, `/brand:image`, `/brand:tokens`
  - 1 new skill: `brand-awareness` (cross-cutting, like `architecture-awareness`)
  - 1 new agent: `designer` (for Task tool invocation)
  - Cost-tiered model routing (Flash default, Pro for production)
  - Prompt-only fallback (no API key required)
  - Brand Spec schema: already done (AC-2 met)

- **No-gos (out of scope):**
  - Figma integration
  - Component library generation
  - GUI brand editor
  - Animation or motion design
  - OpenAI provider support (blocked by MCP bug — revisit later)
  - `/brand:review` command (defer — Critic skill handles this via brand-awareness)

- **Fixed elements:**
  - Must work without MCP configured (prompt-only fallback)
  - Must work without any API keys (prompt-only fallback)
  - Must integrate with existing workflow (opt-in, not required)
  - Brand spec uses YAML frontmatter per `schemas/brand-spec.schema.md`
  - CLI stability constraint (ADR-001)

---

## 5. Solution Sketch

### Integration Architecture: Commands + Skill + Agent

The Designer genie integrates via three mechanisms, following the same pattern as Architect (which has `/design` command + `architecture-awareness` skill + `architect` agent):

```
┌─────────────────────────────────────────────────────────┐
│  COMMANDS (user-invoked)                                │
│  ├── /brand [input]        → Create brand spec          │
│  ├── /brand:image [prompt] → Generate brand image       │
│  └── /brand:tokens [spec]  → Generate design tokens     │
└─────────────────────────────────────────────────────────┘
                         ↕ reads/writes brand spec
┌─────────────────────────────────────────────────────────┐
│  SKILL (auto-activated: brand-awareness)                │
│  ├── During /design  → Inject brand context for Arch.   │
│  ├── During /deliver → Provide tokens for Crafter       │
│  └── During /discern → Brand compliance for Critic      │
└─────────────────────────────────────────────────────────┘
                         ↕ isolated analysis
┌─────────────────────────────────────────────────────────┐
│  AGENT (Task tool: designer)                            │
│  └── Autonomous brand analysis, prompt crafting         │
└─────────────────────────────────────────────────────────┘
```

### Brand Guide: Persistent Artifact Model

The Designer manages the third pillar of persistent project knowledge:

```
     SPEC (WHAT)          BRAND (HOW IT LOOKS)
    /           \        /
   /             \      /
ADR (HOW+WHY) -- C4 (CONTEXT MAP)
```

| Concern | Genie | Artifact | Location | Bootstrap | Lifecycle |
|---------|-------|----------|----------|-----------|-----------|
| WHAT | Shaper | Specs | `docs/specs/{domain}/` | `/spec:init` | active → deprecated |
| HOW/WHY | Architect | ADRs + C4 | `docs/decisions/` + `docs/architecture/` | `/arch:init` | proposed → accepted → superseded |
| HOW IT LOOKS | Designer | Brand Guide + Tokens | `docs/brand/` | `/brand` | draft → active → deprecated |

**Directory structure** (in the target project):

```
docs/brand/
  {brand-name}.md              # Brand Guide (YAML frontmatter + design guide narrative)
  tokens.json                  # W3C Design Tokens (derived, machine-readable)
  assets/                      # Generated assets
    manifest.md                # Asset catalog with provenance (prompt, model, date)
    *.png / *.jpg              # Generated files
```

The Brand Guide file uses the same dual-format as specs:
- **YAML frontmatter** = machine-readable (colors, typography, imagery rules) per `schemas/brand-spec.schema.md`
- **Markdown body** = human-readable product design guide (principles, logo usage, color application, imagery guidelines, dos/don'ts)

**Persistence rules** (same as specs and ADRs):
- Brand guides are **never archived**, even when backlog items are `/done`
- Brand guides **accumulate knowledge** over time (new sections, updated tokens, asset history)
- Brand guides are the **source of truth** for how the product looks; backlog items are transient changes

### The `/brand` Interview: Interactive Design Workshop

The `/brand` interview is not a simple Q&A — it's a **facilitated design workshop** where the Designer actively generates visual options, the user reacts and chooses, and the brand emerges through iteration.

If no brand guide exists when `/brand` (or `/brand:image`) is called, the Designer guides the user into the interview.

**Phase 1: Brand Identity**
Conversational discovery — who are you, who's your audience, what do you stand for?

```
/brand
> No brand guide found. Let's build one together.
>
> What's the brand name? > Acme
> In one sentence, what does Acme do? > Developer tools that just work.
> Who's the primary audience? > Solo devs and small engineering teams
> What 3 words describe how Acme should feel? > Confident, approachable, sharp
```

**Phase 2: Color Exploration**
Designer generates 2-3 color palette options as visual swatches. User picks or remixes.

```
> Let me generate some palette options based on "confident, approachable, sharp"...
>
> Option A: Deep blue + amber accent (trust + energy)
>   [generates palette swatch image via Flash]
> Option B: Slate + emerald accent (precision + growth)
>   [generates palette swatch image via Flash]
> Option C: Navy + coral accent (authority + warmth)
>   [generates palette swatch image via Flash]
>
> Which direction resonates? Or describe what you'd change.
> > A, but warmer — more like electric blue than deep blue
>
> Refining...
>   [generates refined palette swatch]
> How's this?
```

**Phase 3: Typography & Style**
Suggest font pairings and UI style patterns. Show examples.

```
> For "confident + approachable", I'd suggest:
>   Heading: Inter (geometric, clean authority)
>   Body: Inter (consistency) or Source Sans (warmer)
>   Mono: JetBrains Mono (developer audience)
>
> UI style patterns for developer tools:
>   [generates example UI mockup — dashboard with chosen colors + fonts via Flash]
>
> Does this direction feel right?
```

**Phase 4: Imagery Style**
Generate sample images in different styles with the chosen palette. Side-by-side comparison.

```
> Let's find your imagery style. Same prompt, three approaches:
>
> Photography style:
>   [generates team collaboration photo via Flash]
> Flat illustration style:
>   [generates flat illustration via Flash]
> Abstract/geometric style:
>   [generates abstract pattern via Flash]
>
> Which fits Acme's personality? > Photography, but less stock-photo-y
>
> Refining mood: "candid, natural light, real workspaces"
>   [generates refined example via Flash]
```

**Phase 5: Target Examples**
Generate reference images using the finalized brand. These become the first entries in the asset catalog — **the brand's visual north star.**

Defaults to Flash (free tier). User can explicitly request Pro for any example.

```
> Let me create target examples using your finalized brand.
>
> Hero image (landing page):
>   [generates via Flash]
> Social media banner:
>   [generates via Flash]
> Logo concept:
>   [generates via Flash]
>
> Saved to docs/brand/assets/ with full provenance.
>
> Want to upgrade any of these to production quality?
>   /brand:image "hero image for landing page" --pro
>   (Uses Gemini 3 Pro for higher fidelity)
```

**Phase 6: Consolidation**
Write the brand guide with all decisions captured.

```
> Brand guide complete!
>
> Saved: docs/brand/acme.md (status: draft)
>   - Identity: mission, values, voice
>   - Colors: primary #2563EB, accent #F59E0B, full palette
>   - Typography: Inter / JetBrains Mono
>   - Imagery: photography, candid, natural light
>   - Target examples: 3 reference images
> Saved: docs/brand/tokens.json
> Saved: docs/brand/assets/manifest.md (3 target examples)
>
> Review the guide. When ready: /brand docs/brand/acme.md --activate
```

**Key design principles for the interview:**
- **Show, don't just ask** — generate visual options at each phase, don't just collect text answers
- **Iterate, don't finalize** — each phase allows remixing and refinement
- **Use Flash for exploration, Pro for target examples** — cost-tiered routing in action
- **Capture decisions** — every choice becomes part of the brand guide narrative (why this palette, why photography over illustration)
- **Target examples are the north star** — they're the visual standard that all future generations aim to match

**Evolution mode** (`/brand docs/brand/acme.md --evolve`):
Re-enters the workshop for specific phases. E.g., "adding dark mode" → Phase 2 color exploration with dark palette, then regenerate tokens and target examples.

```
/brand docs/brand/acme.md --evolve "Adding dark mode variant"
> Loading existing brand guide...
> Entering color exploration for dark mode variant.
>
> Based on your light palette (#2563EB primary), here are dark options:
>   [generates dark palette swatch options via Flash]
> ...
```

**Guard rail** — if no brand guide exists:

```
/brand:image "hero image for landing page"
> No brand guide found at docs/brand/.
> A brand guide helps ensure consistent, high-quality images.
>
> Would you like to:
>   1. Start the brand interview (/brand)
>   2. Generate without brand context (one-off, no consistency)
```

### Cross-Reference Pattern: brand_ref

Backlog items gain a `brand_ref` field, parallel to `spec_ref` and `adr_refs`:

```yaml
# In any backlog item
spec_ref: docs/specs/marketing/landing-page.md
adr_refs: [docs/decisions/ADR-005-ssr-strategy.md]
brand_ref: docs/brand/acme.md    # ← NEW
```

The `brand-awareness` skill reads `brand_ref` using the same loading pattern as `spec-awareness` reads `spec_ref`:
1. Check backlog frontmatter for `brand_ref`
2. If present: load the brand guide, inject context
3. If missing: scan `docs/brand/*.md` for any brand guide
4. If none found: silently continue (no overhead)
5. **Never block** — brand is valuable but optional

### Asset Catalog as Living Record

Each `/brand:image` generation appends to the asset manifest:

```markdown
## Asset: hero-landing-001.png
- **Generated:** 2026-02-05
- **Model:** gemini-3-pro-image-preview (premium tier)
- **Brand guide:** docs/brand/acme.md v1.2
- **Prompt:** "Professional hero image for B2B SaaS landing page..."
- **Augmented with:** colors (primary #2563EB, accent #F59E0B), mood (modern, clean), style (photography)
```

This gives the Designer a paper trail — like how `/deliver` appends implementation evidence to specs.

### Cost-Tiered Model Routing

```
/brand:image receives prompt
    │
    ├─ --pro flag explicitly set?
    │   YES → Gemini 3 Pro (user chose premium)
    │
    └─ Default (all other cases)
        └─ Gemini 2.5 Flash (lower cost)
```

Pro is always opt-in via `--pro`. Flash handles everything by default — drafts, target examples, exploration. The user upgrades specific images when they want production quality.

### Graceful Degradation (3 tiers)

| Tier | Requirements | Behavior |
|------|-------------|----------|
| **Full** | `GOOGLE_API_KEY` + imagegen MCP | Generate images via cost-tiered Gemini routing |
| **Basic** | imagegen MCP only (no key) | Warn about missing key, output prompt only |
| **Prompt-only** | No MCP, no API key | Craft optimized brand-aware prompt, output to clipboard/file for use in free tools (Gemini web, ChatGPT free, Ideogram, etc.) |

The prompt-only mode is the **zero-cost floor**. The Designer genie still provides value by:
1. Reading the brand spec
2. Augmenting the user's request with brand colors, style, mood, and constraints
3. Outputting a crafted prompt optimized for image generation
4. Suggesting which free tool to paste it into

### New Files

```
.claude/commands/
├── brand.md                    # /brand [input] — create brand spec
├── brand-image.md              # /brand:image [prompt] — generate image
└── brand-tokens.md             # /brand:tokens [brand-spec] — generate tokens

.claude/skills/brand-awareness/
└── SKILL.md                    # Cross-cutting brand context injection

.claude/agents/designer.md      # Task(subagent_type='designer', ...)
```

### Genie Persona Files

```
genies/designer/
├── GENIE.md                    # Overview, identity, role
├── DESIGNER_SPEC.md            # Detailed capabilities
└── DESIGNER_SYSTEM_PROMPT.md   # System prompt for image gen context
```

### Brand-Awareness Skill Behavior

The `brand-awareness` skill follows the same pattern as `architecture-awareness` and `spec-awareness`:

**Activation triggers:** "brand", "brand spec", "design tokens", "brand consistent", "visual identity"

**During /design:**
1. Scan for brand spec in project root or `docs/brand/`
2. If found: inject brand constraints as design context for Architect
3. Architect receives color tokens, typography, imagery style as input

**During /deliver:**
1. Load brand spec if present
2. Surface design tokens for Crafter (theming, colors, typography)
3. Reference token values in implementation guidance

**During /discern:**
1. Load brand spec if present
2. Add "Brand Compliance" to Critic's review checklist
3. Check: Do implemented colors match brand spec? Do images follow style guidelines?
4. Output compliance table (similar to ADR compliance in architecture-awareness)

**During /context:load:**
1. Check for brand spec files in project
2. Report: "Brand spec found: {path}" or "No brand spec found"

### Workflow Position (unchanged)

```
Scout → Shaper → Designer (opt-in) → Architect → Crafter → Critic → Tidier
                    ↑
              /brand creates
              brand spec here
```

Designer is fully opt-in. Projects without a brand spec skip it. The `brand-awareness` skill silently detects "no brand spec" and adds no overhead.

---

## 6. Rabbit Holes

- **Don't build a prompt router ML model** — use simple keyword matching for cost-tier selection
- **Don't build image quality scoring** — trust the model selection heuristic
- **Don't build MCP server** — use existing `@fastmcp-me/imagegen-mcp`
- **Don't add OpenAI support** — blocked by MCP bug, not worth fixing upstream for now
- **Don't build brand spec editor** — CLI-first, YAML editing is fine for v1
- **Don't add `/brand:review`** — brand compliance checking is handled by `brand-awareness` skill during `/discern`

---

## 7. Behavioral Delta

**Spec:** `docs/specs/genies/designer.md`

### Current Spec (from initial shaping)

- AC-4: `/design:brand` command (collision with Architect's `/design` namespace)
- AC-5: `/design:tokens` command
- AC-6: `/design:image` command (no model routing, no degradation path)
- AC-7: `/design:review` command
- AC-10: Critic extended with design-aware review skill

### Proposed Changes

| AC | Current | Proposed | Rationale |
|----|---------|----------|-----------|
| AC-4 | `/design:brand` command | `/brand` command (own namespace) | Avoids collision with Architect's `/design` |
| AC-5 | `/design:tokens` command | `/brand:tokens` command | Consistent with `/brand` namespace |
| AC-6 | `/design:image` with generic MCP | `/brand:image` with cost-tiered Gemini routing | Spike proved Gemini superiority; Flash default, Pro for production |
| AC-7 | `/design:review` command | Removed — handled by `brand-awareness` skill during `/discern` | Simpler; follows architecture-awareness pattern |
| AC-10 | Critic extended with design-aware skill | `brand-awareness` skill activates during `/discern` | Same outcome, better pattern (cross-cutting skill) |
| NEW | — | Prompt-only fallback when no API key | Zero-cost floor for users who can't pay for APIs |
| NEW | — | `brand-awareness` skill as cross-cutting behavior | Injects brand context into /design, /deliver, /discern |
| NEW | — | `designer` agent for Task tool | Autonomous brand analysis in subagent |

### Rationale

1. **Namespace change**: `/design` belongs to Architect. Designer needs its own command namespace (`/brand`) to avoid confusion about which genie handles which sub-command.
2. **Skill pattern**: `brand-awareness` follows the proven `architecture-awareness` and `spec-awareness` pattern — a cross-cutting concern that enriches multiple workflow phases.
3. **Cost-tiered routing**: Spike proved Flash is sufficient for most use cases; Pro reserved for production/photography. Keeps costs low by default.
4. **Prompt-only fallback**: Users without API keys still get value — the Designer crafts optimized prompts they can paste into free tools.

---

## 8. Open Questions

### For Architect
- Should `brand-awareness` skill auto-detect brand guide in `docs/brand/` or require explicit `brand_ref` on every backlog item?
- How should `/brand --evolve` handle concurrent changes to the brand guide?
- What is the tokens.json regeneration strategy — on every `/brand` update, or explicit via `/brand:tokens`?

### For Navigator
- Is Medium batch (1 week) right for this reduced scope?
- Should we ship `/brand` and `brand-awareness` separately (incremental) or together?

---

## 9. Dependencies

- **Met:** Brand spec schema (`schemas/brand-spec.schema.md`) — AC-2 done
- **Met:** MCP server installed and tested (`@fastmcp-me/imagegen-mcp` v0.1.9)
- **Met:** Spike validated provider strategy
- **Minor:** `gemini-3-pro-image-preview` model availability (currently preview)

---

## 10. Routing Target

- [x] **Architect** — Needs technical design for:
  - `brand-awareness` skill activation and loading patterns
  - `/brand` command file structure and prompt construction
  - Cost-tiered model routing implementation
  - Graceful degradation detection logic
  - Brand spec file discovery heuristic

- [ ] **Crafter** — Not ready (needs design first)

---

## Artifacts

- **Contract:** `docs/backlog/P1-designer-genie.md` (this file)
- **Spec:** `docs/specs/genies/designer.md` (to be updated)
- **Spike:** `docs/analysis/20260205_spike_image_mcp_results.md`
- **Discovery:** `docs/analysis/20260203_discover_ux_design_agent.md`
- **Schema:** `schemas/brand-spec.schema.md`
- **ADR (proposed):** `docs/decisions/ADR-002-designer-integration-commands-plus-skill.md`

---

# Design

> **Produced by:** Architect genie via `/design docs/backlog/P1-designer-genie.md`
> **Date:** 2026-02-05
> **Schema:** `schemas/design-document.schema.md` v1.0

```yaml
spec_version: "1.0"
type: design
id: designer-genie
title: "Designer Genie for Brand-Consistent Asset Generation"
status: designed
created: 2026-02-05
spec_ref: docs/specs/genies/designer.md
backlog_ref: docs/backlog/P1-designer-genie.md
appetite: medium
complexity: moderate
author: architect
adr_refs:
  - docs/decisions/ADR-002-designer-integration-commands-plus-skill.md
ac_mapping:
  - ac_id: AC-1
    approach: "Create genies/designer/ directory with GENIE.md, DESIGNER_SPEC.md, DESIGNER_SYSTEM_PROMPT.md following existing genie file pattern"
    components:
      - genies/designer/GENIE.md
      - genies/designer/DESIGNER_SPEC.md
      - genies/designer/DESIGNER_SYSTEM_PROMPT.md
  - ac_id: AC-2
    approach: "Already met — schemas/brand-spec.schema.md exists"
    components:
      - schemas/brand-spec.schema.md
  - ac_id: AC-3
    approach: "brand.md command file orchestrates 6-phase interactive workshop using AskUserQuestion and image generation MCP tools"
    components:
      - .claude/commands/brand.md
      - genies/designer/DESIGNER_SYSTEM_PROMPT.md
  - ac_id: AC-4
    approach: "brand-tokens.md command reads brand guide YAML frontmatter and transforms to W3C Design Tokens JSON"
    components:
      - .claude/commands/brand-tokens.md
  - ac_id: AC-5
    approach: "brand-image.md command with cost-tiered routing: Flash default, Pro on --pro flag; logs to assets/manifest.md"
    components:
      - .claude/commands/brand-image.md
  - ac_id: AC-6
    approach: "brand-image.md detects MCP availability via tool listing and API key via env var; falls back to prompt-only output"
    components:
      - .claude/commands/brand-image.md
  - ac_id: AC-6a
    approach: "brand-image.md checks for docs/brand/*.md before generation; if missing, offers /brand interview or one-off generation"
    components:
      - .claude/commands/brand-image.md
  - ac_id: AC-7
    approach: "brand-awareness SKILL.md follows spec-awareness/architecture-awareness pattern with brand_ref loading and per-command injection"
    components:
      - .claude/skills/brand-awareness/SKILL.md
  - ac_id: AC-8
    approach: "brand-awareness uses warn-never-block pattern — silently continues when no brand guide exists"
    components:
      - .claude/skills/brand-awareness/SKILL.md
  - ac_id: AC-9
    approach: "agents/designer.md defines Task tool agent with Read, Glob, Grep tools and structured output format"
    components:
      - agents/designer.md
  - ac_id: AC-10
    approach: "Brand guide lifecycle managed via brand.md command: --activate promotes draft→active, --evolve re-enters workshop phases"
    components:
      - .claude/commands/brand.md
  - ac_id: AC-11
    approach: "brand-awareness skill reads brand_ref from backlog frontmatter; schemas/shaped-work-contract.schema.md documents the optional field"
    components:
      - .claude/skills/brand-awareness/SKILL.md
      - schemas/shaped-work-contract.schema.md
components:
  - name: "Designer Genie (persona files)"
    action: create
    files:
      - genies/designer/GENIE.md
      - genies/designer/DESIGNER_SPEC.md
      - genies/designer/DESIGNER_SYSTEM_PROMPT.md
  - name: "/brand command"
    action: create
    files:
      - .claude/commands/brand.md
  - name: "/brand:image command"
    action: create
    files:
      - .claude/commands/brand-image.md
  - name: "/brand:tokens command"
    action: create
    files:
      - .claude/commands/brand-tokens.md
  - name: "brand-awareness skill"
    action: create
    files:
      - .claude/skills/brand-awareness/SKILL.md
  - name: "designer agent"
    action: create
    files:
      - agents/designer.md
  - name: "install.sh"
    action: modify
    files:
      - install.sh
  - name: "C4 Container Diagram"
    action: modify
    files:
      - docs/architecture/containers.md
  - name: "Shaped Work Contract Schema"
    action: modify
    files:
      - schemas/shaped-work-contract.schema.md
```

## Design Overview

The Designer genie adds brand strategy and visual asset generation to the genie team workflow via three integration mechanisms: **commands** (`/brand`, `/brand:image`, `/brand:tokens`), a **skill** (`brand-awareness`), and an **agent** (`designer`). This follows the same triple-mechanism pattern established by the Architect genie (`/design` + `architecture-awareness` + `architect` agent).

All new files are markdown prompt definitions — no code compilation, no runtime dependencies beyond the existing `@fastmcp-me/imagegen-mcp` MCP server. The design adds 9 new files and modifies 3 existing files.

## Architecture

### System Context

The Designer genie sits between Shaper and Architect in the workflow (opt-in). It consumes brand requirements from Shaper's shaped work contracts and produces brand guides + design tokens consumed by Architect, Crafter, and Critic via the `brand-awareness` skill.

```
Developer
    │
    ├── /brand ──────────► Designer Genie ──► docs/brand/{name}.md (Brand Guide)
    │                          │              docs/brand/tokens.json (Tokens)
    │                          │              docs/brand/assets/ (Images)
    │                          │
    │                          ▼
    │                   imagegen MCP ──► Gemini 2.5 Flash / 3 Pro
    │
    ├── /brand:image ──► Designer (image gen with brand context)
    │
    └── /brand:tokens ─► Designer (token extraction from brand guide)
```

### Component Design

| Component | Responsibility | New/Modified | Source Pattern |
|-----------|---------------|--------------|----------------|
| `genies/designer/GENIE.md` | Designer identity, charter, WILL/WILL NOT | New | `genies/architect/GENIE.md` |
| `genies/designer/DESIGNER_SPEC.md` | Detailed capabilities, input/output scope | New | `genies/architect/ARCHITECT_SPEC.md` |
| `genies/designer/DESIGNER_SYSTEM_PROMPT.md` | System prompt for brand strategy + image gen | New | `genies/architect/ARCHITECT_SYSTEM_PROMPT.md` |
| `.claude/commands/brand.md` | Interactive brand workshop (6 phases) | New | `.claude/commands/design.md` |
| `.claude/commands/brand-image.md` | Brand-consistent image generation | New | `.claude/commands/design.md` |
| `.claude/commands/brand-tokens.md` | W3C Design Token extraction | New | `.claude/commands/design.md` |
| `.claude/skills/brand-awareness/SKILL.md` | Cross-cutting brand context injection | New | `.claude/skills/architecture-awareness/SKILL.md` |
| `agents/designer.md` | Autonomous brand analysis subagent | New | `agents/architect.md` |
| `install.sh` | Add designer genie to distribution | Modified | — |

### Data Flow

```
/brand (interview)
    │
    ├─ Phase 1: Identity ──► AskUserQuestion (conversational)
    │     └─► brand identity data collected
    │
    ├─ Phase 2: Colors ──► mcp__imagegen__image_generate_gemini (Flash)
    │     └─► 2-3 palette swatches ──► AskUserQuestion (pick/remix)
    │
    ├─ Phase 3: Typography ──► mcp__imagegen__image_generate_gemini (Flash)
    │     └─► UI mockup with fonts ──► AskUserQuestion (confirm/adjust)
    │
    ├─ Phase 4: Imagery ──► mcp__imagegen__image_generate_gemini (Flash) × 3
    │     └─► photo/illustration/abstract samples ──► AskUserQuestion (pick style)
    │
    ├─ Phase 5: Target Examples ──► mcp__imagegen__image_generate_gemini (Flash)
    │     └─► reference images ──► assets/manifest.md + assets/*.png
    │     └─► user can --pro specific images ──► gemini-3-pro-image-preview
    │
    └─ Phase 6: Consolidation
          ├─► docs/brand/{name}.md (YAML frontmatter + narrative body)
          ├─► docs/brand/tokens.json (W3C Design Tokens)
          └─► docs/brand/assets/manifest.md (asset catalog)
```

```
/brand:image [prompt]
    │
    ├─ Check docs/brand/*.md exists?
    │   NO ──► Guard rail: offer /brand interview or one-off
    │   YES ──► Load brand guide YAML frontmatter
    │
    ├─ Augment prompt with brand context:
    │   colors, mood, style, subjects, avoid list
    │
    ├─ Detect MCP + API key availability:
    │   FULL ──► Select model (Flash default, Pro on --pro)
    │            └─► mcp__imagegen__image_generate_gemini
    │   BASIC ──► Warn missing API key, output prompt only
    │   NONE ──► Craft brand-aware prompt for free tools
    │
    └─ Log to docs/brand/assets/manifest.md
```

```
brand-awareness skill (cross-cutting)
    │
    ├─ During /design:
    │   └─► Read brand guide ──► Inject as Architect context
    │       (colors, typography, imagery constraints)
    │
    ├─ During /deliver:
    │   └─► Read brand guide + tokens.json ──► Surface for Crafter
    │       (theming values, color constants, font stack)
    │
    ├─ During /discern:
    │   └─► Read brand guide ──► Add Brand Compliance to review
    │       (color adherence, style consistency, token usage)
    │
    └─ During /context:load:
        └─► Report brand guide status
```

## Interfaces & Contracts

### GENIE.md Frontmatter Contract

```yaml
---
name: designer
description: Brand strategist for visual identity, design systems, and AI-assisted asset generation. Transforms brand requirements into machine-readable specifications.
tools: Read, Glob, Grep
model: inherit
context: fork
---
```

**Key design decision:** Designer genie does NOT have Write, Edit, or Bash tools. All file writing is done by the orchestrator (main Claude Code context) after the designer agent returns its analysis. The `/brand` command (which runs in the main context, not as a subagent) uses the full tool set including Write and image generation MCP tools.

### Command Interface: `/brand [input]`

```markdown
# Arguments
- `input` - Optional: brand name, requirements, or path to existing brand guide
- Optional flags:
  - `--activate` - Promote brand guide from draft → active
  - `--evolve "reason"` - Re-enter workshop to update specific phases
  - No flags - Start new brand interview

# Context Loading
READ:
  - docs/brand/*.md (existing brand guides)
  - schemas/brand-spec.schema.md (frontmatter contract)
  - genies/designer/DESIGNER_SYSTEM_PROMPT.md (persona)

WRITE:
  - docs/brand/{name}.md (brand guide)
  - docs/brand/tokens.json (design tokens)
  - docs/brand/assets/manifest.md (asset catalog)
  - docs/brand/assets/*.png (generated images)
```

### Command Interface: `/brand:image [prompt]`

```markdown
# Arguments
- `prompt` - Description of desired image (required)
- Optional flags:
  - `--pro` - Use Gemini 3 Pro (premium tier)
  - `--brand [path]` - Explicit brand guide path (overrides auto-detect)
  - No flags - Use Gemini 2.5 Flash (default tier)

# Context Loading
READ:
  - docs/brand/*.md (auto-detect brand guide)
  - Backlog item brand_ref (if in workflow context)

WRITE:
  - docs/brand/assets/{filename}.png (generated image)
  - docs/brand/assets/manifest.md (append entry)
```

### Command Interface: `/brand:tokens [brand-guide]`

```markdown
# Arguments
- `brand-guide` - Path to brand guide (optional, auto-detects from docs/brand/)

# Context Loading
READ:
  - docs/brand/{name}.md (YAML frontmatter)

WRITE:
  - docs/brand/tokens.json (W3C Design Tokens)
```

### Brand-Awareness Skill Interface

```yaml
---
name: brand-awareness
description: Ensures brand-consistent behavior during workflows. Auto-activates when brand guide exists and "brand", "brand spec", "design tokens", "brand consistent", or "visual identity" are mentioned. Activates during /design, /deliver, /discern, /context:load, and /context:refresh.
allowed-tools: Read, Glob, Grep
---
```

**Loading pattern** (mirrors spec-awareness and architecture-awareness):

```
1. Check backlog frontmatter for brand_ref
2. If brand_ref present: Read the referenced brand guide file
3. If brand_ref missing: Scan docs/brand/*.md for any brand guide
4. If no brand guide found: Silently continue (no overhead, no warning)
5. Never block — brand is valuable but optional
```

**Key difference from spec-awareness:** Step 4 does NOT warn when no brand guide is found. Brand is fully opt-in — there's no expectation that every project has one. This contrasts with spec-awareness which warns about missing specs (since specs are expected).

### Designer Agent Interface

```yaml
# agents/designer.md
name: designer
description: Brand analysis and prompt crafting subagent. Analyzes brand guides, crafts image generation prompts, evaluates brand consistency.
tools: Read, Glob, Grep
context: fork
```

**Output format:**
```markdown
## Agent Result: Designer

**Task:** [Original prompt]
**Status:** complete | partial | blocked
**Confidence:** high | medium | low

### Findings
[Brand analysis, prompt recommendations, consistency evaluation]

### Files Examined
[Up to 10 files]
```

### Prompt Augmentation Contract

When `/brand:image` augments a user prompt with brand context, it constructs the augmented prompt following this pattern:

```
[User's original prompt]

Brand context (apply consistently):
- Style: {imagery.style}
- Mood: {imagery.mood | join(", ")}
- Color palette: primary {colors.primary}, secondary {colors.secondary}, accent {colors.accent}
- Preferred subjects: {imagery.subjects | join(", ")}
- Avoid: {imagery.avoid | join(", ")}
- Typography mood: {typography.headings.family} headings, {typography.body.family} body
- No text overlay unless explicitly requested.
```

The "No text overlay" default suppresses Gemini's tendency to hallucinate brand names (observed in spike T3/T6). User can override with explicit text instructions.

### W3C Design Tokens Format

`/brand:tokens` produces `docs/brand/tokens.json` in W3C Design Tokens Community Group format:

```json
{
  "brand": {
    "color": {
      "primary": { "$type": "color", "$value": "#2563EB" },
      "secondary": { "$type": "color", "$value": "#1E40AF" },
      "accent": { "$type": "color", "$value": "#F59E0B" },
      "background": { "$type": "color", "$value": "#FFFFFF" },
      "foreground": { "$type": "color", "$value": "#1F2937" }
    },
    "typography": {
      "heading-family": { "$type": "fontFamily", "$value": "Inter" },
      "body-family": { "$type": "fontFamily", "$value": "Inter" },
      "mono-family": { "$type": "fontFamily", "$value": "JetBrains Mono" }
    },
    "semantic": {
      "success": { "$type": "color", "$value": "#10B981" },
      "warning": { "$type": "color", "$value": "#F59E0B" },
      "error": { "$type": "color", "$value": "#EF4444" },
      "info": { "$type": "color", "$value": "#3B82F6" }
    }
  }
}
```

## Pattern Adherence

- **Genie file pattern:** 3 files per genie (GENIE.md, {NAME}_SPEC.md, {NAME}_SYSTEM_PROMPT.md) — matches all existing genies. Note: No template file needed since Designer's output (brand guide) uses the brand-spec schema, not a custom template.
- **Command file pattern:** Markdown prompt definitions at `.claude/commands/{name}.md` — matches all existing commands (design.md, deliver.md, etc.)
- **Skill file pattern:** `.claude/skills/{name}/SKILL.md` with YAML frontmatter — matches architecture-awareness and spec-awareness exactly.
- **Agent file pattern:** `agents/{name}.md` with structured output format — matches scout, architect, critic, tidier.
- **Schema pattern:** YAML-frontmatter-first document design — brand guide uses same dual-format as specs.
- **Loading pattern:** Check frontmatter ref → scan directory → warn/continue — identical to spec-awareness and architecture-awareness.
- **Install pattern:** `install.sh` copies genies/, agents/, commands/, skills/ to target project — Designer files follow same directory conventions.

**Deviations:** None. The Designer genie follows every established pattern without modification.

## Technical Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| Integration mechanism | A: Commands only, B: Skill only, C: Commands + Skill, D: Separate namespaces | **C: Commands + Skill** | ADR-002: Follows Architect pattern; commands for explicit actions, skill for cross-cutting context |
| Command namespace | `/design:brand` (share Architect's namespace), `/brand` (own namespace) | **`/brand`** | Avoids collision with Architect's `/design`; clear genie ownership |
| Image generation model | Single model, best-of-both, category routing | **Cost-tiered routing** | Spike proved Flash sufficient for most cases; Pro reserved for explicit `--pro` |
| No brand guide behavior | Block, warn, silently skip | **Silently skip** | Brand is fully opt-in; no overhead when not used |
| Prompt augmentation | Template string, LLM-generated, hybrid | **Template string** | Deterministic, predictable, no extra LLM calls; brand YAML maps directly to prompt sections |
| Token regeneration | Auto on brand update, explicit command only | **Explicit `/brand:tokens`** | Avoids unexpected file changes; user controls when tokens sync |
| Designer genie tools | Full tool set, read-only | **Read-only (Read, Glob, Grep)** | Designer analyzes and recommends; does not write files directly as a subagent |
| MCP detection strategy | Check env vars, try-and-catch, tool listing | **Tool listing** | Check if `mcp__imagegen__image_generate_gemini` tool exists in available tools |
| Text overlay default | Include brand name, suppress text | **Suppress ("No text overlay")** | Spike showed Gemini hallucinating brand names; explicit opt-in is safer |

## Implementation Guidance

### Ordered Implementation Steps

**Step 1: Designer Genie Persona Files** (AC-1)

Create `genies/designer/` with three files following the Architect genie as the structural template:

1. **GENIE.md** — Identity, charter (WILL: brand strategy, color theory, prompt engineering, design tokens; WILL NOT: write code, make architectural decisions, modify other genies), core behaviors, output format, routing logic.

2. **DESIGNER_SPEC.md** — Purpose & Identity, Role & Charter, Input Scope (brand requirements from Shaper, user descriptions, existing brand guidelines), Context Reading Behavior (brand guide loading, MCP detection).

3. **DESIGNER_SYSTEM_PROMPT.md** — System prompt establishing the Designer persona: expert visual designer combining brand strategy, design systems, visual language, and AI-native workflows. Core responsibilities (MUST/MUST NOT), judgment rules for color theory, typography pairing, imagery style selection, and prompt engineering. Output requirements reference brand-spec schema.

**Step 2: /brand Command** (AC-3, AC-10)

Create `.claude/commands/brand.md` implementing the 6-phase interactive workshop:

- Arguments: `[input]`, `--activate`, `--evolve "reason"`
- Genie invoked: Designer
- Context loading: Read `docs/brand/*.md`, `schemas/brand-spec.schema.md`, Designer system prompt
- Context writing: `docs/brand/{name}.md`, `docs/brand/tokens.json`, `docs/brand/assets/`
- Workshop phases: Identity → Colors → Typography → Imagery → Target Examples → Consolidation
- Each visual phase calls `mcp__imagegen__image_generate_gemini` with `model: "gemini-2.5-flash-image"` for exploration
- Uses `AskUserQuestion` between phases for user choices
- `--activate`: reads existing brand guide, changes frontmatter `status: draft` → `status: active`
- `--evolve "reason"`: reads existing brand guide, re-enters relevant phases based on the reason

**Step 3: /brand:image Command** (AC-5, AC-6, AC-6a)

Create `.claude/commands/brand-image.md`:

- Arguments: `[prompt]`, `--pro`, `--brand [path]`
- Guard rail: Check `docs/brand/*.md` exists; if not, offer interview or one-off (AC-6a)
- Brand context: Load brand guide YAML frontmatter, augment prompt per contract above
- MCP detection: Check for `mcp__imagegen__image_generate_gemini` in available tools
  - Full: Generate image via MCP with `model: "gemini-2.5-flash-image"` (default) or `model: "gemini-3-pro-image-preview"` (on `--pro`)
  - Basic: MCP exists but generation fails → output prompt only with warning
  - Prompt-only: No MCP → craft optimized prompt, suggest free tools
- Asset logging: Append to `docs/brand/assets/manifest.md` with provenance
- Save generated images to `docs/brand/assets/`

**Step 4: /brand:tokens Command** (AC-4)

Create `.claude/commands/brand-tokens.md`:

- Arguments: `[brand-guide]` (optional path, auto-detects from `docs/brand/`)
- Read brand guide YAML frontmatter
- Transform `visual.colors`, `visual.typography`, `visual.colors.semantic` to W3C Design Tokens format
- Write to `docs/brand/tokens.json`

**Step 5: brand-awareness Skill** (AC-7, AC-8, AC-11)

Create `.claude/skills/brand-awareness/SKILL.md`:

- Follow `architecture-awareness/SKILL.md` structure exactly
- YAML frontmatter: name, description, allowed-tools
- Activation triggers and per-command behaviors
- Loading pattern: `brand_ref` → scan → silent continue
- Per-command behaviors:
  - `/design`: Inject brand constraints as Architect context
  - `/deliver`: Surface tokens for Crafter theming
  - `/discern`: Add Brand Compliance table to review
  - `/context:load`: Report brand guide status
  - `/context:refresh`: Detect brand/token drift
- Anti-patterns section (what it does NOT do)

**Step 6: Designer Agent** (AC-9)

Create `agents/designer.md`:

- Follow `agents/architect.md` structure
- Tools: Read, Glob, Grep (read-only)
- Context: fork
- Structured output format with Findings section
- Use cases: brand analysis, prompt crafting, consistency evaluation

**Step 7: install.sh Update**

Modify `install.sh` to include `genies/designer/` in the genie distribution. No new install functions needed — the existing `install_genies()` function copies all `genies/*/` directories automatically. Verify that `brand-awareness` skill is included in `install_skills()`.

**Step 8: Schema Update** (AC-11)

Add `brand_ref` as an optional field to `schemas/shaped-work-contract.schema.md`:

```markdown
| `brand_ref` | string | Path to brand guide in docs/brand/ |
```

### Key Considerations

- **Must do:** All command files must reference `genies/designer/DESIGNER_SYSTEM_PROMPT.md` for consistent persona
- **Must do:** brand-awareness skill must use the identical loading pattern as spec-awareness (check ref → scan → warn/continue) but with silent-skip instead of warn on missing
- **Must do:** Prompt augmentation must include "No text overlay" by default to suppress hallucinated brand names
- **Should do:** Test the interview flow end-to-end with a mock brand before shipping
- **Should do:** Verify MCP tool names match exactly (`mcp__imagegen__image_generate_gemini`)

## Error Handling & Edge Cases

| Scenario | Expected Behavior | Handling |
|----------|-------------------|----------|
| No MCP server configured | `/brand:image` degrades to prompt-only | Detect via tool listing; output crafted prompt with free tool suggestions |
| MCP configured but no API key | Generation fails with auth error | Catch error, output the augmented prompt, suggest setting `GOOGLE_API_KEY` |
| No brand guide exists, user calls `/brand:image` | Guard rail activates | Offer two options via AskUserQuestion: start interview or generate without brand context |
| Multiple brand guides in `docs/brand/` | Ambiguous which to use | If only one: use it. If multiple: ask user to specify via `--brand` flag |
| Brand guide has `status: deprecated` | Should not be actively used | Warn user; suggest creating new brand guide or updating status |
| `/brand --evolve` on non-existent brand | Cannot evolve what doesn't exist | Redirect to `/brand` interview (create mode) |
| Image generation times out or fails | Don't block the workshop | Inform user, offer to retry or skip the visual phase and continue with text descriptions |
| tokens.json out of sync with brand guide | Stale tokens | `/context:refresh` can detect drift; recommend running `/brand:tokens` |
| `brand_ref` points to missing file | Broken reference | Warn and continue (same pattern as broken `spec_ref`) |

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Gemini model names change (preview → GA) | Medium | Medium | Model names are in command prompt text, easy to update; not compiled |
| MCP server `@fastmcp-me/imagegen-mcp` discontinued | Low | High | Prompt-only fallback ensures Designer still provides value; MCP server is replaceable |
| Image generation quality inconsistent | Medium | Low | Flash is "good enough" for exploration; Pro available for production; prompt augmentation improves consistency |
| 6-phase interview feels too long | Medium | Medium | Each phase is skippable; user can exit early and get a partial brand guide |
| Brand guide YAML becomes complex | Low | Medium | Schema is well-defined; only structured data in frontmatter, narrative in body |
| Gemini 2.5 Flash image generation becomes paid | Low | Medium | Prompt-only tier exists as zero-cost floor; other free models can be substituted |

## Testing Strategy

Since all components are markdown prompt definitions (no compiled code), testing is behavioral:

- **Unit:** Validate each command file has correct structure (Arguments, Genie, Context Loading/Writing, Output sections)
- **Unit:** Validate GENIE.md frontmatter matches schema (name, tools, context)
- **Unit:** Validate brand-awareness SKILL.md has correct activation triggers and per-command behaviors
- **Integration:** Run `/brand` workshop with test brand, verify all 6 phases produce expected outputs
- **Integration:** Run `/brand:image` with existing brand guide, verify prompt augmentation includes brand colors/mood/style
- **Integration:** Run `/brand:tokens` on sample brand guide, verify W3C format output
- **Integration:** Run `/brand:image` without MCP, verify graceful degradation to prompt-only
- **Integration:** Run `/design` with `brand_ref` set, verify brand-awareness injects context
- **Key scenarios:**
  - Fresh project: `/brand` → full interview → brand guide created
  - Existing brand: `/brand:image "hero" --pro` → premium generation with brand context
  - No MCP: `/brand:image "hero"` → prompt-only output with free tool suggestions
  - Cross-cutting: `/discern` with brand guide → Brand Compliance table in review

## Routing

- [x] **Crafter** — Design is complete, ready for implementation
- [ ] **Shaper** — N/A (scope is clear)
- [ ] **Scout** — N/A (spike is complete)

**Rationale:** All components are well-defined markdown files following established patterns. Implementation is straightforward prompt authoring. No architectural unknowns remain.

**Recommended implementation order:**
1. Persona files (Step 1) — foundation for everything else
2. brand-awareness skill (Step 5) — establishes the cross-cutting pattern
3. /brand:image command (Step 3) — highest user value, simplest command
4. /brand command (Step 2) — most complex, builds on skill and image gen
5. /brand:tokens command (Step 4) — simple transformation
6. designer agent (Step 6) — straightforward pattern copy
7. install.sh + schema updates (Steps 7-8) — distribution

**Next:** `/deliver docs/backlog/P1-designer-genie.md`

---

# Implementation

> **Produced by:** Crafter genie via `/deliver docs/backlog/P1-designer-genie.md`
> **Date:** 2026-02-05

## Files Created (9)

| File | AC | Purpose |
|------|-----|---------|
| `genies/designer/GENIE.md` | AC-1 | Designer genie identity, charter, core behaviors |
| `genies/designer/DESIGNER_SPEC.md` | AC-1 | Detailed specification: role, workshop process, behaviors |
| `genies/designer/DESIGNER_SYSTEM_PROMPT.md` | AC-1 | System prompt with judgment rules for color, typography, imagery, prompts |
| `.claude/commands/brand.md` | AC-3, AC-10 | 6-phase interactive brand workshop with --activate and --evolve modes |
| `.claude/commands/brand-image.md` | AC-5, AC-6, AC-6a | Cost-tiered image gen with graceful degradation and guard rail |
| `.claude/commands/brand-tokens.md` | AC-4 | W3C Design Token extraction with field-by-field mapping table |
| `.claude/skills/brand-awareness/SKILL.md` | AC-7, AC-8, AC-11 | Cross-cutting brand context injection, per-command behaviors |
| `agents/designer.md` | AC-9 | Autonomous brand analysis subagent with structured output |

## Files Modified (2)

| File | AC | Change |
|------|-----|--------|
| `schemas/shaped-work-contract.schema.md` | AC-11 | Added `adr_refs` and `brand_ref` optional fields |
| `docs/architecture/containers.md` | — | Added Designer, designer agent, Brand Awareness, Brand Commands, Image Gen MCP |

## No Changes Needed (1)

| File | Reason |
|------|--------|
| `install.sh` | Existing `install_genies()`, `install_skills()`, `install_commands()`, `install_agents()` auto-discover new directories/files |

## Pattern Adherence

All files follow established patterns exactly:
- **Genie files**: 3 files (GENIE.md, {NAME}_SPEC.md, {NAME}_SYSTEM_PROMPT.md) — matches architect, scout, shaper, crafter, critic, tidier
- **Command files**: Markdown prompt definitions with Arguments, Genie, Context Loading/Writing, Output, Routing sections — matches design.md, deliver.md
- **Skill file**: YAML frontmatter + activation triggers + per-command behaviors + update rules + anti-patterns — matches architecture-awareness, spec-awareness
- **Agent file**: YAML frontmatter + Agent Result Format + responsibilities + routing — matches architect, scout, critic, tidier
- **Schema update**: Optional field table addition — follows existing schema style

## AC Coverage

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Implemented | `genies/designer/GENIE.md`, `DESIGNER_SPEC.md`, `DESIGNER_SYSTEM_PROMPT.md` |
| AC-2 | Already met | `schemas/brand-spec.schema.md` (pre-existing) |
| AC-3 | Implemented | `.claude/commands/brand.md` (6-phase workshop with 3 modes) |
| AC-4 | Implemented | `.claude/commands/brand-tokens.md` (W3C format with mapping table) |
| AC-5 | Implemented | `.claude/commands/brand-image.md` (Flash default, Pro on --pro) |
| AC-6 | Implemented | `.claude/commands/brand-image.md` (3-tier degradation: full → basic → prompt-only) |
| AC-6a | Implemented | `.claude/commands/brand-image.md` (guard rail with AskUserQuestion) |
| AC-7 | Implemented | `.claude/skills/brand-awareness/SKILL.md` (per-command behaviors for /design, /deliver, /discern) |
| AC-8 | Implemented | `.claude/skills/brand-awareness/SKILL.md` (silent-skip when no brand guide) |
| AC-9 | Implemented | `agents/designer.md` (structured Agent Result Format) |
| AC-10 | Implemented | `.claude/commands/brand.md` (--activate for draft→active, --evolve for updates) |
| AC-11 | Implemented | `schemas/shaped-work-contract.schema.md` (brand_ref field), `.claude/skills/brand-awareness/SKILL.md` (brand_ref loading) |

---

## Routing

**Next:** `/commit docs/backlog/P1-designer-genie.md`

---

# Review

> **Produced by:** Critic genie via `/discern docs/backlog/P1-designer-genie.md`
> **Date:** 2026-02-05

## Verdict: CHANGES REQUESTED

All 12 spec ACs are **MET**. ADR-002 is **fully compliant**. One minor issue prevents full approval.

## AC Verdicts

| AC | Description | Verdict | Evidence |
|----|-------------|---------|----------|
| AC-1 | Designer genie directory with 3 files | MET | `genies/designer/GENIE.md`, `DESIGNER_SPEC.md`, `DESIGNER_SYSTEM_PROMPT.md` — follows Architect pattern exactly |
| AC-2 | Brand Spec schema | MET | Pre-existing `schemas/brand-spec.schema.md`; SYSTEM_PROMPT.md includes full YAML template |
| AC-3 | /brand workshop (6 phases) | MET | `brand.md` implements Identity → Colors → Typography → Imagery → Target Examples → Consolidation with AskUserQuestion between phases |
| AC-4 | /brand:tokens command | MET | `brand-tokens.md` with 17-row mapping table, W3C format, auto-detect or explicit path |
| AC-5 | /brand:image cost-tiered | MET | `brand-image.md` Flash default, Pro on `--pro`, prompt augmentation with brand context |
| AC-6 | Graceful degradation | MET | `brand-image.md` 3-tier: Full → Basic → Prompt-only with free tool suggestions |
| AC-6a | Guard rail (no brand guide) | MET | `brand-image.md` AskUserQuestion with 2 options: interview or one-off |
| AC-7 | brand-awareness skill | MET | `SKILL.md` covers /design, /deliver, /discern with brand_ref loading pattern |
| AC-8 | Opt-in, no overhead | MET | Silent-skip pattern; "What This Skill Does NOT Do" section (7 anti-patterns) |
| AC-9 | designer agent | MET | `agents/designer.md` with structured Agent Result Format, read-only tools |
| AC-10 | Brand guide lifecycle | MET | `brand.md` --activate (draft→active), `DESIGNER_SPEC.md` lifecycle definition |
| AC-11 | brand_ref field | MET | `shaped-work-contract.schema.md` updated; `SKILL.md` loading pattern checks brand_ref first |

## ADR-002 Compliance

| Requirement | Status |
|-------------|--------|
| `/brand` namespace (no collision with `/design`) | Compliant |
| `brand-awareness` skill follows spec/arch-awareness pattern | Compliant |
| `designer` agent follows architect/scout agent pattern | Compliant |
| Silent-skip (not warn) when no brand guide | Compliant |
| Three-mechanism integration (commands + skill + agent) | Compliant |

## Pattern Adherence

| Pattern | Expected | Observed | Compliant? |
|---------|----------|----------|------------|
| GENIE.md structure | Heading, YAML, Identity, Charter, Behaviors, Output, Routing, Context | Matches Architect exactly | YES |
| GENIE.md tools | Read-only for Designer (design constraint) | `tools: Read, Glob, Grep` | YES |
| SPEC.md sections | 9 numbered sections | All present (Purpose, Role, Input, Workshop, Behaviors, Context, Routing, Constraints, Anti-Patterns, Integration) | YES |
| SYSTEM_PROMPT.md | MUST/MUST NOT, Judgment Rules, Output Requirements | 5 judgment rules, full YAML template | YES |
| Command .md structure | Arguments, Genie, Context Loading/Writing, Output, Routing, Notes, ARGUMENTS | All 3 commands compliant | YES |
| SKILL.md | YAML frontmatter, behaviors per command, update rules, anti-patterns | Matches architecture-awareness structure | YES |
| Agent .md | Frontmatter, Agent Result Format, responsibilities, routing | Matches architect agent structure | YES |

## Issues

### Issue 1: install.sh summary messages stale (CHANGES REQUESTED)

**Severity:** Minor
**Location:** `install.sh` lines 313-323 (global) and 444-450 (project)
**Problem:** The printed summary after installation doesn't list the new Designer artifacts:
- Skills line (319) missing `brand-awareness`
- Agents line (322) missing `designer`
- Commands don't list `/brand`, `/brand:image`, `/brand:tokens`

**Note:** Actual installation works correctly — `install_commands()`, `install_skills()`, `install_agents()`, `install_genies()` all auto-discover new files. Only the user-facing output strings are stale.

**Fix:** Update the echo statements at lines 313-323 (global summary) and 444-450 (project summary) to include Designer artifacts.

### Issue 2: No defects in implementation files

All 9 new files and 2 modified files are correctly implemented with no structural, behavioral, or pattern violations.

## Routing

**After fix:** `/commit docs/backlog/P1-designer-genie.md`
