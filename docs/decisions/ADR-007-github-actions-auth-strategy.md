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
- One secret: `CLAUDE_CODE_OAUTH_TOKEN` — a long-lived token (~1 year) minted via
  `claude setup-token`.
- Billing: against the user's Max/Pro Claude subscription (not per-token API charges).
  Suitable for teams with existing subscriptions who want to avoid API billing.
- Setup: requires `claude setup-token` once per user. Single secret, no PAT required.
- Token lifespan: ~1 year. No rotation step needed.

**The decision context:** This is a distributable workflow file. Different teams have
different billing preferences and existing subscriptions. The integration must work for
both without requiring teams to choose a different file — only different secrets.

### Alternatives Considered

| Alternative | Pros | Cons | Why Not |
|-------------|------|------|---------|
| API key only | Simplest; universal distribution | Per-token billing; no subscription path | Excludes teams with Max/Pro subscriptions who prefer that billing model |
| OAuth only | Subscription billing; single secret | Requires `claude setup-token` setup; not universally distributable | Excludes teams without existing subscriptions |
| **Dual-path (API key preferred when both present)** | Universal distribution; teams choose by which secrets they configure | Slightly more complex workflow YAML | — |
| **Dual-path (OAuth preferred when both present)** | Subscription billing preferred over per-token for cost-sensitive teams | Teams who configure both accidentally pay via subscription | Confusing default |

## Decision

**Accepted.** Implement dual-path auth with OAuth preferred when `CLAUDE_CODE_OAUTH_TOKEN`
is present. Fall back to `ANTHROPIC_API_KEY` when it is absent.

**Preference rationale:** Teams that go through the OAuth setup explicitly intend to use
subscription billing. API key is the zero-setup default. Preferring OAuth when configured
reflects the user's explicit intent.

**Implementation:** Auth path selection is implicit — Claude Code detects
`CLAUDE_CODE_OAUTH_TOKEN` in the environment and prefers it over `ANTHROPIC_API_KEY`.
The workflow injects both secrets as env vars; no explicit `if:` branching is required
in the `claude` invocation step itself.

**Token rotation:** Not required. `claude setup-token` issues a long-lived token (~1 year).
No `SECRETS_ADMIN_PAT` or rotation step is needed.

## Consequences

### Positive
- Single workflow file works for both billing models — teams activate by configuring
  the appropriate secret(s).
- Zero additional complexity for API key users (the simplest and most common path).
- OAuth path requires only one secret (`CLAUDE_CODE_OAUTH_TOKEN`) — no PAT, no rotation.
- If neither auth path is configured, claude fails with an auth error, which is caught
  by the error handling flow and results in a visible error comment rather than a
  silent failure.

### Negative
- The implicit auth path selection (env var presence) means teams who accidentally
  configure both secrets will use OAuth, which may surprise API-key-intending users.

### Neutral
- `ANTHROPIC_API_KEY` is recommended for the initial distribution documentation as
  the simpler path. OAuth is documented as an alternative for subscription users.
- Future v2 could make auth path explicit via a workflow input (`auth_mode: oauth|apikey`)
  if implicit selection causes confusion.

## When to Reconsider

- If `CLAUDE_CODE_OAUTH_TOKEN` token lifespan changes (e.g., moves to short-lived) —
  a rotation step would need to be reintroduced.
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
