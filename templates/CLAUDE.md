# Project Name

> Brief description of this project

<!-- This file is automatically loaded by Claude Code at session start -->

## Genie Team Quick Reference

This project uses **Genie Team** - specialized AI genies for product discovery and delivery.

### Start Here
- `/genie:help` - Show all commands
- `/genie:status` - Show current work status
- `/context:load` - Initialize full session context

### Common Workflows
| Command | Use When |
|---------|----------|
| `/feature [topic]` | Building something new end-to-end |
| `/bugfix [issue]` | Quick fix for a known issue |
| `/spike [question]` | Technical investigation/research |
| `/cleanup [scope]` | Reducing tech debt |

### The 6 D's Lifecycle
```
/discover → /shape → /design → /deliver → /discern
                                              ↓
                              /diagnose → /tidy
```

---

## Agent Conventions

If this project has agents installed (`.claude/agents/`), these conventions apply:

### Agent Output Standards
- All agents use the **Agent Result Format** with Task/Status/Confidence header
- Findings section uses genie-specific templates (Opportunity Snapshot, Design Document, etc.)
- Maximum **10 files** listed in "Files Examined" section
- Blockers always escalated to Navigator

### Context Boundaries
- Agents do **NOT** write files directly — they return content for orchestrator to write
- Agents do **NOT** use AskUserQuestion — they work autonomously
- Agents return **distilled summaries**, not raw exploration data
- Write artifacts to disk; reference by path (document trail is persistent memory)

### Available Agents
| Agent | Purpose | Tools |
|-------|---------|-------|
| `scout` | Discovery and problem exploration | Read, Glob, Grep, WebFetch, WebSearch |
| `architect` | Technical design and feasibility | Read, Glob, Grep, Bash (read-only) |
| `critic` | Code review and quality assessment | Read, Glob, Grep, Bash (test runners) |
| `tidier` | Cleanup analysis and refactoring recommendations | Read, Glob, Grep, Bash (git only) |

### Using Agents
Invoke via Task tool: `Task(subagent_type='scout', prompt='explore authentication patterns')`

---

## Project Context

### Overview
<!-- What this project does and why it exists -->

### Architecture
<!-- Key components and patterns -->

### Active Work
<!-- Current focus areas -->

### Conventions
<!-- Project-specific patterns and standards -->
