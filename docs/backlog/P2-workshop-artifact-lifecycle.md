---
spec_version: "1.0"
type: shaped-work
id: GT-32
title: "Workshop Artifact Lifecycle and Multi-Theme Schema Support"
status: designed
created: "2026-02-13"
appetite: medium
priority: P2
author: shaper
tags: [brand, workshop, schema, artifacts, designer]
spec_ref: docs/specs/genies/designer.md
adr_refs:
  - docs/decisions/ADR-002-designer-integration-commands-plus-skill.md
acceptance_criteria:
  - id: AC-1
    description: "brand-awareness /context:load reports workshop HTML artifacts count alongside brand guide and tokens status"
    status: pending
  - id: AC-2
    description: "brand-awareness /context:refresh flags workshop HTML files older than the brand guide as potentially stale"
    status: pending
  - id: AC-3
    description: "brand-awareness /deliver surfaces workshop HTML artifact paths as visual references when they exist"
    status: pending
  - id: AC-4
    description: "brand-spec schema supports per-theme color objects under visual.colors.themes with each theme having accent/signature fields"
    status: pending
  - id: AC-5
    description: "brand-spec schema remains backward compatible — brand guides without visual.colors.themes validate unchanged"
    status: pending
  - id: AC-6
    description: "/brand:tokens extracts per-theme tokens when visual.colors.themes is present"
    status: pending
  - id: AC-7
    description: "Designer brand guide template includes visual.colors.themes structure for multi-theme projects"
    status: pending
---

# Shaped Work Contract: Workshop Artifact Lifecycle and Multi-Theme Schema

## Problem

Two related gaps in the Designer workflow compound to cause visual intent loss:

**1. Workshop HTML artifacts are invisible after creation.** The `/brand` workshop generates 5+ HTML preview files (palette options, typography samples, imagery moodboard) to `docs/brand/assets/`. These files show complete themed compositions — accent colors, signature elements, decorative treatments — that are visible in the HTML but never transcribed to the brand guide YAML. After the workshop session ends, no command surfaces these artifacts. `/context:load` reports brand guide status and token count but not workshop HTMLs. Subsequent implementation sessions have no way to discover they exist.

**2. The brand spec schema can't express per-theme accent colors.** The schema defines a single color set (`primary`, `secondary`, `accent`, `background`, `foreground`, `semantic`, `palette`). For multi-theme applications, the workshop produces per-theme color maps (background, card, elevated, input, border, text) but these have no accent/signature fields per theme. The schema's global `accent` field captures one color; per-theme accents have nowhere to live.

Combined effect: the workshop shows rich visual compositions per theme, the YAML captures surface colors but not signature elements, workshop HTML artifacts showing the full visual intent become invisible, and implementation sessions consume only the YAML.

**Evidence:** Field report — accent colors visible in workshop HTML compositions (teal labels, gold highlights, ember orange decoratives) were never transcribed to YAML. 2 follow-up fix contracts resulted.

## Appetite & Boundaries

- **Appetite:** Medium (3-5 days)
- **In scope:** Extending brand-awareness skill to surface workshop HTML artifacts. Extending brand-spec schema with optional per-theme color structure including accent/signature fields. Updating Designer template and `/brand:tokens` for multi-theme support.
- **No-gos:** No automatic HTML regeneration when brand values change (workshop HTMLs are snapshots, not living documents). No visual diffing or screenshot comparison tooling. No breaking changes to existing brand guides.
- **Fixed elements:** Brand-awareness loading pattern (check brand_ref → scan docs/brand/ → silently skip if missing) is unchanged. Workshop HTML files remain optional session artifacts.

## Goals & Outcomes

- Implementation sessions can discover and reference workshop visual artifacts
- Brand guides for multi-theme apps capture accent/signature colors per theme
- Token extraction produces per-theme tokens including accents
- Staleness of workshop artifacts is surfaced (not fixed — just flagged)

## Behavioral Delta

**Spec:** docs/specs/genies/designer.md

### Current Behavior
- AC-9: "brand-awareness skill activates during /design, /deliver, /discern to inject brand context via brand_ref" — injects hex values and font families from YAML only; workshop HTML artifacts are not surfaced
- AC-3: "Designer outputs Design Tokens at docs/brand/tokens.json in W3C Design Tokens format" — single color set, no per-theme structure

### Proposed Changes
- AC-9 extended: brand-awareness also surfaces workshop HTML artifact paths during /deliver and /discern as visual references; reports their existence during /context:load; flags staleness during /context:refresh
- AC-3 extended: tokens include per-theme color sets (including accent/signature) when `visual.colors.themes` is present in the brand guide
- AC-NEW: brand-spec schema supports optional `visual.colors.themes` object with per-theme color definitions including accent/signature fields

