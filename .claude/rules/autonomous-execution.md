# Autonomous Execution Conventions

## Git Workflow Mode

**Default: PR mode.** Use trunk-based mode only when explicitly activated.

### How to activate trunk-based mode

Genie-team recognizes trunk-based mode through these signals (checked in order):

1. **CLAUDE.md** (project-level, persistent) — the target project's `CLAUDE.md` contains:
   ```
   ## Git Workflow
   trunk-based
   ```
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
