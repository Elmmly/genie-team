---
name: brand-awareness
description: Ensures brand-consistent behavior during workflows. Auto-activates when brand guide exists and "brand", "brand spec", "design tokens", "brand consistent", or "visual identity" are mentioned. Activates during /brand, /brand:image, /brand:tokens, /design, /deliver, /discern, /handoff, /context:load, and /context:refresh.
allowed-tools: Read, Glob, Grep
---

# Brand Awareness

Brand knowledge lives in the **Brand Guide** — the third pillar of persistent project knowledge:

```
     SPEC (WHAT)          BRAND (HOW IT LOOKS)
    /           \        /
   /             \      /
ADR (HOW+WHY) -- C4 (CONTEXT MAP)
```

- **Specs** describe WHAT the system does (capabilities, acceptance criteria)
- **ADRs** describe HOW the system is built and WHY those technical choices were made
- **Brand Guides** describe HOW IT LOOKS — visual identity, colors, typography, imagery

All three are persistent, first-class artifacts. Backlog items are transient; these are not.

## Brand Guide Organization

Brand Guides capture visual identity using YAML frontmatter (machine-readable) and markdown narrative (human-readable).

### Directory Structure

```
docs/brand/
  {brand-name}.md              # Brand Guide (YAML frontmatter + design narrative)
  tokens.json                  # W3C Design Tokens (derived from brand guide)
  assets/                      # Generated images
    manifest.md                # Asset catalog with provenance
    *.png / *.jpg              # Generated files
```

### Frontmatter Schema

> Schema: `schemas/brand-spec.schema.md` v1.0

Required: `spec_version`, `type: brand-spec`, `brand_name`, `status`, `created`, `identity`, `visual`
Optional: `updated`, `author`, `target_project`, `tags`, `extends`

### Brand Guide Lifecycle

```
/brand (create) → draft → /brand --activate → active → deprecated
                              ↑
                    /brand --evolve (update)
```

- **draft** — Created by `/brand` workshop, pending user review
- **active** — Promoted by `--activate`, the source of truth for how the product looks
- **deprecated** — Superseded by a newer brand guide

## When Active

This skill activates during:
- `/brand` — Create or evolve brand guide via interactive workshop
- `/brand:image` — Generate brand-consistent images
- `/brand:tokens` — Extract W3C Design Tokens from brand guide
- `/design` — Inject brand constraints as Architect context
- `/deliver` — Surface design tokens for Crafter theming
- `/discern` — Add Brand Compliance to Critic review checklist
- `/handoff` — Inject brand-specific transition guidance into handoff output
- `/context:load` — Report brand guide status
- `/context:refresh` — Detect brand guide / tokens drift

## Behaviors

### Common: Brand Guide Loading Pattern

All commands that read brand guides follow this pattern:

1. Check for `brand_ref` in the backlog item frontmatter
2. If `brand_ref` is present: Read the referenced brand guide file from `docs/brand/`
3. If `brand_ref` is missing: Scan `docs/brand/*.md` for any file with `type: brand-spec` in frontmatter
4. If multiple brand guides found: Use the one with `status: active` (prefer active over draft)
5. If no brand guide found: **Silently continue** (no warning, no overhead)
6. **Never block** — brand is valuable but optional

**Key difference from spec-awareness:** Step 5 does NOT warn when no brand guide is found. Brand is fully opt-in — there is no expectation that every project has one.

### During /brand (AC-3, AC-10)

Creates or evolves brand guides via the 6-phase interactive workshop:

1. Load existing brand guides via common pattern
2. If `--activate`: Change `status: draft` → `status: active` in frontmatter, done
3. If `--evolve "reason"`: Load existing brand guide, re-enter relevant workshop phases
4. If no flags: Start new brand workshop (Identity → Colors → Typography → Imagery → Target Examples → Consolidation)
5. Workshop uses `mcp__imagegen__image_generate_gemini` with `model: "gemini-2.5-flash-image"` for visual exploration
6. Write brand guide to `docs/brand/{name}.md` with `status: draft`
7. Generate tokens to `docs/brand/tokens.json`
8. Log generated assets to `docs/brand/assets/manifest.md`

**Reads:** `docs/brand/*.md`, `schemas/brand-spec.schema.md`
**Writes:** `docs/brand/{name}.md`, `docs/brand/tokens.json`, `docs/brand/assets/`

### During /brand:image (AC-5, AC-6, AC-6a)

