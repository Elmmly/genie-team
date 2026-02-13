---
type: discovery
concept: boundaries
topic: genie-team-responsibility-boundary
status: active
created: 2026-02-12
prior_version: docs/analysis/20260211_discover_genie_team_responsibility_boundary_v1.md
author: navigator + scout
---

# Discovery: Genie Team Responsibility Boundary

> **Context:** This analysis defines what genie-team owns, what it produces for external consumption, and what it explicitly does NOT absorb. Written as genie-team evolved from a prompt engineering toolkit into a fully autonomous PDLC engine with session management and scheduled execution.

---

## The Shift: What Changed Since v1

Two new capabilities move genie-team from "toolkit requiring a human foreman" to "fully autonomous PDLC engine":

1. **Session Management (Delivered)** — `scripts/genie-session.sh` with worktree-based isolation, parallel sessions, PR creation, and sourceable functions for external scripts.

2. **Autonomous Lifecycle Runner (Designed)** — `/run` command + `scripts/run-pdlc.sh` for headless/cron execution with phase ranges (`--from`/`--through`), automated quality gates, per-phase turn limits, and structured logging.

**Before:** Genie-team was the workshop, but the foreman was always a human.
**After:** Genie-team IS the autonomous delivery engine.

---

## What Genie Team Is

**Identity:** A fully autonomous product development lifecycle engine that extends Claude Code with specialized genies, structured workflows, quality gates, session management, and scheduled execution.

