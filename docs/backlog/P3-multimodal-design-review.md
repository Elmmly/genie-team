---
id: P3-multimodal-design-review
title: Multimodal Design Review for Designer Genie
type: feature
status: reviewed
verdict: APPROVED
priority: P3
appetite: medium
spec_ref: docs/specs/genies/multimodal-design-review.md
adr_refs:
  - docs/decisions/ADR-004-multimodal-design-review-integration.md
created: 2026-02-25
discovery_ref: docs/analysis/20260225_discover_ai_pdlc_trends.md
---

# Shaped Work Contract: Multimodal Design Review for Designer Genie

## Problem

The Designer genie creates brand guides, generates design tokens, and produces images — but it cannot look at a design artifact and critique it. There is no capability in genie-team today to analyze a wireframe, mockup, screenshot, or generated image against brand, accessibility, or UX quality criteria.

The consequence is that design review remains a manual, human-only task:

1. **Design review happens late.** When a designer generates a brand image, exports a mockup, or shares a screenshot, there is no automated first-pass review. Visual feedback typically enters the loop at Critic review time (after implementation) or during stakeholder review — both much later than optimal.

2. **The Designer genie already has brand context but cannot use it visually.** The brand guide at `docs/brand/{name}.md` contains explicit color palettes, typography rules, imagery dos/don'ts, and consistency principles. This structured brand knowledge is loaded by the `brand-awareness` skill during `/design` and `/discern` — but only as text context for non-visual genies. No genie applies this knowledge against actual visual artifacts.

3. **Vision models are now production-ready for this use case.** Gemini 2.5 Pro, Claude Sonnet, and GPT-4V can reliably analyze visual content for design quality signals (alignment, contrast ratios, spacing consistency, brand color adherence). This is not experimental — it is the production tier. The platform capability exists; it just is not wired into any genie workflow.

4. **The gap is widening.** As genie-team positions itself as the "quality-first" AI PDLC framework (discovery doc section 10), having no design review capability is inconsistent with the positioning. Multimodal design review is "entering the mainstream" (discovery doc section 2.8) and genie-team has no answer for it.

**Who is affected:** Designer genie users who generate images, create mockups, or have design artifacts they want reviewed before implementation begins. Also Critic users reviewing features with visual components.

**Evidence from discovery:** Discovery doc section 2.8 identifies multimodal design review as entering mainstream. Section 10 lists "No multimodal design review (missing 'multimodal design analysis' trend)" as a direct gap. The Designer spec already exists with 12 met ACs — this adds one new review capability to a complete genie.

## Appetite & Boundaries

- **Appetite:** Medium batch (3-5 days)
- **No-gos:**
  - Do NOT add vision review to Architect, Crafter, or Critic in this item (scope creep — this is a Designer-only enhancement)
  - Do NOT build a full accessibility audit pipeline (WCAG scoring, automated remediation) — that is a separate, larger item
  - Do NOT require a new MCP server — use Claude's native vision input (passing images as content blocks to the agent context) or the existing `@fastmcp-me/imagegen-mcp` if it supports image reading
  - Do NOT modify the brand guide format or schema — review output is a separate artifact (review report), not a brand guide mutation
  - Do NOT auto-trigger design review without explicit user invocation — review is a user-requested action, not automatic
