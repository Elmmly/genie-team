---
type: spike
topic: Image Generation MCP Comparison
created: 2026-02-04
status: complete
genie: architect
prerequisite_for: P1-designer-genie
---

# Spike: Image Generation MCP Comparison

**Goal:** Evaluate OpenAI GPT Image and Google Gemini Nano Banana for Designer genie integration. Determine if we should enable both and select best outcome per request.

---

## 1. Setup

### OpenAI (GPT Image)

```bash
# Get API key from: https://platform.openai.com/api-keys
export OPENAI_API_KEY="sk-..."

# Add MCP server
claude mcp add openai-image -- npx -y image-gen-mcp
```

**Config** (`.claude/settings.json`):
```json
{
  "mcpServers": {
    "openai-image": {
      "command": "npx",
      "args": ["-y", "image-gen-mcp"],
      "env": {
        "OPENAI_API_KEY": "${OPENAI_API_KEY}"
      }
    }
  }
}
```

### Google Gemini (Nano Banana)

```bash
# Get API key from: https://aistudio.google.com/apikey
export GOOGLE_API_KEY="AIza..."

# Add MCP server (if image-gen-mcp supports Gemini)
# OR use a Gemini-specific MCP server
claude mcp add gemini-image -- npx -y @anthropic-ai/mcp-server-google-genai
```

**Config** (`.claude/settings.json`):
```json
{
  "mcpServers": {
    "gemini-image": {
      "command": "npx",
      "args": ["-y", "@anthropic-ai/mcp-server-google-genai"],
      "env": {
        "GOOGLE_API_KEY": "${GOOGLE_API_KEY}"
      }
    }
  }
}
```

### Restart Claude Code
```bash
# Exit and restart to pick up new MCP servers
claude
```

---

## 2. Test Cases

Run each prompt through both providers. Record results in the table below.

### Test Prompts

| ID | Category | Prompt |
|----|----------|--------|
| T1 | Basic | "A golden retriever sitting in a field of sunflowers, photorealistic" |
| T2 | Logo | "Minimalist logo for a coffee shop called 'Morning Brew', blue and orange colors, white background" |
| T3 | Brand-constrained | "Professional hero image for a B2B SaaS landing page, primary color #2563EB, modern and clean, diverse team collaborating" |
| T4 | Illustration | "Flat illustration of a developer working at a desk with multiple monitors, synthwave color palette" |
| T5 | Text rendering | "Social media banner with the text 'Launch Day' in bold, tech startup aesthetic" |
| T6 | Complex scene | "Isometric view of a modern co-working space with plants, natural lighting, people working on laptops" |

### Brand Constraint Test

For T3, use this mock brand spec to augment the prompt:

```yaml
visual:
  colors:
    primary: "#2563EB"
    secondary: "#1E40AF"
    accent: "#F59E0B"
  imagery:
    style: photography
    mood: [modern, clean, professional, human]
    subjects: [diverse teams collaborating, modern workspaces]
    avoid: [stock photo clichés, overly corporate]
```

---

## 3. Evaluation Criteria

Score each result 1-5:

| Criterion | Weight | Description |
|-----------|--------|-------------|
| Quality | 30% | Overall visual quality, artifacts, coherence |
| Prompt adherence | 25% | How well it matches the request |
| Brand alignment | 20% | For T3: Does it match the brand constraints? |
| Text accuracy | 15% | For T5: Is text readable and correct? |
| Speed | 10% | Time to generate |

---

## 4. Results Template

### Test T1: Basic (Golden Retriever)

| Metric | OpenAI GPT Image | Gemini Nano Banana |
|--------|------------------|-------------------|
| Time | ___ s | ___ s |
| Quality (1-5) | | |
| Prompt adherence (1-5) | | |
| Cost | $____ | $____ |
| Notes | | |

**Winner:** ___

### Test T2: Logo (Morning Brew)

| Metric | OpenAI GPT Image | Gemini Nano Banana |
|--------|------------------|-------------------|
| Time | ___ s | ___ s |
| Quality (1-5) | | |
| Prompt adherence (1-5) | | |
| Cost | $____ | $____ |
| Notes | | |

**Winner:** ___

### Test T3: Brand-Constrained (B2B Hero)

