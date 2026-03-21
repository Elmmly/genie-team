---
adr_version: "1.0"
type: adr
id: ADR-010
title: "Use --dangerously-skip-permissions for Headless CI Genie Invocations"
status: accepted
created: 2026-03-21
deciders: [architect, navigator]
domain: platform
spec_refs:
  - docs/specs/platform/github-actions-integration.md
backlog_ref: docs/backlog/P2-github-actions-slash-commands.md
tags: [architecture, github-actions, security, permissions, headless]
---

# ADR-010: Use --dangerously-skip-permissions for Headless CI Genie Invocations

## Context

The GitHub Actions genie slash command integration invokes `claude` headlessly
on an ephemeral `ubuntu-latest` runner. Claude Code's interactive permission
model — which prompts the user before performing file writes, shell execution,
or other potentially destructive operations — requires a TTY and a human
operator present. Neither is available in CI.

Two flags address this:

**`--allowedTools "WebFetch,WebSearch,Read,Glob,Grep"`**
An explicit tool allowlist restricting Claude to read-only operations. This is
the primary security control: Scout and Critic require no write operations, so
the allowlist directly encodes the intended capability scope.

**`--dangerously-skip-permissions`**
Disables the interactive permission prompts so the headless process can proceed
without a TTY. The name signals that the caller has accepted responsibility for
scoping Claude's capabilities through other means.

**The relationship between the two flags:**
`--dangerously-skip-permissions` without `--allowedTools` would be genuinely
dangerous — Claude could write files, execute shell commands, or perform other
operations without any safeguard. The combination is safe because
`--allowedTools` restricts capability before `--dangerously-skip-permissions`
removes the interactive gate. The permissions flag is only needed because the
tool allowlist alone does not satisfy the CLI's requirement for explicit operator
consent in non-interactive mode.

### Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| TTY simulation (`script`, `expect`) | Avoids the flag | Complex, fragile, requires pty | Adds significant complexity for no security benefit over the allowlist approach |
| `--allowedTools` only (no skip-permissions) | Cleaner signal | CLI still blocks on interactive prompt in headless context | Does not work — process hangs waiting for TTY input |
| Write-capable tool scope | More flexible | Claude could modify repo content from untrusted prompts | Violates v1 read-only scope; unacceptable prompt injection blast radius |
| User-level permission grant in settings | Persistent | Affects all sessions, not scoped to CI | Too broad — permission should be scoped to the headless invocation only |

## Decision

**Accepted.** Use `--dangerously-skip-permissions` in combination with
`--allowedTools "WebFetch,WebSearch,Read,Glob,Grep"` for all headless genie
invocations in the GitHub Actions workflow.

The `--allowedTools` allowlist is the security boundary. The
`--dangerously-skip-permissions` flag is an operational enabler that allows the
process to run without a TTY — it does not expand Claude's effective capability
because the allowlist takes precedence.

**Scope:** This decision applies only to the ephemeral `ubuntu-latest` runner
context. Interactive sessions retain the default permission model.

## Consequences

### Positive
- Headless execution works without TTY simulation or process wrapper complexity.
- The tool allowlist provides a clear, auditable record of what Claude can do
  during CI invocations.
- Any attempt by a prompt-injection payload to invoke write tools (Edit, Write,
  Bash) is blocked by the allowlist before reaching execution.

### Negative
- The flag name (`--dangerously-skip-permissions`) reads as alarming without
  context. Reviewers unfamiliar with the `--allowedTools` pairing may flag it
  as a security concern. This ADR exists to provide that context.
- If `--allowedTools` is inadvertently removed in a future edit, the invocation
  becomes genuinely dangerous. Both flags must appear together; removing either
  one alone changes the security posture.

### Neutral
- The combination is the recommended pattern for read-only headless Claude Code
  invocations. Other integrations (Claude GitHub Action, etc.) use the same
  approach.

## When to Reconsider

- If the Claude Code CLI adds a dedicated `--headless` or `--ci` flag that
  bundles the non-interactive behavior without the permission-skip semantics —
  migrate to that flag.
- If v2 requires write capability (e.g., Crafter phase auto-commits) — the
  allowlist scope must be expanded deliberately, with a security review, and
  this ADR updated to document the expanded capability.
- If `--allowedTools` validation changes such that it no longer takes precedence
  over `--dangerously-skip-permissions` — reassess the combined security model.

## Related Decisions

- ADR-006: issue_comment event trigger — establishes the event model this runs within.
- ADR-007: Dual-path auth strategy — establishes the auth model for the same invocation.
- P2-github-actions-slash-commands: Implementation backlog item.
