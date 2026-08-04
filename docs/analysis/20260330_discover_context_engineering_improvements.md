---
type: discover
topic: "Context Engineering Improvements for Genie Team"
reasoning_mode: deep
status: active
created: "2026-03-30"
---

# Opportunity Snapshot: Context Engineering Improvements

## Discovery Question

How can genie-team improve context management to (1) load more accurate context that aligns genies to the right approach, and (2) reduce the time and token cost of loading and maintaining that context?

## Observed Behaviors / Signals

### External Landscape (from provided articles)

**Refactoring.fm — "Managing Context for AI Coding" (Luca Rossi):**
- Core thesis: context engineering, not prompt engineering, separates high-performing AI-assisted teams from the rest. "Magical incantations don't substitute for substance."
- Framework: 2x2 matrix — single/multi-player x static/dynamic. Teams should move toward multi-player + dynamic (shared context, automatically fetched).
- Key insight: "What's good for humans is good for AI" — AI amplifies existing organizational knowledge hygiene.
- Four-part agenda: distinguish tasks from procedures, share the "why" not just the "what", identify task-relevant context, keep context small.

**Unblocked — "Context Engineering":**
- Core thesis: "Prompts can shape tone and format, but they do not give models the knowledge they need to solve meaningful engineering problems."
- 8-stage context pipeline: data ingestion → environment learning → memory management → working context identification → intent interpretation → first-pass retrieval → relationship exploration → ranking/de-conflicting/refinement.
- Key challenges: access control, data relationships across systems, conflicting sources, token constraints, memory management, latency vs completeness.
- Claims >98% accuracy through dynamic context pulling from docs, issue trackers, and conversations.

### Internal Signals (genie-team codebase)

- **7 complementary context systems** already exist: session context, CLAUDE.md/rules, agent memory, persistent specs, architecture artifacts, document trail, hook-based state.
- **Hook-based zero-cost state tracking** — shell hooks maintain session state across context compactions with no LLM API calls.
- **Known cost pain**: minimum-turn guard was created after ~$15 wasted on input tokens with zero useful work. Deliver phase is 50-65% of total run cost.
- **ADR-001 trade-off**: "repeated LLM context loading for each process" explicitly listed as a negative of the thin orchestrator approach.
- **ADR-005 mitigation**: SDK-integrated orchestrator enables "session resume across genie phases — context preservation without re-prompting."
- **Empty context templates**: `market.md`, `season.md`, `assumptions.md` exist as scaffolding but are unpopulated — context loading reads files that add no value.
- **Memory system is transitional**: 150-line caps, no semantic retrieval, no cross-genie sharing, no decay/relevance scoring (per 20260321 analysis).

## Pain Points / Friction Areas

1. **Shotgun context loading** — `/context:load` reads everything: all specs, all ADRs, all backlog items, C4 diagrams, stack profiles. Most of this is irrelevant to the current task. Every token loaded is a token paid for.

2. **No task-relevance filtering** — Context is loaded by category (all specs, all ADRs), not by relevance to the task at hand. A genie working on image generation loads auth middleware ADRs.

3. **Redundant re-loading across phases** — Each genie phase (discover → define → design → deliver → discern) starts fresh, re-reading the same CLAUDE.md, rules, specs, and ADRs. The thin orchestrator model (ADR-001) makes this structural.

4. **Context files that add noise** — Empty template files (market.md, season.md, assumptions.md) are loaded but contribute zero signal. Rules files total ~526 lines, always loaded regardless of task.

5. **Agent memory is siloed** — Each genie has its own memory. Scout's knowledge about the codebase can't inform Crafter. Architect's pattern knowledge can't guide Critic. No cross-genie learning.

6. **No context cost observability** — No metrics on how many tokens each context source consumes, or which sources actually influenced the genie's output. Can't optimize what you can't measure.

7. **Static context in a dynamic world** — Context is file-based and manually curated. No automatic retrieval from git history, test results, or recent changes. The "dynamic" quadrant from Rossi's framework is aspirational.

