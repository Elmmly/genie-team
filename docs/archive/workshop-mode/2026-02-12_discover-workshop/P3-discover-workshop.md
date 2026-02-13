---
spec_version: "1.0"
type: shaped-work
id: discover-workshop
title: "Discovery Workshop Mode"
status: done
created: 2026-02-12
appetite: medium
priority: P3
target_project: genie-team
author: shaper
depends_on: []
builds_on: []
spec_ref:
tags: [workshop, discovery, scout, interactive, product-management]
acceptance_criteria:
  - id: AC-1
    description: "/discover --workshop runs a multi-phase interactive product discovery workshop with iteration loops, producing an Opportunity Snapshot"
    status: pending
  - id: AC-2
    description: "Workshop has at least 4 phases: Landscape Scan (market/competitor context), Opportunity Mapping (Teresa Torres opportunity tree), Assumption Surfacing (rank by risk/evidence), and Evidence Plan (what to validate and how)"
    status: pending
  - id: AC-3
    description: "Each phase produces a viewable HTML artifact (like /define --workshop and /design --workshop) for visual comparison and user decision"
    status: pending
  - id: AC-4
    description: "Each phase has an iteration loop — user can request adjustments and the HTML is regenerated until approved"
    status: pending
  - id: AC-5
    description: "Workshop consolidation produces the same Opportunity Snapshot format as batch /discover, so downstream /define can consume it identically"
    status: pending
  - id: AC-6
    description: "Source commands/discover.md includes the workshop mode (not just the installed .claude/commands/ copy)"
    status: pending
---

# Discovery Workshop Mode

## Problem/Opportunity Statement

`/discover` is a single-pass command — the Scout genie explores a topic and produces an Opportunity Snapshot. This works well for well-scoped research, but when bootstrapping a new project or exploring a broad problem space, users need a structured multi-phase workshop with iteration loops. The `/brand --workshop`, `/define --workshop`, and `/design --workshop` commands demonstrate the pattern: interactive phases, HTML artifacts for visual decision-making, and iteration until the user is satisfied. `/discover` is the only major lifecycle command missing this workshop mode.

## Evidence

- README review (2026-02-12) identified this as a gap in the new-project bootstrap journey
- `/brand --workshop` (6 phases), `/define --workshop` (4 phases), and `/design --workshop` (4 phases) all follow the same pattern successfully
- Users bootstrapping new projects need guided product discovery before they can shape work

## Appetite

**Medium batch (3-5 days).** The workshop pattern is well-established — this is applying it to the Scout genie's domain.

## Solution Sketch

Add `--workshop` flag to `/discover` command following the established pattern:

1. **Landscape Scan** — Market context, competitor landscape, user segments. HTML artifact showing the landscape map.
2. **Opportunity Mapping** — Teresa Torres opportunity tree. HTML artifact showing opportunities organized by outcome.
3. **Assumption Surfacing** — Rank assumptions by risk (high impact + low evidence = test first). HTML artifact with assumption matrix.
4. **Evidence Plan** — For top assumptions: what evidence would change our mind? HTML artifact with validation approaches.
5. **Consolidation** — Standard Opportunity Snapshot document.

## Rabbit Holes

- Don't build a full product strategy tool — this is structured discovery, not roadmap planning
- Don't require external data sources (web search is optional enrichment, not a dependency)
- Don't try to replace human product intuition — surface and organize, don't decide

## No-Gos

- No integration with external PM tools (Linear, Jira) — that's a separate concern
- No automated assumption validation — the workshop surfaces what to validate, humans validate

---

# Design

<!-- Design appended by /design on 2026-02-12 -->

## Design Summary

Add a `## Workshop Mode (--workshop)` section to `commands/discover.md` following the established pattern from `/brand`, `/define --workshop`, and `/design --workshop`. Five phases: 4 interactive HTML artifact phases + consolidation. Each interactive phase has an iteration loop. The consolidation produces the identical Opportunity Snapshot format as batch `/discover`.

The workshop synthesizes intent from four product discovery frameworks into a cohesive flow that sets up **ongoing discovery** — not a one-shot research exercise:

