---
type: opportunity-snapshot
topic: UI/UX Design Agent and Skills
created: 2026-02-03
status: discovered
genie: scout
---

# Opportunity Snapshot: UI/UX Design Agent and Skills for Genie Team

## 1. Context Summary

**What we know:**
- Genie-team currently has 6 genies: Scout, Shaper, Architect, Crafter, Critic, Tidier
- There is no design phase in the current workflow (Scout -> Shaper -> Architect -> Crafter)
- Claude Code can **analyze images** (screenshots, mocks, diagrams) but **cannot generate images**
- P0-multi-agent-provider-framework explored multi-provider integration; found Gemini CLI is Python-native
- MCP servers already exist for bridging Claude Code to image generation APIs

**Current Claude Code Visual Capabilities:**
- Analyze images: JPEG, PNG, GIF (first frame), WebP
- Input methods: clipboard paste, drag-and-drop, file references
- Limits: 100 images/request, 32MB total, 2000x2000px when >20 images
- Use cases: design mock reference, diagram interpretation, text extraction
- **Cannot generate images natively**

---

## 2. Opportunity Frame

### Primary Job-to-be-Done

> "When I'm building a new product or feature, I want to create brand-consistent visual assets so I can maintain professional appearance without hiring a designer for every image."

### Secondary Jobs

1. "When I have a design mock, I want AI to understand my brand context so generated code uses correct tokens and components."
2. "When creating marketing materials, I want to generate images that match our established visual identity."
3. "When reviewing UI implementations, I want design-aware feedback on brand consistency."

### Outcomes Served

| Outcome | Current State | Desired State |
|---------|---------------|---------------|
| Visual asset creation | Manual / external tools | AI-generated, brand-aligned |
| Brand consistency | Tribal knowledge, style guides | Machine-readable brand spec |
| Design-to-code gap | Figma exports, manual translation | Automated token extraction |
| Design review | Human designer needed | AI-assisted brand compliance |

---

## 3. Evidence Analysis

### Image Generation API Landscape (2026)

| Provider | API | Cost | Notes |
|----------|-----|------|-------|
| OpenAI GPT Image 1.5 | REST | $0.011-0.25/image | Best quality, 32K char prompts |
| DALL-E 3 | REST | Varies | **Deprecated May 2026** - migrate away |
| Gemini Imagen | Vertex AI | Varies | Good integration, requires GCP |
| Replicate Flux | REST | Per-second | Popular for MCP, model flexibility |

### Existing MCP Servers for Image Generation

| Server | Backend | Status |
|--------|---------|--------|
| `mcp-image-gen` | Together AI | Production |
| `image-gen-mcp` | GPT Image 1 + Gemini | Production |
| `mcp-imagegen` | Replicate | Production |

**Key insight:** MCP servers already bridge the gap. Integration is possible today without building from scratch.

### Design System / AI Integration Patterns

- **Design Tokens** (W3C Community Group format) are the atomic elements of brand
- Platforms like Typeface, Frontify, Supernova.io demonstrate brand-guided AI generation
- Figma MCP server (official, beta) enables design-to-code with token awareness
- AI-ready brand systems require machine-readable tokens, rules, and metadata

---

## 4. Assumption Map

### Must Test (High Risk)

| # | Assumption | Type | Test Method |
|---|------------|------|-------------|
| A1 | Brand specs can guide AI image generation toward visual consistency | Value | Spike: Generate images with/without brand constraints, compare results |
| A2 | Users will pay for image generation API calls ($0.01-0.25/image) | Viability | User interviews, usage tracking |
| A3 | A Designer genie is distinct enough from Architect to warrant a new role | Value | Map responsibilities, identify unique deliverables |

### Likely True (Medium Risk)

| # | Assumption | Type | Evidence |
|---|------------|------|----------|
| A4 | MCP servers can bridge Claude to image generation | Feasibility | Multiple production servers exist |
| A5 | Design tokens are the right abstraction for brand specs | Usability | Industry consensus, W3C spec |
| A6 | Claude can analyze images to provide design feedback | Feasibility | Documented capability, tested |

### True (Low Risk)

| # | Assumption | Type | Evidence |
|---|------------|------|----------|
| A7 | Claude cannot generate images natively | Feasibility | Anthropic documentation confirmed |
| A8 | External image generation APIs are production-ready | Feasibility | OpenAI, Gemini, Replicate all GA |

---

## 5. Recommended Path

### Option A: Narrow Scope (Small Batch - 1-2 days)
**MCP Integration Documentation Only**
- Document how to install/configure image generation MCP servers
- No new genie, no new artifacts
- Users get capability via existing MCP ecosystem
- **Pros:** Fast, low risk, immediate value
- **Cons:** No brand consistency enforcement, no workflow integration

