---
name: conventional-commits
description: Creates conventional commit messages following commitlint standards. Use when committing code, creating git commits, or when the user says commit, push, or save changes.
allowed-tools: Bash(git status*), Bash(git diff*), Bash(git add*), Bash(git commit*), Bash(git log*)
---

# Conventional Commits

Generate commit messages following [Conventional Commits](https://www.conventionalcommits.org/) format.

## Format

```
type(scope): concise description (<50 chars, imperative mood)

Optional body explaining what and why (not how).

Refs: #issue or docs/backlog/item.md (if applicable)

Co-Authored-By: Claude <noreply@anthropic.com>
```

## Commit Types

| Type | Use When |
|------|----------|
| `feat` | New feature or capability |
| `fix` | Bug fix |
| `docs` | Documentation only |
| `refactor` | Code change (no feature/fix) |
| `test` | Adding or updating tests |
| `chore` | Maintenance, deps, config |
| `perf` | Performance improvement |
| `style` | Formatting (no code change) |
| `build` | Build system changes |
| `ci` | CI/CD configuration |

## Breaking Changes

Append `!` after type/scope:
```
feat(api)!: remove deprecated endpoints

BREAKING CHANGE: The /v1/users endpoint has been removed.
Use /v2/users instead.
```

## Examples

**Feature:**
```
feat(auth): add JWT token refresh endpoint

Implements automatic token refresh to prevent session expiration
during active use.

Refs: docs/backlog/P2-auth-improvements.md
```

**Bug fix:**
```
fix(form): prevent double submission on slow networks

Add loading state and disable button during form submission
to prevent duplicate requests.
```

**Refactor:**
```
refactor(utils): extract date formatting to shared module

Move duplicated date formatting logic from 5 components
into a single shared utility.
```

## Process

1. Run `git status` to see changes
2. Run `git diff --staged` (or `git diff` if nothing staged)
3. Analyze what changed and why
4. Determine appropriate type from the table
5. Write concise description (imperative: "add" not "added")
6. Use HEREDOC for multi-line messages:

```bash
git commit -m "$(cat <<'EOF'
feat(scope): description

Body text here.

Co-Authored-By: Claude <noreply@anthropic.com>
EOF
)"
```

## Safety Rules

- Never commit without explicit user request
- Check `git status` before committing
- Don't use `--force` or `--no-verify`
- Verify staged files don't contain secrets
