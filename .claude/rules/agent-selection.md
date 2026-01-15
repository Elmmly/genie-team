# Agent Selection Guide

Genie Team provides custom agents that extend Claude Code's built-in agents with workflow-specific behaviors.

## When to Use Custom Genie Agents

Use the **custom genie agents** when:
- Following the 7 D's workflow (discover → define → design → deliver → discern)
- You need structured output in genie-specific formats (Opportunity Snapshot, Shaped Contract, etc.)
- You want routing recommendations to the next workflow phase
- You're working within the backlog-centric document model

## Custom Genie Agents

| Agent | Purpose | Output Format |
|-------|---------|---------------|
| `scout` | Problem discovery and assumption surfacing | Agent Result: Opportunity Snapshot |
| `architect` | Technical design within shaped boundaries | Agent Result: Design Document |
| `critic` | Code review with acceptance verdicts | Agent Result: Review Document |
| `tidier` | Cleanup analysis and prioritization | Agent Result: Cleanup Report |

## When to Use Built-in Claude Code Agents

Use the **built-in agents** when:
- Doing quick exploration without workflow context
- Not following the genie team methodology
- Need general-purpose functionality

| Built-in Agent | Use For |
|----------------|---------|
| `Explore` | Quick codebase searches, finding files |
| `Plan` | General implementation planning |

## Invocation Examples

**Custom genie agent:**
```
Task(subagent_type='scout', prompt='explore user authentication pain points')
```

**Built-in agent:**
```
Task(subagent_type='Explore', prompt='find all API endpoint files')
```

## Key Differences

1. **Output Format**: Custom agents return structured Agent Result Format with genie-specific sections
2. **Routing**: Custom agents recommend next workflow phases
3. **Context**: Custom agents reference CLAUDE.md and project conventions
4. **Isolation**: Custom agents use `context: fork` for analysis isolation
