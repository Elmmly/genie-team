---
type: spike
question: "Can claude CLI authenticate via OAuth in headless/daemon mode?"
verdict: Partially Feasible
time_spent: "1 session"
created: "2026-03-30"
refs:
  - docs/analysis/20260330_discover_claude_code_autonomous_orchestration_features.md
  - docs/analysis/20260330_discover_claude_cli_oauth_authentication.md
---

# Spike: Can Claude CLI Authenticate via OAuth in Headless/Daemon Mode?

**Question:** Can the `claude` CLI authenticate via OAuth without an interactive browser flow, enabling headless daemon execution with access to OAuth-gated features (Remote Control, Auto Mode, Channels)?

**Verdict:** PARTIALLY FEASIBLE — API key remains the reliable headless path, but `setup-token` provides a limited OAuth bridge. The auth wall is real but has workarounds.

---

## Findings

### Auth Hierarchy (Precedence Order)

The Claude CLI resolves auth in this order:

1. Cloud provider environment variables (Bedrock/Vertex)
2. `ANTHROPIC_AUTH_TOKEN` (OAuth token, passed as env var)
3. `ANTHROPIC_API_KEY` (API key)
4. `apiKeyHelper` script (dynamic key provisioning)
5. Subscription OAuth (interactive login, tokens in macOS Keychain or `~/.claude/.credentials.json`)

### Three Auth Paths for Headless Execution

