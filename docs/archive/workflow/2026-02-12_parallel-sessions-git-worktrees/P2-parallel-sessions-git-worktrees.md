---
spec_version: "1.0"
type: shaped-work
id: parallel-sessions-git-worktrees
title: "Parallel Sessions via Git Worktrees"
status: done
created: 2026-02-12
appetite: small
priority: P2
target_project: genie-team
author: shaper
tags: [workflow, parallel, git-worktrees, isolation, sessions]
spec_ref: docs/specs/workflow/parallel-sessions.md
adr_refs:
  - docs/decisions/ADR-001-thin-orchestrator.md
acceptance_criteria:
  - id: AC-1
    description: "Multiple Claude Code sessions can operate on the same repository simultaneously using git worktrees, each on a separate branch with no file or index conflicts during parallel operation; merge conflicts when merging to main are resolved via standard git merge workflow"
    status: met
  - id: AC-2
    description: "install.sh supports installing genie-team into a worktree (not just the main working tree)"
    status: met
  - id: AC-3
    description: "Autonomous execution rules document worktree-aware behavior: branch naming, worktree lifecycle, and conflict avoidance"
    status: met
  - id: AC-4
    description: "Target project CLAUDE.md template includes parallel session guidance when worktree mode is configured"
    status: met
  - id: AC-5
    description: "Genie memory (.claude/agent-memory/) is either shared via symlink or isolated per worktree, with a documented convention"
    status: met
  - id: AC-6
    description: "Safety rules prevent destructive operations that affect sibling worktrees (e.g., force-pushing shared branches, deleting the main worktree's branch)"
    status: met
---

# Shaped Work Contract: Parallel Sessions via Git Worktrees

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Original input:** "A way for multiple Claude sessions powered by genie-team can work on the same local git repo using git workspaces."

**Reframed problem:** When a user wants to run multiple Claude Code sessions on the same codebase in parallel — one session delivering feature A while another designs feature B — both sessions share the same working directory, causing file conflicts, git staging collisions, and context pollution. There is currently no documented pattern for isolated parallel execution on a single local repository.

## Evidence & Insights

- **From Discovery:** `docs/analysis/20260204_discover_worker_based_execution.md` — identified workspace isolation as a key capability gap. Assumption 3: "Multiple concurrent genie executions can be isolated without cross-contamination."
- **From Archive:** `docs/archive/backlog-review/2026-02-10_platform-reality-check/P2-batch-parallel-execution.md` — superseded because it proposed application-level infrastructure (worker pools, job queues). The insight that survived: "Genie-team's contribution to parallel execution is safety rules for concurrent git operations and stateless commands."
- **Existing conventions:** PR mode already creates unique branches per item (`genie/{item}-{phase}`), which naturally maps to one branch per worktree.
- **Platform capability:** `git worktree` is a built-in git feature. Claude Code sessions can be launched in any directory. No runtime infrastructure needed.

### Why Git Worktrees (Not Alternatives)

| Approach | Disk Cost | Git History | `.claude/` Sharing | Practical |
|----------|-----------|-------------|---------------------|-----------|
| **Git worktrees** | Low (shared objects) | Shared | Tracked files auto-present | Yes — built-in, lightweight |
| Full repo clones | High (full copy) | Separate until push/fetch | Must install separately | Heavy — wastes disk, history diverges |
| Same directory, different branches | None | Shared | Shared | No — can't checkout two branches simultaneously |

Git worktrees are the only approach that provides true parallel isolation without duplicating the repository.

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days)
- **Rationale:** This is a prompt engineering project. Deliverables are conventions, rules, documentation, and install.sh changes — no application code.
- **Boundaries:**
  - Document worktree conventions for parallel genie sessions
  - Update `autonomous-execution.md` rules with worktree-aware safety
  - Update `install.sh` to detect and handle worktree targets
  - Update CLAUDE.md template with parallel session guidance
  - Define genie memory convention for worktrees
