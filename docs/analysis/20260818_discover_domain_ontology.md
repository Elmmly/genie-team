---
type: discover
concept: knowledge
enhancement: domain-ontology
status: active
created: 2026-08-18
author: scout
reasoning_mode: deep
---

# Opportunity Snapshot: A Domain Ontology That Sticks

## 1. Discovery Question

Even with domain-organized specs, ADRs, and C4 diagrams, the *sense* of intended
architectural practices and the domain's ontology — what things are called, what
they mean, how they relate, what invariants hold — decays across long-haul
autonomous development. How might the ontology be formalized so it persists and
stays authoritative as humans step back from the terminal?

Reframed problem-first: **meaning is the only project knowledge with no
artifact, no loader, and no drift detection.**

## 2. Context Summary

The knowledge architecture today has three deliberate pillars, all healthy:

| Pillar | Artifact | Loader | Drift detection |
|--------|----------|--------|-----------------|
| WHAT the system does | `docs/specs/{domain}/` | spec-awareness skill | AC statuses, /discern verification |
| WHY it's built this way | `docs/decisions/ADR-*.md` | architecture-awareness skill | /diagnose ADR health, /discern compliance |
| STRUCTURE | `docs/architecture/` C4 L1-3 | architecture-awareness skill | /diagnose staleness (>90d), coupling checks |
| **MEANING** | **— none —** | **— none —** | **— none —** |

The closest existing artifacts: a 5-line Vocabulary section in CLAUDE.md
("genies, not agents" + the Kent Beck metaphor), scattered Judgment Rules in
agent definitions, and per-language practices in `stacks/`. No glossary, no
concept model, no naming contract binding docs ↔ code ↔ upstream context.

## 3. Observed Signals / Evidence

**S1 — The upstream context layer invented a different product (strong).**
`docs/context/strategy.md` (written by the upstream context-producer, per its
`updated_by` field) describes Genie Team as a Slack/Jira team-coordination
assistant for knowledge workers — not a Claude Code delivery workflow. With no
authoritative ontology to load, the upstream layer *hypothesized* the domain
from the name alone, and that fiction now sits in the context directory that
every `/discover` run loads as ground truth. This is ontology drift crossing a
system boundary, in production, today.

**S2 — Terminology drift already caused a real loss (strong).**
The genies→agents consolidation (the one vocabulary migration attempted so far)
silently dropped the critic's authorization checklist — recovered only by the
2026-08 hardening audit (`docs/backlog/P0-failure-mode-hardening.md`). When
names migrate without a contract, content attached to the names leaks.

**S3 — Prose conventions decay; structural gates hold (strong).**
The 17-session /insights analysis behind the P0 hardening showed prose
discipline ("the critic should…") drifting under autonomy, while hooks,
schemas, and validators held. The existing Vocabulary section is prose. Any
ontology that is only a document will meet the same fate.

**S4 — Context artifacts without producers go stale (moderate).**
`docs/context/assumptions.md` is an unfilled template (`updated: YYYY-MM-DD`).
An ontology artifact with no lifecycle owner would look like this within a
quarter.

**S5 — Architectural practices live in fragments (moderate).**
"How we intend to build here" is scattered across ADR consequence sections,
design-section notes in archived backlog items, and generic `rules/`. Nothing
compiles accepted decisions into ambient, per-domain practice guidance that a
crafter loads at build time. Evidence: the /deliver flow reads ADRs listed in
`adr_refs` only — practices from unlisted-but-relevant ADRs are invisible.

**S6 — The stakes are rising (strong, directional).**
The active direction (non-coding PM, autonomous builds, upstream push /
write-back) removes the human who currently *is* the ontology. Today Nolan
reconciles "what we meant" in review; the target operating model has no such
person in the loop.

**Counter-evidence considered:** (a) The repo is small enough that frontier
models re-derive much of the ontology from code each session — true today,
but S1 shows re-derivation already fails at the system boundary, and context
windows don't span the portfolio. (b) DDD-style ontologies famously become
shelf-ware — valid; this is the central design risk, not a reason to skip
(see Assumption A1). (c) Maybe specs ARE the ontology — but specs define
behavior per domain; they never define terms, relationships, or invariants
across domains, which is where S1/S2 drift occurred.

## 4. Opportunity Frame (JTBD)

- **When** an autonomous genie starts a phase months into development, **it
  wants to** load what concepts exist, what they're called, and what
  invariants constrain them, **so it can** make locally-correct decisions
  that stay globally coherent.
- **When** the upstream context layer writes strategy/market framing into the
  repo, **it wants to** anchor on the system's real concepts, **so that**
  executive direction and implementation reality don't diverge (S1).
- **When** a non-coding PM reviews a PR, **they want** ACs and reviews phrased
  in a stable shared language, **so that** approval is informed consent rather
  than vocabulary roulette.
