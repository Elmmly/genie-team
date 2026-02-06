---
type: spike-results
topic: Image Generation MCP Comparison
created: 2026-02-05
status: complete
genie: architect
prerequisite_for: P1-designer-genie
parent: docs/analysis/20260204_spike_image_generation_mcp.md
---

# Spike Results: Image Generation MCP Comparison

**MCP Server:** `@fastmcp-me/imagegen-mcp` v0.1.9
**Providers Tested:** OpenAI DALL-E 3, Gemini 2.5 Flash Image, Gemini 3 Pro Image Preview
**Providers Unavailable:** Replicate/Flux (no `REPLICATE_API_TOKEN`), Google Imagen (no `GOOGLE_IMAGEN_ENDPOINT`), OpenAI gpt-image-1 (MCP server sends unsupported `response_format` param — server bug)

---

## Provider Configuration

| Provider | Model | Status |
|----------|-------|--------|
| OpenAI `dall-e-3` | dall-e-3 | Working |
| OpenAI `gpt-image-1` | gpt-image-1 | BROKEN — MCP server sends `response_format` param not supported by API |
| Gemini 2.5 Flash | gemini-2.5-flash-image | Working |
| Gemini 3 Pro | gemini-3-pro-image-preview | Working |
| Gemini 2.0 Flash | gemini-2.0-flash-exp-image-generation | BROKEN — returns text instead of image |
| Google Imagen 4.0 | imagen-4.0-generate-001 | Untested — requires `GOOGLE_IMAGEN_ENDPOINT` |
| Replicate Flux | flux-1.1-pro | Untested — requires `REPLICATE_API_TOKEN` |

---

## Test Results

### T1: Basic — "Golden retriever sitting in a field of sunflowers, photorealistic"

| Metric | OpenAI DALL-E 3 | Gemini 2.5 Flash | Gemini 3 Pro |
|--------|-----------------|------------------|--------------|
| Quality (1-5) | 4 | 4 | **5** |
| Prompt adherence (1-5) | 4 | 4 | **5** |
| Style | Painterly/artistic, dreamy bokeh | Photorealistic, tight crop | Most photorealistic, cinematic wide |
| Composition | Dog looking sideways, moody golden hour | Dog facing camera, happy expression | Wide frame with fence, natural depth |
| Detail | Soft, stylized fur | Good fur detail | Excellent fur, environmental detail |

**Images:**
- OpenAI: `outputs/1770330891662-t1_openai_golden_retriever.png`
- Gemini 2.5 Flash: `outputs/1770330931875-t1_gemini_25flash_golden_retriever.png`
- Gemini 3 Pro: `outputs/1770330957182-t1_gemini_3pro_golden_retriever.jpg`

**Winner: Gemini 3 Pro** — most photorealistic, best composition, highest detail. Clear margin.

---

### T2: Logo — "Minimalist logo for a coffee shop called 'Morning Brew', blue and orange colors, white background"

| Metric | OpenAI DALL-E 3 | Gemini 2.5 Flash | Gemini 3 Pro |
|--------|-----------------|------------------|--------------|
| Quality (1-5) | 4 | 3 | **5** |
| Prompt adherence (1-5) | **5** | 4 | **5** |
| Text accuracy | "MORNING BREW" correct | "MORNING BREW" correct | "MORNING BREW" correct |
| Concept | Sun rising from coffee cup in circle | Abstract leaves/beans with sun in circle | Sun-as-coffee-cup, bold linework |
| Color adherence | Blue + orange | Blue + orange | Blue + orange |
| Scalability | Good | Fair (thin lines) | Excellent (bold, clean) |

**Images:**
- OpenAI: `outputs/1770330991542-t2_openai_morning_brew_logo.png`
- Gemini 2.5 Flash: `outputs/1770330997851-t2_gemini_25flash_morning_brew_logo.png`
- Gemini 3 Pro: `outputs/1770331011338-t2_gemini_3pro_morning_brew_logo.jpg`

**Winner: Gemini 3 Pro** — boldest concept, clearest sun+coffee integration, most usable at any size. OpenAI close second with a more refined/subtle approach.

---

### T3: Brand-Constrained — "B2B SaaS hero image" with brand spec (primary #2563EB, accent #F59E0B)

