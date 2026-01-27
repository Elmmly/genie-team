---
spec_version: "1.0"
type: shaped-work
id: GT-6
title: "spec:init Command and Define Behavioral Delta"
status: done
created: 2026-01-27
appetite: medium
priority: P0
target_project: genie-team
depends_on: [GT-5]
tags: [spec-driven, specs, lifecycle]
acceptance_criteria:
  - id: AC-1
    description: "New /spec:init command reads source code, tests, and docs to produce rich specs at specs/{domain}/{capability}.md with descriptions, ACs, and evidence — asking the user for domain assignments"
    status: met
  - id: AC-2
    description: "/context:refresh no longer bootstraps specs — spec bootstrapping behavior removed, returns to context-only duties (codebase structure, patterns, drift)"
    status: met
  - id: AC-3
    description: "/define loads the existing spec when shaping work that changes a capability, and documents the behavioral delta — what the spec says today vs. what the shaped work proposes to change"
    status: met
  - id: AC-4
    description: "/define standalone draft promotion mode removed (no more _drafts/ staging area)"
    status: met
  - id: AC-5
    description: "spec-awareness SKILL.md updated — lifecycle starts with /spec:init instead of /context:refresh, _drafts/ references removed, /define behavioral delta documented"
    status: met
  - id: AC-6
    description: "/context:load updated — no longer references _drafts/, reports spec coverage from specs/{domain}/ only"
    status: met
---

# GT-6: spec:init Command and Define Behavioral Delta

## Problem

Two related problems with how specs get created and changed:

**1. Spec bootstrapping is bolted onto the wrong command.**

`/context:refresh` is a context-update command — it refreshes `codebase_structure.md`, detects patterns, flags drift. Spec bootstrapping was added there because that's where test scanning happened, but it doesn't belong. The result is thin "draft" specs that are just test inventories — no meaningful descriptions of what the capability does, no product context, no boundaries. They require a separate promotion step through `/define` to become useful.

**2. `/define` doesn't document what's changing.**

When `/define` shapes work that modifies an existing capability, it links to the spec via `spec_ref` — but it doesn't articulate the behavioral delta. If the auth spec says "tokens expire after 15 minutes" and the shaped work proposes "tokens expire after 1 hour with refresh", the spec should clearly show: here's what the behavior is today, here's what we're proposing to change, and here's why. Without this, the spec just gets silently updated later with no record of the reasoning.

## Appetite

Medium batch — 1 week. Two command files to create/rewrite, several files to update for consistency.

## Solution Sketch

### 1. New `/spec:init` command

A dedicated command for establishing the spec landscape on an existing project. Unlike the thin bootstrap that `/context:refresh` produced, this command:

- **Reads deeply:** Source code (not just tests), project docs (README, CLAUDE.md), test files, directory structure, config files
- **Identifies capabilities:** Groups by what the system does, not by test file boundaries
- **Produces rich specs:** Each spec gets a meaningful description of the capability, acceptance criteria grounded in actual behavior (not just test names), and evidence from both code and tests
- **Assigns domains interactively:** For each capability (or batch), asks the user which domain it belongs to. Presents existing domains and allows new ones.
- **Writes directly to `specs/{domain}/`:** No drafts staging area. Specs go straight to their domain with `status: active`.

**Output:** `specs/{domain}/{capability}.md` files with:
```yaml
---
spec_version: "1.0"
type: spec
id: {capability-slug}
title: {Capability Name}
status: active
created: {YYYY-MM-DD}
domain: {domain}
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: {behavioral description grounded in code/tests}
    status: met
---

# {Capability Name}

{Rich description of what this capability does, why it exists, and its boundaries}

## Acceptance Criteria

{Narrative expansion of each AC with context}

## Evidence

### Source Code
- {source-file}: {what it implements}

### Tests
- {test-file}: {N} tests covering {behaviors}
```

**Interaction model:** The command processes capabilities in batches, presenting each batch to the user for domain assignment and review before writing. The user can adjust descriptions, merge capabilities, or skip ones that don't warrant a spec.

### 2. Remove spec bootstrapping from `/context:refresh`

