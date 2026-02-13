---
type: discovery
concept: boundaries
topic: genie-team-vs-cataliva-responsibility-separation
status: active
created: 2026-02-11
author: scout
---

# Discovery: Genie Team vs Cataliva Responsibility Boundaries

## The Core Tension

Genie Team has evolved from a "prompt engineering toolkit" into a **fully autonomous PDLC engine** — it now handles the complete discover-through-done lifecycle, session management, parallel execution via worktrees, pre-commit quality enforcement, and CI integration. Meanwhile, Cataliva was originally designed as the "executive layer" that would orchestrate genie-team, but it built its own `services/genie/` (LLM orchestration), its own copilot, its own workflow tracking, and its own delivery automation — creating significant overlap.

The question isn't "which one is better" — it's "where does one end and the other begin?"

---

## Current State: What Each System Owns

### Genie Team (Claude Code Extension)

**Identity:** Structured PDLC methodology engine that extends Claude Code with specialized genies, quality gates, and a document trail.

| Capability | Status |
|-----------|--------|
| 7 specialized genies (Scout, Shaper, Architect, Crafter, Critic, Tidier, Designer) | Production |
| 25+ slash commands (7 D's lifecycle + shortcuts + context management) | Production |
| Document trail architecture (specs, backlog, ADRs, architecture diagrams) | Production |
| TDD enforcement, code quality, pattern enforcement (skills) | Production |
| Pre-commit validation pipeline (4 tiers) | Production |
| GitHub Actions CI | Production |
| Autonomous execution (PR mode + trunk-based mode) | Production |
| Parallel sessions via git worktrees | Production |
| Post-compaction context re-injection hooks | Production |
| Brand workshop + AI image generation (Designer genie) | Production |
| CLI contract for external orchestrators (ADR-001) | Production |
| `install.sh` distribution (global, project, prehook) | Production |

### Cataliva (Web Platform)

**Identity:** Innovation operating system for portfolio management and autonomous delivery orchestration.

| Capability | Status |
|-----------|--------|
| Idea capture, classification (Farm Framework: Stage/Zone/Health) | Production |
| Portfolio scoring engine | Production |
| Strategic context (TAM/SAM/SOM, narratives, assumptions) | Production |
| Multi-tenant workspace isolation (PostgreSQL RLS) | Production |
| Event-driven genie orchestration (Kafka triggers, scheduler) | Production |
| Cataliva's own `services/genie/` (LLM dispatch, tool execution) | Production |
| AI copilot for idea refinement | Production |
| GitHub repo linking and execution tracking | Production |
| Change journal (audit trail) | Production |
| Go backend (gRPC + REST), Next.js frontend | Production |
| Observability stack (OpenTelemetry, Jaeger, Prometheus) | Production |

---

## Overlap Zones (Where Boundaries Blurred)

### 1. Genie Orchestration (Critical Overlap)

**Genie Team** has:
- 7 specialized genies with system prompts, tools, and model routing
- Autonomous execution rules (PR mode, trunk-based, worktrees)
- CLI contract for external invocation
- Session management and context persistence

**Cataliva** has:
- `services/genie/` — its own LLM orchestration engine
- Genie Teams config UI (defining teams, triggers, schedules)
- Worker service that processes events and executes workflows
- Tool execution framework for genies

**The overlap:** Both systems define "what a genie is" and "how to run one." Cataliva partially reimplements genie execution rather than purely delegating to genie-team via the CLI contract.

### 2. Discovery

**Genie Team** has:
- `/discover` command with Scout genie (JTBD, assumption mapping, evidence analysis)
- Produces Opportunity Snapshots in `docs/analysis/`

**Cataliva** plans:
- Discovery Engine (Layer 1) — "automated research + member engagement"
- Idea capture with strategic context

**The overlap:** Who initiates and owns discovery? Is Cataliva's idea capture the same as genie-team's `/discover`?

### 3. Workflow Lifecycle Tracking

**Genie Team** tracks lifecycle via:
- Frontmatter status progression: `shaped` → `designed` → `implemented` → `reviewed` → `done`
- Document trail in `docs/backlog/` → `docs/archive/`
- `/genie:status` command

**Cataliva** tracks lifecycle via:
- Farm Framework stages: `Seed` → `Tend` → `Grow` → `Harvest` → `Prune`
- Database records with health/zone/stage metadata
- Dashboard UI with portfolio view

**The overlap:** Two separate status systems tracking the same work through different lenses.

### 4. AI Copilot vs Genies

**Genie Team:** Specialized genies for each phase (Scout for research, Shaper for framing, etc.)

**Cataliva:** General-purpose AI copilot for idea refinement + its own genie dispatching

**The overlap:** Cataliva's copilot does "idea refinement" which overlaps with Shaper's problem-framing and Scout's discovery.

---

## Proposed Boundary: Clean Separation

### Principle: **Cataliva is the Business; Genie Team is the Workshop**

Think of it as a company:
- **Cataliva** = the executive team, board room, portfolio strategy, and business operations
- **Genie Team** = the engineering workshop where products actually get built

### Cataliva Owns (Business Layer)

| Responsibility | Description |
|---------------|-------------|
| **Portfolio strategy** | Which ideas to pursue, kill, or pivot — the investment thesis |
| **Business classification** | Farm Framework (Stage/Zone/Health) — strategic positioning |
| **Scoring and prioritization** | Which opportunities get resources first |
| **Stakeholder engagement** | UI for teams to collaborate, comment, vote on ideas |
| **Business metrics** | TAM/SAM/SOM, revenue models, market analysis |
| **Multi-tenant operations** | Workspace isolation, user management, billing |
| **Execution scheduling** | WHEN to kick off work (time-based, event-based triggers) |
| **Progress dashboard** | Executive view of portfolio health across all products |
| **Audit trail** | Change journal for compliance and forensics |
| **Integration hub** | GitHub linking, analytics (PostHog), auth (OIDC) |

### Genie Team Owns (Workshop Layer)

| Responsibility | Description |
|---------------|-------------|
| **PDLC methodology** | The 7 D's lifecycle, quality gates, structured phases |
| **Specialized genies** | Scout, Shaper, Architect, Crafter, Critic, Tidier, Designer |
| **Code generation** | TDD implementation, tests, refactoring |
| **Technical design** | Architecture, ADRs, C4 diagrams, interface design |
| **Quality enforcement** | Pre-commit hooks, review verdicts, pattern compliance |
| **Document trail** | Specs, backlog items, decisions — the project's memory |
| **Session management** | Context persistence, compaction recovery, parallel sessions |
| **Git operations** | Branches, commits, PRs, worktrees |
| **Brand and design** | Visual identity, image generation, design tokens |

### The Interface Between Them

```
                    CATALIVA (Business)
                    ━━━━━━━━━━━━━━━━━━
                    Portfolio decisions
                    "Build password reset"
                    "P1 priority, medium appetite"
                    "Seed → Tend stage transition"
                            │
                            ▼
                    ┌───────────────┐
                    │  DISPATCH     │  ← Cataliva's ONLY touch point
                    │  INTERFACE    │     with genie-team
                    │               │
                    │  • Work order │  (what to build, priority, appetite)
                    │  • Git repo   │  (where to build it)
                    │  • Callback   │  (how to report completion)
                    └───────┬───────┘
                            │
                            ▼
                    GENIE TEAM (Workshop)
                    ━━━━━━━━━━━━━━━━━━━
                    /define → /design → /deliver → /discern → /done
                    Writes to docs/, commits to git
                    Reports completion via artifacts
                            │
                            ▼
                    ┌───────────────┐
                    │  COMPLETION   │  ← Genie-team's ONLY touch point
                    │  SIGNAL       │     back to Cataliva
                    │               │
                    │  • Status     │  (done, blocked, needs-input)
                    │  • Artifacts  │  (paths to specs, code, tests)
                    │  • Metrics    │  (tests passed, files changed)
                    └───────────────┘
```

---

## What Must Change

### In Cataliva

1. **Remove `services/genie/` as an execution engine.** Cataliva should NOT have its own LLM orchestration for product delivery. It dispatches work orders to genie-team via the CLI contract (ADR-001). Cataliva's genie service becomes a thin dispatch layer, not a reimplementation.

2. **Copilot stays, but scoped to business concerns.** The AI copilot is valuable for idea refinement, strategic framing, and portfolio analysis — that's business intelligence, not PDLC. It should NOT do discovery (that's Scout), problem framing (that's Shaper), or design (that's Architect).

