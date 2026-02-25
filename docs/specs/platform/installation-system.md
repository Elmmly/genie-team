---
spec_version: "1.0"
type: spec
id: installation-system
title: Installation System
status: active
created: 2026-02-25
domain: platform
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      install.sh supports global (~/.claude/), project (/path/.claude/), prehook (standalone
      pre-commit hooks), status (show installation state), and uninstall modes with
      component-level flags (--commands, --skills, --agents, --rules, --hooks, --schemas,
      --scripts, --mcp, --all)
    status: met
  - id: AC-2
    description: >-
      Worktree detection via git rev-parse comparison adjusts MCP scope from local to user
      (shared across sessions) and creates agent-memory symlinks to main worktree for
      shared genie learning
    status: met
  - id: AC-3
    description: >-
      MCP image generation server (imagegen) installed via claude mcp add with correct
      env var passing (-e GOOGLE_API_KEY=value flag before server name) and scope handling
      (-s user for worktrees, -s project otherwise)
    status: met
  - id: AC-4
    description: >-
      --sync removes obsolete files in target directories before copying (clean install);
      --force overwrites existing files; --dry-run previews all changes without writing;
      --skip-mcp skips MCP server installation
    status: met
---

# Installation System

The `install.sh` script provides multi-mode installation of genie-team artifacts into Claude Code's `.claude/` directory structure. It copies commands, agents, skills, rules, hooks, schemas, and scripts from the canonical source (repo root) to target directories (global `~/.claude/` or project `.claude/`). The installer handles worktree detection, MCP server setup, pre-commit hook installation, and component-level selective installation.

The installer is the primary distribution mechanism for genie-team. It's designed to be re-runnable (idempotent with --force), support incremental adoption (component-level flags), and detect worktree contexts automatically.

## Acceptance Criteria

### AC-1: Multi-mode installation with component flags
Five modes: `global` (install to `~/.claude/` for all projects), `project [path]` (install to specific project `.claude/`), `prehook [path]` (standalone pre-commit hooks, non-destructive), `status` (show what's installed where), `uninstall` (remove installation). Component flags: `--commands`, `--skills`, `--agents`, `--rules`, `--hooks`, `--schemas`, `--scripts`, `--mcp`, `--all` (default). Scripts install `genies` CLI entry point to PATH with supporting files alongside.

### AC-2: Worktree-aware installation
The installer auto-detects git worktree context by comparing `git rev-parse --git-dir` with `--git-common-dir`. In a worktree: MCP scope switches from `local`/`project` to `user` (shared across sessions since worktrees don't share `.claude/` config), and agent-memory symlinks are created pointing to the main worktree's memory directory for shared genie learning.

### AC-3: MCP image generation server setup
The `imagegen` MCP server (`@fastmcp-me/imagegen-mcp`) is installed via `claude mcp add` with `GOOGLE_API_KEY` passed via the `-e` short flag (not `--env`). Flag order matters: `-s scope -e KEY=val` must come before the server name. The installer checks for existing MCP configuration before adding to avoid duplicates.

### AC-4: Install modifiers
`--sync` performs a clean install by removing target directories before copying, ensuring obsolete files from previous versions are removed. `--force` overwrites existing files without prompting. `--dry-run` previews all changes without writing anything. `--skip-mcp` skips MCP server installation (useful in environments without API keys).

## Evidence

### Source Code
- `install.sh`: Full installer (~1200 lines) with multi-mode support, worktree detection, MCP setup
- `templates/CLAUDE.md`: Project CLAUDE.md template installed to target projects

### Tests
- `tests/test_execute.sh`: 62 tests including install verification, component detection, and status checking
- `tests/test_worktree.sh`: 19 tests covering worktree detection, MCP scope, and memory symlinks