| Metric | OpenAI GPT Image | Gemini Nano Banana |
|--------|------------------|-------------------|
| Time | ___ s | ___ s |
| Quality (1-5) | | |
| Prompt adherence (1-5) | | |
| Brand alignment (1-5) | | |
| Cost | $____ | $____ |
| Notes | | |

**Winner:** ___

### Test T4: Illustration (Developer)

| Metric | OpenAI GPT Image | Gemini Nano Banana |
|--------|------------------|-------------------|
| Time | ___ s | ___ s |
| Quality (1-5) | | |
| Prompt adherence (1-5) | | |
| Cost | $____ | $____ |
| Notes | | |

**Winner:** ___

### Test T5: Text Rendering (Launch Day)

| Metric | OpenAI GPT Image | Gemini Nano Banana |
|--------|------------------|-------------------|
| Time | ___ s | ___ s |
| Quality (1-5) | | |
| Text accuracy (1-5) | | |
| Cost | $____ | $____ |
| Notes | | |

**Winner:** ___

### Test T6: Complex Scene (Co-working)

| Metric | OpenAI GPT Image | Gemini Nano Banana |
|--------|------------------|-------------------|
| Time | ___ s | ___ s |
| Quality (1-5) | | |
| Prompt adherence (1-5) | | |
| Cost | $____ | $____ |
| Notes | | |

**Winner:** ___

---

## 5. Aggregate Results

| Provider | Wins | Avg Quality | Avg Speed | Avg Cost |
|----------|------|-------------|-----------|----------|
| OpenAI GPT Image | /6 | /5 | s | $ |
| Gemini Nano Banana | /6 | /5 | s | $ |

---

## 6. Multi-Provider Strategy

### Option A: Single Provider
- Pick the winner, use exclusively
- Simpler implementation
- Single API key to manage

### Option B: Best-of-Both (Recommended if close)
- Generate with both providers
- Present both to user OR auto-select based on criteria
- Higher cost (2x API calls)
- Better outcomes

### Option B Implementation Sketch

```
/design:image [prompt]
    │
    ├─► OpenAI: generate(prompt + brand_context)
    │       └─► image_a.png
    │
    ├─► Gemini: generate(prompt + brand_context)
    │       └─► image_b.png
    │
    └─► Present both OR auto-select by:
            - User preference in brand spec
            - Category heuristics (logos→OpenAI, photos→Gemini)
            - Quality scoring model
```

### Option C: Category Routing
- Route different prompt types to different providers
- E.g., logos → OpenAI, photography → Gemini
- Requires prompt classification

---

## 7. Success Criteria

Spike succeeds if:

| Criterion | Target | Result |
|-----------|--------|--------|
| At least one provider works reliably | >80% success rate | |
| Latency acceptable | <10s average | |
| Brand constraints improve output | Noticeable difference | |
| Cost is reasonable | <$0.50 per test | |

---

## 8. Decision Framework

After completing tests:

| If... | Then... |
|-------|---------|
| One provider clearly wins (>4 point lead) | Use single provider |
| Providers are close (<4 point difference) | Implement Option B (best-of-both) |
| Both fail reliability threshold | Investigate alternative MCP servers |
| Brand constraints don't help | Simplify Designer to prompt-only |

---

## 9. Next Steps

- [x] Obtain OpenAI API key
- [x] Obtain Google API key
- [x] Configure MCP servers
- [x] Run test suite
- [x] Document results
- [x] Make provider recommendation
- [ ] Update P1-designer-genie with findings

---

## 10. Findings

**Full results:** [docs/analysis/20260205_spike_image_mcp_results.md](20260205_spike_image_mcp_results.md)

### Summary

Tested 3 models (OpenAI DALL-E 3, Gemini 2.5 Flash, Gemini 3 Pro) across 6 test cases. Google Gemini models dominated — Gemini 3 Pro won 4/6 tests on quality, Gemini 2.5 Flash won 2/6 on prompt precision. DALL-E 3 won 0/6 and failed critically on text rendering.

### Recommendation

**Cost-tiered routing** — Gemini 2.5 Flash as default (drafts, illustrations, iteration), Gemini 3 Pro for production assets (photography, brand hero images, final deliverables). Single MCP server (`@fastmcp-me/imagegen-mcp`) handles both.

### Impact on Designer Genie

Designer genie agent should implement tier selection logic based on user intent, brand spec style, and workflow phase. Flash for exploration, 3 Pro for delivery.
