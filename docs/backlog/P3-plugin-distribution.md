---
spec_version: "1.0"
type: shaped-work
id: plugin-distribution
title: "Package Genie Team as a Claude Code Plugin"
status: abandoned
abandoned: "2026-02-13"
abandoned_reason: "Premature — audience of one, Claude Code plugin system is new/unstable, install.sh works. Revisit when there's actual user demand or the plugin system stabilizes."
created: "2026-02-13"
appetite: medium
priority: someday
target_project: genie-team
author: shaper
depends_on: []
tags: [distribution, plugin, installation, adoption]
acceptance_criteria:
  - id: AC-1
    description: "A .claude-plugin/plugin.json manifest exists declaring genie-team's commands, skills, agents, hooks, and MCP servers"
    status: deferred
  - id: AC-2
    description: "A .claude-plugin/marketplace.json exists enabling installation via '/plugin marketplace add' and '/plugin install'"
    status: deferred
  - id: AC-3
    description: "Users can install genie-team with two commands: add marketplace, then install plugin — no shell script execution required"
    status: deferred
  - id: AC-4
    description: "Plugin installation produces the same functional result as 'install.sh global --all' (commands, skills, rules, agents, schemas, hooks, MCP)"
    status: deferred
  - id: AC-5
    description: "install.sh continues to work as an alternative installation path (not removed)"
    status: deferred
  - id: AC-6
    description: "Plugin version matches the VERSION in install.sh and is updated in a single place"
    status: deferred
  - id: AC-7
    description: "Command namespacing impact is documented — whether commands become '/genie-team:discover' vs staying '/discover' and what tradeoffs that creates"
    status: deferred
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

Add a Claude Code plugin manifest (`.claude-plugin/plugin.json` + `marketplace.json`) alongside the existing `install.sh`, giving users a native `/plugin install` path. The plugin covers commands, skills, agents, hooks, and MCP servers. Three component types — rules, schemas, and scripts — have no plugin.json equivalent and remain `install.sh`-only, with a post-install setup command (`/genie:setup`) to bridge the gap.

## Architecture

**Pattern: Dual distribution with shared source.** Both the plugin system and `install.sh` read from the same source directories (`commands/`, `skills/`, `agents/`, etc.). The plugin manifest points to these directories; `install.sh` copies from them. Neither mechanism owns the source — they are parallel distribution channels over the same artifacts.

```
┌────────────────────────────────────────────────────┐
│  Source Artifacts (genie-team repo)                 │
│  commands/  skills/  agents/  hooks/  schemas/      │
│  rules/  scripts/  genies/                          │
└────────────────┬──────────────────┬────────────────┘
                 │                  │
     ┌───────────▼──────┐  ┌───────▼────────────┐
     │  plugin.json      │  │  install.sh         │
     │  (native path)    │  │  (power-user path)  │
     │                   │  │                     │
     │  Commands    ✓    │  │  Commands       ✓   │
     │  Skills      ✓    │  │  Skills         ✓   │
     │  Agents      ✓    │  │  Agents         ✓   │
     │  Hooks       ✓    │  │  Hooks          ✓   │
     │  MCP servers ✓    │  │  MCP servers    ✓   │
     │  Rules       ✗    │  │  Rules          ✓   │
     │  Schemas     ✗    │  │  Schemas        ✓   │
     │  Scripts     ✗    │  │  Scripts        ✓   │
     │  Scaffolding ✗    │  │  Scaffolding    ✓   │
     └──────────────────┘  └─────────────────────┘
```

### Component Mapping

| Component | install.sh target | plugin.json field | Gap? |
|-----------|------------------|-------------------|------|
| Commands (30+ `.md` files) | `.claude/commands/` | `"commands"` | No |
| Skills (8 SKILL.md dirs) | `.claude/skills/` | `"skills"` | No |
| Agents (7 `.md` files) | `.claude/agents/` | `"agents"` | No |
| Hooks (3 `.sh` scripts + settings merge) | `.claude/hooks/` + `settings.json` | `"hooks"` | No |
| MCP (imagegen) | `claude mcp add` | `"mcpServers"` | No |
| Rules (7 `.md` files) | `.claude/rules/` | — | **Yes** — no `rules` field in plugin.json |
| Schemas (7 `.md` files) | `./schemas/` | — | **Yes** — no `schemas` field |
| Scripts (2 `.sh` files) | `./scripts/` | — | **Yes** — no `scripts` field |
| Project scaffolding (`docs/` dirs) | `mkdir -p docs/{backlog,specs,...}` | — | **Yes** — not plugin content |

