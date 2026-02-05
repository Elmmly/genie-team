---
spec_version: "1.0"
type: shaped-work
id: designer-genie
title: "Designer Genie for Brand-Consistent Asset Generation"
status: reshaped
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
    status: pending
  - id: AC-2
    description: "Brand Spec schema defined in schemas/brand-spec.schema.md with W3C Design Tokens format"
    status: met
  - id: AC-3
    description: "/brand command runs interactive design workshop (identity → colors → typography → imagery → target examples → consolidation)"
    status: pending
  - id: AC-4
    description: "/brand:tokens command generates Design Tokens artifact from brand guide"
    status: pending
  - id: AC-5
    description: "/brand:image generates brand-consistent images via cost-tiered Gemini routing, logs to assets/manifest.md"
    status: pending
  - id: AC-6
    description: "/brand:image gracefully degrades to prompt-only output when no MCP or API key is configured"
    status: pending
  - id: AC-6a
    description: "/brand:image with no brand guide redirects user to /brand interview before proceeding"
    status: pending
  - id: AC-7
    description: "brand-awareness skill activates during /design, /deliver, and /discern to inject brand context via brand_ref"
    status: pending
  - id: AC-8
    description: "Existing workflow unchanged — Designer is opt-in; projects without brand guide skip it entirely"
    status: pending
  - id: AC-9
    description: "designer agent available via Task tool for autonomous brand analysis"
    status: pending
  - id: AC-10
    description: "Brand guide is a persistent artifact (never archived) with lifecycle: draft → active → deprecated"
    status: pending
  - id: AC-11
    description: "Backlog items support brand_ref field linking to brand guide, parallel to spec_ref and adr_refs"
    status: pending
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

## Routing

**Next:** `/design docs/backlog/P1-designer-genie.md`
