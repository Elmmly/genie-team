---
spec_version: "1.0"
type: spec
id: environment-health
title: Environment Health
status: active
created: 2026-03-12
domain: platform
source: define
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

# Environment Health

Runtime environment validation, authentication control, and model tier configuration for genie-team. Provides visibility into auth method and billing mode, diagnostic tooling for troubleshooting, explicit auth mode control for headless execution, and per-genie model routing for cost optimization.

This capability extends the installation system with post-install health checks and adds new `genies check` and `genies models` subcommands to the orchestration script. It introduces `genie-config.yaml` as the user-facing configuration file for model tier assignments.

## Acceptance Criteria

### AC-1: Post-install health check
After `install.sh` completes file installation, it runs a health check that reports Claude CLI presence/version, auth method (OAuth vs API key) with billing mode label, GitHub CLI auth status, MCP server status, and install completeness. When `ANTHROPIC_API_KEY` is set alongside an active OAuth session, it warns about billing ambiguity with guidance to unset the API key if Max subscription billing is intended.

### AC-2: `genies check` diagnostic command
The `genies check` subcommand checks all runtime prerequisites and reports each as OK/WARN/FAIL with actionable fix guidance. Checks include: Claude CLI availability, auth method detection, billing mode, `gh` auth status, MCP server status, global and project installation completeness, git repository state, and `genie-config.yaml` validity. Exit code 0 when all checks pass, 1 when any check fails.

### AC-3: Auth mode control for headless execution
The `genies` script preflight (for run, daemon, and session modes) detects the auth method and reports the billing mode before spawning Claude processes. The `--auth oauth` flag unsets `ANTHROPIC_API_KEY` in the child process environment to force OAuth/subscription billing. The `--auth apikey` flag requires `ANTHROPIC_API_KEY` to be set and fails if it's missing. Default behavior (no flag) detects and warns but does not modify the environment.

### AC-4: Model tier configuration file
`genie-config.yaml` defines model tiers (`reasoning`, `default`, `fast`) mapped to Claude model IDs, and per-genie tier assignments. Sensible defaults: Scout and Architect use `reasoning` (Opus), Crafter and Tidier use `default` (Sonnet), Critic uses `fast` (Haiku). The config file is searched at project scope (`.claude/genie-config.yaml`) then global scope (`~/.claude/genie-config.yaml`), with project config taking precedence.

### AC-5: Model routing in genies script
The `genies` script reads `genie-config.yaml` and passes the `--model` flag to `claude -p` invocations based on the genie-to-tier mapping for each phase. When config is absent or a tier is unset for a particular genie, it falls back to no `--model` flag (Claude Code's default model selection).

### AC-6: `genies models` subcommand
The `genies models` subcommand displays the current model tier configuration: tier names with their mapped model IDs, per-genie tier assignments, the config file location being used (project vs global vs built-in defaults), and estimated relative cost indicators per tier.

### AC-7: Default config generation during install
`install.sh --all` generates a default `genie-config.yaml` at the appropriate scope (global or project, matching the install mode) if one does not already exist. The generated file includes commented sensible defaults explaining each tier's purpose and the rationale for each genie's tier assignment. `--force` regenerates the config file. Existing config is never overwritten without `--force`.

## Evidence

### Discovery
- OAuth/API key billing path analysis (discovery session 2026-03-12)

### Related Specs
- `docs/specs/platform/installation-system.md` — Existing install system this extends
- `docs/specs/workflow/autonomous-lifecycle.md` — Headless execution modes affected by auth control
