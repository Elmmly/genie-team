---
spec_version: "1.0"
type: shaped-work
id: session-management
title: "Session Management for Parallel Worktree Sessions"
status: done
created: 2026-02-12
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
builds_on:
  - docs/archive/workflow/2026-02-12_parallel-sessions-git-worktrees/P2-parallel-sessions-git-worktrees.md
spec_ref: docs/specs/workflow/parallel-sessions.md
adr_refs:
  - docs/decisions/ADR-001-thin-orchestrator.md
tags: [workflow, parallel, sessions, worktree, convenience, pr, merge]
acceptance_criteria:
  - id: AC-1
    description: "A `session start` command creates a named worktree with correct branch naming convention, prints the path, and provides copy-pasteable next steps (cd + claude)"
    status: pending
  - id: AC-2
    description: "A `session list` command shows all active worktree sessions with branch name, path, and merge status (merged/unmerged to default branch — no process monitoring)"
    status: pending
  - id: AC-3
    description: "A `session finish` command handles the full close-out: creates a PR (default in PR mode) or merges to main (trunk-based mode), removes the worktree, and deletes the branch after merge"
    status: pending
  - id: AC-4
    description: "A `session cleanup` command removes all finished sessions (worktrees whose branches have been merged) in a single operation"
    status: pending
  - id: AC-5
    description: "The script exposes sourceable functions with documented signatures and return codes: session_start(), session_finish(), session_worktree_path(), session_cleanup_item() — enabling the autonomous runner to source genie-session.sh and call functions directly without subshell overhead"
    status: pending
  - id: AC-6
    description: "Session finish in PR mode uses `gh pr create` with a conventional title and body that references the backlog item; falls back to merge instructions if gh CLI is unavailable"
    status: pending
  - id: AC-7
    description: "A `session_cleanup_item` function removes a specific item's worktree and branch (even if unmerged), enabling the autonomous runner to clean up prior failed attempts before retrying"
    status: pending
  - id: AC-8
    description: "Session finish supports a `--force` flag that removes the worktree and deletes the branch without requiring a clean merge state, enabling the runner's --cleanup-on-failure mode"
    status: pending
---

# Shaped Work Contract: Session Management for Parallel Worktree Sessions

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Problem:** Using parallel genie-team sessions requires 3 manual git steps to start (worktree add, cd, claude) and 3 manual steps to finish (merge/PR, worktree remove, branch delete). Users must remember the branch naming convention (`genie/{item}-{phase}`), the worktree naming convention (`../project--session`), and the correct sequence for teardown. Getting any step wrong leaves orphaned worktrees or branches.

**Who's affected:**
- Human users running interactive parallel sessions — the most common case today
- The upcoming autonomous lifecycle runner (P2-autonomous-lifecycle-runner, designed) — needs the same worktree lifecycle logic

**Evidence:**
- The parallel-sessions spec (6/6 ACs met) established worktree isolation but explicitly deferred lifecycle management: "Worktree lifecycle management is the user's or orchestrator's responsibility"
- The autonomous runner design (P2-autonomous-lifecycle-runner, status: designed) explicitly sources `genie-session.sh` for worktree lifecycle — it calls `session_start()`, `session_finish()`, `session_worktree_path()`, and `session_cleanup_item()`. These function signatures are locked in the runner's design.
- The forward-compatibility table in the parallel-sessions spec identified "No worktree cleanup convention for failed autonomous runs" as Critical severity

**What's actually missing:** A thin convenience layer that wraps git worktree ceremony into memorable commands, handles the PR/merge workflow, and is reusable by the autonomous runner.

## Behavioral Delta

**Spec:** docs/specs/workflow/parallel-sessions.md

### Current Behavior
- AC-1: Multiple sessions can operate simultaneously using git worktrees (met)
- AC-2: install.sh supports worktree installation (met)
- No ACs cover session lifecycle management (create, list, finish, cleanup)

### Proposed Changes
- AC-NEW (AC-7): Session lifecycle commands exist for creating, listing, finishing, and cleaning up worktree sessions
- AC-NEW (AC-8): Session finish handles PR creation or direct merge based on git workflow mode
- AC-NEW (AC-9): Session management functions are sourceable by external scripts with documented signatures and return codes
- AC-NEW (AC-10): Targeted item cleanup function removes a specific item's worktree and branch regardless of merge state
- AC-NEW (AC-11): Force-finish mode removes worktree and branch without requiring clean merge (for autonomous failure cleanup)

### Rationale
The parallel sessions capability delivered the isolation mechanism but left the lifecycle ceremony to users. This creates friction that discourages adoption and will cause duplication when the autonomous runner is built.

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days)
  - Single bash script with 4 subcommands (~0.5 day with TDD)
  - PR/merge workflow with gh CLI integration (~0.25 day)
  - install.sh distribution (~0.25 day)
  - Tests (~0.5 day)
