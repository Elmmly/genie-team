# /brand [input]

Activate Designer genie to create, evolve, or activate a brand guide via an interactive design workshop.

---

## Arguments

- `input` - Optional: brand name, requirements, or path to existing brand guide
- Optional flags:
  - `--activate` - Promote an existing brand guide from `draft` → `active`
  - `--evolve "reason"` - Re-enter specific workshop phases to update an existing brand guide
  - No flags - Start a new brand interview workshop

---

## Genie Invoked

**Designer** - Brand strategist combining:
- Brand strategy and identity development
- Color theory and typography pairing
- AI-native prompt engineering for image generation
- Design systems and token management

**System prompt:** `genies/designer/DESIGNER_SYSTEM_PROMPT.md`

---

## Context Loading

**READ (automatic):**
- `docs/brand/*.md` (existing brand guides)
- `schemas/brand-spec.schema.md` (frontmatter contract for brand specs)
- `genies/designer/DESIGNER_SYSTEM_PROMPT.md` (persona and judgment rules)

---

## Context Writing

**WRITE:**
- `docs/brand/{name}.md` (brand guide with YAML frontmatter + markdown narrative)
- `docs/brand/tokens.json` (W3C Design Tokens derived from brand guide)
- `docs/brand/assets/manifest.md` (asset catalog with provenance)
- `docs/brand/assets/*.png` (generated images from workshop)

---

## Modes

### Mode 1: New Brand Workshop (default)

When no flags are provided and no existing brand guide matches the input:

Run the **6-phase interactive design workshop**. Each phase builds on the previous.
Use AskUserQuestion between phases for user decisions.

#### Phase 1: Brand Identity

Conversational discovery — no image generation needed.

Gather:
- **Brand name** — What is the brand called?
- **Mission** — In one sentence, what does it do?
- **Audience** — Who is the primary audience?
- **Personality** — 3 words that describe how the brand should feel
- **Positioning** — How does it differentiate?

Output: Brand identity section for the brand guide.

#### Phase 2: Color Exploration

Generate 2-3 color palette options as visual swatches based on the brand personality.

For each option:
- Use `mcp__imagegen__image_generate_gemini` with `model: "gemini-2.5-flash-image"` to generate a palette swatch image
- Explain the color theory rationale (e.g., "blue conveys trust, amber adds energy")
- Show hex values for primary, secondary, accent, background, foreground

Present options to user via AskUserQuestion. Allow remixing ("A, but warmer").
Refine until user is satisfied.

Output: Color palette with hex values and rationale.

#### Phase 3: Typography & Style

Suggest font pairings appropriate to the brand personality and audience:
- **Headings:** Font family + weight (match brand personality)
- **Body:** Font family + weight (optimize for readability)
- **Monospace:** Font family (if developer audience)

Generate a UI mockup with the chosen colors and fonts using `mcp__imagegen__image_generate_gemini` with `model: "gemini-2.5-flash-image"`.

Present to user for confirmation or adjustment.

Output: Typography section with font families, weights, and fallback stacks.

#### Phase 4: Imagery Style

Generate the same concept prompt in 3 different styles:
1. **Photography** — realistic, photographic style
2. **Flat illustration** — vector, minimal, clean lines
3. **Abstract/geometric** — patterns, shapes, artistic

Use `mcp__imagegen__image_generate_gemini` with `model: "gemini-2.5-flash-image"` for each.

Present all three to user. Allow the user to pick a direction and refine the mood.

Output: Imagery guidelines with style, mood descriptors, preferred subjects, and things to avoid.

#### Phase 5: Target Examples

Generate 2-3 reference images using the finalized brand identity (colors, typography mood, imagery style). These are the brand's **visual north star**.

Default tier: Gemini 2.5 Flash (`gemini-2.5-flash-image`).
User can request `--pro` for any specific example to get premium quality.

Suggested targets:
- Hero image (landing page or marketing)
- Social media banner
- Logo concept or brand mark

Save each to `docs/brand/assets/` and log to `docs/brand/assets/manifest.md`.