Generates brand-consistent images with cost-tiered routing:

1. Load brand guide via common pattern
2. If no brand guide found: **Guard rail** — ask user:
   > No brand guide found at docs/brand/.
   > Would you like to:
   >   1. Start the brand interview (/brand)
   >   2. Generate without brand context (one-off)
3. If brand guide found: Augment user prompt with brand context (colors, mood, style, subjects, avoid)
4. Add "No text overlay unless explicitly requested" to prevent hallucinated brand names
5. Detect MCP availability:
   - Full (MCP + key): Generate via `mcp__imagegen__image_generate_gemini`
     - Default: `model: "gemini-2.5-flash-image"`
     - On `--pro`: `model: "gemini-3-pro-image-preview"`
   - Basic (MCP, no key): Output augmented prompt with warning
   - Prompt-only (no MCP): Craft optimized prompt, suggest free tools
6. Save generated image to `docs/brand/assets/`
7. Append provenance entry to `docs/brand/assets/manifest.md`

**Reads:** `docs/brand/*.md`, backlog `brand_ref`
**Writes:** `docs/brand/assets/*.png`, `docs/brand/assets/manifest.md`

### During /brand:tokens (AC-4)

Extracts W3C Design Tokens from brand guide:

1. Load brand guide via common pattern (or use explicit path argument)
2. Read YAML frontmatter `visual` object
3. Transform to W3C Design Tokens format:
   - `visual.colors.*` → `brand.color.*` tokens
   - `visual.typography.*` → `brand.typography.*` tokens
   - `visual.colors.semantic.*` → `brand.semantic.*` tokens
   - Extended `visual.colors.palette[]` → `brand.color.{name}` tokens
4. Write to `docs/brand/tokens.json`

**Reads:** `docs/brand/{name}.md` (YAML frontmatter only)
**Writes:** `docs/brand/tokens.json`

### During /design (AC-7)

Injects brand constraints as Architect context:

1. Load brand guide via common pattern
2. If brand guide found: Surface brand constraints for Architect:
   - Color palette and semantic colors → design constraint for UI components
   - Typography hierarchy → font stack constraints
   - Imagery style → asset generation guidelines
   - Design tokens path → implementation reference
3. Present as "Brand Context" section in Architect's input:
   ```
   ## Brand Context (from docs/brand/{name}.md)
   - Colors: primary {primary}, secondary {secondary}, accent {accent}
   - Typography: {headings.family} / {body.family} / {mono.family}
   - Imagery: {style}, mood: {mood}
   - Tokens: docs/brand/tokens.json
   ```
4. If no brand guide: Silently continue (no warning)

**Reads:** `docs/brand/*.md`, `docs/brand/tokens.json`
**Writes:** Nothing (read-only — context injection only)

### During /deliver (AC-7)

Surfaces design tokens for Crafter theming:

1. Load brand guide via common pattern
2. If brand guide found: Surface design tokens for implementation:
   - Color values from `docs/brand/tokens.json` for CSS/theme variables
   - Font families for typography implementation
   - Imagery guidelines for any asset-related code
3. Reference token values in implementation context:
   ```
   ## Brand Tokens Available
   Use these values from docs/brand/tokens.json:
   - Primary: {colors.primary}
   - Font stack: {typography.heading-family}, {typography.body-family}
   ```
4. If no brand guide: Silently continue (no warning)
5. **Transition guidance** (conditional):
   a. If `docs/brand/assets/manifest.md` has entries:
      > **Brand assets available:** Generated brand images exist in docs/brand/assets/ — review the manifest for visual references (color palettes, signature elements, mood boards) that capture intent beyond what the YAML brand guide encodes.
   b. If brand guide has `status: active` and work touches CSS/theme/style files:
      > **Visual verification recommended:** This work affects visual appearance. Before marking complete, verify the rendered UI matches the brand guide's visual intent (not just hex values).

**Reads:** `docs/brand/*.md`, `docs/brand/tokens.json`
**Writes:** Nothing (read-only — context surface only)

### During /discern (AC-7)

Adds Brand Compliance to Critic review:

1. Load brand guide via common pattern
2. If brand guide found: Add **Brand Compliance** section to review checklist:
   - Do implemented colors match brand spec values?
   - Does typography use the specified font families?
   - Do generated or referenced images follow imagery style guidelines?
   - Are design token values used (not hardcoded alternatives)?
