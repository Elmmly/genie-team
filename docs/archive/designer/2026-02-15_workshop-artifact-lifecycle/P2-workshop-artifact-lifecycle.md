---
spec_version: "1.0"
type: shaped-work
id: GT-32
title: "Workshop Artifact Lifecycle and Multi-Theme Schema Support"
status: wontfix
created: "2026-02-13"
appetite: medium
priority: P2
author: shaper
tags: [brand, workshop, schema, artifacts, designer]
spec_ref: docs/specs/genies/designer.md
adr_refs:
  - docs/decisions/ADR-002-designer-integration-commands-plus-skill.md
refs: ["github#2"]
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

# Design (Revision 2 — 2026-02-15)

## Revision Summary

Revision 2 updates the design after GT-30 (context-aware transition guidance) delivered and GT-31 (lightweight contract variants) was dropped.

**GT-30 delivered these changes** now present in brand-awareness SKILL.md:
- `/context:load` (L225): Reports manifest entry count (`Assets: {count} entries in docs/brand/assets/manifest.md`)
- `/context:refresh` (L243-245): Steps 2e-2f compare manifest entry dates vs brand guide `updated` field
- `/deliver` (L182-186): Step 5a surfaces manifest entries, step 5b recommends visual verification
- `/handoff` (L251-264): Brand-specific transition guidance

