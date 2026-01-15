# /cleanup [scope]

Debt reduction workflow: diagnose → tidy (batched).

---

## Arguments

- `scope` - Area to clean: module, directory, or "full" (optional, defaults to full)
- Optional flags:
  - `--continue` - Continue from previous cleanup session
  - `--priority [high/medium/low]` - Focus on specific priority items

---

## Workflow

```
/cleanup src/services
    │
    ├─→ /diagnose src/services
    │   └─→ Architect scans for issues
    │   └─→ Produces prioritized cleanup list
    │
    └─→ /tidy [diagnose-report]
        └─→ Tidier executes batches
        └─→ Tests after each batch
        └─→ Progress tracked
```

---

## Progress Tracking

Cleanup maintains state in `docs/cleanup/defrag-progress.md`:

```markdown
# Defrag Progress

## Current Cleanup: services
- **Started:** 2024-12-03
- **Status:** In Progress
- **Batches:** 3/7 complete

## Completed
- [x] Dead code removal - 2024-12-03
- [x] Import cleanup - 2024-12-03
- [x] Naming consistency - 2024-12-03

## Remaining
- [ ] Dependency updates
- [ ] Test coverage gaps
- [ ] Documentation

## Blocked
- [ ] Config refactor - needs Architect input
```

---

## Usage Examples

```
/cleanup
> Starting cleanup workflow (full codebase)
>
> [Architect diagnosing...]
> Health score: 72/100
> Issues found: 15
> Priority breakdown:
> - High: 2 items
> - Medium: 8 items
> - Low: 5 items
>
> Proceeding to tidy...
>
> [Tidier executing...]
> Batch 1: Complete (tests pass)
> Batch 2: Complete (tests pass)
> Progress: 2/6 batches
>
> Session saved. Continue with /cleanup --continue

/cleanup --continue
> Resuming cleanup workflow
> Progress: 2/6 batches complete
> Continuing with Batch 3...
```

---

## Session Management

Cleanup can span multiple sessions:
1. First session: Diagnose + initial batches
2. Subsequent sessions: `--continue` to resume
3. Progress persisted in defrag-progress.md

---

## Routing

- **In progress**: Continue with `--continue`
- **Blocked**: Escalate to Architect
- **Complete**: Archive diagnose report, reset progress
- **Critical issues**: Escalate to Navigator

---

## Notes

- Safe, incremental debt reduction
- Progress survives session boundaries
- Test-gated (never breaks tests)
- Creates audit trail of cleanup work
- Can be paused and resumed