Strip the "Spec bootstrapping" behavior (step 5) and all related output formats (Spec Bootstrap Output Format, Bootstrap Summary Output). `/context:refresh` returns to its original purpose:

1. Scan codebase for structural changes
2. Update `docs/context/codebase_structure.md`
3. Check for new patterns or conventions
4. Flag drift from documented architecture

Remove `specs/_drafts/` references from WRITE section. Remove triggers related to spec bootstrapping.

### 3. Update `/define` with behavioral delta documentation

When `/define` shapes work that touches an existing capability:

1. **Load the existing spec** via `spec_ref` or by scanning `specs/` for a matching capability
2. **Document the behavioral delta** in the shaped work contract:
   - **Current behavior:** What the spec says the system does today (quote relevant ACs)
   - **Proposed change:** What the shaped work will change about this behavior
   - **Rationale:** Why the change is needed (from discovery or problem statement)
3. **Tag affected ACs:** In the shaped work contract, reference which spec ACs will be modified, added, or deprecated
4. **Set `spec_ref`** on the backlog item linking to the spec that will be updated

This means the shaped work contract becomes a clear change proposal against the spec — not just "we're doing auth improvements" but "we're changing AC-2 from 15-minute expiry to 1-hour with refresh, adding AC-5 for refresh token rotation."

The downstream commands (`/design`, `/deliver`, `/discern`) already read `spec_ref` and write back to the spec. The delta documentation in `/define` gives them clear guidance on what's changing.

**Remove standalone draft promotion mode.** With no `_drafts/` directory, there's nothing to promote. The `specs/_drafts/*.md` input trigger and Standalone Draft Promotion Mode section get removed from `/define`.

### 4. Update supporting files

- **`spec-awareness SKILL.md`:** Lifecycle starts with `/spec:init`, not `/context:refresh`. Remove `_drafts/` references. Document `/define` behavioral delta behavior.
- **`/context:load`:** Remove `_drafts/` references. Report coverage from `specs/{domain}/` only.
- **`/done`:** Remove draft promotion safety net (no drafts to promote).
- **`install.sh`:** Remove `mkdir specs/_drafts` if present. Just `mkdir specs`.

## Rabbit Holes

1. **Don't auto-detect domains.** `/spec:init` must ask the user for domain assignments, not infer them from code structure. Code directories are not product domains.
2. **Don't make `/spec:init` fully automated.** It should be interactive — presenting capabilities for review, allowing merges and skips. A fully automated run would produce specs the user hasn't validated.
3. **Don't require all specs before work starts.** `/spec:init` is helpful but not mandatory. A project can start with zero specs and build them incrementally through `/define`.
4. **Don't preserve `_drafts/` as a fallback.** Clean break — one way to create specs (`/spec:init` for bulk, `/define` for incremental). No staging area.
5. **Don't make the behavioral delta section mandatory in `/define`.** It only applies when shaping work that changes an existing capability. New capabilities don't have a delta.

## Acceptance Criteria

See frontmatter above:

| AC | Scope | Change |
|----|-------|--------|
| AC-1 | New command | `/spec:init` — rich spec creation from existing projects |
| AC-2 | `context-refresh.md` | Remove spec bootstrapping, return to context-only |
| AC-3 | `define.md` | Behavioral delta documentation when changing existing capability |
| AC-4 | `define.md` | Remove standalone draft promotion mode |
| AC-5 | `SKILL.md` | Update lifecycle, remove _drafts/, add /spec:init and define delta |
| AC-6 | `context-load.md` | Remove _drafts/ references |

## Handoff

Ready for `/design`. Key design decisions needed:
- Exact interaction model for `/spec:init` (batch size, review flow)
- How `/define` discovers which spec an existing capability maps to (name matching? user selection?)
- Behavioral delta section format in the shaped work contract

# Design

## Design Summary

7 files affected (1 new, 6 modified). All markdown instruction changes plus one `install.sh` line.

## Component Design

