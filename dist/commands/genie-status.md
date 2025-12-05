# /genie:status

Show current work status and recent document trail.

---

## Output

When invoked, scan the project and display:

```
╭─────────────────────────────────────────────────────────────────╮
│  GENIE TEAM STATUS                                              │
├─────────────────────────────────────────────────────────────────┤
│                                                                 │
│  CURRENT WORK                                                   │
│  ────────────                                                   │
│  [Read docs/context/current_work.md and summarize]              │
│                                                                 │
│  RECENT DOCUMENTS                                               │
│  ────────────────                                               │
│  [List recent files in docs/analysis/ and docs/backlog/]        │
│  • YYYYMMDD_discover_topic.md                                   │
│  • YYYYMMDD_design_topic.md                                     │
│  • P1-topic.md                                                  │
│                                                                 │
│  BACKLOG                                                        │
│  ───────                                                        │
│  [Summarize items in docs/backlog/]                             │
│                                                                 │
╰─────────────────────────────────────────────────────────────────╯
```

---

## Context Loading

**READ (automatic):**
- docs/context/current_work.md
- docs/context/recent_decisions.md
- docs/backlog/*.md (titles only)
- docs/analysis/*.md (recent, titles only)

---

## Notes

- Run at start of session to see where you left off
- Helps identify stale work that needs attention
- Use `/context:load` for full context initialization
