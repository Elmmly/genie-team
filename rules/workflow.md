# Genie Team Workflow

## The 7 D's Lifecycle

```
/discover → /define → /design → /deliver → /discern → /done
                                              ↓
                              /diagnose → /tidy

/commit — anytime there are changes worth committing
```

## Command Quick Reference

### Primary Lifecycle
| Command | Genie | Purpose |
|---------|-------|---------|
| `/discover [topic]` | Scout | Explore opportunities and surface assumptions |
| `/define [input]` | Shaper | Frame problem with appetite boundaries |
| `/design [contract]` | Architect | Create technical design |
| `/deliver [design]` | Crafter | TDD implementation |
| `/discern [impl]` | Critic | Review and approve/reject |
| `/commit [item]` | — | Create conventional commit |
| `/done [item]` | — | Archive completed work |

### Maintenance Cycle
| Command | Genie | Purpose |
|---------|-------|---------|
| `/diagnose [scope]` | Architect | Scan codebase health |
| `/tidy [report]` | Tidier | Execute safe cleanup |

### Workflow Shortcuts
| Command | Flow |
|---------|------|
| `/feature [topic]` | Full lifecycle (discover → discern) |
| `/bugfix [issue]` | Quick fix (define → discern) |
| `/spike [question]` | Technical investigation |
| `/cleanup [scope]` | Maintenance (diagnose → tidy) |

### Context Management
| Command | Purpose |
|---------|---------|
| `/context:load` | Initialize session |
| `/context:summary` | End-of-session handoff |
| `/context:recall [topic]` | Find past work |
| `/genie:help` | Show all commands |
| `/genie:status` | Current work status |

## Handoffs

Use `/handoff [from] [to]` for explicit phase transitions with context summarization.

## Document Trail

All outputs create persistent artifacts:
- `docs/analysis/` — Discovery and design documents
- `docs/backlog/` — Living backlog items (shaped → designed → implemented → reviewed)
- `docs/archive/` — Completed work
