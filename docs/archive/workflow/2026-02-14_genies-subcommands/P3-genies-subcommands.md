---
spec_version: "1.0"
type: shaped-work
id: P3-genies-subcommands
title: "Unify CLI Under genies Subcommands"
status: done
verdict: APPROVED
created: "2026-02-14"
appetite: small
priority: P3
author: shaper
spec_ref: docs/specs/workflow/parallel-sessions.md
depends_on:
  - docs/archive/workflow/2026-02-14_script-rename-branding/P2-script-rename-branding.md
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

# Implementation

## Changes

### `scripts/genies` — Subcommand dispatch (AC-1, AC-2)
- Added `case` dispatch before `main "$@"`: `session` routes to sourced genie-session functions, `quality` runs validate scripts inline, `*` falls through to PDLC `main()`
- Updated `--help` text to show `session` and `quality` subcommands

### `scripts/genie-session` — Library-only mode (AC-3)
- Removed CLI dispatch block (the `if BASH_SOURCE == $0` case statement)
- File is now purely a library sourced by `genies`

### `scripts/genie-quality` — Removed (AC-3)
- Deleted standalone script; its 6-line loop logic is inlined in the `genies quality` subcommand

### `install.sh` — Single entry point (AC-3)
- `install_scripts()` now installs only `genies` as a PATH command
- Also copies `genie-session` (library) and `validate/` directory alongside for sourcing
- Updated all help text and summary output

### `README.md` — Documentation (AC-4)
- Session examples updated from `genie-session` to `genies session`
- Directory tree updated to show `genies` as CLI entry point
- Install table updated

## Test Coverage
- `tests/test_run_pdlc.sh`: 13 new tests (Category 20) covering subcommand dispatch
- `tests/test_session.sh`: 6 updated tests covering sourceability and CLI dispatch removal
- Total: 385 tests across all suites, all passing

## Decisions
- `quality` subcommand inlines the validate loop rather than `exec`ing the deleted script — avoids dependency on a file that no longer exists
- `session` subcommand reuses the already-sourced genie-session functions (loaded at line 663 of genies) — no extra `source` call needed

# Review
<!-- Appended by /discern on 2026-02-14 -->

**Verdict:** APPROVED
**ACs verified:** 4/4 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `case` dispatch at genies:1454-1465 routes session subcommands to sourced functions. 10 tests. |
| AC-2 | met | Inlined validate loop at genies:1467-1475. Same behavior as deleted genie-quality. 2 tests. |
| AC-3 | met | genie-quality deleted. genie-session CLI dispatch removed. install_scripts() installs only genies to PATH. |
| AC-4 | met | README, install.sh help text updated. Spec design constraint updated. |

Code quality: Clean, minimal. No behavior changes to underlying functions.
Test coverage: 385 total, 0 failures. 13 new + 6 updated tests.
Security: Pass (no new inputs, no privilege changes).
Performance: Pass (dispatch is a single `case` statement).
