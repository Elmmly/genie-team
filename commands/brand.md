# /brand [input]

Activate Designer genie to create, evolve, or activate a brand guide via an interactive design workshop.

---

## Arguments

- `input` - Optional: brand name, requirements, or path to existing brand guide
- Optional flags:
  - `--activate` - Promote an existing brand guide from `draft` → `active`
  - `--evolve "reason"` - Re-enter specific workshop phases to update an existing brand guide
  - `--workshop` - Force a fresh full workshop even when an existing brand guide exists
  - No flags - Review existing brand (if found) or start new workshop (if none found)

---

## Agent Identity

Read and internalize `.claude/agents/designer.md` for your identity, charter, and judgment rules.

---

## Context Loading

**READ (automatic):**
- `docs/brand/*.md` (existing brand guides)
- `schemas/brand-spec.schema.md` (frontmatter contract for brand specs)
- `.claude/agents/designer.md` (persona and judgment rules)

---

## Context Writing

**WRITE:**
- `docs/brand/{name}.md` (brand guide with YAML frontmatter + markdown narrative)
- `docs/brand/tokens.json` (W3C Design Tokens derived from brand guide)
- `docs/brand/assets/manifest.md` (asset catalog with provenance)
- `docs/brand/assets/*.png` (generated images from workshop)

---

## Mode Selection

When `/brand` is invoked, determine the mode:

1. **`--activate` flag present** → Mode 4: Activate
2. **`--evolve "reason"` flag present** → Mode 3: Evolve
3. **`--workshop` flag present** → Mode 1: New Brand Workshop (fresh start, even if existing guide found)
4. **No flags + existing brand guide found in `docs/brand/`** → Mode 2: Review & Affirm
5. **No flags + no existing brand guide** → Mode 1: New Brand Workshop

---

## Modes

### Mode 1: New Brand Workshop (`--workshop` or no existing guide)

When `--workshop` is provided, OR no flags are provided and no existing brand guide matches the input:

Run the **6-phase interactive design workshop**. Each phase builds on the previous.
Use AskUserQuestion between phases for user decisions.

**If `--workshop` is used and an existing guide exists:** Warn the user that this will create a new brand guide alongside the existing one, then proceed with the full workshop.

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
   - For each palette option, include TWO sections:

   **Section A — Individual Swatches:**
   - Show each color as a large swatch (minimum 100px tall rectangle)
   - Label each swatch with its role (Primary, Secondary, Accent, Background, Foreground) and hex value
   - Set the text color on each swatch to ensure readability (white text on dark colors, dark text on light colors)
   - Include the palette name and mood keywords as a heading above each option
   - Include semantic colors (success, warning, error, info) as a smaller row beneath

   **Section B — Color Combinations In Context (this is the critical part):**
   - A **hero banner** using primary as background with foreground text and an accent CTA button
   - A **card component** on the background color with a secondary border/header, foreground body text, and a primary action link
   - A **navigation bar** using secondary or primary as the background with foreground text and accent highlights for the active item
   - A **form section** with background color, foreground labels, primary-colored input focus borders, and an accent submit button
   - A **notification/alert strip** using each semantic color (success, warning, error, info) with appropriate text
   - Each mini-composition should be at least 200px wide so the color relationships are clearly visible

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
- If multiple font pairing options are offered, show each option as a separate labeled section

For EACH font pairing option, show these **real-world scenario blocks** so the user can see how the fonts work across different contexts:

1. **Marketing hero** — Large H1 heading (heading font, bold), a subtitle in H3, body copy paragraph, and a CTA button. This shows the font at its most expressive scale.
2. **Content/blog page** — H2 heading, two body paragraphs with a pull quote or blockquote between them. This shows readability at body size.
3. **App UI / dashboard** — A card with a small H3 title, metadata line (date, category), body snippet, and action links. This shows the font at compact/functional sizes.
4. **Form / input context** — Labels (heading font, small caps or semibold), placeholder text (body font, light), helper text below, and a submit button. This shows the font in utilitarian contexts.
5. **Code / technical** (if mono font included) — A code snippet block using the mono font alongside body text explanations. This shows how mono integrates with the other fonts.

Each scenario block should:
- Be labeled with the scenario name
- Show the font family, weight, and size used for each element as a subtle annotation
- Use the chosen brand colors (background, foreground, primary, accent) so the user sees fonts AND colors working together

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

