---
schema_name: brand-spec
schema_version: "1.0"
type: schema
description: Defines the frontmatter contract for Brand Specification documents used by Designer genie
created: 2026-02-04
---

# Brand Spec Schema v1.0

> All structured data lives in YAML frontmatter. The markdown body is free-form
> human narrative. Machines parse frontmatter only; they never need to parse the body.

## Purpose

Brand Specs provide machine-readable brand definitions that guide:
- AI image generation (consistent style, colors, mood)
- Design token extraction (colors, typography, spacing)
- Design review (brand compliance checking)
- Code generation (component theming)

## Required Frontmatter Fields

| Field | Type | Constraint | Description |
|-------|------|------------|-------------|
| `spec_version` | string | semver, e.g. `"1.0"` | Schema version for compatibility |
| `type` | string | `"brand-spec"` | Document type discriminator |
| `brand_name` | string | max 100 chars | Human-readable brand name |
| `status` | string | enum: `draft`, `active`, `deprecated` | Lifecycle status |
| `created` | string | ISO 8601 date | Creation date |
| `identity` | object | see Identity Object | Brand identity elements |
| `visual` | object | see Visual Object | Visual design system |

## Optional Frontmatter Fields

| Field | Type | Description |
|-------|------|-------------|
| `updated` | string (ISO date) | Last modified date |
| `author` | string | Producing genie or person |
| `target_project` | string | Target project name |
| `tags` | array of strings | Categorization tags |
| `extends` | string | Path to parent brand spec (for variants) |

## Identity Object

| Field | Type | Description |
|-------|------|-------------|
| `mission` | string | Brand mission statement |
| `values` | array of strings | Core brand values |
| `voice` | object | Voice and tone definition |
| `positioning` | string | Market positioning statement |

### Voice Object

| Field | Type | Description |
|-------|------|-------------|
| `tone` | string | e.g., "professional", "friendly", "bold" |
| `personality` | array of strings | Personality traits |
| `vocabulary` | object | Preferred/avoided terms |

### Vocabulary Object

| Field | Type | Description |
|-------|------|-------------|
| `preferred` | array of strings | Terms to use |
| `avoided` | array of strings | Terms to avoid |

## Visual Object

| Field | Type | Description |
|-------|------|-------------|
| `colors` | object | Color palette (see Colors Object) |
| `typography` | object | Typography system (see Typography Object) |
| `imagery` | object | Imagery guidelines (see Imagery Object) |
| `spacing` | object | Spacing scale (optional) |
| `forms` | object | Forms & UI components (see Forms Object, optional) |
| `ai` | object | AI design system (see AI Object, optional) |

### Colors Object

Follows W3C Design Tokens format where applicable.

| Field | Type | Description |
|-------|------|-------------|
| `primary` | string | Primary brand color (hex) |
| `secondary` | string | Secondary brand color (hex) |
| `accent` | string | Accent color (hex) |
| `background` | string | Default background (hex) |
| `foreground` | string | Default text color (hex) |
| `semantic` | object | Semantic colors (success, warning, error, info) |
| `palette` | array | Extended palette with name/value pairs |

### Typography Object

| Field | Type | Description |
|-------|------|-------------|
| `headings` | object | Heading font definition |
| `body` | object | Body text font definition |
| `mono` | object | Monospace font definition (optional) |
| `scale` | array | Type scale ratios |

### Font Definition Object

| Field | Type | Description |
|-------|------|-------------|
| `family` | string | Font family name |
| `weight` | string or number | Font weight |
| `style` | string | Font style (normal, italic) |
| `fallback` | array of strings | Fallback font stack |

### Imagery Object

| Field | Type | Description |
|-------|------|-------------|
| `style` | string | enum: `photography`, `illustration`, `mixed`, `abstract` |
| `mood` | array of strings | Mood descriptors for AI generation |
| `subjects` | array of strings | Preferred image subjects |
| `avoid` | array of strings | Subjects/styles to avoid |
| `aspect_ratios` | array of strings | Preferred aspect ratios |
| `filters` | object | Color grading/filter preferences |

### Forms Object

Defines the brand's form and UI component specifications. All values are framework-agnostic — they describe the design, not the implementation.

| Field | Type | Description |
|-------|------|-------------|
| `button` | object | Button component spec (see Button Object) |
| `input` | object | Form input spec (see Input Object) |
| `spacing` | object | Spacing token scale (key-value: xs, sm, md, lg, xl, 2xl, 3xl, 4xl) |
| `border_radius` | object | Border radius token scale (key-value: sm, md, lg, full) |

### Button Object

| Field | Type | Description |
|-------|------|-------------|
| `height_default` | string | Default button height (e.g., "36px") |
| `height_small` | string | Small button height (e.g., "32px") |
| `height_large` | string | Large button height (e.g., "40px") |
| `radius` | string | Button border radius (e.g., "6px") |
| `font_size` | string | Button font size (e.g., "14px") |
| `font_weight` | string or number | Button font weight (e.g., 500) |
| `variants` | array of strings | Available variants (e.g., primary, secondary, accent, ghost, outline, destructive) |