- **When** artifacts are refactored or archived, **the team wants** meaning
  attached to names to survive the move (S2).

## 5. Opportunity Areas (Unshaped)

1. **No canonical ontology artifact** — terms, concepts, relationships,
   invariants have no home. (The "fourth pillar" gap.)
2. **No ambient loading** — even the 5-line vocabulary reaches only Claude
   Code sessions; upstream/downstream systems and subagents never see it.
3. **No enforcement loop** — validators check frontmatter structure, never
   meaning; /diagnose detects diagram staleness but not terminology drift;
   nothing lints new artifacts/code against the domain language.
4. **Write-back semantic drift** — status flowing up to the executive layer is
   re-narrated prose (see strategy.md "Recent Delivery"), not
   ontology-anchored facts.
5. **Practices don't compile** — accepted ADR consequences never distill into
   per-domain "intended practices" that load at build time.

## 6. Assumption Map

| # | Assumption | Type | Evidence | Impact if wrong | Priority |
|---|-----------|------|----------|-----------------|----------|
| A1 | An ontology artifact will be maintained only if writes are wired into existing phases (define/design/done), not offered as a new ritual | Viability | Strong (S3, S4; P0 hardening precedent) | High — shelf-ware | Test first |
| A2 | Ambient loading (skill/hook) measurably changes genie output vocabulary and upstream framing | Value | Strong — cross-model production study shows large effects from input-side ontology injection, greatest for project-specific (thin training-coverage) vocabulary; see research addendum | High — artifact without effect | Validated externally; confirm locally |
| A3 | Meaning-drift is mechanically detectable (term usage in new artifacts vs. registry) at useful precision | Feasibility | Strong — Vale-class terminology linting is proven in CI at scale; fits existing validator tiers; see research addendum | Medium — falls back to review-time checks | De-risked |
| A4 | The upstream layer will consume an ontology file if exposed at a known path with a schema | Feasibility | Moderate — push function already keys off repo paths | Medium | Test |
| A5 | A single portfolio-wide ontology format works across projects with different domains | Viability | Weak — only this repo examined | Medium — per-project variance | Defer |

## 7. Architecture Context

- **ADR-001 (thin orchestrator):** the ontology must live in repo files, not
  orchestrator state — consistent with everything else that survived.
- **architecture-knowledge spec:** establishes the pillar pattern (artifact +
  schema + skill + diagnose checks) this would extend; its AC-3 drift
  detection is the template for "meaning drift" checks.
- **`schemas/` + validator pipeline:** the enforcement rails (pre-commit
  tiers, frontmatter validation, crossref checks) already exist to receive an
  ontology schema and a terminology lint.
- **P0-failure-mode-hardening:** the design doctrine to reuse — fire
  automatically, load ambiently, strengthen existing commands; no new rituals.

## 8. Recommended Path

Route to **Shaper** (`/handoff discover shape`) with this framing: *establish
meaning as the fourth knowledge pillar, using the same artifact + schema +
ambient-skill + drift-check pattern the other three pillars already use* —
explicitly NOT a documentation project. Suggested shape boundaries for the
contract: an ontology/glossary schema with a lifecycle owner per phase (who
writes terms, who retires them); ambient loading for genies and a stable path
contract for the upstream layer (fixing S1's class of failure); and at least
one mechanical drift check wired into /diagnose. Appetite guidance: medium —
the risk is over-modeling (full DDD ceremony), and A1 says wiring beats
completeness.

First cheap evidence (this week): correct `docs/context/strategy.md`'s product
description and observe whether the upstream layer's next push preserves or
re-invents it — a direct test of A4 and the write-back loop.

### Files Examined
- CLAUDE.md
- docs/specs/knowledge/architecture-knowledge.md
- docs/specs/knowledge/spec-driven-development.md
- docs/context/strategy.md
- docs/context/assumptions.md
- docs/decisions/ (ADR-000 … ADR-006 scan)
- docs/analysis/20260211_discover_genie_team_responsibility_boundary_v1.md
- docs/backlog/P0-failure-mode-hardening.md
- schemas/ (validator coverage scan)
- agents/scout.md

### Recommended Next Steps
- Read `20260818_research_ontology_embedding_approaches.md` (evidence addendum:
  five schools of practice surveyed; synthesis table maps them onto the
  fourth-pillar pattern)
- `/handoff discover shape` → shaped contract for the fourth-pillar ontology
- Run the strategy.md correction experiment (A4, S1) before shaping completes
- During shaping, decide the lifecycle owner question first — it dominates A1

### Blockers
- None. (Note for Navigator: strategy.md's inaccurate product framing affects
  every future /discover run until corrected — cheap to fix, high leverage.)