### Gap Resolution Strategy

Three components have no plugin.json equivalent. Rather than forcing them into the plugin format, the design accepts the gap and provides a clean bridge:

1. **Rules** — Bundled as a `rules/` directory in the plugin repo. After plugin install, users run `/genie:setup` (a command included in the plugin) which copies rules to `.claude/rules/`. This is a one-time setup step.

2. **Schemas** — Referenced by commands and agents via relative paths. Commands already contain the schema content inline (e.g., "Schema: `schemas/shaped-work-contract.schema.md` v1.0"). For plugin users, schemas are available in the plugin's installed directory and can be read by agents. `/genie:setup` copies them to `./schemas/` for projects that want local copies.

3. **Scripts** (`genie-session.sh`, `run-pdlc.sh`) — These are orchestrator utilities (ADR-001), not core plugin functionality. They remain `install.sh`-only. Plugin users who need headless orchestration use `install.sh global --scripts`.

4. **Project scaffolding** — `docs/` directories are project setup, not distribution. `/genie:setup` handles this (or users run `install.sh project` for the full scaffolding).

### Namespacing

Plugin-installed commands are namespaced: `/discover` becomes `/genie-team:discover`. This is a significant UX change.

**Mitigation:** Use a short plugin name. `genie` instead of `genie-team` yields `/genie:discover` — which reads naturally and is only 6 characters longer than `/discover`. The colon already appears in existing commands (`/context:load`, `/brand:image`), so the pattern is familiar.

**Plugin name decision: `genie`** — commands become `/genie:discover`, `/genie:deliver`, `/genie:commit`, etc.

**Exception:** Some commands already use colons: `/context:load` becomes `/genie:context:load` (double-colon). This is awkward but functional. The alternative — flattening to `/genie:context-load` — changes the command name, violating the no-gos.

**Documentation approach:** README and `/genie:help` list both forms:
```
Plugin path:     /genie:discover [topic]
install.sh path: /discover [topic]
```

## Component Design

### 1. Plugin Manifest — `.claude-plugin/plugin.json`

```json
{
  "name": "genie",
  "version": "2.0.0",
  "description": "Structured AI workflows for product discovery and delivery. 7 specialist genies, 30+ commands, TDD enforcement, and architecture governance.",
  "author": {
    "name": "Nolan Patterson",
    "email": "nolan@elmmly.com"
  },
  "repository": "https://github.com/nolan/genie-team",
  "license": "MIT",
  "keywords": ["workflow", "tdd", "architecture", "product-discovery", "genies"],
  "commands": "../.claude/commands/",
  "agents": "../agents/",
  "skills": "../.claude/skills/",
  "hooks": "./hooks.json",
  "mcpServers": "./mcp-config.json"
}
```

**Path convention:** Paths are relative to `.claude-plugin/`. Commands, agents, and skills point back to the existing source directories so there is no duplication.

### 2. Hooks Configuration — `.claude-plugin/hooks.json`

```json
{
  "UserPromptSubmit": [
    {
      "hooks": [
        {
          "type": "command",
          "command": "bash .claude/hooks/track-command.sh"
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
          "command": "bash .claude/hooks/track-artifacts.sh"
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
          "command": "bash .claude/hooks/reinject-context.sh"
        }
      ]
    }
  ]
}
```

### 3. MCP Configuration — `.claude-plugin/mcp-config.json`

```json
{
  "imagegen": {
    "command": "npx",
    "args": ["-y", "@fastmcp-me/imagegen-mcp"],
    "env": {
      "GOOGLE_API_KEY": "${GOOGLE_API_KEY}"
    }
  }
}
```

**Note:** MCP env vars use `${VAR}` syntax for runtime resolution. Users must have `GOOGLE_API_KEY` in their shell environment for image generation to work.

### 4. Marketplace Manifest — `.claude-plugin/marketplace.json`

```json
{
  "name": "genie-team",
  "owner": {
    "name": "Nolan Patterson",
    "email": "nolan@elmmly.com"
  },
  "plugins": [
    {
      "name": "genie",
      "source": ".",
      "description": "Structured AI workflows for product discovery and delivery",
      "version": "2.0.0"
    }
  ]
}
```

The marketplace is the repo itself. Users add it as:
```bash
/plugin marketplace add nolan/genie-team
/plugin install genie@genie-team --scope user
```

Or for local development:
```bash
/plugin marketplace add ./path/to/genie-team
/plugin install genie@genie-team --scope project
```

