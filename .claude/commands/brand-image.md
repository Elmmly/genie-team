# /brand:image [prompt]

Generate a brand-consistent image using AI, with cost-tiered model routing and graceful degradation.

---

## Arguments

- `prompt` - Description of desired image (required)
- Optional flags:
  - `--pro` - Use Gemini 3 Pro (premium tier) instead of default Flash
  - `--brand [path]` - Explicit brand guide path (overrides auto-detect)
  - No flags - Use Gemini 2.5 Flash (default tier)

---

## Genie Invoked

**Designer** - Visual identity specialist combining:
- Brand strategy and visual consistency
- AI prompt engineering for Gemini image generation
- Cost-tiered model routing

**System prompt:** `genies/designer/DESIGNER_SYSTEM_PROMPT.md`

---

## Context Loading

**BRAND GUIDE LOADING:**
1. If `--brand [path]` is provided: Read that specific brand guide
2. If in workflow context: Check backlog frontmatter for `brand_ref`
3. Otherwise: Scan `docs/brand/*.md` for files with `type: brand-spec` in frontmatter
4. If multiple found: Prefer the one with `status: active`
5. If no brand guide found: **Guard Rail** (see below)

**READ (automatic):**
- `docs/brand/{name}.md` (brand guide YAML frontmatter — colors, typography, imagery)
- `schemas/brand-spec.schema.md` (for reference)
- `genies/designer/DESIGNER_SYSTEM_PROMPT.md` (persona)

---

## Guard Rail: No Brand Guide (AC-6a)

If no brand guide is found at `docs/brand/`:

```
> No brand guide found at docs/brand/.
> A brand guide helps ensure consistent, high-quality images.
>
> Would you like to:
>   1. Start the brand interview (/brand)
>   2. Generate without brand context (one-off, no consistency)
```

Use AskUserQuestion to present the two options. If user chooses option 2, proceed with the raw prompt only (no brand augmentation).

---

## Prompt Augmentation

When a brand guide is loaded, augment the user's prompt with brand context:

```
{user's original prompt}

Brand context (apply consistently):
- Style: {imagery.style}
- Mood: {imagery.mood | join(", ")}
- Color palette: primary {colors.primary}, secondary {colors.secondary}, accent {colors.accent}
- Preferred subjects: {imagery.subjects | join(", ")}
- Avoid: {imagery.avoid | join(", ")}
- Typography mood: {typography.headings.family} headings, {typography.body.family} body
- No text overlay unless explicitly requested.
```

The "No text overlay" default suppresses Gemini's tendency to hallucinate brand names (validated in spike T3/T6).

---

## Image Generation: Cost-Tiered Routing (AC-5)

### Model Selection

```
Is --pro flag set?
  YES → model: "gemini-3-pro-image-preview" (premium)
  NO  → model: "gemini-2.5-flash-image" (default)
```

### Generation Call

Use `mcp__imagegen__image_generate_gemini` with:
- `prompt`: The augmented prompt (brand context appended)
- `model`: Selected model per tier
- `filenameHint`: Descriptive filename based on prompt (e.g., "hero-landing-page")

---

## Graceful Degradation (AC-6)

### Detection

Check environment capabilities in order:

1. **Full mode:** `mcp__imagegen__image_generate_gemini` tool is available AND generation succeeds
   → Save image, log to manifest

2. **Basic mode:** MCP tool is available BUT generation fails (authentication error, missing API key)
   → Output the augmented prompt with:
   ```
   > Image generation failed (likely missing GOOGLE_API_KEY).
   > Here's your brand-augmented prompt — paste it into any image generator:
   >
   > [augmented prompt]
   >
   > To enable generation, set GOOGLE_API_KEY in your environment.
   ```

3. **Prompt-only mode:** No `mcp__imagegen__image_generate_gemini` tool available at all
   → Craft and output the augmented prompt:
   ```
   > No image generation MCP configured.
   > Here's your brand-augmented prompt optimized for image generation:
   >
   > [augmented prompt]
   >
   > Paste this into:
   >   - Gemini (gemini.google.com) — free, best results
   >   - ChatGPT (chatgpt.com) — free tier available
   >   - Ideogram (ideogram.ai) — free, good for text in images
   >
   > To enable direct generation, install the imagegen MCP:
   >   claude mcp add imagegen -- npx -y @fastmcp-me/imagegen-mcp
   ```

---

## Asset Logging

After successful generation, log the asset:

1. Ensure `docs/brand/assets/` directory exists
2. Save the generated image to `docs/brand/assets/{filename}.{ext}`
3. Append entry to `docs/brand/assets/manifest.md`:

```markdown
## Asset: {filename}.{ext}
- **Generated:** {YYYY-MM-DD}
- **Model:** {model} ({default|premium} tier)
- **Brand guide:** {brand guide path}
- **Prompt:** "{user's original prompt}"
- **Augmented:** colors ({primary}, {accent}), mood ({mood}), style ({style})
```

---

## Context Writing

**WRITE:**
- `docs/brand/assets/{filename}.{ext}` (generated image, on full mode)
- `docs/brand/assets/manifest.md` (append provenance entry, on full mode)

---

## Output

On success (full mode):
- Generated image displayed inline
- Asset saved to `docs/brand/assets/`
- Manifest entry appended with full provenance

On degradation (basic or prompt-only mode):
- Brand-augmented prompt output to console
- Instructions for using the prompt in free tools

---

## Usage Examples

```
/brand:image "hero image for landing page, modern team collaborating"
> Loading brand guide: docs/brand/acme.md
> Augmenting prompt with brand context...
> Generating via Gemini 2.5 Flash (default tier)...
>
> [image displayed]
>
> Saved: docs/brand/assets/hero-landing-page-001.png
> Logged to: docs/brand/assets/manifest.md

/brand:image "product screenshot for app store" --pro
> Loading brand guide: docs/brand/acme.md
> Augmenting prompt with brand context...
> Generating via Gemini 3 Pro (premium tier)...
>
> [image displayed]
>
> Saved: docs/brand/assets/product-screenshot-001.png
> Logged to: docs/brand/assets/manifest.md

/brand:image "social media banner" --brand docs/brand/secondary-brand.md
> Loading brand guide: docs/brand/secondary-brand.md
> ...
```

---

## Routing

After image generation:
- User can generate more images
- User can upgrade to `--pro` if Flash result needs higher quality
- If no brand guide: redirect to `/brand` for interview

---

## Notes

- Flash is always the default — Pro requires explicit `--pro`
- "No text overlay" is appended by default to prevent hallucinated brand names
- Image generation is best-effort — failures degrade to prompt output, never block
- Asset manifest is append-only — provides full provenance trail
- Guard rail prevents accidental generation without brand context

ARGUMENTS: $ARGUMENTS