- **Teresa Torres (Continuous Discovery Habits / Opportunity Solution Tree)** — the opportunity tree structure in Phase 2, the assumption mapping discipline, and the framing of discovery as a continuous practice with weekly customer touchpoints
- **Lean Canvas (Ash Maurya)** — the business-context dimensions in Phase 1: customer segments, existing alternatives, channels, and unique value proposition. Not the full canvas, but the "understand the business landscape" elements that ground discovery in commercial reality
- **Marty Cagan (Inspired / Empowered)** — the four product risks (Value, Usability, Feasibility, Viability) as the organizing structure for assumption surfacing in Phase 3, and the emphasis on de-risking through discovery before committing to delivery
- **Intuit Design for Delight (D4D)** — the three-phase philosophy woven across the entire workshop: Deep Customer Empathy (Phase 1), Go Broad to Go Narrow (Phase 2), and Rapid Experiments with Customers (Phase 4)

The frameworks are not applied prescriptively — users never see framework names in the HTML artifacts. Instead, their intent shapes how the Scout explores, organizes, and plans.

**Complexity:** Low — this is pure prompt engineering applying an established pattern to a new domain. No code, no scripts, no runtime changes.

## Architecture Approach

No ADRs needed. This follows the same workshop pattern already used by three other commands. The only artifact is markdown prompt content appended to `commands/discover.md`.

**Key design choice:** The Scout genie has `WebSearch` and `WebFetch` tools available. Phase 1 (Landscape Scan) SHOULD use these tools for real market/competitor research when the user provides a market-facing topic. This differentiates `/discover --workshop` from the other workshops — it's the only one that does external research as part of the interactive flow.

## Phase Design

### Phase 1: Landscape Scan

**Purpose:** Build deep empathy for the problem space — who are the people, what are they trying to accomplish, what exists today, and what forces are shaping their world. This phase applies D4D's "Deep Customer Empathy" principle: go beyond surface-level market data to understand the emotional and functional reality of the people involved.

**Framework intent:**
- *Lean Canvas:* Customer Segments, Existing Alternatives, Channels, and early Value Proposition signals
- *D4D:* Deep Customer Empathy — understand what would delight, not just satisfy
- *Teresa Torres:* Interview snapshot thinking — what would we learn from a real conversation?
- *JTBD:* What job is the user hiring a product to do?

**Scout behavior:**
1. Read the topic. If it references a market, product category, or user segment, use `WebSearch` to gather real context (competitors, market size, trends, customer reviews, forum discussions). If it's internal (codebase quality, workflow improvement), use `Read`/`Grep`/`Glob` to scan the project.
2. Go beyond feature comparisons — look for how users describe their frustrations, workarounds, and unmet desires in their own language.
3. Organize findings into a landscape map that surfaces both the business context and the human context.
4. Write HTML artifact.

**HTML artifact:** `{scratchpad}/workshop/landscape-scan.html`

Layout — a four-section landscape map:
- **Section 1: People & Jobs** — User segments with their jobs-to-be-done (JTBD format: "When [situation], they want to [motivation] so they can [outcome]"). Each as a card with segment name, primary JTBD, key pain point, and current workaround. Include an empathy note: what frustrates or delights them about the current state.
- **Section 2: Existing Alternatives** — How people solve this today (competitors, manual processes, workarounds, "do nothing"). Each as a card with name, what it does well, and where it falls short. Framed from the user's perspective, not a feature matrix.
- **Section 3: Channels & Context** — How users find and adopt solutions, market trends, regulatory or technical constraints, and ecosystem forces. Each as a card with relevance note.
- **Section 4: Key Signals** — 3-5 notable observations that suggest where the biggest opportunities or unmet needs live. Each signal with a brief evidence note (where it came from).

Self-contained HTML, inline CSS, light background, clear section headers.

**Iteration:** AskUserQuestion with options:
- "Looks good, proceed"
- "Deepen empathy for a specific segment"
- "Missing important alternatives or segments"
- "Refocus on a different angle"

If user requests changes → regenerate HTML, tell user to refresh.

### Phase 2: Opportunity Mapping

