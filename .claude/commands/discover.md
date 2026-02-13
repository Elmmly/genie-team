# /discover [topic]

Activate Scout genie to explore opportunities and surface assumptions.

---

## Arguments

- `topic` - What to discover (required)
- Optional flags:
  - `--assumptions` - Focus on assumption mapping only
  - `--evidence` - Focus on evidence gathering only
  - `--feasibility` - Include Architect feasibility check
  - `--workshop` - Interactive multi-phase discovery workshop with HTML artifacts

---

## Agent Identity

Read and internalize `.claude/agents/scout.md` for your identity, charter, and judgment rules.

---

## Context Loading

**READ (automatic):**
- CLAUDE.md
- docs/context/system_architecture.md
- docs/context/recent_decisions.md
- docs/decisions/ADR-*.md (scan for ADRs relevant to the discovery topic)
- Any provided telemetry/data

**RECALL (if topic matches past work):**
- Previous discovery on this topic
- Related decisions

---

## Context Writing

**WRITE:**
- docs/analysis/YYYYMMDD_discover_{topic}.md

**UPDATE:**
- docs/context/current_work.md (mark discovery in progress)

---

## Output

Produces an **Opportunity Snapshot** containing:
1. Context Summary - What we know
2. Opportunity Frame - Jobs, outcomes, JTBD
3. Evidence Analysis - Data, quotes, observations
4. Assumption Map - Risky assumptions to test
5. Recommended Path - What to do next
6. Architecture Context - Relevant ADRs that inform the discovery topic (if they exist)

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/discover:assumptions [topic]` | Assumption mapping only |
| `/discover:evidence [topic]` | Evidence gathering only |
| `/discover:feasibility [topic]` | Include Architect feasibility |

---

## Usage Examples

```
/discover "user authentication improvements"
> [Scout produces Opportunity Snapshot]
> Saved to docs/analysis/20251203_discover_auth.md
>
> Key findings:
> - Users frustrated with SSO login failures
> - Token expiry too aggressive
> - No refresh token mechanism
>
> Next: /handoff discover shape

