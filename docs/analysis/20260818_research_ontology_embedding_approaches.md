---
type: discover
concept: knowledge
enhancement: domain-ontology
status: active
created: 2026-08-18
author: scout
reasoning_mode: deep
---

# Research: Approaches to Embedding an Ontology in Agentic Development Flows

Evidence addendum to `20260818_discover_domain_ontology.md`. External survey of
how teams and platforms make domain ontologies operative (not documentary) in
AI-agent workflows, August 2026.

## The five schools of practice

### 1. Steering / constitution files (spec-driven development tooling)
Repo-committed markdown auto-injected into every agent interaction. Kiro's
steering topology (`product.md`, `structure.md`, `tech.md`) covers purpose,
stack, and naming/structure conventions; the AGENTS.md / constitution
convention commits durable decisions (language, testing, security, dependency
policy) as always-loaded context, sometimes as structured EARS statements.

- **Embedding mechanism:** input-side, always-on prompt injection.
- **Strength:** zero infrastructure; matches how agents already consume context.
- **Weakness:** prose with no enforcement or drift detection — the school is
  silent on maintenance. This is genie-team's current de-facto approach
  (CLAUDE.md vocabulary + rules/) and its observed failure mode (S3).

### 2. Enterprise operational ontology as control plane
The heavyweight end: a typed world model — entities, relationships, allowable
states, permitted verbs — that *intercepts* agent plans and validates them
against business logic before execution, with security policies applied to
agent actions identically to human actions. Decisions decompose into
data/logic/action/security.

- **Embedding mechanism:** runtime validation gate between reasoning and action.
- **Portable lesson:** ontology as **executable contract**, not documentation.
- **Non-portable:** a platform-scale control plane contradicts ADR-001 (thin
  orchestrator, repo files as state). The gate concept maps to /discern, not
  to a runtime layer.

### 3. Ontology-constrained agents (neurosymbolic, measured)
Production research (650+ agents, 22 verticals): three-layer ontology (role /
domain / interaction) serialized to a ~2,800–3,200-token budget and injected
input-side per task. Cross-model results (1,800 runs incl. Claude Sonnet):
large significant effects on metric accuracy and role consistency. Two
findings matter most here:

- **Inverse parametric knowledge effect:** grounding value is inversely
  proportional to the model's training-data coverage of the domain. Genie-team
  vocabulary (genie, shaped contract, appetite, discern verdicts) is exactly
  the thin-coverage case where injection pays most.
- **Don't over-invest in common terms:** terminological fidelity showed no
  pairwise improvement for well-known vocabulary — models already know what a
  "PR" is. Budget the ontology for *project-specific* meaning.
- Output-side validation (checking generated artifacts against the ontology)
  remains unimplemented research even there — input-side coupling is the
  proven mechanism.

### 4. Knowledge-graph memory (MCP servers)
Codebase-indexing KGs (Tree-sitter based, structural queries at ~120x token
efficiency), conversation-derived graphs (Graphiti), and the official MCP
memory server. Agents query entities/relationships on demand instead of
loading documents.

- **Embedding mechanism:** tool-retrieved, on-demand.
- **Strength:** relationships are first-class; scales past context windows.
- **Caution for genie-team:** external mutable state as source of truth
  violates the docs-in-git doctrine. Viable later as a **derived index built
  from repo files**, never as the canonical store.

### 5. Terminology enforcement in CI (DDD ubiquitous language, mechanized)
The DDD playbook operationalized: maintain a glossary, rename code to match,
and lint rogue terms. Vale (prose linter) enforces custom terminology rules in
git hooks and CI; teams use it to block discouraged terms and enforce
canonical ones ("user" vs "account" vs "member") before merge.

- **Embedding mechanism:** validator in the commit/CI path.
- **Direct relevance:** this is precisely the missing "meaning drift"
  detector, and it fits the existing pre-commit tier pipeline. Upgrades
  assumption A3 from Weak to Strong — the tooling exists and is proven.

## Cross-cutting pattern: "active ontology"
The 2026 enterprise framing: static definitions drift within ~30 days; an
ontology must stay bound to live signals (lineage, ownership, governance) to
remain trustworthy. Confirms A1 — maintenance wiring, not artifact quality,
is the survival variable.

## Synthesis for genie-team

The schools compose rather than compete, and map cleanly onto the existing
fourth-pillar pattern:

| Pillar element | School | Concrete form here |
|----------------|--------|--------------------|
| Artifact | 1 | `docs/context/ontology.md` (or per-domain) with schema: terms, definitions, relationships, invariants, aliases-deprecated |
| Ambient loading | 3 | Skill/hook injects a token-budgeted serialization; prioritize project-specific terms (inverse-parametric finding); expose stable path for the upstream context layer |
| Drift detection | 5 | Vale-style terminology lint in the validator tiers + /diagnose "meaning drift" check (deprecated terms in new artifacts, code identifiers vs. glossary) |
| Gate | 2 (lesson only) | /discern checks new concepts introduced by an implementation against the ontology — flag unregistered domain nouns |
| Lifecycle | active-ontology | Writes wired into /define (new terms), /design (relationships/invariants), /done (retirement); staleness threshold like diagrams' 90d |
| Later option | 4 | Derived KG index over docs/ for query efficiency — build artifact, not source of truth |

**What the evidence rules out:** a standalone glossary document (school 1
alone — proven to drift), a runtime control plane (school 2 wholesale —
contradicts ADR-001), and canonical state outside git (school 4 as primary).

## Sources
- [Ontology-Constrained Neural Reasoning in Enterprise Agentic Systems (arXiv 2604.00555)](https://arxiv.org/html/2604.00555v2)
- [Why Ontology Matters for Agentic AI in 2026](https://kenhuangus.substack.com/p/why-ontology-matters-for-agentic)
- [Palantir: The Ontology system](https://www.palantir.com/docs/foundry/architecture-center/ontology-system) and [Connecting Agents to Decisions](https://blog.palantir.com/connecting-agents-to-decisions-277dee8ddb40)
- [Active Ontology: 2026 enterprise pattern](https://atlan.com/know/what-is-active-ontology/)
- [Kiro steering / spec-driven development guide](https://medium.com/@arnab.kg.co.in/mastering-kiro-the-definitive-guide-to-spec-driven-ai-development-b14e82ff4ea5) and [SDD tools comparison](https://www.infoworld.com/article/4171332/four-cutting-edge-tools-for-spec-driven-development.html)
- [codebase-memory-mcp](https://deusdata.github.io/codebase-memory-mcp/), [Graphiti + FalkorDB MCP memory](https://www.falkordb.com/blog/mcp-knowledge-graph-graphiti-falkordb/)
- [Vale terminology linting](https://getstream.io/blog/linting-documentation-with-vale/), [Datadog's Vale workflow](https://www.datadoghq.com/blog/engineering/how-we-use-vale-to-improve-our-documentation-editing-process/), [Ubiquitous Language pattern for agentic coding](https://aipatternbook.com/ubiquitous-language)
