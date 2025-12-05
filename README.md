# Genie Team

A customizable AI agent configuration system for Claude Code and Cursor that orchestrates specialized "genies" through product discovery and delivery lifecycles.

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

For deeper exploration of the ideas behind Genie Team, see the [idea documentation](file:///Users/nolan/ideas/genie-team).

---

Last updated: 2025-12-05
