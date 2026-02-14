---
spec_version: "1.0"
type: shaped-work
id: P3-genies-subcommands
title: "Unify CLI Under genies Subcommands"
status: shaped
created: "2026-02-14"
appetite: small
priority: P3
author: shaper
spec_ref: docs/specs/workflow/parallel-sessions.md
depends_on:
  - docs/backlog/P2-script-rename-branding.md
acceptance_criteria:
  - id: AC-1
    description: >-
      genies session {start|list|finish|cleanup|cleanup-item} dispatches to
      genie-session functions. All existing genie-session CLI behavior is
      accessible via the subcommand with identical arguments and exit codes.
    status: pending
  - id: AC-2
    description: >-
      genies quality [files...] dispatches to genie-quality. Identical
      behavior to calling genie-quality directly.
    status: pending
  - id: AC-3
    description: >-
      Standalone genie-session and genie-quality are removed from PATH
      installation. genie-session remains as a sourceable library in
      scripts/ but is no longer installed as a standalone command.
      genie-quality is removed; its logic moves into the genies quality
      subcommand. install.sh stops copying these to PATH targets.
    status: pending
  - id: AC-4
    description: >-
      README, install.sh help output, and commands/run.md updated to show
      genies as the single CLI entry point with session and quality
      subcommands.
    status: pending
---

# Shaped Work Contract: Unify CLI Under genies Subcommands

## Problem

After the P2 rename (P2-script-rename-branding), users have 3 separate PATH
commands: `genies`, `genie-session`, `genie-quality`. Users must learn and
remember 3 commands rather than one entry point with subcommands.

The standard CLI pattern — `git {remote|stash|worktree}`, `docker {compose|volume}`,
`cargo {test|build}` — uses a single command with subcommands. Users expect this.

**Dependency:** This item depends on P2-script-rename-branding completing first
(the rename establishes the `genies` command name).

## Appetite & Boundaries

- **Appetite:** Small batch (1 day)
- **No-gos:**
  - No behavior changes to any underlying function
  - No new subcommands beyond `session` and `quality`
- **Fixed elements:**
  - `genies` (no subcommand) continues to run the PDLC lifecycle as before
  - `genie-session` library sourcing by `genies` is unchanged
  - All existing session function signatures, return codes, and contracts are preserved

## Goals & Outcomes

- Single entry point: `genies` is the one command users learn
- `genies session list` feels natural, matches CLI conventions
- No dead standalone scripts cluttering PATH

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Subcommand routing doesn't conflict with existing PDLC flags | Feasibility | `session` and `quality` are not valid phase names or flag values |
| ~15 lines of dispatch code fits cleanly before main() | Feasibility | Review script structure |

## Behavioral Delta

**Spec:** docs/specs/workflow/parallel-sessions.md

### Current Behavior
- AC-7: Session lifecycle commands wrap git worktree ceremony into single operations
- AC-9: Session management functions are sourceable by external scripts

### Proposed Changes
- AC-7: CLI access moves from standalone `genie-session` to `genies session` subcommand — same functions, same args, same exit codes
- AC-9: No change — sourcing contract unchanged (`genie-session` stays as a library file in `scripts/`)
- AC-NEW: `genies session` and `genies quality` subcommands replace standalone PATH commands

### Rationale
Users get a unified CLI surface. Standalone scripts are removed to avoid PATH clutter — `genie-session` remains sourceable for library use, `genie-quality` logic is trivial enough to inline.

## Routing

**Ready for:** `/design` (or skip to `/deliver` — subcommand routing is ~15 lines)