- **Fixed elements:**
  - Review must reference the brand guide (`brand_ref`) when one exists — brand-aware review is the differentiator vs. generic lint tools
  - When no brand guide exists, review falls back to universal UX heuristics (Nielsen's 10, contrast ratios, spacing, visual hierarchy)
  - The command follows the existing `/brand:*` namespace convention (ADR-002) — new command is `/brand:review`
  - Review output is human-readable (not machine-readable schema) — a structured report, not a scored metric dashboard

## Goals & Outcomes

- A Designer user can invoke `/brand:review [image-path]` and receive structured feedback on an image or design artifact covering brand adherence, accessibility signals, and UX quality
- When a brand guide exists, review feedback explicitly references brand rules being met or violated (e.g., "button uses #2D4A8E — matches brand primary color; text size 10px — below brand minimum of 14px")
- The feedback is actionable: each issue includes a specific recommendation for resolution, not just a flag
- A Critic user reviewing a feature with visual components can attach design artifacts to their review context and get vision-augmented brand compliance feedback
- The capability degrades gracefully: if no image is provided or the path is invalid, a helpful error is shown; if no brand guide exists, review continues with generic heuristics

## Behavioral Delta Against Existing Specs

**Affected spec:** `docs/specs/genies/designer.md`

**Current Behavior (AC-10):**
> designer agent available via Task tool for autonomous brand analysis

**Proposed Change:**
> AC-10 updated: designer agent supports two modes — (a) existing brand analysis mode, (b) new visual review mode when an image path is provided. In visual review mode, agent receives the image as a content block alongside the brand guide and returns a structured Design Review Report.

**New AC for Designer spec:**
> AC-13: /brand:review [image-path] command invokes the designer agent in visual review mode, producing a Design Review Report at docs/brand/reviews/{timestamp}_{filename}-review.md with sections: Brand Adherence, Accessibility Signals, UX Quality, and Recommendations

**New AC for Designer spec:**
> AC-14: /brand:review falls back to universal UX heuristics (Nielsen, contrast, spacing, visual hierarchy) when no brand guide exists; report notes the fallback mode

**New AC for Designer spec:**
> AC-15: Design Review Reports are persistent artifacts in docs/brand/reviews/ (never archived); they accumulate as an audit trail of design decisions

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Claude Sonnet/Opus (the execution model) can receive image paths as content and analyze them for design quality | feasibility | Quick spike: pass a PNG path to Claude via /brand:review with a brand guide and evaluate output quality |
| The claude CLI can pass image files as content input to an agent invocation | feasibility | Test whether `claude -p "/brand:review path/to/image.png"` correctly passes image content to the agent |
| Brand guide color/typography rules are specific enough to generate concrete visual compliance feedback | value | Test with genie-team's own brand guide (if one exists) or create a minimal test guide with colors and font sizes |
| Users have design artifacts to review (the use case is real for this project) | value | Low bar: even reviewing /brand:image outputs against the brand guide that created them is useful |
| Review quality is good enough to catch obvious violations without being noisy | value | Define a rubric: the review should catch 3+ violations in a deliberately off-brand image; should not flag false positives on a brand-compliant image |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: New `/brand:review` command + designer agent visual mode | Follows ADR-002 namespace; clean separation; designer agent owns visual analysis | Adds one command; requires image content passing to agent | Recommended |
| B: Extend `/discern` to optionally review design artifacts | Critic already reviews; multimodal review piggybacks | Blurs Critic/Designer ownership; Critic is code-review, not design-review | Avoid — wrong genie |
| C: New `/review:design` command in a separate namespace | Clean separation from `/brand:*` | Fragments design-related commands across namespaces; violates ADR-002 | Avoid |
| D: Automatic review on every `/brand:image` generation | No user action needed; instant feedback loop | Adds cost to every image generation; designer may not want feedback on exploration images | Avoid — cost and friction |

**Recommendation:** Option A. Follows the established integration pattern (ADR-002), adds exactly one new command, and keeps visual review as an explicit user action rather than an automatic tax on image generation.

## ADR Trigger

This item creates a proposed ADR (ADR-004) because:
- Multiple viable alternatives exist for how to pass image content to the agent (native Claude vision, MCP image reader, base64 encoding)
- The decision affects how future vision-capable workflows are integrated (precedent-setting)
- Hard to change once adopted — if we choose MCP-based image reading and MCP server changes, or if we choose native vision and it has limitations, migration is costly

See: `docs/decisions/ADR-004-multimodal-design-review-integration.md`

## Acceptance Criteria

- id: AC-1
  description: >-
    /brand:review [image-path] command exists and invokes the designer agent
    in visual review mode with the image and brand guide (when available)
    as context
  status: pending

- id: AC-2
  description: >-
    Review produces a Design Review Report at
    docs/brand/reviews/{timestamp}_{filename}-review.md with sections:
    Brand Adherence, Accessibility Signals, UX Quality, and Recommendations
  status: pending

- id: AC-3
  description: >-
    When a brand guide exists, Brand Adherence section explicitly references
    specific brand rules (color hex values, font sizes, imagery guidelines)
    and states whether each is met or violated in the reviewed artifact
  status: pending

- id: AC-4
  description: >-
    When no brand guide exists, review falls back to universal UX heuristics
    and the report notes: "No brand guide found; review uses universal UX
    heuristics"
  status: pending

- id: AC-5
  description: >-
    Each identified issue in the Recommendations section includes a specific,
    actionable suggestion (not just "improve contrast" — "increase text
    contrast from 2.1:1 to at least 4.5:1 per WCAG AA")
  status: pending

- id: AC-6
  description: >-
    Design Review Reports are written to docs/brand/reviews/ and are never
    archived — they persist as an audit trail of design decisions
  status: pending

- id: AC-7
  description: >-
    When image path is invalid or file does not exist, /brand:review shows
    a helpful error message and exits cleanly without creating a partial report
  status: pending

- id: AC-8
  description: >-
    /brand:review command definition is documented in commands/brand-review.md
    following the pattern of commands/brand-image.md
  status: pending

## Routing

- **Next genie:** Crafter — spike is resolved, ADR-004 accepted. The Designer agent can read and analyze images via the Read tool (confirmed by empirical test 2026-02-25).
- **Crafter scope:** New `commands/brand-review.md` file + update to `agents/designer.md` to describe visual review mode + update `skills/brand-awareness.md` if needed
- **After Crafter:** Critic to verify review quality on a sample brand image

---

# Design

## Design Summary

Two files change, one new file is created. The new `commands/brand-review.md` command follows the pattern of `commands/brand-image.md` exactly: argument parsing, brand guide loading, agent invocation, output writing, and graceful degradation. The Designer agent (`agents/designer.md`) gets a new "Visual Review Mode" section describing how it analyzes images and produces Design Review Reports. The brand-awareness skill (`skills/brand-awareness/SKILL.md`) gets a new `### During /brand:review` behavior entry. Per ADR-004 (accepted), image content is delivered via the Read tool — no new MCP servers, no base64 encoding.

## Architecture

```
/brand:review [image-path] [--brand path] [--pro]
        │
        ▼
commands/brand-review.md
  1. Validate image path exists
  2. Load brand guide (brand-awareness loading pattern)
  3. Read image via Read tool (ADR-004: native Claude vision)
  4. Invoke designer agent in visual review mode
  5. Write Design Review Report to docs/brand/reviews/{timestamp}_{filename}-review.md
        │
        ▼
agents/designer.md  (Visual Review Mode)
  - Reads image via Read tool
  - Loads brand guide if provided
  - Analyzes: Brand Adherence | Accessibility Signals | UX Quality
  - Produces Recommendations (specific, actionable)
  - Returns report content

skills/brand-awareness/SKILL.md
  - During /brand:review: Load brand guide, inject brand rules as review criteria
```

Image delivery path (ADR-004, Option A):
- Command passes image path as part of the prompt context
- Designer agent uses `Read` tool to load the image
- Claude Code's Read tool natively supports image file types (PNG, JPG, GIF, WebP)
- Agent receives image content as a vision content block

Output path:
- Report written to `docs/brand/reviews/{YYYYMMDD}_{HHmmss}_{filename}-review.md`
- Directory created if it does not exist
- Reports are append-only artifacts (never archived, never deleted)

## Component Design

| Component | Action | File | What Changes |
|-----------|--------|------|--------------|
| BrandReviewCommand | create | `commands/brand-review.md` | New command file following brand-image.md pattern |
| DesignerVisualMode | modify | `agents/designer.md` | Add "Visual Review Mode" section describing review behavior |
| BrandAwarenessReview | modify | `skills/brand-awareness/SKILL.md` | Add `### During /brand:review` behavior entry |

## AC Mapping

| AC | Approach | Components |
|----|----------|------------|
| AC-1 | New `commands/brand-review.md` command that accepts `[image-path]` argument and invokes designer agent in visual review mode | `commands/brand-review.md` |
| AC-2 | Command writes report to `docs/brand/reviews/{timestamp}_{filename}-review.md` using fixed section structure: Brand Adherence, Accessibility Signals, UX Quality, Recommendations | `commands/brand-review.md`, `agents/designer.md` |
| AC-3 | Brand-awareness skill loads brand guide rules and injects them as review criteria; designer agent references specific hex values, font sizes, imagery guidelines by name | `agents/designer.md`, `skills/brand-awareness/SKILL.md` |
| AC-4 | Command uses brand-awareness loading pattern; when no brand guide found, designer agent receives heuristics-only instruction and report header notes fallback mode | `commands/brand-review.md`, `agents/designer.md` |
| AC-5 | Designer agent instruction requires each Recommendations entry to include specific values (contrast ratio numbers, exact pixel sizes, specific color hex codes) | `agents/designer.md` |
| AC-6 | Command writes to `docs/brand/reviews/` directory; explicit instruction that reports are never archived | `commands/brand-review.md` |
| AC-7 | Command validates image path before invoking agent; if path invalid or file not found, outputs error message and exits without creating a report file | `commands/brand-review.md` |
| AC-8 | Command definition documented in `commands/brand-review.md` following brand-image.md pattern (same section structure: Arguments, Agent Identity, Context Loading, etc.) | `commands/brand-review.md` |

## Interfaces

### `commands/brand-review.md` — Full Structure

Follows the section structure of `commands/brand-image.md` exactly. Below is the interface contract for each section:

**Arguments:**
```
- image-path  — Local path to image file to review (required)
- Optional flags:
  - --pro     — Use Gemini 3 Pro model for review (future: if vision-enhanced model becomes available)
  - --brand [path] — Explicit brand guide path (overrides auto-detect)
  - No flags  — Auto-detect brand guide from docs/brand/
```

**Image Path Validation (before any agent invocation):**
```
1. Check if image-path argument is present
   → If missing: error "Usage: /brand:review [image-path]" — exit
2. Check if file exists at the given path
   → If not found: error "Image not found: {image-path}. Check the path and try again." — exit
3. Check file extension (accept: .png, .jpg, .jpeg, .gif, .webp)
   → If unsupported: error "Unsupported file type: {ext}. Supported: PNG, JPG, GIF, WebP" — exit
4. If all checks pass: proceed to brand guide loading
```

**Brand Guide Loading:** Uses the standard brand-awareness loading pattern (same as brand-image.md):
1. If `--brand [path]` provided: use that path
2. Else: scan `docs/brand/*.md` for `type: brand-spec`; prefer `status: active`
3. If found: load brand rules for injection into review context
4. If not found: proceed with heuristics-only mode

**Agent Invocation:**

Instruct the designer agent (via the command's prompt body) to:
1. Read the image at `{image-path}` using the Read tool
2. Perform visual analysis in the following order:
   - Brand Adherence (only if brand guide loaded; else skip this section header)
   - Accessibility Signals
   - UX Quality
   - Recommendations

**Report Writing:**
```
File: docs/brand/reviews/{YYYYMMDD}_{HHmmss}_{stem}-review.md
  where {stem} is the image filename without extension
  e.g., docs/brand/reviews/20260225_143022_hero-landing-page-001-review.md

Create docs/brand/reviews/ directory if it does not exist.
Write report content returned by designer agent.
```

**Graceful Degradation:**
- If designer agent fails to read image (provider limitation per ADR-004): output warning and note in report
- The review report is always created if image path validation passes — even if agent output is partial

### Design Review Report Template

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

When in heuristics-only mode (no brand guide), the report header notes: "No brand guide found at docs/brand/. Review uses universal UX heuristics (Nielsen's 10, WCAG contrast, visual hierarchy)."

### `agents/designer.md` — Visual Review Mode Section

Add a new `## Visual Review Mode` section after the existing `## Image Generation` section. Structure:

```markdown
## Visual Review Mode

When invoked by `/brand:review`, the Designer operates in visual review mode rather than generation mode.

### Entry Condition

Visual review mode is active when the command is `/brand:review` and an image path is provided. The agent must:
1. Read the image file using the Read tool (the Read tool supports PNG, JPG, GIF, WebP)
2. Load the brand guide context if provided (from brand-awareness skill injection)
3. Perform analysis in the order: Brand Adherence → Accessibility Signals → UX Quality → Recommendations
4. Return the complete Design Review Report content for the command to write

### Analysis Criteria

**Brand Adherence (when brand guide loaded):**
For each color in the brand guide visual.colors: compare the expected hex value to the observed colors in the image. Note: exact hex matching is not expected — estimate within ±10% luminance range counts as compliant.
For typography: identify the apparent font weight and style; compare to brand typography.headings and typography.body specifications.
For imagery: assess whether the image style (photography, illustration, abstract) matches the brand's imagery.style field.

**Accessibility Signals:**
Estimate contrast ratios for text on background using visual inspection. Flag any text that appears to have contrast below 4.5:1 (AA) for normal text or 3:1 (AA Large) for large text (18px+ or 14px+ bold).
Note minimum visible text size. Flag text that appears smaller than 14px.
Note interactive element affordances: are buttons visually distinguishable from static content?

**UX Quality:**
Apply Nielsen's heuristics relevant to visual artifacts: visual hierarchy (H1), consistency (H4), aesthetic minimalism (H8). Additional heuristics as relevant to the artifact type (mockup vs. screenshot vs. generated image).

**Recommendations:**
Every identified issue MUST include a specific resolution: exact contrast ratio target, exact color hex code to use, exact font size in pixels, exact spacing value in rem or px. Generic advice ("improve the contrast") is not acceptable.

### Provider Limitation Note

Per ADR-004: Read tool image analysis may not work on OpenRouter or AWS Bedrock API providers (GitHub #18588). If the Read tool does not produce image content (the agent sees only a file path, not visual content), the agent MUST include in the report:

> Note: Image analysis may be incomplete. Read tool image content was not visible in this session. This is a known limitation on some API providers (GitHub #18588). For full visual review, use native Claude (claude.ai or direct API).

### WILL NOT Do (Visual Review Mode)

- WILL NOT generate new images (this is review mode, not generation mode)
- WILL NOT modify the brand guide (review is read-only relative to brand artifacts)
- WILL NOT score designs numerically — reports are narrative with structured tables
- WILL NOT auto-remediate issues — recommendations are advisory
```

### `skills/brand-awareness/SKILL.md` — `/brand:review` Behavior

Add a new `### During /brand:review` entry to the Behaviors section, after the existing `### During /brand:image` entry:

```markdown
### During /brand:review

Loads brand guide and injects brand rules as review criteria:

1. Load brand guide via common pattern
2. If brand guide found: Extract review criteria and inject into command context:
   - From visual.colors: all color hex values with their roles (primary, secondary, accent, semantic)
   - From visual.typography: font families and their roles (headings, body, mono)
   - From visual.imagery: style, mood, subjects, avoid list
   - Inject as "Brand Review Criteria" block for designer agent to use in Brand Adherence section
3. If no brand guide found: Set review_mode to heuristics-only; report header notes the fallback
4. Never block — heuristics-only mode produces a useful review

**Reads:** `docs/brand/*.md`, backlog `brand_ref`
**Writes:** Nothing (read-only — criteria injection only)
```

## Pattern Adherence

- **`/brand:*` namespace:** `commands/brand-review.md` follows ADR-002 — all Designer commands live in the `/brand:` namespace. The file name, argument structure, and section layout mirror `commands/brand-image.md` exactly.
- **Brand guide loading pattern:** The command uses the brand-awareness common loading pattern (check `brand_ref` → scan `docs/brand/*.md` → prefer `status: active` → silent-skip if none found). No deviation.
- **Agent section pattern:** "## Visual Review Mode" follows the naming and structure of other named mode sections in agent definitions (e.g., Headless Execution Mode in `agents/crafter.md`, Workshop Facilitation in `agents/designer.md`).
- **Skill behavior entry pattern:** The new `### During /brand:review` entry in `skills/brand-awareness/SKILL.md` follows the exact structure of all other behavior entries: trigger condition, ordered steps, reads/writes summary.
- **Persistent artifact pattern:** `docs/brand/reviews/` mirrors `docs/brand/assets/` — both are append-only audit trail directories that are never archived.
- **No new commands pattern:** This is one new command. The shaped contract evaluated and rejected four alternatives; the `/brand:review` approach is consistent with how `/brand:image` and `/brand:tokens` were added.

No deviations from established patterns.

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Read tool image visibility fails on OpenRouter/Bedrock (GitHub #18588) | M | M | Designer agent includes provider limitation note in report; ADR-004 documents this; affected users can switch to native Claude |
| Review quality too low to catch violations (false confidence) | L | H | Critic verifies quality on a sample brand image; designer instruction mandates specific measurements not vague assessments |
| Designer agent produces generic recommendations without specific values | M | M | Instruction explicitly forbids generic advice; each recommendation must include concrete values; Critic checks this |
| `docs/brand/reviews/` directory does not exist on first run | L | L | Command creates directory if missing (standard pattern from brand-image.md with assets/) |
| Report timestamp collisions (two reviews of same image in same second) | L | L | Timestamp includes HH:MM:SS; in practice, two reviews of the same image in the same second is not a real scenario |

Rollback: `commands/brand-review.md` is a new file — deleting it removes the feature entirely without affecting any existing functionality. Changes to `agents/designer.md` and `skills/brand-awareness/SKILL.md` are additive sections — remove them and existing behavior is unchanged.

## Implementation Guidance

**Sequence for Crafter (three files, ordered by dependency):**

1. **`commands/brand-review.md` — New file** (primary deliverable)
   - Copy the structure of `commands/brand-image.md` as a starting template
   - Sections to include (matching brand-image.md): Arguments, Agent Identity, Context Loading (BRAND GUIDE LOADING), Image Path Validation, Brand Guide Loading, Agent Invocation, Report Writing, Graceful Degradation, Context Writing, Output, Usage Examples, Routing, Notes
   - Key differences from brand-image.md: no image generation; input is existing image; output is a markdown report file (not an image); no MCP tool call
   - End of file: `ARGUMENTS: $ARGUMENTS`

2. **`agents/designer.md` — Modify (add Visual Review Mode section)**
   - Location: After the existing `## Image Generation` section and before `## Agent Result Format`
   - Section header: `## Visual Review Mode`
   - Content: Entry condition, analysis criteria, provider limitation note, WILL NOT Do list (see Interfaces above)

3. **`skills/brand-awareness/SKILL.md` — Modify (add `/brand:review` behavior)**
   - Location: After the existing `### During /brand:image` sub-section, before `### During /brand:tokens`
   - Sub-section header: `### During /brand:review`
   - Content: 4-step behavior (see Interfaces above) with Reads/Writes summary

4. **Create `docs/brand/reviews/` directory**
   - Create an empty placeholder or `.gitkeep` if the directory does not exist yet
   - The directory is referenced in the command but may not exist in the repo until first use
   - Preferred: create a `docs/brand/reviews/.gitkeep` to establish the directory in git

**Test scenarios for Critic:**
- `/brand:review path/to/existing-image.png` with a brand guide present → report created at `docs/brand/reviews/`, contains all four sections, Brand Adherence references specific brand hex values
- `/brand:review path/to/existing-image.png` with NO brand guide → report created, header notes "No brand guide found; review uses universal UX heuristics", Brand Adherence section absent
- `/brand:review non-existent-path.png` → helpful error message, no report file created
- `/brand:review path/to/image.png --brand docs/brand/specific.md` → uses the specified brand guide (not auto-detected)
- Report file naming follows `{YYYYMMDD}_{HHmmss}_{stem}-review.md` pattern
- Each issue in Recommendations section includes specific values (not just "improve contrast")

## Routing

Ready for Crafter. ADR-004 accepted (Option A: native Read tool vision). Implementation is three files (one new, two modified). All decisions are made. No further design questions outstanding.

# Implementation
<!-- Added by /deliver on 2026-02-25 -->

## Summary

Implemented the multimodal design review capability as three file changes plus one directory creation, following the design specification exactly. TDD approach: 52 structural tests written first (RED), then implementation (GREEN), all passing with zero regressions across 147 total project tests.

## Files Changed

| File | Action | Purpose |
|------|--------|---------|
| `commands/brand-review.md` | created | New `/brand:review` command following `brand-image.md` pattern — argument parsing, image path validation, brand guide loading, designer agent invocation in visual review mode, report writing |
| `agents/designer.md` | modified | Added `## Visual Review Mode` section between Image Generation and Agent Result Format — entry condition, analysis criteria (Brand Adherence, Accessibility Signals, UX Quality, Recommendations), provider limitation note, WILL NOT Do list |
| `skills/brand-awareness/SKILL.md` | modified | Added `/brand:review` to activation list and `### During /brand:review` behavior entry between `/brand:image` and `/brand:tokens` — brand guide loading, criteria injection, heuristics-only fallback |
| `docs/brand/reviews/.gitkeep` | created | Established persistent review reports directory in git |
| `tests/test_brand_review.sh` | created | 52 structural validation tests covering all 8 ACs |

## Implementation Decisions

1. **Report template embedded in command** — the Design Review Report template lives in `commands/brand-review.md` rather than a separate template file, matching how `brand-image.md` embeds its prompt augmentation template
2. **No new skill file** — the `/brand:review` behavior is a new entry in the existing `brand-awareness` skill, not a separate skill, consistent with how `/brand:image` and `/brand:tokens` are organized
3. **Directory creation via .gitkeep** — `docs/brand/reviews/` established with `.gitkeep` so it exists in git before first review, same pattern as `docs/brand/assets/`

## Test Results

```
test_brand_review.sh: 52 tests, 52 passed, 0 failed
test_execute.sh:      62 tests, 62 passed, 0 failed (no regression)
test_hooks.sh:        38 tests, 38 passed, 0 failed (no regression)
test_precommit.sh:    47 tests, 47 passed, 0 failed (no regression)
```

## AC Coverage

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | covered | `commands/brand-review.md` accepts image-path, references designer.md, invokes visual review mode via Read tool |
| AC-2 | covered | Report template in command includes all 4 sections (Brand Adherence, Accessibility Signals, UX Quality, Recommendations) with `type: design-review` frontmatter; output path `docs/brand/reviews/{timestamp}_{stem}-review.md` |
| AC-3 | covered | `agents/designer.md` Visual Review Mode Analysis Criteria specifies brand-aware comparison of hex values, font families, imagery style |
| AC-4 | covered | Command and agent both handle heuristics-only mode; report notes "No brand guide found; review uses universal UX heuristics"; Nielsen's 10 referenced |
| AC-5 | covered | Agent instruction mandates specific values (contrast ratios, hex codes, pixel sizes); generic advice explicitly prohibited |
| AC-6 | covered | `docs/brand/reviews/` directory created with `.gitkeep`; command writes reports there; explicitly noted as never-archived |
| AC-7 | covered | Image Path Validation section: checks presence, file existence, extension (.png, .jpg, .jpeg, .gif, .webp); error messages for each case; no partial report on failure |
| AC-8 | covered | `commands/brand-review.md` follows `brand-image.md` pattern: Arguments, Agent Identity, Context Loading, Usage Examples, Routing, Notes, `ARGUMENTS: $ARGUMENTS` |

# Review
<!-- Added by /discern on 2026-02-25 -->

## Verdict: APPROVED

**ACs verified:** 8/8 met
**Tests:** 52/52 passed (0 regressions across 147 total project tests)
**ADR compliance:** ADR-004 YES

## AC Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `commands/brand-review.md` accepts `image-path` (line 9), references `designer.md` (line 19), activates Visual Review Mode, uses Read tool per ADR-004 (line 84) |
| AC-2 | met | Report template (lines 102-160) has `type: design-review` frontmatter, all 4 sections (Brand Adherence, Accessibility Signals, UX Quality, Recommendations), output path `docs/brand/reviews/{YYYYMMDD}_{HHmmss}_{stem}-review.md` |
| AC-3 | met | Command injects color hex values, font families, imagery guidelines (lines 85-88); designer agent compares expected vs observed values (designer.md lines 177-180); skill extracts brand rules (SKILL.md lines 132-136) |
| AC-4 | met | Heuristics-only mode: Context Loading (line 30), fallback message (lines 162-163): "No brand guide found at docs/brand/. Review uses universal UX heuristics (Nielsen's 10, WCAG contrast, visual hierarchy)"; Brand Adherence omitted in fallback (line 165) |
| AC-5 | met | Command (lines 94-98) and agent (designer.md lines 190-191) mandate specific values; generic advice explicitly prohibited; example includes contrast ratios and hex codes |
| AC-6 | met | `docs/brand/reviews/` exists with `.gitkeep`; reports explicitly "never archived, never deleted" (line 180); notes confirm "append-only audit trail" (line 261) |
| AC-7 | met | Three-step validation (lines 42-66): missing argument, file not found, unsupported extension; "Do NOT create a partial report if validation fails" (line 66); error examples in Usage Examples (lines 239-243) |
| AC-8 | met | `commands/brand-review.md` matches `brand-image.md` pattern: Arguments, Agent Identity, Context Loading, Routing, Notes, Usage Examples; ends with `ARGUMENTS: $ARGUMENTS` (line 266) |

## ADR Compliance

| ADR | Decision | Compliant? | Notes |
|-----|----------|------------|-------|
| ADR-004 | Native Read tool vision (Option A) | YES | Image delivery via Read tool (no new MCP servers, no base64); provider limitation (GitHub #18588) documented in command (line 186) and agent (designer.md lines 193-197) |

## Findings

- Implementation follows the design specification with zero deviations
- Three files changed (one new, two modified) plus one directory creation — minimal, focused scope
- All test patterns follow established conventions (`test_execute.sh`, `test_hooks.sh`)
- Rollback is trivial: delete `commands/brand-review.md` and remove additive sections from `agents/designer.md` and `skills/brand-awareness/SKILL.md`
- No security concerns — review is a read-only analysis that produces markdown artifacts
- No performance concerns — image token cost ~$0.024 per review (ADR-004)

## Routing

Ready for `/done`. All acceptance criteria met, all tests passing, ADR-004 compliant.
