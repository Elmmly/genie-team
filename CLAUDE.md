# Genie Team

Specialized AI genies for product discovery and delivery, extending Claude Code with structured workflows.

## Vocabulary

- **"Genies"** — the project term for specialists. NOT "agents."
- `.claude/agents/` is a technical implementation path (Claude Code's native format); in docs, README, and comments, always say "genie" / "genies"
- The Kent Beck metaphor: genies grant wishes literally, requiring precise requests

## Repository Structure

```
genie-team/
├── agents/              # Genie definitions (native .claude/agents/ format)
├── commands/            # Slash command source files
├── genies/              # Genie specs, system prompts, templates
├── schemas/             # Document format schemas (ADR, spec, brand-spec, etc.)
├── templates/           # CLAUDE.md template for target projects
├── tests/               # Test fixtures and test suite
├── .claude/
│   ├── commands/        # Installed command definitions
│   ├── skills/          # Automatic behavior skills
│   └── rules/           # Always-on constraints
├── dist/                # Built/distributable commands
├── install.sh           # Installation script
└── docs/                # Document trail (see below)
```

## Document Trail

All project knowledge lives in `docs/` under git:

| Directory | Contents |
|-----------|----------|
| `docs/backlog/` | Active work items (shaped contracts, spikes) |
| `docs/specs/` | Capability specifications by domain |
| `docs/decisions/` | Architecture Decision Records (ADR-NNN) |
| `docs/architecture/` | C4 diagrams (system-context, containers) |
| `docs/analysis/` | Spike results, discovery findings |
| `docs/archive/` | Completed work (grouped by topic/date) |
| `docs/brand/` | Brand guides and design tokens (when present) |

## Knowledge Architecture

Two complementary persistence systems:

- **Document trail** (`docs/`): project knowledge — deliverables, decisions, findings. Git-tracked.
- **Genie memory** (`.claude/agent-memory/`): genie meta-learning — patterns, calibrations, shortcuts. Gitignored.

Boundary: docs store WHAT the project knows; memory stores what each genie has LEARNED about working on this project.

## Key Architecture Decisions

- **ADR-000**: Use ADRs for architecture decisions
- **ADR-001**: Thin Orchestrator for external portfolio integration (spawn CLI processes, no shared runtime)
- **ADR-002**: Designer integrates via `/brand` commands + `brand-awareness` skill + `designer` agent

## Development Conventions

- This is a **prompt engineering** project — the primary artifacts are markdown files, not application code
- `install.sh` copies commands, agents, skills, rules, and schemas to target `.claude/` directories
- No build step — all artifacts are markdown/YAML prompt definitions
- Image generation uses `@fastmcp-me/imagegen-mcp` with Gemini models (see `.claude/rules/mcp-integration.md`)
- Always check `docs/analysis/` for spike results before starting related work