### Option B: Medium Scope (Medium Batch - 3-5 days)
**Brand Spec Artifact + Image Generation Skill**
- Define `schemas/brand-spec.md` for machine-readable brand definitions
- Create `/design:image` command that uses brand spec to augment prompts
- Extend Critic genie with design-aware review (skill, not separate genie)
- **Pros:** Enables brand consistency, fits existing workflow
- **Cons:** New artifact type, requires brand spec authoring

### Option C: Wide Scope (Big Batch - 2+ weeks)
**Full Designer Genie + Design Workflow Phase**
- New Designer genie with full persona and prompts
- New workflow phase between Shaper and Architect
- Commands: `/design:brand`, `/design:tokens`, `/design:image`, `/design:review`
- Outputs: Brand Spec, Design Tokens, Style Guidelines, Generated Assets
- **Pros:** Comprehensive design practice, clear ownership
- **Cons:** Significant investment, may overlap with Architect

### Recommended: Start with Option B

**Rationale:**
1. Tests the key assumption (A1) that brand specs can guide AI generation
2. Delivers immediate value without heavyweight genie creation
3. Can evolve into Option C if demand warrants
4. Complements (not competes with) P0 multi-provider work

---

## 6. Architecture Context

### Relevant ADRs

**ADR-000: Use ADRs to record architecture decisions**
- If we introduce a brand spec artifact, should we create an ADR for the format?
- Design tokens and brand specs are architectural artifacts that affect multiple domains

### Relationship to P0-multi-agent-provider-framework

The P0 work focused on CLI host abstraction (Claude Code vs Gemini CLI). Image generation is different:
- **P0 Problem:** Different CLI hosts have incompatible conventions (file-based vs Python-native)
- **Design Problem:** Different image APIs are relatively uniform (REST endpoints, similar parameters)

**Recommendation:** Design work does NOT depend on P0. Image generation APIs are more homogeneous than CLI hosts. Could potentially inform a lighter-weight "provider" pattern for APIs vs CLIs.

### Container Diagram Impact

A Designer genie would add to the existing container structure:
```
genies/
├── scout/
├── shaper/
├── designer/    ← NEW (if Option C)
├── architect/
├── crafter/
├── critic/
└── tidier/
```

---

## 7. Evidence Gaps

### Missing Data

1. How effective are existing MCP image generation servers in practice? (Quality, latency, reliability)
2. What does a "good" machine-readable brand spec look like? Need examples.
3. How much do users actually want AI image generation vs. design review/guidance?

### Research Needed

1. **Technical Spike:** Install and test `image-gen-mcp` with Claude Code
2. **Artifact Research:** Review W3C Design Tokens spec for brand spec structure
3. **User Research:** Survey genie-team users on design pain points

---

## 8. Routing

**Discovered → Ready for Shaper**

Problem is understood sufficiently to scope options. Key decisions for Navigator:

1. **Appetite:** Small batch (Option A) vs. medium batch (Option B) vs. big batch (Option C)?
2. **Dependency:** Does this work block on P0-multi-agent-provider-framework?
3. **Scope:** Image generation only vs. full design practice?

**Suggested next command:** `/define docs/analysis/20260203_discover_ux_design_agent.md`

---

## Sources

- [Claude Code Common Workflows](https://code.claude.com/docs/en/common-workflows)
- [OpenAI Image Generation API](https://platform.openai.com/docs/guides/image-generation)
- [OpenAI DALL-E Pricing Calculator](https://costgoat.com/pricing/openai-images)
- [Complete Guide to AI Image Generation APIs 2026 - WaveSpeedAI](https://wavespeed.ai/blog/posts/complete-guide-ai-image-apis-2026/)
- [Design Systems and AI: Why MCP Servers Are The Unlock - Figma Blog](https://www.figma.com/blog/design-systems-ai-mcp/)
- [Guide to the Figma MCP Server - Figma Help](https://help.figma.com/hc/en-us/articles/32132100833559-Guide-to-the-Figma-MCP-server)
- [MCP Image Gen Server - GitHub](https://github.com/sarthakkimtani/mcp-image-gen)
- [Image Gen MCP (GPT Image + Gemini) - GitHub](https://github.com/lansespirit/image-gen-mcp)
- [Design Tokens Explained - Contentful](https://www.contentful.com/blog/design-token-system/)
- [What Are Design Tokens - Supernova.io](https://www.supernova.io/blog/what-are-design-tokens)
