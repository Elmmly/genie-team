# /feature [topic]

Orchestrate full feature lifecycle: discover → define → design → deliver → discern.

---

## Arguments

- `topic` - Feature to build (required)
- Optional flags:
  - `--skip-discover` - Start from defining (topic already explored)
  - `--resume` - Continue from last checkpoint

---

## Workflow

```
/feature "user authentication"
    │
    ├─→ /context:recall "authentication"
    │   └─→ Check for existing work
    │
    ├─→ /discover "user authentication"
    │   └─→ Scout produces Opportunity Snapshot
    │
    ├─→ /handoff discover define
    │   └─→ Transition summary
    │
    ├─→ /define [discovery-output]
    │   └─→ Shaper produces Shaped Contract
    │
    ├─→ /handoff define design
    │   └─→ Transition summary
    │
    ├─→ /design [shaped-contract]
    │   └─→ Architect produces Design Document
    │
    ├─→ /handoff design deliver
    │   └─→ Transition summary
    │
    ├─→ /deliver [design-doc]
    │   └─→ Crafter implements with TDD
    │
    ├─→ /handoff deliver discern
    │   └─→ Transition summary
    │
    └─→ /discern [implementation]
        └─→ Critic reviews → APPROVED / CHANGES REQUESTED
```

---

## State Tracking

```markdown
# Feature Workflow: [Topic]

**Status:** [Phase] of 5
**Started:** [Date]
**Current phase:** [discover/define/design/deliver/discern]

## Progress
- [x] Discover - docs/analysis/...
- [x] Define - docs/backlog/...
- [ ] Design
- [ ] Deliver
- [ ] Discern

## Artifacts
- Discovery: [path]
- Shaped contract: [path]
- Design doc: [path]
- Implementation: [path]
- Review: [path]
```

---

## Usage Examples

```
/feature "dark mode support"
> Starting feature workflow for "dark mode support"
> Checking for existing work...
> No previous work found.
>
> Phase 1/5: Discovery
> [Scout begins opportunity discovery]

/feature --resume
> Resuming feature workflow: "dark mode support"
> Current phase: Design (3/5)
> Last activity: Shaped contract created yesterday
>
> Continuing with /design docs/backlog/P2-dark-mode.md
```

---

## Phase Transitions

User confirms before each phase transition:
- "Discovery complete. Ready to shape? (y/n)"
- "Shaping complete. Ready to design? (y/n)"
- etc.

This prevents runaway automation and maintains Navigator control.

---

## Notes

- Full end-to-end orchestration
- Checkpointed progress (can resume)
- Creates complete document trail
- User confirms each transition
- Can skip phases if appropriate
