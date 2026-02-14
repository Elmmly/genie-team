# /run [topic|backlog-item-path]

Orchestrate autonomous PDLC lifecycle: discover → define → design → deliver → discern → done → commit.

No confirmation prompts. No manual gates. Phases flow directly. Use `/discern` as the automated quality gate.

Unlike `/feature` (which pauses for user confirmation at each transition), `/run` executes the specified phase range without stopping — unless `/discern` returns BLOCKED.

---

## Prerequisites

`/run` is designed for unattended execution. Before invoking, ensure:

**Permissions:** The `genies` script skips permission prompts by default (passes `--dangerously-skip-permissions` to claude). To require interactive approvals, use `--no-skip-permissions`.

**Example:**
```bash
claude -p "/run \"add password reset\""
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
    ├─→ [cleanup] Remove compiled binaries
    │
    ├─→ /done [item_path]
    │   └─→ Archive completed work, update statuses
    │
    ├─→ [stage] Stage all session artifacts (including archive changes)
    │
    └─→ /commit [item_path]
        └─→ Create conventional commit (single commit for everything)
```

---

## Phase Range Model

The `--from` and `--through` flags define any contiguous range of the 7 D's:

```
discover → define → design → deliver → discern → done → commit
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

**Commit as utility:** Regardless of `--through`, the runner always commits
any uncommitted artifacts after the phase range completes. This prevents
work loss in worktree and batch modes where artifacts would otherwise be
destroyed on teardown. If `--through` already includes `commit` or `done`,
no extra commit is made (double-commit protection via `git status`).

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
- [ ] done
- [ ] commit

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
> [done] Archived to docs/archive/
> [commit] Complete

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
> [done] Archived
> [commit] Complete
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

### Preflight state propagation

After running preflight checks, set these session variables that later phases
reference:

| Variable | Source | Used By |
|----------|--------|---------|
| `PR_CREATION_MODE` | `gh auth status` exit code: 0 → `auto`, non-zero → `manual` | `/commit` phase |

When `PR_CREATION_MODE` is `manual`, note this in the preflight output:
> gh not authenticated — PR creation will be manual. Branch will be pushed,
> manual PR URL printed.

### Clean build state
Run the project's build and test commands. If either fails on the current branch before any changes are made, **STOP** — the codebase is broken and autonomous delivery will compound the problem.

### Context freshness
Read `docs/context/current_work.md` (if it exists) to orient the discovery phase. A fresh context file dramatically reduces scout exploration time — the difference between reading 3 files vs 46.

---

## Gate Behavior

When `/discern` is within the phase range:

| Verdict | Action |
|---------|--------|
| APPROVED | Continue to `/done` → `/commit` |
| BLOCKED | **STOP immediately**. Report what failed. Suggest next action. |
| CHANGES REQUESTED | Attempt one fix cycle (fix → retest → re-discern). If still not APPROVED, **STOP**. |
| (not parsed) | **STOP** (safe default). Report parsing failure. |

Stopping on BLOCKED matches the "genie grants wishes literally" philosophy — don't try to be clever about failures.

---

## Cleanup and Staging

Build artifact cleanup and file staging are split around the `/done` phase
so that archive changes (file moves, status updates) are included in the
single delivery commit.

### Before /done: Remove build artifacts

1. **Remove compiled binaries** — `go build ./...` may produce binaries in
   the repo root. Run `go clean` or delete explicitly. Check `.gitignore`
   covers build outputs.

### After /done, before /commit: Stage all artifacts

2. **Stage artifacts from this session** — Use the `artifacts_written` list
   from `.claude/session-state.md` (populated by the track-artifacts hook) to
   determine which files to stage. For each path in the list, run `git add`.
   Then check `git diff --name-only` for any modified tracked files not in the
   list (e.g., files modified by build tools) and stage those too.
   This now includes archive file moves and status updates from `/done`.
   **Never use `git add -A` or `git add .`** — this risks staging untracked
   files from previous sessions. If session-state.md is unavailable, fall back
   to `git diff --name-only HEAD` for tracked changes only.
3. **Verify nothing is left behind** — Run `git status` after staging.
   Untracked files NOT in the session's artifact list should be left unstaged
   (they belong to other sessions or are leftover artifacts).

---

## Phase Metrics

Track metrics as each phase completes. At the end of the run, include a
summary table:

| Phase | Artifacts | Notes |
|-------|-----------|-------|
| discover | docs/analysis/... | |
| define | docs/backlog/... | |
| design | (appended to backlog) | |
| deliver | 5 files changed | 17 tests pass |
| discern | APPROVED | |
| done | 2 archived | |
| commit | abc1234 | |

This gives operators per-phase visibility without parsing raw logs.

---

## Phase Completion Verification

After the final phase completes, verify ALL phases in the range executed.
Use the Progress tracker to check:

1. Every phase between `--from` and `--through` has a `[x]` checkmark
2. If any phase shows `[ ]` (unchecked), report it in the completion summary:

   > INCOMPLETE: The following phases were in range but did not execute:
   > - [phase name]
   >
   > Backlog item may have stale status. Run `/done [item_path]` manually.

3. The completion summary MUST include the verification result:
   - **All phases complete** — report normally
   - **Phases skipped** — report as INCOMPLETE with the list above

This verification runs even if the run appears successful. A committed
codebase with unarchived backlog items is an incomplete lifecycle.

---

## Notes

- No confirmation prompts — phases flow directly (unlike `/feature`)
- `/feature` remains the interactive shortcut with manual gates
- `/run` is lifecycle-agnostic: works for features, maintenance, quality improvements
- Conversation context is preserved across all phases (single session)
- The backlog item's frontmatter `status` field tracks progression
- For headless/cron use, see `scripts/genies` (available on PATH after global install)
- For overnight batch execution, use `genies --parallel N` (scans backlog, auto-detects phases)
- For large-appetite items, consider splitting: `--through design` then `--from deliver` in separate sessions to avoid context limits
