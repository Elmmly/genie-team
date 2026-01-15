# /genie:help

Display available Genie Team commands and current project status.

---

## Output

When invoked, display the following reference:

```
╭─────────────────────────────────────────────────────────────────╮
│  GENIE TEAM COMMANDS                                            │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  LIFECYCLE (the 7 D's)                                          │
│  ─────────────────────                                          │
│  /discover [topic]     Scout explores opportunities             │
│  /define [input]       Shaper frames work with appetite         │
│  /design [contract]    Architect creates technical design       │
│  /deliver [design]     Crafter implements with TDD              │
│  /discern [impl]       Critic reviews and validates             │
│  /done [concept]       Archive completed work                   │
│  /diagnose [scope]     Architect analyzes codebase health       │
│  /tidy [report]        Tidier executes cleanup                  │
│                                                                 │
│  WORKFLOWS (shortcuts)                                          │
│  ─────────────────────                                          │
│  /feature [topic]      Full lifecycle: discover → discern       │
│  /bugfix [issue]       Quick fix: shape → deliver → discern     │
│  /spike [question]     Research: discover → feasibility         │
│  /cleanup [scope]      Maintenance: diagnose → tidy             │
│                                                                 │
│  CONTEXT                                                        │
│  ───────                                                        │
│  /context:load         Initialize session with project context  │
│  /context:summary      Create end-of-session handoff            │
│  /context:recall       Find past work on a topic                │
│  /context:refresh      Update context from codebase             │
│                                                                 │
│  TRANSITIONS                                                    │
│  ───────────                                                    │
│  /handoff [from] [to]  Explicit phase transition                │
│  /commit [item]        Create conventional commit               │
│                                                                 │
│  HELP                                                           │
│  ────                                                           │
│  /genie:help           Show this reference (you are here)       │
│  /genie:status         Show current work and recent docs        │
│                                                                 │
╰─────────────────────────────────────────────────────────────────╯

WORKFLOW:  /discover → /define → /design → /deliver → /discern
                                                          ↓
FINALIZE:                                    /commit → /done

MAINTAIN:                               /diagnose → /tidy
```

---

## Sub-Commands

| Command | Purpose |
|---------|---------|
| `/genie:help` | Show command reference |
| `/genie:status` | Show current work status and recent documents |

---

## Notes

- Start a session with `/context:load` to initialize project context
- Use `/feature [topic]` for end-to-end delivery of new work
- Use `/bugfix [issue]` for quick fixes
- After any phase, the genie will suggest the natural next step