### Rationale
Workshop artifacts contain visual intent not captured in YAML. Making them discoverable prevents the translation gap that caused follow-up fixes. Per-theme schema support addresses the root cause — the YAML can capture what the workshop showed.

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Multi-theme apps are common enough to warrant schema support | value | The field report is one data point; check if other mobile/web apps typically need multi-theme |
| Workshop HTML staleness flagging is useful (vs. confusing) | usability | If HTML shows old values, is it better to flag "stale" or just not surface them? |
| Per-theme schema can be backward compatible | feasibility | Existing brand guides have no `visual.colors.themes` — test that validation still passes |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Extend existing schema with optional `themes` + surface workshop artifacts | Backward compatible, additive, addresses both gaps | Schema grows more complex | Recommended |
| B: Schema only (no workshop artifact surfacing) | Simpler | Doesn't address the visibility gap — workshop artifacts remain invisible | Partial fix |
| C: Workshop artifacts only (no schema change) | Simpler | Doesn't address the root cause — YAML still can't express per-theme accents | Partial fix |

## Routing

- [x] **Ready for design** — Schema evolution is additive; brand-awareness changes are prompt engineering
- [ ] Needs Architect spike

**Next:** `/deliver docs/backlog/P2-workshop-artifact-lifecycle.md`

---

# Design

## Overview

Two complementary changes: (1) make workshop HTML artifacts visible to the brand-awareness skill so they're surfaced during context loading, delivery, and drift detection; (2) extend the brand-spec schema with an optional per-theme color structure that includes accent/signature fields. Both changes are backward compatible.

## Architecture

**Workshop artifact visibility** follows the existing brand-awareness pattern — add HTML file detection alongside the existing brand guide and tokens detection. No new loading pattern, just extending the existing one.

**Multi-theme schema** uses an optional `themes` object under `visual.colors` that maps theme names to color sets. Each theme color set includes all surface colors plus `accent` and `signature` fields. The existing top-level color fields (`primary`, `secondary`, `accent`, etc.) remain the single-theme default.

## Component Design

### 1. Brand-spec schema — `schemas/brand-spec.schema.md`

**Add to Colors Object section, after `palette`:**

```markdown
| `themes` | object | Per-theme color definitions (optional, for multi-theme apps) |

### Themes Object

Maps theme names to per-theme color sets. Use when the brand has multiple named themes (e.g., dark, light, warm, cool).

| Field | Type | Description |
|-------|------|-------------|
| `{theme-name}` | object | Theme color set (see Theme Color Set below) |

### Theme Color Set

Each theme contains:

| Field | Type | Description |
|-------|------|-------------|
| `background` | string (hex) | Theme background color |
| `surface` | string (hex) | Card/elevated surface color |
| `text_primary` | string (hex) | Primary text color |
| `text_secondary` | string (hex) | Secondary text color |
| `border` | string (hex) | Border/divider color |
| `accent` | string (hex) | Theme-specific accent color |
| `signature` | string (hex) | Signature/decorative color unique to this theme |
| `input` | string (hex) | Input field background (optional) |
| `elevated` | string (hex) | Elevated surface color (optional) |
```

**Add to Validation section:**

```markdown
7. If `visual.colors.themes` is present: each theme must have at least `background`, `text_primary`, and `accent`
8. `visual.colors.themes` is optional — brand guides without it validate unchanged
```

**Add to Complete Example** — extend the example with a `themes` section after `palette`:

```yaml
    themes:
      light:
        background: "#FFFFFF"
        surface: "#F8FAFC"
        text_primary: "#1F2937"
        text_secondary: "#6B7280"
        border: "#E5E7EB"
        accent: "#2563EB"
        signature: "#F59E0B"
      dark:
        background: "#111827"
        surface: "#1F2937"
        text_primary: "#F9FAFB"
        text_secondary: "#9CA3AF"
        border: "#374151"
        accent: "#60A5FA"
        signature: "#FBBF24"
```

### 2. Designer agent template — `agents/designer.md`

**Extend the Brand Guide Template (L85-131)** to include the optional themes structure:

After the existing `palette` line in the template, add a commented-out themes section:

```yaml
    # Per-theme colors (for multi-theme apps — remove if single-theme):
    # themes:
    #   {theme-name}:
    #     background: "{hex}"
    #     surface: "{hex}"
    #     text_primary: "{hex}"
    #     text_secondary: "{hex}"
    #     border: "{hex}"
    #     accent: "{hex}"
    #     signature: "{hex}"
```

The Designer should include `themes` when the workshop produces multiple themed compositions, and omit it for single-theme brands.

