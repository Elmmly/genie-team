# Genie Team

**Specialized AI genies for product discovery and delivery, from opportunity mapping to spec-driven implementation.**

> Software teams face relentless pressure to deliver business outcomes while also building scalable systems. High costs, tight timelines, communication gaps, coordination overhead, and inconsistent practices across the team frame the challenges messy in the middle. AI coding agents promise help but often add noise; generating code without context, expanding scope without constraint, forgetting and drifting from decisions and guardrails already made.
>
> What if your AI assistant was a team of specialists instead of one generalist? Genie Team brings industry practices, insight, and workflows to Claude Code. Curated wishes, focused expertise, and a document trail that builds shared understanding as things evolve over time. It's an experiment in whether structured AI collaboration can reduce friction, align practices, and help teams move faster without sacrificing craft and pride of ownership.

## Quick Start

```bash
# Install globally (available to all projects)
./install.sh global

# Or install to a specific project
./install.sh project /path/to/your/project

# Check what's installed
./install.sh status
```

### What Gets Installed

| Component | Purpose | Location |
|-----------|---------|----------|
| **Commands** | Slash commands (`/discover`, `/deliver`, etc.) | `.claude/commands/` |
| **Genies** | Genie definitions (native Claude Code agent format) with per-genie model, tools, and memory | `.claude/agents/` |
| **Skills** | Automatic behaviors (TDD, code quality, brand awareness, etc.) | `.claude/skills/` |
| **Rules** | Always-on constraints (workflow, code quality, agent conventions) | `.claude/rules/` |
| **Schemas** | Document format definitions (ADR, spec, shaped contract, etc.) | `schemas/` |
| **Hooks** | Context re-injection on compaction (preserves context across long sessions) | `.claude/hooks/` |
| **MCP** | Image generation server (Designer genie) | Via `claude mcp add` |

### Install Options

```bash
./install.sh global                  # Full global install (includes MCP)
./install.sh global --commands       # Commands only
./install.sh global --skills         # Skills only (automatic behaviors)
./install.sh global --agents         # Agents only
./install.sh global --rules          # Rules only
./install.sh global --hooks          # Hooks only (context re-injection)
./install.sh global --schemas        # Schemas only
./install.sh global --mcp            # MCP server only (imagegen)
./install.sh project /path/to/app    # Full project install
./install.sh project --skip-mcp      # Everything except MCP
./install.sh project --force         # Re-install/upgrade (overwrite existing)
./install.sh project --sync          # Clean install (removes obsolete files)
./install.sh project --dry-run       # Preview changes
./install.sh prehook /path/to/app    # Install pre-commit hooks (standalone)
./install.sh uninstall               # Remove genie-team installation
```

## The Genies

Each genie is implemented as a native Claude Code agent (`.claude/agents/{name}.md`) with platform-enforced tool restrictions, per-genie model selection, and persistent memory.

| Genie | Command | Model | Purpose |
|-------|---------|-------|---------|
| **Scout** | `/discover` | haiku | Discovery, research, opportunity mapping |
| **Shaper** | `/define` | sonnet | Problem framing, appetite, constraints |
| **Architect** | `/design`, `/diagnose` | sonnet | Technical design, patterns, health analysis |
| **Crafter** | `/deliver` | sonnet | TDD implementation, code quality |
| **Critic** | `/discern` | sonnet | Review, acceptance criteria, risks |
| **Tidier** | `/tidy` | haiku | Refactoring, cleanup, tech debt |
| **Designer** | `/brand`, `/brand:image` | sonnet | Brand identity, visual assets, design tokens |

**Cost optimization:** Scout and Tidier run on haiku (10-20x cheaper) for research/analysis tasks. Crafter, Critic, Architect, Shaper, and Designer run on sonnet where judgment quality matters.

## Commands

### Lifecycle
- `/discover [topic]` - Explore a problem space
- `/define [input]` - Frame work with appetite and constraints
- `/design [contract]` - Create technical design
- `/deliver [design]` - Implement with TDD
- `/discern [impl]` - Review and validate
- `/commit [item]` - Create conventional commit
- `/done [item]` - Archive completed work

### Workflows
- `/feature [topic]` - Full lifecycle delivery
- `/bugfix [issue]` - Quick fix flow
- `/spike [question]` - Technical investigation
- `/cleanup [scope]` - Debt reduction

### Brand
- `/brand [input]` - Interactive brand workshop
- `/brand:image [prompt]` - Generate brand-consistent image
- `/brand:tokens [guide]` - Extract W3C design tokens

### Maintenance
- `/diagnose [scope]` - Scan codebase health
- `/tidy [report]` - Execute safe cleanup

### Bootstrap
- `/spec:init [scope]` - Bootstrap specs from source code
- `/arch:init` - Bootstrap architecture diagrams

