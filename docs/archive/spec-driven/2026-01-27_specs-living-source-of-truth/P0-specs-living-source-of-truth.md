---
spec_version: "1.0"
type: shaped-work
id: GT-5
title: "Specs as Living Source of Truth Through the 7 D's"
status: done
created: 2026-01-27
appetite: medium
priority: P0
target_project: genie-team
depends_on: [GT-4]
tags: [spec-driven, specs, lifecycle]
acceptance_criteria:
  - id: AC-1
    description: "/define promotes drafts from docs/specs/_drafts/ into docs/specs/{domain}/{capability}.md with status: active, and sets spec_ref on the backlog item"
    status: met
  - id: AC-2
    description: "/define can also be invoked standalone to promote existing drafts (e.g. /define docs/specs/_drafts/session-management.md) for projects that already have bootstrapped drafts"
    status: met
  - id: AC-3
    description: "/design reads spec_ref from backlog, loads the linked spec for context, and updates the spec with any new architectural constraints or refined ACs"
    status: met
  - id: AC-4
    description: "/deliver reads spec_ref from backlog, uses spec ACs to drive TDD tests, and updates spec with implementation evidence (test file paths, coverage notes)"
    status: met
  - id: AC-5
    description: "/discern reads spec_ref from backlog, verifies implementation against spec ACs, and updates spec AC statuses (pending → met/unmet) based on review verdict"
    status: met
  - id: AC-6
    description: "/done archives the backlog item but leaves the spec in place; if spec is still draft, promotes it to active in docs/specs/{domain}/"
    status: met
  - id: AC-7
    description: "spec-awareness SKILL.md updated to reflect the full lifecycle read/write behaviors across all commands"
    status: met
---

# GT-5: Specs as Living Source of Truth Through the 7 D's

## Problem

GT-4 established `docs/specs/` as a persistent location and `/context:refresh` bootstraps drafts into `docs/specs/_drafts/`. But specs are currently write-once. No command in the 7 D's lifecycle reads from or writes back to specs after bootstrapping. The result:

1. **Drafts never get promoted.** There's no mechanism to move a draft from `docs/specs/_drafts/` to `docs/specs/{domain}/{capability}.md`. The SKILL.md says `/define` does this, but `/define` currently only writes to `docs/backlog/`.

2. **Specs don't accumulate knowledge.** `/design` doesn't read the spec for context. `/deliver` doesn't update the spec with implementation evidence. `/discern` doesn't mark spec ACs as met/unmet. The spec stays frozen at bootstrap state.

3. **Existing projects have orphaned drafts.** Projects that ran `/context:refresh` now have `docs/specs/_drafts/` full of bootstrapped drafts with no path to promote them into domain-organized active specs.

4. **Backlog items and specs are disconnected.** Even though `spec_ref` exists in the schema, no command sets it or reads it. The link between transient work (backlog) and persistent knowledge (spec) is theoretical.

The lifecycle should be: drafts get promoted by `/define`, refined by `/design`, evidenced by `/deliver`, verified by `/discern`, and preserved by `/done` — while the backlog item gets archived.

## Appetite

Medium batch — 1 week. This touches 6 command files and 1 skill file, but each change is a targeted addition to existing markdown instructions (no code, no tests). The risk is in coherence across commands, not complexity.

## Solution Sketch

### 1. `/define` — Draft Promotion + Spec Creation

**New behavior:** When `/define` shapes work for a capability:

- **If a draft exists** in `docs/specs/_drafts/{capability}.md`: Move it to `docs/specs/{domain}/{capability}.md`, update `status: draft` → `status: active`, refine ACs based on shaping.
- **If no draft exists**: Create a new spec at `docs/specs/{domain}/{capability}.md` with `status: active` and ACs from the shaped contract.
- **Always**: Set `spec_ref: docs/specs/{domain}/{capability}.md` in the backlog item frontmatter.

**Standalone draft promotion:** `/define docs/specs/_drafts/session-management.md` takes a draft path directly, asks the user for the target domain, and promotes it without creating a backlog item. This handles existing projects that already have bootstrapped drafts.

