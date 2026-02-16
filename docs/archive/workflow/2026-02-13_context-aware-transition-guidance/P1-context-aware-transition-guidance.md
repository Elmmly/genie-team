---
spec_version: "1.0"
type: shaped-work
id: GT-30
title: "Context-Aware Transition Guidance"
status: done
verdict: APPROVED
created: "2026-02-13"
appetite: medium
priority: P1
author: shaper
tags: [skills, workflow, guidance, phase-transitions]
acceptance_criteria:
  - id: AC-1
    description: "Awareness skills append a numbered 'Transition guidance' step to existing per-command behavior sections, gated by artifact state"
    status: pending
  - id: AC-2
    description: "brand-awareness injects visual verification reminder during /deliver and /discern when brand guide exists"
    status: pending
  - id: AC-3
    description: "brand-awareness injects asset review reminder during /deliver when docs/brand/assets/manifest.md has entries"
    status: pending
  - id: AC-4
    description: "brand-awareness injects asset staleness warning during /context:refresh when manifest entries predate the brand guide updated date"
    status: pending
  - id: AC-5
    description: "spec-awareness injects spec-delta reminder during /deliver when backlog item has behavioral delta section"
    status: pending
  - id: AC-6
    description: "architecture-awareness injects ADR compliance reminder during /deliver when backlog item has adr_refs"
    status: pending
  - id: AC-7
    description: "/handoff activates awareness skills via trigger list; each skill has a 'During /handoff' section that injects domain-specific guidance into the handoff output"
    status: pending
  - id: AC-8
    description: "Guidance is additive — skills that detect no relevant artifacts inject nothing (zero overhead)"
    status: pending
---

# Shaped Work Contract: Context-Aware Transition Guidance

## Problem

Awareness skills (brand-awareness, spec-awareness, architecture-awareness) have domain knowledge and activate at phase boundaries, but they only surface data — never process guidance. When an operator follows the prescribed workflow through design-heavy work, the system doesn't tell them what extra steps this type of work requires. Every pain point in the field report traced back to the operator correctly following the workflow while the tooling failed to suggest appropriate next steps.

The gap is between "knowing what artifacts exist" (which skills already do) and "suggesting what to do about them" (which nothing does). The `/handoff` command summarizes what was done but doesn't inject domain-specific guidance.

**Evidence:** Field report (Feb 2026) — 2 follow-up fix contracts (4 visual issues) resulted from the operator not being reminded to visually verify CSS-heavy work or reference workshop HTML artifacts during implementation. The brand-awareness skill activated during `/deliver` and `/discern` but only surfaced hex values, not process reminders.

## Appetite & Boundaries

- **Appetite:** Medium (3-5 days)
- **In scope:** Adding `## Phase Transition Guidance` sections to brand-awareness, spec-awareness, and architecture-awareness skills. Extending `/handoff` to collect and present skill-injected guidance.
- **No-gos:** No new commands. No new skills. No changes to command flow or gating (guidance is advisory, not blocking). No automated screenshot capture or visual diff tooling.
- **Fixed elements:** Existing skill activation points remain unchanged. Guidance must be zero-cost when artifacts don't exist.

## Goals & Outcomes

- Operators receive contextual reminders at phase transitions based on what the system knows about the work type
- Reduce rework from missed context (workshop artifacts, visual verification, spec deltas)
- Generalize the pattern so future awareness skills can inject guidance without modifying commands

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Operators will read and act on transition reminders | usability | Run a brand workflow end-to-end with guidance enabled; check if operator verifies visual output |
| Skills can detect artifact state reliably (e.g., HTML files exist, timestamps) | feasibility | Test `docs/brand/assets/*.html` glob detection in brand-awareness |
| Guidance won't create noise fatigue | usability | Confirm guidance only appears when artifacts are detected (zero-cost default) |

## Options

| Option | Pros | Cons | Recommendation |
|--------|------|------|----------------|
| A: Add guidance sections to each skill independently | Simple, no coordination needed | `/handoff` doesn't benefit; guidance only shows within commands | Start here |
| B: Add guidance sections to skills + `/handoff` collects them | Full transition coverage; handoff becomes context-aware | Slightly more complex; handoff needs to invoke skill guidance | Target state |
| C: Create a new `transition-guidance` meta-skill | Clean separation | Over-engineering; duplicates detection logic already in awareness skills | Not recommended |

**Recommendation:** Implement Option A first (skill-level guidance), extend to Option B (handoff integration) within the same contract.