| File | Change | AC |
|------|--------|----|
| `commands/spec-init.md` | **New** — full command file for `/spec:init` using Scout genie | AC-1 |
| `commands/context-refresh.md` | **Rewrite** — strip all spec bootstrapping, return to context-only | AC-2 |
| `commands/define.md` | **Rewrite** — add behavioral delta section, remove standalone draft promotion, remove `_drafts/` refs | AC-3, AC-4 |
| `.claude/skills/spec-awareness/SKILL.md` | **Rewrite** — lifecycle starts with `/spec:init`, remove `_drafts/`, add define delta, add spec:init behavior | AC-5 |
| `commands/context-load.md` | **Rewrite** — remove `_drafts/` refs, point to `/spec:init` instead of `/context:refresh` | AC-6 |
| `commands/done.md` | **Edit** — remove draft promotion safety net from SPEC PRESERVATION | AC-6 |
| `install.sh` | **Edit** — change `mkdir -p "$project_path/specs/_drafts"` to `mkdir -p "$project_path/specs"` | AC-6 |

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Genie for `/spec:init` | Scout | Discovery/exploration agent — reads broadly, surfaces capabilities |
| Interaction model | Batch with review (up to 5 per batch) | Balances efficiency with human oversight for domain assignment |
| Spec discovery in `/define` | `spec_ref` first, then search `specs/` with user confirmation | Never silently assume a match — always confirm with user |
| Behavioral delta format | Dedicated "## Behavioral Delta" section in shaped contract | Keeps delta visible where reviewers see it |
| `_drafts/` removal | Clean break across all files | One way to create specs (spec:init for bulk, define for incremental) |

## `/spec:init` Interaction Design

1. Deep scan source code, tests, docs, config
2. Identify behavioral capabilities (grouped by what system does, not file boundaries)
3. Skip capabilities that already have specs
4. Present in batches of up to 5 with: name, description, evidence, proposed ACs
5. User assigns domain per batch (or per capability), can merge/skip/rename
6. Write directly to `specs/{domain}/{capability}.md` with `status: active`
7. Output summary of everything created

Supports `--dry-run` (list without writing) and `--domain [name]` (pre-assign all).

## `/define` Behavioral Delta Design

When changing an existing capability:

1. Discover spec via `spec_ref` or search `specs/` with user confirmation
2. Document in shaped contract:
   - **Current Behavior** — quote affected spec ACs
   - **Proposed Changes** — what each AC changes to, plus new ACs
   - **Rationale** — why changes are needed
3. Tag affected ACs, set `spec_ref`

When creating a new capability: ask domain, create spec, link via `spec_ref` (same as before, minus `_drafts/`).

## Cross-File Consistency

All `_drafts/` references removed from: context-refresh, define, context-load, done, SKILL.md, install.sh.

All `/context:refresh` references as spec bootstrapper replaced with `/spec:init` in: context-load, SKILL.md, context-refresh notes.

## Implementation Guidance

1. Create `commands/spec-init.md` (new file)
2. Rewrite `commands/context-refresh.md` (strip spec bootstrapping)
3. Rewrite `commands/define.md` (behavioral delta + remove draft promotion)
4. Rewrite `.claude/skills/spec-awareness/SKILL.md` (full lifecycle update)
5. Rewrite `commands/context-load.md` (remove `_drafts/`)
6. Edit `commands/done.md` (remove draft promotion safety net)
7. Edit `install.sh` (remove `_drafts` from mkdir)
8. Sync all commands to `.claude/commands/`
9. Check `commands/genie-help.md` for `/spec:init` addition
10. Verify coherence across all files

# Implementation

## Implementation Summary

All 6 ACs implemented across 8 files (1 new, 7 modified) plus 6 `.claude/commands/` sync copies.

## Changes Made

