---
spec_version: "1.0"
type: shaped-work
id: plugin-distribution
title: "Package Genie Team as a Claude Code Plugin"
status: designed
created: "2026-02-13"
appetite: medium
priority: P3
target_project: genie-team
author: shaper
depends_on: []
tags: [distribution, plugin, installation, adoption]
acceptance_criteria:
  - id: AC-1
    description: "A .claude-plugin/plugin.json manifest exists declaring genie-team's commands, skills, agents, hooks, and MCP servers"
    status: pending
  - id: AC-2
    description: "A .claude-plugin/marketplace.json exists enabling installation via '/plugin marketplace add' and '/plugin install'"
    status: pending
  - id: AC-3
    description: "Users can install genie-team with two commands: add marketplace, then install plugin — no shell script execution required"
    status: pending
  - id: AC-4
    description: "Plugin installation produces the same functional result as 'install.sh global --all' (commands, skills, rules, agents, schemas, hooks, MCP)"
    status: pending
  - id: AC-5
    description: "install.sh continues to work as an alternative installation path (not removed)"
    status: pending
  - id: AC-6
    description: "Plugin version matches the VERSION in install.sh and is updated in a single place"
    status: pending
  - id: AC-7
    description: "Command namespacing impact is documented — whether commands become '/genie-team:discover' vs staying '/discover' and what tradeoffs that creates"
    status: pending
---

# Shaped Work Contract: Package Genie Team as a Claude Code Plugin

## Problem

Genie-team distributes via `install.sh` — a shell script that copies commands, skills, rules,
agents, schemas, hooks, and MCP servers to `~/.claude/` or a project `.claude/` directory. This
works but creates friction at three points:

1. **Installation requires running a shell script.** Users must clone the repo, trust the script,
   and run `install.sh global` or `install.sh project`. This is a higher barrier than
   `/plugin install`, which is Claude Code's native extension mechanism.

2. **Updates are manual.** When genie-team evolves (new skills, updated commands, schema changes),
   users must re-run `install.sh --sync --force`. There is no notification that an update is
   available, no version comparison, and no changelog surfacing. Users on stale versions don't
   know they're stale.

3. **No discoverability.** Users can't browse available extensions and find genie-team through
   Claude Code's plugin system. Adoption depends entirely on finding the git repo through external
   channels.

**Evidence:** `install.sh` is a 1,070-line script handling 8 component types, 3 installation
scopes, worktree detection, MCP configuration, and pre-commit hook setup. Claude Code's plugin
system handles installation scope, component discovery, versioning, and updates natively —
eliminating most of this machinery.

**Who's affected:** New users evaluating genie-team, existing users maintaining their installation,
and the project maintainer managing the distribution pipeline.

## Appetite & Boundaries