## Routing

- [x] **Ready for design** — No architectural unknowns; this is prompt engineering in existing skill files
- [ ] Needs Architect spike

**Next:** `/deliver docs/backlog/P1-context-aware-transition-guidance.md`

---

# Design (Revision 2 — 2026-02-13)

## Revision Summary

Revision 2 fixes 6 issues found during pre-implementation review of the original design:

1. **AC-1 text mismatch** — AC said "## Phase Transition Guidance section" but the approach uses inline numbered steps. AC-1 updated to match the actual approach.
2. **Workshop HTML files don't exist** — AC-3/AC-4 referenced `docs/brand/assets/*.html` but the brand system only produces `*.png / *.jpg` files with a `manifest.md` catalog. ACs updated to reference real artifact types (manifest entries, asset images).
3. **Handoff guidance mechanism gap** — `/handoff` was not in any skill's activation triggers, so skills couldn't inject guidance into handoff output. Fixed: each skill adds `/handoff` to its activation list and defines a "During /handoff" behavior section.
4. **architecture-awareness /deliver: replace vs. append** — Original design appeared to replace the existing `/deliver` section (L212-224) which has useful violation warnings. Fixed: design explicitly appends a step 5 to the existing 4 steps.
5. **Inconsistent guidance formatting** — Different skills used different numbering patterns. Fixed: all skills use the same pattern (numbered step appended after the last existing step, with conditional sub-items a/b).
6. **Timestamp comparison mechanism** — Original design required file system `stat` for HTML timestamps. Fixed: staleness comparison now uses manifest entry dates (readable via Read tool) vs. brand guide `updated` frontmatter field. No Bash needed.

## Overview

Append a numbered **Transition guidance** step to existing per-command behavior sections in each awareness skill. Add `/handoff` to each skill's activation triggers with a "During /handoff" section. All changes are prompt engineering — editing existing `.md` skill and command files.

## Architecture

**Pattern: Conditional guidance injection.** Each awareness skill already has per-command behavior sections ("During /deliver", "During /discern", etc.). The design appends one numbered step to each relevant section. Guidance steps follow the same conditional pattern as data injection: detect artifact → emit reminder → silently skip if absent.

**Consistent format across all skills:**
```markdown
{N}. **Transition guidance** (conditional):
   a. If {condition}:
      > **{Bold label}:** {1-2 sentence reminder}
   b. If {condition}:
      > **{Bold label}:** {1-2 sentence reminder}
```

Where `{N}` is the next step number after the existing steps in that behavior section.

**Zero-cost guarantee:** Every guidance sub-item is gated by an artifact detection condition (file exists, frontmatter field present, date comparison in readable content). If the condition is false, nothing is emitted.

## Component Design

### 1. brand-awareness skill — `.claude/skills/brand-awareness/SKILL.md`

**Modify: `description` field in YAML frontmatter (L3)**

Add `/handoff` to the activation trigger list:
```yaml
description: "Ensures brand-consistent behavior during workflows. Auto-activates when brand guide exists and \"brand\", \"brand spec\", \"design tokens\", \"brand consistent\", or \"visual identity\" are mentioned. Activates during /brand, /brand:image, /brand:tokens, /design, /deliver, /discern, /handoff, /context:load, and /context:refresh."
```

**Modify: "When Active" list (L60-68)**

Add `/handoff` entry:
```markdown
- `/handoff` — Inject brand-specific transition guidance into handoff output
```

**Modify: "During /deliver" section (L164-183)**

The existing section has 4 steps (load → surface → reference → silent skip). Append step 5:

```markdown
5. **Transition guidance** (conditional):
   a. If `docs/brand/assets/manifest.md` has entries:
      > **Brand assets available:** Generated brand images exist in docs/brand/assets/ — review the manifest for visual references (color palettes, signature elements, mood boards) that capture intent beyond what the YAML brand guide encodes.
   b. If brand guide has `status: active` and work touches CSS/theme/style files:
      > **Visual verification recommended:** This work affects visual appearance. Before marking complete, verify the rendered UI matches the brand guide's visual intent (not just hex values).
```

**Modify: "During /discern" section (L185-206)**

The existing section has 4 steps. Append step 5:

```markdown
5. **Transition guidance** (conditional):
   a. If work touched CSS/theme/style files:
      > **Visual evidence:** This review covers brand-related visual changes. Consider requesting a screenshot or dev server inspection to verify rendered appearance matches brand intent — hex-value compliance alone may miss visual issues.
```