- **No-gos:**
  - No process monitoring (don't track whether Claude is "running" — just show worktrees and branch state)
  - No integration with Claude Code internals (pure git + gh operations)
  - No automatic merge conflict resolution — show the conflict, let the user handle it
  - No changes to existing genie-team commands
- **Fixed elements:**
  - Must follow existing branch naming convention (`genie/{item}-{phase}`)
  - Must follow existing worktree naming convention (`../project--session-name`)
  - Must respect PR mode vs trunk-based mode from CLAUDE.md
  - Must be pure bash (consistent with install.sh and future runner)
  - Must be distributable via `install.sh`

## Goals & Outcomes

**Outcome hypothesis:** "A `genie-session` script will reduce parallel session ceremony from 6 manual git steps (3 start + 3 finish) to 2 commands (`session start` + `session finish`), and provide the worktree lifecycle functions the autonomous runner needs."

**Success signals:**
- User runs `genie-session start P2-search deliver` → gets worktree + branch + instructions in one step
- User runs `genie-session finish P2-search` → PR created, worktree removed, branch cleaned up
- User runs `genie-session list` → sees all active sessions at a glance
- Autonomous runner script sources `genie-session` functions for worktree lifecycle
- No orphaned worktrees or branches after normal usage

## Solution Sketch

### Interface

```bash
# Start a new session
genie-session start <item> <phase>
# → Creates ../project--item at branch genie/item-phase
# → Prints: cd ../project--item && claude
# → Returns 0 on success, 1 on failure
# Example: genie-session start P2-search deliver

# List active sessions
genie-session list
# → Shows worktree path, branch, merge status (merged/unmerged)

# Finish a session (PR mode — default)
genie-session finish <item> [--merge] [--force]
# → Creates PR via gh, removes worktree, deletes branch
# → --merge: direct merge to main instead of PR
# → --force: remove worktree + branch without requiring clean merge
#            (for cleanup of failed runs — skips PR/merge, just removes)
# → Returns 0 on success, 1 on failure, 2 on merge conflict
# Example: genie-session finish P2-search

# Clean up a specific item's session (even if unmerged)
genie-session cleanup-item <item>
# → Removes the item's worktree and branch regardless of merge state
# → Used by autonomous runner to clean up prior failed attempts
# Example: genie-session cleanup-item P2-search

# Clean up all merged sessions
genie-session cleanup
# → Removes worktrees whose branches are already merged to main
```

### PR/Merge Workflow (the "how do changes get back to main" question)

The session `finish` command handles the full close-out based on git workflow mode:

**PR Mode (default):**

```
genie-session finish P2-search
```

1. Check for uncommitted changes in worktree → warn if present
2. Push branch to origin: `git push -u origin genie/P2-search-deliver`
3. Create PR via `gh pr create`:
   - Title: conventional commit format (e.g., "feat(search): implement search redesign")
   - Body: references backlog item path, lists changed files
   - Base: main/master (default branch)
4. Remove worktree: `git worktree remove ../project--P2-search`
5. Print PR URL
6. Branch cleanup happens after PR merge (user merges PR, then `session cleanup` deletes stale branches)

**If `gh` CLI is not available:** Skip PR creation, print manual instructions:
```
Branch genie/P2-search-deliver pushed to origin.
Create PR manually: https://github.com/org/repo/compare/genie/P2-search-deliver
```

**Trunk-based mode (`--merge` flag or CLAUDE.md signal):**

```
genie-session finish P2-search --merge
```

1. Check for uncommitted changes → warn if present
2. Switch to main: `git checkout main` (from main worktree, not the session worktree)
3. Merge: `git merge genie/P2-search-deliver`
   - If merge conflict → print conflict files, return exit code 2
   - If clean merge → continue
4. Remove worktree: `git worktree remove ../project--P2-search`
5. Delete branch: `git branch -d genie/P2-search-deliver`
6. Optionally push: prompt or `--push` flag

**Force mode (`--force` flag — for autonomous runner cleanup):**

```
genie-session finish P2-search --force
```

1. Remove worktree: `git worktree remove --force ../project--P2-search`
2. Delete branch: `git branch -D genie/P2-search-deliver` (capital -D, force delete even if unmerged)
3. No PR, no merge, no uncommitted changes check
4. Always returns 0 (best-effort cleanup)

This mode exists for the autonomous runner's `--cleanup-on-failure` flag. Interactive users should use normal finish (PR or merge).

**Merge conflict handling (both modes):**

Conflicts are expected when parallel sessions edit the same files. The session helper doesn't resolve conflicts — it surfaces them clearly:

```
⚠ Merge conflict in 2 files:
  - src/search/index.ts
  - docs/backlog/P2-search.md

Resolve conflicts, then run:
  git add . && git commit
  genie-session cleanup
```

### Reusability for Autonomous Runner

The script exposes sourceable functions with documented return codes. When sourced (not executed), it provides the function API without running the CLI dispatcher.

```bash
# In run-pdlc.sh:
source "$(dirname "$0")/genie-session.sh"

# Clean up prior failed attempt before retry
session_cleanup_item "$item_slug"      # Returns 0 (even if no prior session)

# Create worktree + branch
session_start "$item_slug" "run"       # Returns 0=success, 1=failure
# → Creates ../project--item-slug at branch genie/item-slug-run

# Resolve worktree directory
worktree_dir=$(session_worktree_path "$item_slug")  # Prints path to stdout

# Close out: PR + worktree removal + branch cleanup
session_finish "$item_slug"            # Returns 0=success, 1=failure, 2=merge conflict
session_finish "$item_slug" --pr       # Explicit PR mode (same as default)
session_finish "$item_slug" --merge    # Trunk-based: merge to main instead of PR

# Force-remove on failure (runner's --cleanup-on-failure)
session_finish "$item_slug" --force    # Returns 0 (always — best-effort removal)
```

**Function contract:**

| Function | Args | Returns | Stdout | Stderr |
|----------|------|---------|--------|--------|
| `session_start` | `<item> <phase>` | 0=success, 1=failure | worktree path | progress/errors |
| `session_finish` | `<item> [--pr\|--merge\|--force]` | 0=success, 1=failure, 2=conflict | PR URL (if PR mode) | progress/errors |
| `session_worktree_path` | `<item>` | 0=found, 1=not found | worktree path | errors |
| `session_cleanup_item` | `<item>` | 0 (always) | — | progress/errors |

This means the autonomous runner doesn't reinvent worktree lifecycle — it calls the same functions humans use. The runner adds phase execution, lockfile, retry, and verdict detection on top.

### Distribution

- Script lives at `scripts/genie-session.sh`
- `install.sh` copies to target project's `scripts/` directory
- For global installs: scripts go to `~/.claude/scripts/` (or user adds to PATH)

## Risks & Assumptions

| Assumption | Type | Confidence | Test |
|------------|------|------------|------|
| `gh` CLI is available for PR creation | Feasibility | Medium | Graceful fallback to manual instructions when gh is missing |
| Users have push access to create PRs | Feasibility | High | Standard development workflow |
| Worktree naming convention won't collide | Feasibility | High | Includes item slug which is unique per backlog item |
| Autonomous runner will reuse session functions | Value | High | Runner design (status: designed) explicitly sources genie-session.sh with 4 function signatures locked |
| Source mode (sourced vs executed) works reliably in bash | Feasibility | High | Standard bash pattern — guard main logic with `[[ "${BASH_SOURCE[0]}" == "${0}" ]]` |
| Return codes + stdout/stderr separation is sufficient for runner integration | Feasibility | High | Runner only needs path strings (stdout) and success/failure (return code) |

### Rabbit Holes to Avoid

- **Process monitoring** — Don't try to detect if Claude is running in a worktree. `git worktree list` + branch state is sufficient.
- **Conflict resolution** — Don't auto-resolve merge conflicts. Surface them, let the human decide.
- **Cross-session awareness** — Don't build coordination between sessions. Each session is independent.
- **Dashboard/UI** — `session list` is a terminal command, not a web interface.

## Options (Ranked)

### Option 1: Standalone `genie-session.sh` script (Recommended)

- **Description:** New script in `scripts/` with start/list/finish/cleanup subcommands. Sourceable by the autonomous runner.
- **Pros:** Standalone, testable, reusable, focused. Ships immediately without waiting for the runner.
- **Cons:** Another script to distribute. Users need to know about it.
- **Appetite fit:** Small — 1-2 days

### Option 2: Add `session` subcommand to `install.sh`

- **Description:** Extend install.sh with `./install.sh session start/list/finish/cleanup`
- **Pros:** Single entry point users already know. No new script to learn.
- **Cons:** install.sh is already 800+ lines. Mixes installation concerns with runtime operations. Harder for runner to source individual functions.
- **Appetite fit:** Small — 1-2 days

### Option 3: Shell aliases in CLAUDE.md template

- **Description:** Document shell aliases in the CLAUDE.md template that users copy to their profile.
- **Pros:** Zero code. Users customize freely.
- **Cons:** No PR workflow, no cleanup, no reusability. Just start shortcuts.
- **Appetite fit:** Tiny — 0.25 day (but doesn't solve the real problem)

## Dependencies

- **Builds on:** P2-parallel-sessions-git-worktrees (worktree isolation, branch naming, safety rules)
- **Feeds into:** P2-autonomous-lifecycle-runner (status: designed) — runner's design explicitly sources `genie-session.sh` for:
  - `session_start()` — worktree + branch creation
  - `session_finish()` — PR/merge + worktree cleanup (including `--force` for failure cleanup)
  - `session_worktree_path()` — resolve worktree directory
  - `session_cleanup_item()` — remove prior failed attempts before retry
- **Integration contract:** Runner expects functions to be sourceable (not just CLI subcommands), with return codes on stdout/stderr separation documented above
- **Optional:** `gh` CLI for PR creation (graceful fallback without it)

## Routing

- [ ] **Architect** — Design function signatures, error handling, and integration surface for the runner
- [ ] **Crafter** — Build and test `genie-session.sh`

**Rationale:** Small scope with clear patterns from install.sh. Architect designs the function interface that both humans and the runner will use. Crafter implements with TDD.

## Artifacts

- **Contract saved to:** `docs/backlog/P2-session-management.md`
- **Spec updated:** `docs/specs/workflow/parallel-sessions.md` (new ACs appended)

---

# Design: Session Management for Parallel Worktree Sessions

> **Schema:** `schemas/design-document.schema.md` v1.0

```yaml
spec_version: "1.0"
type: design
id: session-management-design
title: "Session Management for Parallel Worktree Sessions"
status: designed
created: 2026-02-12
spec_ref: docs/backlog/P2-session-management.md
appetite: small
complexity: simple
author: architect
ac_mapping:
  - ac_id: AC-1
    approach: "session_start() creates worktree + branch via git worktree add, prints path to stdout, prints next steps to stderr"
    components: ["scripts/genie-session.sh"]
  - ac_id: AC-2
    approach: "session_list() parses git worktree list --porcelain, filters for genie/ branches, checks merge status via git branch --merged"
    components: ["scripts/genie-session.sh"]
  - ac_id: AC-3
    approach: "session_finish() dispatches to _gs_finish_pr(), _gs_finish_merge(), or _gs_finish_force() based on flags"
    components: ["scripts/genie-session.sh"]
  - ac_id: AC-4
    approach: "session_cleanup() iterates genie/ worktrees, filters to merged branches, calls session_cleanup_item() for each"
    components: ["scripts/genie-session.sh"]
  - ac_id: AC-5
    approach: "Source guard pattern: functions defined at top level, CLI dispatcher gated by BASH_SOURCE check"
    components: ["scripts/genie-session.sh"]
  - ac_id: AC-6
    approach: "_gs_finish_pr() checks for gh CLI availability, falls back to manual instructions with compare URL"
    components: ["scripts/genie-session.sh"]
  - ac_id: AC-7
    approach: "session_cleanup_item() uses git worktree remove --force and git branch -D, always returns 0"
    components: ["scripts/genie-session.sh"]
  - ac_id: AC-8
    approach: "session_finish --force delegates to _gs_finish_force() which skips all checks and force-removes"
    components: ["scripts/genie-session.sh"]
components:
  - name: "genie-session.sh"
    action: create
    files: ["scripts/genie-session.sh"]
  - name: "install.sh"
    action: modify
    files: ["install.sh"]
  - name: "test_session.sh"
    action: create
    files: ["tests/test_session.sh"]
```

## Overview

A single bash script (`scripts/genie-session.sh`) that wraps git worktree ceremony into memorable commands and sourceable functions. The script operates in two modes: CLI mode (subcommand dispatch for human users) and library mode (sourced by the autonomous runner for direct function calls). No new dependencies beyond bash and git; `gh` CLI is optional for PR creation.

## Architecture

### Dual-Mode Script Pattern

The script uses the same source guard pattern as `install.sh`:

```bash
#!/bin/bash
# genie-session.sh — Session management for parallel worktree sessions

set -euo pipefail

# ── Configuration ──────────────────────────────────────────────
# (constants, naming conventions)

# ── Internal Helpers ───────────────────────────────────────────
# (prefixed with _gs_ to avoid namespace collisions when sourced)

# ── Public Functions ───────────────────────────────────────────
# session_start(), session_finish(), session_worktree_path(),
# session_cleanup_item()

# ── CLI-Only Functions ─────────────────────────────────────────
# session_list(), session_cleanup() — no runner contract, CLI convenience only

# ── Source Guard ───────────────────────────────────────────────
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    # Running as CLI — dispatch subcommands
    case "${1:-}" in
        start)        shift; session_start "$@" ;;
        list)         session_list ;;
        finish)       shift; session_finish "$@" ;;
        cleanup-item) shift; session_cleanup_item "$@" ;;
        cleanup)      session_cleanup ;;
        -h|--help|"") _gs_usage ;;
        *)            _gs_error "Unknown command: $1"; _gs_usage; exit 1 ;;
    esac
fi
```

When sourced (e.g., by `run-pdlc.sh`), the `if` block is skipped and only the function definitions are loaded. When executed directly, the CLI dispatcher routes to the appropriate function.

### Naming Conventions (Locked)

These conventions are inherited from P2-parallel-sessions and locked by the runner design:

| Convention | Pattern | Example |
|------------|---------|---------|
| Branch | `genie/{item}-{phase}` | `genie/P2-search-deliver` |
| Worktree directory | `../{repo}--{item}` | `../myproject--P2-search` |
| Runner branch | `genie/{item}-run` | `genie/P2-search-run` |

The worktree directory uses the **item slug only** (not item + phase) because a single worktree may span multiple phases in the runner context. The branch includes the phase for disambiguation.

### Namespace Convention

All internal helpers use the `_gs_` prefix (genie-session) to avoid collisions when sourced alongside other scripts. Public functions use the `session_` prefix as documented in the runner's integration contract.

## Interfaces

### Public Functions (Runner Contract — Locked)

These signatures are locked by the autonomous runner design (P2-autonomous-lifecycle-runner, status: designed).

```bash
# session_start <item> <phase>
# Creates a worktree and branch for the given item and phase.
# Args:
#   item  — backlog item slug (e.g., "P2-search")
#   phase — lifecycle phase (e.g., "deliver", "run")
# Stdout: worktree absolute path
# Stderr: progress messages
# Returns: 0=success, 1=failure
session_start() {
    local item="${1:?Usage: session_start <item> <phase>}"
    local phase="${2:?Usage: session_start <item> <phase>}"
    # ...
}

# session_finish <item> [--pr|--merge|--force]
# Closes out a session: creates PR, merges, or force-removes.
# Args:
#   item  — backlog item slug
#   --pr    (default) push + PR via gh, remove worktree
#   --merge merge to default branch, remove worktree, delete branch
#   --force force-remove worktree + branch, no PR/merge
# Stdout: PR URL (in --pr mode, if gh available)
# Stderr: progress messages, conflict details
# Returns: 0=success, 1=failure, 2=merge conflict (--merge mode only)
session_finish() {
    local item="${1:?Usage: session_finish <item> [--pr|--merge|--force]}"
    shift
    local mode="pr"  # default
    # parse flags...
}

# session_worktree_path <item>
# Resolves the absolute path to an item's worktree.
# Args:
#   item — backlog item slug
# Stdout: absolute worktree path
# Stderr: errors
# Returns: 0=found, 1=not found
session_worktree_path() {
    local item="${1:?Usage: session_worktree_path <item>}"
    # ...
}

# session_cleanup_item <item>
# Force-removes an item's worktree and branch regardless of merge state.
# Used by the runner to clean up prior failed attempts before retry.
# Args:
#   item — backlog item slug
# Stdout: (none)
# Stderr: progress messages
# Returns: 0 (always — best-effort cleanup)
session_cleanup_item() {
    local item="${1:?Usage: session_cleanup_item <item>}"
    # ...
}
```

### CLI-Only Functions (Not in Runner Contract)

```bash
# session_list
# Shows all active genie worktree sessions.
# No args. Output to stdout (human-readable table).
session_list() { ... }

# session_cleanup
# Removes all sessions whose branches are merged to the default branch.
# No args. Returns 0.
session_cleanup() { ... }
```

### Internal Helpers

```bash
# ── Git context detection ──
_gs_repo_name()        # → repo basename (e.g., "myproject")
_gs_default_branch()   # → "main" or "master"
_gs_repo_root()        # → absolute path to main worktree root

# ── Naming convention resolution ──
_gs_worktree_dir()     # (item) → "../{repo}--{item}" as absolute path
_gs_branch_name()      # (item, phase) → "genie/{item}-{phase}"

# ── Branch state queries ──
_gs_is_merged()        # (branch) → 0 if merged to default branch, 1 otherwise
_gs_branch_exists()    # (branch) → 0 if exists, 1 otherwise
_gs_find_branch()      # (item) → prints branch name for item (finds genie/{item}-*)

# ── Output ──
_gs_log()              # (message) → stderr with prefix
_gs_error()            # (message) → stderr with red prefix
_gs_usage()            # prints CLI usage to stderr
```

## Detailed Function Design

### session_start(item, phase)

```
1. Validate args: item and phase are non-empty
2. Compute:
   - worktree_dir = _gs_worktree_dir(item)
   - branch = _gs_branch_name(item, phase)
3. Guard: if worktree_dir already exists → _gs_error, return 1
4. Guard: if branch already exists → _gs_error, return 1
5. Ensure on default branch for clean base:
   - base_branch = _gs_default_branch()
6. git worktree add "$worktree_dir" -b "$branch" "$base_branch"
   - If fails → _gs_error with git output, return 1
7. Print absolute worktree_dir path to stdout
8. Print to stderr:
   "Session started: $item ($phase)
    Worktree: $worktree_dir
    Branch: $branch

    Next steps:
      cd $worktree_dir && claude"
9. Return 0
```

### session_finish(item, [flags])

**Flag parsing:**
```
Default mode: "pr"
--pr     → mode="pr"
--merge  → mode="merge"
--force  → mode="force"
```

**Dispatch to internal helpers based on mode:**

**_gs_finish_force(item):**
```
1. worktree_dir = _gs_worktree_dir(item)
2. branch = _gs_find_branch(item)  # finds genie/{item}-*
3. git worktree remove --force "$worktree_dir" 2>/dev/null || true
4. git branch -D "$branch" 2>/dev/null || true
5. _gs_log "Force-removed session: $item"
6. Return 0 (always)
```

**_gs_finish_merge(item):**
```
1. worktree_dir = _gs_worktree_dir(item)
2. branch = _gs_find_branch(item)
3. Guard: check for uncommitted changes in worktree → warn to stderr
4. default_branch = _gs_default_branch()
5. From main worktree root:
   git merge "$branch"
   - If merge conflict → print conflict files to stderr, return 2
6. git worktree remove "$worktree_dir"
7. git branch -d "$branch"
8. _gs_log "Merged and cleaned up: $item"
9. Return 0
```

**_gs_finish_pr(item):**
```
1. worktree_dir = _gs_worktree_dir(item)
2. branch = _gs_find_branch(item)
3. Guard: check for uncommitted changes in worktree → warn to stderr
4. Push branch:
   git push -u origin "$branch"
   - If fails → _gs_error, return 1
5. Check if gh CLI is available:
   - If available:
     pr_url=$(gh pr create --base "$default_branch" --head "$branch" \
       --title "$(_gs_pr_title "$item")" \
       --body "$(_gs_pr_body "$item")")
     echo "$pr_url"  # stdout
   - If unavailable:
     remote_url = git remote get-url origin
     _gs_log "Branch pushed. Create PR manually:"
     _gs_log "  ${remote_url%.git}/compare/$branch"
6. git worktree remove "$worktree_dir"
7. _gs_log "Session finished: $item"
8. Return 0
```

Note: Branch cleanup in PR mode happens later via `session cleanup` after the PR is merged. The branch is NOT deleted immediately because it backs the open PR.

### session_worktree_path(item)

```
1. worktree_dir = _gs_worktree_dir(item)
2. Verify worktree_dir exists in git worktree list output
   - If found → print absolute path to stdout, return 0
   - If not found → _gs_error, return 1
```

### session_cleanup_item(item)

```
1. worktree_dir = _gs_worktree_dir(item)
2. branch = _gs_find_branch(item)  # may be empty if no branch
3. if worktree exists:
     git worktree remove --force "$worktree_dir" 2>/dev/null || true
4. if branch exists:
     git branch -D "$branch" 2>/dev/null || true
5. _gs_log "Cleaned up: $item" (or "Nothing to clean up" if neither existed)
6. Return 0 (always)
```

### session_list()

```
1. Parse git worktree list --porcelain
2. For each worktree entry:
   - Extract: path, branch
   - Filter: only branches matching genie/*
   - Check: _gs_is_merged(branch) → "merged" or "active"
3. Print table to stdout:
   ITEM         BRANCH                        PATH                          STATUS
   P2-search    genie/P2-search-deliver       ../myproject--P2-search       active
   P1-auth      genie/P1-auth-run             ../myproject--P1-auth         merged
4. If no genie sessions found: "No active sessions"
```

### session_cleanup()

```
1. Get all genie/ worktrees via session_list logic
2. Filter to merged-only
3. For each: session_cleanup_item(item)
4. Report: "Cleaned up N sessions" or "No merged sessions to clean up"
```

### PR Title and Body Helpers

```bash
_gs_pr_title() {
    local item="$1"
    # Generates: "feat({item-scope}): {item} delivery"
    # e.g., "feat(search): P2-search delivery"
    # Scope is derived from item slug by stripping priority prefix
}

_gs_pr_body() {
    local item="$1"
    # Generates markdown body:
    # ## Summary
    # Session delivery for backlog item.
    #
    # **Backlog:** docs/backlog/{item}.md
    #
    # 🤖 Generated with [Claude Code](https://claude.com/claude-code)
}
```

## Pattern Adherence

| Pattern | How This Design Follows It |
|---------|---------------------------|
| **Source guard** (install.sh) | Same `BASH_SOURCE` check pattern for dual CLI/library mode |
| **Namespace prefix** (bash convention) | `_gs_` prefix on internal helpers avoids collisions when sourced |
| **Exit code contract** (CLI contract) | 0=success, 1=failure, 2=conflict — same as runner design |
| **Stdout/stderr separation** (unix convention) | Machine-readable output (paths, URLs) on stdout; human-readable progress on stderr |
| **Branch naming** (autonomous-execution.md) | `genie/{item}-{phase}` from PR mode convention |
| **Worktree naming** (parallel-sessions spec) | `../{repo}--{item}` from existing convention |
| **Graceful degradation** | gh CLI optional; manual fallback preserves core functionality |
| **ADR-001 Thin Orchestrator** | Script is a thin wrapper around git/gh — no shared runtime, no daemon |

## Data Flow

```
Human user:
  genie-session start P2-search deliver
    → session_start("P2-search", "deliver")
      → git worktree add ../myproject--P2-search -b genie/P2-search-deliver main
      → stdout: /path/to/myproject--P2-search
      → stderr: next steps

  genie-session finish P2-search
    → session_finish("P2-search")  [default --pr]
      → git push -u origin genie/P2-search-deliver
      → gh pr create ...
      → git worktree remove ../myproject--P2-search
      → stdout: https://github.com/org/repo/pull/42

Autonomous runner:
  source genie-session.sh
  session_cleanup_item "$item"
  session_start "$item" "run"
  worktree_dir=$(session_worktree_path "$item")
  cd "$worktree_dir"
  # ... run phases ...
  session_finish "$item" --pr       # success path
  session_finish "$item" --force    # failure path
```

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Branch name collision when multiple phases use same item | L | M | `_gs_find_branch()` uses glob match `genie/{item}-*`; `session_start` guards against existing branch |
| Worktree removal fails (processes holding files) | M | L | `--force` flag on `git worktree remove`; document that user should exit Claude first |
| gh CLI not authenticated | M | L | Check `gh auth status` before attempting PR; graceful fallback to manual URL |
| Remote push fails (no permission, no remote) | L | M | Check remote exists; clear error message; return 1 |
| Stale worktrees accumulate from runner failures | M | M | `session_cleanup_item()` as pre-step in runner; `session cleanup` for batch cleanup |
| Merge conflict in --merge mode | M | L | Return exit code 2; print conflicting files; let user resolve |

## Distribution via install.sh

### Changes to install.sh

Add a new `cmd_scripts()` helper (or fold into existing `cmd_project()` / `cmd_global()`):

```
1. Create scripts/ directory in target if it doesn't exist
2. Copy scripts/genie-session.sh to target scripts/
3. chmod +x on the copied script
4. For global install: copy to ~/.claude/scripts/ (user adds to PATH)
5. For project install: copy to {project}/scripts/
```

This aligns with the runner design which expects both `scripts/genie-session.sh` and `scripts/run-pdlc.sh` to live in the same directory and be copied by install.sh.

### install.sh flag

Add `--scripts` flag alongside existing `--commands`, `--skills`, etc. Include scripts in `--all` (default).

## Implementation Guidance

### File Structure

```
scripts/
└── genie-session.sh     # ~250-300 lines
tests/
└── test_session.sh      # ~200-250 lines (follows test_worktree.sh patterns)
install.sh               # Modified: add scripts distribution
```

### Implementation Sequence

1. **Create `scripts/genie-session.sh` skeleton** — source guard, configuration constants, helper stubs, public function stubs, CLI dispatcher
2. **Implement internal helpers** — `_gs_repo_name`, `_gs_default_branch`, `_gs_worktree_dir`, `_gs_branch_name`, `_gs_is_merged`, `_gs_find_branch`, logging
3. **Implement `session_start`** — the simplest public function, good first TDD target
4. **Implement `session_worktree_path`** — second simplest, needed by other functions
5. **Implement `session_cleanup_item`** — needed by `session_finish --force` and cleanup
6. **Implement `session_finish`** — three modes, most complex function. Start with `--force` (simplest), then `--merge`, then `--pr`
7. **Implement `session_list`** — CLI convenience, uses worktree list parsing
8. **Implement `session_cleanup`** — uses session_list logic + session_cleanup_item
9. **Update `install.sh`** — add scripts distribution
10. **Integration test** — end-to-end: start → list → finish → cleanup

### Test Scenarios (for Crafter)

Tests should follow the same harness pattern as `tests/test_worktree.sh` (assert_eq, assert_contains, assert_exit_code helpers with TESTS_RUN/TESTS_PASSED/TESTS_FAILED counters).

**Test environment:** Each test group creates a temporary git repo with `git init`, runs operations, then cleans up.

| Test Group | Scenarios |
|------------|-----------|
| **session_start** | Creates worktree at correct path; creates branch with correct name; prints path to stdout; fails if worktree already exists; fails if branch already exists; fails with missing args |
| **session_worktree_path** | Returns correct path for existing session; returns exit code 1 for nonexistent session |
| **session_cleanup_item** | Removes existing worktree and branch; succeeds silently when nothing to clean up; always returns 0 |
| **session_finish --force** | Force-removes worktree and branch; succeeds even if worktree doesn't exist; always returns 0 |
| **session_finish --merge** | Merges branch to default; removes worktree after merge; deletes branch after merge; returns exit code 2 on merge conflict |
| **session_finish --pr** | Pushes branch to remote; calls gh pr create (mock gh with wrapper script); falls back to manual URL when gh unavailable; removes worktree after push |
| **session_list** | Lists active genie sessions; shows merge status; handles no sessions gracefully |
| **session_cleanup** | Removes only merged sessions; preserves unmerged sessions |
| **sourceability** | Functions available when sourced; CLI dispatcher skipped when sourced; CLI dispatcher runs when executed |

**gh CLI mocking:** Create a mock `gh` script in the test's temp directory that echoes a fake PR URL, prepend to PATH during PR tests.

### Key Considerations

- **`set -euo pipefail`** at the top — but public functions that promise "always returns 0" (session_cleanup_item, _gs_finish_force) must use `|| true` on commands that might fail
- **No `cd` in public functions** — all git operations use explicit `--git-dir` / `-C` flags or absolute paths, so the caller's working directory is preserved
- **Worktree detection** — use `git worktree list --porcelain` for reliable parsing (not the default human-readable format which varies across git versions)
- **Default branch detection** — `git symbolic-ref refs/remotes/origin/HEAD 2>/dev/null | sed 's|refs/remotes/origin/||'` with fallback to checking for `main` then `master`

## Routing

- [x] **Architect** — Design complete
- [ ] **Crafter** — Build and test `scripts/genie-session.sh` with TDD

**Next:** `/deliver docs/backlog/P2-session-management.md`

---

# Implementation

> **Phase:** RED-GREEN-REFACTOR complete (48/48 tests passing)
> **Date:** 2026-02-12
> **Genie:** Crafter

## What Was Built

### scripts/genie-session.sh (~310 lines)

Single bash script implementing the full session management API:

**Public functions (runner contract):**
- `session_start(item, phase)` — creates worktree + branch, prints path to stdout
- `session_finish(item, [--pr|--merge|--force])` — closes session with three modes
- `session_worktree_path(item)` — resolves worktree absolute path
- `session_cleanup_item(item)` — force-removes item's worktree and branch

**CLI-only functions:**
- `session_list()` — tabular display of active genie sessions with merge status
- `session_cleanup()` — batch cleanup of all merged sessions

**Internal helpers (12 functions, `_gs_` prefix):**
- Git context: `_gs_repo_root`, `_gs_repo_name`, `_gs_default_branch`
- Naming: `_gs_worktree_dir`, `_gs_branch_name`
- Branch state: `_gs_branch_exists`, `_gs_find_branch`, `_gs_is_merged`
- Finish modes: `_gs_finish_force`, `_gs_finish_merge`, `_gs_finish_pr`
- PR helpers: `_gs_pr_title`, `_gs_pr_body`
- Output: `_gs_log`, `_gs_error`, `_gs_usage`

**Key design decisions during implementation:**
- Merge detection uses `git merge-base --is-ancestor` + reflog entry count to distinguish "just created branch" from "fast-forward merged branch" — a novel approach not in the original design
- All git operations use `-C` flag with absolute paths (no `cd` in public functions)
- `set -euo pipefail` at top; best-effort functions use `|| true` guards

### tests/test_session.sh (~600 lines, 48 test cases)

Follows the `test_worktree.sh` harness pattern. Test groups:

| Group | Tests | ACs Covered |
|-------|-------|-------------|
| Internal Helpers | 6 | — |
| session_start | 8 | AC-1, Spec AC-7 |
| session_worktree_path | 3 | AC-5, Spec AC-9 |
| session_cleanup_item | 5 | AC-7, Spec AC-10 |
| session_finish --force | 4 | AC-8, Spec AC-11 |
| session_finish --merge | 5 | AC-3, Spec AC-7 |
| session_finish --pr | 6 | AC-3, AC-6, Spec AC-8 |
| session_list | 6 | AC-2, Spec AC-7 |
| session_cleanup | 3 | AC-4, Spec AC-7 |
| Sourceability | 2 | AC-5, Spec AC-9 |

**Test infrastructure:** Temp git repos with bare origins, mock `gh` CLI, restricted PATH for gh-unavailable tests.

### install.sh modifications

- Added `install_scripts()` function — copies `scripts/*.sh` to target with `chmod +x`
- Added `--scripts` flag (included in `--all` default)
- Global: copies to `~/.claude/scripts/`
- Project: copies to `{project}/scripts/`
- Added scripts to sync mode, dry-run, status, and uninstall

## TDD Log

- **RED:** 48 test cases written → 12 passed (stubs), 36 failed
- **GREEN:** Full implementation → 48/48 passing after solving merge detection ambiguity
- **REFACTOR:** No changes needed — implementation is clean

---

# Review

> **Date:** 2026-02-12
> **Genie:** Critic
> **Verdict:** APPROVED

## Summary

Clean implementation of all 8 backlog ACs and all 5 spec ACs. The script follows existing patterns (source guard from install.sh, test harness from test_worktree.sh, `_gs_` namespace prefix) and the dual CLI/library mode works correctly. The reflog-based merge detection is a novel approach that correctly handles both fast-forward and non-fast-forward merge scenarios.

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 (start) | Pass | `session_start()` creates worktree + branch, prints path to stdout, cd+claude on stderr. 8 tests. |
| AC-2 (list) | Pass | `session_list()` parses porcelain output, shows table with merge status. 6 tests. |
| AC-3 (finish) | Pass | Three modes (pr/merge/force) via `_gs_finish_*` helpers. Returns 2 on conflict. 16 tests across modes. |
| AC-4 (cleanup) | Pass | `session_cleanup()` filters merged branches, calls `session_cleanup_item`. 3 tests. |
| AC-5 (sourceable) | Pass | Source guard at line 482. Functions available when sourced, CLI dispatch skipped. 2 tests + implicit proof from all sourced-mode tests. |
| AC-6 (PR/gh fallback) | Pass | `_gs_finish_pr()` checks `command -v gh`, falls back to manual compare URL. 6 tests including mock gh and restricted PATH. |
| AC-7 (cleanup_item) | Pass | `session_cleanup_item()` force-removes worktree+branch, always returns 0. 5 tests. |
| AC-8 (--force) | Pass | `_gs_finish_force()` skips all checks, force-removes. Always returns 0. 4 tests. |

## Code Quality

### Strengths
- Consistent `_gs_` namespace prefix on all 12 internal helpers
- Clean stdout/stderr separation per the runner contract
- Defensive error handling with `|| true` for best-effort functions
- No `cd` in any function — all git operations use `-C` flag with absolute paths
- Tests follow AAA pattern with dedicated setup/teardown per group

### Issues Found and Fixed

| # | Severity | Location | Issue | Fix |
|---|----------|----------|-------|-----|
| 1 | Major | `README.md` | Parallel Sessions section showed manual git commands, no mention of `genie-session` | Added full session management documentation early in README |
| 2 | Major | `README.md` | "What Gets Installed" table missing Scripts row, install options missing `--scripts` | Added Scripts row and `--scripts` to install options |
| 3 | Major | `templates/CLAUDE.md` | Parallel Sessions section showed only raw git commands | Updated to reference `genie-session` commands |
| 4 | Minor | `README.md:153-174` | Structure tree missing `scripts/` directory | Added `scripts/` with `genie-session.sh` |
| 5 | Minor | `genie-session.sh:203` | Merge error said "Switch first" without showing the command | Added `git checkout` command to error message |

## Test Coverage

- **48 test cases** covering all 8 backlog ACs and 5 spec ACs
- **Test infrastructure:** Temp git repos with bare origins, mock `gh` CLI, restricted PATH for gh-unavailable tests
- **Edge cases covered:** duplicate sessions, nonexistent sessions, merge conflicts, force cleanup of nothing, CLI dispatch of unknown commands

## Security Review

- No sensitive data exposure (no tokens, passwords, keys)
- Input validation at function boundaries via `${1:?Usage: ...}` pattern
- No injection vulnerabilities (all user input is used as git arguments, not in eval/command construction)
- `set -euo pipefail` for strict error handling

## ADR Compliance

| ADR | Decision | Compliant? | Notes |
|-----|----------|------------|-------|
| ADR-001 | Thin Orchestrator | YES | Script is a thin wrapper around git/gh. No shared runtime, no daemon. Sourceable by runner per the Thin Orchestrator pattern. |

## Risk Assessment

| Risk | L | I | Status |
|------|---|---|--------|
| Branch name collision (multiple phases) | L | M | Addressed — `_gs_find_branch()` uses glob, `session_start` guards against existing branch |
| Stale worktrees from runner failures | M | M | Addressed — `session_cleanup_item()` as pre-step |
| gh CLI not available | M | L | Addressed — graceful fallback to manual compare URL |
| Merge conflicts in --merge mode | M | L | Addressed — returns exit code 2, prints conflict details |
| Fast-forward merge detection ambiguity | M | M | Addressed — reflog entry count distinguishes just-created from merged |

## Verdict

**APPROVED** — All ACs met, all issues fixed, ready for commit.

**Next:** `/commit` then `/done`

---

# End of Shaped Work Contract