### 2. `/design` — Spec-Informed Design

**New behavior:** Before designing:

- Read `spec_ref` from backlog frontmatter.
- Load the linked spec for context (existing ACs, domain, evidence).
- After designing: Update the spec if the design introduces new constraints or refines ACs (append, never remove).

### 3. `/deliver` — Spec-Driven Tests + Evidence

**New behavior:** Before implementing:

- Read `spec_ref` from backlog frontmatter.
- Load spec ACs to inform test writing (RED phase uses spec ACs as test targets).
- After implementing: Update spec with evidence section (test file paths, coverage).

### 4. `/discern` — Spec Verification

**New behavior:** During review:

- Read `spec_ref` from backlog frontmatter.
- Load spec ACs and verify each against implementation.
- After review: Update spec AC statuses (`pending` → `met` or `unmet`).
- Review checklist gains item: "Spec ACs verified?"

### 5. `/done` — Spec Preservation

**New behavior:** When archiving:

- Archive backlog item as normal (move to `docs/archive/`).
- **Leave spec in place** — never archive specs.
- If spec `status: draft`, promote to `status: active` (safety net).
- Spec persists with all accumulated knowledge from the lifecycle.

### 6. `spec-awareness SKILL.md` — Full Lifecycle Documentation

Update the skill to document the complete read/write behaviors for all commands, not just `/deliver` and `/discover`.

## Rabbit Holes

1. **Don't automate domain assignment.** Choosing which domain a capability belongs to is a human decision. `/define` should ask the user, not guess.
2. **Don't modify ACs destructively.** Commands can add ACs and update statuses, but never remove or rewrite existing ACs. Specs accumulate.
3. **Don't block on missing specs.** If `spec_ref` is missing, warn and continue — don't break the workflow. Specs are valuable but optional.
4. **Don't create a promotion wizard.** The standalone `/define docs/specs/_drafts/foo.md` flow should be simple: ask domain, move file, update status. No multi-step UI.
5. **Don't touch `/discover` or `/commit`.** Discovery is upstream of specs (finds opportunities, doesn't define capabilities). Commit is downstream (just git operations). Keep them out of scope.

## Acceptance Criteria

See frontmatter above. Each AC maps to one command change:

| AC | Command | Change |
|----|---------|--------|
| AC-1 | `/define` | Promote drafts, create specs, set spec_ref |
| AC-2 | `/define` | Standalone draft promotion for existing projects |
| AC-3 | `/design` | Read spec_ref, load spec, update spec constraints |
| AC-4 | `/deliver` | Read spec_ref, spec-driven TDD, add evidence |
| AC-5 | `/discern` | Read spec_ref, verify ACs, update AC statuses |
| AC-6 | `/done` | Preserve spec, promote if still draft |
| AC-7 | `SKILL.md` | Document full lifecycle behaviors |

## Handoff

Ready for `/design`. The scope is well-bounded (markdown instruction changes to 6 commands + 1 skill file). No code changes needed — this is all prompt engineering for the genie team workflow.

# Design

## Design Summary

Make specs a living document that accumulates knowledge through the full 7 D's lifecycle. Each command reads `spec_ref` from backlog frontmatter to load the linked spec, and writes back a specific section type. Ten files are modified — 6 command files, 2 sub-command files, 1 skill file, and 1 shaper genie file (plus 1 template).

## Component Design