8. **Spec/ADR staleness** — 90-day staleness threshold for C4 diagrams exists but specs and ADRs have no freshness mechanism. Stale context is worse than no context — it misleads.

## JTBD / User Moments

**When** a genie starts a new phase (discover, design, deliver...),
**it wants to** load exactly the context needed to understand the task, constraints, and prior decisions,
**so it can** produce accurate output without wasting tokens on irrelevant information.

**When** an orchestrator runs multiple genie phases in sequence,
**it wants to** preserve relevant context across phase boundaries,
**so it can** avoid re-paying for the same context loading at every transition.

**When** a human reviews genie output that seems misaligned,
**they want to** understand what context the genie had (and didn't have),
**so they can** diagnose whether the issue is missing context, stale context, or wrong interpretation.

**When** context costs are high and rising with project complexity,
**the team wants to** reduce per-task context overhead without sacrificing accuracy,
**so they can** scale usage without proportional cost growth.

## Assumptions & Evidence

### High Risk (test first)

| # | Assumption | Type | Evidence | Impact if Wrong |
|---|-----------|------|----------|-----------------|
| A1 | Task-scoped context loading (loading only relevant specs/ADRs) would significantly reduce token costs | Feasibility | Weak — no measurement of current per-source token costs | High — optimization effort wasted if context is already small |
| A2 | Genies would produce better output with less but more relevant context | Value | Moderate — Rossi's "keep context small" principle + known hallucination patterns with large contexts | High — undermines entire optimization direction |
| A3 | Cross-genie memory sharing would improve downstream phase quality | Value | Weak — no evidence of downstream failures caused by siloed memory | Medium — significant implementation effort for uncertain gain |
| A4 | SDK session resume (ADR-005) will meaningfully reduce re-loading costs | Feasibility | Moderate — SDK migration is in progress, resume API exists | High — if it doesn't work, the structural re-loading problem from ADR-001 persists |

### Medium Risk

| # | Assumption | Type | Evidence | Impact if Wrong |
|---|-----------|------|----------|-----------------|
| A5 | Empty context templates add measurable noise | Usability | Moderate — templates exist, are loaded, but have no content | Low — trivial to skip empty files |
| A6 | Context cost observability would enable meaningful optimization | Value | Moderate — can't optimize without measurement, but team may not act on data | Medium — effort to build instrumentation with uncertain follow-through |
| A7 | Semantic/vector retrieval for agent memory would outperform file-based memory | Feasibility | Moderate — 20260321 analysis evaluated options, but no prototype tested | Medium — adds dependency complexity for uncertain gain |

### Lower Risk

| # | Assumption | Type | Evidence | Impact if Wrong |
|---|-----------|------|----------|-----------------|
| A8 | Git history and recent changes could serve as dynamic context | Value | Strong — Unblocked's pipeline model + obvious utility of "what changed recently" | Low — incremental improvement |
| A9 | Spec/ADR staleness detection would prevent misalignment | Value | Moderate — 90-day threshold exists for C4 but not specs/ADRs | Low — easy to add, minimal downside |

## Technical Signals

- **SDK migration (P0-typescript-sdk-migration)** is the primary technical enabler — session resume, phase prompt construction with context injection, and `settingSources` configuration are all in-flight.
- **Hook system** already demonstrates zero-cost context maintenance — pattern could extend to context relevance scoring.
- **Agent memory landscape analysis** (20260321) evaluated vector DB options (sqlite-vec, LanceDB, ChromaDB) but no prototype exists.
- **Context protocol** for external systems (Cataliva scoping) shows the team has already thought about context boundaries — topic files with frontmatter as the interface.

## Opportunity Areas (Unshaped)

### O1: Task-Scoped Context Loading
Instead of loading all specs, ADRs, and context files, use the backlog item's `spec_ref`, `adr_refs`, and domain to load only relevant context. The backlog item already has this metadata — it's just not used for scoping.

### O2: Context Cost Instrumentation
Measure token cost per context source per phase. Surface in session summaries. Enable data-driven pruning of low-value context sources. Could be a hook that counts tokens per file read.

### O3: Phase-to-Phase Context Handoff
Rather than each phase re-loading from scratch, produce a structured handoff artifact that carries forward the relevant context subset. `/handoff` command exists but doesn't optimize for token efficiency.

### O4: Context Relevance Scoring
Before loading a context file, score its relevance to the current task (by keyword overlap, backlog item references, or recency). Skip files below a threshold. Start with a simple heuristic before investing in semantic retrieval.

### O5: Cross-Genie Memory Index
Create a shared memory index that genies can query without loading all other genies' full memories. A lightweight "what does Scout know about X?" lookup.

### O6: Dynamic Context from Git
Auto-generate a "recent changes relevant to this task" context snippet from git log, filtered by files/directories related to the backlog item. Zero manual curation.

## Evidence Gaps

1. **No token-per-source measurement** — We don't know how many tokens each context source consumes. Before optimizing, measure. Recommended experiment: instrument one `/deliver` run to log token counts per file read. (Quick — hours)

2. **No A/B on context scoping** — We haven't tested whether scoped context produces better or worse genie output. Recommended experiment: run the same task twice — once with full context, once with task-scoped context — and compare output quality. (Medium — days)

3. **SDK resume effectiveness unknown** — ADR-005 promises context preservation, but the SDK migration is in-progress. Recommended experiment: once Slice 13+ is complete, measure token savings from session resume vs. fresh start. (Medium — blocked on SDK progress)

4. **Cross-genie memory value unproven** — No evidence that siloed memory has caused downstream failures. Recommended experiment: review critic feedback on delivered items — are rejections traceable to context that another genie had but the delivering genie lacked? (Quick — hours)

## Routing Recommendation

**Continue Discovery → then Ready for Shaper** on specific opportunities.

The highest-leverage next step is **evidence gathering on A1 (context cost measurement)**. Without knowing where tokens are spent, optimization is guesswork.

Recommended sequence:
1. **Quick spike**: Instrument a `/deliver` run to measure token-per-source costs (validates A1, informs O1/O2)
2. **Define O1 (Task-Scoped Context Loading)** if measurement confirms significant waste — this has the best cost/value ratio and uses metadata that already exists in backlog items
3. **Defer O5 (Cross-Genie Memory)** until evidence of cross-genie context failures exists (validates A3)
4. **Monitor SDK migration** for O3 (Phase-to-Phase Handoff) — ADR-005 may solve this structurally

The SDK migration (P0-typescript-sdk-migration) is the tectonic shift. Many context inefficiencies are structural consequences of the thin orchestrator model (ADR-001) that the SDK-integrated orchestrator (ADR-005) is designed to address. Time context improvements to land after or alongside the SDK work.

**Discovery cadence**: Revisit this opportunity tree after the token measurement spike and after SDK Slice 13+ lands. Re-run `/discover` when new evidence from experiments changes the priority ordering.

## Architecture Context

- **ADR-001 (Thin Orchestrator)**: Root cause of repeated context loading — each CLI process starts fresh. Accepted trade-off at the time.
- **ADR-005 (SDK-Integrated Orchestrator)**: Direct response to ADR-001's context loading cost. Session resume is the key mechanism.
- **ADR-003 (Extended Thinking)**: Cost-aware thinking budget (`budget_tokens: 5000`) shows precedent for token-cost optimization in the project.

## Workshop Provenance

N/A — batch discovery mode.

## Sources

- Luca Rossi, "Managing Context for AI Coding", Refactoring.fm (2026)
- "Context Engineering", Unblocked blog (2026)
- Genie-team codebase analysis (7 context systems, 6 ADRs, 18+ analysis documents)
- Prior discovery: `docs/analysis/20260321_discover_ai_agent_memory_knowledge_management_landscape.md`
