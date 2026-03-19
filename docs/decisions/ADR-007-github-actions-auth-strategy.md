---
adr_version: "1.0"
type: adr
id: ADR-007
title: "Dual-Path Auth Strategy for GitHub Actions Genie Invocations"
status: accepted
created: 2026-03-19
deciders: [architect, navigator]
domain: platform
spec_refs:
  - docs/specs/platform/github-actions-integration.md
backlog_ref: docs/backlog/P2-github-actions-slash-commands.md
tags: [architecture, github-actions, auth, billing, security]
---

# ADR-007: Dual-Path Auth Strategy for GitHub Actions Genie Invocations

## Context

The GitHub Actions genie slash command integration must authenticate to the Anthropic
API from an ephemeral GitHub Actions runner. Two distinct authentication mechanisms
are available, each with materially different billing, setup, and security characteristics:

**Path A: API Key (`ANTHROPIC_API_KEY`)**
- Single secret: a standard Anthropic API key stored as a GitHub repo secret.
- Billing: per-token, charged to the API key owner's account.
- Setup: zero additional setup beyond obtaining a key from console.anthropic.com.
- Availability: universally distributable — any team can activate with one secret.
- No token expiry or rotation concerns.

**Path B: OAuth Subscription Token**
- Four secrets: `CLAUDE_CODE_OAUTH_TOKEN`, `CLAUDE_REFRESH_TOKEN`, `CLAUDE_EXPIRES_AT`
  (the OAuth token bundle), plus `SECRETS_ADMIN_PAT` (a GitHub PAT with `secrets:write`
  for auto-rotating the short-lived OAuth token after each invocation).
- Billing: against the user's Max/Pro Claude subscription (not per-token API charges).
  Suitable for teams with existing subscriptions who want to avoid API billing.
- Setup: requires `claude setup-token` once per user to mint the initial token bundle.
  More complex — not universally distributable without user setup.
- Token lifespan: short-lived. Claude Code refreshes internally during invocation.
  The `SECRETS_ADMIN_PAT` pattern writes the refreshed token back to repo secrets.
- Reference implementation: `anthropics/claude-code-action` OAuth variant.

**The decision context:** This is a distributable workflow file. Different teams have
different billing preferences and existing subscriptions. The integration must work for
both without requiring teams to choose a different file — only different secrets.

### Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| API key only | Simplest; universal distribution; no rotation | Per-token billing; no subscription path | Excludes teams with Max/Pro subscriptions who prefer that billing model |
| OAuth only | Subscription billing; familiar to claude-code-action users | Requires 4 secrets + PAT setup; not universally distributable | Excludes teams without existing subscriptions or those who prefer API key simplicity |
| **Dual-path (API key preferred when both present)** | Universal distribution; teams choose by which secrets they configure | Slightly more complex workflow YAML; rotation step is a no-op for API key users | — |
| **Dual-path (OAuth preferred when both present)** | Subscription billing preferred over per-token for cost-sensitive teams | Teams who configure both accidentally pay via subscription even if they intended API key | Confusing default |

## Decision

**Accepted.** Implement dual-path auth with OAuth preferred when the full OAuth secret
bundle is present (`CLAUDE_CODE_OAUTH_TOKEN` + `CLAUDE_REFRESH_TOKEN` + `CLAUDE_EXPIRES_AT`
+ `SECRETS_ADMIN_PAT`). Fall back to `ANTHROPIC_API_KEY` when OAuth secrets are absent.

**Preference rationale:** Teams that go through the OAuth setup explicitly intend to use
subscription billing. API key is the zero-setup default. Preferring OAuth when configured
reflects the user's explicit intent.

**Implementation:** Auth path selection is implicit — Claude Code detects
`CLAUDE_CODE_OAUTH_TOKEN` in the environment and prefers it over `ANTHROPIC_API_KEY`.
The workflow injects all secrets as env vars; no explicit `if:` branching is required
in the `claude` invocation step itself.

**Token rotation:** An explicit post-invocation step conditionally rotates OAuth tokens
back to repo secrets using `SECRETS_ADMIN_PAT`. This step is gated on
`SECRETS_ADMIN_PAT` being non-empty and uses `continue-on-error: true` (rotation
failure must not block the result comment from being posted).

## Consequences

### Positive
- Single workflow file works for both billing models — teams activate by configuring
  the appropriate secrets.
- Zero additional complexity for API key users (the simplest and most common path).
- OAuth teams get subscription billing with automatic token rotation matching the
  `anthropics/claude-code-action` reference pattern.
- If neither auth path is configured, claude fails with an auth error, which is caught
  by the error handling flow and results in a visible error comment rather than a
  silent failure.

### Negative
- The `SECRETS_ADMIN_PAT` requirement for OAuth rotation is a high-privilege secret
  (requires `secrets:write` on the repo). Teams must understand what they are granting.
- OAuth token rotation depends on Claude Code updating env vars in-process during
  invocation. This behavior may change across Claude Code versions. If rotation
  silently fails, the OAuth token expires and the next invocation fails with an auth
  error until the user re-runs `claude setup-token`.
- The implicit auth path selection (env var presence) means teams who accidentally
  configure both sets of secrets will use OAuth, which may surprise API-key-intending
  users.

### Neutral
- `ANTHROPIC_API_KEY` is recommended for the initial distribution documentation as
  the simpler path. OAuth is documented as an advanced option.
- Future v2 could make auth path explicit via a workflow input (`auth_mode: oauth|apikey`)
  if implicit selection causes confusion.

## When to Reconsider

- If `anthropics/claude-code-action` changes its OAuth token rotation mechanism or
  env var names — the `SECRETS_ADMIN_PAT` pattern must be updated to match.
- If the Claude Code CLI adds an explicit `--auth` flag (as anticipated in ADR-005
  SDK migration) — use that flag for explicit path control rather than implicit env
  var detection.
- If teams report confusion about which billing path is active — add a workflow step
  that logs the detected auth path (without exposing secret values).

## Related Decisions

- ADR-005: SDK-Integrated Orchestrator — anticipates explicit `--auth oauth|apikey`
  flag in the SDK migration; that flag would supersede the implicit detection used here.
- ADR-006: issue_comment event trigger — establishes the event model this auth strategy
  operates within.
- P2-github-actions-slash-commands: Implementation backlog item.