| File | Reads From Spec | Writes To Spec |
|------|----------------|----------------|
| `commands/define.md` | `docs/specs/_drafts/`, `docs/specs/` domains | Creates/promotes `docs/specs/{domain}/{capability}.md`, sets `spec_ref` on backlog |
| `commands/design.md` | `spec_ref` → spec ACs, evidence | Appends "## Design Constraints" to spec body; may append new ACs |
| `commands/deliver.md` | `spec_ref` → spec ACs as TDD targets | Appends "## Implementation Evidence" to spec body |
| `commands/deliver-tests.md` | `spec_ref` → spec ACs as test targets | Nothing (test phase only) |
| `commands/deliver-implement.md` | `spec_ref` → spec for context | Appends "## Implementation Evidence" to spec body |
| `commands/discern.md` | `spec_ref` → spec ACs for verification | Updates AC statuses in frontmatter; appends "## Review Verdict" to spec body |
| `commands/done.md` | `spec_ref` → spec status check | Promotes `draft` → `active` if needed; never archives specs |
| `.claude/skills/spec-awareness/SKILL.md` | n/a | n/a (documentation of all behaviors above) |
| `genies/shaper/GENIE.md` | n/a | Context Usage updated to include spec reads/writes |
| `genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md` | n/a | `spec_ref` added to template frontmatter |

## Interface Design: Common Spec Loading Pattern

All commands that read specs follow the same three-step pattern:

1. Read `spec_ref` from backlog item frontmatter
2. If present: load the spec file and use its contents
3. If missing or file not found: **warn** and continue — never block

Warning messages:
- Missing: `This backlog item has no spec_ref. Consider linking it to a persistent spec in docs/specs/{domain}/.`
- Not found: `spec_ref points to {path} but file not found. Proceeding without spec context.`

## Interface Design: Spec Body Sections

Each command appends a specific section to the spec body. Sections use dated comment markers for traceability:

```markdown
## Design Constraints
<!-- Updated by /design on {YYYY-MM-DD} from {backlog-item-id} -->
- {constraint}

## Implementation Evidence
<!-- Updated by /deliver on {YYYY-MM-DD} from {backlog-item-id} -->
### Test Coverage
- {test-file}: {N} cases covering AC-1, AC-2
### Implementation Files
- {source-file}: {description}

## Review Verdict
<!-- Updated by /discern on {YYYY-MM-DD} from {backlog-item-id} -->
**Verdict:** {APPROVED | CHANGES REQUESTED | BLOCKED}
**ACs verified:** {N}/{M} met
| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | {brief} |
```

## Data Design: /define Spec Promotion

`/define` has two modes:

**Standard mode** (shaping work): After producing the shaped contract:
1. Check `docs/specs/_drafts/` for a matching draft
2. Ask the user which domain (present existing domains from `docs/specs/` subdirectories)
3. Promote or create spec at `docs/specs/{domain}/{capability}.md` with `status: active`
4. Set `spec_ref` in backlog frontmatter

**Standalone mode** (`/define docs/specs/_drafts/foo.md`): Input is a draft path:
1. Read the draft spec
2. Ask the user for the domain
3. Move to `docs/specs/{domain}/{capability}.md`, update `status: active`, add `domain` field
4. No backlog item created

## Key Design Decisions

| Decision | Choice | Rationale |
|----------|--------|-----------|
| Domain assignment | Always ask user | Rabbit hole #1: human decision |
| Spec updates | Append-only body sections + frontmatter status updates | Never lose data; machine-readable frontmatter + human-readable body |
| Missing spec_ref | Warn and continue | Rabbit hole #3: never block |
| Who updates AC statuses | Only /discern | Single responsibility — deliver writes evidence, discern renders verdict |
| spec_ref direction | Backlog → spec only | Spec doesn't point back to transient backlog |
| Standalone promotion output | Confirmation only, no backlog | Rabbit hole #4: simple flow |

## Risks & Mitigations

| Risk | Mitigation |
|------|-----------|
| LLM doesn't ask for domain | Clear imperative language ("Ask the user") + example output showing the prompt |
| Spec body grows large over multiple cycles | Dated comment markers allow future cleanup; each section is replaceable |
| Standalone /define confused with standard mode | Argument pattern matching: `docs/specs/_drafts/*.md` triggers standalone |

## Implementation Guidance

**Order of implementation (10 files + 1 template):**

