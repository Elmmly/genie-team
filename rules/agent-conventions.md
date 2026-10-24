# Agent Conventions

When using agents via Task tool, these conventions apply.

## Agent Output Standards

- All agents use the **Agent Result Format** with Task/Status/Confidence header
- Findings section uses genie-specific templates
- Maximum **10 files** listed in "Files Examined" section
- Blockers always escalated to Navigator

## Context Boundaries

- Agents do **NOT** write files directly — they return content for orchestrator to write
  - **Exception:** a Crafter or Tidier dispatched by the Director writes files
    inside its own worktree, and commits there. Analysis genies (and the Critic) still
    return content
- Agents do **NOT** use AskUserQuestion — they work autonomously
- Agents return **distilled summaries**, not raw exploration data
- Write artifacts to disk; reference by path (document trail is persistent memory)

## Available Agents

| Agent | Purpose | Tools |
|-------|---------|-------|
| `scout` | Discovery and problem exploration | Read, Glob, Grep, WebFetch, WebSearch |
| `architect` | Technical design and feasibility | Read, Glob, Grep, Bash |
| `critic` | Code review and quality assessment | Read, Glob, Grep, Bash, Skill |
| `tidier` | Cleanup analysis and refactoring | Read, Glob, Grep, Bash, Skill |
| `crafter` | TDD implementation (dispatched by the Director, in a worktree) | Read, Glob, Grep, Bash, Write, Edit, Skill |

The `director` genie is never invoked through the Task tool: `/direct` loads it on the main
thread so it can dispatch the others.

## Using Agents

Invoke via Task tool:
```
Task(subagent_type='scout', prompt='explore authentication patterns')
```

Agents with `context: fork` run in isolated context for better separation.