### Input Object

| Field | Type | Description |
|-------|------|-------------|
| `height` | string | Input height — should match default button height |
| `radius` | string | Input border radius |
| `font_size` | string | Input font size |
| `focus_ring` | string | Focus ring description (e.g., "primary border + 2px outer glow") |

### AI Object

Optional — only present when the product uses AI-powered features.

| Field | Type | Description |
|-------|------|-------------|
| `indicator_icon` | string | Icon used as universal AI indicator (e.g., "sparkle") |
| `glow` | object | Glow system (see Glow Object) |
| `gradient` | object | AI gradient bar definition (optional) |
| `animations` | object | Animation keyframe specs |
| `form_states` | array of strings | Progressive AI form states (e.g., populating, suggestion, accepted, insight, recommended) |

### Glow Object

| Field | Type | Description |
|-------|------|-------------|
| `decorative` | string | Multi-layer glow CSS (for icons, buttons, FABs) |
| `functional` | string | Single-layer glow CSS (for form fields) |

### AI Gradient Object

| Field | Type | Description |
|-------|------|-------------|
| `stops` | array of strings | Gradient color stops (hex values) |
| `flow_duration` | string | Gradient animation duration (e.g., "3s") |

### AI Animations Object

| Field | Type | Description |
|-------|------|-------------|
| `glow_pulse` | string | Glow pulse duration (e.g., "2s") |
| `breathe` | string | Icon breathe duration (e.g., "2s") |
| `gradient_flow` | string | Gradient flow duration (e.g., "3s") |
| `shimmer_sweep` | string | Shimmer sweep duration (e.g., "3s") |

## Status Lifecycle

```
draft → active → deprecated
```

## Complete Example

```yaml
---
spec_version: "1.0"
type: brand-spec
brand_name: "Acme Corp"
status: active
created: 2026-02-04
author: designer
target_project: acme-web
tags: [b2b, saas, enterprise]
identity:
  mission: "Empowering teams to build faster"
  values:
    - Innovation
    - Reliability
    - Simplicity
  voice:
    tone: professional
    personality:
      - confident
      - helpful
      - clear
    vocabulary:
      preferred:
        - streamline
        - empower
        - seamless
      avoided:
        - synergy
        - leverage
        - pivot
  positioning: "The developer platform that scales with you"
visual:
  colors:
    primary: "#2563EB"
    secondary: "#1E40AF"
    accent: "#F59E0B"
    background: "#FFFFFF"
    foreground: "#1F2937"
    semantic:
      success: "#10B981"
      warning: "#F59E0B"
      error: "#EF4444"
      info: "#3B82F6"
    palette:
      - name: "blue-50"
        value: "#EFF6FF"
      - name: "blue-100"
        value: "#DBEAFE"
  typography:
    headings:
      family: "Inter"
      weight: 700
      fallback: ["system-ui", "sans-serif"]
    body:
      family: "Inter"
      weight: 400
      fallback: ["system-ui", "sans-serif"]
    mono:
      family: "JetBrains Mono"
      weight: 400
      fallback: ["monospace"]
    scale: [0.75, 0.875, 1, 1.125, 1.25, 1.5, 1.875, 2.25, 3]
  imagery:
    style: photography
    mood:
      - modern
      - clean
      - professional
      - human
    subjects:
      - diverse teams collaborating
      - modern workspaces
      - technology in use
    avoid:
      - stock photo clichés
      - overly corporate
      - isolated individuals
    aspect_ratios: ["16:9", "1:1", "4:3"]
    filters:
      saturation: 0.9
      contrast: 1.1
---

# Acme Corp Brand Specification

## Overview

Acme Corp is a B2B SaaS platform focused on developer productivity. Our brand
reflects innovation, reliability, and simplicity.

## Usage Guidelines

### Logo Usage

[Free-form narrative about logo placement, sizing, clear space...]

### Color Application

[Free-form narrative about when to use primary vs. secondary colors...]

### Image Selection

[Free-form narrative about choosing appropriate imagery...]
```

## Validation

To validate a brand spec, parse the YAML frontmatter and check:

1. All required fields are present
2. `type` equals `"brand-spec"`
3. `status` is a valid enum value
4. `identity` and `visual` objects contain required sub-fields
5. Color values are valid hex codes
6. `imagery.style` is a valid enum value

## Integration with Design Tokens

Brand Specs can be transformed into W3C Design Tokens format:

```json
{
  "$type": "color",
  "$value": "#2563EB",
  "$description": "Primary brand color"
}
```

The `/design:tokens` command performs this transformation automatically.

## MCP Image Generation

When generating images via MCP, the `imagery` section guides prompt construction:

```
Generate an image in {imagery.style} style.
Mood: {imagery.mood | join(", ")}
Subjects: {imagery.subjects | join(", ")}
Avoid: {imagery.avoid | join(", ")}
Color palette: {visual.colors.primary}, {visual.colors.secondary}, {visual.colors.accent}
```