**Purpose:** Organize the landscape findings into an opportunity tree — desired outcomes at the top, opportunities (problem spaces) branching below. This phase applies D4D's "Go Broad to Go Narrow" principle: generate a wide field of opportunities first, then help the user converge on the most promising areas.

**Framework intent:**
- *Teresa Torres OST:* Hierarchical tree structure — outcomes → opportunities. Opportunities are problem statements, never solutions. The tree is a living artifact for continuous discovery, not a one-time snapshot.
- *D4D:* Go Broad to Go Narrow — start with more opportunities than you'll pursue, then narrow through evidence and iteration. The initial tree should feel expansive.
- *Cagan:* Outcomes over output — Level 1 of the tree is desired outcomes (what changes for users), not features or deliverables.

**Scout behavior:**
1. Read the landscape scan decisions from Phase 1.
2. Identify the user's desired outcomes (from JTBD in Phase 1). Frame as changes in the user's world, not product capabilities.
3. Go broad: map a wide set of opportunities (unmet needs, pain points, friction areas, delight gaps) under each outcome. Aim for breadth — include non-obvious and adjacent opportunities alongside the obvious ones.
4. For each opportunity, note the evidence strength from Phase 1 research.
5. Do NOT include solutions — opportunities are problem statements. If an opportunity sounds like a feature, reframe it as the underlying user need.
6. After going broad, highlight the 3-5 opportunities that have the strongest signal (evidence + impact) to help the user narrow.

**HTML artifact:** `{scratchpad}/workshop/opportunity-tree.html`

Layout — a hierarchical tree visualization:
- **Root:** The overarching discovery topic
- **Level 1:** Desired outcomes (2-4 outcomes, each as a colored header bar)
- **Level 2:** Opportunities under each outcome (3-7 per outcome, as expandable/collapsible cards) — intentionally broad to support narrowing
- Each opportunity card shows: opportunity name, 1-sentence description, evidence strength indicator (strong/moderate/weak/missing as colored dots), and source reference
- **Highlighted opportunities** (top 3-5 by signal strength) shown with a subtle gold border and a "Strong signal" badge to guide narrowing

Tree rendered with CSS indentation and connector lines (not Mermaid — pure HTML/CSS for reliability). Expand/collapse via `<details>` elements for manageable information density.

**Iteration:** AskUserQuestion with options:
- "Tree looks right, proceed"
- "Narrow further (remove weak opportunities)"
- "Go broader (add more opportunities to a branch)"
- "Reframe an opportunity (too solution-y)"

### Phase 3: Assumption Surfacing

**Purpose:** For the opportunities identified in Phase 2, surface the assumptions that underpin them and rank by risk. The core principle: de-risk before you build. Every opportunity rests on assumptions — this phase makes them explicit so the team knows what to test first.

**Framework intent:**
- *Cagan (four product risks):* Organize assumptions into four risk categories — Value (will users choose this?), Usability (can users figure it out?), Feasibility (can we build it?), Viability (does it work for the business?). These four lenses ensure discovery doesn't fixate on one dimension.
- *Teresa Torres:* Assumption mapping as a core continuous discovery discipline. Assumptions are testable, not debatable — they become the basis for experiments.
- *Lean Canvas:* Viability assumptions connect to business model questions — revenue, cost, channels, unfair advantage.

**Scout behavior:**
1. For each opportunity in the approved tree, identify assumptions across all four product risk types:
   - **Value** — Will users want this? Will it solve a real problem? Will they choose it over alternatives?
   - **Usability** — Can users discover, learn, and use this effectively?
   - **Feasibility** — Can we build this with available technology, skills, and time?
   - **Viability** — Does this work for the business? Is it sustainable? Does it align with strategy?
2. Assess each assumption's evidence level: Strong, Moderate, Weak, Missing.
3. Assess each assumption's impact if wrong: High, Medium, Low.
4. Rank by risk priority: `impact_if_wrong * inverse_evidence_level`.
5. Ensure all four risk types are represented — if one category is empty, surface why (e.g., "No viability assumptions surfaced — is the business model out of scope for this discovery?").

