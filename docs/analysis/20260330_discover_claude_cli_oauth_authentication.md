---
type: discover
topic: "Claude CLI OAuth Authentication for Headless/Daemon Modes"
reasoning_mode: deep
status: active
created: "2026-03-30"
---

# Opportunity Snapshot: Claude CLI OAuth Authentication for Headless/Daemon Modes

## 1. Discovery Question

**Original:** How does Claude CLI OAuth authentication work, and can it support headless/daemon/non-interactive modes?

**Reframed:** What are the authentication constraints and gaps that affect running Claude Code in unattended, daemon, or CI/CD scenarios -- and which features are locked behind OAuth vs. available with API keys?

## 2. How Claude CLI OAuth Works Today

### Authentication Flow

When you run `claude` for the first time, it opens a browser window for OAuth login via claude.ai. If the browser cannot open (e.g., SSH), pressing `c` copies the login URL to the clipboard for manual use.

**CLI auth commands:**
- `claude auth login` -- Sign in. Flags: `--email` (pre-fill), `--sso` (force SSO), `--console` (API billing instead of subscription)
- `claude auth logout` -- Sign out
- `claude auth status` -- Show auth status as JSON (`--text` for human-readable). Exit code 0 = logged in, 1 = not
- `/login` and `/logout` -- In-session equivalents

### Token Storage

| Platform | Location |
|----------|----------|
| macOS | Encrypted macOS Keychain |
| Linux | `~/.claude/.credentials.json` (mode 0600) |
| Windows | `~/.claude/.credentials.json` (user profile ACLs) |

Override with `$CLAUDE_CONFIG_DIR` to change the base directory.

Additional state in `~/.claude.json`: stores `hasCompletedOnboarding`, `oauthAccount` (UUID, email, org UUID), and `lastOnboardingVersion`.

### Token Lifetime and Refresh

- **OAuth access tokens:** Expire after ~10-15 minutes
- **Refresh tokens:** Used to obtain new access tokens transparently in **interactive mode**
- **`setup-token` tokens:** 1-year validity (long-lived, inference-only scope)
- **Token refresh in non-interactive mode:** BROKEN. OAuth access tokens expire and are NOT refreshed when using `-p` with `--output-format json/stream-json`. This causes 401 errors after ~10-15 minutes. Filed as Issue #28827 (closed as duplicate of #12447 and #21765). No fix confirmed as shipped.

### Authentication Precedence (highest to lowest)

1. **Cloud provider credentials** -- `CLAUDE_CODE_USE_BEDROCK`, `CLAUDE_CODE_USE_VERTEX`, `CLAUDE_CODE_USE_FOUNDRY`
2. **`ANTHROPIC_AUTH_TOKEN`** -- Bearer token for LLM gateways/proxies
3. **`ANTHROPIC_API_KEY`** -- Direct API key from Claude Console (`sk-ant-api03-...`). In interactive mode, prompts once for approval. In `-p` mode, always used when present.
4. **`apiKeyHelper`** script -- Dynamic/rotating credentials from a vault. Called every 5 min or on 401. Customize TTL via `CLAUDE_CODE_API_KEY_HELPER_TTL_MS`.
5. **Subscription OAuth** -- Default for Pro/Max/Team/Enterprise users via `/login`

**Critical note:** `apiKeyHelper`, `ANTHROPIC_API_KEY`, and `ANTHROPIC_AUTH_TOKEN` apply to **terminal CLI sessions only**. Claude Desktop and remote sessions use OAuth exclusively.

### API Key vs OAuth: Billing Model

| Prefix | Type | Billing |
|--------|------|---------|
| `sk-ant-oat01-...` | OAuth token (from `setup-token`) | Against Pro/Max subscription quota |
| `sk-ant-api03-...` | API key (from Console) | Pay-per-token API billing |

These are two completely separate billing systems.

## 3. Headless/Non-Interactive OAuth

### `claude setup-token` Command

Generates a long-lived (1-year) OAuth token for use in automated environments:

```bash
# On a machine with a browser
claude setup-token
# Outputs: sk-ant-oat01-xxxxx...xxxxx (store securely, shown once)

# On the headless machine
export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..."
```