3. **Farm Framework maps TO genie-team phases, not replaces them.** The mapping:

   | Cataliva Stage | Genie Team Phase | Trigger |
   |---------------|-----------------|---------|
   | Seed → Tend | `/discover` + `/define` | Cataliva dispatches when idea is approved |
   | Tend → Grow | `/design` + `/deliver` | Cataliva dispatches when shaped work is approved |
   | Grow → Harvest | `/discern` + `/done` | Cataliva dispatches review when implementation complete |
   | Harvest → Prune | Manual or `/cleanup` | Cataliva signals maintenance cycle |

4. **Cataliva reads `docs/` for status, doesn't maintain a parallel tracker.** The document trail IS the source of truth for work status. Cataliva's database stores portfolio metadata (zone, health, scoring) but not delivery status — it reads that from frontmatter.

### In Genie Team

1. **CLI contract already exists (ADR-001) — strengthen it.** The contract defines how external orchestrators invoke genie-team. This IS the interface. No changes needed to genie-team's internals.

2. **Add a completion signal convention.** When `/done` archives work, it could optionally emit a structured signal (JSON to stdout, webhook, or a well-known file) that Cataliva can consume.

3. **Don't absorb business concerns.** Genie-team should never track portfolio health, scoring, or strategic classification. It builds what it's told to build.