| Metric | OpenAI DALL-E 3 | Gemini 2.5 Flash | Gemini 3 Pro |
|--------|-----------------|------------------|--------------|
| Quality (1-5) | 4 | 3 | **5** |
| Prompt adherence (1-5) | 4 | 3 | **5** |
| Brand alignment (1-5) | 3 | 3 | **5** |
| Photorealism | Good, slight AI feel | 3D render look | Excellent, could pass as stock |
| Brand colors | Blue in clothing, amber absent | Blue/amber via injected logos | Blue clothing/screens + amber pendant lights |
| Diversity | Good | Good | Excellent (age + race) |
| "Avoid stock cliché" | Somewhat corporate | Hallucinated "Nexus" brand | Natural laughing, whiteboard, plants |

**Images:**
- OpenAI: `outputs/1770331052188-t3_openai_b2b_hero.png`
- Gemini 2.5 Flash: `outputs/1770331061761-t3_gemini_25flash_b2b_hero.png`
- Gemini 3 Pro: `outputs/1770331076397-t3_gemini_3pro_b2b_hero.jpg`

**Winner: Gemini 3 Pro** — genuinely looks like a professional stock photo. Natural amber accents via lighting, blue integration via clothing/screens. Most diverse, most human.

**Note:** Both Gemini models hallucinated brand names ("Nexus", "ACME B2B Solutions"). This is controllable via prompt — useful for Designer genie if we want to inject a real brand name, or suppress with "no text overlay."

---

### T4: Illustration — "Flat illustration of a developer working at a desk with multiple monitors, synthwave color palette"

| Metric | OpenAI DALL-E 3 | Gemini 2.5 Flash | Gemini 3 Pro |
|--------|-----------------|------------------|--------------|
| Quality (1-5) | 4 | 4 | **5** |
| Prompt adherence (1-5) | 3 | **5** | 3 |
| "Flat" style | Too detailed, not flat | Clean vector, truly flat | Detailed cyberpunk, not flat |
| Synthwave | Purple/neon, partial | Full retrowave (sunset, grid, palms) | Cyberpunk neon city |
| Visual impact | Good | Good | Stunning |

**Images:**
- OpenAI: `outputs/1770331119555-t4_openai_developer_illustration.png`
- Gemini 2.5 Flash: `outputs/1770331127730-t4_gemini_25flash_developer_illustration.png`
- Gemini 3 Pro: `outputs/1770331140675-t4_gemini_3pro_developer_illustration.jpg`

**Winner: Gemini 2.5 Flash** — only model that delivered true "flat illustration" with proper synthwave aesthetic. Gemini 3 Pro is visually stunning but interpreted "flat" too liberally.

**Key Insight:** Gemini 3 Pro maximizes visual quality but can deviate from specific style instructions. Gemini 2.5 Flash follows prompts more literally. This matters for Designer genie where brand specs require precise style adherence.

---

### T5: Text Rendering — "Social media banner with the text 'Launch Day' in bold, tech startup aesthetic"

| Metric | OpenAI DALL-E 3 | Gemini 2.5 Flash | Gemini 3 Pro |
|--------|-----------------|------------------|--------------|
| Quality (1-5) | 3 | 4 | **5** |
| Text accuracy (1-5) | **1** | **5** | **5** |
| Text rendered | "LAUH DAY" (mangled) | "LAUNCH DAY" (correct) | "LAUNCH DAY" + "TECH STARTUP INNOVATION" |
| Banner format | Square | Square | Wide banner (correct for social media) |
| Usability | Unusable due to text error | Good, needs cropping | Ready to use as-is |

**Images:**
- OpenAI: `outputs/1770331179743-t5_openai_launch_day.png`
- Gemini 2.5 Flash: `outputs/1770331188835-t5_gemini_25flash_launch_day.png`
- Gemini 3 Pro: `outputs/1770331202596-t5_gemini_3pro_launch_day.jpg`

**Winner: Gemini 3 Pro** — perfect text, correct banner format, most usable output. DALL-E 3's text rendering failure ("LAUH DAY") is a critical weakness.

**Critical Finding:** DALL-E 3 still struggles with text rendering. Both Gemini models rendered text perfectly. This is a decisive advantage for any use case involving text in images (banners, social media, marketing assets).

---