**Modify: "During /context:load" section (L208-221)**

Append to step 2 output (when brand guide found), after the existing three `>` lines:

```markdown
   > Brand assets: {count} entries in docs/brand/assets/manifest.md
```

**Modify: "During /context:refresh" section (L223-237)**

The existing section has steps through 2d. Append after step 2d:

```markdown
   e. Read `docs/brand/assets/manifest.md` for entry dates
   f. If any manifest entries have dates older than the brand guide `updated` field:
      > Brand asset images may be stale (generated before latest brand guide update). Visual references in these images may not reflect current brand values. Regenerate with /brand:image if needed.
```

**Add: "During /handoff" section**

Insert new behavior section after "During /context:refresh" (before "## Brand Update Rules"):

```markdown
### During /handoff

Injects brand-specific transition guidance into handoff output:

1. Load brand guide via common pattern
2. If brand guide found:
   a. For `design → deliver` handoff:
      > **Brand context for Crafter:** Brand guide active at docs/brand/{name}.md. Design tokens at docs/brand/tokens.json. {If manifest has entries: "Review docs/brand/assets/manifest.md for visual reference images."}
   b. For `deliver → discern` handoff:
      > **Brand context for Critic:** {If work touched CSS/theme/style files: "Visual changes present — verify rendered appearance, not just token compliance."}
3. If no brand guide: Silently continue (no guidance injected)
```

### 2. spec-awareness skill — `.claude/skills/spec-awareness/SKILL.md`

**Modify: `description` field in YAML frontmatter (L3)**

Add `/handoff` to the activation trigger list:
```yaml
description: "Ensures spec-driven behavior during all workflows. Use when loading context, discussing project structure, starting features, or when \"spec\", \"specification\", \"acceptance criteria\", or \"bootstrap\" are mentioned. Activates during /context:load, /context:refresh, /spec:init, /define, /design, /deliver, /discern, /handoff, /done, and /discover."
```

**Modify: "When Active" list (L62-71)**

Add `/handoff` entry:
```markdown
- `/handoff` — Inject spec-specific transition guidance into handoff output
```

**Modify: "During /deliver" section (L135-146)**