---

## Communication Protocol

### Work Order (Cataliva → Genie Team)

```json
{
  "action": "deliver",
  "backlog_item": "docs/backlog/P1-password-reset.md",
  "repo": "git@github.com:org/product.git",
  "branch_strategy": "pr",
  "appetite": "medium",
  "priority": "P1",
  "callback": {
    "type": "webhook",
    "url": "https://cataliva.example.com/api/v1/genie/callback"
  }
}
```

Cataliva translates this into:
```bash
claude -p "/deliver docs/backlog/P1-password-reset.md" \
  --output-format stream-json \
  --max-turns 100
```

### Completion Signal (Genie Team → Cataliva)

Genie-team's final output (already available via CLI contract):
```json
{
  "phase": "deliver",
  "status": "complete",
  "backlog_item": "docs/backlog/P1-password-reset.md",
  "artifacts": {
    "tests": ["tests/auth/password-reset.test.ts"],
    "implementation": ["src/auth/password-reset.ts"],
    "backlog_status": "implemented"
  },
  "routing": "/discern docs/backlog/P1-password-reset.md",
  "metrics": {
    "tests_passed": 12,
    "tests_failed": 0,
    "files_changed": 4
  }
}
```

### Status Query (Cataliva reads git)

Cataliva can check work status without invoking genie-team:
```bash
# Read frontmatter status from backlog item
grep "^status:" docs/backlog/P1-password-reset.md
# → status: implemented

# Check if archived (completed)
ls docs/archive/auth/*/P1-password-reset.md
```

---

## Summary Table

| Concern | Cataliva Owns | Genie Team Owns | Interface |
|---------|--------------|----------------|-----------|
| "What to build" | Yes | No | Work order |
| "How to build it" | No | Yes | CLI contract |
| Portfolio health | Yes | No | — |
| Code quality | No | Yes | Completion signal |
| Prioritization | Yes | No | Priority in work order |
| TDD, architecture | No | Yes | — |
| User-facing dashboard | Yes | No | Reads `docs/` |
| Document trail | No | Yes | Git repo |
| Multi-tenancy | Yes | No | Repo-per-project |
| Session management | No | Yes | CLI handles |
| Scheduling triggers | Yes | No | Dispatch interface |
| Business metrics | Yes | No | — |
| Technical metrics | No | Yes | Completion signal |

---

## Recommended Next Steps

1. **Refactor Cataliva's `services/genie/`** to be a thin dispatch layer that invokes genie-team CLI, not a parallel LLM orchestration engine
2. **Define the Work Order schema** as a formal contract between Cataliva and genie-team
3. **Define the Completion Signal schema** so Cataliva can reliably read genie-team outcomes
4. **Scope Cataliva's copilot** to business intelligence (market analysis, scoring rationale, strategic framing) — not PDLC phases
5. **Map Farm Framework stages** to genie-team phases explicitly in Cataliva's domain model
6. **Remove duplicate lifecycle tracking** — Cataliva reads `docs/` frontmatter for delivery status, keeps its own DB for portfolio metadata only