**Iteration loop (MANDATORY):**

1. Present all three generated images to user
2. Use AskUserQuestion: "Which style direction?" with options for each style plus "Mix / refine"
3. Based on user feedback:
   - If user picks a style but wants refinement (e.g., "photography but warmer", "illustration but more playful") → generate a NEW image incorporating the feedback, show it, and ask again
   - If user wants to mix styles (e.g., "illustrated but with photographic textures") → generate a NEW image with the hybrid direction
   - If user is happy → lock in the style and move to Phase 5
4. **Keep iterating until the user explicitly approves.** There is no limit on rounds. Each round generates a new image with the adjusted prompt. Number the iterations in filenames: `style-photography-v2`, `style-photography-v3`, etc.

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

**Iteration loop (MANDATORY):**

After generating each target example:
1. Show the generated image to user
2. Ask: "Does this capture the brand? What would you change?"
3. If user wants adjustments → regenerate with updated prompt, show it, ask again. Number iterations: `target-hero-v2`, `target-hero-v3`, etc.
4. If user approves → save final version and move to next target (or Phase 6 if all targets are done)
5. User can also request `--pro` for any specific image to regenerate at premium quality

**Do NOT rush through target examples.** These define the visual standard for all future brand work. Iterate until each one feels right.

Save approved versions to `docs/brand/assets/` and log to `docs/brand/assets/manifest.md`.

Output: Target examples saved with provenance.

#### Phase 6: Consolidation

Write three brand guide artifacts:

##### 6a. Markdown Brand Guide (`docs/brand/{name}.md`)

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

##### 6b. HTML Brand Guide (`docs/brand/index.html`)

**Write a rich, self-contained HTML brand guide** that consolidates all workshop decisions into a polished, browsable document. This is the primary visual reference for the brand.

The HTML file MUST:
- Be **fully self-contained** (inline CSS, no external dependencies except Google Fonts CDN)
- Use the brand's own colors, fonts, and design language throughout
- Include CSS custom properties (`:root` variables) matching the brand's design tokens

**Required sections:**

1. **Fixed navigation** — Sticky top nav with scroll anchors to each section, brand name, and status badge (Draft/Active)
2. **Hero** — Brand name, tagline, and key visual concept. Reference any generated target images from Phase 5 via relative paths (`assets/target-*.png`)
3. **Story / Mission** — The brand narrative from Phase 1. Why this brand exists, what it stands for
4. **Design Principles** — 2-4 principles derived from workshop decisions. Each with a name, description, and a litmus test ("Does this feel like X? Or Y?")
5. **Color Palette** — Visual swatches for every color (primary, secondary, accent, semantic, dark mode). Each swatch shows: color block, name, hex value, role/usage. Include a "colors in context" section showing the palette applied to realistic UI patterns
6. **Typography** — Font pairings with live Google Fonts rendering. Show the type scale (h1-h6, body, caption) with actual sizes and weights. Include 2-3 real-world usage scenarios
7. **Imagery** — Style guidelines with references to generated assets from Phase 4-5. Describe the tiers (e.g., photography, illustration, abstract) with dos and don'ts
8. **Voice & Tone** — Writing guidelines from Phase 1. Include do/don't examples for different contexts (marketing, UI, notifications, error messages)
9. **Decision Log** — Key workshop decisions with rationale (why this palette over alternatives, why these fonts, etc.)
10. **Quick Reference** — Prompt guidance for generating brand-consistent content with AI tools

**Design quality standards:**
- Responsive layout (readable on mobile and desktop)
- Generous whitespace, clear visual hierarchy
- Section eyebrows (small labels above headings) for scannability
- Smooth scroll behavior
- The guide itself should exemplify the brand — it's the first proof that the system works

**Tell the user** to open: `open docs/brand/index.html`

##### 6c. Design Tokens (`docs/brand/tokens.json`)

Generate in W3C format.

##### 6d. Status Report

```
> Brand guide complete!
>
> Saved: docs/brand/{name}.md (structured reference)
> Saved: docs/brand/index.html (visual brand guide — open in browser)
> Saved: docs/brand/tokens.json (W3C design tokens)
> Saved: docs/brand/assets/manifest.md ({N} target examples)
>
> Open the visual guide: open docs/brand/index.html
> When ready to activate: /brand docs/brand/{name}.md --activate
```