### 3. Brand-awareness skill — `SKILL.md`

**Modify: "During /context:load" section (L208-221)**

Extend step 2 to report workshop artifacts:

```markdown
   > Workshop artifacts: {count} HTML files in docs/brand/assets/ ({filenames})
```

(This overlaps with GT-30 AC-3 — if GT-30 delivers first, this is already done.)

**Modify: "During /deliver" section (L164-183)**

Append after existing token surfacing:

```markdown
4. If `docs/brand/assets/*.html` files exist:
   - List workshop artifact filenames as visual references
   - Note: "These are workshop snapshots — verify they reflect current brand values"
5. If brand guide has `visual.colors.themes`:
   - Surface per-theme color sets including accent and signature values
   - Reference: "Theme-specific tokens available — use accent/signature values per theme, not just global primary/secondary"
```

**Modify: "/brand:tokens extraction" section (L125-139)**

Extend step 3:

```markdown
   - If `visual.colors.themes` present:
     - `visual.colors.themes.{name}.accent` → `brand.color.theme.{name}.accent`
     - `visual.colors.themes.{name}.signature` → `brand.color.theme.{name}.signature`
     - `visual.colors.themes.{name}.background` → `brand.color.theme.{name}.background`
     - (... all theme color set fields)
```

**Modify: "During /context:refresh" section (L223-237)**

Extend to detect workshop HTML staleness:

```markdown
   e. Glob `docs/brand/assets/*.html` — if any exist and are older than brand guide `updated` date:
      > Workshop artifacts may be stale: {filenames} pre-date latest brand guide update.
```

(This overlaps with GT-30 AC-4 — if GT-30 delivers first, this is already done.)

### 4. Brand directory structure docs — `SKILL.md` L29-37

**Update directory structure** to acknowledge HTML workshop artifacts:

```markdown
docs/brand/
  {brand-name}.md              # Brand Guide (YAML frontmatter + design narrative)
  tokens.json                  # W3C Design Tokens (derived from brand guide)
  assets/                      # Generated images + workshop artifacts
    manifest.md                # Asset catalog with provenance
    *.png / *.jpg              # Generated image files
    *.html                     # Workshop preview artifacts (palette, typography, moodboard)
```

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | /context:load reports HTML file count + names | `.claude/skills/brand-awareness/SKILL.md` |
| AC-2 | /context:refresh compares HTML timestamps to brand guide `updated` | `.claude/skills/brand-awareness/SKILL.md` |
| AC-3 | /deliver lists HTML files as visual references with staleness caveat | `.claude/skills/brand-awareness/SKILL.md` |
| AC-4 | `visual.colors.themes` object with per-theme `accent` and `signature` fields | `schemas/brand-spec.schema.md` |
| AC-5 | `themes` is optional; validation skips it when absent | `schemas/brand-spec.schema.md` |
| AC-6 | /brand:tokens extracts `theme.{name}.accent`, `theme.{name}.signature` etc. | `.claude/skills/brand-awareness/SKILL.md` |
| AC-7 | Designer template includes commented-out themes structure | `agents/designer.md` |

## Implementation Guidance

**Sequence:**
1. `schemas/brand-spec.schema.md` — add themes object, validation rules, example
2. `agents/designer.md` — add themes to brand guide template
3. `.claude/skills/brand-awareness/SKILL.md` — extend /context:load, /deliver, /context:refresh, /brand:tokens
4. Update directory structure docs in SKILL.md

**Note on GT-30 overlap:** AC-1, AC-2, AC-3 of this contract partially overlap with GT-30 (transition guidance). If GT-30 delivers first, those changes may already exist. Check before editing — avoid duplicating guidance text. The non-overlapping parts are AC-4-AC-7 (schema + tokens + Designer template).

**Test strategy:**
- Validate existing brand guides (no `themes`) pass schema validation unchanged
- Create brand guide with `themes.light` and `themes.dark` → validate passes
- Create brand guide with `themes.light` missing `accent` → validate fails
- Run `/brand:tokens` on multi-theme brand guide → verify per-theme tokens generated
- Run `/context:load` on project with workshop HTML files → verify count reported

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Multi-theme schema is niche | Med | Low | Entirely optional; single-theme brands are unchanged. Schema only adds complexity when `themes` is present. |
| Workshop HTML staleness warnings are confusing | Low | Low | Warning text explains what "stale" means and that visual references may not reflect current values. |
| Per-theme token extraction naming conflicts with existing tokens | Low | Med | Theme tokens are namespaced: `brand.color.theme.{name}.*` — no collision with `brand.color.primary` |

## Routing

Ready for Crafter. Schema evolution is additive. GT-30 overlap handled by checking before editing.