The existing section has 5 steps (load → TDD targets → reference AC ids → implementation evidence → don't update statuses). Append step 6:

```markdown
6. **Transition guidance** (conditional):
   a. If backlog item body contains a "## Behavioral Delta" or "**Current Behavior:**" section:
      > **Spec delta active:** This work modifies existing spec behavior. Verify that the implementation matches the proposed changes in the Behavioral Delta section, not just the original spec ACs.
   b. If spec has ACs with `status: met`:
      > **Regression watch:** Some spec ACs are already met. Verify the implementation doesn't regress previously passing criteria.
```

**Add: "During /handoff" section**

Insert new behavior section after "During /done" (before "### During /discover"):

```markdown
### During /handoff

Injects spec-specific transition guidance into handoff output:

1. Load spec via `spec_ref` (using common pattern)
2. If spec loaded:
   a. For `design → deliver` handoff:
      > **Spec context for Crafter:** Spec at {spec_ref} has {N} acceptance criteria ({M} pending). {If backlog has Behavioral Delta: "Behavioral delta exists — implementation must match proposed changes, not just original ACs."}
   b. For `deliver → discern` handoff:
      > **Spec context for Critic:** {If spec has ACs with status: met: "Some ACs were previously met — check for regressions."} {If backlog has Behavioral Delta: "Spec delta — verify both old and new behavior."}
3. If no spec: Silently continue (no guidance injected)
```

### 3. architecture-awareness skill — `.claude/skills/architecture-awareness/SKILL.md`

**Modify: `description` field in YAML frontmatter (L3)**

Add `/handoff` to the activation trigger list:
```yaml
description: "Ensures ADR and C4 diagram behaviors during all workflows. Use when loading context, discussing architecture, creating designs, or when \"ADR\", \"architecture decision\", \"C4\", \"coupling\", \"cohesion\", or \"boundary\" are mentioned. Activates during /arch:init, /context:load, /context:refresh, /spec:init, /define, /design, /deliver, /discern, /handoff, /diagnose, and /discover."
```

**Modify: "When Active" list (L133-145)**

Add `/handoff` entry:
```markdown
- `/handoff` — Inject ADR-specific transition guidance into handoff output
```

**Modify: "During /deliver" section (L212-224)**

The existing section has 4 steps (load ADRs → surface decisions → reference ids → warn on violation). Append step 5:

```markdown
5. **Transition guidance** (conditional):
   a. If `adr_refs` exist in backlog item frontmatter:
      > **ADR compliance:** This work references {N} architecture decision(s). Ensure the approach aligns with each accepted decision. Violations will be flagged during /discern review.
```

**Add: "During /handoff" section**

Insert new behavior section after "During /discover" (before "### During /context:load"):

```markdown
### During /handoff

Injects ADR-specific transition guidance into handoff output:

1. Load ADRs via common pattern
2. If ADRs found relevant to the work:
   a. For `design → deliver` handoff:
      > **ADR context for Crafter:** {N} architecture decision(s) constrain this work: {list ADR ids + 1-line summaries}. Implementation must align with these decisions.
   b. For `deliver → discern` handoff:
      > **ADR context for Critic:** {If adr_refs exist: "Verify ADR compliance for: {list ADR ids}. Check for boundary violations."}
3. If no ADRs: Silently continue (no guidance injected)
```

### 4. `/handoff` command — `.claude/commands/handoff.md`

**Modify: Output Format template (L35-51)**

Add a `**Domain-Specific Guidance:**` section to the base template, after `**Recommended next:**`:

```markdown
**Domain-Specific Guidance:**
{Each active awareness skill that detects relevant artifacts contributes 1-2 contextual reminders here. Skills activate via their "During /handoff" behavior sections. If no skill has guidance, omit this section entirely.}
```

**Modify: `design → deliver` handoff template (L101-118)**

Add domain guidance block after the existing "**For Crafter:**" bullet list:

```markdown
**For Crafter (domain context):**
{brand-awareness /handoff guidance — if brand guide exists}
{spec-awareness /handoff guidance — if spec_ref exists}
{architecture-awareness /handoff guidance — if adr_refs exist}
{Omit this section if no awareness skill has guidance}
```

**Modify: `deliver → discern` handoff template (L120-138)**

Add domain guidance block after the existing "**For Critic:**" bullet list:

```markdown
**For Critic (domain context):**
{brand-awareness /handoff guidance — if visual work}
{spec-awareness /handoff guidance — if spec delta or regressions}
{architecture-awareness /handoff guidance — if ADR compliance needed}
{Omit this section if no awareness skill has guidance}
```

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Each skill appends a numbered "Transition guidance" step to existing behavior sections, using consistent `{N}. **Transition guidance** (conditional):` format with sub-items a/b | All 3 skill SKILL.md files |
| AC-2 | brand-awareness /deliver step 5b (visual verification when CSS work + active brand guide), /discern step 5a (visual evidence when CSS work) | `.claude/skills/brand-awareness/SKILL.md` |
| AC-3 | brand-awareness /deliver step 5a — reads `docs/brand/assets/manifest.md` for entries | `.claude/skills/brand-awareness/SKILL.md` |
| AC-4 | brand-awareness /context:refresh steps 2e-2f — compares manifest entry dates (from file content) against brand guide `updated` frontmatter field | `.claude/skills/brand-awareness/SKILL.md` |
| AC-5 | spec-awareness /deliver step 6a — detects "## Behavioral Delta" or "**Current Behavior:**" in backlog body | `.claude/skills/spec-awareness/SKILL.md` |
| AC-6 | architecture-awareness /deliver step 5a — detects `adr_refs` in backlog frontmatter | `.claude/skills/architecture-awareness/SKILL.md` |
| AC-7 | Each skill adds `/handoff` to activation triggers + defines "During /handoff" behavior section. `/handoff` template adds "Domain-Specific Guidance" placeholders. | All 3 SKILL.md files + `.claude/commands/handoff.md` |
| AC-8 | All guidance is gated by condition (file exists, field present, manifest has entries). No condition → no output. | All modified files |

## Implementation Guidance

**Sequence:**
1. brand-awareness SKILL.md — largest change (frontmatter, "When Active", 4 behavior sections + 1 new section)
2. spec-awareness SKILL.md — medium change (frontmatter, "When Active", 1 behavior section + 1 new section)
3. architecture-awareness SKILL.md — small change (frontmatter, "When Active", 1 behavior section + 1 new section)
4. handoff.md — small change (base template + 2 transition templates)

**Key considerations:**
- Guidance text must be concise (1-2 sentences) — not paragraphs
- Use blockquote format (`>`) consistent with existing skill output patterns
- Prefix each guidance with a bold label (e.g., **Brand assets available:**, **Spec delta active:**) for scannability
- All conditions use artifact detection the skill already performs — no new scanning logic
- The "During /handoff" sections follow the same pattern as other "During /{command}" sections in each skill
- Manifest date comparison reads content (markdown text), not file system timestamps

**Test strategy:**
- Run `/deliver` on a project with brand guide + manifest entries → verify asset review reminder appears
- Run `/deliver` on a project without brand guide → verify no guidance appears (zero-cost)
- Run `/deliver` on a project with behavioral delta in backlog → verify spec delta reminder
- Run `/deliver` on a project with `adr_refs` → verify ADR compliance reminder
- Run `/context:refresh` on a project with old manifest entries → verify staleness warning
- Run `/handoff design deliver` on brand work → verify domain-specific guidance in handoff output
- Run `/handoff design deliver` on plain work (no brand/spec/ADR) → verify no guidance section

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Guidance noise fatigue | Low | Med | All guidance is conditional on artifact state; zero-cost default. Keep to 1-2 sentences max. |
| Operators ignore guidance | Med | Low | Advisory only — the goal is reducing rework, not gating. Even partial adoption helps. |
| Guidance text becomes stale as skills evolve | Low | Low | Guidance is co-located with the behavior it augments — edits to behavior naturally prompt guidance review. |
| Skills may not activate during /handoff if keyword matching is imprecise | Low | Med | Explicit `/handoff` in skill description trigger list. Test with `/handoff design deliver` to verify activation. |

## Routing

Ready for Crafter. No architectural unknowns — all changes are additive prompt engineering in existing files.

---

# Implementation

## Summary

Implemented context-aware transition guidance across all 3 awareness skills and the `/handoff` command. All changes are additive prompt engineering — appending numbered transition guidance steps to existing behavior sections and adding new "During /handoff" sections.

## Changes

### Files Modified

| File | Changes |
|------|---------|
| `.claude/skills/brand-awareness/SKILL.md` | Frontmatter: added `/handoff` trigger. "When Active" list: added `/handoff` entry. `/deliver`: appended step 5 (asset review + visual verification). `/discern`: appended step 5 (visual evidence). `/context:refresh`: appended steps 2e-2f (manifest staleness). New "During /handoff" section. |
| `.claude/skills/spec-awareness/SKILL.md` | Frontmatter: added `/handoff` trigger. "When Active" list: added `/handoff` entry. `/deliver`: appended step 6 (spec delta + regression watch). New "During /handoff" section. |
| `.claude/skills/architecture-awareness/SKILL.md` | Frontmatter: added `/handoff` trigger. "When Active" list: added `/handoff` entry. `/deliver`: appended step 5 (ADR compliance). New "During /handoff" section. |
| `.claude/commands/handoff.md` | Base template: added "Domain-Specific Guidance" section. `design → deliver` template: added "For Crafter (domain context)" block. `deliver → discern` template: added "For Critic (domain context)" block. |

### Files Created

| File | Purpose |
|------|---------|
| `tests/test_transition_guidance.sh` | 34 structural validation tests covering all 8 ACs |

## Test Results

```
Results: 34/34 passed, 0 failed (transition guidance)
Results: 47/47 passed, 0 failed (precommit regression check)
```

## AC Evidence

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | All 3 skills use consistent `{N}. **Transition guidance** (conditional):` format with sub-items a/b |
| AC-2 | met | brand-awareness `/deliver` step 5b (**Visual verification recommended:**), `/discern` step 5a (**Visual evidence:**) |
| AC-3 | met | brand-awareness `/deliver` step 5a checks `docs/brand/assets/manifest.md` for entries |
| AC-4 | met | brand-awareness `/context:refresh` steps 2e-2f compare manifest entry dates vs brand guide `updated` field |
| AC-5 | met | spec-awareness `/deliver` step 6a detects "## Behavioral Delta" / "**Current Behavior:**" sections |
| AC-6 | met | architecture-awareness `/deliver` step 5a detects `adr_refs` in backlog frontmatter |
| AC-7 | met | All 3 skills add `/handoff` to triggers + define "During /handoff" sections. Handoff template has domain guidance blocks. |
| AC-8 | met | All guidance gated by conditions. Each /handoff section has "Silently continue (no guidance injected)" guard. |

## Routing

Ready for review: `/discern docs/backlog/P1-context-aware-transition-guidance.md`

---

# Review

## Summary

Clean implementation of context-aware transition guidance across all 3 awareness skills and the handoff command. All changes are additive prompt engineering — no existing behavior was modified or removed, only appended to. The revised design correctly addressed the 6 issues found in the pre-implementation review. Test coverage is structural and appropriate for a prompt engineering project.

## Acceptance Criteria

| AC | Verdict | Evidence |
|----|---------|----------|
| AC-1 | **PASS** | All 3 skills use consistent `{N}. **Transition guidance** (conditional):` numbered step format with sub-items a/b. Verified at: brand-awareness L182, spec-awareness L145, architecture-awareness L223. |
| AC-2 | **PASS** | brand-awareness `/deliver` step 5b emits `**Visual verification recommended:**` when `status: active` and CSS work. `/discern` step 5a emits `**Visual evidence:**` when CSS work. Both correctly gated. |
| AC-3 | **PASS** | brand-awareness `/deliver` step 5a checks `docs/brand/assets/manifest.md` for entries, emits `**Brand assets available:**`. Correctly uses manifest (not HTML files, which don't exist). |
| AC-4 | **PASS** | brand-awareness `/context:refresh` steps 2e-2f read manifest entry dates and compare against brand guide `updated` field. Uses Read-accessible content, not file system timestamps. |
| AC-5 | **PASS** | spec-awareness `/deliver` step 6a detects `## Behavioral Delta` or `**Current Behavior:**` in backlog body. Step 6b detects ACs with `status: met` for regression watch. |
| AC-6 | **PASS** | architecture-awareness `/deliver` step 5a checks `adr_refs` in backlog frontmatter. Emits `**ADR compliance:**` with decision count. |
| AC-7 | **PASS** | All 3 skills: (1) added `/handoff` to frontmatter description trigger, (2) added `/handoff` to "When Active" list, (3) defined "During /handoff" behavior section with phase-specific guidance. Handoff command: base template has "Domain-Specific Guidance" section; design→deliver and deliver→discern templates have "(domain context)" blocks. |
| AC-8 | **PASS** | All transition guidance is gated by artifact detection conditions. All /handoff sections end with "Silently continue (no guidance injected)" for the no-artifact case. Zero overhead when artifacts don't exist. |

**Result: 8/8 PASS**

## Code Quality

### Strengths
- Consistent formatting pattern across all 3 skills — easy to extend to future awareness skills
- Guidance text is concise (1-2 sentences per reminder, as specified)
- Bold labels (`**Visual verification recommended:**`, `**Spec delta active:**`, `**ADR compliance:**`) provide scannability
- Existing behavior sections were appended to, never modified — preserves all previous functionality
- New "During /handoff" sections follow the exact same structural pattern as other "During /{command}" sections

### Issues Found

| Issue | Severity | Location | Fix |
|-------|----------|----------|-----|
| None | — | — | — |

No critical, major, or minor issues found.

## Test Coverage

- **Structural tests:** 34/34 passing — cover all 8 ACs plus section ordering and "When Active" list presence
- **Regression tests:** 47/47 passing — existing precommit validation tests unaffected
- **Coverage gap:** No negative test (e.g., "skill file without /handoff should fail"). Acceptable for prompt engineering — the tests validate presence of expected content, which is the primary risk.

## Pattern Adherence

- [x] Follows project conventions (skills use `### During /{command}` pattern)
- [x] Uses established patterns (conditional blockquote guidance format)
- [x] No hardcoded values
- [x] Error handling in place (all guidance is conditional with silent-skip defaults)
- [x] Tests cover key scenarios

## Security Review

Not applicable — changes are prompt engineering (markdown content), no executable code or data handling.

## Risk Assessment

| Risk | L | I | Status |
|------|---|---|--------|
| Guidance noise fatigue | Low | Med | **Addressed** — all guidance conditional on artifact state |
| Skills may not activate during /handoff | Low | Med | **Addressed** — `/handoff` explicitly in all 3 skill description trigger lists |
| Manifest date comparison mechanism | Low | Low | **Addressed** — reads content dates (not file stat), uses Read tool |

## Verdict

**Decision: APPROVED**

All 8 acceptance criteria met. Implementation is clean, additive, and follows established patterns. No issues found. The pre-implementation design review caught and resolved all 6 correctness issues before any code was written — good process discipline.

## Routing

Ready for `/commit` and then `/done`.
