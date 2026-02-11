# /commit [backlog-item]

Create a conventional commit for completed work after review approval.

---

## Arguments

- `backlog-item` - Path to backlog item for context (optional, uses current work if omitted)
- Optional flags:
  - `--type [type]` - Specify commit type (feat|fix|docs|refactor|test|chore|perf|style|build|ci)
  - `--scope [scope]` - Specify commit scope
  - `--breaking` - Mark as breaking change
  - `--amend` - Amend previous commit (use with caution)

---

## Genie Invoked

**None** — This is a workflow command that creates git commits.

---

## Context Loading

**READ (automatic):**
- `docs/context/current_work.md` (for context-aware invocation)
- Target backlog item (if provided)
- `git status` and `git diff --staged`

---

## Behavior

1. Check for staged changes (prompt to stage if none)
2. Read backlog item for context (problem, implementation, acceptance criteria)
3. Determine appropriate commit type from work done
4. Generate conventional commit message
5. Execute `git commit` with HEREDOC format
6. Report commit hash and summary

---

## Commit Message Format

```
type(scope): concise description (imperative, <50 chars)

Brief explanation of what changed and why.
Reference to backlog item if available.

Refs: docs/backlog/{item}.md (if applicable)

🤖 Generated with [Claude Code](https://claude.com/claude-code)

Co-Authored-By: Claude <noreply@anthropic.com>
```

### Commit Types

| Type | When to Use |
|------|-------------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change that neither fixes a bug nor adds a feature |
| `test` | Adding or updating tests |
| `chore` | Maintenance, dependencies, config |
| `perf` | Performance improvement |
| `style` | Formatting, whitespace (no code change) |
| `build` | Build system or external dependencies |
| `ci` | CI/CD configuration |

### Breaking Changes

For breaking changes, append an exclamation mark after the type/scope:

```
feat(api)!: remove deprecated endpoints
```

---

## Usage Examples

```
# After /discern APPROVED - context-aware
/commit
> Staged: 3 files changed
> Type detected: feat (new command added)
>
> Commit message:
> feat(commands): add /commit command for conventional commits
>
> Created? (y/n)
> y
>
> [abc1234] feat(commands): add /commit command for conventional commits
> Next: /done

# With explicit backlog reference
/commit docs/backlog/P3-commit-command.md
> Reading backlog item for context...
> Problem: Genie Team workflow has no structured git commit handling
> Implementation: Created /commit command
>
> Suggested commit:
> feat(workflow): add /commit command for conventional commits
>
> Add standalone command for creating commitlint-compatible
> commit messages after /discern approval.
>
> Refs: docs/backlog/P3-commit-command.md

# With explicit type
/commit --type fix --scope auth
> fix(auth): resolve token refresh race condition

# Amend previous commit
/commit --amend
> Amending: [abc1234] feat(commands): add /commit command
> Additional changes staged: 1 file
> Amend this commit? (y/n)
```

---

## Workflow Position

```
/discover → /define → /design → /deliver → /discern → /done
                                                ↑
                                    /commit (anytime)
```

The `/commit` command is a utility available at any point in the workflow:
- Use whenever there are changes worth committing
- Not tied to a fixed position — can run before or after `/done`

---

## Safety Rules

Following Claude Code git conventions:
- **Never commit proactively** — only when explicitly invoked
- **Check before amend** — verify HEAD commit authorship
- **No force push** — warn if attempting
- **Respect hooks** — don't skip pre-commit hooks

---

## Routing

After commit:
- If work is complete: `/done` to archive
- If more changes needed: Continue implementation, re-commit

---

## Notes

- Produces [Conventional Commits](https://www.conventionalcommits.org/) format
- Compatible with commitlint and semantic-release
- Reads backlog context for richer commit messages
- Uses HEREDOC for proper multi-line formatting
- Explicit invocation only (no auto-commit)