1. `.claude/skills/spec-awareness/SKILL.md` — Canonical reference for all behaviors. Update first.
2. `commands/define.md` — Entry point for spec creation. Most complex change (two modes).
3. `commands/design.md` — Add spec loading + Design Constraints write-back.
4. `commands/deliver.md` — Add spec loading + Implementation Evidence write-back + spec-driven TDD note.
5. `commands/deliver-tests.md` — Add spec loading for test targets.
6. `commands/deliver-implement.md` — Add spec loading + Implementation Evidence write-back.
7. `commands/discern.md` — Add spec loading + AC status updates + Review Verdict write-back + checklist item.
8. `commands/done.md` — Add spec preservation + draft promotion safety net.
9. `genies/shaper/GENIE.md` — Update Context Usage to include spec reads/writes.
10. `genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md` — Add `spec_ref` to template frontmatter.
11. Sync all `commands/` → `.claude/commands/` copies.
12. Verify coherence: read all files end-to-end, confirm lifecycle narrative is consistent.

**Spec update rules (enforced across all commands):**
- Append only — never remove ACs, sections, or evidence
- Frontmatter is machine-readable (AC statuses, structural fields)
- Body is human-readable (narrative sections with dated markers)
- Domain is a human decision — always ask, never infer
- Specs persist — never archive, delete, or move out of `docs/specs/`

# Implementation

## Summary

All 7 ACs implemented across 10 files + 7 synced copies. No application code changes — all deliverables are markdown instruction updates.

## Changes Made

### AC-7: SKILL.md (canonical reference — updated first)
- **File:** `.claude/skills/spec-awareness/SKILL.md`
- Replaced "When Active" section: added `/define`, `/design`, `/deliver`, `/discern`, `/done`
- Replaced entire "Behaviors" section with full lifecycle documentation:
  - Common Spec Loading Pattern (4-step: read spec_ref, load, warn missing, warn not found)
  - Per-command sections with Reads/Writes annotations
  - "Spec Update Rules (All Commands)" section with 6 append-only rules
  - Updated "What This Skill Does NOT Do" to reflect full lifecycle scope

### AC-1 + AC-2: define.md (draft promotion + standalone mode)
- **File:** `commands/define.md`
- Arguments: Added draft spec path as valid input, standalone mode trigger
- Context Loading: Added `docs/specs/_drafts/` and `docs/specs/{domain}/` directories
- Context Writing: Added `docs/specs/{domain}/{capability}.md` write, `spec_ref` update, MOVE for draft promotion
- New section: "Spec Lifecycle Behavior" with Standard Mode (5 steps) and Standalone Draft Promotion Mode (5 steps)
- Usage Examples: Added spec promotion output and standalone promotion example

### AC-3: design.md (spec loading + constraint write-back)
- **File:** `commands/design.md`
- Context Loading: Added spec_ref loading, SPEC LOADING subsection (4 steps)
- Context Writing: Added spec update with "## Design Constraints" section, AC append behavior

### AC-4: deliver.md + deliver-tests.md + deliver-implement.md (spec-driven TDD + evidence)
- **File:** `commands/deliver.md`
  - Context Loading: Added spec_ref loading, SPEC LOADING subsection (4 steps)
  - Context Writing: Added "## Implementation Evidence" spec update template
  - Phase 1 Red: Added "Spec-Driven Test Targets" guidance (AC ids in test descriptions)
- **File:** `commands/deliver-tests.md`
  - Context Loading: Added spec_ref loading, SPEC LOADING subsection (4 steps)
- **File:** `commands/deliver-implement.md`
  - Context Loading: Added spec_ref loading, SPEC LOADING subsection (4 steps), SPEC UPDATE section

### AC-5: discern.md (spec AC verification)
- **File:** `commands/discern.md`
- Context Loading: Added spec_ref loading, SPEC LOADING subsection (4 steps)
- Context Writing: Added SPEC UPDATE with AC status updates (pending → met/unmet) and "## Review Verdict" section template
- Review Checklist: Added item #2 "Spec ACs verified?"

### AC-6: done.md (spec preservation)
- **File:** `commands/done.md`
- Context Loading: Added spec_ref loading for preservation check
- Context Writing: Added SPEC PRESERVATION subsection (4 rules: never archive, promote drafts, preserve knowledge, retain spec_ref)
- Notes: Added 2 bullet points about spec persistence

