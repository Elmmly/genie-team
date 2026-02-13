# /run [topic|backlog-item-path]

Orchestrate autonomous PDLC lifecycle: discover → define → design → deliver → discern → commit → done.

No confirmation prompts. No manual gates. Phases flow directly. Use `/discern` as the automated quality gate.

Unlike `/feature` (which pauses for user confirmation at each transition), `/run` executes the specified phase range without stopping — unless `/discern` returns BLOCKED.

---

## Arguments

- `topic|backlog-item-path` - What to work on (required)
  - Topic string: starts from `/discover` (e.g., "add password reset")
  - Backlog item path: continues from current status (e.g., `docs/backlog/P2-auth.md`)
- Optional flags:
  - `--from <phase>` - Start at this phase (default: discover)
  - `--through <phase>` - Stop AFTER this phase (default: done)

---

## Workflow

```
/run "add password reset"
    │
    ├─→ /discover "add password reset"
    │   └─→ Scout produces Opportunity Snapshot
    │       └─→ Parse analysis_path from output
    │
    ├─→ /define [analysis_path]
    │   └─→ Shaper produces Shaped Contract
    │       └─→ Parse item_path from output
    │
    ├─→ /design [item_path]
    │   └─→ Architect appends design to backlog item
    │
    ├─→ /deliver [item_path]
    │   └─→ Crafter implements with TDD
    │
    ├─→ /discern [item_path]     ◄── AUTOMATED QUALITY GATE
    │   ├─→ APPROVED → continue
    │   └─→ BLOCKED → STOP, report failure
    │
    ├─→ /commit [item_path]
    │   └─→ Create conventional commit
    │
    └─→ /done [item_path]
        └─→ Archive completed work
```

---

## Phase Range Model

The `--from` and `--through` flags define any contiguous range of the 7 D's:

```
discover → define → design → deliver → discern → commit → done
         ^                           ^
      --from                     --through
```

| Example | Phases Run | Use Case |
|---------|-----------|----------|
| (no flags) | discover → done | Full autonomous lifecycle |
| `--through define` | discover → define | Daily discovery pipeline |
| `--from design --through deliver` | design → deliver | Implement approved items |
| `--from discern` | discern → done | Review and close |
| `--from deliver --through deliver` | deliver | Single phase execution |

**Validation rules:**
- `--from` must precede `--through` in the phase sequence
- `--from design` or later requires a backlog item path (not a topic string)

---

## State Tracking

Two variables track artifacts across phases:

1. `analysis_path` — output of `/discover` (consumed by `/define`)
2. `item_path` — output of `/define` (consumed by all subsequent phases)

When `--from` is `design` or later, the user provides `item_path` directly as input.

```markdown
# Autonomous Run: [Topic]

**Status:** [phase] of [total]
**Range:** [from_phase] → [through_phase]
**Started:** [timestamp]

## Progress
- [x] discover - docs/analysis/...
- [x] define - docs/backlog/...
- [ ] design
- [ ] deliver
- [ ] discern
- [ ] commit
- [ ] done

## Artifacts
- analysis_path: [path]
- item_path: [path]
- verdict: [APPROVED/BLOCKED]
```

---

## Usage Examples

```
# Full lifecycle — discover through done
/run "add password reset"
> Starting autonomous PDLC: discover → done
> Input: "add password reset"
>
> [discover] Starting...
> [discover] Complete — docs/analysis/20260212_discover_password_reset.md
> [define] Starting...
> [define] Complete — docs/backlog/P2-password-reset.md
> [design] Starting...
> ...
> [discern] Verdict: APPROVED
> [commit] Complete
> [done] Archived to docs/archive/

# Discover and define only — stop for human review
/run --through define "add password reset"
> Starting autonomous PDLC: discover → define
> ...
> [define] Complete — docs/backlog/P2-password-reset.md
> PDLC completed: discover → define

# Design through delivery on existing item
/run --from design --through deliver docs/backlog/P2-auth.md
> Starting autonomous PDLC: design → deliver
> Input: docs/backlog/P2-auth.md
> ...
> [deliver] Complete
> PDLC completed: design → deliver

# Review and close
/run --from discern docs/backlog/P2-auth.md
> Starting autonomous PDLC: discern → done
> ...
> [discern] Verdict: APPROVED
> [commit] Complete
> [done] Archived
```

---

## Gate Behavior

When `/discern` is within the phase range:

| Verdict | Action |
|---------|--------|
| APPROVED | Continue to `/commit` → `/done` |
| BLOCKED | **STOP immediately**. Report what failed. Suggest next action. |
| CHANGES REQUESTED | **STOP immediately**. Report feedback. |
| (not parsed) | **STOP** (safe default). Report parsing failure. |

Stopping on BLOCKED matches the "genie grants wishes literally" philosophy — don't try to be clever about failures.

---

## Notes

- No confirmation prompts — phases flow directly (unlike `/feature`)
- `/feature` remains the interactive shortcut with manual gates
- `/run` is lifecycle-agnostic: works for features, maintenance, quality improvements
- Conversation context is preserved across all phases (single session)
- The backlog item's frontmatter `status` field tracks progression
- For headless/cron use, see `scripts/run-pdlc.sh`
