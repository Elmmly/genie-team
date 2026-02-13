---
type: discover
topic: "workflow-guidance-gaps"
status: active
created: "2026-02-13"
---

# Opportunity Snapshot: Workflow Guidance Gaps

## 1. Discovery Question

**Original:** Field report from brand implementation workflow identifies context-aware phase guidance, contract flexibility, and visual validation gaps. Validate and map opportunities.

**Reframed:** When the genie workflow encounters design-heavy or mechanical work, where does it fail to guide the operator toward the right next step — and how does that failure propagate into rework?

## 2. Observed Behaviors / Signals

**Source:** Field report from ~48hrs of genie-driven brand implementation (Feb 11-12, 2026). 6 contracts, 10 commits, 70+ files touched. Post-Designer genie addition.

Validated against codebase — all claims substantiated:

- **Workshop HTML artifacts are write-only.** The `/brand` workshop generates 5+ HTML preview files (`palette-options.html`, `typography-preview.html`, `imagery-moodboard.html`, etc.) to `docs/brand/assets/`. Brand-awareness skill's loading pattern (`SKILL.md` L72-81) scans `docs/brand/*.md` and `tokens.json` but never surfaces HTML files. `/context:load` (`SKILL.md` L208-221) reports brand guide status and token count but not workshop artifacts. They are invisible to all subsequent sessions.

- **Brand spec schema has a structural gap for multi-theme work.** The `brand-spec.schema.md` defines a single color set: `primary`, `secondary`, `accent`, `background`, `foreground`, `semantic`, `palette`. The Designer template (`agents/designer.md` L85-131) matches this. But for multi-theme apps, the workshop produced per-theme color maps (background, card, elevated, input, border, text) — a structure that doesn't exist in the schema. The schema's `accent` field captures one global accent color; per-theme accent/signature colors have nowhere to live.

- **Skills inject data, not guidance.** Brand-awareness activates during `/deliver` (`SKILL.md` L164-183) to surface token values and during `/discern` (`SKILL.md` L185-206) to add Brand Compliance hex-value checking. But neither phase injects process guidance — no "you should visually verify" reminder, no "workshop artifacts exist, reference them" suggestion. All three awareness skills (brand, spec, architecture) follow the same pattern: surface data at activation points, no contextual next-step suggestions.

- **`/handoff` is generic.** The handoff command (`handoff.md`) summarizes what was done and provides a static template per transition (discover→define, define→design, etc.). It doesn't inject domain-specific guidance. A design→deliver handoff looks identical whether the work is CSS theming or API refactoring.

- **One contract template for all work types.** `shaped-work-contract.schema.md` requires `appetite`, `acceptance_criteria`, and free-form narrative. The example shows full product discovery framing (Problem, Appetite & Boundaries, Solution Sketch, Risks & Assumptions). No `work_type` discriminator. No lightweight variant for mechanical/migration tasks.

- **`/bugfix` has no spec integration.** `bugfix.md` accepts an issue description and optional `--urgent`/`--test-only` flags. No `--spec` parameter. No mechanism to auto-populate from spec drift. It's a standalone quick-fix path disconnected from the spec/brand/ADR artifact system.

- **Critic validates code, not appearance.** `/discern` brand compliance (`SKILL.md` L185-206) checks hex values and font families against the brand guide. It does not require or suggest visual evidence (screenshots, dev server inspection). For design work where correctness is visual, this means the Critic can approve code that looks wrong.

## 3. Pain Points / Friction Areas

**P1: Rework from lost visual intent.** The workshop→implementation gap caused 2 follow-up fix contracts (4 visual issues, ~20 lines CSS each) that required full lifecycle passes. Root cause: workshop HTML artifacts were treated as ephemeral, YAML captured surface values but not accent/signature colors, and no step between design and delivery validated visual appearance.