### Context
- `/context:load` - Initialize session
- `/context:summary` - End-of-session handoff
- `/context:recall [topic]` - Find past work
- `/context:refresh` - Update from codebase
- `/handoff [from] [to]` - Phase transition with context

### Help
- `/genie:help` - Show all commands
- `/genie:status` - Show current work status

## Skills (Automatic Behaviors)

Skills activate automatically based on context — no explicit invocation needed.

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

## Parallel Sessions

Multiple genie-team sessions can work on the same repository simultaneously using git worktrees. Each session operates in its own worktree directory on a separate branch.

```bash
# Create a worktree for parallel work
git worktree add ../myproject--auth -b genie/P1-auth-deliver
cd ../myproject--auth

# Install genie-team (auto-detects worktree context)
/path/to/genie-team/install.sh project .

# Work in parallel — each worktree has its own branch, index, and files
claude

# Clean up when done
git worktree remove ../myproject--auth
```

Worktree-aware behaviors:
- **MCP scope** switches to `user` (shared across sessions) instead of `local`
- **Genie memory** is symlinked to the main worktree (shared learning)
- **Safety rules** prevent destructive operations that affect sibling worktrees
- Enable in your project's CLAUDE.md by uncommenting `<!-- worktree-enabled -->`

## Structure

```
genie-team/
├── .claude/
│   ├── commands/        # Slash command definitions (installed to target)
│   ├── skills/          # Automatic behavior skills
│   ├── hooks/           # Context re-injection scripts (compaction recovery)
│   └── rules/           # Always-on constraints
├── agents/              # Genie definitions in native agent format (→ .claude/agents/)
│   ├── scout.md         # Discovery specialist (haiku, read-only)
│   ├── shaper.md        # Problem framer (sonnet, read-only)
│   ├── architect.md     # Technical designer (sonnet, read-only)
│   ├── crafter.md       # TDD implementer (sonnet, read-write)
│   ├── critic.md        # Code reviewer (sonnet, read-only)
│   ├── tidier.md        # Cleanup specialist (haiku, read-only)
│   └── designer.md      # Brand strategist (sonnet, read-only)
├── genies/              # Genie specs, system prompts, and templates per genie
├── schemas/             # Document format schemas (ADR, spec, brand-spec, etc.)
├── templates/           # Project templates (CLAUDE.md)
├── tests/               # Test suite
├── dist/                # Built/distributable commands
└── install.sh           # Installation script
```

### Knowledge Architecture

Genie Team uses two complementary persistence systems:

| System | Purpose | Location | Lifecycle |
|--------|---------|----------|-----------|
| **Document trail** | Project knowledge — findings, designs, reviews, decisions | `docs/` (git-tracked) | Created → appended → archived |
| **Genie memory** | Genie meta-learning — patterns, calibrations, shortcuts | `.claude/agent-memory/` (gitignored) | Curated continuously, 200-line cap |

**Document trail** stores what the project knows. **Genie memory** stores what each genie has learned about working on this project. Genies get better at *your specific project* over time.

## Philosophy & Vision

### The Aspiration

We're at an inflection point in how software gets made. AI assistants are powerful but unpredictable. They'll grant your wishes, just not always the way you intended. This project is an exploration: *What if we could shape that power into something more deliberate?*

Genie Team is a playground for discovering new ways of working. It's not a finished product but an ongoing harvesting of experiments in human-AI collaboration. This is an attempt to find patterns that make augmented development more effective, more sustainable, more intentional, more craft-oriented, and even a little fun.

### Guiding Principles

**Genies, not agents.** AI coding assistants work best when you think of them as genies; powerful entities that grant wishes, but benefit from clear, well-formed requests. A genie does exactly what you ask in the way that the genie interprets what you ask, which means the quality of output depends on the quality of input and some blend of context management of the AI context.

**Team of specialists.** Instead of one general purpose assistant, Genie Team provides a cast of specialized genies, each optimized for a specific phase of product development. Specialization beats generalization. Each genie has platform-enforced tool restrictions, its own model selection, and persistent memory that improves over time.

**Context accumulates.** Structured outputs (Opportunity Snapshots, Design Documents, Implementation Reports) create a document trail that builds project knowledge over time. Genie memory complements this with meta-learning — patterns noticed across sessions, calibrations, and shortcuts that help each genie work more effectively on *your* project.

**Efficiency matters.** AI tokens cost money and time. Structured prompts with clear scope reduce wasted iterations, hallucinated features, and context drift. Per-genie model selection routes research tasks (Scout, Tidier) to cheaper models while keeping judgment-heavy work (Critic, Architect) on more capable ones.

**Tinkering as practice.** This is exploratory work. Forking, adapting, and sharing configurations is part of our craft. The goal isn't to prescribe a workflow but to provide a starting point for your own experiments in augmented development.

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

Last updated: 2026-02-12
