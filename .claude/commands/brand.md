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

**MANDATORY: You MUST produce a viewable artifact for each palette option. Do NOT describe palettes in text tables.**

For each of 2-3 palette options, write an HTML file the user can open in their browser:

1. **Write** `docs/brand/assets/palette-options.html` using the Write tool. The HTML file MUST:
   - Be a self-contained HTML file (inline CSS, no external dependencies)
   - Show each palette option as a row of large color swatches (minimum 100px tall rectangles)
   - Label each swatch with its role (Primary, Secondary, Accent, Background, Foreground) and hex value
   - Set the text color on each swatch to ensure readability (white text on dark colors, dark text on light colors)
   - Include the palette name and mood keywords as a heading above each option
   - Show a sample text block for each palette: heading on background color, body text, a button in primary color with accent hover
   - Include semantic colors (success, warning, error, info) as a smaller row beneath each palette

2. **Tell the user** to open the file: `open docs/brand/assets/palette-options.html`

3. **Then** briefly explain the color theory rationale for each palette

4. Present options to user via AskUserQuestion. Allow remixing ("A, but warmer").

5. If user requests a remix: **regenerate the HTML file** with the refined palette and tell user to refresh.

Output: Color palette with hex values, rationale, and viewable HTML swatch file.

#### Phase 3: Typography & Style

Suggest font pairings appropriate to the brand personality and audience:
- **Headings:** Font family + weight (match brand personality)
- **Body:** Font family + weight (optimize for readability)
- **Monospace:** Font family (if developer audience)

**MANDATORY: You MUST produce a viewable artifact.** Write `docs/brand/assets/typography-preview.html` using the Write tool. The HTML file MUST:
- Be a self-contained HTML file using Google Fonts CDN (`<link>` tags) for the proposed fonts
- Use the chosen color palette as background/foreground/accent colors
- Show a sample page layout with: H1, H2, H3 headings, body paragraph, blockquote, button, code block (if mono font)
- Label each element with the font family, weight, and size being used
- Show the full type scale if one was proposed
- Include a side-by-side comparison if multiple font pairing options are offered

Tell the user to open: `open docs/brand/assets/typography-preview.html`

Present to user for confirmation or adjustment. If user requests changes, **regenerate the HTML file** with updated fonts/colors.

Output: Typography section with font families, weights, fallback stacks, and viewable HTML preview.

#### Phase 4: Imagery Style

**MANDATORY: You MUST generate 3 images — one per style. Do NOT describe styles in text — show them.**

This phase requires actual image generation. Generate the same concept (relevant to the brand) in 3 different styles by calling `mcp__imagegen__image_generate_gemini` three times:

1. **Photography** — `prompt`: A realistic photograph relevant to the brand's mission, using the brand color palette as environmental colors. Specify lighting, composition, mood.
   - `filenameHint`: `"style-photography"`
2. **Flat illustration** — `prompt`: A flat vector illustration of the same concept, using the exact brand colors ({primary}, {secondary}, {accent}). Clean lines, minimal style.
   - `filenameHint`: `"style-illustration"`
3. **Abstract/geometric** — `prompt`: An abstract geometric composition using the brand colors, conveying the brand mood. Patterns, shapes, gradients.
   - `filenameHint`: `"style-abstract"`

All three use `model: "gemini-2.5-flash-image"`. Generate ALL three images before presenting choices.

If image generation is not available, fall back to writing `docs/brand/assets/imagery-moodboard.html` with reference images from the web or detailed visual descriptions with color blocks showing the style direction.

Present all three to user. Allow the user to pick a direction and refine the mood. If refinement is requested, generate a NEW image with the adjusted style.

Output: Imagery guidelines with style, mood descriptors, preferred subjects, and things to avoid.

#### Phase 5: Target Examples

**MANDATORY: You MUST generate each target example image.** These are the brand's **visual north star**.

Generate 2-3 reference images using the finalized brand identity (colors, typography mood, imagery style) by calling `mcp__imagegen__image_generate_gemini` for each:

- `model`: `"gemini-2.5-flash-image"` (default) or `"gemini-3-pro-image-preview"` (if user requests `--pro`)
- Suggested targets with brand-augmented prompts:
  1. **Hero image** (landing page or marketing) — `filenameHint`: `"target-hero"`
  2. **Social media banner** — `filenameHint`: `"target-social"`
  3. **Logo concept or brand mark** — `filenameHint`: `"target-logo"`

Each prompt MUST include brand context: colors (hex values), mood, style, and "No text overlay unless explicitly requested."

If image generation is not available, output the brand-augmented prompts and suggest free tools to paste them into.

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

## Visual Output Rule

**CRITICAL: Every visual phase (2-5) MUST produce a viewable artifact. Text-only tables and descriptions are NEVER acceptable for visual decisions.**

The workshop uses two output strategies:

| Phase | Output Method | Rationale |
|-------|--------------|-----------|
| Phase 2: Colors | **HTML file** (Write tool) | Exact hex rendering, instant, no API needed |
| Phase 3: Typography | **HTML file** (Write tool, Google Fonts CDN) | Real fonts rendered in browser, exact colors |
| Phase 4: Imagery | **Image generation** (MCP tool) | Can't show photo vs illustration vs abstract without AI |
| Phase 5: Targets | **Image generation** (MCP tool) | Brand north star needs actual generated images |
| Phase 6: Consolidation | **Markdown file** (Write tool) | Brand guide document, no visuals needed |

**For Phases 2-3:** Always write an HTML file to `docs/brand/assets/` and tell the user to open it (`open docs/brand/assets/{file}.html`). HTML gives pixel-perfect color rendering and real font previews — better than any image generation for these use cases.

**For Phases 4-5:** Check if `mcp__imagegen__image_generate_gemini` is available:
- **If available:** Generate images. If a call fails, retry once, then fall back to prompt-only for that specific image.
- **If NOT available:** Output optimized prompts and suggest free tools. Tell the user: "Image generation is not configured. To enable it: `claude mcp add imagegen -- npx -y @fastmcp-me/imagegen-mcp`"

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

- **SHOW, don't describe.** Every visual phase (2-5) MUST produce generated images. Text-only palette tables, typography descriptions, or style explanations are NOT acceptable when image generation tools are available. The user needs to SEE and REACT to visuals, not read about them.
- Each phase allows iteration — if the user wants changes, generate a NEW image with the adjustments
- Flash tier is used for all workshop exploration (cost-efficient)
- Target examples are the brand's visual north star — the standard future generations aim to match
- Brand guide is written with `status: draft` — user must explicitly `--activate`
- Evolution mode preserves unchanged sections and only re-enters relevant phases

ARGUMENTS: $ARGUMENTS