| File | Change | AC |
|------|--------|----|
| `commands/spec-init.md` | **Created** — 260-line command file with Scout genie, batch interaction model, rich spec format, domain assignment, `--dry-run` and `--domain` flags | AC-1 |
| `commands/context-refresh.md` | **Rewritten** — stripped all spec bootstrapping (step 5, output formats, triggers, `_drafts/` refs). 77 lines, 4-step context-only behavior. Notes point to `/spec:init` | AC-2 |
| `commands/define.md` | **Rewritten** — added Spec Lifecycle Behavior section with behavioral delta (Current Behavior → Proposed Changes → Rationale) and new capability creation. Removed standalone draft promotion and all `_drafts/` refs | AC-3, AC-4 |
| `.claude/skills/spec-awareness/SKILL.md` | **Rewritten** — lifecycle starts with `/spec:init`, removed `_drafts/` from hierarchy/definitions/naming/lifecycle, added `/spec:init` behavior (8 steps), updated `/define` with behavioral delta, removed `/done` draft promotion, updated description frontmatter | AC-5 |
| `commands/context-load.md` | **Updated** — removed `_drafts/` from spec scanning, removed "draft" from status counts, pointed bootstrap recommendation to `/spec:init` | AC-6 |
| `commands/done.md` | **Updated** — removed draft promotion safety net from SPEC PRESERVATION (3 steps → 3 steps without draft logic), removed safety net note | AC-6 |
| `install.sh` | **Updated** — changed `mkdir -p "$project_path/specs/_drafts"` to `mkdir -p "$project_path/specs"` | AC-6 |
| `commands/genie-help.md` | **Updated** — added SPECS section with `/spec:init [scope]` entry | AC-6 |
| `genies/shaper/GENIE.md` | **Updated** — removed `specs/_drafts/` from Context Usage Read list (found by coherence check) | consistency |

## Coherence Verification

Critic agent verified all 10 coherence criteria passed:
1. No remaining `_drafts/` references in any modified file
2. No remaining "draft" as a spec status
3. No remaining standalone draft promotion
4. SKILL.md correctly documents `/spec:init` and `/define` behavioral delta
5. context-refresh.md has no spec bootstrapping
6. context-load.md points to `/spec:init` for bootstrapping
7. done.md has no draft promotion safety net
8. install.sh creates `specs/` (not `specs/_drafts/`)
9. genie-help.md includes `/spec:init`
10. All files consistent about spec lifecycle

One out-of-scope issue found and fixed: `genies/shaper/GENIE.md` had a stale `specs/_drafts/` reference.

## Decisions Made During Implementation

| Decision | Choice | Reason |
|----------|--------|--------|
| genie-help.md placement | Dedicated SPECS section above CONTEXT | `/spec:init` is a distinct category from context management |
| done.md simplification | Removed 2 sub-steps, kept 3-step preservation | With no drafts, preservation is passive — just don't archive the spec |

# Review

## Verdict: APPROVED

All 6 acceptance criteria met. Zero issues found.

## AC Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | **MET** | `commands/spec-init.md` created (260 lines). Scout genie, batch interaction, rich specs with descriptions/ACs/evidence, user domain assignment, writes to `specs/{domain}/{capability}.md` |
| AC-2 | **MET** | `commands/context-refresh.md` rewritten to 77 lines. 4-step context-only behavior. Zero `_drafts/` references. Zero spec bootstrapping |
| AC-3 | **MET** | `commands/define.md` has Spec Lifecycle Behavior section with behavioral delta (Current Behavior → Proposed Changes → Rationale). Spec discovery via `spec_ref` or search with user confirmation |
| AC-4 | **MET** | `commands/define.md` contains zero `_drafts/` references and zero standalone draft promotion mode |
| AC-5 | **MET** | `SKILL.md` lifecycle starts with `/spec:init`. Zero `_drafts/` references. `/define` behavioral delta documented. `/spec:init` behavior in 8 steps. Frontmatter description includes `/spec:init` |
| AC-6 | **MET** | `commands/context-load.md` has zero `_drafts/` references. Points to `/spec:init` for bootstrapping. Status counts: active and deprecated only |

## Supporting File Verification

| File | Check | Result |
|------|-------|--------|
| `commands/done.md` | No draft promotion safety net | PASS |
| `install.sh` | Creates `specs/` not `specs/_drafts/` | PASS |
| `commands/genie-help.md` | Includes `/spec:init` | PASS |
| `genies/shaper/GENIE.md` | No `_drafts/` reference | PASS |
| `.claude/commands/` sync | All 6 copies byte-identical to sources | PASS |

## Cross-File Coherence

10/10 coherence criteria verified by critic agent. Zero remaining `_drafts/` references across all modified files.

# End of Shaped Work Contract