**What GT-30 did NOT deliver** (GT-32's remaining scope):
- HTML workshop artifact detection (GT-30 checks manifest entries, not HTML files)
- Per-theme schema fields (entirely new)
- Per-theme token extraction (entirely new)
- Designer template update (entirely new)

The design below specifies only the changes that remain. All line references are against the current codebase.

## Overview

Two complementary changes: (1) add HTML workshop artifact detection to brand-awareness alongside the existing manifest-based detection from GT-30; (2) extend the brand-spec schema with an optional per-theme color structure including accent/signature fields. Both changes are backward compatible and additive to GT-30's work.

## Architecture

**Workshop artifact visibility** adds HTML-specific detection alongside GT-30's manifest-based detection. GT-30 surfaces manifest entry counts and dates. GT-32 adds: HTML file count during context loading, HTML file listing during delivery, and HTML staleness detection during refresh. These are distinct from manifest entries — HTML workshop artifacts are visual compositions from the `/brand` workshop that may not appear in the manifest (which tracks `/brand:image` generations).

**HTML staleness mechanism:** Workshop HTML artifacts don't have inline date metadata and the skill's allowed tools (Read, Glob, Grep) can't check filesystem timestamps. Staleness is detected by a heuristic: if the brand guide has an `updated` field different from `created`, it has been evolved since the workshop that generated the HTMLs. Flag the HTMLs as potentially stale.

**Multi-theme schema** uses an optional `themes` object under `visual.colors` that maps theme names to color sets. Each theme color set includes surface colors plus `accent` and `signature` fields. The existing top-level color fields remain the single-theme default. `themes` is purely additive — absent means single-theme (backward compatible).

## Component Design

### 1. Brand-spec schema — `schemas/brand-spec.schema.md`

**Modify: Colors Object table (L81-89)**

Add row after `palette`:

```markdown
| `themes` | object | Per-theme color definitions (optional, for multi-theme apps) |
```

**Add: New subsections after Colors Object table (after L89)**

```markdown
### Themes Object

Maps theme names to per-theme color sets. Use when the brand has multiple named themes (e.g., dark, light, warm, cool).

| Field | Type | Description |
|-------|------|-------------|
| `{theme-name}` | object | Theme color set (see Theme Color Set below) |

### Theme Color Set

Each theme contains:

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `background` | string (hex) | yes | Theme background color |
| `surface` | string (hex) | no | Card/elevated surface color |
| `text_primary` | string (hex) | yes | Primary text color |
| `text_secondary` | string (hex) | no | Secondary text color |
| `border` | string (hex) | no | Border/divider color |
| `accent` | string (hex) | yes | Theme-specific accent color |
| `signature` | string (hex) | no | Signature/decorative color unique to this theme |
| `input` | string (hex) | no | Input field background |
| `elevated` | string (hex) | no | Elevated surface color |
```

**Modify: Validation section (L234-243)**

Append:

```markdown
7. If `visual.colors.themes` is present: each theme must have at least `background`, `text_primary`, and `accent`
8. `visual.colors.themes` is optional — brand guides without it validate unchanged
```

**Modify: Complete Example (L128-210)**

Insert after `palette` entries (after L173) and before the `typography` section:

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

**Modify: Brand Guide Template (L85-131)**

After the existing `avoid` line (L129) and before the closing `---`, add:

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

**Add guidance** after the template (after L131): When the workshop produces multiple themed compositions (e.g., dark and light variants), uncomment and populate `themes`. For single-theme brands, omit it entirely.

### 3. Brand-awareness skill — `skills/brand-awareness/SKILL.md`

All changes below are additive to the current file (post-GT-30).

**Modify: Directory structure (L29-37)**

Replace:

```markdown
  assets/                      # Generated images
    manifest.md                # Asset catalog with provenance
    *.png / *.jpg              # Generated files
```

With:

```markdown
  assets/                      # Generated images + workshop artifacts
    manifest.md                # Asset catalog with provenance
    *.png / *.jpg              # Generated image files
    *.html                     # Workshop preview artifacts (palette, typography, moodboard)
```

**Modify: "During /brand:tokens" section (L126-141)**

Extend step 3 (L132-136). After the existing palette mapping line (L136), append:

```markdown
   - If `visual.colors.themes` present:
     - `visual.colors.themes.{name}.background` → `brand.color.theme.{name}.background`
     - `visual.colors.themes.{name}.surface` → `brand.color.theme.{name}.surface`
     - `visual.colors.themes.{name}.text_primary` → `brand.color.theme.{name}.text-primary`
     - `visual.colors.themes.{name}.text_secondary` → `brand.color.theme.{name}.text-secondary`
     - `visual.colors.themes.{name}.border` → `brand.color.theme.{name}.border`
     - `visual.colors.themes.{name}.accent` → `brand.color.theme.{name}.accent`
     - `visual.colors.themes.{name}.signature` → `brand.color.theme.{name}.signature`
     - (include `input`, `elevated` if present)
```

**Modify: "During /deliver" section (L165-189)**

Insert new step after step 3 (L175-180), before step 4 (L181):

```markdown
3a. If `docs/brand/assets/*.html` files exist:
   - List HTML filenames as workshop visual references
   > **Workshop references available:** {filenames} in docs/brand/assets/ — these are visual compositions from the brand workshop showing intended appearance including accent colors, signature elements, and themed previews.
3b. If brand guide has `visual.colors.themes`:
   - Surface per-theme accent and signature values alongside global tokens
   > **Per-theme tokens:** Theme-specific accent/signature colors available in `visual.colors.themes`. Use per-theme values for themed components, not just global primary/secondary.
```

**Modify: "During /context:load" section (L217-230)**

After the existing manifest line in the step 2 output (L225), append:

```markdown
   > Workshop artifacts: {count} HTML files in docs/brand/assets/
```

This is a Glob for `docs/brand/assets/*.html`. If count is 0, omit the line.

**Modify: "During /context:refresh" section (L232-249)**

After existing step 2f (L245), append:

```markdown
   g. Glob `docs/brand/assets/*.html`
   h. If HTML files found and brand guide `updated` field differs from `created` (meaning the guide was evolved after the workshop):
      > Workshop HTML artifacts may be stale — created during original brand workshop, but brand guide has been updated since. Visual compositions may not reflect current brand values. Regenerate with /brand --evolve if needed.
```

### 4. `/brand:tokens` command — `commands/brand-tokens.md`

**Modify: Mapping table (L42-60)**

Append after the `scale` row (L60):

```markdown
| `visual.colors.themes.{name}.background` | `brand.color.theme.{name}.background` | `color` |
| `visual.colors.themes.{name}.surface` | `brand.color.theme.{name}.surface` | `color` |
| `visual.colors.themes.{name}.text_primary` | `brand.color.theme.{name}.text-primary` | `color` |
| `visual.colors.themes.{name}.text_secondary` | `brand.color.theme.{name}.text-secondary` | `color` |
| `visual.colors.themes.{name}.border` | `brand.color.theme.{name}.border` | `color` |
| `visual.colors.themes.{name}.accent` | `brand.color.theme.{name}.accent` | `color` |
| `visual.colors.themes.{name}.signature` | `brand.color.theme.{name}.signature` | `color` |
| `visual.colors.themes.{name}.input` | `brand.color.theme.{name}.input` | `color` |
| `visual.colors.themes.{name}.elevated` | `brand.color.theme.{name}.elevated` | `color` |
```

**Modify: Output Format example (L64-92)**

Extend the JSON example to show per-theme tokens:

```json
    "theme": {
      "light": {
        "background": { "$type": "color", "$value": "#FFFFFF" },
        "accent": { "$type": "color", "$value": "#2563EB" },
        "signature": { "$type": "color", "$value": "#F59E0B" }
      },
      "dark": {
        "background": { "$type": "color", "$value": "#111827" },
        "accent": { "$type": "color", "$value": "#60A5FA" },
        "signature": { "$type": "color", "$value": "#FBBF24" }
      }
    }
```

**Modify: Notes section (L151-158)**

Append:

```markdown
- Per-theme tokens are namespaced under `brand.color.theme.{name}.*` — no collision with global color tokens
- Theme tokens are only generated when `visual.colors.themes` is present in the brand guide
```

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | /context:load globs `*.html` and reports count | `skills/brand-awareness/SKILL.md` |
| AC-2 | /context:refresh detects HTML staleness via `updated` vs `created` heuristic | `skills/brand-awareness/SKILL.md` |
| AC-3 | /deliver step 3a lists HTML filenames as workshop visual references | `skills/brand-awareness/SKILL.md` |
| AC-4 | `visual.colors.themes` object with per-theme `accent` and `signature` fields | `schemas/brand-spec.schema.md` |
| AC-5 | `themes` is optional; validation rule 8 explicitly states backward compatibility | `schemas/brand-spec.schema.md` |
| AC-6 | /brand:tokens step 3 + command mapping table extract per-theme tokens under `brand.color.theme.{name}.*` | `skills/brand-awareness/SKILL.md`, `commands/brand-tokens.md` |
| AC-7 | Designer template includes commented-out themes structure with guidance | `agents/designer.md` |

## Implementation Guidance

**Sequence:**
1. `schemas/brand-spec.schema.md` — add themes object, theme color set, validation rules 7-8, example
2. `agents/designer.md` — add commented-out themes to brand guide template + guidance text
3. `skills/brand-awareness/SKILL.md` — directory structure, /brand:tokens themes mapping, /deliver HTML + themes surfacing, /context:load HTML count, /context:refresh HTML staleness
4. `commands/brand-tokens.md` — theme token mapping table, JSON example, notes

**GT-30 overlap resolved:** GT-30 is delivered. The manifest-based detection (entry counts, entry date staleness) is already in place. GT-32 adds HTML-specific detection alongside it — these are complementary, not duplicative. Workshop HTMLs and manifest entries are different artifact types (workshop snapshots vs. `/brand:image` generations).

**Test strategy:**
- Validate existing brand guides (no `themes`) pass schema validation unchanged (AC-5)
- Create brand guide with `themes.light` and `themes.dark` → validate passes (AC-4)
- Create brand guide with `themes.light` missing `accent` → validate fails (AC-4)
- Run `/brand:tokens` on multi-theme brand guide → verify per-theme tokens under `brand.color.theme.*` (AC-6)
- Run `/context:load` on project with workshop HTML files → verify HTML count reported (AC-1)
- Run `/context:load` on project without workshop HTML files → verify no HTML line emitted (AC-1)
- Run `/context:refresh` with HTML files + evolved brand guide (`updated` != `created`) → verify staleness warning (AC-2)
- Run `/context:refresh` with HTML files + non-evolved brand guide → verify no staleness warning (AC-2)
- Run `/deliver` on project with HTML artifacts → verify filenames listed (AC-3)
- Run `/deliver` on project with `visual.colors.themes` → verify per-theme tokens surfaced (AC-3)

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Multi-theme schema is niche | Med | Low | Entirely optional; single-theme brands are unchanged. Schema only adds complexity when `themes` is present. |
| HTML staleness heuristic (updated != created) is imprecise | Low | Low | False positive (flagging non-stale HTMLs) is low-cost — just an advisory message. False negative (missing truly stale HTMLs where guide was only edited, not formally evolved) is possible but acceptable. |
| Per-theme token extraction naming conflicts with existing tokens | Low | Med | Theme tokens are namespaced: `brand.color.theme.{name}.*` — no collision with `brand.color.primary` |
| Adding steps to /deliver increases prompt length | Low | Low | Steps are conditional — zero cost when no HTML files or themes exist. Consistent with GT-30's conditional pattern. |

## Routing

Ready for Crafter. All changes are additive prompt engineering. No architectural unknowns.

---

# Wontfix (2026-02-15)

## Rationale

Dropped after priority review. These changes solve for one project's brand workflow, not for the system's general quality. No other workflow has hit these gaps.

GT-30 (context-aware transition guidance, delivered) already addressed the high-leverage issue — operators now get visual verification reminders, manifest entry surfacing, and staleness detection at phase transitions. The incremental value of HTML-specific detection and per-theme schema support doesn't justify the complexity given a single data point from one field report.
