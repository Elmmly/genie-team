# /run [topic|backlog-item-path]

Orchestrate autonomous PDLC lifecycle: discover → define → design → deliver → discern → commit → done.

No confirmation prompts. No manual gates. Phases flow directly. Use `/discern` as the automated quality gate.

Unlike `/feature` (which pauses for user confirmation at each transition), `/run` executes the specified phase range without stopping — unless `/discern` returns BLOCKED.

---

## Prerequisites

`/run` is designed for unattended execution. Before invoking, ensure:

**Permissions:** Claude Code's permission system will block file writes in default mode. Run with one of:
- `--dangerously-skip-permissions` (simplest for unattended runs)
- `--allowedTools "Read,Write,Edit,Glob,Grep,Bash,Task,Skill,TodoWrite"` (scoped)

**Example:**
```bash
claude -p --dangerously-skip-permissions "/run \"add password reset\""
```

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
    ├─→ [preflight] Verify toolchain and context
    │   ├─→ Check required tools (go/npm/make, gh, git)
    │   ├─→ Check build passes on clean state
    │   ├─→ Check tests pass on clean state
    │   └─→ FAIL → STOP, report what's missing
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

## Preflight Check

Before starting any phase, run a preflight check. If any check fails, **STOP immediately** and report what's missing.

### Required tools
Verify each tool exists and is authenticated:

| Tool | Check | Why |
|------|-------|-----|
| `git` | `git status` | Branch creation, commits |
| `gh` | `gh auth status` | PR creation in commit phase |
| Build toolchain | `make build` or `go build ./...` or `npm run build` | Deliver phase needs to compile |
| Test runner | `make test` or `go test ./...` or `npm test` | TDD cycle, discern gate |

If `gh` is not installed or not authenticated, warn but continue — the commit phase will push the branch and print a manual PR URL as fallback.

### Clean build state
Run the project's build and test commands. If either fails on the current branch before any changes are made, **STOP** — the codebase is broken and autonomous delivery will compound the problem.

### Context freshness
Read `docs/context/current_work.md` (if it exists) to orient the discovery phase. A fresh context file dramatically reduces scout exploration time — the difference between reading 3 files vs 46.

---

## Gate Behavior

When `/discern` is within the phase range:

| Verdict | Action |
|---------|--------|
| APPROVED | Continue to `/commit` → `/done` |
| BLOCKED | **STOP immediately**. Report what failed. Suggest next action. |
| CHANGES REQUESTED | Attempt one fix cycle (fix → retest → re-discern). If still not APPROVED, **STOP**. |
| (not parsed) | **STOP** (safe default). Report parsing failure. |

Stopping on BLOCKED matches the "genie grants wishes literally" philosophy — don't try to be clever about failures.

---

## Cleanup Before Commit

Before the `/commit` phase, clean up build artifacts created during `/deliver`:

1. **Remove compiled binaries** — `go build ./...` may produce binaries in the repo root. Run `go clean` or delete explicitly. Check `.gitignore` covers build outputs.
2. **Stage ALL artifacts** — The commit must include everything created during the run:
   - Source code and tests (the implementation)
   - `docs/analysis/` snapshots (from `/discover`)
   - `docs/backlog/` updates (from `/define`, `/design`, `/deliver`, `/discern`)
   - `docs/context/current_work.md` updates
   - Any new config files, dashboards, migrations
3. **Verify nothing is left behind** — Run `git status` after staging. Untracked files created during the run that aren't in `.gitignore` should be either staged or explicitly cleaned up.

---

## Notes

- No confirmation prompts — phases flow directly (unlike `/feature`)
- `/feature` remains the interactive shortcut with manual gates
- `/run` is lifecycle-agnostic: works for features, maintenance, quality improvements
- Conversation context is preserved across all phases (single session)
- The backlog item's frontmatter `status` field tracks progression
- For headless/cron use, see `scripts/run-pdlc.sh`
- For large-appetite items, consider splitting: `--through design` then `--from deliver` in separate sessions to avoid context limits