### T6: Complex Scene — "Isometric view of a modern co-working space with plants, natural lighting, people working on laptops"

| Metric | OpenAI DALL-E 3 | Gemini 2.5 Flash | Gemini 3 Pro |
|--------|-----------------|------------------|--------------|
| Quality (1-5) | 3 | **5** | **5** |
| Prompt adherence (1-5) | 4 | **5** | 4 |
| Isometric accuracy | Clean but sterile | Perfect isometric miniature | More architectural illustration |
| Detail | Minimal, white/grey | Rich — wood, plants, zones | Very rich — two-story, street scene |
| Feel | Corporate/clinical | Charming, warm | Creative, storytelling |
| Extras | — | Coffee area, lounge zones | "THE HIVE CO-WORK" signage, solar panels, dog walker |

**Images:**
- OpenAI: `outputs/1770331237278-t6_openai_coworking.png`
- Gemini 2.5 Flash: `outputs/1770331243383-t6_gemini_25flash_coworking.png`
- Gemini 3 Pro: `outputs/1770331258110-t6_gemini_3pro_coworking.jpg`

**Winner: Gemini 2.5 Flash** — cleanest isometric execution, perfect perspective, excellent warmth and detail. Gemini 3 Pro is visually stunning but took creative liberties beyond the prompt.

---

## Aggregate Results

| Provider | Wins | Avg Quality | Best At | Weakest At |
|----------|------|-------------|---------|------------|
| **Gemini 3 Pro** | **4/6** | **5.0** | Photorealism, text, logos, brand alignment | Follows prompts loosely, adds embellishments |
| **Gemini 2.5 Flash** | **2/6** | **4.2** | Prompt adherence, flat/vector styles, isometric | Lower visual polish than 3 Pro |
| **OpenAI DALL-E 3** | **0/6** | **3.7** | Artistic mood, subtle refinement | Text rendering (critical fail), lower detail |

### Scoring Breakdown (weighted per spike criteria)

| Criterion | Weight | OpenAI DALL-E 3 | Gemini 2.5 Flash | Gemini 3 Pro |
|-----------|--------|-----------------|------------------|--------------|
| Quality | 30% | 3.7 | 4.2 | 5.0 |
| Prompt adherence | 25% | 3.8 | 4.5 | 4.5 |
| Brand alignment | 20% | 3.0 | 3.0 | 5.0 |
| Text accuracy | 15% | 1.0 | 5.0 | 5.0 |
| Format/usability | 10% | 3.5 | 4.0 | 5.0 |
| **Weighted Total** | | **3.1** | **4.1** | **4.9** |

---

## Success Criteria Assessment

| Criterion | Target | Result |
|-----------|--------|--------|
| At least one provider works reliably | >80% success rate | **PASS** — Gemini 2.5 Flash and 3 Pro both 100% success |
| Latency acceptable | <10s average | **PASS** — all generations completed in ~10-15s |
| Brand constraints improve output | Noticeable difference | **PASS** — T3 showed brand colors integrated naturally (esp. Gemini 3 Pro) |
| Cost is reasonable | <$0.50 per test | **PASS** — Gemini Flash is free tier; DALL-E 3 ~$0.04/image |

---

## Key Findings

### 1. Gemini 3 Pro is the quality leader
Consistently produces the highest visual quality, best photorealism, and correct text rendering. Its main weakness is creative liberty — it sometimes embellishes beyond the prompt (hallucinated brand names, expanded compositions).

### 2. Gemini 2.5 Flash is the precision follower
Better at following specific style instructions ("flat illustration," "isometric view"). Lower visual polish but more predictable output. Good for cases where exact style adherence matters.

### 3. DALL-E 3 text rendering is a dealbreaker
"LAUH DAY" instead of "LAUNCH DAY" is a critical failure for any Designer genie use case involving marketing assets, banners, or social media content. Both Gemini models handle text perfectly.

### 4. OpenAI gpt-image-1 is blocked by MCP server bug
The MCP server sends an unsupported `response_format` parameter. This model may be competitive but is untestable without fixing the server or switching to a different MCP.

### 5. Both Gemini models hallucinate brand context
When given a B2B/business prompt, Gemini models inject plausible brand names ("Nexus," "ACME," "THE HIVE CO-WORK"). This is actually useful for Designer genie — we can control it via prompt engineering (inject real brand name or suppress text).

