# /brand:tokens [brand-guide]

Generate W3C Design Tokens JSON from an existing brand guide.

---

## Arguments

- `brand-guide` - Optional: path to brand guide (auto-detects from `docs/brand/` if not provided)

---

## Genie Invoked

**Designer** - Token extraction combining:
- Brand spec schema knowledge
- W3C Design Tokens Community Group format

**System prompt:** `genies/designer/DESIGNER_SYSTEM_PROMPT.md`

---

## Context Loading

**BRAND GUIDE LOADING:**
1. If path argument provided: Read that specific brand guide
2. Otherwise: Scan `docs/brand/*.md` for files with `type: brand-spec` in frontmatter
3. If multiple found: Prefer the one with `status: active`
4. If none found: Error — cannot extract tokens without a brand guide:
   ```
   > No brand guide found at docs/brand/.
   > Create one first with: /brand
   ```

**READ (automatic):**
- `docs/brand/{name}.md` (YAML frontmatter only — the `visual` object)

---

## Token Extraction

Read the brand guide YAML frontmatter and transform the `visual` object into W3C Design Tokens format.

### Mapping

| Brand Guide Path | Token Path | Token Type |
|------------------|------------|------------|
| `visual.colors.primary` | `brand.color.primary` | `color` |
| `visual.colors.secondary` | `brand.color.secondary` | `color` |
| `visual.colors.accent` | `brand.color.accent` | `color` |
| `visual.colors.background` | `brand.color.background` | `color` |
| `visual.colors.foreground` | `brand.color.foreground` | `color` |
| `visual.colors.semantic.success` | `brand.semantic.success` | `color` |
| `visual.colors.semantic.warning` | `brand.semantic.warning` | `color` |
| `visual.colors.semantic.error` | `brand.semantic.error` | `color` |
| `visual.colors.semantic.info` | `brand.semantic.info` | `color` |
| `visual.colors.palette[].name/value` | `brand.color.{name}` | `color` |
| `visual.typography.headings.family` | `brand.typography.heading-family` | `fontFamily` |
| `visual.typography.headings.weight` | `brand.typography.heading-weight` | `fontWeight` |
| `visual.typography.body.family` | `brand.typography.body-family` | `fontFamily` |
| `visual.typography.body.weight` | `brand.typography.body-weight` | `fontWeight` |
| `visual.typography.mono.family` | `brand.typography.mono-family` | `fontFamily` |
| `visual.typography.mono.weight` | `brand.typography.mono-weight` | `fontWeight` |
| `visual.typography.scale[]` | `brand.typography.scale` | `dimension` |

### Output Format

W3C Design Tokens Community Group format:

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
      "heading-weight": { "$type": "fontWeight", "$value": 700 },
      "body-family": { "$type": "fontFamily", "$value": "Inter" },
      "body-weight": { "$type": "fontWeight", "$value": 400 },
      "mono-family": { "$type": "fontFamily", "$value": "JetBrains Mono" },
      "mono-weight": { "$type": "fontWeight", "$value": 400 }
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

Only include tokens for fields that exist in the brand guide. Skip missing fields gracefully.

---

## Context Writing

**WRITE:**
- `docs/brand/tokens.json` (W3C Design Tokens)

---

## Output

```
> Extracted design tokens from docs/brand/{name}.md
>
> Tokens generated:
>   - {N} color tokens
>   - {N} typography tokens
>   - {N} semantic tokens
>
> Saved: docs/brand/tokens.json
```

---

## Usage Examples

```
/brand:tokens
> Scanning docs/brand/ for brand guide...
> Found: docs/brand/acme.md (status: active)
> Extracted design tokens from docs/brand/acme.md
>
> Tokens generated:
>   - 5 color tokens
>   - 6 typography tokens
>   - 4 semantic tokens
>
> Saved: docs/brand/tokens.json

/brand:tokens docs/brand/secondary-brand.md
> Extracted design tokens from docs/brand/secondary-brand.md
> ...
```

---

## Routing

After token extraction:
- `/deliver` — Crafter can use tokens for implementation theming
- `/brand:image` — Generate images using the brand guide
- `/brand --evolve` — Update the brand guide if tokens reveal gaps

---

## Notes

- Token extraction is a mechanical transformation — no inference or generation
- tokens.json is a derived artifact; the brand guide YAML is the source of truth
- Regenerate tokens explicitly after brand guide changes — not auto-triggered
- Only fields present in the brand guide produce tokens — missing fields are skipped
- Extended palette entries (`visual.colors.palette[]`) produce named color tokens

ARGUMENTS: $ARGUMENTS