| Capability | Status |
|-----------|--------|
| 7 specialized genies (Scout, Shaper, Architect, Crafter, Critic, Tidier, Designer) | Production |
| 25+ slash commands (7 D's lifecycle + shortcuts + context management) | Production |
| Document trail architecture (specs, backlog, ADRs, architecture diagrams) | Production |
| TDD enforcement, code quality, pattern enforcement (skills) | Production |
| Pre-commit validation pipeline (4 tiers) | Production |
| GitHub Actions CI | Production |
| Autonomous execution rules (PR mode + trunk-based mode) | Production |
| **Session management (worktree lifecycle, parallel sessions)** | **Production** |
| **Autonomous lifecycle runner (`/run`, `run-pdlc.sh`)** | **Designed** |
| **Phase range execution (`--from`/`--through`)** | **Designed** |
| **Scheduled/cron-compatible headless execution** | **Designed** |
| **Automated quality gate (BLOCKED stops, APPROVED continues)** | **Designed** |
| **Parallel execution (multiple items via worktrees)** | **Designed** |
| Post-compaction context re-injection hooks | Production |
| Brand workshop + AI image generation (Designer genie) | Production |
| CLI contract for external orchestrators (ADR-001) | Production |
| `install.sh` distribution (global, project, prehook, scripts) | Production |

---

## Genie Team's Boundary

### Principle: Genie Team is the Engineering Org

In a three-role model, any organization using genie-team maps to:
- **Portfolio/business layer** = the **CEO** (decides WHAT to build and WHEN)
- **Translation layer** = the **CTO** (translates engineering outputs into business language)
- **Genie Team** = the **engineering organization** (decides HOW to build and executes autonomously)

### What Genie Team Owns

| Responsibility | Description |
|---------------|-------------|
| **PDLC methodology** | 7 D's lifecycle, quality gates, structured phases |
| **Specialized genies** | Scout, Shaper, Architect, Crafter, Critic, Tidier, Designer |
| **Autonomous execution** | Phase chaining, quality gates, retry, logging |
| **Session management** | Worktree lifecycle, parallel sessions |
| **Code generation** | TDD implementation, tests, refactoring |
| **Technical design** | Architecture, ADRs, C4 diagrams |
| **Quality enforcement** | Pre-commit hooks, review verdicts, pattern compliance |
| **Document trail** | Specs, backlog items, decisions — the project's memory |
| **Git operations** | Branches, commits, PRs, worktrees |
| **Brand and design** | Visual identity, image generation, design tokens |
| **Cost transparency** | Per-phase turn/token logging |

### What Genie Team Must NOT Absorb

1. **Portfolio strategy.** Never decide WHAT to build — only HOW.
2. **Business scoring.** Effort/complexity/confidence scoring is a business decision.
3. **Multi-tenant operations.** Genie-team is single-repo, single-user (or single-orchestrator). Multi-tenancy belongs to the business platform layer.
4. **Idea lifecycle.** Business stage gates (e.g., Seed → Tend → Grow → Harvest) are business language. Genie-team's status progression (shaped → designed → implemented → reviewed → done) is engineering language. They can map to each other but don't replace each other.
5. **Stakeholder UI.** Genie-team is CLI-native. Web dashboards belong to the business platform layer.
6. **Business intelligence.** Market analysis, portfolio health aggregation, scoring — all belong to the business platform layer.

---

## What Genie Team Produces (The Two Registries)

External systems (portfolio platforms, CI/CD, orchestrators) read genie-team's output through two registries in git:

### 1. Work Registry: `docs/backlog/`

Each file IS a work item. Its YAML frontmatter IS the status record:

```yaml
status: designed        # WHERE in the lifecycle
priority: P1            # HOW urgent
appetite: medium        # HOW big
type: shaped-work       # WHAT kind of work
```

| Backlog Status | Meaning |
|---------------|---------|
| `shaped` | Scoped and ready for design |
| `designed` | Architecture decided, ready for build |
| `implemented` | Code written, tests passing, ready for review |
| `reviewed` | Quality gate passed, ready for merge |
| (archived) | Done and closed |

### 2. Capability Registry: `docs/specs/`

Each spec describes a product capability with acceptance criteria:

```yaml
status: active          # IS this capability live?
domain: workflow        # WHICH part of the product
acceptance_criteria:
  - id: AC-1
    status: met         # IS this criterion satisfied?
```

### Additional Signals

| Signal | Location | What It Tells |
|--------|----------|---------------|
| Discovery findings | `docs/analysis/*_discover_*.md` | Pre-backlog pipeline (explored, not yet shaped) |
| Architecture decisions | `docs/decisions/ADR-*.md` | Technical bets and constraints |
| Archived work | `docs/archive/{topic}/{date}/` | Completed and closed items |
| Git commits | Conventional commit messages | Activity stream, linked to backlog items |
| Git branches | `genie/{item}-{phase}` naming | What's actively in progress |
| Pull requests | Created by `session_finish` | Work ready for merge |
| Runner logs | `--log-dir` JSON output | Cost: turns, tokens, duration, verdict |

**Key principle:** The document trail IS the status report. External systems read what genie-team already writes to git. Genie-team does not need to "report" separately.

---

## The Interface With External Orchestrators

### Genie Team's Completion Signal

When genie-team finishes work (via `run-pdlc.sh` or interactive commands), it produces:

| Signal | Source | Format |
|--------|--------|--------|
| Exit code | Process exit | 0=success, 1=failure, 2=merge conflict, 3=input error |
| Artifact paths | `docs/` files created/modified | File paths in git |
| Phase reached | Runner log | Which `--through` phase completed |
| Usage metrics | Runner log (JSON) | Turns, tokens per phase |
| Verdict | `/discern` output | APPROVED / BLOCKED |
| PR URL | `session_finish` stdout | GitHub PR link |

### What Genie Team Expects From Orchestrators

Per ADR-001 (Thin Orchestrator), external orchestrators invoke genie-team via the CLI contract:

```bash
# The ONLY interface an orchestrator needs
scripts/run-pdlc.sh [--from phase] [--through phase] [--worktree] <topic|item.md>
```

Or for more control:
```bash
claude -p "/deliver docs/backlog/P1-feature.md" \
  --output-format stream-json \
  --max-turns 100
```

Genie-team does not need to know WHO dispatched the work (a portfolio platform, cron, a human, CI/CD). The interface is the same regardless.

### Status Synchronization Rule

**Git is the source of truth for engineering status.** External systems read backlog frontmatter, spec statuses, and archive entries. Genie-team does not maintain a separate status API or webhook system — the document trail in git IS the API.

```
Engineering Status (Git)          Business Status (external system)
━━━━━━━━━━━━━━━━━━━━━━━          ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
backlog item created        →     Link to backlog item
status: shaped              →     Ready for design decision
status: designed            →     Ready for build decision
status: implemented         →     Ready for review
status: reviewed            →     Quality gate passed
archived in docs/archive/   →     Work complete
```

---

## Summary Table

| Concern | Genie Team Owns | External System Owns | Interface |
|---------|----------------|---------------------|-----------|
| "How to build it" | Yes | No | CLI contract |
| "What to build" | No | Yes | Dispatch → runner invocation |
| "When to build it" | No | Yes | Cron / event → runner |
| Code quality | Yes | No | Completion signal |
| TDD, architecture | Yes | No | — |
| Document trail | Yes | No | Git repo (read-only for others) |
| Session management | Yes | No | `genie-session.sh` |
| Autonomous execution | Yes | No | `run-pdlc.sh` |
| Quality gates | Yes | No | APPROVED/BLOCKED in output |
| Technical metrics | Yes | No | Runner logs |
| Git writes | Yes | No | Genie-team commits; others read |
| Portfolio health | No | Yes | — |
| Business metrics | No | Yes | — |
| Prioritization | No | Yes | Priority in dispatch |
| Multi-tenancy | No | Yes | Repo-per-project |
| Stakeholder UI | No | Yes | Dashboard reads git |
| LLM calls (engineering) | Yes | No | Via Claude Code |
| LLM calls (business) | No | Yes | Copilot / business AI |

---

## What Genie Team Should NOT Change

Genie-team's architecture is correct for its role. No changes needed to support external orchestrators — the CLI contract (ADR-001) and document trail already provide everything an orchestrator needs to:

1. **Dispatch work** — invoke `run-pdlc.sh` or `claude -p`
2. **Monitor progress** — read runner logs, check process liveness
3. **Read results** — parse exit codes, read backlog frontmatter, find PRs
4. **Track capabilities** — read spec statuses and AC completion

The only optional addition is a `docs/MANIFEST.yaml` (auto-generated summary of both registries) to save external systems from walking directories.

---

## The Clean Mental Model

```
┌──────────────────────────────────────────────────────────────┐
│  EXTERNAL ORCHESTRATOR (portfolio platform, cron, CI/CD, human)│
│                                                               │
│  Dispatches: run-pdlc.sh --from X --through Y item.md        │
│  Reads:      docs/backlog/ (work) + docs/specs/ (capabilities)│
└──────────────────────────────────┬───────────────────────────┘
                                   │
                                   ▼
┌──────────────────────────────────────────────────────────────┐
│  GENIE TEAM — ENGINEERING ORG                                 │
│                                                               │
│  discover → define → design → deliver → discern → done        │
│                                                               │
│  Git repo: docs/backlog/ + docs/specs/ + code + tests + PRs   │
│            (work registry)  (capability registry)             │
│                                                               │
│  Completion signal (exit codes, logs, PR URL) → orchestrator  │
└──────────────────────────────────────────────────────────────┘
```

Genie-team builds what it's told to build, reports what it built, and lets the document trail speak for itself.
