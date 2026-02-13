---
spec_version: "1.0"
type: shaped-work
id: workshop-source-sync
title: "Sync Workshop Modes to Source Commands"
status: shaped
created: 2026-02-12
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
builds_on: []
spec_ref: ""
tags: [workshop, commands, sync, install, maintenance]
acceptance_criteria:
  - id: AC-1
    description: "commands/define.md includes the --workshop mode content currently only in .claude/commands/define.md"
    status: pending
  - id: AC-2
    description: "commands/design.md includes the --workshop mode content currently only in .claude/commands/design.md"
    status: pending
  - id: AC-3
    description: "install.sh --force correctly copies the workshop-enabled source commands to target .claude/commands/"
    status: pending
  - id: AC-4
    description: "The brand workshop content in commands/ and .claude/commands/ is consistent (brand.md exists in commands/ source)"
    status: pending
---

# Sync Workshop Modes to Source Commands

## Problem/Opportunity Statement

The workshop modes for `/define --workshop` and `/design --workshop` were added directly to the installed `.claude/commands/` copies but not back-ported to the source `commands/` directory. This means `install.sh --force` or `install.sh --sync` would overwrite the workshop-enabled versions with the workshop-less source versions. The `brand.md` command with its workshop mode also only exists in `.claude/commands/`, not in the source `commands/` directory.

## Evidence

- `commands/define.md`: 228 lines (no workshop mode)
- `.claude/commands/define.md`: 352 lines (has workshop mode)
- `commands/design.md`: 248 lines (no workshop mode)
- `.claude/commands/design.md`: 380 lines (has workshop mode)
- `brand.md` exists in `.claude/commands/` but not in `commands/`

## Appetite

**Small batch (1 day).** Copy content from installed to source, verify install.sh round-trips correctly.

## Solution Sketch

1. Copy `.claude/commands/define.md` → `commands/define.md`
2. Copy `.claude/commands/design.md` → `commands/design.md`
3. Copy `.claude/commands/brand.md` → `commands/brand.md` (and brand-image.md, brand-tokens.md if missing)
4. Run `./install.sh project /tmp/test --dry-run` to verify
5. Run `./install.sh project /tmp/test --force` and diff the result against `.claude/commands/`

## Rabbit Holes

- Don't refactor the install.sh copy logic — this is a content sync, not a tooling change

## No-Gos

- No changes to install.sh behavior
- No changes to workshop mode content (just sync what exists)

# End of Shaped Work Contract