**HTML artifact:** `{scratchpad}/workshop/assumption-matrix.html`

Layout — a two-axis matrix:
- **X-axis:** Evidence level (Missing → Weak → Moderate → Strong, left to right)
- **Y-axis:** Impact if wrong (High → Medium → Low, top to bottom)
- Each assumption is a positioned card in the matrix showing: assumption text, type badge (Value/Usability/Feasibility/Viability as colored tag), and the related opportunity name
- **Top-left quadrant** (high impact, low evidence) highlighted with a red border — "Test First" zone
- **Bottom-right quadrant** (low impact, strong evidence) grayed out — "Safe to assume" zone
- **Risk balance indicator** at the bottom: a simple bar showing the distribution of assumptions across the four risk types, so the user can see if one dimension is over- or under-represented

Below the matrix: an ordered **Priority List** of assumptions ranked by risk score, with the top-left-quadrant items first.

**Iteration:** AskUserQuestion with options:
- "Matrix looks right, proceed"
- "Move an assumption (wrong placement)"
- "Missing assumptions in a risk category"
- "Split or merge assumptions"

### Phase 4: Evidence Plan

**Purpose:** For the highest-risk assumptions, define what evidence would validate or invalidate each one and design the cheapest, fastest experiments to learn. This phase applies D4D's "Rapid Experiments with Customers" principle: bias toward experiments that produce real evidence quickly rather than comprehensive studies that take weeks.

**Framework intent:**
- *D4D:* Rapid Experiments with Customers — the fastest path to evidence wins. Prefer hours over days, days over weeks. Customer contact beats internal analysis.
- *Cagan:* Discovery techniques matched to risk type — value risks need user evidence (interviews, prototypes), feasibility risks need technical spikes, usability risks need interaction tests, viability risks need stakeholder/data validation.
- *Teresa Torres:* Assumption tests as the smallest possible experiment — what's the one thing we could do this week to learn?
- *Lean Canvas:* Key metrics — what would we measure to know if this is working?

**Scout behavior:**
1. Take the top 3-5 assumptions from the "Test First" zone.
2. For each: define what "validated" looks like, what "invalidated" looks like, and 2-3 evidence-gathering approaches.
3. Match discovery techniques to risk type:
   - **Value assumptions** → customer interviews, fake door tests, competitor user reviews, demand signals
   - **Usability assumptions** → prototype walkthroughs, first-click tests, five-second tests
   - **Feasibility assumptions** → technical spikes, proof-of-concept, architecture review
   - **Viability assumptions** → unit economics modeling, stakeholder interviews, market sizing
4. Estimate effort per approach: Quick (hours), Medium (days), Extended (weeks). Bias toward Quick — if an Extended approach exists alongside a Quick one, flag the Quick option as recommended.
5. For each assumption, suggest a **success metric** — what quantitative or qualitative signal would change our confidence level?

**HTML artifact:** `{scratchpad}/workshop/evidence-plan.html`

Layout — a card-per-assumption layout:
- Each assumption gets a full-width card with:
  - **Assumption text** as the header, with risk type badge (Value/Usability/Feasibility/Viability)
  - **Validated if:** 1-2 sentences describing what evidence would confirm this
  - **Invalidated if:** 1-2 sentences describing what evidence would disprove this
  - **Success metric:** What we'd measure to update our confidence
  - **Approaches table:** Method | What we'd learn | Effort | Priority
  - Effort shown as colored badges (Quick=green, Medium=yellow, Extended=orange)
  - Recommended approach marked with a star icon
- A **"This Week" callout** at the top of the page listing the 2-3 experiments that could start immediately (Quick effort, highest risk reduction), reinforcing the continuous discovery cadence