- **No-gos:**
  - No orchestrator, process manager, or session coordinator (that's the user or external orchestrator per ADR-001)
  - No worktree lifecycle commands (users manage worktrees with standard `git worktree add/remove`)
  - No automatic worktree creation on `/deliver` — keep it explicit
  - No cross-worktree communication or coordination protocol
- **Fixed elements:**
  - Must work with existing PR mode branch naming (`genie/{item}-{phase}`)
  - Must not break single-session (non-worktree) usage
  - Must respect ADR-001 Thin Orchestrator boundary

## Goals & Outcomes

**Outcome hypothesis:** "We believe documenting git worktree conventions will enable power users and orchestrators to run 2-5 parallel genie sessions on the same repo without conflicts, reducing wall-clock time for multi-item sprints proportionally."

**Success signals:**
- A user can follow the documented pattern to run two parallel `/deliver` sessions on different backlog items without conflicts
- An orchestrator can spawn parallel Claude processes in separate worktrees using the CLI contract
- `install.sh --worktree` installs genie-team into a worktree cleanly
- No safety violations when sessions operate on sibling worktrees

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| Git worktrees share `.git/` objects without lock contention across parallel sessions | feasibility | Create 2 worktrees, run concurrent commits on different branches |
| `.claude/` tracked files are present and functional in worktrees | feasibility | `git worktree add`, verify `.claude/commands/` accessible |
| Genie memory (`.claude/agent-memory/`, gitignored) can be symlinked from worktrees to main | feasibility | Symlink test, verify genie reads/writes correctly |
| `docs/` isolation per worktree prevents merge conflicts on backlog items | value | Two sessions modifying different `docs/backlog/` files, merge both to main |

### Rabbit Holes to Avoid

- **Cross-worktree coordination protocol** — don't build session awareness or locking. Git's branch-per-worktree constraint already prevents conflicts. If two sessions somehow need the same branch, that's a workflow problem, not a tooling problem.
- **Worktree lifecycle management** — don't automate creation/cleanup. `git worktree add` and `git worktree remove` are simple commands. Users and orchestrators handle this.
- **Shared mutable state** — don't try to share in-progress `docs/` changes across worktrees. Each worktree is a branch; changes merge through git. This is a feature, not a limitation.

## Options (Ranked)

### Option 1: Convention-First (Recommended)

- **Description:** Document worktree conventions in rules + template. Minimal install.sh changes. Users set up worktrees themselves.
- **Deliverables:** Updated `autonomous-execution.md`, new section in CLAUDE.md template, install.sh worktree detection, genie memory symlink convention
- **Pros:** Minimal change surface, builds on existing patterns, no new commands to maintain
- **Cons:** Users must learn `git worktree` themselves
- **Appetite fit:** Excellent — well within small batch

### Option 2: Command-Assisted

- **Description:** Add `/worktree:add [item]` and `/worktree:remove [item]` commands that wrap `git worktree` with genie-team conventions (naming, genie-team installation, memory linking)
- **Pros:** Smoother UX, enforces naming conventions
- **Cons:** More surface area to maintain, may not justify complexity for a rarely-used operation
- **Appetite fit:** Tight — pushes toward medium batch

## Dependencies

- None blocking. Builds on existing:
  - PR mode branch naming (delivered)
  - ADR-001 Thin Orchestrator (accepted)
  - CLI contract (documented)
  - Autonomous execution conventions (delivered)

## Solution Sketch

### Worktree Naming Convention

```
{repo-parent}/{repo-name}--{session-label}/
```

Example:
```
~/code/my-app/                         # Main worktree
~/code/my-app--deliver-auth/           # Worktree for delivering auth feature
~/code/my-app--design-search/          # Worktree for designing search
```

### Worktree Setup Flow (User/Orchestrator)

```bash
# 1. Create worktree on a new branch
git worktree add ../my-app--deliver-auth -b genie/P1-auth-deliver

# 2. Install genie-team into worktree (if not tracked in repo)
cd ../my-app--deliver-auth
./install.sh  # or: install.sh --target ../my-app--deliver-auth

# 3. Launch Claude session in worktree
cd ../my-app--deliver-auth
claude  # interactive, or: claude -p "/deliver docs/backlog/P1-auth.md"

# 4. When done: merge/PR, then clean up
git worktree remove ../my-app--deliver-auth
```

### Genie Memory Convention

`.claude/agent-memory/` is gitignored — not present in worktrees by default.

**Convention:** Symlink from worktree to main worktree's memory:
```bash
ln -s /absolute/path/to/main/.claude/agent-memory \
      ../my-app--deliver-auth/.claude/agent-memory
```

This lets all sessions share learned patterns. If isolation is preferred, skip the symlink — each worktree gets its own (empty) memory.

### Safety Rules (additions to autonomous-execution.md)

```markdown
## Worktree Safety

When operating in a git worktree:
- NEVER force-push or delete a branch checked out in another worktree
- NEVER modify files outside the current worktree directory
- Be aware that `main`/`master` may be checked out in the main worktree — do not reset or rebase it
- Use `git worktree list` to see active worktrees before branch operations
```

## Routing

- [x] **Design** — needs Architect review for install.sh changes and rule structure
- Alternatively: straight to `/deliver` given the small scope and clear deliverables

**Rationale:** The deliverables are well-defined conventions and documentation. Design is optional but would benefit from Architect reviewing the install.sh worktree detection approach.

## Artifacts

- **Contract saved to:** `docs/backlog/P2-parallel-sessions-git-worktrees.md`
- **Spec created:** `docs/specs/workflow/parallel-sessions.md`
- **Discovery referenced:** `docs/analysis/20260204_discover_worker_based_execution.md`
- **Prior work referenced:** `docs/archive/backlog-review/2026-02-10_platform-reality-check/P2-batch-parallel-execution.md` (superseded — infrastructure scope; this item covers genie-team's prompt engineering contribution)

---

# Design: Parallel Sessions via Git Worktrees

> Appended by `/design` on 2026-02-12
> **Complexity:** Simple — conventions, rules, docs, and minor install.sh changes
> **Architect confidence:** High — all assumptions validated by empirical testing

## Research Findings

Design decisions below are grounded in hands-on testing of git worktree mechanics. Key findings:

| Component | Behavior | Implication |
|-----------|----------|-------------|
| Object store (`.git/objects/`) | **Shared** across all worktrees | Parallel commits on different branches succeed with no lock contention |
| Index (`.git/index`) | **Per-worktree** (stored in `.git/worktrees/{name}/index`) | Each session has independent staging — no conflicts |
| HEAD | **Per-worktree** | Each session tracks its own branch |
| Refs (`.git/refs/`) | **Shared** | All worktrees see the same branch refs |
| Hooks (`.git/hooks/`) | **Shared** | Pre-commit hooks run from main `.git/hooks/` for all worktrees |
| Config (`.git/config`) | **Shared** | Same git config across all sessions |
| Tracked files (`.claude/`, `docs/`) | **Per-worktree copy** | Independent working directories; changes don't cross-pollinate until merged |
| Gitignored files (`.claude/agent-memory/`) | **Absent** in worktrees by default | Must be explicitly created or symlinked |
| Branch constraint | **Enforced** — no two worktrees on the same branch | Aligns perfectly with PR mode's unique branches per item |

**Concurrent commit test:** Two simultaneous commits from different worktrees on different branches succeeded (3 microseconds apart). No lock contention on the shared object store.

**Worktree detection:** Reliable via comparing `git rev-parse --git-dir` vs `--git-common-dir`. When they differ, you're in a worktree.

```bash
# Main working tree: both return ".git"
git rev-parse --git-dir         # → .git
git rev-parse --git-common-dir  # → .git

# Worktree: git-dir points to worktree-specific subdir
git rev-parse --git-dir         # → /repo/.git/worktrees/{name}
git rev-parse --git-common-dir  # → /repo/.git
```

## Technical Decisions

### Decision 1: install.sh — Auto-detect worktrees, no flag needed

**Question:** Should install.sh auto-detect worktrees or require `--worktree`?

**Recommendation: Auto-detect. No flag.**

**Rationale:** When `install.sh project` runs inside a worktree, the current behavior already works — it installs to `$PWD/.claude/`. The only change needed is MCP scope awareness:

- In the main working tree: `claude mcp add -s local` (project-private, current behavior)
- In a worktree: `claude mcp add -s user` (shared across all sessions) OR skip MCP install if already present at user scope

The detection is simple and non-breaking:

```bash
detect_worktree() {
    local git_dir git_common_dir
    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 1
    git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
    [[ "$git_dir" != "$git_common_dir" ]]
}
```

**What changes in install.sh:**
1. Add `detect_worktree()` helper function
2. In `cmd_project()`: if worktree detected, log an info message and adjust MCP scope to `user` instead of `local`
3. In `cmd_project()`: if worktree detected, create symlink for `.claude/agent-memory/` pointing to main worktree
4. No new flags, no breaking changes to existing behavior

**AC addressed:** AC-2

### Decision 2: Genie memory — Shared via symlink (default)

**Question:** Should `.claude/agent-memory/` be shared or isolated across worktrees?

**Recommendation: Shared via symlink. Document isolation as opt-out.**

**Rationale:**
- Genie memory captures meta-learning about *the project* — not about the specific task
- All sessions working on the same project benefit from shared learning
- Symlinks work reliably for gitignored directories across worktrees (tested)
- The symlink convention is simple: point worktree memory to main worktree's memory

```bash
# install.sh creates this automatically when worktree detected
main_worktree="$(git rev-parse --git-common-dir | sed 's|/.git$||')"
ln -sf "$main_worktree/.claude/agent-memory" "$project_path/.claude/agent-memory"
```

**Opt-out:** Users who want isolated memory per session simply remove the symlink and create a regular directory. Document this in the CLAUDE.md template guidance.

**AC addressed:** AC-5

### Decision 3: CLAUDE.md template — Commented section, consistent with Git Workflow pattern

**Question:** How should worktree guidance surface in the CLAUDE.md template?

**Recommendation: Add `## Parallel Sessions` section, commented out by default.**

**Rationale:** This follows the exact pattern used for Git Workflow mode:

```markdown
## Parallel Sessions

<!-- Genie-team supports parallel sessions via git worktrees.
     Each session operates in its own worktree on a separate branch.
     Uncomment the section below to enable worktree-aware behavior. -->

<!-- worktree-enabled -->
```

When uncommented, the `autonomous-execution.md` rules activate worktree safety conventions. This keeps the template clean for single-session users while being discoverable.

**AC addressed:** AC-4

### Decision 4: CLI contract — Add worktree invocation section

**Question:** Do CLI contract docs need updates?

**Recommendation: Yes — add a small "Parallel Invocation" section.**

**Rationale:** The CLI contract (`docs/architecture/cli-contract.md`) is the integration surface for orchestrators. A brief section showing the worktree invocation pattern completes the picture:

```bash
# Orchestrator creates worktree per job
git worktree add "../$repo--$job_id" -b "genie/$backlog_id-$phase"

# Launch Claude in the worktree
claude -p "/deliver docs/backlog/$backlog_id.md" \
  --output-format stream-json \
  --cwd "../$repo--$job_id"

# Clean up after job completes
git worktree remove "../$repo--$job_id"
```

No changes to the existing contract — purely additive.

### Decision 5: No in-session dispatch for human-led sessions

**Question:** Should an active Claude session be able to create a worktree and dispatch work to it?

**Decision: No.** Explored and rejected during design.

**Rationale:** In-session dispatch (spawning background `claude -p` from an active session) degrades the human orchestrator experience:
- No unified progress view — user gets a log file instead of interactive control
- No result injection — dispatched session output doesn't flow back into the main session's context
- Claude Code `--resume` doesn't work across worktrees (different project paths)
- Mental model overhead of tracking N background processes

The human already *is* the orchestrator. They manage terminal windows naturally — creating a worktree and opening `claude` in a new tab is simpler and gives full interactive control over each session.

**The split:**
- **Human-led sessions:** Create worktree manually, open new terminal, run `claude` interactively
- **Orchestrator-driven sessions:** CLI contract documents `claude -p` invocation per worktree (headless, programmatic monitoring)

Genie-team does not attempt to make an active session act as an orchestrator. That's Cataliva's role per ADR-001.

## Component Design

### Files to Create/Modify

| Component | File | Action | AC |
|-----------|------|--------|-----|
| Install script | `install.sh` | Modify — add worktree detection, memory symlink, MCP scope adjustment | AC-2, AC-5 |
| Safety rules | `.claude/rules/autonomous-execution.md` | Modify — add Worktree Safety section | AC-3, AC-6 |
| CLAUDE.md template | `templates/CLAUDE.md` | Modify — add Parallel Sessions section | AC-4 |
| CLI contract | `docs/architecture/cli-contract.md` | Modify — add Parallel Invocation section | AC-1 |

### install.sh Changes

```bash
# New helper function (add near line 70)
detect_worktree() {
    local git_dir git_common_dir
    git_dir="$(git rev-parse --git-dir 2>/dev/null)" || return 1
    git_common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
    [[ "$git_dir" != "$git_common_dir" ]]
}

# Get the main worktree path from inside any worktree
get_main_worktree() {
    local common_dir
    common_dir="$(git rev-parse --git-common-dir 2>/dev/null)" || return 1
    # common-dir is the .git/ dir; parent is the main worktree
    dirname "$(cd "$common_dir" && pwd)"
}
```

**In `cmd_project()`** (after line 659):
1. Detect if running in worktree
2. If worktree: log info, set MCP scope to `user`, create memory symlink
3. If not worktree: current behavior unchanged

### autonomous-execution.md Changes

Add after the existing "Workspace Boundaries" section:

```markdown
## Parallel Sessions via Git Worktrees

When `worktree-enabled` is present (uncommented) in the project's CLAUDE.md
`## Parallel Sessions` section, these conventions apply.

### Worktree Detection

```bash
# Returns 0 if running in a worktree, 1 if in main working tree
git_dir="$(git rev-parse --git-dir)"
git_common="$(git rev-parse --git-common-dir)"
[[ "$git_dir" != "$git_common" ]]  # true = worktree
```

### Safety Rules

- NEVER force-push or delete a branch checked out in another worktree
  (run `git worktree list` before destructive branch operations)
- NEVER modify files outside the current worktree directory
- Be aware that `main`/`master` is likely checked out in the main worktree —
  do not reset, rebase, or force-push it
- Do NOT attempt to check out a branch that another worktree is using
  (git enforces this, but genies should not retry or work around the error)
- Treat merge conflicts from parallel worktree merges as expected —
  resolve them, don't force-overwrite

### Worktree Branch Convention

- Worktree branches follow PR mode naming: `genie/{backlog-item-id}-{phase}`
- Each worktree operates on exactly one backlog item in one phase
- When the phase completes, the worktree's branch is merged/PR'd and the
  worktree is removed

### Human-Led Parallel Sessions

For human-led (interactive) sessions, parallel work uses separate terminals:

1. Create a worktree: `git worktree add ../project--session -b genie/P1-item-deliver`
2. Open a new terminal, `cd` into the worktree
3. Run `claude` interactively

The human is the orchestrator — they manage terminal windows and decide when
to merge. No in-session dispatch machinery needed.

### Orchestrator-Driven Parallel Sessions

For headless orchestrators, dispatch via CLI contract:

1. Create worktree per job
2. Spawn `claude -p` per worktree (see cli-contract.md)
3. Monitor via `--output-format stream-json`
4. Clean up worktrees after completion
```

### templates/CLAUDE.md Changes

Add after the `## Git Workflow` section:

```markdown
## Parallel Sessions

<!-- Genie-team supports parallel sessions via git worktrees.
     Each session operates in its own worktree directory on a separate branch.
     To enable worktree-aware safety rules, uncomment the line below. -->

<!-- worktree-enabled -->

<!-- Setup:
     git worktree add ../project--session-name -b genie/P1-item-deliver
     cd ../project--session-name
     claude

     Cleanup:
     git worktree remove ../project--session-name
-->
```

### docs/architecture/cli-contract.md Changes

Add a "Parallel Invocation via Worktrees" section after "Session Continuation":

```markdown
### Parallel Invocation via Worktrees

For running multiple jobs concurrently on the same repository:

\```bash
# Create a worktree per job (each on a unique branch)
git worktree add "../${repo}--${job_id}" -b "genie/${backlog_id}-${phase}"

# Launch Claude session in the worktree directory
cd "../${repo}--${job_id}"
claude -p "/deliver docs/backlog/${backlog_id}.md" \
  --output-format stream-json \
  --max-turns 100

# After job completes: merge/PR, then clean up
cd ..
git worktree remove "${repo}--${job_id}"
\```

Each worktree has its own working directory, branch, and index.
No coordination needed between parallel sessions — git's branch-per-worktree
constraint prevents conflicts. Genie-team's PR mode branch naming
(`genie/{item}-{phase}`) produces unique branches naturally.
```

## Risks & Mitigations

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Two sessions edit the same `docs/backlog/` file via different worktrees, causing merge conflict | Medium | Low | Document that each session should operate on different backlog items. Conflicts resolve via standard git merge. |
| User forgets to remove worktrees, accumulating stale directories | Low | Low | `git worktree list` shows all worktrees. Add reminder in cleanup guidance. No automated cleanup needed. |
| Symlinked agent-memory has concurrent write contention | Low | Low | Agent memory files are small markdown. Write contention is unlikely — sessions typically read memory at start and write at end. If contention occurs, it's self-healing (last write wins for metadata). |
| Claude Code `--resume` doesn't work across worktrees (different project paths) | Medium | Medium | Document this limitation. Each worktree is treated as a separate project by Claude Code. Use `--resume` only within the same worktree. Cross-session context transfer is via the document trail (`docs/`). |

## Implementation Guidance

### Sequence

1. **install.sh** — Add `detect_worktree()` and `get_main_worktree()` helpers. Modify `cmd_project()` to detect worktree context, adjust MCP scope, and create memory symlink.
2. **autonomous-execution.md** — Add "Worktree Safety" section after "Workspace Boundaries".
3. **templates/CLAUDE.md** — Add "Parallel Sessions" section after "Git Workflow".
4. **docs/architecture/cli-contract.md** — Add "Parallel Invocation via Worktrees" section.
5. **Tests** — Add worktree detection test to `tests/test_execute.sh`. Verify `detect_worktree` returns correct result in main tree vs worktree.

### Test Scenarios

| Scenario | Expected Result |
|----------|-----------------|
| `install.sh project` in main working tree | Current behavior unchanged. MCP scope: local. No symlink. |
| `install.sh project` in a worktree | Detects worktree, logs info, MCP scope: user, creates memory symlink to main worktree |
| `detect_worktree` in main tree | Returns false (exit 1) |
| `detect_worktree` in worktree | Returns true (exit 0) |
| `get_main_worktree` in worktree | Returns absolute path to main working tree |
| Two parallel sessions commit to different branches | Both succeed, no lock contention |
| Session in worktree runs `git worktree list` | Shows all active worktrees |

### Key Considerations for Crafter

- **Backwards compatibility is critical.** The `detect_worktree` path must be a clean branch — when not in a worktree, behavior is identical to today.
- **No new dependencies.** Only uses `git rev-parse`, which is available in all git installations.
- **install.sh is bash.** Follow existing script patterns (`log_info`, `log_success`, etc.).
- **The CLAUDE.md template uses HTML comments for opt-in sections.** Follow the `<!-- trunk-based -->` pattern exactly.
- **autonomous-execution.md is a markdown rule file.** Keep the worktree section consistent with the existing tone and structure.

## Routing

- [x] **Ready for Crafter** — Design is complete. All deliverables are well-scoped.

**Next:** `/deliver docs/backlog/P2-parallel-sessions-git-worktrees.md`

---

# Implementation
<!-- Appended by /deliver on 2026-02-12 -->

## TDD Summary

- **RED:** 23 tests written covering all 6 ACs — all failed as expected (functions undefined, content absent)
- **GREEN:** Minimal implementation to pass all tests
- **REFACTOR:** No refactoring needed — code is clean and minimal

## What Was Built

### install.sh (AC-2, AC-5)
- `detect_worktree()` — compares `git rev-parse --git-dir` vs `--git-common-dir`; returns 0 in worktree, 1 otherwise
- `get_main_worktree()` — resolves main worktree path from git common dir
- `cmd_project()` — detects worktree context, adjusts MCP scope to `user` (shared across sessions), creates symlink for `.claude/agent-memory/` to main worktree
- `INSTALL_SOURCED` guard added for testability (follows `EXECUTE_SOURCED` pattern)
- Backwards compatible — non-worktree behavior unchanged

### .claude/rules/autonomous-execution.md (AC-3, AC-6)
- Added "Parallel Sessions via Git Worktrees" section after "Workspace Boundaries"
- Worktree detection snippet
- 5 safety rules (force-push, file boundaries, main branch protection, branch checkout conflicts, merge conflict handling)
- Branch convention documentation
- Human-led and orchestrator-driven session patterns (separate subsections)

### templates/CLAUDE.md (AC-4)
- Added "## Parallel Sessions" section after "## Git Workflow"
- `<!-- worktree-enabled -->` comment marker (consistent with `<!-- trunk-based -->`)
- Setup and cleanup instructions in comments

### docs/architecture/cli-contract.md (AC-1)
- Added "Parallel Invocation via Worktrees" section after "Session Continuation"
- Complete orchestrator workflow: create worktree, launch claude, cleanup
- Documents `--resume` limitation across worktrees

### tests/test_worktree.sh
- 23 test cases following existing test_execute.sh patterns
- Tests: detect_worktree (3), get_main_worktree (5), autonomous-execution.md content (7), templates/CLAUDE.md content (4), cli-contract.md content (4)
- Uses real git repos and worktrees created in temp directories

## Decisions Made During Implementation
- Added `INSTALL_SOURCED` guard to install.sh for testability (mirrors existing `EXECUTE_SOURCED` pattern in commands/execute.sh)
- Memory symlink only created when main worktree's `.claude/agent-memory/` directory exists (avoids dangling symlinks)
- Disabled `set -e` after sourcing install.sh in tests (install.sh's `set -e` propagates into test context)

## Test Results

```
tests/test_worktree.sh: 23 tests, 23 passed, 0 failed
tests/test_execute.sh:  62 tests, 62 passed, 0 failed (no regression)
```

---

# Pre-Review Notes (Architect + Shaper)
<!-- Added by parallel review session on 2026-02-12 -->
<!-- These notes are INPUT for /discern, not a verdict -->

## Context

This review was conducted in a separate session while delivery was in progress, specifically to evaluate forward-compatibility with the autonomous lifecycle runner (next roadmap item).

## Findings

### 2 Critical Gaps (for autonomous runner, not for this delivery)

**1. No worktree cleanup convention for failed autonomous runs.**
When a cron job fails mid-lifecycle (max-turns, test failure, crash), the worktree and branch are orphaned. A retry attempt fails on `git worktree add -b genie/{item}-{phase}` ("branch already exists"). The runner needs a cleanup-before-retry convention:
```bash
# Before creating worktree, cleanup prior failed attempt
git worktree list | grep "$job_id" && git worktree remove "../${repo}--${job_id}" --force
git show-ref --verify refs/heads/genie/${item}-${phase} && git branch -D genie/${item}-${phase}
```

**2. No merge conflict resolution policy for autonomous context.**
When two parallel runners finish simultaneously and both try to merge/PR to main, one will hit conflicts. Autonomous runners can't ask a human. Recommendation: rebase before PR creation; use exit code 2 (distinct from exit 1 "implementation failure") to signal "needs human merge resolution."

### 5 Important Nuances

3. **AC-1 precision:** "No conflicts" is true during parallel operation but misleading — merge conflicts ARE expected when branches merge to main. Spec AC-1 updated to clarify this.
4. **Pre-commit hooks (P2-precommit-validation-pipeline):** Custom hook scripts in `hooks/precommit/` need to be accessible from all worktrees. The `hooks/` directory should be symlinked (like agent-memory). Not yet in install.sh.
5. **MCP `user` scope conflict:** Multiple projects installing MCP at user scope will overwrite each other's env vars. Safer approach: check if MCP already exists at user scope before installing.
6. **`--resume` clarification:** Works within a single worktree, not across. Spec updated.
7. **Cost multiplication:** N parallel sessions x `--max-budget-usd` per session = N times the cost. Spec updated with cost implications section.

### Forward-Compatibility Updates Applied

- Spec: Added "Primary Use Cases" naming autonomous runner as primary consumer
- Spec: Added "Cost Implications" section
- Spec: Added "Autonomous Runner Forward-Compatibility" table documenting all gaps
- Spec: Updated `--resume` constraint to clarify within-worktree vs cross-worktree behavior
- Spec: Updated AC-1 to clarify merge conflict expectations

### Recommendation for /discern

Implementation is solid for the **human-led parallel sessions** use case. All 6 ACs appear met for that scope. The critical gaps identified are NOT blocking for this delivery — they should be tracked as requirements for the autonomous lifecycle runner item (next in roadmap).

**Suggested follow-up:** When the autonomous lifecycle runner is shaped, carry forward the 2 critical gaps and 5 important nuances as input requirements.

### Appetite Observation

Both Architect and Shaper flagged that "small batch (1-2 days)" may underestimate — the delivery surface (4 files modified, 23 tests, install.sh logic) is closer to medium. The other genie delivered it efficiently, but the appetite calibration note stands for future similar items.

---

# Review
<!-- Appended by /discern on 2026-02-12 -->

## Verdict: APPROVED

**Confidence:** High
**ACs verified:** 6/6 met
**ADR compliance:** ADR-001 YES

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Pass | cli-contract.md documents worktree invocation; safety rules address merge conflicts; design validated concurrent commits with no lock contention |
| AC-2 | Pass | `detect_worktree()` and `get_main_worktree()` in install.sh; `cmd_project()` adjusts MCP scope to `user` and creates memory symlink when worktree detected |
| AC-3 | Pass | autonomous-execution.md has full "Parallel Sessions via Git Worktrees" section: detection snippet, 5 safety rules, branch convention, human-led and orchestrator-driven patterns |
| AC-4 | Pass | templates/CLAUDE.md has "## Parallel Sessions" with `<!-- worktree-enabled -->` comment marker, setup/cleanup instructions |
| AC-5 | Pass | install.sh creates memory symlink when worktree detected and main memory exists; isolation documented as opt-out (remove symlink) |
| AC-6 | Pass | 5 safety rules: force-push/delete, file boundaries, main branch protection, branch checkout conflicts, merge conflict handling |

## Code Quality

### Strengths
- Functions are clean, minimal, follow existing install.sh patterns
- Error handling with `|| return 1` for git operations
- Memory symlink has proper guards (dir exists, not already linked/present)
- `INSTALL_SOURCED` guard follows existing `EXECUTE_SOURCED` pattern
- Backwards compatible — non-worktree path untouched

### Issues Found

| Issue | Severity | Location | Fix |
|-------|----------|----------|-----|
| Dry-run path hardcodes MCP scope "local" instead of using worktree-aware `$mcp_scope` | Minor | `install.sh:707` | Move `mcp_scope` assignment before dry-run block |

Cosmetic only — dry-run doesn't install anything. No functional impact.

## Test Coverage

- **test_worktree.sh:** 23 tests (detect_worktree: 3, get_main_worktree: 5, content verification: 15)
- **test_execute.sh:** 62 tests, no regression
- Tests use real git repos with worktrees in temp directories — good isolation

## Pre-Review Notes Assessment

The parallel architect+shaper review identified forward-compatibility gaps for the autonomous lifecycle runner. None are blocking for this delivery:
- Orphaned worktree cleanup → autonomous runner concern
- Merge conflict resolution policy → autonomous runner concern
- Pre-commit hooks in worktrees → tracked files auto-present; not blocking
- MCP user scope conflicts → mitigated by existing `check_mcp_installed()` collision detection

## Routing

**APPROVED** — Ready for `/commit` then `/done`

---

# End of Shaped Work Contract