### Supporting: Shaper genie + template
- **File:** `genies/shaper/GENIE.md` — Context Usage updated to include spec reads/writes
- **File:** `genies/shaper/SHAPED_WORK_CONTRACT_TEMPLATE.md` — Added `spec_ref` to template frontmatter

### Sync
- All 7 modified commands synced to `.claude/commands/`

## Coherence Verification

Critic agent verified all 10 files end-to-end:
- **Verdict:** APPROVED
- 4-step spec loading pattern consistent across all 5 consuming commands
- Each command writes to correct spec section (Design Constraints / Implementation Evidence / Review Verdict)
- Only `/discern` updates AC statuses — confirmed in all files
- `/define` standard + standalone modes fully documented
- `/done` never archives specs, promotes drafts as safety net
- SKILL.md accurately mirrors all command behaviors
- 2 minor inconsistencies found and fixed (deliver-tests.md 3-step expanded to 4-step, deliver-implement.md added explicit SPEC LOADING subsection)

## Decisions Made

- Fixed deliver-tests.md and deliver-implement.md spec loading patterns to match the standard 4-step pattern used by all other commands (consistency fix identified by critic)

# Review

## Verdict: APPROVED (after fix)

Initial review returned **CHANGES REQUESTED** with 1 major issue. Issue was fixed and re-verified.

## AC Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | **met** | `commands/define.md` "Spec Lifecycle Behavior" section: Standard Mode (5 steps) — check draft, ask domain, promote/create at `docs/specs/{domain}/{capability}.md` with `status: active`, set `spec_ref`, create domain dir |
| AC-2 | **met** | `commands/define.md` "Standalone Draft Promotion Mode" (5 steps) — input matching `docs/specs/_drafts/*.md`, ask domain, promote, no backlog item. Arguments section declares trigger. Usage example shows standalone invocation. |
| AC-3 | **met** | `commands/design.md` Context Loading reads `spec_ref`, SPEC LOADING (4 steps). SPEC UPDATE appends "## Design Constraints" with dated marker, appends new ACs (never removes), does not change spec status. |
| AC-4 | **met** | `commands/deliver.md` reads `spec_ref`, uses ACs as TDD targets, "Spec-Driven Test Targets" in Phase 1, appends "## Implementation Evidence". `deliver-tests.md` reads spec ACs as test targets. `deliver-implement.md` reads spec, writes Implementation Evidence after GREEN. |
| AC-5 | **met** | `commands/discern.md` reads `spec_ref`, SPEC UPDATE updates AC statuses (`pending` → `met`/`unmet`), appends "## Review Verdict" with verdict table. Checklist item #2 "Spec ACs verified?" |
| AC-6 | **met** | `commands/done.md` SPEC PRESERVATION: never archive spec, promote `draft` → `active` as safety net (ask domain if in `_drafts/`), leave spec with all accumulated knowledge. Notes reinforce. |
| AC-7 | **met** | `SKILL.md` "When Active" lists all 7 commands. Per-command sections with Reads/Writes. Common pattern. Spec Update Rules (6 rules). Frontmatter description updated to trigger on all lifecycle commands. |

## Issues Found and Fixed

| Severity | Issue | Fix |
|----------|-------|-----|
| Major | SKILL.md frontmatter `description` only triggered on 4 commands, missing `/define`, `/design`, `/discern`, `/done` | Updated description to include all 8 lifecycle commands |

## Coherence Checks

- 4-step spec loading pattern consistent across all 5 consuming commands
- Spec body section names match: "Design Constraints", "Implementation Evidence", "Review Verdict"
- Only `/discern` updates AC statuses — confirmed in all files
- All `.claude/commands/` copies match `commands/` originals
- Rabbit holes respected: domain asks user, ACs append-only, warn never block, no discover/commit changes

## Recommendation

APPROVED. Ready for `/commit` then `/done`.

# End of Shaped Work Contract
