---
adr_version: "1.0"
type: adr
id: ADR-004
title: "Multimodal design review image content delivery mechanism"
status: accepted
created: 2026-02-25
decided: 2026-02-25
deciders: [navigator]
domain: genies
spec_refs:
  - docs/specs/genies/multimodal-design-review.md
  - docs/specs/genies/designer.md
backlog_ref: docs/backlog/P3-multimodal-design-review.md
tags: [multimodal, vision, designer, brand-review, image-content]
---

# ADR-004: Multimodal design review image content delivery mechanism

## Context

The `/brand:review` command needs to pass a local image file to the designer agent for visual analysis. The question is HOW the image content reaches the agent's context — this is a mechanistic question with multiple valid approaches, each with different tradeoffs.

Genie-team is a prompt engineering project: all behavior is markdown/YAML. The agent invocation model is `claude -p "/brand:review path/to/image.png"`. The designer agent (at `agents/designer.md`) processes the command and produces the review.

Three mechanisms have been identified:

**A: Native Claude vision (path reference in prompt)**
Claude Code can read and analyze local images when a file path is mentioned in the prompt and the file exists. The `/brand:review` command passes the image path as part of the prompt context; Claude reads the image as a vision content block automatically.

**B: MCP image reader**
An MCP server with an `image_read` tool is added to the project. The `/brand:review` command calls the MCP tool to load the image, then passes the loaded content to the designer agent for analysis.

**C: Base64 encoding in prompt**
A bash pre-step encodes the image file as base64 and injects it into the prompt. The designer agent receives raw base64 data and decodes it for analysis.

**Constraint:** genie-team already uses `@fastmcp-me/imagegen-mcp` for image generation. That server's capabilities (does it support image reading?) need to be verified by the Architect spike before this ADR can be accepted.

## Alternatives Considered

| Alternative | Pros | Cons | Risk |
|-------------|------|------|------|
| **A: Native Claude vision (path in prompt)** | Zero new dependencies; simple; Claude Code already handles image files in context | Requires claude CLI to support image file path in headless `-p` mode; behavior may differ interactive vs. headless | Low if supported; Medium if headless limitation |
| **B: MCP image reader** | Structured tool call; consistent with existing MCP pattern | Requires new MCP server or extended existing server; adds dependency; potential version/auth issues | Medium |
| **C: Base64 in prompt** | No new dependencies; deterministic | Significantly inflates prompt token count for large images; messy implementation in bash; error-prone | High |
| **D: Resize + path reference** | Smaller tokens; native path | Requires imagemagick or similar; adds a processing step | Medium |

## Decision

**Option A: Native Claude vision via Read tool.**

### Spike Results (2026-02-25)

Tested all three spike questions empirically:

1. **Can agents read images via the Read tool?** YES — confirmed. The Designer agent received a test brand card image via `Read` tool and produced a detailed, accurate analysis: correctly identified background color (~#3350A0, close to target #2D4A8E), text content ("Genie Team"), font style (bold sans-serif), lamp icon, and assessed WCAG contrast compliance.

2. **Does `@fastmcp-me/imagegen-mcp` support image reading?** NO — generation only. No `image_read` tool in the manifest.

3. **Token cost per image?** ~1,600 tokens per image (Claude API vision docs). At $15/M output tokens (sonnet), this is ~$0.024 per image review. Negligible.

### Why Option A

- **Zero new dependencies** — uses Claude Code's built-in Read tool, which already supports images
- **Fits prompt-engineering-only constraint** — the `/brand:review` command simply instructs the agent to `Read` the image path
- **Confirmed working** in agent context via Task tool (Designer subagent successfully analyzed a test image)
- **Simple invocation**: `/brand:review path/to/image.png` → agent reads image → produces review report

### Known Limitation

GitHub Issue #18588 documents that Read tool image content may be invisible to the model when using non-native API providers (OpenRouter, AWS Bedrock). This is a provider-level bug, not a Claude Code bug. On native Claude (claude.ai, API direct), images work correctly.

**Mitigation:** Document the provider limitation in `/brand:review` command help text. If a user reports image analysis failures, recommend checking their API provider. Option B (MCP image reader) remains available as a fallback for affected users.

## Consequences

### Positive
- Zero new dependencies — simplest possible implementation
- `/brand:review path/to/image.png` is a straightforward command
- Image content handled natively by Claude Code's existing Read tool
- Implementation is pure prompt engineering (markdown files only)
- Cost is negligible (~$0.024 per image review)

### Negative
- Provider-dependent: may not work on OpenRouter/Bedrock (GitHub #18588)
- No image preprocessing (resize, crop) — large images use more tokens

### Mitigations
- Document provider limitation in command help text
- Option B (MCP reader) available as fallback if needed
- Image token cost (~1,600 tokens) is small relative to analysis output

### Neutral
- Does not affect Design Review Report format or brand guide format
- Does not affect designer agent's analysis logic
- Review quality depends on the vision model capability, not the delivery mechanism

## When to Revisit

- If GitHub #18588 is resolved — provider limitation disappears, Option A becomes universally reliable
- If `@fastmcp-me/imagegen-mcp` adds image reading — Option B becomes trivial to add as alternative
- If review token costs prove prohibitive for very large images (>5MB) — consider Option D (resize pipeline)
- If Claude Code adds explicit `--image` flag for headless mode — simplifies headless invocation path
