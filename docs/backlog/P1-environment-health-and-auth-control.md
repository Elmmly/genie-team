---
spec_version: "1.0"
type: shaped-work
id: P1-environment-health-and-auth-control
title: "Environment Health, Auth Control, and Model Tier Routing"
status: abandoned
superseded_by: docs/backlog/P0-typescript-sdk-migration.md
created: 2026-03-12
appetite: big
priority: P1
author: shaper
spec_ref: docs/specs/platform/environment-health.md
discovery_ref: null
spike_ref: null
acceptance_criteria:
  - id: AC-1
    description: >-
      install.sh runs a post-install health check that reports: Claude CLI
      presence and version, auth method (OAuth vs API key) with billing mode
      label (capped vs uncapped), GitHub CLI auth status, MCP server status,
      and install completeness. Warns when ANTHROPIC_API_KEY is set alongside
      an active OAuth session (billing ambiguity).
    status: pending
  - id: AC-2
    description: >-
      `genies check` subcommand checks all runtime prerequisites: Claude CLI,
      auth method and billing mode, gh auth, MCP servers, global/project install
      status, git repo state, and genie-config.yaml validity. Reports each check
      as OK/WARN/FAIL with actionable fix guidance. Exit code 0 when all pass,
      1 when any fail.
    status: pending
  - id: AC-3
    description: >-
      `genies` script preflight (run/daemon/session modes) detects auth method
      and reports billing mode before spawning claude processes. `--auth oauth`
      flag unsets ANTHROPIC_API_KEY in child environment to force OAuth billing.
      `--auth apikey` flag requires ANTHROPIC_API_KEY is set. Default behavior
      detects and warns but does not change the environment.
    status: pending
  - id: AC-4
    description: >-
      `genie-config.yaml` supports model tier definitions (reasoning, default,
      fast) mapped to Claude model IDs, and per-genie tier assignments with
      sensible defaults (Scout/Architect→reasoning, Crafter/Tidier→default,
      Critic→fast). Config file searched at project (.claude/genie-config.yaml)
      then global (~/.claude/genie-config.yaml) with project taking precedence.
    status: pending
  - id: AC-5
    description: >-
      `genies` script reads genie-config.yaml and passes --model flag to
      claude -p invocations per phase based on the genie-to-tier mapping.
      Falls back to no --model flag (Claude Code default) when config is
      absent or tier is unset.
    status: pending
  - id: AC-6
    description: >-
      `genies models` subcommand displays current model tier configuration:
      tier names with model IDs, per-genie assignments, config file location
      (project vs global vs default), and estimated relative cost per tier.
    status: pending
  - id: AC-7
    description: >-
      install.sh --all generates a default genie-config.yaml (if not present)
      with commented sensible defaults explaining each tier and genie mapping.
      --force regenerates the config. Existing config is never overwritten
      without --force.
    status: pending
---

# Shaped Work Contract: Environment Health, Auth Control, and Model Tier Routing

## Problem

