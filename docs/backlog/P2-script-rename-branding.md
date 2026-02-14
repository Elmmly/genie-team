---
spec_version: "1.0"
type: shaped-work
id: P2-script-rename-branding
title: "Rename PATH Scripts for Genie Team Brand Alignment"
status: designed
created: "2026-02-14"
appetite: small
priority: P2
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
acceptance_criteria:
  - id: AC-1
    description: >-
      Primary lifecycle runner renamed from run-pdlc.sh to genies
      (without .sh extension) in scripts/, install.sh, and all documentation
    status: pending
  - id: AC-2
    description: >-
      All companion scripts drop .sh extension for PATH consistency:
      genie-session.sh → genie-session, run-quality-checks.sh → genie-quality
    status: pending
  - id: AC-3
    description: >-
      run-batch.sh backwards-compatible wrapper updated to delegate to the
      new primary script name
    status: pending
  - id: AC-4
    description: >-
      All cross-references updated: README.md, install.sh output messages,
      commands/run.md, specs, backlog items, test files, and archive docs.
      Verified via grep that zero references to old names remain (excluding
      git history and this backlog item).
    status: pending
  - id: AC-5
    description: >-
      install.sh installs scripts without .sh extension, chmod +x, and the
      PATH setup message reflects the new names
    status: pending
  - id: AC-6
    description: >-
      Test sourcing updated: test_run_pdlc.sh sources the renamed script
      correctly; test_session.sh sources genie-session correctly.
      All existing tests pass.
    status: pending
---

# Shaped Work Contract: Rename PATH Scripts for Genie Team Brand Alignment

## Problem

With `run-pdlc.sh` now on the system PATH (via `install.sh global`), users type
this name frequently in terminals, cron jobs, and CI/CD pipelines. The current
name has three problems:

1. **Not brand-aligned** — `run-pdlc` doesn't mention "genie" anywhere. Users who
   installed "Genie Team" now run a script with no connection to that name.
2. **`.sh` extension is non-standard for PATH commands** — Conventional CLI tools
   (`git`, `docker`, `cargo`, `rails`) don't use file extensions. The `.sh` suffix
   signals "this is a shell script" rather than "this is a polished CLI command."
3. **Naming inconsistency across scripts** — `run-pdlc.sh` and `run-batch.sh` use
   a `run-*` prefix while `genie-session.sh` uses a `genie-*` prefix. No unified
   naming convention.

**Who's affected:** Every user who runs the lifecycle runner from the command line,
schedules it in cron, or references it in CI/CD configuration.