- **Appetite:** Medium (3-5 days)
- **No-gos:**
  - Do NOT remove `install.sh` — it remains as an alternative for users who prefer it or need
    customization (e.g., `--skip-mcp`, `--commands` only, `prehook`)
  - Do NOT change command names or skill behavior — packaging only
  - Do NOT auto-publish to any marketplace without explicit user action
  - Do NOT address the `docs/` directory structure (that's project scaffolding, not plugin content)
- **Fixed elements:**
  - Plugin must include all components that `install.sh --all` installs
  - Plugin version must stay in sync with `install.sh` VERSION
  - MCP server configuration must be included (imagegen for Designer genie)

## Goals & Outcomes

- Users can install genie-team through Claude Code's native plugin system
- Updates are surfaced automatically when the marketplace is refreshed
- `install.sh` remains for power users, customization, and project-level scaffolding (`docs/` directories)

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Claude Code's plugin system is stable enough for production use | feasibility | Install an existing plugin from the official marketplace; verify the workflow |
| Plugin namespacing doesn't break existing user workflows | usability | Test whether `/discover` becomes `/genie-team:discover` and assess UX impact |
| Plugin format can express all genie-team components (commands, skills, agents, hooks, MCP, schemas) | feasibility | Map each install.sh component to a plugin.json field; identify any gaps |
| Users prefer `/plugin install` over `install.sh` | value | The plugin system is Claude Code's standard; shell scripts are non-standard |

## Solution Sketch

1. Create `.claude-plugin/plugin.json` manifest mapping genie-team components to plugin fields
2. Create `.claude-plugin/marketplace.json` for distribution
3. Verify all components are discovered and loaded correctly via plugin installation
4. Document the namespacing behavior (if commands get prefixed, users need to know)
5. Update README with plugin installation as the primary path, `install.sh` as alternative

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Add plugin manifest alongside install.sh | Both paths work; gradual migration | Two distribution mechanisms to maintain | **Recommended** |
| B: Replace install.sh with plugin-only distribution | Simpler; single path | Loses customization (selective install, prehook, scaffolding) | Not recommended — install.sh does things plugins can't |
| C: Defer until plugin ecosystem matures | No effort now | Continues friction; misses early adoption window | Not recommended unless plugin system is unstable |

## Open Questions

- **Namespacing:** Does plugin installation prefix commands? If `/discover` becomes `/genie-team:discover`, that's a significant UX change that needs evaluation.
- **Schemas directory:** `install.sh` copies schemas to the project root (`./schemas/`). Can plugin.json express this, or do schemas need a different distribution path?
- **Project scaffolding:** `install.sh project` creates `docs/backlog/`, `docs/specs/`, etc. This is project setup, not plugin content. Should it stay in `install.sh` only?

## Routing

- [ ] **Needs spike** — Verify plugin.json can express all genie-team components; test namespacing behavior
- [x] **Ready for design after spike** — No architectural unknowns beyond the spike questions

**Next:** `/deliver docs/backlog/P3-plugin-distribution.md`

---

# Design

## Overview

Make genie-team installable as a Claude Code plugin for a 2-person team (you + one collaborator) before broader distribution. The repo root IS the plugin — the existing directory structure (`commands/`, `agents/`, `skills/`) already matches the plugin layout exactly. Add 4 files: `plugin.json`, `marketplace.json`, `hooks/hooks.json`, `.mcp.json`. Rules and schemas remain `install.sh`-only for now; the second developer runs `install.sh global --rules --schemas` alongside the plugin install.

**Phase 1 (this item):** Validate the plugin experience with 2 people.
**Phase 2 (future, separate item):** Broader distribution — version sync, README, `/genie:setup` command, cache optimization.

## Architecture

**The repo root IS the plugin.** Claude Code's plugin system expects `commands/`, `agents/`, `skills/`, `hooks/` at the plugin root — which is exactly how genie-team is already structured. No restructuring needed.

**Critical constraint:** When a plugin is installed, Claude Code copies the entire plugin directory to a cache. This means:
- No `../` paths — everything must be self-contained within the repo
- Hook scripts must use `${CLAUDE_PLUGIN_ROOT}` to reference files in the cached location
- The entire repo (including `docs/`, `tests/`, etc.) gets cached — acceptable for 2 people, optimize in Phase 2

```
genie-team/                    ← this IS the plugin root
├── .claude-plugin/
│   ├── plugin.json            ← NEW (manifest)
│   └── marketplace.json       ← NEW (catalog for /plugin marketplace add)
├── commands/                  ← EXISTS (29 .md files → plugin commands)
├── agents/                    ← EXISTS (7 .md files → plugin agents)
├── skills/                    ← EXISTS (9 dirs with SKILL.md → plugin skills)
├── hooks/
│   ├── hooks.json             ← NEW (plugin hook configuration)
│   ├── track-command.sh       ← EXISTS
│   ├── track-artifacts.sh     ← EXISTS
│   └── reinject-context.sh    ← EXISTS
├── .mcp.json                  ← NEW (MCP server configuration)
├── rules/                     ← EXISTS (no plugin field — install.sh only)
├── schemas/                   ← EXISTS (no plugin field — install.sh only)
├── install.sh                 ← EXISTS (alternative/complement path)
└── ...
```

### Component Coverage

| Component | Plugin handles? | Notes |
|-----------|:-:|-------|
| Commands (29 `.md` files) | Yes | Namespaced as `/genie:command` |
| Skills (9 SKILL.md dirs) | Yes | Auto-activated by Claude |
| Agents (7 `.md` files) | Yes | Available via Task tool |
| Hooks (3 `.sh` scripts) | Yes | Via `hooks/hooks.json` + `${CLAUDE_PLUGIN_ROOT}` |
| MCP (imagegen) | Yes | Via `.mcp.json` at root |
| Rules (7 `.md` files) | **No** | No plugin field — `install.sh global --rules` |
| Schemas (7 `.md` files) | **No** | No plugin field — `install.sh global --schemas` |
| Scripts (`run-pdlc.sh`, etc.) | **No** | Orchestrator utilities — `install.sh global --scripts` |
| Project scaffolding (`docs/` dirs) | **No** | `install.sh project` |

**Gap resolution for Phase 1:** The second developer runs:
```bash
# Plugin install (commands, agents, skills, hooks, MCP)
/plugin marketplace add nolan/genie-team
/plugin install genie@genie-team --scope user

# Gap fill (rules, schemas)
git clone git@github.com:nolan/genie-team.git ~/genie-team
cd ~/genie-team && ./install.sh global --rules --schemas
```

This is pragmatic for 2 people. Phase 2 adds a `/genie:setup` command to eliminate the gap-fill step.

### Namespacing

Plugin name: **`genie`**. All commands become `/genie:command`:

| install.sh path | Plugin path |
|----------------|-------------|
| `/discover` | `/genie:discover` |
| `/deliver` | `/genie:deliver` |
| `/commit` | `/genie:commit` |
| `/context:load` | `/genie:context:load` |
| `/brand:image` | `/genie:brand:image` |

The colon pattern is already familiar from existing sub-commands (`/context:load`, `/brand:image`). Double-colons (`/genie:context:load`) are awkward but functional.

## Component Design

### 1. Plugin Manifest — `.claude-plugin/plugin.json`

```json
{
  "name": "genie",
  "version": "2.0.0",
  "description": "Structured AI workflows for product discovery and delivery. 7 specialist genies, 30+ commands, TDD enforcement, and architecture governance.",
  "author": {
    "name": "Nolan Patterson"
  },
  "repository": "https://github.com/nolan/genie-team",
  "license": "MIT",
  "keywords": ["workflow", "tdd", "architecture", "product-discovery", "genies"]
}
```

No explicit `commands`, `agents`, `skills` fields needed — the plugin system auto-discovers directories at the plugin root when they follow the default naming convention.

### 2. Marketplace Manifest — `.claude-plugin/marketplace.json`

```json
{
  "name": "genie-team",
  "metadata": {
    "description": "Specialist AI genies for product discovery and delivery workflows"
  },
  "owner": {
    "name": "Nolan Patterson"
  },
  "plugins": [
    {
      "name": "genie",
      "source": "./",
      "description": "Structured AI workflows for product discovery and delivery"
    }
  ]
}
```

Self-contained marketplace: the repo is both the marketplace and the single plugin. Install commands:

```bash
# From GitHub (second developer)
/plugin marketplace add nolan/genie-team
/plugin install genie@genie-team --scope user

# Local development (you)
/plugin marketplace add ./path/to/genie-team
/plugin install genie@genie-team --scope user
```

### 3. Hooks Configuration — `hooks/hooks.json`

```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-command.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/track-artifacts.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact|clear",
        "hooks": [
          {
            "type": "command",
            "command": "bash ${CLAUDE_PLUGIN_ROOT}/hooks/reinject-context.sh"
          }
        ]
      }
    ]
  }
}
```

Key: `${CLAUDE_PLUGIN_ROOT}` resolves to the plugin's cached install location, ensuring hook scripts are found after caching.

### 4. MCP Configuration — `.mcp.json`

```json
{
  "mcpServers": {
    "imagegen": {
      "command": "npx",
      "args": ["-y", "@fastmcp-me/imagegen-mcp"],
      "env": {
        "GOOGLE_API_KEY": "${GOOGLE_API_KEY}"
      }
    }
  }
}
```

Second developer needs `GOOGLE_API_KEY` in their shell environment for image generation (Designer genie). Not required for core workflow.

## AC Mapping

| AC | Phase 1 approach | Files |
|----|-----------------|-------|
| AC-1 | Create plugin.json — plugin system auto-discovers commands/, agents/, skills/ at root | `.claude-plugin/plugin.json` |
| AC-2 | Create marketplace.json with self-contained repo-as-marketplace pattern | `.claude-plugin/marketplace.json` |
| AC-3 | Two-command install: `/plugin marketplace add nolan/genie-team` + `/plugin install genie@genie-team` | Both manifests |
| AC-4 | Plugin covers commands, skills, agents, hooks, MCP. Rules + schemas via `install.sh global --rules --schemas` | `.claude-plugin/*`, `hooks/hooks.json`, `.mcp.json` |
| AC-5 | install.sh unchanged — no modifications | No changes needed |
| AC-6 | **Deferred to Phase 2.** Version is hardcoded in both plugin.json and install.sh. Manual sync for 2 people. | — |
| AC-7 | Namespacing tested empirically during Phase 1. Plugin name `genie` → `/genie:discover` etc. | `.claude-plugin/plugin.json` |

## Implementation Guidance

**Sequence:**
1. Create `.claude-plugin/plugin.json` (manifest)
2. Create `.claude-plugin/marketplace.json` (catalog)
3. Create `hooks/hooks.json` (hook config with `${CLAUDE_PLUGIN_ROOT}`)
4. Create `.mcp.json` at repo root (MCP server config)
5. Test locally: `claude --plugin-dir .` — verify commands, skills, agents load
6. Test marketplace flow: `/plugin marketplace add .` → `/plugin install genie@genie-team`
7. Validate: `/plugin validate .` — check for structural errors
8. Push to GitHub; second developer tests from remote

**Test checklist for Phase 1 validation:**
- [ ] `claude --plugin-dir .` loads without errors
- [ ] `/genie:discover test-topic` invokes Scout
- [ ] `/genie:deliver` invokes Crafter
- [ ] `/genie:commit` creates conventional commit
- [ ] `/genie:context:load` works (double-colon)
- [ ] Hooks fire: `track-command.sh` on prompt submit, `track-artifacts.sh` on Write
- [ ] Second developer installs from GitHub marketplace
- [ ] Second developer can run `/genie:discover` successfully
- [ ] install.sh still works alongside plugin (no conflicts)

**What to learn from Phase 1:**
- Does the plugin cache include too much (docs/, tests/)? If so, Phase 2 needs `.claudeignore` or directory restructuring
- Do hooks using `${CLAUDE_PLUGIN_ROOT}` work reliably?
- Is the gap-fill step (`install.sh --rules --schemas`) acceptable friction, or does Phase 2 need a `/genie:setup` command?
- Are double-colon commands (`/genie:context:load`) confusing enough to warrant renaming?

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Hook scripts not found via `${CLAUDE_PLUGIN_ROOT}` after caching | Med | High | Test during Phase 1 before second developer onboarding |
| Plugin cache bloat (entire repo including docs/tests) | Low | Low | Acceptable for 2 people; optimize in Phase 2 if needed |
| MCP env vars not resolved in plugin context | Low | High | Test `.mcp.json` with `${GOOGLE_API_KEY}` syntax; document env setup |
| Double-colon commands confuse users | Low | Low | Monitor in Phase 1; consider command renaming in Phase 2 if problematic |
| install.sh and plugin coexist with conflicts | Low | Med | Test both on same machine; plugin uses cache, install.sh uses `.claude/` |

## Phase 2 Roadmap (future, separate backlog item)

When Phase 1 validates the plugin experience:
- **Version sync**: `VERSION` file + `scripts/sync-version.sh`
- **`/genie:setup` command**: Eliminate the gap-fill step for rules/schemas/scaffolding
- **README update**: Plugin as primary install path, install.sh as alternative
- **Cache optimization**: `.claudeignore` or directory restructuring to exclude docs/tests
- **Team auto-install**: `.claude/settings.json` with `extraKnownMarketplaces` for target projects

## Routing

Ready for Crafter. 4 new files to create, no modifications to existing files. Test-first: `claude --plugin-dir .` validates the structure before committing.
