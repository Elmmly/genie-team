---
spec_version: "1.0"
type: spec
id: multimodal-design-review
title: Multimodal Design Review
status: active
created: 2026-02-25
domain: genies
source: define
acceptance_criteria:
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
---

# Multimodal Design Review

## Overview

The multimodal design review capability adds a `/brand:review` command to the Designer genie, enabling vision-model-powered analysis of design artifacts (wireframes, mockups, screenshots, generated images) against brand guides and universal UX heuristics. Review reports are persistent artifacts in `docs/brand/reviews/` that accumulate as an audit trail of design decisions.

This capability addresses the gap identified in the 2026-02-25 discovery analysis: genie-team's Designer genie can create design artifacts but cannot critique them. Vision models (Claude Sonnet, Gemini 2.5 Pro) are now production-ready for this use case. The integration follows ADR-002's established pattern: new `/brand:*` command + existing designer agent in a new mode.

When a brand guide is present, review is brand-contextual — checking specific hex values, font sizes, and imagery guidelines against the artifact. When no brand guide exists, review uses universal UX heuristics (Nielsen's 10 usability heuristics, WCAG contrast ratios, visual hierarchy principles).

## Design Constraints
<!-- Updated by /design on 2026-02-25 from P3-multimodal-design-review -->
- Image delivery mechanism: Option A (native Read tool vision per ADR-004); no new MCP servers; no base64 encoding
- Provider limitation: Read tool image analysis may not work on OpenRouter/Bedrock (GitHub #18588); designer agent includes fallback note in report; native Claude (claude.ai or direct API) is the supported path
- Three files total: one new (`commands/brand-review.md`), two modified (`agents/designer.md`, `skills/brand-awareness/SKILL.md`)
- `commands/brand-review.md` follows the exact section structure of `commands/brand-image.md` (Arguments, Agent Identity, Context Loading, etc.)
- Report output path: `docs/brand/reviews/{YYYYMMDD}_{HHmmss}_{stem}-review.md`; directory created if missing
- Reports are persistent artifacts (never archived) — same persistence rule as brand guides and ADRs
- Image path validation is mandatory before agent invocation: check presence, file existence, and supported extension (.png, .jpg, .jpeg, .gif, .webp)
- Brand-aware review mode activated by brand-awareness skill injection; heuristics-only mode when no brand guide found (no block, no error)
- Recommendations must include specific, measurable values (contrast ratios, hex codes, pixel sizes) — generic advice is prohibited
- Designer agent visual review mode does NOT generate images, modify brand guides, or produce numerical scores

## Implementation Evidence
<!-- Updated by /deliver on 2026-02-25 from P3-multimodal-design-review -->

### Test Coverage
- tests/test_brand_review.sh: 52 test cases covering AC-1, AC-2, AC-3, AC-4, AC-5, AC-6, AC-7, AC-8

### Implementation Files
- commands/brand-review.md: New `/brand:review` command (argument parsing, image validation, brand guide loading, agent invocation, report writing)
- agents/designer.md: Added Visual Review Mode section (entry condition, analysis criteria, provider limitation note)
- skills/brand-awareness/SKILL.md: Added `/brand:review` to activation list and behavior entry (criteria injection, heuristics-only fallback)
- docs/brand/reviews/.gitkeep: Established persistent review reports directory

## Review Verdict

_To be populated by Critic during /discern phase._
