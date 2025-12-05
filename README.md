# Genie Team

**Specialized AI genies for product discovery and delivery, from opportunity mapping to spec-driven implementation.**

> Software teams face relentless pressure to deliver business outcomes while also building scalable systems. High costs, tight timelines, communication gaps, coordination overhead, and inconsistent practices across the team frame the challenges messy in the middle. AI coding agents promise help but often add noise; generating code without context, expanding scope without constraint, forgetting and drifting from decisions and guardrails already made.
>
> What if your AI assistant was a team of specialists instead of one generalist? Genie Team brings industry practices, insight, and workflows to Claude Code. Curated wishes, focused expertise, and a document trail that builds shared understanding as things evolve over time. It's an experiment in whether structured AI collaboration can reduce friction, align practices, and help teams move faster without sacrificing craft and pride of ownership.

## Quick Start

```bash
# Install to your Claude Code project
./install.sh /path/to/your/project
```

This copies command definitions to your project's `.claude/commands/` directory.

## The Genies

| Genie | Command | Purpose |
|-------|---------|---------|
| **Scout** | `/discover` | Discovery, research, opportunity mapping |
| **Shaper** | `/shape` | Problem framing, appetite, constraints |
| **Architect** | `/design`, `/diagnose` | Technical design, patterns, health analysis |
| **Crafter** | `/deliver` | TDD implementation, code quality |
| **Critic** | `/discern` | Review, acceptance criteria, risks |
| **Tidier** | `/tidy` | Refactoring, cleanup, tech debt |

## Commands

### Lifecycle
- `/discover [topic]` - Explore a problem space
- `/shape [input]` - Frame work with appetite and constraints
- `/design [contract]` - Create technical design
- `/deliver [design]` - Implement with TDD
- `/discern [impl]` - Review and validate

### Workflows
- `/feature [topic]` - Full lifecycle delivery
- `/bugfix [issue]` - Quick fix flow
- `/spike [question]` - Technical investigation
- `/cleanup [scope]` - Debt reduction

### Context
- `/context:load` - Initialize session
- `/context:summary` - End-of-session handoff
- `/context:recall [topic]` - Find past work
- `/context:refresh` - Update from codebase

## Structure

```
genie-team/
├── genies/           # Genie specs, prompts, and templates
│   ├── scout/
│   ├── shaper/
│   ├── architect/
│   ├── crafter/
│   ├── critic/
│   └── tidier/
├── commands/         # Command definitions (16 files)
└── install.sh        # Installation script
```

## Philosophy & Vision

### The Aspiration

We're at an inflection point in how software gets made. AI assistants are powerful but unpredictable. They'll grant your wishes, just not always the way you intended. This project is an exploration: *What if we could shape that power into something more deliberate?*

Genie Team is a playground for discovering new ways of working. It's not a finished product but an ongoing harvesting of experiments in human-AI collaboration. This is an attempt to find patterns that make augmented development more effective, more sustainable, more intentional, more craft-oriented, and even a little fun.

### Guiding Principles

**Genies, not agents.** AI coding assistants work best when you think of them as genies; powerful entities that grant wishes, but benefit from clear, well-formed requests. A genie does exactly what you ask in the way that the genie interprets what you ask, which means the quality of output depends on the quality of input and some blend of context management of the AI context.

**Team of specialists.** Instead of one general purpose assistant, Genie Team provides a cast of specialized genies, each optimized for a specific phase of product development. Specialization beats generalization.

**Context accumulates.** Structured outputs (Opportunity Snapshots, Design Documents, Implementation Reports) create a document trail that builds project memory over time.

**Efficiency matters.** AI tokens cost money and time. Structured prompts with clear scope reduce wasted iterations, hallucinated features, and context drift. Specialization means smaller, focused contexts instead of bloated conversations. The goal is more value per interaction: less rework, fewer corrections, better outcomes.

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

Last updated: 2025-12-05