Output: Target examples saved with provenance.

#### Phase 6: Consolidation

Write the complete brand guide:

1. **YAML frontmatter** — All structured data per `schemas/brand-spec.schema.md`:
   - `spec_version: "1.0"`
   - `type: brand-spec`
   - `brand_name`, `status: draft`, `created`, `author: designer`
   - `identity` object (mission, values, voice, positioning)
   - `visual` object (colors, typography, imagery)

2. **Markdown body** — Human-readable narrative:
   - Design principles and philosophy
   - Color application rules (when to use primary vs secondary vs accent)
   - Typography hierarchy
   - Imagery guidelines and dos/don'ts
   - Workshop decisions captured (why this palette, why this imagery style)

3. **Design Tokens** — Generate `docs/brand/tokens.json` in W3C format

4. **Status report:**
   ```
   > Brand guide complete!
   >
   > Saved: docs/brand/{name}.md (status: draft)
   > Saved: docs/brand/tokens.json
   > Saved: docs/brand/assets/manifest.md ({N} target examples)
   >
   > Review the guide. When ready: /brand docs/brand/{name}.md --activate
   ```

### Mode 2: Activate (`--activate`)

Promote an existing brand guide from `draft` → `active`:

1. Read the specified brand guide (or auto-detect from `docs/brand/`)
2. Verify it has `status: draft`
3. Update frontmatter: `status: draft` → `status: active`, add `updated: {today}`
4. Confirm:
   ```
   > Brand guide activated: docs/brand/{name}.md
   > Status: draft → active
   > This is now the source of truth for brand identity.
   ```

### Mode 3: Evolve (`--evolve "reason"`)

Re-enter specific workshop phases to update an existing brand guide:

1. Read the existing brand guide
2. Analyze the evolution reason to determine which phases to re-enter:
   - "adding dark mode" → Phase 2 (Color Exploration) + Phase 5 (Target Examples)
   - "new font" → Phase 3 (Typography) + Phase 5 (Target Examples)
   - "pivoting to illustration" → Phase 4 (Imagery Style) + Phase 5 (Target Examples)
   - "rebranding" → All phases
3. Run the relevant phases, preserving unchanged sections
4. Update the brand guide frontmatter (`updated: {today}`)
5. Regenerate `docs/brand/tokens.json` if visual values changed

---

## Graceful Degradation

If image generation is unavailable during the workshop:

- **Phases 2-5:** Describe visual options in text instead of generating images. Offer to generate later when MCP is available.
- **Phase 6:** Write brand guide normally — image generation is not required for the guide itself.
- Note: The workshop provides value even without image generation. The brand identity, color choices, and typography decisions are captured regardless.

---

## Usage Examples

```
/brand
> No brand guide found. Let's build one together.
>
> === Phase 1: Brand Identity ===
> What's the brand name?
> ...

/brand docs/brand/acme.md --activate
> Brand guide activated: docs/brand/acme.md
> Status: draft → active

/brand docs/brand/acme.md --evolve "Adding dark mode variant"
> Loading existing brand guide...
> Entering color exploration for dark mode variant.
> ...

/brand "Acme - developer tools that just work"
> Starting brand workshop for "Acme"...
> === Phase 1: Brand Identity ===
> I'll use "developer tools that just work" as a starting point.
> ...
```

---

## Routing

After brand workshop:
- `/brand:image` — Generate additional brand-consistent images
- `/brand:tokens` — Regenerate tokens if brand guide was updated
- `/brand --activate` — Promote draft to active
- `/design` — Proceed to technical design (brand-awareness skill will inject context)

---

## Notes

- The workshop is collaborative — show visual options, don't just ask questions
- Each phase allows iteration and refinement before moving on
- Flash tier is used for all workshop exploration (cost-efficient)
- Target examples are the brand's visual north star — the standard future generations aim to match
- Brand guide is written with `status: draft` — user must explicitly `--activate`
- Evolution mode preserves unchanged sections and only re-enters relevant phases

ARGUMENTS: $ARGUMENTS