Genie-team's installation and runtime experience provides no visibility into authentication method, billing mode, or model selection. Users can unknowingly run headless genie sessions on uncapped API billing when they expect their capped Max subscription to apply — discovered firsthand when `ANTHROPIC_API_KEY` in a shell profile silently overrides the OAuth token. When something breaks, there's no diagnostic command to identify the problem. And all genies use the same model regardless of task complexity, missing obvious cost optimization opportunities (Critic doesn't need Opus).

**Who's affected:** Every genie-team user. Cost impact scales with batch/daemon usage — the more autonomous execution, the higher the risk of silent billing surprises.

**Evidence:**
- OAuth spike confirmed API key takes precedence over OAuth token (strong)
- Health check subcommand is a common pattern in CLI ecosystems for troubleshooting (moderate)
- Opus costs ~10x Haiku; routing Critic to Haiku could save 30-50% on review phases (moderate)
- User discovered the billing ambiguity firsthand during this project (strong — direct experience)

## Appetite & Boundaries

- **Appetite:** Big batch (1-2 weeks)
- **No-gos:**
  - No onboarding wizard — post-install validation is sufficient for Claude Code-native tools
  - No multi-provider support — single provider by design
  - No gateway proxy implementation — document patterns only (per spike findings)
  - No interactive prompts during install — health check is informational output, not a blocker
  - No changes to Claude Code itself — work within existing CLI flags and env vars
- **Fixed elements:**
  - `install.sh` remains the installation entry point
  - `scripts/genies` remains the orchestration entry point
  - YAML config format (not JSON5 — avoids known config-placement errors with JSON5)
  - Existing `install.sh status` behavior preserved
  - Existing preflight checks in `genies` preserved and extended

## Goals & Outcomes

1. **Setup confidence:** Users know their environment is correctly configured and which billing path their genies will use — before running expensive batch operations
2. **Billing control:** Users can explicitly choose OAuth (capped) or API key (uncapped) billing for headless execution
3. **Cost optimization:** Model tier routing reduces costs by matching model capability to task complexity
4. **Self-service diagnostics:** `genies check` identifies and explains problems without requiring support

## Behavioral Delta

**Spec:** docs/specs/platform/installation-system.md

### Current Behavior
- AC-1: install.sh supports multi-mode installation with component flags (no health check output)
- AC-4: --sync, --force, --dry-run, --skip-mcp modifiers (no config generation)

### Proposed Changes
- AC-1: Post-install output now includes a health check section reporting auth/billing/MCP/install status
- AC-4: --all now generates default genie-config.yaml (if not present); --force regenerates it
- AC-NEW (5 new ACs): Environment health, auth control, model tier config — captured in new spec `docs/specs/platform/environment-health.md`

### Rationale
The installation system spec covers file distribution. Environment health is a new capability covering runtime validation, auth control, and model configuration — capabilities that didn't exist before. Extending the install spec with a health check output (AC-1 delta) is the natural seam; the rest belongs in a new spec.

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| `claude -p` uses OAuth token when ANTHROPIC_API_KEY is unset | Feasibility | Run `unset ANTHROPIC_API_KEY && claude -p "echo test"` and verify billing path (hours) |
| Max plan rate limits handle batch load gracefully | Feasibility | Run 3 parallel genie sessions on OAuth and monitor for throttling (days) |
| `claude auth status` or env inspection can reliably detect auth method | Feasibility | Test detection logic against OAuth-only, API-key-only, and dual-configured environments (hours) |
| Model tier routing via --model flag works per-invocation | Feasibility | Spawn `claude -p --model claude-haiku-4-5` and verify model used (hours) |
| YAML config is simpler to maintain than JSON5 | Usability | User testing during delivery — config should be self-documenting with comments |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: All-in-one delivery (health check + check + auth + model tiers) | Single coherent delivery; config file serves all features; test infrastructure shared | Larger scope; model tier routing is independent of auth control | **Recommended** — user chose full scope; features share config file and diagnostic infrastructure |
| B: Split into two items (diagnostics vs model config) | Smaller batches; faster first delivery | Config file designed twice; check command incomplete without model checks; two PR cycles | Viable fallback if scope proves too large during delivery |
| C: Health check only, defer everything else | Smallest possible delivery | Misses the core billing control problem that motivated the discovery | Not recommended — solves symptoms, not cause |

## Dependencies

- **Minor:** `claude auth status` output format — undocumented, may change between Claude Code versions. Mitigation: detect via env var (`ANTHROPIC_API_KEY` presence) as primary signal, CLI output as secondary.
- **Minor:** `--model` flag behavior for `claude -p` — documented but not heavily tested with all model IDs. Mitigation: validate during delivery with actual invocations.
- **None:** No blocking dependencies on other backlog items or external teams.

## Rabbit Holes

- **Don't build auth token refresh logic** — `apiKeyHelper` handles this; genie-team just needs to not interfere
- **Don't parse Claude Code internals** — Use env vars and CLI flags, not keychain inspection or config file parsing
- **Don't make health check a gate** — Informational output only; install should always succeed even if Claude Code isn't configured yet
- **Don't build cost tracking** — Model tiers optimize cost; actual spend tracking is Anthropic Console's job
- **Don't support arbitrary model IDs in tiers** — Use tier names (reasoning/default/fast) mapped to model IDs; this abstracts away model version churn

## Routing

**Next:** `/handoff define design` — Architect should design the config file format, check check sequence, and auth detection logic before Crafter implements.

**After delivery:** `/discern` to verify all ACs, then revisit the broader enterprise discovery with real-world feedback from this work.
