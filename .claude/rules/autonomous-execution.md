# Autonomous Execution Conventions

## Git Workflow Mode

**Default: PR mode.** Use trunk-based mode only when explicitly activated.

### How to activate trunk-based mode

Genie-team recognizes trunk-based mode through these signals (checked in order):

1. **Project config** (persistent) — the project's `CLAUDE.md` or any loaded rules file contains `trunk-based`
2. **Prompt prefix** (per-invocation) — the orchestrator prepends to the command:
   ```
   claude -p "git-mode: trunk. /deliver docs/backlog/P1-feature.md"
   ```
3. **User instruction** (interactive) — the user says "use trunk-based mode" during the session.

If none of these signals are present, use PR mode.

### PR Mode (default)

- Create a feature branch: `genie/{backlog-item-id}-{phase}`
  - Examples: `genie/P1-auth-improvements-deliver`, `genie/P2-search-redesign-design`
  - Always branch from the default branch (main/master)
  - One branch per backlog item per phase
- Create a PR for code changes (never push directly to default branch)
- PR title: conventional commit format matching the primary change
- PR body: reference the backlog item path and acceptance criteria status
- Request review from the user or team (do not auto-merge)

### Trunk-Based Mode

- Commit directly to the default branch (main/master)
- No feature branches, no PRs
- Keep commits small and self-contained (one logical change per commit)
- All commits must pass existing tests before push

## Commit Attribution

All commits from genie execution include:

```
type(scope): description

Context from backlog item.

Refs: docs/backlog/{item}.md

Co-Authored-By: {Genie Name} <noreply@anthropic.com>
```

Where `{Genie Name}` is the active genie (e.g., "Crafter", "Architect").

## Workspace Boundaries

- Operate only within the target repository root
- Do not modify files in parent directories
- Do not access other repositories
- Clean up any temporary files created during execution

## Parallel Sessions via Git Worktrees

When `worktree-enabled` is present in the project's CLAUDE.md or rules,
these conventions apply.

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