3. Output Brand Compliance table:
   ```
   | Aspect | Brand Spec | Implementation | Compliant? |
   |--------|-----------|----------------|------------|
   | Primary color | #2563EB | #2563EB | YES |
   | Heading font | Inter | Arial | NO — should use Inter |
   | Imagery style | Photography | Stock illustration | NO — brand specifies photography |
   ```
4. If no brand guide: Silently continue (no Brand Compliance section)
5. **Transition guidance** (conditional):
   a. If work touched CSS/theme/style files:
      > **Visual evidence:** This review covers brand-related visual changes. Consider requesting a screenshot or dev server inspection to verify rendered appearance matches brand intent — hex-value compliance alone may miss visual issues.

**Reads:** `docs/brand/*.md`, `docs/brand/tokens.json`, implementation files
**Writes:** Nothing (compliance output goes in review document, not in brand guide)

### During /context:load

Reports brand guide status:

1. Scan `docs/brand/*.md` for files with `type: brand-spec` in frontmatter
2. If found: Report status:
   > Brand guide found: docs/brand/{name}.md (status: {status})
   > Design tokens: docs/brand/tokens.json ({exists|missing})
   > Assets: {count} entries in docs/brand/assets/manifest.md
3. If not found: Report:
   > No brand guide found. Use /brand to create one.

**Reads:** `docs/brand/*.md`, `docs/brand/tokens.json`, `docs/brand/assets/manifest.md`
**Writes:** Nothing (read-only)

### During /context:refresh

Detects brand guide / tokens drift:

1. Load brand guide via common pattern
2. If brand guide found:
   a. Check if `docs/brand/tokens.json` exists
   b. If tokens exist: Compare brand guide `updated` date vs tokens file modification date
   c. If brand guide is newer than tokens: Flag drift:
      > Brand guide updated more recently than tokens.json. Run /brand:tokens to sync.
   d. Scan `docs/brand/assets/manifest.md` for references to deprecated brand guide versions
   e. Read `docs/brand/assets/manifest.md` for entry dates
   f. If any manifest entries have dates older than the brand guide `updated` field:
      > Brand asset images may be stale (generated before latest brand guide update). Visual references in these images may not reflect current brand values. Regenerate with /brand:image if needed.
3. If no brand guide: Silently continue

**Reads:** `docs/brand/*.md`, `docs/brand/tokens.json`
**Writes:** Nothing (drift is reported, user fixes it)

### During /handoff

Injects brand-specific transition guidance into handoff output:

1. Load brand guide via common pattern
2. If brand guide found:
   a. For `design → deliver` handoff:
      > **Brand context for Crafter:** Brand guide active at docs/brand/{name}.md. Design tokens at docs/brand/tokens.json. {If manifest has entries: "Review docs/brand/assets/manifest.md for visual reference images."}
   b. For `deliver → discern` handoff:
      > **Brand context for Critic:** {If work touched CSS/theme/style files: "Visual changes present — verify rendered appearance, not just token compliance."}
3. If no brand guide: Silently continue (no guidance injected)

**Reads:** `docs/brand/*.md`, `docs/brand/tokens.json`, `docs/brand/assets/manifest.md`
**Writes:** Nothing (read-only — guidance injection only)

## Brand Update Rules (All Commands)

These rules apply to ALL commands that interact with brand artifacts:

1. **Silently skip, never block** — Missing brand guide is silent, not a warning. Brand is fully opt-in.
2. **Never archive brand guides** — They persist as project knowledge, same as specs and ADRs
3. **Prefer active over draft** — When multiple brand guides exist, use the one with `status: active`
4. **brand_ref takes precedence** — If backlog has `brand_ref`, use that specific guide over auto-detection
5. **Tokens are derived** — `tokens.json` is always derived from brand guide; regenerated via `/brand:tokens`
6. **Assets have provenance** — Every generated image gets a manifest entry with prompt, model, and date

## What This Skill Does NOT Do

- Does NOT block any workflow — silently continues when no brand guide exists
- Does NOT warn when brand guide is missing — brand is opt-in (unlike specs which are expected)
- Does NOT auto-generate tokens on brand guide changes — tokens regeneration is explicit via `/brand:tokens`
- Does NOT auto-detect imagery style for model selection — `--pro` is always explicit
- Does NOT write to brand guides during /design, /deliver, or /discern — those commands only read brand context
- Does NOT replace the Designer genie — this skill provides cross-cutting context; the genie creates and manages brand guides
- Does NOT validate brand guide schema — that is `/brand` command's responsibility during creation
