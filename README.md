# Genie Team

**Specialized AI genies for product discovery and delivery, from opportunity mapping to spec-driven implementation.**

> Software teams face relentless pressure to deliver business outcomes while also building scalable systems. High costs, tight timelines, communication gaps, coordination overhead, and inconsistent practices across the team frame the challenges messy in the middle. AI coding agents promise help but often add noise; generating code without context, expanding scope without constraint, forgetting and drifting from decisions and guardrails already made.
>
> What if your AI assistant was a team of specialists instead of one generalist? Genie Team brings industry practices, insight, and workflows to Claude Code. Curated wishes, focused expertise, and a document trail that builds shared understanding as things evolve over time. It's an experiment in whether structured AI collaboration can reduce friction, align practices, and help teams move faster without sacrificing craft and pride of ownership.

## Table of Contents

- [Philosophy & Vision](#philosophy--vision)
- [Install](#1-install)
- [Bootstrap a New Project](#2-bootstrap-a-new-project)
- [Bootstrap an Existing Project](#3-bootstrap-an-existing-project)
- [Working with Genie Team](#4-working-with-genie-team)
- [Local Dev, CI/CD & Deployment](#5-local-dev-cicd--deployment)
- [The Genies](#the-genies)
- [Commands & Skills](#commands--skills)
- [Structure](#structure)
- [Inspiration & Credits](#inspiration--credits)

---

## Philosophy & Vision

### The Aspiration

We're at an inflection point in how software gets made. AI assistants are powerful but unpredictable. They'll grant your wishes, just not always the way you intended. This project is an exploration: *What if we could shape that power into something more deliberate?*

Genie Team is a playground for discovering new ways of working. It's not a finished product but an ongoing harvesting of experiments in human-AI collaboration. This is an attempt to find patterns that make augmented development more effective, more sustainable, more intentional, more craft-oriented, and even a little fun.

### Guiding Principles

**Genies, not agents.** AI coding assistants work best when you think of them as genies, powerful entities that grant wishes but interpret those wishes on their own terms. Without structure, they drift: expanding scope, losing context mid-session, and confidently building the wrong thing. Genie Team adds the constraints that make wishes reliable: specialized roles, scoped tools, structured prompts, and persistent context that survives the conversation window.

**Team of specialists.** Instead of one general purpose assistant, Genie Team provides a cast of specialized genies, each optimized for a specific phase of product development. Specialization beats generalization. Each genie has platform-enforced tool restrictions, its own model selection, and persistent memory that improves over time.

**Context accumulates.** Structured outputs (Opportunity Snapshots, Design Documents, Implementation Reports) create a document trail that builds project knowledge over time. Genie memory complements this with meta-learning: patterns noticed across sessions, calibrations, and shortcuts that help each genie work more effectively on *your* project.

**Efficiency matters.** AI tokens cost money and time. Structured prompts with clear scope reduce wasted iterations, hallucinated features, and context drift. Per-genie model selection routes research tasks (Scout, Tidier) to cheaper models while keeping judgment-heavy work (Critic, Architect) on more capable ones.

**Tinkering as practice.** This is exploratory work. Forking, adapting, and sharing configurations is part of our craft. The goal isn't to prescribe a workflow but to provide a starting point for your own experiments in augmented development.

---

## 1. Install

### Prerequisites

- **[Claude Code CLI](https://docs.anthropic.com/en/docs/claude-code)** (v1.0.33+) — The foundation that genie-team extends
- **[`gh` CLI](https://cli.github.com/)** (optional) — For PR creation in PR-mode workflows
- **[`jq`](https://jqlang.github.io/jq/)** (optional) — For the headless runner's JSON parsing

### Script Install

```bash
git clone git@github.com:elmmly/genie-team.git ~/genie-team
cd ~/genie-team

# Install globally (available to all projects)
./install.sh global

# Or install to a specific project
./install.sh project /path/to/your/project

# Verify installation
./install.sh status
```

**Global install** puts commands, genies, skills, and rules in `~/.claude/` so they're available across all projects. Best for individual developers or teams with consistent practices.

**Project install** puts everything in `/path/to/project/.claude/` for isolation. Best for trying out the workflow or when different projects need different configurations.

<details>
<summary>Plugin Install (Experimental)</summary>

> **Note:** Plugin install is experimental. The Claude Code plugin system is still evolving, and plugin installs may not include all components. The script install above is the recommended approach.

Install as a Claude Code plugin. Commands are namespaced as `/genie:command` (e.g., `/genie:discover`, `/genie:deliver`).

```
/plugin marketplace add elmmly/genie-team
/plugin install genie@genie-team --scope user
```

The plugin provides commands, genies, skills, hooks, and the MCP image generation server. Rules and schemas require a supplemental step:

```bash
git clone git@github.com:elmmly/genie-team.git ~/genie-team
cd ~/genie-team && ./install.sh global --rules --schemas
```

</details>

### Post-Install

Start a Claude session and load context:

```bash
cd /path/to/your/project
claude
> /context:load
```

This scans for existing specs, ADRs, diagrams, and backlog items, then recommends next steps.

> Plugin users: use `/genie:context:load` instead (all commands are namespaced under `/genie:`).

### What Gets Installed

| Component | Purpose |
|-----------|---------|
| **Commands** | Slash commands (`/discover`, `/deliver`, etc.) |
| **Genies** | Specialist definitions with per-genie model, tools, and memory |
| **Skills** | Automatic behaviors (TDD, code quality, brand awareness) |
| **Hooks** | Context re-injection on compaction |
| **MCP** | Image generation server (Designer genie via Gemini) |
| **Rules** | Always-on constraints (workflow, code quality, conventions) |
| **Schemas** | Document format definitions (ADR, spec, shaped contract) |
| **Scripts** | `genies` (headless runner + session management + quality checks) |

<details>
<summary>All script install options</summary>

```bash
./install.sh global                  # Full global install (includes MCP)
./install.sh global --commands       # Commands only
./install.sh global --skills         # Skills only (automatic behaviors)
./install.sh global --agents         # Agents only
./install.sh global --rules          # Rules only
./install.sh global --hooks          # Hooks only (context re-injection)
./install.sh global --schemas        # Schemas only
./install.sh global --scripts        # Scripts only (genies)
./install.sh global --mcp            # MCP server only (imagegen)
./install.sh project /path/to/app    # Full project install
./install.sh project --skip-mcp      # Everything except MCP
./install.sh project --force         # Re-install/upgrade (overwrite existing)
./install.sh project --sync          # Clean install (removes obsolete files)
./install.sh project --dry-run       # Preview changes
./install.sh prehook /path/to/app    # Install pre-commit hooks (standalone)
./install.sh uninstall               # Remove genie-team installation
```

</details>

---

## 2. Bootstrap a New Project

Starting from scratch? Genie Team provides interactive workshops that walk you through establishing the key decisions and artifacts to guide ongoing development.

### Product Workshop

Start by exploring the problem space, then run an interactive workshop to shape the first work items:

```
> /discover "the problem we're solving"
```

The Scout genie performs opportunity mapping using Teresa Torres' Continuous Discovery and Jobs-to-be-Done frameworks. It surfaces assumptions, documents unknowns, and produces an Opportunity Snapshot.

Then shape the work with an interactive workshop:

```
> /define --workshop "the opportunity to pursue"
```

The Shaper genie leads a 4-phase interactive session:
1. **Problem Framing** — Choose from 2-3 solution-free reframings of the problem
2. **Appetite Explorer** — Visual HTML comparison of Small/Medium/Big scope tiers
3. **Option Exploration** — Side-by-side solution directions with tradeoff ratings
4. **Scope Negotiation** — In/out boundaries, no-gos, rabbit holes

Output: A Shaped Work Contract (`docs/backlog/P{N}-{topic}.md`) with appetite boundaries and acceptance criteria. A capability spec (`docs/specs/{domain}/{capability}.md`) tracking what the system does.

> **Planned:** `/discover --workshop` — A structured multi-phase product discovery workshop with iteration loops, similar to the brand workshop. Today, `/discover` is a single-pass command.

### Brand Workshop

Establish visual identity and design language:

```
> /brand --workshop
```

The Designer genie leads a 6-phase interactive workshop:
1. **Identity** — Name, mission, voice, personality traits
2. **Colors** — Palette exploration with generated HTML previews and accessibility validation
3. **Typography** — Font families, scale, hierarchy with real-world scenario previews
4. **Imagery** — Photography, illustration, and abstract style exploration with generated examples
5. **Target Examples** — Brand north star images generated with Gemini
6. **Consolidation** — Brand guide with W3C Design Tokens

Output: Brand Specification (`docs/brand/{name}-brand.md`), design tokens (`docs/brand/tokens.json`), and generated visual examples.

### Architecture Workshop

Establish key technical decisions:

```
> /design --workshop docs/backlog/P1-first-feature.md
```

The Architect genie leads a structured technical workshop:
1. **Approach Comparison** — Side-by-side HTML panels evaluating 2-3 architectural alternatives
2. **Technical Decisions** — Walk through each significant choice interactively (framework, database, CI provider, deployment target)
3. **Interface Preview** — Component boundaries and API contracts in code-styled HTML preview
4. **Risk Prioritization** — Select which mitigations are worth the investment

Output: Architecture Decision Records (`docs/decisions/ADR-{NNN}-{slug}.md`), design document appended to the backlog item, and C4 diagram updates.

### Generate Bootstrap Artifacts

After workshops, generate the persistent knowledge foundation:

```
> /arch:init          # Infers system boundaries → generates C4 diagrams
> /spec:init          # Scans source code + tests → generates capability specs
```

These create:
- **C4 diagrams** (`docs/architecture/`) — System context, containers, components
- **Capability specs** (`docs/specs/{domain}/{capability}.md`) — What the system does, acceptance criteria
- **ADR-000** bootstrapping record (`docs/decisions/`)

---

## 3. Bootstrap an Existing Project

Joining an existing codebase? Genie Team can scan what's there and generate the missing artifacts.

### Scan and Generate

```
> /spec:init
```

The Scout genie performs a deep scan of source code, tests, config files, and documentation. It identifies capabilities by behavioral grouping (not file structure), presents them in batches for you to assign domains, and generates specs with acceptance criteria inferred from tests.

```
> /arch:init
```

The Architect genie infers containers from directory structure, `package.json` workspaces, Dockerfiles, and config files. It detects external systems from database configs, API URLs, and service integrations. Output: C4 diagrams and an ADR-000 bootstrapping record.

### Health Check

```
> /diagnose
```

The Architect genie scans for:
- Dead code and pattern violations
- Coupling violations (undocumented cross-domain dependencies)
- ADR health (stale proposals, contradictory decisions)
- Diagram staleness (>90 days without update)
- Test coverage gaps (capabilities with tests but no specs)

### Fill Gaps with Workshops

Use the interactive workshops from Section 2 to address gaps that scanning alone can't fill:

```
> /define --workshop "area that needs product clarity"
> /design --workshop docs/backlog/P2-area-needing-architecture.md
```

---

## 4. Working with Genie Team

The 7 D's lifecycle — discover, define, design, deliver, discern, commit, done — can be run in different modes depending on the level of control you want.

### Guided Lifecycle (`/feature`)

Full lifecycle with manual gates at each transition. Best for learning the workflow or complex features where you want to steer at each phase.

```
> /feature "user authentication improvements"
```

Runs discover → define → design → deliver → discern, pausing for your approval at each transition. You can redirect, refine, or reject before the next phase begins.

### Autonomous Lifecycle (`/run`)

Same phases, no manual gates. `/discern` is the automated quality gate — stops on BLOCKED, continues through APPROVED. Best for trusted execution of well-shaped work.

```
> /run "add password reset"                               # Full lifecycle from topic
> /run docs/backlog/P2-auth.md                            # Continue from backlog item
> /run docs/backlog/P2-auth.md --from design              # Skip discovery + shaping
> /run --through define "explore notification patterns"   # Just discover + define
```

### Headless/Scheduled (`genies`)

Chains `claude -p` per phase for cron, CI/CD, or GitHub Actions. Best for daily discovery pipelines or overnight delivery. Available on PATH after global install.

```bash
# Full lifecycle from topic
genies "add password reset"

# Discovery pipeline — have the genies explore and shape improvement areas
genies --through define \
  "identify 3-5 opportunities to improve the product UX" \
  "identify 3-5 foundational improvements for reliability and performance" \
  "identify 3-5 developer experience improvements"

# Implement approved items (run after human review)
genies --from design docs/backlog/P2-auth.md

# Deliver everything in the backlog while you're away from the keyboard
genies --parallel 3 --trunk --verbose --log-dir logs/overnight

# With operational flags
genies --lock --log-dir ./logs \
  --from design docs/backlog/P2-auth.md
```

Features: phase ranges (`--from`/`--through`), lockfiles (`--lock`), per-phase turn limits, automatic retry on exhaustion, structured JSON logging (`--log-dir`), exit codes (0=success, 1=failure, 2=merge conflict, 3=validation error).

### Individual Commands

Use any command directly for surgical work:

```
> /deliver docs/backlog/P2-auth.md     # Just implement
> /discern docs/backlog/P2-auth.md     # Just review
> /commit docs/backlog/P2-auth.md      # Just commit
```

### Quick Workflows

Shortcuts for common patterns:

| Command | What It Does |
|---------|-------------|
| `/bugfix "broken login"` | Light shape → deliver → discern |
| `/spike "can we use SQLite?"` | Time-boxed technical investigation |
| `/cleanup auth module` | diagnose → tidy (safe refactoring) |

### Parallel Sessions

Multiple genie-team sessions working on the same repo simultaneously via git worktrees:

```bash
# Start a parallel session
genies session start P2-search deliver
# → Creates ../myproject--P2-search on branch genie/P2-search-deliver

# List active sessions
genies session list

# Finish (push + PR, remove worktree)
genies session finish P2-search

# Or merge directly (trunk-based)
genies session finish P2-search --merge

# Or leave branch for later integration (used by parallel batch)
genies session finish P2-search --leave-branch

# Clean up all merged sessions
genies session cleanup
```

Enable in your project's `CLAUDE.md` by uncommenting `<!-- worktree-enabled -->`.

### Git Workflow

**PR mode** (default): Feature branches (`genie/{item}-{phase}`) with pull requests via `gh`. No direct pushes to main.

**Trunk-based mode** (opt-in): Direct commits to main. Activate by adding to your project's `CLAUDE.md`:
```markdown
## Git Workflow
trunk-based
```

---

## 5. Local Dev, CI/CD & Deployment

Genie Team's workshops capture infrastructure decisions, and the existing lifecycle delivers them.

### How It Works

The architecture workshop (`/design --workshop`) captures infrastructure decisions as ADRs:
- Which container runtime (Docker, Podman, native)
- Which CI provider (GitHub Actions, CircleCI, GitLab CI)
- Which deployment target (AWS, Vercel, Fly.io, K8s)
- Which observability stack (Datadog, Grafana, CloudWatch)

These decisions live in `docs/decisions/ADR-{NNN}-{slug}.md`. Then use the normal lifecycle to implement them:

```
> /define "set up local dev environment with Docker"
> /deliver docs/backlog/P2-local-dev-setup.md
```

The Crafter reads ADRs and C4 diagrams during implementation. The Critic checks ADR compliance during review. No special infrastructure command needed — the same workflow that builds features also builds infrastructure.

`/arch:init` documents the system in C4 diagrams showing containers, external systems, and deployment boundaries.

### Batch Execution

Run multiple items in parallel with serialized integration — all through `genies`:

```bash
# Deliver all actionable backlog items with 3 parallel workers, trunk-based
genies --parallel 3 --trunk --verbose \
  --log-dir logs/overnight

# Deliver only P1 items (auto-detects phase from status)
genies --priority P1 --parallel 2 --trunk \
  --verbose --log-dir logs/p1-delivery

# Have the genies discover and shape improvement areas in parallel
genies --parallel 3 --trunk --verbose \
  --through define --log-dir logs/discovery \
  "identify 3-5 ways to improve the onboarding experience" \
  "identify 3-5 performance and reliability improvements" \
  "identify 3-5 ways to reduce developer friction"

# Preview what would run (no execution)
genies --parallel 3 --dry-run
```

Parallel mode uses git worktrees for isolation. Workers leave branches intact after completing, then the runner serializes integration (rebase+ff for `--trunk`, push+PR otherwise). Logs in `--log-dir` for post-run inspection.

### Scheduling with the Headless Runner

For CI/CD integration with `genies`:

```bash
# Nightly discovery pipeline — genies explore and shape improvement opportunities
0 2 * * * genies --through define --lock --log-dir ./logs \
  "identify 3-5 opportunities to improve the product experience"

# Weekend delivery — genies work through the entire backlog while you're away
0 22 * * 5 genies --parallel 3 --trunk --lock --log-dir ./logs/weekend

# Implement specific approved items (manual trigger or CI)
genies --from design --lock --log-dir ./logs docs/backlog/P2-approved-item.md
```

---

## The Genies

Each genie is a native Claude Code agent (`.claude/agents/{name}.md`) with platform-enforced tool restrictions, per-genie model selection, and persistent memory.

| Genie | Command | Model | Purpose |
|-------|---------|-------|---------|
| **Scout** | `/discover` | haiku | Discovery, research, opportunity mapping |
| **Shaper** | `/define` | sonnet | Problem framing, appetite, constraints |
| **Architect** | `/design`, `/diagnose` | sonnet | Technical design, patterns, health |
| **Crafter** | `/deliver` | sonnet | TDD implementation, code quality |
| **Critic** | `/discern` | sonnet | Review, acceptance criteria, risks |
| **Tidier** | `/tidy` | haiku | Refactoring, cleanup, tech debt |
| **Designer** | `/brand` | sonnet | Brand identity, visual assets, design tokens |

**Cost optimization:** Scout and Tidier run on haiku (10-20x cheaper) for research/analysis. Crafter, Critic, Architect, Shaper, and Designer run on sonnet where judgment quality matters.

## Commands & Skills

Genie Team extends Claude Code using two complementary mechanisms:

**Commands** (`.claude/commands/`) — Explicit slash commands that you invoke. Each command activates a specific genie for a specific phase of the lifecycle.

**Skills** (`.claude/skills/`) — Automatic behaviors that activate based on context. No explicit invocation needed — Claude applies them when relevant.

Both are the recommended Claude Code extension patterns. Commands are for workflows you choose to run. Skills are for standards you always want enforced.

<details>
<summary>All commands</summary>

### Lifecycle
- `/discover [topic]` — Explore a problem space
- `/define [input]` — Frame work with appetite and constraints (`--workshop` for interactive)
- `/design [contract]` — Create technical design (`--workshop` for interactive)
- `/deliver [design]` — Implement with TDD
- `/discern [impl]` — Review and validate
- `/commit [item]` — Create conventional commit
- `/done [item]` — Archive completed work

### Workflows
- `/feature [topic]` — Full lifecycle with manual gates
- `/run [item]` — Autonomous lifecycle (no gates, /discern as quality gate)
- `/bugfix [issue]` — Quick fix flow
- `/spike [question]` — Technical investigation
- `/cleanup [scope]` — Debt reduction

### Brand
- `/brand [input]` — Brand workshop (`--workshop` for fresh, `--evolve` to update)
- `/brand:image [prompt]` — Generate brand-consistent image
- `/brand:tokens [guide]` — Extract W3C design tokens

### Maintenance
- `/diagnose [scope]` — Scan codebase health
- `/tidy [report]` — Execute safe cleanup

### Bootstrap
- `/spec:init [scope]` — Generate specs from source code
- `/arch:init` — Generate architecture diagrams

### Context
- `/context:load` — Initialize session
- `/context:summary` — End-of-session handoff
- `/context:recall [topic]` — Find past work
- `/context:refresh` — Update from codebase
- `/handoff [from] [to]` — Phase transition with context

### Help
- `/genie:help` — Show all commands
- `/genie:status` — Show current work status

</details>

<details>
<summary>All skills (automatic behaviors)</summary>

| Skill | Activates When |
|-------|----------------|
| **tdd-discipline** | Writing code, implementing features, fixing bugs |
| **code-quality** | Implementing features, editing code, refactoring |
| **conventional-commits** | Committing code, creating git commits |
| **problem-first** | Defining work, feature requests, "we should add..." |
| **pattern-enforcement** | Designing systems, reviewing code structure |
| **spec-awareness** | Loading context, starting features, discussing specs |
| **architecture-awareness** | Discussing architecture, ADRs, C4 diagrams |
| **brand-awareness** | Working with brand guides, design tokens, visual identity |

</details>

## Structure

```
genie-team/
├── .claude-plugin/
│   ├── plugin.json      # Plugin manifest (name, version, metadata)
│   └── marketplace.json # Marketplace catalog for /plugin install
├── commands/            # Slash command definitions
├── agents/              # Genie definitions
├── skills/              # Automatic behavior skills
├── hooks/
│   ├── hooks.json       # Plugin hook configuration
│   ├── track-command.sh # Command tracking
│   ├── track-artifacts.sh # Artifact tracking
│   └── reinject-context.sh # Context re-injection on compaction
├── rules/               # Always-on constraints
├── schemas/             # Document format schemas
├── genies/              # Genie specs, system prompts, templates
├── scripts/
│   ├── genies           # CLI entry point (lifecycle, session, quality)
│   ├── genie-session    # Session library (sourced by genies)
│   └── validate/        # Quality validation scripts
├── templates/           # Project templates (CLAUDE.md)
├── tests/               # Test suite
└── install.sh           # Installation script
```

### Knowledge Architecture

Two complementary persistence systems:

| System | Purpose | Location | Lifecycle |
|--------|---------|----------|-----------|
| **Document trail** | Project knowledge — findings, designs, reviews, decisions | `docs/` (git-tracked) | Created → appended → archived |
| **Genie memory** | Genie meta-learning — patterns, calibrations, shortcuts | `.claude/agent-memory/` (gitignored) | Curated continuously, 200-line cap |

**Document trail** stores what the project knows. **Genie memory** stores what each genie has learned about working on this project. Genies get better at *your specific project* over time.

## Inspiration & Credits

This project draws heavily from the work of:

### Kent Beck — The Genie Metaphor & Tidy First?
The "genie" framing for AI coding assistants comes from Beck's writing on his [Tidy First?](https://tidyfirst.substack.com/) Substack where he explores a number of topics including augmented coding vs. "vibe coding." Key insights include treating AI as a genie that grants wishes literally (requiring precise requests), the importance of "exhaling" (tidying/refactoring) to counter the genie's tendency to only "inhale" (add features), and the seed corn problem of complexity accumulation.

- *[Tidy First?: A Personal Exercise in Empirical Software Design](https://www.oreilly.com/library/view/tidy-first/9781098151232/)* (O'Reilly, 2023)
- [Augmented Coding & Design](https://tidyfirst.substack.com/p/augmented-coding-and-design) — The genie metaphor and complexity trap
- [Augmented Coding: Beyond the Vibes](https://tidyfirst.substack.com/p/augmented-coding-beyond-the-vibes) — Vibe coding vs. augmented coding distinction
- Test-Driven Development, Extreme Programming, and simple design principles

### Product Discovery & Strategy

**Teresa Torres** — *[Continuous Discovery Habits](https://www.producttalk.org/2021/05/continuous-discovery-habits/)* (2021). The Scout genie draws from her structured approach to continuous discovery: weekly customer touchpoints, opportunity mapping, assumption testing, and the Product Trio model. See [producttalk.org](https://www.producttalk.org/).

**Ryan Singer** — *[Shape Up: Stop Running in Circles and Ship Work that Matters](https://basecamp.com/shapeup)* (Basecamp, 2019). The Shaper genie implements his appetite-driven approach: fixed time/variable scope, six-week cycles, pitches, and the betting table. Free online at basecamp.com/shapeup.

**Clayton Christensen & Tony Ulwick** — Jobs-to-be-Done framework. Christensen popularized JTBD in *The Innovator's Solution* (2003); Ulwick created the underlying [Outcome-Driven Innovation](https://strategyn.com/jobs-to-be-done/) methodology. See *[Jobs to be Done: Theory to Practice](https://jobs-to-be-done-book.com/)* (Ulwick, 2016).

**Marty Cagan** — *[Inspired: How to Create Tech Products Customers Love](https://www.svpg.com/books/)* (2nd ed, 2017) and *[Empowered: Ordinary People, Extraordinary Products](https://www.svpg.com/books/empowered-ordinary-people-extraordinary-products/)* (2020). The Shaper genie incorporates his product sense and empowered teams philosophy. See [svpg.com](https://www.svpg.com/).

**Melissa Perri** — *[Escaping the Build Trap: How Effective Product Management Creates Real Value](https://www.oreilly.com/library/view/escaping-the-build/9781491973783/)* (O'Reilly, 2018). Her outcome-over-output philosophy shapes the Shaper genie's focus on value over features.

### Software Craftsmanship

**Martin Fowler** (ThoughtWorks) — *[Refactoring: Improving the Design of Existing Code](https://martinfowler.com/books/refactoring.html)* (2nd ed, 2018). The Tidier and Crafter genies draw from his catalog of refactoring patterns. Online catalog at [refactoring.com/catalog](https://refactoring.com/catalog/).

**Dave Thomas & Andy Hunt** — *[The Pragmatic Programmer](https://pragprog.com/titles/tpp20/the-pragmatic-programmer-20th-anniversary-edition/)* (20th Anniversary Edition, 2019). The Crafter genie's practical, no-dogma approach to implementation draws from their emphasis on working software, continuous learning, and craftsmanship without ceremony.

---

Last updated: 2026-03-03