**Evidence:** The install.sh output already uses shortened names in informal text
(line 888: "run-pdlc (autonomous runner + batch), genie-session (parallel sessions)")
but the actual installed files retain `.sh` extensions.

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days)
- **No-gos:**
  - No behavior changes to any script — this is purely a rename + reference update
  - No changes to the autonomous-lifecycle spec ACs (behavior is unchanged)
  - No removal of `run-batch.sh` wrapper (keep it for backwards compatibility, update target)
  - No renaming of test files (test filenames don't need to match script names)
- **Fixed elements:**
  - `genie-session` keeps its current name (already well-named, just drops `.sh`)
  - `scripts/` directory remains the source location
  - `~/.claude/scripts/` remains the install target
  - `RUN_PDLC_SOURCED` guard variable gets renamed to `GENIES_SOURCED`

## Goals & Outcomes

- Users type a brand-aligned, extension-free command to run the lifecycle
- All scripts follow a consistent `genie-*` naming convention
- Documentation, cron examples, and CI/CD snippets all reflect the new names
- Zero old-name references remain in the codebase (verified by grep)

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Users have existing cron jobs / CI configs referencing `run-pdlc.sh` | Value | Low risk — tool is new, few external references exist yet |
| Renaming the source guard variable won't break test sourcing | Feasibility | Run test suite after rename |
| `genie-session.sh` sources from `run-pdlc.sh` — the source line needs updating | Feasibility | Grep for cross-script sourcing |

## Chosen Direction: `genies`

**Decision:** `genies` — chosen interactively from 4 candidates (`genie`, `genies`, `genie-team`, `genie-run`).

| Script | Old Name | New Name |
|--------|----------|----------|
| Lifecycle runner | `run-pdlc.sh` | `genies` |
| Session manager | `genie-session.sh` | `genie-session` |
| Quality checks | `run-quality-checks.sh` | `genie-quality` |
| Batch wrapper | `run-batch.sh` | stays as backwards-compat shim → delegates to `genies` |

**Usage examples:**
```bash
genies "add password reset"
genies --from design --through deliver P2-auth.md
genies --parallel 3 --trunk --verbose
genies --through define "explore auth improvements"
0 2 * * * genies --through define --lock --log-dir ./logs "explore improvements"
```

**Why `genies`:**
- Uses the project's own vocabulary — "genies" IS the brand term for specialists
- Plural is semantically correct — you're dispatching scout → shaper → architect → crafter → critic, not one genie
- `genies --parallel 3` reads perfectly — "run 3 genies in parallel"
- 6 chars, unique, zero collision risk
- Companion namespace: `genies` (the team), `genie-session` (one session), `genie-quality` (one check)

**Alternatives considered:**
- `genie` — shorter but singular doesn't capture the team dispatch
- `genie-team` — unambiguous but 10 chars, "running the team" sounds odd
- `genie-run` — redundant, doesn't extend well to companion scripts

## Blast Radius

Files requiring updates (18 for `run-pdlc`, 12 for `genie-session`, ~4 for `run-quality-checks`):

- `scripts/run-pdlc.sh` → `scripts/genies` + update `RUN_PDLC_SOURCED` → `GENIES_SOURCED`
- `scripts/genie-session.sh` → `scripts/genie-session`
- `scripts/run-quality-checks.sh` → `scripts/genie-quality`
- `scripts/run-batch.sh` → update delegation target to `genies`
- `install.sh` → script names in install function, PATH messages, help output (~6 locations)
- `README.md` → script references in install table, usage examples, cron examples (~15 locations)
- `commands/run.md` → script references
- `docs/specs/workflow/autonomous-lifecycle.md` → implementation evidence references
- `tests/test_run_pdlc.sh` → source line, guard variable
- `tests/test_session.sh` → source line
- Various `docs/backlog/`, `docs/archive/` references

## Routing

**Ready for:** `/design` (or skip directly to `/deliver` — the scope is well-understood and purely mechanical)

**Recommended:** Skip `/design` — no architectural decisions needed. This is a find-and-replace with test verification. Go straight to `/deliver`.

# Design
<!-- Appended by /design on 2026-02-14 from P2-script-rename-branding -->

## Overview

Rename 3 source scripts (drop `.sh` extension, apply `genie-*`/`genies` naming), update the install.sh glob pattern to match extensionless files, update all cross-references across ~25 files, and verify via tests + grep sweep.

**Complexity:** Simple — mechanical find-and-replace with one structural change (install.sh glob).

## Rename Map

| Old (scripts/) | New (scripts/) | Guard Variable |
|----------------|----------------|----------------|
| `run-pdlc.sh` | `genies` | `RUN_PDLC_SOURCED` → `GENIES_SOURCED` |
| `genie-session.sh` | `genie-session` | _(none — uses `return 0` guard)_ |
| `run-quality-checks.sh` | `genie-quality` | _(none)_ |

**Not renamed:** `scripts/validate/*.sh` — these are internal validation scripts called by `genie-quality`, not PATH commands. They keep their `.sh` extension.

**Already deleted:** `run-batch.sh` — was removed in GT-36. AC-3 is N/A.

## Design Constraints

### 1. install.sh Glob Pattern Change (Critical)

The current `install_scripts()` function globs `*.sh`:

```bash
for script in "$SCRIPT_DIR/scripts"/*.sh; do
    if [[ -f "$script" ]]; then
```

After rename, scripts have no extension. Change to:

```bash
for script in "$SCRIPT_DIR/scripts"/*; do
    if [[ -f "$script" && -x "$script" ]]; then
```

The `-x` check ensures only executable files are installed (excludes subdirectories and any non-executable files). The `validate/` subdirectory is excluded by `-f`.

### 2. Cross-Script Sourcing

In `genies` (formerly `run-pdlc.sh`), line 655:
```bash
GENIE_SESSION="$SCRIPT_DIR/genie-session.sh"
```
→
```bash
GENIE_SESSION="$SCRIPT_DIR/genie-session"
```

The `shellcheck source=` directive on line 657 also updates:
```bash
# shellcheck source=genie-session.sh
```
→
```bash
# shellcheck source=genie-session
```

### 3. SELF Variable

Line 654 uses `basename "${BASH_SOURCE[0]}"` — this automatically resolves to the new filename. No change needed.

### 4. Test Sourcing

`tests/test_run_pdlc.sh`:
- Line 12: `RUN_PDLC="$PROJECT_DIR/scripts/run-pdlc.sh"` → `"$PROJECT_DIR/scripts/genies"`
- Line 137: `RUN_PDLC_SOURCED=true` → `GENIES_SOURCED=true`
- Line 143: error message `run-pdlc.sh not found` → `genies not found`
- Comment on line 2, line 3, line 132, line 136, line 140

`tests/test_session.sh`:
- Line 13: `SESSION_SH="$PROJECT_DIR/scripts/genie-session.sh"` → `"$PROJECT_DIR/scripts/genie-session"`
- Line 134: error message `genie-session.sh not found` → `genie-session not found`

### 5. Usage Text in genies Script

Lines 200-208 contain `run-pdlc.sh` in help text. All become `genies`:
```
Usage: genies [OPTIONS] [<topic|backlog-item-path>...]
  genies [OPTIONS] <topic|backlog-item-path>
  genies --parallel 3 --trunk
  genies --dry-run
  genies item1.md item2.md
```

### 6. Log Message

Line 1419: `log_info "PDLC completed: ..."` — keep as-is (describes what completed, not the script name).

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | `git mv scripts/run-pdlc.sh scripts/genies` + update guard, usage, sourcing | `scripts/genies` |
| AC-2 | `git mv` for session + quality scripts | `scripts/genie-session`, `scripts/genie-quality` |
| AC-3 | N/A — `run-batch.sh` was already deleted in GT-36 | — |
| AC-4 | Grep-driven reference sweep across all docs, commands, specs | ~20 files |
| AC-5 | Change glob from `*.sh` to `*` with `-f && -x` guard | `install.sh` |
| AC-6 | Update source paths + guard variable in test files, run full suite | `tests/test_run_pdlc.sh`, `tests/test_session.sh` |

## Implementation Sequence

Order matters — `git mv` first to preserve history, then update references.

1. **Rename source files** (`git mv` × 3)
2. **Update script internals** — guard variable, usage text, cross-script source path, shellcheck directives
3. **Update install.sh** — glob pattern, comments, help output (~8 locations)
4. **Update test files** — source paths, guard variable, error messages
5. **Run test suite** — verify all 119+ tests pass
6. **Update README.md** — install table, usage examples, cron examples, tree (~15 locations)
7. **Update commands/run.md** — headless runner references
8. **Update docs/** — specs, backlog items, archive docs
9. **Grep verification** — confirm zero stale references (excluding git history and this backlog item)

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Tests break from stale source path | Medium | Low | Run tests after step 4, before bulk doc updates |
| install.sh `*` glob matches unexpected files in scripts/ | Low | Low | `-f && -x` guard; scripts/ only contains scripts |
| Archive docs have stale references | Low | Low | Grep sweep catches them; archive is read-only context |

## Architecture Decisions

None — does not meet ADR threshold (single viable approach, easily reversible).

## Diagram Updates

None — structural boundaries unchanged.

## Routing

**Ready for:** `/deliver docs/backlog/P2-script-rename-branding.md`