### Mode 2: Review & Affirm (existing guide found, no flags)

When an existing brand guide is found in `docs/brand/` and no flags are provided:

Present the existing brand assets phase-by-phase for affirmation. The user confirms what's still right and flags what needs revision. Only flagged phases enter the workshop.

#### Review Phase 1: Identity Affirmation

1. **Read** the existing brand guide's identity section (name, mission, audience, personality, positioning)
2. **Present** the current identity as a summary
3. **Use AskUserQuestion:** "Is the brand identity still accurate?" with options:
   - "Yes, keep as-is"
   - "Needs updates"
4. If "Needs updates": Enter Phase 1 (Brand Identity) from Mode 1 workshop, pre-populated with current values

#### Review Phase 2: Color Affirmation

1. **Write** `docs/brand/assets/palette-review.html` showing the **current** color palette using the same Section A (swatches) + Section B (colors in context) format from Mode 1 Phase 2
2. **Tell the user** to open: `open docs/brand/assets/palette-review.html`
3. **Use AskUserQuestion:** "Are these colors still working?" with options:
   - "Yes, keep as-is"
   - "Needs refinement" (minor tweaks)
   - "Needs rethinking" (explore new palettes)
4. If "Needs refinement": Enter Phase 2 from Mode 1, starting from the current palette as a baseline
5. If "Needs rethinking": Enter Phase 2 from Mode 1 as a fresh exploration

#### Review Phase 3: Typography Affirmation

1. **Write** `docs/brand/assets/typography-review.html` showing the **current** font pairings using the same 5-scenario format from Mode 1 Phase 3
2. **Tell the user** to open: `open docs/brand/assets/typography-review.html`
3. **Use AskUserQuestion:** "Are the fonts still right?" with options:
   - "Yes, keep as-is"
   - "Needs refinement"
   - "Needs rethinking"
4. If refinement or rethinking: Enter Phase 3 from Mode 1, starting from current fonts or fresh

#### Review Phase 4: Imagery Affirmation

1. **Check** if target example images exist in `docs/brand/assets/` (from the manifest)
2. If images exist: **Show** them to the user and ask: "Does this imagery style still represent the brand?"
3. If no images exist: Note that and ask if imagery exploration is needed
4. **Use AskUserQuestion:** with options:
   - "Yes, keep as-is"
   - "Needs a new direction"
5. If "Needs a new direction": Enter Phase 4 (Imagery Style) + Phase 5 (Target Examples) from Mode 1

#### Review Phase 5: Consolidation

1. If ANY phase was flagged for revision:
   - **Update** the brand guide with revised sections
   - **Preserve** unchanged sections verbatim
   - Update frontmatter: `updated: {today}`
   - Regenerate `docs/brand/tokens.json` if visual values changed
   - Report what changed and what was affirmed
2. If ALL phases affirmed:
   - Report: "Brand guide reviewed and affirmed. No changes needed."
   - If status is `draft`, ask if user wants to activate it

---

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

### Mode 4: Activate (`--activate`)

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
| Phase 6: Consolidation | **HTML file** + Markdown + tokens (Write tool) | Rich visual brand guide, structured reference, design tokens |

**For Phases 2-3:** Always write an HTML file to `docs/brand/assets/` and tell the user to open it (`open docs/brand/assets/{file}.html`). HTML gives pixel-perfect color rendering and real font previews — better than any image generation for these use cases.

**For Phases 4-5:** Check if `mcp__imagegen__image_generate_gemini` is available:
- **If available:** Generate images. If a call fails, retry once, then fall back to prompt-only for that specific image.
- **If NOT available:** Output optimized prompts and suggest free tools. Tell the user: "Image generation is not configured. To enable it: `claude mcp add imagegen -- npx -y @fastmcp-me/imagegen-mcp`"

---

## Usage Examples

```
/brand
> Found existing brand guide: docs/brand/acme.md
> Starting brand review...
>
> === Review Phase 1: Identity ===
> Current: Acme — developer tools that just work
> Is the brand identity still accurate?
> ...

/brand --workshop
> Starting fresh brand workshop...
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
> No existing brand guide found.
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