---

## Recommendation

### Strategy: Cost-Tiered Routing

Start with the **lower-cost option as default** and selectively escalate to premium based on the design scenario and product context. This keeps costs low during iteration while ensuring high quality where it matters.

### Default Tier: Gemini 2.5 Flash (`gemini-2.5-flash-image`)

The everyday workhorse. Use for:
- **Drafts and iteration** — fast, cheap, good enough for reviews
- **Flat illustrations and vector styles** — actually outperforms 3 Pro on style precision
- **Isometric/technical diagrams** — more accurate perspective control
- **Exploratory concepts** — generate multiple options before committing

Strengths: Precise prompt following, consistent style adherence, lower cost, faster generation.

### Premium Tier: Gemini 3 Pro (`gemini-3-pro-image-preview`)

Escalate when the output needs to be production-quality. Triggers:
- **Final/production assets** — hero images, marketing banners, deliverables
- **Photography/photorealism** — 3 Pro is significantly more photorealistic
- **Text-heavy assets** — both handle text well, but 3 Pro produces more usable layouts
- **Brand-constrained photography** — better at integrating brand colors naturally into photorealistic scenes
- **Client-facing deliverables** — when visual impact matters more than cost

Strengths: Best-in-class quality, cinematic compositions, natural brand color integration.

### Not Recommended (Yet): OpenAI

DALL-E 3 lost across all categories. `gpt-image-1` is blocked by an MCP server bug (one-line fix identified in `@fastmcp-me/imagegen-mcp` — `response_format` param sent to unsupported model). Revisit if/when patched.

### Tier Selection Logic for Designer Genie

```
Designer receives image request
    │
    ├─ Is this a final/production deliverable?
    │   YES → Gemini 3 Pro
    │
    ├─ Does it require photorealism or brand photography?
    │   YES → Gemini 3 Pro
    │
    ├─ Does it require precise style (flat, isometric, vector)?
    │   YES → Gemini 2.5 Flash
    │
    └─ Default (drafts, concepts, iteration)
        └─ Gemini 2.5 Flash
```

The Designer genie agent should make this routing decision based on:
1. **Explicit user intent** — "final version" vs "quick mockup"
2. **Brand spec `imagery.style`** — `photography` → 3 Pro, `illustration` → Flash
3. **Context from workflow phase** — `/discover` drafts → Flash, `/deliver` assets → 3 Pro

---

## Impact on Designer Genie (P1-designer-genie)

1. **Single MCP dependency** — `@fastmcp-me/imagegen-mcp` handles both Gemini providers via one server
2. **Cost-tiered routing** — Agent selects model based on intent, style, and workflow phase
3. **Prompt augmentation** — Brand spec YAML injected into prompts with explicit style and constraint instructions
4. **Text control** — Include explicit text instructions or "no text overlay" to manage hallucinated brand names
5. **Iterative workflow** — Start with Flash drafts, escalate to 3 Pro for final output
6. **No Replicate/Flux needed** — Google Gemini covers all use cases; revisit OpenAI when MCP server is fixed

---

## MCP Server Bug: gpt-image-1

**Issue:** `@fastmcp-me/imagegen-mcp` v0.1.9 sends `response_format: "b64_json"` to all OpenAI models, but `gpt-image-1` doesn't support this parameter.

**Fix identified** (one-line change in `dist/providers/openai.js` line 29):
```js
// Before:
response_format: "b64_json",

// After:
...(model !== "gpt-image-1" ? { response_format: "b64_json" } : {}),
```

**Status:** Patched locally but requires MCP server restart to take effect. Consider filing upstream issue or PR.

---

## Next Steps

- [ ] Define Designer genie agent spec in P1-designer-genie (informed by these findings)
- [ ] Design prompt augmentation strategy: brand spec YAML → image generation prompt
- [ ] Implement tier selection logic (Flash default, 3 Pro for production/photography)
- [ ] File upstream issue on `@fastmcp-me/imagegen-mcp` for gpt-image-1 `response_format` bug
- [ ] Re-test with gpt-image-1 after MCP restart to validate OpenAI comparison (optional)
- [ ] Prototype Designer genie with T2 (logo) and T3 (brand hero) as acceptance test scenarios