### 5. Setup Command — `commands/genie-setup.md`

A new command `/genie:setup` (or `/setup` via install.sh) bridges the gap for plugin users:

```markdown
# /genie:setup

Post-installation setup for plugin users. Copies components that the plugin
system cannot distribute natively.

## Behavior

1. Copy rules from plugin source to `.claude/rules/`
2. Copy schemas to `./schemas/`
3. Create project scaffolding directories (`docs/backlog/`, `docs/specs/`, etc.)
4. Report what was set up

## When to Use

After `/plugin install genie@genie-team` — run once per project.
Not needed if installed via `install.sh project` (which handles all of this).
```

### 6. Version Synchronization

Single source of truth: `VERSION` file at repo root.

```
2.0.0
```

Both `install.sh` and `.claude-plugin/plugin.json` read from this file:
- `install.sh`: reads `VERSION` at startup (replace hardcoded `VERSION="2.0.0"`)
- `plugin.json`: a pre-release script (`scripts/sync-version.sh`) updates the version field in both JSON files before tagging a release

**Trade-off:** plugin.json requires a literal version string (not a file reference). The sync script is necessary to keep them aligned. This is acceptable because version bumps happen at release time, not during development.

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Create plugin.json with commands, skills, agents, hooks, mcpServers fields pointing to existing source dirs | `.claude-plugin/plugin.json` |
| AC-2 | Create marketplace.json with repo-as-marketplace pattern | `.claude-plugin/marketplace.json` |
| AC-3 | Two-command install: `/plugin marketplace add` + `/plugin install genie@genie-team` | `.claude-plugin/marketplace.json`, `.claude-plugin/plugin.json` |
| AC-4 | Plugin covers commands, skills, agents, hooks, MCP. Rules, schemas, scaffolding handled by `/genie:setup`. Scripts remain install.sh-only. | `.claude-plugin/*`, `commands/genie-setup.md` |
| AC-5 | install.sh unchanged — no modifications | `install.sh` (no changes) |
| AC-6 | `VERSION` file at repo root; sync script updates JSON files pre-release | `VERSION`, `scripts/sync-version.sh` |
| AC-7 | Plugin name `genie` yields `/genie:discover` etc. Documented in README with both forms. | `README.md`, `commands/genie-help.md` |

## Implementation Guidance

**Sequence:**
1. Create `VERSION` file at repo root with `2.0.0`
2. Create `.claude-plugin/plugin.json` with relative paths to existing source dirs
3. Create `.claude-plugin/hooks.json` (extracted from install.sh's merge_hook_config)
4. Create `.claude-plugin/mcp-config.json` (extracted from install.sh's MCP setup)
5. Create `.claude-plugin/marketplace.json`
6. Create `commands/genie-setup.md` — post-install setup command
7. Create `scripts/sync-version.sh` — version sync utility
8. Update `install.sh` to read version from `VERSION` file instead of hardcoded string
9. Update README with plugin installation instructions alongside install.sh
10. Test: install via plugin system, run `/genie:setup`, verify all components work

**Key considerations:**
- Paths in plugin.json are relative to `.claude-plugin/` — use `../` to reach repo root dirs
- Hook scripts must be copied to `.claude/hooks/` by the plugin loader (verify this works)
- MCP env vars use `${VAR}` syntax — document that GOOGLE_API_KEY must be in the user's environment
- Test namespaced commands thoroughly: `/genie:discover`, `/genie:deliver`, `/genie:context:load`

**Test strategy:**
- Install via plugin on a fresh project → verify commands are available as `/genie:*`
- Run `/genie:setup` → verify rules, schemas, and docs/ directories are created
- Run `/genie:discover test-topic` → verify full workflow functions
- Run `install.sh global` on same system → verify no conflicts
- Verify MCP imagegen works through plugin-installed config

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Plugin system changes in future Claude Code versions | Med | Med | Plugin manifest is simple JSON; `install.sh` remains as fallback |
| Namespacing confuses existing users | Med | Low | Document both forms; existing install.sh users unaffected |
| Hook scripts not found at expected paths after plugin install | Low | High | Test hook execution path; hooks.json uses paths relative to plugin install location |
| Version drift between plugin.json and install.sh | Low | Med | sync-version.sh + CI check that versions match |
| MCP env vars not resolved in plugin context | Low | High | Test MCP config with `${VAR}` syntax; document env setup requirement |

## Routing

Ready for Crafter. All changes are new file creation (plugin manifests, setup command, version sync) with one small modification (install.sh reads VERSION file). No architectural unknowns.
