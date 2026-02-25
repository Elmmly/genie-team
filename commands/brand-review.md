# /brand:review [image-path]

Review a design artifact (wireframe, mockup, screenshot, or generated image) against brand guidelines and universal UX heuristics, producing a persistent Design Review Report.

---

## Arguments

- `image-path` - Local path to image file to review (required)
- Optional flags:
  - `--pro` - Use premium model for review (future: when vision-enhanced model becomes available)
  - `--brand [path]` - Explicit brand guide path (overrides auto-detect)
  - No flags - Auto-detect brand guide from docs/brand/

---

## Agent Identity

Read and internalize `.claude/agents/designer.md` for your identity, charter, and judgment rules. Activate **Visual Review Mode** (not image generation mode).

---

## Context Loading

**BRAND GUIDE LOADING:**
1. If `--brand [path]` is provided: Read that specific brand guide
2. If in workflow context: Check backlog frontmatter for `brand_ref`
3. Otherwise: Scan `docs/brand/*.md` for files with `type: brand-spec` in frontmatter
4. If multiple found: Prefer the one with `status: active`
5. If no brand guide found: Proceed in **heuristics-only mode** (no warning, no block)

The brand-awareness skill injects brand rules as review criteria when a brand guide is loaded.

**READ (automatic):**
- `docs/brand/{name}.md` (brand guide YAML frontmatter — colors, typography, imagery)
- `.claude/agents/designer.md` (persona and judgment rules — Visual Review Mode)
- Image file at `{image-path}` via the Read tool (ADR-004: native Claude vision)

---

## Image Path Validation

Before invoking the designer agent, validate the image path:

1. Check if `image-path` argument is present
   - If missing: output error and exit
   ```
   > Usage: /brand:review [image-path]
   > Provide a path to an image file (PNG, JPG, GIF, or WebP) to review.
   ```

2. Check if file exists at the given path
   - If not found: output error and exit
   ```
   > Image not found: {image-path}. Check the path and try again.
   ```

3. Check file extension (accept: .png, .jpg, .jpeg, .gif, .webp)
   - If unsupported: output error and exit
   ```
   > Unsupported file type: {ext}. Supported: PNG, JPG, GIF, WebP
   ```

4. If all checks pass: proceed to brand guide loading and agent invocation

**Important:** Do NOT create a partial report if validation fails. Exit cleanly with the error message only.

---

## Brand Guide Loading

Uses the standard brand-awareness loading pattern (same as brand-image.md):
1. If `--brand [path]` provided: use that path
2. Else: scan `docs/brand/*.md` for `type: brand-spec`; prefer `status: active`
3. If found: load brand rules for injection into review context
4. If not found: proceed with heuristics-only mode

---

## Agent Invocation

Invoke the designer agent in **visual review mode**:

1. Read the image at `{image-path}` using the Read tool (per ADR-004: native Claude vision — the Read tool natively supports image file types)
2. If a brand guide was loaded, include brand rules as review criteria:
   - Color hex values with roles (primary, secondary, accent, semantic)
   - Font families and their roles (headings, body, mono)
   - Imagery style, mood, subjects, and avoid list
3. Perform visual analysis in the following order:
   - **Brand Adherence** (only if brand guide loaded; skip this section in heuristics-only mode)
   - **Accessibility Signals**
   - **UX Quality**
   - **Recommendations**
4. Each recommendation MUST include specific, actionable values:
   - Contrast ratios with exact numbers (e.g., "2.1:1 — increase to at least 4.5:1 per WCAG AA")
   - Color hex codes (e.g., "change from #9BABB8 to #4A5568")
   - Font sizes in pixels (e.g., "10px is below minimum — increase to 14px")
   - Generic advice like "improve contrast" is NOT acceptable

---

## Design Review Report Template

The report is written with YAML frontmatter and structured sections:

```markdown
---
type: design-review
image: "{image-path}"
brand_ref: "{brand guide path | none}"
review_mode: brand-aware | heuristics-only
created: "{YYYY-MM-DD}"
reviewer: designer
---

# Design Review: {filename}

**Image:** `{image-path}`
**Brand Guide:** `{brand guide path}` | `none (heuristics-only mode)`
**Reviewed:** {YYYY-MM-DD HH:MM}

## Brand Adherence
<!-- Only present when brand guide is loaded; omitted in heuristics-only mode -->

| Rule | Expected | Observed | Status |
|------|----------|----------|--------|
| Primary color | #{hex} | #{observed-hex} | PASS / FAIL |
| Heading font | {font-family} | {observed-font} | PASS / FAIL |
| Imagery style | {style} | {observed-style} | PASS / FAIL |

Narrative: [2-3 sentences on overall brand compliance]

## Accessibility Signals

| Signal | Target | Observed | Status |
|--------|--------|----------|--------|
| Text contrast (primary) | ≥4.5:1 (WCAG AA) | {measured} | PASS / FAIL |
| Text contrast (large) | ≥3:1 (WCAG AA Large) | {measured} | PASS / FAIL |
| Minimum text size | ≥14px | {observed} | PASS / FAIL |

Narrative: [2-3 sentences on accessibility]

## UX Quality

Evaluated against Nielsen's 10 Usability Heuristics relevant to visual design:

- **Visual Hierarchy:** [Assessment]
- **Consistency and Standards:** [Assessment]
- **Aesthetic and Minimalist Design:** [Assessment]
- [Other relevant heuristics]

## Recommendations

Each recommendation includes a specific, actionable resolution:

1. **{Issue title}** — {Specific measurement or observation}. Recommendation: {Exact fix with specific values}.
   - Example: "Text contrast ratio 2.1:1 — below WCAG AA minimum of 4.5:1. Increase text color from #9BABB8 to #4A5568 to achieve 5.2:1 ratio."

2. **{Issue title}** — ...
```

When in **heuristics-only mode** (no brand guide), the report header notes:
> "No brand guide found at docs/brand/. Review uses universal UX heuristics (Nielsen's 10, WCAG contrast, visual hierarchy)."

And the Brand Adherence section is omitted entirely.

---

## Report Writing

```
File: docs/brand/reviews/{YYYYMMDD}_{HHmmss}_{stem}-review.md
  where {stem} is the image filename without extension
  e.g., docs/brand/reviews/20260225_143022_hero-landing-page-001-review.md

Create docs/brand/reviews/ directory if it does not exist.
Write report content returned by designer agent.
```

Reports are **persistent artifacts** — they are never archived, never deleted. They accumulate in `docs/brand/reviews/` as an audit trail of design decisions.

---

## Graceful Degradation

- If designer agent fails to read image content (provider limitation per ADR-004, GitHub #18588): include a provider limitation note in the report rather than failing entirely
- The review report is always created if image path validation passes — even if agent output is partial
- If no brand guide exists: proceed with heuristics-only mode (never block)

---

## Context Writing

**WRITE:**
- `docs/brand/reviews/{timestamp}_{stem}-review.md` (Design Review Report)

**UPDATE:**
- Nothing — review is a read-only analysis that produces a new artifact

---

## Output

On success:
- Design Review Report written to `docs/brand/reviews/`
- Report path displayed to user
- Summary of findings (pass/fail counts) displayed inline

On validation failure:
- Helpful error message displayed
- No report file created

---

## Usage Examples

```
/brand:review docs/brand/assets/hero-landing-page-001.png
> Loading brand guide: docs/brand/acme.md
> Reading image: docs/brand/assets/hero-landing-page-001.png
> Analyzing in visual review mode...
>
> Design Review Report written to:
>   docs/brand/reviews/20260225_143022_hero-landing-page-001-review.md
>
> Summary: 5 rules checked — 3 PASS, 2 FAIL
> Recommendations: 2 actionable items

/brand:review mockups/login-screen.png --brand docs/brand/secondary-brand.md
> Loading brand guide: docs/brand/secondary-brand.md
> Reading image: mockups/login-screen.png
> ...

/brand:review screenshots/dashboard.png
> No brand guide found at docs/brand/. Review uses universal UX heuristics.
> Reading image: screenshots/dashboard.png
> ...

/brand:review non-existent-file.png
> Image not found: non-existent-file.png. Check the path and try again.

/brand:review document.pdf
> Unsupported file type: .pdf. Supported: PNG, JPG, GIF, WebP
```

---

## Routing

After design review:
- If issues found: User can fix and re-review with `/brand:review`
- If clean review: Proceed with implementation (`/deliver`)
- If no brand guide: Create one with `/brand` before re-reviewing for brand compliance

---

## Notes

- Review is always explicit — never auto-triggered on image generation
- Brand Adherence section only appears when a brand guide is loaded
- Reports are append-only audit trail artifacts (never archived)
- Image content delivered via Read tool per ADR-004 (native Claude vision)
- Provider limitation on OpenRouter/Bedrock documented in ADR-004; report includes fallback note
- Each recommendation must include specific, measurable values — generic advice is prohibited

ARGUMENTS: $ARGUMENTS
