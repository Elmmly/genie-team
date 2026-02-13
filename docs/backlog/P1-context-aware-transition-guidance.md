---
spec_version: "1.0"
type: shaped-work
id: GT-30
title: "Context-Aware Transition Guidance"
status: designed
created: "2026-02-13"
appetite: medium
priority: P1
author: shaper
tags: [skills, workflow, guidance, phase-transitions]
acceptance_criteria:
  - id: AC-1
    description: "Awareness skills define a '## Phase Transition Guidance' section with contextual reminders keyed to artifact state"
    status: pending
  - id: AC-2
    description: "brand-awareness injects visual verification reminder during /deliver and /discern when brand guide exists"
    status: pending
  - id: AC-3
    description: "brand-awareness injects workshop artifact reminder during /deliver when docs/brand/assets/*.html files exist"
    status: pending
  - id: AC-4
    description: "brand-awareness injects drift warning during /context:refresh when workshop HTML files are older than the brand guide"
    status: pending
  - id: AC-5
    description: "spec-awareness injects spec-delta reminder during /deliver when backlog item has behavioral delta section"
    status: pending
  - id: AC-6
    description: "architecture-awareness injects ADR compliance reminder during /deliver when backlog item has adr_refs"
    status: pending
  - id: AC-7
    description: "/handoff output includes domain-specific guidance section populated by active awareness skills"
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

# Design

## Overview

Add a `## Phase Transition Guidance` section to each awareness skill that emits contextual process reminders based on detected artifact state. Extend `/handoff` to collect and present these reminders. All changes are prompt engineering — editing existing `.md` skill and command files.

## Architecture

**Pattern: Conditional guidance injection.** Each awareness skill already has per-command behavior sections ("During /deliver", "During /discern", etc.). The design adds guidance steps to existing behavior sections — not new sections, but new numbered steps appended to existing ones. Guidance steps follow the same conditional pattern as data injection: detect artifact → emit reminder → silently skip if absent.

**Zero-cost guarantee:** Every guidance step is gated by an artifact detection condition (file exists, frontmatter field present, timestamp comparison). If the condition is false, nothing is emitted.

## Component Design

### 1. brand-awareness skill — `SKILL.md`

**Modify: "During /deliver" section (L164-183)**

Append after step 4:

```markdown
5. **Transition guidance** (conditional):
   a. If `docs/brand/assets/*.html` workshop files exist:
      > **Visual reference:** Workshop preview artifacts exist at docs/brand/assets/*.html — review these for visual intent (accent colors, signature elements) that may not be captured in the YAML brand guide.
   b. If brand guide has `status: active` and work touches CSS/theme/style files:
      > **Visual verification recommended:** This work affects visual appearance. Before marking complete, verify the rendered UI matches the brand guide's visual intent (not just hex values).
```

**Modify: "During /discern" section (L185-206)**

Append after step 4:

```markdown
5. **Transition guidance** (conditional):
   a. If work touched CSS/theme/style files:
      > **Visual evidence:** This review covers brand-related visual changes. Consider requesting a screenshot or dev server inspection to verify rendered appearance matches brand intent — hex-value compliance alone may miss visual issues.
```

**Modify: "During /context:load" section (L208-221)**

Append to step 2 (when brand guide found):

```markdown
   > Workshop artifacts: {count} HTML preview files in docs/brand/assets/ ({list filenames})
```

**Modify: "During /context:refresh" section (L223-237)**

Append after step 2d:

```markdown
   e. Check `docs/brand/assets/*.html` modification dates against brand guide `updated` date
   f. If any HTML files are older than the brand guide:
      > Workshop preview artifacts may be stale (pre-date brand guide update). Visual references in these files may not reflect current brand values.
```

### 2. spec-awareness skill — `SKILL.md`

**Modify: "During /deliver" section**

Append after the existing implementation evidence step:

```markdown
   **Transition guidance** (conditional):
   a. If backlog item contains a "## Behavioral Delta" section:
      > **Spec delta active:** This work modifies existing spec behavior. Verify that the implementation matches the proposed changes in the Behavioral Delta section, not just the original spec ACs.
   b. If `spec_ref` exists and spec has ACs with `status: met`:
      > **Regression watch:** Some spec ACs are already met. Verify the implementation doesn't regress previously passing criteria.
```

### 3. architecture-awareness skill — `SKILL.md`

**Modify: "During /deliver" section** (or add one if it doesn't exist for /deliver)

```markdown
### During /deliver

Surfaces ADR compliance context:

1. Check for `adr_refs` in backlog item frontmatter
2. If `adr_refs` present: Load each referenced ADR
3. Surface the Decision section from each accepted ADR as implementation context:
   > **ADR context:** ADR-{NNN} — {title}. Decision: {1-sentence summary}
4. **Transition guidance** (conditional):
   a. If `adr_refs` exist:
      > **ADR compliance:** This work references {N} architecture decision(s). During implementation, ensure the approach aligns with each accepted decision. Violations will be flagged during /discern review.
```

### 4. `/handoff` command — `handoff.md`

**Modify: Output Format section (L35-51)**

Add a `## Domain-Specific Guidance` section to the handoff template:

```markdown
**Domain-Specific Guidance:**
{Collected from active awareness skills. Each skill that detects relevant artifacts contributes 0-2 reminders. If no skill has guidance, this section is omitted.}
```

**Modify: Each transition template** (discover→define, define→design, design→deliver, deliver→discern)

Add to the `design → deliver` handoff template specifically:

```markdown
**For Crafter (domain context):**
- {brand-awareness guidance if brand guide exists}
- {spec-awareness guidance if behavioral delta exists}
- {architecture-awareness guidance if adr_refs exist}
```

Add to the `deliver → discern` handoff template:

```markdown
**For Critic (domain context):**
- {brand-awareness guidance if visual work}
- {spec-awareness guidance if spec delta}
- {architecture-awareness guidance if ADR compliance needed}
```

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Each skill gets guidance steps in existing per-command behavior sections, gated by artifact detection | `.claude/skills/*/SKILL.md` |
| AC-2 | brand-awareness /deliver step 5b, /discern step 5a | `.claude/skills/brand-awareness/SKILL.md` |
| AC-3 | brand-awareness /deliver step 5a — glob `docs/brand/assets/*.html` | `.claude/skills/brand-awareness/SKILL.md` |
| AC-4 | brand-awareness /context:refresh step 2e-2f — timestamp comparison | `.claude/skills/brand-awareness/SKILL.md` |
| AC-5 | spec-awareness /deliver guidance step a — detect "## Behavioral Delta" in backlog body | `.claude/skills/spec-awareness/SKILL.md` |
| AC-6 | architecture-awareness /deliver guidance step a — detect `adr_refs` in frontmatter | `.claude/skills/architecture-awareness/SKILL.md` |
| AC-7 | /handoff template adds "Domain-Specific Guidance" section for design→deliver and deliver→discern | `.claude/commands/handoff.md` |
| AC-8 | All guidance is gated by condition (file exists, field present). No condition → no output. | All modified files |

## Implementation Guidance

**Sequence:**
1. brand-awareness SKILL.md — largest change, most guidance points
2. spec-awareness SKILL.md — smaller change, 2 guidance points
3. architecture-awareness SKILL.md — add /deliver section with guidance
4. handoff.md — add domain-specific guidance to transition templates

**Key considerations:**
- Guidance text must be concise (1-2 sentences) — not paragraphs
- Use blockquote format (`>`) consistent with existing skill output patterns
- Prefix each guidance with a bold label (e.g., **Visual reference:**, **Spec delta active:**) for scannability
- All conditions use artifact detection the skill already performs — no new scanning logic

**Test strategy:**
- Run `/deliver` on a project with brand guide → verify visual verification reminder appears
- Run `/deliver` on a project without brand guide → verify no guidance appears (zero-cost)
- Run `/context:refresh` on a project with stale workshop HTMLs → verify staleness warning
- Run `/handoff design deliver` on brand work → verify domain-specific guidance in handoff output

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Guidance noise fatigue | Low | Med | All guidance is conditional on artifact state; zero-cost default. Keep to 1-2 sentences max. |
| Operators ignore guidance | Med | Low | Advisory only — the goal is reducing rework, not gating. Even partial adoption helps. |
| Guidance text becomes stale as skills evolve | Low | Low | Guidance is co-located with the behavior it augments — edits to behavior naturally prompt guidance review. |

## Routing

Ready for Crafter. No architectural unknowns — all changes are additive prompt engineering in existing files.