| Path | Mechanism | Token Lifetime | Features Unlocked | Reliability |
|------|-----------|---------------|-------------------|-------------|
| **API Key** | `ANTHROPIC_API_KEY` env var | Indefinite | `claude -p`, `/loop`, scheduled tasks, GitHub Actions | **High** — battle-tested, no refresh issues |
| **Setup Token** | `claude setup-token` → `sk-ant-oat01-...` | 1 year | `claude -p`, `/loop`, scheduled tasks | **Medium** — requires manual `.claude.json` workaround (Issue #8938) |
| **OAuth Token** | `ANTHROPIC_AUTH_TOKEN` env var | ~10-15 min (unrefreshed) | Same as setup-token | **Low** — token refresh broken in `-p` mode (Issues #28827, #12447, #21765) |

### What Each Path Cannot Do

| Feature | API Key | Setup Token | Full OAuth |
|---------|---------|-------------|-----------|
| Remote Control | No | No (inference-only scope) | **Yes** |
| Channels | No | Unclear (likely no) | **Yes** |
| Auto Mode | No | Unclear | **Yes** |
| Dispatch | No | No | **Yes** (Desktop only) |
| `claude -p` batch | **Yes** | **Yes** | **Yes** |
| `/loop` session-scoped | **Yes** | **Yes** | **Yes** |
| Scheduled Tasks (desktop) | **Yes** | **Yes** | **Yes** |
| Scheduled Tasks (cloud) | **Yes** | **Yes** | **Yes** |
| GitHub Actions | **Yes** | **Yes** | N/A |

### The `setup-token` Workaround

`claude setup-token` generates a 1-year inference-only OAuth token for headless use:

```bash
claude setup-token
# Outputs: sk-ant-oat01-...
```

**Current bug (Issue #8938):** The token alone doesn't work — you must also manually create `~/.claude.json`:
```json
{
  "hasCompletedOnboarding": true,
  "oauthAccount": {
    "emailAddress": "user@example.com",
    "organizationName": "your-org"
  }
}
```

**Scope limitation:** `setup-token` creates an **inference-only** token. It cannot access features that require full OAuth session scope (Remote Control, Channels).

### The `apiKeyHelper` Pattern

For credential rotation without hardcoded keys:
```json
{
  "apiKeyHelper": {
    "command": "/path/to/script",
    "timeout_ms": 5000
  }
}
```

The helper script is called before each API request. It can fetch from vaults (1Password, AWS Secrets Manager, etc.) and rotate credentials. This is the recommended production pattern for daemon execution with API keys.

### Agent SDK Auth Model

The `@anthropic-ai/claude-agent-sdk` explicitly requires `ANTHROPIC_API_KEY`:

> "The Agent SDK does not allow third-party developers to offer claude.ai login or rate limits."

`CLAUDE_CODE_OAUTH_TOKEN` works as an undocumented env var but Issue #6536 was closed NOT_PLANNED — Anthropic does not intend to support OAuth in the SDK.

---

## Impact on Genie Team

### Current State

Genie Team uses `ANTHROPIC_API_KEY` via environment variable. The shell orchestrator (`scripts/genies`) and TypeScript SDK (`src/core/phase-executor.ts`) both inherit auth from the environment. The `--auth oauth|apikey` flag is spec'd but not yet wired in the shell script.

Your system has `ANTHROPIC_API_KEY` set in `~/.zshrc` → API key billing mode.

### What This Means for Feature Adoption

The three features identified as high/medium priority in the orchestration discovery:

1. **Auto Mode** — **Blocked.** Requires full OAuth. API key and `setup-token` don't qualify. No workaround.

2. **Remote Control** — **Blocked.** Requires full OAuth session scope. `setup-token` is inference-only. No workaround.

3. **Channels** — **Blocked.** Requires full OAuth. No confirmed workaround.

4. **Desktop Scheduled Tasks** — **Available.** Works with API key. Already accessible.

5. **Cloud Scheduled Tasks** — **Available.** Works with API key. Already accessible.

6. **`/loop`** — **Available.** Works with API key. Already used.

### The Hybrid Model

A practical architecture emerges:

```
┌─────────────────────────────────────────────────────┐
│  INTERACTIVE (Human-supervised)                      │
│  Auth: OAuth (interactive login)                     │
│  Features: Remote Control, Auto Mode, Channels       │
│  Use: Supervised genie sessions, mobile monitoring   │
└─────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────┐
│  HEADLESS (Daemon/CI/CD)                             │
│  Auth: API Key (via ANTHROPIC_API_KEY or apiKeyHelper)│
│  Features: claude -p, /loop, scheduled tasks         │
│  Use: Autonomous genies, batch execution, daemon     │
└─────────────────────────────────────────────────────┘
```

These are **not mutually exclusive** — the same machine can run both:
- Interactive sessions with OAuth (get Remote Control, Auto Mode)
- Daemon processes with API key (reliable headless execution)

The `--auth` flag in genie-team's spec (AC-3) was already designed for this: `--auth oauth` unsets `ANTHROPIC_API_KEY` to force OAuth, `--auth apikey` requires it.

---

## Risks

1. **OAuth token refresh bug is a blocker for unified auth.** Even if you wanted OAuth everywhere, the `-p` mode refresh bug (Issues #28827/#12447) makes it unreliable for long-running daemon processes. API key has no such issue.

2. **Auto Mode's safety benefit is unavailable to daemon mode.** The most valuable native feature (replacing `--dangerously-skip-permissions` with a classifier) requires OAuth. Daemon mode must continue using `--dangerously-skip-permissions` or `--skip-permissions`.

3. **Feature bifurcation.** Interactive and headless sessions have different capability sets. This is manageable but adds complexity to documentation and user expectations.

4. **Anthropic's direction is unclear.** The `setup-token` scope limitation and SDK OAuth rejection (Issue #6536) suggest Anthropic may intentionally keep premium features OAuth-gated (tied to subscription). This may not change.

---

## Recommendation

**Accept the hybrid model. Don't fight the auth wall — work with it.**

### Immediate (no code changes needed)

1. **Document the hybrid auth model** as an ADR. Interactive sessions use OAuth for enhanced features. Daemon/CI uses API key for reliability.

2. **Implement the `--auth` flag** in the shell orchestrator (already spec'd in AC-3, TypeScript implementation ready in `src/environment/auth.ts`).

3. **Test `apiKeyHelper`** for credential rotation in daemon mode — this is the production-grade API key management pattern.

### Short-term (when SDK migration completes)

4. **Wire Auto Mode into interactive genie sessions** — when a user runs genies interactively with OAuth, enable Auto Mode instead of `--dangerously-skip-permissions`.

5. **Add Remote Control to supervised daemon sessions** — `genies daemon --remote-control` could spawn a Remote Control server, letting the user monitor daemon progress from mobile.

### Monitor

6. **Watch Issue #28827** (OAuth token refresh in `-p` mode) — if fixed, `setup-token` becomes viable for daemon mode with subscription billing.

7. **Watch for API key support in Auto Mode** — this would be the highest-impact change for genie-team's safety model.

### Don't pursue

8. **Don't try to hack OAuth into headless mode.** The `CLAUDE_CODE_OAUTH_TOKEN` path is unsupported (Issue #6536 closed NOT_PLANNED) and the refresh bug makes it unreliable. API key is the right choice for unattended execution.

---

## Next Steps

- **Ready for `/define`** — Shape the hybrid auth model as a backlog item
- The auth wall is understood; the workaround (hybrid model) is practical
- No sub-spikes needed — the evidence is sufficient
