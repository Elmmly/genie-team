---
type: test-plan
topic: multi-provider-execution
created: "2026-04-02"
---

# Multi-Provider Test Plan

## Prerequisites

| Provider | Requirement | Env var |
|----------|------------|---------|
| Claude | Claude Code installed, Anthropic account (OAuth or API key) | `ANTHROPIC_API_KEY` (optional if using OAuth) |
| OpenAI | OpenAI account with API access | `OPENAI_API_KEY` |
| Google | Google AI Studio account | `GEMINI_API_KEY` (when implemented) |

## Test Matrix

### 1. Smoke tests (no API call)

```bash
# Claude (default)
genies-core --version
genies-core check
genies-core models
genies-core session list

# Provider flag parsing
genies-core run --provider openai --model gpt-4o "test"    # should fail: no OPENAI_API_KEY
genies-core run --provider google --model gemini-2.0-flash "test"  # should fail: unknown provider (until Google impl added)
genies-core run --provider bogus "test"                      # should fail: unknown provider
```

### 2. Claude (Tier 1) — live execution

```bash
# Single phase, budget-capped
genies-core run --auth oauth --from discover --through discover \
  --budget 0.50 --skip-permissions --verbose \
  "what patterns exist in this repo?"

# Full lifecycle
genies-core run --auth oauth --skip-permissions --budget 10.00 --verbose \
  "build hangman with a twist"

# Verify: cost > 0, turns > 0, output contains meaningful text
# Verify: --verbose shows tool use (Read, Write, Bash, etc.)
# Verify: --log-dir produces JSONL cost entries
```

### 3. OpenAI (Tier 2) — live execution

```bash
# Requires: export OPENAI_API_KEY=sk-...

# Single phase, budget-capped
genies-core run --provider openai --model gpt-4o \
  --from discover --through discover \
  --budget 0.50 --skip-permissions --verbose \
  "what patterns exist in this repo?"

# Full lifecycle
genies-core run --provider openai --model gpt-4o \
  --skip-permissions --budget 10.00 --verbose \
  "build a simple TODO app"

# Verify: tool calls appear (Read, Write, Bash via LocalToolExecutor)
# Verify: --verbose shows tool names and inputs
# Verify: turns and token usage are tracked
# Note: cost tracking is token-based (Tier 2 doesn't get cost from SDK)
```

### 4. Google (Tier 2) — live execution (when implemented)

```bash
# Requires: export GEMINI_API_KEY=...

genies-core run --provider google --model gemini-2.0-flash \
  --from discover --through discover \
  --budget 0.50 --skip-permissions --verbose \
  "what patterns exist in this repo?"
```

### 5. Provider comparison test

Run the same prompt through all providers and compare output quality:

```bash
PROMPT="discover what testing patterns exist in this repo"

genies-core run --from discover --through discover \
  --skip-permissions --budget 1.00 --verbose \
  --log-dir /tmp/compare/claude "$PROMPT"

genies-core run --provider openai --model gpt-4o \
  --from discover --through discover \
  --skip-permissions --budget 1.00 --verbose \
  --log-dir /tmp/compare/openai "$PROMPT"

# Compare: /tmp/compare/claude/run-pdlc.jsonl vs /tmp/compare/openai/run-pdlc.jsonl
# Compare: output quality, tool usage, turn count, cost
```

### 6. Known limitations of Tier 2 (OpenAI/Google) vs Tier 1 (Claude)

| Feature | Claude (Tier 1) | OpenAI/Google (Tier 2) |
|---------|----------------|----------------------|
| Tool use | SDK built-in tools | LocalToolExecutor |
| Session resume | Supported (--resume) | Not supported |
| MCP servers | Supported | Not supported |
| Subagents | Supported | Not supported |
| Permission system | SDK permissions | Not implemented |
| Cost tracking | SDK provides total_cost_usd | Token count only (no cost) |
| CLAUDE.md loading | Via settingSources | Read and prepend to system prompt (TODO) |
| Hooks (PostToolUse) | SDK hooks | Inline in agent loop |
| Sandbox | SDK sandbox | Not implemented |