**P2: Process overhead for spec-driven corrections.** When a fix is "CSS variable X doesn't match brand guide value Y," the only paths are full `/feature` lifecycle or `/bugfix` (which doesn't reference specs). No lightweight "correct against spec" path exists.

**P3: Template friction for mechanical work.** 5 of 6 genie-driven brand contracts were mechanical migrations (replace hex values, bundle fonts, align chart colors). Product discovery framing (JTBD, riskiest assumptions, bet framing) was irrelevant but unavoidable — the template has no alternative.

**P4: Non-code artifact drift without tracking.** Workshop HTMLs became stale immediately after the first implementation changed theme values. Design tokens drifted from the brand guide until manually regenerated. `/context:refresh` detects brand guide vs. tokens timestamp drift (`SKILL.md` L223-237) but not HTML workshop artifacts.

**P5: Operator trusted the system and the system didn't warn.** Every pain point traces to the operator following the prescribed workflow correctly while the tooling failed to surface context or suggest next steps. The operator's "errors" were trusting the system.

## 4. JTBD / User Moments

**Primary Job:** "When I'm implementing design-heavy work through the genie lifecycle, I want the system to tell me what extra steps this type of work requires so I can avoid rework from missed context."

**Secondary Job:** "When I need to correct a value that doesn't match a spec, I want a lightweight path to fix and verify it so I don't spend more process time than coding time."

**Tertiary Job:** "When my work is a mechanical migration (replace N values across M files), I want a contract format that fits the work so I don't waste effort on irrelevant product discovery framing."

## 5. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| Skills have the information needed to provide contextual guidance | feasibility | high | Brand-awareness already detects brand work, activates during relevant commands, and has access to all artifact paths. The detection infrastructure exists. | Skills currently only surface data, never process suggestions. Adding guidance means expanding the skill pattern. |
| Workshop HTML artifacts are valuable reference material | value | high | Field report: accent colors visible in HTML compositions were lost because YAML didn't capture them. 2 fix contracts resulted. | HTML files are snapshots — they don't update when values change. They may give false confidence if stale. |
| A `work_type` field would reduce template friction | usability | medium | 5/6 brand contracts were mechanical. Product discovery sections were forced/awkward. | Adding work_type creates schema complexity. Shaper must choose correctly. Wrong choice may cause different friction. |
| `/bugfix --spec` would reduce correction overhead | value | medium | 2 follow-up fix contracts (~20 LOC each) took full lifecycle. Spec-driven fixes are mechanically verifiable. | Bugfix is intentionally lightweight. Adding spec integration increases its complexity. Risk of scope creep into a "mini-feature" path. |
| Visual validation would catch design issues pre-merge | value | high | All 4 follow-up visual issues would have been caught by looking at the UI. Critic currently validates hex values, not rendered appearance. | Visual validation is inherently manual (no automated screenshot comparison in the genie stack). It depends on operator discipline. |
| The schema's single-color-set structure is sufficient for multi-theme apps | feasibility | low | Schema has `palette` (extended colors) which could theoretically hold per-theme sets. | Field report shows the workshop produced per-theme color maps that don't fit the schema. The `palette` field is a flat list of name/value pairs, not a theme-indexed structure. |

## 6. Technical Signals

- **Feasibility:** Straightforward for guidance injection (prompt engineering). Moderate for schema evolution (backward compatibility). Straightforward for `/bugfix --spec`.
- **Constraints:**
  - Skills are markdown files — adding guidance is prompt engineering, not code
  - Schema changes affect all existing brand guides — need migration story or backward compatibility
  - `/handoff` is the natural injection point for transition guidance, but it's optional (operators can skip it)
  - `/bugfix` is intentionally minimal — adding features risks losing its "fast path" identity
- **Needs Architect spike:** No. All changes are prompt engineering or schema evolution — no new infrastructure.

## 7. Opportunity Areas (Unshaped)

**OA-1: Context-aware transition guidance.** Skills that have domain awareness could inject process reminders at phase boundaries. The pattern exists (skills activate during commands) but the behavior doesn't (skills surface data, not guidance). This is the highest-leverage opportunity because it addresses P1, P4, and P5 simultaneously and generalizes across all domain-aware skills.

**OA-2: Work-type-aware contract templates.** The shaped work contract could support discriminated variants — `feature` (current full template), `migration` (spec reference + file map + grep-verifiable ACs), `correction` (spec drift fix, minimal framing). This addresses P2 and P3 but requires schema evolution.

**OA-3: Visual validation in the review loop.** For work touching visual appearance, the Critic should gate on visual evidence — not automated screenshots, but operator-provided confirmation that the UI looks correct. This addresses P1 directly but depends on operator discipline.

**OA-4: Multi-theme brand guide structure.** The brand spec schema needs to support per-theme color sets for multi-theme applications. The current single-color-set structure works for single-theme brands but breaks when the workshop produces themed compositions. This is the root cause of the "visual intent lost in translation" problem.

**OA-5: Workshop artifact lifecycle.** Workshop HTML files need minimal lifecycle tracking — surfaced by `/context:load`, flagged for staleness by `/context:refresh`, referenced by brand-awareness during implementation phases. Not full lifecycle management, just visibility.

## 8. Evidence Gaps

- **How common is multi-theme work?** The field report is one data point from a mobile app. If most brand work is single-theme, OA-4 is lower priority than reported.
- **Does visual validation actually work with genies?** The genie can't see the dev server. It can only ask the operator to check. Will operators actually do this, or will they rubber-stamp it?
- **What's the right boundary for `/bugfix`?** Adding `--spec` is small, but the report also suggests auto-population from drift detection. Where does `/bugfix` end and `/deliver` begin?
- **How do other awareness skills experience similar gaps?** The field report focuses on brand-awareness, but spec-awareness and architecture-awareness may have parallel transition guidance gaps. A broader survey would strengthen OA-1.

## 9. Routing Recommendation

- [x] **Ready for Shaper** — Problem understood, opportunities mapped, evidence validated
- [ ] Continue Discovery — Evidence gaps noted but not blocking
- [ ] Needs Architect Spike — No infrastructure questions
- [ ] Needs Navigator Decision — No strategic question

**Rationale:** The field report provides strong evidence (48hrs of real usage, specific pain points with root causes, operator-vs-tooling analysis). All claims validated against codebase. The opportunity areas are clearly separated and independently shapeable. Two natural shaping priorities emerge:

1. **OA-1 (transition guidance)** — Highest leverage, lowest effort, generalizes beyond brand work. Shape first.
2. **OA-2 + OA-3 combined** — Contract flexibility and visual validation address the rework cycle. Shape together because they interact (lightweight correction contracts often arise from missed visual validation).

OA-4 (multi-theme schema) and OA-5 (workshop lifecycle) are supporting improvements that reduce root causes but have narrower impact. Shape after the first two land.

**Suggested next:** `/define docs/analysis/20260213_discover_workflow_guidance_gaps.md` — shape OA-1 first (context-aware transition guidance), then OA-2+OA-3 as a combined contract.