**Limitations of `setup-token` tokens:**
- **Inference-only scope** -- cannot establish Remote Control sessions
- **Does not bypass onboarding** -- Must also create `~/.claude.json` with `{"hasCompletedOnboarding": true}` and `oauthAccount` data (Issue #8938, still open)
- **Pro/Max subscription required** -- not available for Console/API-only accounts

### Full Headless Setup Recipe (from community)

```bash
# 1. On machine with browser: generate token
claude setup-token

# 2. On machine with browser: extract account info
cat ~/.claude.json | python3 -c "import json,sys; d=json.load(sys.stdin); print(json.dumps(d.get('oauthAccount'), indent=2))"

# 3. On headless machine: set env var
export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-your-token-here"

# 4. On headless machine: create ~/.claude.json
cat > ~/.claude.json << 'EOF'
{
  "hasCompletedOnboarding": true,
  "lastOnboardingVersion": "2.1.29",
  "oauthAccount": {
    "accountUuid": "your-uuid",
    "emailAddress": "your@email.com",
    "organizationUuid": "your-org-uuid"
  }
}
EOF
```

### SSH Port Forwarding Workaround

For interactive headless auth (no `setup-token`):

```bash
# Local machine
ssh -L 8080:localhost:8080 user@remote-server.com

# Remote machine
claude /login
# Open the displayed localhost URL in your local browser
```

Blocked by corporate firewalls or `AllowTcpForwarding no`.

### Can `claude -p` Reuse OAuth Tokens?

Yes, but with the token refresh bug caveat:
- If authenticated interactively, subsequent `claude -p` calls use the cached OAuth credentials
- If using `CLAUDE_CODE_OAUTH_TOKEN`, the long-lived token avoids the refresh issue
- If using `ANTHROPIC_API_KEY`, no OAuth is involved at all

### Device Code Flow / Service Accounts

**No device code flow exists.** There is no `claude auth login --device-code` or similar.
**No service account concept exists.** The closest equivalent is an API key from the Console.

## 4. Features Requiring OAuth vs. API Key

| Feature | OAuth (Subscription) | API Key | `setup-token` (OAuth, limited scope) | Notes |
|---------|---------------------|---------|--------------------------------------|-------|
| `claude -p` (batch/print mode) | Yes | Yes | Yes | Primary headless use case |
| Interactive `claude` | Yes | Yes | Yes (with onboarding workaround) | |
| Remote Control | **Yes (full OAuth only)** | No | **No** (inference-only scope insufficient) | Explicitly requires "full-scope login token" |
| Auto Mode | Yes (Team plan required) | Unclear, likely yes with Team plan | Unclear | Requires Team plan + Sonnet/Opus 4.6 |
| Channels | **Yes (claude.ai login only)** | **No** | Unclear (likely no -- inference-only) | "Console and API key authentication is not supported" |
| Scheduled Tasks (`/loop`) | Yes | Yes | Yes | Session-scoped, inherits session auth |
| Desktop Scheduled Tasks | Yes (OAuth via Desktop) | N/A | N/A | Desktop uses OAuth exclusively |
| Cloud Scheduled Tasks | Yes (subscription) | Unclear | Unclear | Runs on Anthropic cloud |
| Dispatch (Desktop) | Yes (OAuth via Desktop) | N/A | N/A | Desktop uses OAuth exclusively |
| GitHub Actions (`claude-code-action`) | Yes | Yes | Yes (`claude_code_oauth_token` input) | Both auth methods documented |

### Key Takeaway

**Remote Control and Channels are OAuth-only.** Standard `claude -p` batch execution works fine with API keys. The Agent SDK officially recommends API keys and explicitly discourages OAuth tokens for third-party products.

## 5. Agent SDK Authentication

### Official Stance

From the Agent SDK overview docs:

> "Unless previously approved, Anthropic does not allow third party developers to offer claude.ai login or rate limits for their products, including agents built on the Claude Agent SDK. Please use the API key authentication methods described in this document instead."

### SDK Auth Methods

1. **`ANTHROPIC_API_KEY`** -- Primary recommended method
2. **Cloud providers** -- Bedrock (`CLAUDE_CODE_USE_BEDROCK=1`), Vertex (`CLAUDE_CODE_USE_VERTEX=1`), Foundry (`CLAUDE_CODE_USE_FOUNDRY=1`)
3. **`CLAUDE_CODE_OAUTH_TOKEN`** -- Works technically (community demo exists: `weidwonder/claude_agent_sdk_oauth_demo`), but officially discouraged for third-party apps

### SDK vs CLI Auth Issue (#6536)

Issue #6536 asked if the SDK could use `CLAUDE_CODE_OAUTH_TOKEN`. Response: The SDK is designed for **programmatic use** with API keys (pay-per-token). OAuth tokens are for **interactive CLI** use (subscription billing). Issue closed as NOT_PLANNED.

**However:** The `claude_agent_sdk_oauth_demo` repo demonstrates that `CLAUDE_CODE_OAUTH_TOKEN` does work with the SDK in practice, even if not officially supported for third-party distribution.

## 6. CI/CD Authentication

### GitHub Actions (`claude-code-action`)

Supports two auth methods:

```yaml
- uses: anthropics/claude-code-action@v1
  with:
    # Option 1: API Key
    anthropic_api_key: ${{ secrets.ANTHROPIC_API_KEY }}
    # Option 2: OAuth Token (from setup-token)
    claude_code_oauth_token: ${{ secrets.CLAUDE_CODE_OAUTH_TOKEN }}
```

### General CI/CD Pattern

```bash
# API Key approach (simplest)
export ANTHROPIC_API_KEY="sk-ant-api03-..."
claude -p "run tests and fix failures"

# OAuth Token approach (uses subscription quota)
export CLAUDE_CODE_OAUTH_TOKEN="sk-ant-oat01-..."
echo '{"hasCompletedOnboarding": true}' > ~/.claude.json
claude -p "run tests and fix failures"
```

### Container/Docker Authentication

The `setup-container-guide` pattern:
1. Generate token locally with `claude setup-token`
2. Pass as environment variable or mount credentials
3. Ensure `~/.claude.json` has `hasCompletedOnboarding: true`

## 7. Assumptions & Evidence

| Assumption | Type | Confidence | Evidence For | Evidence Against |
|------------|------|------------|--------------|------------------|
| `setup-token` provides 1-year tokens | feasibility | high | Multiple sources confirm this. Community gist, official docs reference for GitHub Actions. Consistent across all sources. | No contradicting evidence found. |
| OAuth token refresh is broken in `-p` mode | feasibility | high | Issue #28827 with reproduction steps, closed as dup of #12447 and #21765. Multiple reporters. Consistent symptoms. | Issue is closed -- may have been silently fixed. No confirmed fix in changelogs. |
| `setup-token` + `hasCompletedOnboarding` is the complete headless recipe | usability | moderate | Community gist with detailed steps, Issue #8938 documents the gap. Multiple Docker users confirm. | The onboarding version number may drift, requiring updates. Account info extraction is undocumented. |
| Remote Control requires full OAuth (not `setup-token`) | feasibility | high | Official docs explicitly state: "These tokens are limited to inference-only and cannot establish Remote Control sessions." Clear error message documented. | None. |
| Channels require claude.ai OAuth login | feasibility | high | Official channels-reference docs: "Console and API key authentication is not supported." | None. |
| Agent SDK officially requires API keys, not OAuth | viability | high | SDK overview explicitly says third-party developers should not use claude.ai login. Issue #6536 closed NOT_PLANNED. | Community demo shows it works technically. Anthropic may change stance. |
| API keys work for all `claude -p` scenarios | feasibility | high | Auth precedence docs, GitHub Actions docs, multiple community confirmations. | None. |
| No device code flow or service account exists | feasibility | high | Exhaustive search found no documentation or flags. Issue #7100 requested it, closed NOT_PLANNED. | May exist undocumented. |

### Evidence Grade Justifications

- **High confidence items:** Backed by official Anthropic docs (code.claude.com), multiple GitHub issues with consistent reports, and community replication. Sample: 3+ independent sources per claim.
- **Moderate confidence items:** Community gists and single-source documentation. The `hasCompletedOnboarding` workaround is well-replicated but not officially documented by Anthropic.

## 8. Technical Signals

- **Feasibility:** Straightforward for API key auth in `-p` mode. Moderate complexity for OAuth in headless setups. Complex/fragile for features requiring full OAuth scope.
- **Constraints:**
  - Token refresh bug in non-interactive mode is a significant daemon risk
  - `setup-token` scope limitations block Remote Control and likely Channels
  - Two separate billing systems (subscription vs API) create confusion
  - `hasCompletedOnboarding` hack is fragile and version-dependent
- **Needs Architect spike:** Yes -- for genie-team daemon design, need to decide: API key (simple, pay-per-token) vs OAuth token (subscription billing, scope limitations) vs hybrid approach

## 9. Opportunity Areas (Unshaped)

1. **Authentication strategy for genie-team daemon mode** -- Which auth method(s) should the daemon use? API key is simplest and most reliable for `claude -p`. OAuth token (via `setup-token`) allows subscription billing but has scope limits and the refresh bug.

2. **Token lifecycle management** -- `setup-token` tokens last 1 year. What happens at expiry? No auto-rotation mechanism exists. A daemon needs token health monitoring and renewal workflow.

3. **Feature access tier mapping** -- Remote Control and Channels are OAuth-only. If genie-team wants to expose these capabilities, it needs full OAuth -- which means interactive setup and the refresh bug risk.

4. **`apiKeyHelper` for credential rotation** -- The existing `apiKeyHelper` mechanism (called every 5min or on 401) could be leveraged for vault-based credential management in daemon scenarios. No community examples found for this pattern.

5. **Agent SDK auth vs CLI auth divergence** -- The SDK officially forbids OAuth for third-party apps but the CLI supports it. Genie-team sits in a gray area (personal tooling, not third-party distribution). This distinction matters for the SDK migration.

## 10. Evidence Gaps

- **Is the token refresh bug (#28827/#12447/#21765) actually fixed?** Issues are closed but no changelog entry confirms a fix. Need to test empirically with a long-running `-p` session using OAuth.
- **Does `setup-token` work with Channels?** The docs say "claude.ai login" required -- unclear if the long-lived token qualifies or if full-scope browser OAuth is needed.
- **What happens when a `setup-token` token expires?** No documentation on expiry behavior or renewal process.
- **Can `apiKeyHelper` be used with the Agent SDK?** The SDK docs mention `ANTHROPIC_API_KEY` but not `apiKeyHelper`.
- **Auto Mode auth requirements:** Requires Team plan, but does it specifically require OAuth or does API key with Team plan work?
- **Cloud Scheduled Tasks auth:** Runs on Anthropic infra -- how does it authenticate? Likely subscription OAuth but not confirmed.

## 11. CLI Auth Flags Quick Reference

| Flag/Command | Purpose |
|-------------|---------|
| `claude auth login` | Interactive browser OAuth |
| `claude auth login --console` | Console/API billing login |
| `claude auth login --sso` | Force SSO |
| `claude auth login --email user@co.com` | Pre-fill email |
| `claude auth logout` | Sign out |
| `claude auth status` | JSON auth status (exit 0/1) |
| `claude auth status --text` | Human-readable auth status |
| `claude setup-token` | Generate 1-year inference-only OAuth token |
| `/login` | In-session login |
| `/logout` | In-session logout |
| `/status` | In-session auth status |
| `ANTHROPIC_API_KEY` | Env var for API key auth |
| `ANTHROPIC_AUTH_TOKEN` | Env var for bearer token (gateway/proxy) |
| `CLAUDE_CODE_OAUTH_TOKEN` | Env var for `setup-token` output |
| `CLAUDE_CODE_API_KEY_HELPER_TTL_MS` | Env var to customize `apiKeyHelper` refresh interval |

**No `--auth-token` or `--oauth-token` CLI flags exist.** Auth is handled via env vars and the `auth` subcommand, not inline flags.

## 12. Routing Recommendation

- [x] **Ready for Shaper** -- Problem understood
- [ ] **Needs Architect Spike** -- One targeted question: empirically test whether token refresh bug is fixed in current Claude Code version

**Rationale:** The authentication landscape is now well-characterized. The primary decision for genie-team daemon mode is a strategy call (API key vs OAuth vs hybrid), which is a shaping question. One empirical test (does `-p` mode properly refresh OAuth tokens now?) would close the most important evidence gap, but the findings are sufficient to shape the auth approach for the SDK migration regardless of that answer, since API key auth is the reliable path.

## Sources

- [Authentication - Claude Code Docs](https://code.claude.com/docs/en/authentication)
- [CLI Reference - Claude Code Docs](https://code.claude.com/docs/en/cli-reference)
- [Remote Control - Claude Code Docs](https://code.claude.com/docs/en/remote-control)
- [Channels Reference - Claude Code Docs](https://code.claude.com/docs/en/channels-reference)
- [Scheduled Tasks - Claude Code Docs](https://code.claude.com/docs/en/scheduled-tasks)
- [Agent SDK Overview - Claude API Docs](https://platform.claude.com/docs/en/agent-sdk/overview)
- [claude-code-action setup.md](https://github.com/anthropics/claude-code-action/blob/main/docs/setup.md)
- [Issue #28827: OAuth token refresh fails in non-interactive mode](https://github.com/anthropics/claude-code/issues/28827)
- [Issue #7100: Document headless/remote authentication](https://github.com/anthropics/claude-code/issues/7100)
- [Issue #8938: setup-token not enough to authenticate](https://github.com/anthropics/claude-code/issues/8938)
- [Issue #6536: SDK use of CLAUDE_CODE_OAUTH_TOKEN](https://github.com/anthropics/claude-code/issues/6536)
- [Automating Claude Code on Headless VPS (community gist)](https://gist.github.com/coenjacobs/d37adc34149d8c30034cd1f20a89cce9)
- [claude_agent_sdk_oauth_demo](https://github.com/weidwonder/claude_agent_sdk_oauth_demo)