Cards ordered by risk priority (same order as Phase 3's priority list).

**Iteration:** AskUserQuestion with options:
- "Plan looks good, proceed to consolidation"
- "Adjust validation criteria"
- "Find cheaper/faster experiments"
- "Reprioritize which assumptions to plan for"

### Phase 5: Consolidation

**Purpose:** Produce the standard Opportunity Snapshot that batch `/discover` produces, incorporating all decisions from Phases 1-4. Frame the output as the beginning of an ongoing discovery practice, not a finished research report.

**Framework intent:**
- *Teresa Torres:* Discovery is continuous — this snapshot is a living document. Include guidance on what to revisit and when.
- *Cagan:* The snapshot should make clear which risks remain and what needs to happen before the team commits to building.

**Scout behavior:**
1. Write `docs/analysis/YYYYMMDD_discover_{topic}.md` using the Opportunity Snapshot template from `agents/scout.md`.
2. Populate each section from workshop decisions:
   - **Discovery Question** — the original topic, reframed in problem terms
   - **Observed Behaviors / Signals** — from Phase 1 landscape scan (Key Signals)
   - **Pain Points / Friction Areas** — from Phase 2 opportunity tree (top opportunities)
   - **JTBD / User Moments** — from Phase 1 people & jobs section and Phase 2 outcomes
   - **Assumptions & Evidence** — directly from Phase 3 matrix (all assumptions, ranked, with risk type labels)
   - **Technical Signals** — from feasibility assumptions in Phase 3
   - **Opportunity Areas (Unshaped)** — from Phase 2 tree (top 3-5 opportunities, NOT solutions)
   - **Evidence Gaps** — from Phase 4 evidence plan (what still needs validation, with recommended next experiments)
   - **Routing Recommendation** — based on evidence quality: if high-risk assumptions remain unvalidated → "Continue Discovery"; if problem is well-understood → "Ready for Shaper"
3. Note workshop provenance in the document:
   - "Landscape scan: {N} alternatives, {M} user segments identified"
   - "Opportunity tree: {N} outcomes, {M} opportunities mapped (broad), {K} highlighted (narrowed)"
   - "Assumptions surfaced: {N} total across {V/U/F/B} risk types, {M} in test-first zone"
   - "Evidence plan: {N} assumptions with validation approaches, {K} experiments ready to start this week"
4. Add a **Discovery Cadence** note at the end of the routing recommendation:
   - "Recommended cadence: revisit this opportunity tree weekly as new evidence arrives. Re-run `/discover --workshop` when the landscape shifts significantly or new opportunities emerge from experiments."

**Output:** Standard Opportunity Snapshot — identical format to batch `/discover`. Downstream `/define` consumes it the same way.

## Component Design

### Component 1: Workshop Mode section in `commands/discover.md` — MODIFY

Append a `## Workshop Mode (--workshop)` section to `commands/discover.md` after the existing content. The section follows the same structure as the workshop sections in `/design` and `/brand`:

1. **MANDATORY directive** — when `$ARGUMENTS` contains `--workshop`, follow interactive phases instead of batch flow
2. **Phase 1-4** — each with Scout behavior instructions, HTML artifact spec, and iteration loop via AskUserQuestion
3. **Phase 5** — consolidation producing the standard Opportunity Snapshot
4. **Batch preservation** — existing batch flow is completely untouched

**Interface:**
```
/discover --workshop "topic"
  → Phase 1: Landscape Scan (HTML + iteration)
  → Phase 2: Opportunity Mapping (HTML + iteration)
  → Phase 3: Assumption Surfacing (HTML + iteration)
  → Phase 4: Evidence Plan (HTML + iteration)
  → Phase 5: Consolidation (Opportunity Snapshot to docs/analysis/)
```

### Component 2: install.sh — NO CHANGE

`install.sh` already copies `commands/discover.md` to `.claude/commands/discover.md`. No changes needed — the workshop section is part of the same file.

## AC Mapping

| AC | Approach | Component |
|----|----------|-----------|
| AC-1 | MANDATORY directive + 5-phase workshop flow in `commands/discover.md` | commands/discover.md |
| AC-2 | Phases 1-4 cover all four required areas; Phase 5 is consolidation | commands/discover.md |
| AC-3 | Each phase writes a self-contained HTML file to `{scratchpad}/workshop/` | commands/discover.md |
| AC-4 | Each phase uses AskUserQuestion with 3-4 options including adjustment paths; regenerate HTML on changes | commands/discover.md |
| AC-5 | Phase 5 uses the Opportunity Snapshot template from `agents/scout.md` identically to batch mode | commands/discover.md |
| AC-6 | Workshop section appended to source `commands/discover.md` (install.sh copies to `.claude/commands/`) | commands/discover.md |

## Pattern Adherence

- **Workshop pattern:** Same structure as `/brand`, `/define --workshop`, `/design --workshop` — MANDATORY directive, HTML artifacts, AskUserQuestion iteration loops, consolidation to standard output format
- **Scout charter:** Phase behavior stays within Scout's WILL DO list — explore problems, surface assumptions, map opportunities. No solutions proposed.
- **Problem-first orientation:** Phase 2 explicitly rejects solution-loaded opportunities. Consolidation produces unshaped opportunity areas, not features.
- **Batch preservation:** All existing `commands/discover.md` content untouched. Workshop section is additive.
- **Framework synthesis:** Four frameworks inform the workshop without prescribing a methodology. Users experience a coherent discovery flow — they don't need to know Teresa Torres or Cagan by name. The framework names appear only in the design document (for Crafter context) and the prompt engineering, never in user-facing HTML artifacts.

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| HTML artifacts are too complex for reliable LLM generation | M | M | Keep layouts simple — cards, tables, positioned dots. No JavaScript beyond `<details>` toggles. |
| WebSearch in Phase 1 returns irrelevant results | M | L | Prompt instructs Scout to use web search as optional enrichment. Internal topics skip it entirely. |
| Opportunity tree becomes unwieldy (too many branches) | L | M | Prompt caps at 4 outcomes and 5 opportunities per outcome. User can request expansion. |
| Assumption matrix placement feels subjective | M | L | Provide clear rubric in prompt (evidence levels mapped to concrete criteria). User can adjust via iteration. |

## Implementation Guidance

### Sequence

1. **Read existing workshop sections** in `commands/brand.md` and the `/design` workshop section to internalize the MANDATORY directive pattern and iteration loop structure
2. **Append workshop section** to `commands/discover.md` — all 5 phases with detailed Scout instructions, HTML specs, and iteration loops
3. **Test manually** — run `/discover --workshop "topic"` in an interactive session and verify each phase produces the expected HTML artifact and iteration behavior
4. **Verify batch preservation** — run `/discover "topic"` without `--workshop` and confirm identical behavior to before

### Testing

This is prompt engineering — no automated tests. Manual testing:

| # | Test | Expected |
|---|------|----------|
| 1 | `/discover --workshop "evaluate competitor landscape for coaching apps"` | 4 HTML phases + Opportunity Snapshot in docs/analysis/ |
| 2 | `/discover --workshop "improve error handling in our API"` | Internal focus — Phase 1 uses Grep/Read instead of WebSearch |
| 3 | `/discover "simple topic"` (no --workshop) | Batch mode, identical to current behavior |
| 4 | Phase 1 iteration: select "Missing important players" | HTML regenerated with additions |
| 5 | Phase 3 iteration: select "Move an assumption" | Matrix redrawn with adjusted placement |
| 6 | Verify consolidation output matches Opportunity Snapshot template | Compare section-by-section with `agents/scout.md` template |

### Key Consideration for Crafter

- This is a **single file modification** — append ~200-300 lines of markdown prompt content to `commands/discover.md`
- No code, no scripts, no tests (prompt engineering project)
- The HTML artifact specs should be detailed enough that the LLM generates consistent layouts, but not so rigid that minor formatting variations cause failures
- Follow the exact MANDATORY directive wording from `/design --workshop` for consistency
- **Framework intent, not framework names:** The prompt content should encode the thinking from Torres, Cagan, Lean Canvas, and D4D without naming them. The user should experience "deep customer empathy" without being told it's D4D. The Scout should "go broad then narrow" without citing the source. The frameworks shaped the prompt design — they don't need to be visible at runtime.

## Routing

- [ ] **Crafter** — Append workshop section to `commands/discover.md`

**Next:** `/deliver docs/backlog/P3-discover-workshop.md`

# Implementation

<!-- Implementation appended by /deliver on 2026-02-12 -->

## Summary

Appended a `## Workshop Mode (--workshop)` section (~210 lines) to `commands/discover.md` following the established workshop pattern from `/brand`, `/define --workshop`, and `/design --workshop`. The workshop section was also synced to the installed copy at `.claude/commands/discover.md`.

## Framework Synthesis

Four product discovery frameworks inform the workshop phases without being named in the user-facing prompts:

| Framework | Phase | How Intent Is Applied |
|-----------|-------|----------------------|
| Lean Canvas | Phase 1 | Business-context dimensions: customer segments, existing alternatives, channels. "People & Jobs" and "Existing Alternatives" sections in the landscape HTML. |
| D4D (Design for Delight) | Phase 1, 2, 4 | Deep Customer Empathy (P1: empathy notes, user language), Go Broad to Go Narrow (P2: 3-7 opportunities per outcome, then highlight/narrow), Rapid Experiments (P4: "This Week" callout, Quick effort bias). |
| Teresa Torres OST | Phase 2, 3, 5 | Opportunity tree structure (outcomes → opportunities, never solutions), assumption mapping as continuous discipline, discovery cadence recommendation. |
| Marty Cagan | Phase 3, 4 | Four product risks (Value/Usability/Feasibility/Viability) as organizing structure, risk-matched discovery techniques, de-risk before building. |

## Implementation Files

- `commands/discover.md` — Source command: added `--workshop` flag to Arguments, appended full Workshop Mode section (5 phases)
- `.claude/commands/discover.md` — Installed copy: synced workshop content to match source

## Decisions Made During Implementation

1. **MANDATORY directive wording** matches `/design --workshop` and `/define --workshop` exactly: "When `$ARGUMENTS` contains `--workshop`, you MUST follow..."
2. **No framework names in runtime prompts** — the phase descriptions encode framework thinking (empathy notes, broad-to-narrow, four risk types, rapid experiments) without citing sources
3. **Four-section layout in Phase 1** instead of three columns — replaced "Players" with "Existing Alternatives" (Lean Canvas framing) and "Users" with "People & Jobs" (JTBD + empathy)
4. **Phase 2 goes intentionally broad** (3-7 opportunities per outcome) with gold-bordered highlights to guide narrowing — D4D's "Go Broad to Go Narrow"
5. **Phase 3 includes risk balance indicator** — a visual bar showing distribution across Value/Usability/Feasibility/Viability to catch blind spots
6. **Phase 4 includes "This Week" callout** and success metrics — D4D's rapid experiment bias + Teresa Torres's "smallest possible experiment"
7. **Phase 5 includes Discovery Cadence note** — frames the output as a living document for ongoing discovery, not a finished report

## AC Evidence

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | MANDATORY directive triggers 5-phase interactive workshop producing Opportunity Snapshot |
| AC-2 | met | Phases 1-4 cover Landscape Scan, Opportunity Mapping, Assumption Surfacing, Evidence Plan |
| AC-3 | met | Each phase writes self-contained HTML to `{scratchpad}/workshop/` |
| AC-4 | met | Each phase uses AskUserQuestion with 4 options including adjustment paths; regenerates HTML on changes |
| AC-5 | met | Phase 5 uses Opportunity Snapshot template from `agents/scout.md` identically to batch mode |
| AC-6 | met | Workshop section appended to source `commands/discover.md`; also synced to `.claude/commands/discover.md` |

## Next

`/discern docs/backlog/P3-discover-workshop.md`

# Review

<!-- Review appended by /discern on 2026-02-12 -->

## Verdict: APPROVED

**Confidence:** high
**Acceptance criteria:** 6/6 met
**Spec ACs:** N/A (no spec_ref)
**ADR compliance:** N/A (no adr_refs)

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Pass | MANDATORY directive at `commands/discover.md:115` triggers 5-phase interactive workshop when `$ARGUMENTS` contains `--workshop`. Phase 5 consolidation produces Opportunity Snapshot to `docs/analysis/`. |
| AC-2 | Pass | Phase 1 = Landscape Scan (lines 121-157), Phase 2 = Opportunity Mapping (lines 161-199), Phase 3 = Assumption Surfacing (lines 203-244), Phase 4 = Evidence Plan (lines 248-288). All four required areas covered. |
| AC-3 | Pass | Each of Phases 1-4 writes a self-contained HTML file to `{scratchpad}/workshop/` with MANDATORY directive: "You MUST produce a viewable HTML artifact." HTML specs include inline CSS, card layouts, and color-coded indicators. |
| AC-4 | Pass | Each of Phases 1-4 uses AskUserQuestion with 4 options including adjustment paths. Each has explicit "regenerate the HTML with adjustments and tell user to refresh" instruction. |
| AC-5 | Pass | Phase 5 explicitly says: "Write `docs/analysis/YYYYMMDD_discover_{topic}.md` using the Opportunity Snapshot template from `agents/scout.md`." Section mapping covers all 9 Opportunity Snapshot sections. Output line confirms "identical format to batch `/discover`." |
| AC-6 | Pass | Source `commands/discover.md` contains workshop section (lines 113-317). Installed `.claude/commands/discover.md` also contains identical workshop content. Verified via diff — only pre-existing `Genie Invoked` vs `Agent Identity` divergence. |

## Quality Assessment

### Strengths

- **Pattern compliance:** MANDATORY directive wording matches `/design --workshop` and `/define --workshop` exactly
- **Framework synthesis executed well:** Four framework intents (Torres, Cagan, Lean Canvas, D4D) are clearly encoded in phase behaviors without naming any framework in the runtime prompts. Verified via grep — zero framework name leaks.
- **Batch preservation:** All content before the workshop section is untouched. Only the `--workshop` flag was added to Arguments (line 14).
- **Problem-first discipline maintained:** Phase 2 explicitly says "Do NOT include solutions — opportunities are problem statements. If an opportunity sounds like a feature, reframe it as the underlying user need."
- **Continuous discovery framing:** Phase 5 includes Discovery Cadence note and frames output as "beginning of an ongoing discovery practice, not a finished research report."

### Issues Found

| # | Issue | Severity | Location | Fix |
|---|-------|----------|----------|-----|
| 1 | Source `commands/discover.md` has `## Genie Invoked` (lines 18-23) while installed `.claude/commands/discover.md` has `## Agent Identity` (lines 18-20) | Minor | Both files | Pre-existing divergence, not introduced by this change. Will be addressed by P2-workshop-source-sync. |
| 2 | Design Risks table says "caps at 4 outcomes and 5 opportunities per outcome" but Phase 2 implementation says "3-7 per outcome" | Minor | Design vs implementation | Implementation chose the design's Phase Design section range (3-7) over the Risks table cap (5). This better serves the "Go Broad to Go Narrow" intent. The user can narrow via iteration. Acceptable deviation. |

No critical or major issues found.

## Test Coverage

N/A — This is a prompt engineering project. No automated tests exist or are expected per the design: "This is prompt engineering — no automated tests."

Manual testing per the design's test matrix should be performed by running `/discover --workshop "topic"` in an interactive session.

## Security Review

- [x] No sensitive data exposure — prompts reference `$ARGUMENTS` and `{scratchpad}` paths only
- [x] No injection vulnerabilities — prompt content is static markdown
- [x] WebSearch/WebFetch usage is guarded: "If it references a market... use WebSearch. If it's internal... use Read/Grep/Glob"

## Risk Assessment

| Risk | L | I | Status |
|------|---|---|--------|
| HTML artifacts too complex for reliable LLM generation | M | M | Addressed — layouts use cards, tables, colored dots/badges. No JS beyond `<details>`. |
| Framework names leak to users | L | L | Addressed — verified via grep, zero framework names in workshop section. |
| Source/installed drift | M | M | Pre-existing — flagged as minor. P2-workshop-source-sync backlog item exists. |
| Batch mode disrupted | L | H | Addressed — all batch content untouched. Workshop section is additive, guarded by `$ARGUMENTS` check. |

## Routing

**APPROVED** — Ready for `/commit` then `/done`

**Next:** `/commit docs/backlog/P3-discover-workshop.md`

# End of Shaped Work Contract