/discover:feasibility "real-time notifications"
> [Scout + Architect collaboration]
> Opportunity identified + technical feasibility assessed
```

---

## Routing

After discovery:
- If ready to scope: `/handoff discover shape`
- If more evidence needed: Continue discovery
- If technically complex: `/discover:feasibility`

---

## Notes

- Problem-first orientation (not solution-first)
- Surfaces assumptions before investment
- Creates document trail for future reference
- Run /context:recall first to avoid duplicate work

---

## Workshop Mode (`--workshop`)

**MANDATORY: When `$ARGUMENTS` contains `--workshop`, you MUST follow the interactive workshop phases below instead of producing a batch Opportunity Snapshot. The final output is identical — an Opportunity Snapshot saved to `docs/analysis/` — but the user participates in key discovery decisions along the way.**

When `$ARGUMENTS` does NOT contain `--workshop`, ignore this entire section and follow the standard batch flow above.

---

### Workshop Phase 1: Landscape Scan

**MANDATORY: You MUST produce a viewable HTML artifact. Do NOT describe the landscape in a text table.**

Build deep empathy for the problem space — who are the people, what are they trying to accomplish, what exists today, and what forces shape their world. Go beyond surface-level market data to understand the emotional and functional reality of the people involved.

1. **Read** the topic from `$ARGUMENTS` (strip the `--workshop` flag). Load all context per the standard Context Loading section above.
2. **Research** the topic:
   - If it references a market, product category, or user segment: use `WebSearch` and `WebFetch` to gather real context — competitors, market size, trends, customer reviews, forum discussions, user complaints. Look for how users describe frustrations and workarounds in their own language.
   - If it's internal (codebase quality, workflow improvement): use `Read`/`Grep`/`Glob` to scan the project for patterns, pain points, and usage data.
3. **Write** an HTML file to the scratchpad directory using the Write tool:

   **File path:** `{scratchpad}/workshop/landscape-scan.html`

   The HTML file MUST be self-contained (inline CSS, no external dependencies) and show a **four-section landscape map**:

   - **Section 1: People & Jobs** — User segments with their jobs-to-be-done. Each as a card with:
     - Segment name
     - Primary JTBD in format: "When [situation], they want to [motivation] so they can [outcome]"
     - Key pain point
     - Current workaround
     - Empathy note: what frustrates or delights them about the current state
   - **Section 2: Existing Alternatives** — How people solve this today (competitors, manual processes, workarounds, "do nothing"). Each as a card with name, what it does well, and where it falls short. Framed from the user's perspective, not as a feature matrix.
   - **Section 3: Channels & Context** — How users find and adopt solutions, market trends, regulatory or technical constraints, and ecosystem forces. Each as a card with relevance note.
   - **Section 4: Key Signals** — 3-5 notable observations that suggest where the biggest opportunities or unmet needs live. Each signal with a brief evidence note (where it came from).

   Layout: Clean card-based sections with clear headers. Light background, readable typography. Cards should be at least 250px wide.

4. **Tell the user** to open the file: `open {scratchpad}/workshop/landscape-scan.html`
5. **Use AskUserQuestion:** "How does this landscape look?" with options:
   - "Looks good, proceed"
   - "Deepen empathy for a specific segment"
   - "Missing important alternatives or segments"
   - "Refocus on a different angle"
6. If user requests changes → **regenerate the HTML** with adjustments and tell user to refresh

**Output:** Locked landscape understanding for the discovery.

---

### Workshop Phase 2: Opportunity Mapping

**MANDATORY: You MUST produce a viewable HTML artifact. Do NOT describe the opportunity tree in a text table.**

Organize the landscape findings into an opportunity tree — desired outcomes at the top, opportunities (problem spaces) branching below. Start broad: generate a wide field of opportunities, then help the user converge on the most promising areas.

1. **Read** the landscape scan decisions from Phase 1
2. **Identify** the user's desired outcomes from the JTBD in Phase 1. Frame as changes in the user's world, not product capabilities.
3. **Go broad:** Map a wide set of opportunities (unmet needs, pain points, friction areas, delight gaps) under each outcome. Include non-obvious and adjacent opportunities alongside the obvious ones. Aim for 3-7 opportunities per outcome.
4. For each opportunity, note the evidence strength from Phase 1 research.
5. Do NOT include solutions — opportunities are problem statements. If an opportunity sounds like a feature, reframe it as the underlying user need.
6. **Highlight** the 3-5 opportunities with the strongest signal (evidence + impact) to guide narrowing.
7. **Write** an HTML file to the scratchpad directory using the Write tool:

   **File path:** `{scratchpad}/workshop/opportunity-tree.html`

   The HTML file MUST be self-contained (inline CSS) and show a **hierarchical tree visualization**:

   - **Root:** The overarching discovery topic
   - **Level 1:** Desired outcomes (2-4 outcomes, each as a colored header bar)
   - **Level 2:** Opportunities under each outcome (3-7 per outcome, as expandable/collapsible cards)
   - Each opportunity card shows:
     - Opportunity name
     - 1-sentence description
     - Evidence strength indicator (strong/moderate/weak/missing as colored dots: green/yellow/orange/gray)
     - Source reference (where the evidence came from)
   - **Highlighted opportunities** (top 3-5 by signal strength) shown with a subtle gold border and a "Strong signal" badge

   Tree rendered with CSS indentation and connector lines (pure HTML/CSS, not Mermaid). Expand/collapse via `<details>` elements for manageable information density.

8. **Tell the user** to open the file: `open {scratchpad}/workshop/opportunity-tree.html`
9. **Use AskUserQuestion:** "How does this opportunity tree look?" with options:
   - "Tree looks right, proceed"
   - "Narrow further (remove weak opportunities)"
   - "Go broader (add more opportunities to a branch)"
   - "Reframe an opportunity (too solution-y)"
10. If user requests changes → **regenerate the HTML** with adjustments and tell user to refresh

**Output:** Locked opportunity tree for the discovery.

---

### Workshop Phase 3: Assumption Surfacing

**MANDATORY: You MUST produce a viewable HTML artifact. Do NOT describe assumptions in a text table.**

For the opportunities in the approved tree, surface the assumptions that underpin them and rank by risk. Every opportunity rests on assumptions — this phase makes them explicit so the team knows what to test first. Organize assumptions into four product risk categories to ensure discovery doesn't fixate on one dimension.

1. For each opportunity in the approved tree, identify assumptions across all four product risk types:
   - **Value** — Will users want this? Will it solve a real problem? Will they choose it over alternatives?
   - **Usability** — Can users discover, learn, and use this effectively?
   - **Feasibility** — Can we build this with available technology, skills, and time?
   - **Viability** — Does this work for the business? Is it sustainable? Does it align with strategy?
2. Assess each assumption's evidence level: Strong, Moderate, Weak, Missing.
3. Assess each assumption's impact if wrong: High, Medium, Low.
4. Rank by risk priority: `impact_if_wrong * inverse_evidence_level`.
5. If any of the four risk categories is empty, note why (e.g., "No viability assumptions surfaced — is the business model out of scope?").
6. **Write** an HTML file to the scratchpad directory using the Write tool:

   **File path:** `{scratchpad}/workshop/assumption-matrix.html`

   The HTML file MUST be self-contained (inline CSS) and show a **two-axis risk matrix**:

   - **X-axis:** Evidence level (Missing → Weak → Moderate → Strong, left to right)
   - **Y-axis:** Impact if wrong (High → Medium → Low, top to bottom)
   - Each assumption is a positioned card in the matrix showing:
     - Assumption text
     - Type badge (Value/Usability/Feasibility/Viability as colored tag — e.g., blue/green/orange/purple)
     - Related opportunity name
   - **Top-left quadrant** (high impact, low evidence) highlighted with a red border — "Test First" zone
   - **Bottom-right quadrant** (low impact, strong evidence) grayed out — "Safe to assume" zone
   - **Risk balance indicator** at the bottom: a simple bar showing the distribution of assumptions across the four risk types, so the user can see if one dimension is over- or under-represented

   Below the matrix: an ordered **Priority List** of assumptions ranked by risk score, with the top-left-quadrant items first.

7. **Tell the user** to open the file: `open {scratchpad}/workshop/assumption-matrix.html`
8. **Use AskUserQuestion:** "How does this assumption matrix look?" with options:
   - "Matrix looks right, proceed"
   - "Move an assumption (wrong placement)"
   - "Missing assumptions in a risk category"
   - "Split or merge assumptions"
9. If user requests changes → **regenerate the HTML** with adjustments and tell user to refresh

**Output:** Locked assumption matrix for the discovery.

---

### Workshop Phase 4: Evidence Plan

**MANDATORY: You MUST produce a viewable HTML artifact. Do NOT describe the evidence plan in a text table.**

For the highest-risk assumptions ("Test First" zone), design the cheapest, fastest experiments to learn. Bias toward experiments that produce real evidence quickly — the fastest path to evidence wins. Match discovery techniques to risk type.

1. Take the top 3-5 assumptions from the "Test First" zone.
2. For each, define what "validated" looks like and what "invalidated" looks like.
3. Design 2-3 evidence-gathering approaches per assumption, matched to risk type:
   - **Value assumptions** → customer interviews, fake door tests, competitor user reviews, demand signals
   - **Usability assumptions** → prototype walkthroughs, first-click tests, five-second tests
   - **Feasibility assumptions** → technical spikes, proof-of-concept, architecture review
   - **Viability assumptions** → unit economics modeling, stakeholder interviews, market sizing
4. Estimate effort per approach: Quick (hours), Medium (days), Extended (weeks). If an Extended approach exists alongside a Quick one, flag the Quick option as recommended.
5. For each assumption, define a **success metric** — what quantitative or qualitative signal would change the team's confidence level.
6. **Write** an HTML file to the scratchpad directory using the Write tool:

   **File path:** `{scratchpad}/workshop/evidence-plan.html`

   The HTML file MUST be self-contained (inline CSS) and show a **card-per-assumption layout**:

   - **"This Week" callout** at the top of the page listing the 2-3 experiments that could start immediately (Quick effort, highest risk reduction)
   - Each assumption gets a full-width card with:
     - **Assumption text** as the header, with risk type badge (Value/Usability/Feasibility/Viability)
     - **Validated if:** 1-2 sentences describing what evidence would confirm this
     - **Invalidated if:** 1-2 sentences describing what evidence would disprove this
     - **Success metric:** What to measure to update confidence
     - **Approaches table:** Method | What we'd learn | Effort | Priority
     - Effort shown as colored badges (Quick=green, Medium=yellow, Extended=orange)
     - Recommended approach marked with a star icon
   - Cards ordered by risk priority (same order as Phase 3's priority list)

7. **Tell the user** to open the file: `open {scratchpad}/workshop/evidence-plan.html`
8. **Use AskUserQuestion:** "How does this evidence plan look?" with options:
   - "Plan looks good, proceed to consolidation"
   - "Adjust validation criteria"
   - "Find cheaper/faster experiments"
   - "Reprioritize which assumptions to plan for"
9. If user requests changes → **regenerate the HTML** with adjustments and tell user to refresh

**Output:** Locked evidence plan for the discovery.

---

### Workshop Phase 5: Consolidation

Produce the standard Opportunity Snapshot incorporating all decisions from Phases 1-4. This snapshot is the beginning of an ongoing discovery practice, not a finished research report.

1. **Write** `docs/analysis/YYYYMMDD_discover_{topic}.md` using the Opportunity Snapshot template from `agents/scout.md`.
2. Populate each section from workshop decisions:
   - **Discovery Question** — the original topic, reframed in problem terms
   - **Observed Behaviors / Signals** — from Phase 1 landscape scan (Key Signals section)
   - **Pain Points / Friction Areas** — from Phase 2 opportunity tree (top opportunities)
   - **JTBD / User Moments** — from Phase 1 People & Jobs section and Phase 2 outcomes
   - **Assumptions & Evidence** — directly from Phase 3 matrix (all assumptions, ranked, with risk type labels)
   - **Technical Signals** — from feasibility assumptions in Phase 3
   - **Opportunity Areas (Unshaped)** — from Phase 2 tree (top 3-5 opportunities, NOT solutions)
   - **Evidence Gaps** — from Phase 4 evidence plan (what still needs validation, with recommended next experiments)
   - **Routing Recommendation** — based on evidence quality: if high-risk assumptions remain unvalidated → "Continue Discovery"; if problem is well-understood → "Ready for Shaper"
3. Note workshop provenance in the document:
   - "Landscape scan: {N} alternatives, {M} user segments identified"
   - "Opportunity tree: {N} outcomes, {M} opportunities mapped (broad), {K} highlighted (narrowed)"
   - "Assumptions surfaced: {N} total across Value/Usability/Feasibility/Viability, {M} in test-first zone"
   - "Evidence plan: {N} assumptions with validation approaches, {K} experiments ready to start this week"
4. Add a **Discovery Cadence** note at the end of the routing recommendation:
   - "Recommended cadence: revisit this opportunity tree weekly as new evidence arrives. Re-run `/discover --workshop` when the landscape shifts significantly or new opportunities emerge from experiments."

**Output:** Standard Opportunity Snapshot — identical format to batch `/discover`. Downstream `/define` consumes it the same way.

ARGUMENTS: $ARGUMENTS
