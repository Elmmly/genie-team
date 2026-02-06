---
spec_version: "1.0"
type: shaped-work
id: workshop-mode
title: "Interactive Workshop Mode for Shaper and Architect Genies"
status: implemented
created: 2026-02-05
appetite: medium
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [shaper, architect, workshop, interactive, decisions]
acceptance_criteria:
  - id: AC-1
    description: "/define produces an HTML appetite explorer showing what fits in small/medium/big batches with concrete scope tradeoffs the user can see and adjust"
    status: met
  - id: AC-2
    description: "/define walks through option generation interactively — presenting 2-3 solution sketches with tradeoff summaries, user picks direction before full contract is written"
    status: met
  - id: AC-3
    description: "/define --workshop flag activates full interactive mode; without flag, batch mode is preserved as default"
    status: met
  - id: AC-4
    description: "/design produces an HTML architecture comparison showing 2-3 approaches with pros/cons/complexity/risk before committing to one"
    status: met
  - id: AC-5
    description: "/design walks through technical decisions interactively — each decision in the decisions table is presented as options before the choice is locked in"
    status: met
  - id: AC-6
    description: "/design --workshop flag activates full interactive mode; without flag, batch mode is preserved as default"
    status: met
  - id: AC-7
    description: "Workshop phases use HTML artifacts (like Designer Phase 2-3) for decisions that benefit from visual comparison, and AskUserQuestion for simpler choices"
    status: met
  - id: AC-8
    description: "Existing batch-mode behavior is fully preserved — workshop mode is additive, not replacing"
    status: met
---

# Shaped Work Contract: Interactive Workshop Mode for Shaper and Architect

**Date:** 2026-02-05
**Shaper:** Problem shaping
**Input:** User observation from running `/brand` workshop — visual, interactive decision-making is far more effective than reading finished documents with decisions already made.

---

## 1. Problem / Opportunity Statement

**Reframed as problem:** The Shaper and Architect genies make dozens of autonomous decisions (appetite sizing, option ranking, pattern selection, component boundaries, implementation sequencing) and present them as a finished document. The user only gets to react *after* the decisions are already baked in. This creates two failure modes:

1. **Unstated assumptions** — The genie makes a judgment call the user would disagree with, but it's buried in a complete document and easy to miss
2. **Undeveloped decisions** — Options that could benefit from user input (appetite tradeoffs, architecture approaches, risk priorities) are decided autonomously when the user has valuable context

**Evidence from Designer workshop:**
- The `/brand` workshop's interactive phases (colors, typography, imagery) produced significantly better outcomes than a batch "here's your brand guide" approach
- Showing visual options and letting the user react → better alignment than describing options in text
- HTML artifacts for colors/typography were more effective than text descriptions or even image generation for data-display decisions

**Key insight:** Not every decision needs a workshop. Many Shaper/Architect decisions are straightforward and benefit from speed (batch mode). But **high-impact, multi-option decisions** — where the user has context the genie doesn't — benefit from the workshop pattern.

---

## 2. Evidence & Insights

- **From Designer delivery:** Workshop phases with HTML artifacts and iteration loops produced better brand decisions than batch output
- **From workflow observation:** Users often accept Shaper appetite/Architect pattern choices without reviewing them critically, then discover misalignment during `/deliver` or `/discern`
- **JTBD:**
  - Primary: "When I'm shaping work, I want to see the tradeoffs between small/medium/big appetite so I can make an informed scope decision, not just accept whatever the Shaper chose."
  - Secondary: "When designing architecture, I want to see 2-3 approaches compared visually before committing to one, especially for decisions that are hard to reverse."

---

## 3. Strategic Alignment

- Follows the "show, don't tell" principle proven by the Designer genie
- Follows ADR-001 Thin Orchestrator: additive, opt-in, no breaking changes
- Workshop mode is opt-in (`--workshop` flag) — batch mode remains the default
- Builds on the HTML artifact pattern established by `/brand` Phase 2-3

---

## 4. Appetite (Scope Box)

- **Appetite:** Medium batch (1-2 weeks)
  - Known patterns: follows Designer workshop model exactly
  - HTML artifact approach is proven (palette-options.html, typography-preview.html)
  - Two genies to enhance, but the workshop phases are conceptually similar

- **Boundaries (in scope):**
  - `--workshop` flag for `/define` and `/design` commands
  - Shaper workshop: appetite explorer (HTML) + option comparison (HTML) + interactive scope negotiation
  - Architect workshop: architecture comparison (HTML) + technical decision walkthrough + risk prioritization
  - HTML artifacts written to scratchpad (not persisted in docs/ — these are session artifacts, not brand assets)

- **No-gos (out of scope):**
  - Changing batch-mode behavior — existing `/define` and `/design` without `--workshop` must work identically
  - Adding workshops to other genies (Crafter, Critic, Tidier)
  - Image generation for Shaper/Architect workshops (HTML is sufficient for decision comparison)
  - Modifying the GENIE.md/SPEC.md/SYSTEM_PROMPT.md files — workshop behavior lives in the command files only

- **Fixed elements:**
  - `--workshop` flag is opt-in, not default
  - HTML artifacts are session-scoped (scratchpad or temp), not persisted to docs/brand/
  - Final output is still the same Shaped Work Contract (Shaper) or Design Document (Architect)
  - Workshop phases don't change what's produced, only how decisions are made along the way

---

## 5. Solution Sketch

### Shaper Workshop Phases (`/define --workshop`)

| Phase | Decision Being Made | Output Method | Current (Batch) |
|-------|-------------------|---------------|-----------------|
| 1. Problem Framing | Is this the right problem? | AskUserQuestion — present 2-3 problem reframings, user picks | Shaper picks best reframing autonomously |
| 2. Appetite Explorer | What fits in small vs medium vs big? | HTML file showing 3 columns with concrete scope items in each tier | Shaper picks appetite autonomously |
| 3. Option Exploration | Which solution direction? | HTML file showing 2-3 options with tradeoff matrix (effort, risk, alignment, dependencies) | Shaper ranks options, recommends top pick |
| 4. Scope Negotiation | What's in, what's out? | AskUserQuestion — present boundary proposals, user adjusts | Shaper sets boundaries autonomously |
| 5. Consolidation | Final shaped contract | Write standard Shaped Work Contract | Same |

The workshop surfaces decisions that are currently made silently. The final output is identical — a Shaped Work Contract — but the user participated in the key tradeoffs.

### Architect Workshop Phases (`/design --workshop`)

| Phase | Decision Being Made | Output Method | Current (Batch) |
|-------|-------------------|---------------|-----------------|
| 1. Approach Comparison | Which architecture? | HTML file showing 2-3 approaches with pros/cons/complexity/risk side-by-side | Architect picks best approach autonomously |
| 2. Technical Decisions | Each multi-option decision | AskUserQuestion for each decision that meets the "multiple viable alternatives" threshold | Architect fills decisions table autonomously |
| 3. Interface Preview | API ergonomics | HTML file showing interface signatures with usage examples | Architect defines interfaces autonomously |
| 4. Risk Prioritization | Which risks to mitigate? | AskUserQuestion — present risk matrix, user picks which mitigations are worth the cost | Architect proposes all mitigations |
| 5. Consolidation | Final design document | Write standard Design Document appended to backlog item | Same |

### HTML Artifact Approach (proven by Designer)

- **Appetite Explorer HTML:** Three columns (Small / Medium / Big) showing concrete scope items in each tier. Color-coded: green = in scope, yellow = stretch, red = out. User can visually see what they're trading.
- **Option Comparison HTML:** Cards per option with consistent dimensions (effort, risk, alignment, dependencies, reversibility). Visual tradeoff radar chart or bar comparison.
- **Architecture Comparison HTML:** Side-by-side architecture diagrams (simplified), with pros/cons beneath each. Component list, dependency count, complexity score.
- **Interface Preview HTML:** Code-styled API signatures with inline usage examples. Shows what calling the interfaces looks like from the consumer's perspective.

All HTML artifacts are self-contained (inline CSS), written to scratchpad, and opened with `open {path}`.

---

## 6. Rabbit Holes

- **Don't make workshop mode the default** — most `/define` and `/design` runs benefit from speed. Workshop is for when you want to be deliberate.
- **Don't add workshops to all phases** — Crafter, Critic, and Tidier make fewer multi-option decisions; their batch mode is appropriate.
- **Don't persist HTML artifacts to docs/** — these are session decision aids, not project knowledge. Use scratchpad.
- **Don't generate images** — HTML comparison tables and cards are better for decision comparison than AI-generated visualizations.
- **Don't change the output format** — the final Shaped Work Contract and Design Document should be identical whether produced via batch or workshop mode.

---

## 7. Behavioral Delta

No existing specs for Shaper or Architect genies. This is new capability — workshop mode is additive.

**Commands affected:**
- `.claude/commands/define.md` — add `--workshop` flag and workshop phases
- `.claude/commands/design.md` — add `--workshop` flag and workshop phases

No changes to GENIE.md, SPEC.md, or SYSTEM_PROMPT.md files for either genie.

---

## 8. Open Questions

### For Architect
- Should the Architect workshop include a "component boundary discovery" phase (DDD-lite event storming)?
- Should workshop HTML artifacts reference the current C4 diagrams for context?
- Where should workshop HTML artifacts be written — scratchpad dir or `docs/brand/assets/` equivalent for architecture?

### For Navigator
- Is P2 the right priority? This enhances existing genies rather than adding new capability.
- Should `--workshop` be a global flag (e.g., `GENIE_WORKSHOP=true` env var) or per-command only?

---

## 9. Dependencies

- **Met:** Designer workshop model proven (HTML artifacts for Phase 2-3, image gen for Phase 4-5)
- **Met:** `/brand` command demonstrates the pattern end-to-end
- **None blocking**

---

## 10. Routing Target

- [x] **Architect** — Needs technical design for:
  - Workshop phase integration into existing command files
  - HTML artifact structure for appetite/option/architecture comparison
  - `--workshop` flag detection and flow branching
  - Scratchpad vs docs/ artifact location decision

- [ ] **Crafter** — Not ready (needs design first)

---

## Artifacts

- **Contract:** `docs/backlog/P2-workshop-mode-shaper-architect.md` (this file)
- **Pattern precedent:** `.claude/commands/brand.md` (Designer workshop phases)

---

# Design Document: Interactive Workshop Mode for Shaper and Architect

---
spec_version: "1.0"
type: design
id: workshop-mode-design
title: "Interactive Workshop Mode — Technical Design"
status: designed
created: 2026-02-05
spec_ref: docs/backlog/P2-workshop-mode-shaper-architect.md
appetite: medium
complexity: moderate
author: architect
ac_mapping:
  - ac_id: AC-1
    approach: "Add appetite explorer phase to define.md that writes HTML with 3-column layout"
    components: [".claude/commands/define.md"]
  - ac_id: AC-2
    approach: "Add option exploration phase to define.md with HTML tradeoff cards + AskUserQuestion"
    components: [".claude/commands/define.md"]
  - ac_id: AC-3
    approach: "Detect --workshop in $ARGUMENTS; branch to workshop flow or batch flow"
    components: [".claude/commands/define.md"]
  - ac_id: AC-4
    approach: "Add approach comparison phase to design.md that writes HTML with side-by-side layout"
    components: [".claude/commands/design.md"]
  - ac_id: AC-5
    approach: "Add technical decisions phase to design.md with AskUserQuestion per multi-option decision"
    components: [".claude/commands/design.md"]
  - ac_id: AC-6
    approach: "Detect --workshop in $ARGUMENTS; branch to workshop flow or batch flow"
    components: [".claude/commands/design.md"]
  - ac_id: AC-7
    approach: "HTML for visual comparison phases (appetite, options, architecture, interfaces); AskUserQuestion for simpler choices (problem framing, scope, risk priorities)"
    components: [".claude/commands/define.md", ".claude/commands/design.md"]
  - ac_id: AC-8
    approach: "Workshop sections are gated by --workshop flag check; entire existing command text is untouched when flag is absent"
    components: [".claude/commands/define.md", ".claude/commands/design.md"]
components:
  - name: "define.md command"
    action: modify
    files: [".claude/commands/define.md"]
  - name: "design.md command"
    action: modify
    files: [".claude/commands/design.md"]
---

## Design Overview

Workshop mode is implemented as **prompt-level branching** within the existing `/define` and `/design` command files. When `--workshop` is present in `$ARGUMENTS`, the genie follows a phased interactive flow instead of the batch flow. No new files are created — this is purely additive content in two existing command files.

The design follows the **identical pattern** proven by `/brand`: write self-contained HTML to a temp location, tell the user to open it, use AskUserQuestion for feedback, iterate until the user approves, then consolidate into the standard output format.

## Architecture

### System Context

Workshop mode lives entirely within the command prompt layer. No new genies, agents, skills, or system prompt changes. The Shaper and Architect system prompts already support interactive questioning — workshop mode simply makes that questioning structured and visual.

```
User → /define --workshop → define.md (workshop branch) → HTML artifacts + AskUserQuestion → Shaped Work Contract
User → /define             → define.md (batch branch)    → Shaped Work Contract (unchanged)
```

### Component Design

| Component | Responsibility | Action |
|-----------|---------------|--------|
| `.claude/commands/define.md` | Add `--workshop` flag detection and 5 workshop phases for Shaper | Modify |
| `.claude/commands/design.md` | Add `--workshop` flag detection and 5 workshop phases for Architect | Modify |

No other files are modified. Per the shaped contract's no-go: GENIE.md, SPEC.md, and SYSTEM_PROMPT.md are untouched.

### Data Flow

```
/define --workshop [input]
  │
  ├─ Phase 1: Problem Framing
  │    └─ AskUserQuestion → user picks problem reframing
  │
  ├─ Phase 2: Appetite Explorer
  │    ├─ Write appetite-explorer.html to scratchpad
  │    ├─ Tell user: open {path}
  │    └─ AskUserQuestion → user picks appetite tier + adjusts scope
  │
  ├─ Phase 3: Option Exploration
  │    ├─ Write option-comparison.html to scratchpad
  │    ├─ Tell user: open {path}
  │    └─ AskUserQuestion → user picks option direction
  │
  ├─ Phase 4: Scope Negotiation
  │    └─ AskUserQuestion → user confirms in/out boundaries
  │
  └─ Phase 5: Consolidation
       └─ Write standard Shaped Work Contract (same as batch)
```

```
/design --workshop [contract]
  │
  ├─ Phase 1: Approach Comparison
  │    ├─ Write approach-comparison.html to scratchpad
  │    ├─ Tell user: open {path}
  │    └─ AskUserQuestion → user picks architecture direction
  │
  ├─ Phase 2: Technical Decisions
  │    └─ For each multi-option decision:
  │         └─ AskUserQuestion → user picks from alternatives
  │
  ├─ Phase 3: Interface Preview
  │    ├─ Write interface-preview.html to scratchpad
  │    ├─ Tell user: open {path}
  │    └─ AskUserQuestion → user confirms or adjusts API surface
  │
  ├─ Phase 4: Risk Prioritization
  │    └─ AskUserQuestion → user selects which mitigations to invest in
  │
  └─ Phase 5: Consolidation
       └─ Append standard Design Document to backlog item (same as batch)
```

## Interfaces & Contracts

### Flag Detection Pattern

Both commands use the same detection pattern at the top of their workshop section:

```
If $ARGUMENTS contains "--workshop":
  → Run workshop phases (interactive flow)
  → Then run consolidation (produces same output as batch)
Else:
  → Run batch flow (existing behavior, completely unchanged)
```

This is a prompt-level conditional, not code. The existing command text remains verbatim — workshop content is appended as a new section after the existing content.

### HTML Artifact Contract

All workshop HTML artifacts follow these rules (proven by `/brand`):

1. **Self-contained** — Inline CSS, no external dependencies (except Google Fonts CDN for typography if needed)
2. **Written to scratchpad** — Session-scoped, not persisted to `docs/`
3. **Opened with `open {path}`** — User views in browser
4. **Regenerable** — If user wants changes, regenerate the HTML and tell them to refresh
5. **Ephemeral** — Not referenced in the final output document

### Scratchpad Location

HTML artifacts are written to the Claude Code scratchpad directory (available as a session-scoped temp dir). The exact path follows the pattern:
```
{scratchpad}/workshop/appetite-explorer.html
{scratchpad}/workshop/option-comparison.html
{scratchpad}/workshop/approach-comparison.html
{scratchpad}/workshop/interface-preview.html
```

## Pattern Adherence

- **Follows `/brand` workshop pattern exactly** — HTML artifacts for visual decisions, AskUserQuestion for simple choices, consolidation produces standard output
- **Follows existing flag pattern** — Both commands already support optional flags (`--appetite`, `--risks`, `--interfaces`, `--spike`, `--review`); `--workshop` is another optional flag
- **No new structural patterns introduced** — Purely prompt-level additions to existing commands

## Technical Decisions

| Decision | Options | Choice | Rationale |
|----------|---------|--------|-----------|
| Workshop activation | `--workshop` flag vs env var vs separate command | `--workshop` flag | Consistent with existing flag patterns (`--appetite`, `--spike`); per-command granularity; no new env vars |
| HTML artifact location | Scratchpad vs `docs/workshop/` vs `docs/brand/assets/` | Scratchpad | Session artifacts, not project knowledge; shaped contract explicitly requires this |
| C4 diagram context in Architecture Comparison | Embed diagram vs reference only vs none | Reference in HTML preamble | Lightweight context without duplicating diagram; HTML can include a "Current Architecture" summary section before showing options |
| Workshop phase structure | Fixed 5 phases vs dynamic phases vs configurable | Fixed 5 phases per genie | Predictable, follows Designer's fixed 6-phase structure; no over-engineering |
| Iteration within phases | Single-pass per phase vs iteration loops | Single-pass with revision option | Unlike imagery (creative exploration), decisions are convergent — one round of options → pick is usually sufficient. AskUserQuestion's "Other" option handles edge cases. |

## Implementation Guidance

### Step 1: Modify `define.md` — Add workshop section

Append a new `## Workshop Mode` section **after** the existing `## Notes` section (preserving all existing content). Structure:

1. **Flag detection block** — Check `$ARGUMENTS` for `--workshop`
2. **Phase 1: Problem Framing** — Present 2-3 problem reframings via AskUserQuestion
3. **Phase 2: Appetite Explorer** — Write HTML, open, gather feedback via AskUserQuestion
4. **Phase 3: Option Exploration** — Write HTML, open, gather feedback via AskUserQuestion
5. **Phase 4: Scope Negotiation** — Present boundary proposals via AskUserQuestion
6. **Phase 5: Consolidation** — Same as batch output

### Step 2: Modify `design.md` — Add workshop section

Same approach — append `## Workshop Mode` section after existing content:

1. **Flag detection block** — Check `$ARGUMENTS` for `--workshop`
2. **Phase 1: Approach Comparison** — Write HTML, open, gather feedback via AskUserQuestion
3. **Phase 2: Technical Decisions** — AskUserQuestion per multi-option decision
4. **Phase 3: Interface Preview** — Write HTML, open, gather feedback via AskUserQuestion
5. **Phase 4: Risk Prioritization** — Present risk matrix via AskUserQuestion
6. **Phase 5: Consolidation** — Same as batch output (append Design Document to backlog item)

### Step 3: Verify batch mode preservation

After implementation, verify that running `/define [input]` and `/design [contract]` without `--workshop` produces identical behavior to current state.

### Key Considerations

**Must do:**
- Preserve ALL existing command text verbatim — workshop is additive
- HTML artifacts must be self-contained (inline CSS)
- AskUserQuestion must include meaningful options (not open-ended questions)
- Consolidation phase must produce identical output format to batch mode
- Each HTML artifact must tell the user to open it with `open {path}`

**Should do:**
- Use consistent visual language across all 4 HTML artifact types (color scheme, layout grid)
- Include a "Current State" context section in Architecture Comparison HTML when C4 diagrams exist
- Number workshop phases in user-facing output for clarity (e.g., "=== Phase 2: Appetite Explorer ===")

### HTML Artifact Specifications

#### Appetite Explorer HTML (Shaper Phase 2)

Three-column layout:

| Small Batch (1-2 days) | Medium Batch (3-5 days) | Big Batch (1-2 weeks) |
|---|---|---|

Each column contains:
- **Concrete scope items** that fit in that tier (features, capabilities, changes)
- **Color coding:** Green (included), Yellow (stretch), Red (excluded)
- **Tradeoff summary** at bottom: "You get X but not Y"
- **Risk indicator** per tier: Low / Medium / High

CSS: Use a clean card-based layout with clear tier headers. Green (#22c55e), Yellow (#eab308), Red (#ef4444) for scope indicators.

#### Option Comparison HTML (Shaper Phase 3)

Card-per-option layout with consistent evaluation dimensions:

Each option card shows:
- **Option name and 1-sentence description**
- **Evaluation bars** (visual, not text) for: Effort, Risk, Alignment, Dependencies, Reversibility
- Each dimension rated Low/Medium/High with a colored bar (green → yellow → red)
- **Bottom line:** 1-sentence tradeoff summary

Cards sit side-by-side for direct comparison.

#### Architecture Comparison HTML (Architect Phase 1)

Side-by-side approach layout:

Each approach panel shows:
- **Approach name and summary**
- **Component list** with component count
- **Dependency diagram** (simplified text-based, not Mermaid — just indented lists showing what depends on what)
- **Evaluation table:** Complexity, Risk, Maintainability, Performance, Reversibility
- **Pros / Cons** bullet lists

If C4 context is available, include a "Current Architecture" summary section at the top before the comparison panels.

#### Interface Preview HTML (Architect Phase 3)

Code-styled layout showing interface signatures:

- **Monospace font** for interface definitions
- **Syntax-highlighted** code blocks (inline CSS for basic highlighting)
- **Usage examples** beneath each interface showing how callers would use it
- **Side notes** explaining design choices for key methods
- Group by component/module

## Error Handling & Edge Cases

| Scenario | Expected Behavior | Handling |
|----------|-------------------|----------|
| `--workshop` with `--appetite` (sub-command + workshop) | Workshop takes precedence | Workshop flag check comes first; sub-command flags ignored with warning |
| User cancels mid-workshop (closes conversation) | No output produced | Normal — workshop is interactive, no side effects until consolidation |
| HTML file write fails (permissions) | Workshop continues without visual | Fall back to text description of options + AskUserQuestion |
| No scratchpad available | Use `/tmp/genie-workshop/` | Fallback path in write instruction |
| User says "Other" on every AskUserQuestion | Free-form responses captured | AskUserQuestion's built-in "Other" option handles this naturally |

## Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Workshop takes too long, users skip it | Medium | Medium | Workshop is opt-in; phases are concise (5 phases, not 10); each phase has one clear decision point |
| HTML artifacts look broken in some browsers | Low | Low | Self-contained inline CSS; tested layout patterns from `/brand`; simple grid/card layouts only |
| Existing batch behavior accidentally changed | Low | High | Workshop content is appended AFTER existing content; flag check gates all new behavior; AC-8 verifies preservation |
| LLM ignores workshop phases and does batch anyway | Medium | Medium | Explicit "MANDATORY: When --workshop is present" instruction at top of workshop section; same pattern that worked for `/brand` visual output rules |

## Testing Strategy

- **Manual verification:** Run `/define topic` and `/design contract` without `--workshop` → confirm identical behavior to current
- **Workshop flow:** Run `/define --workshop topic` → verify all 5 phases execute in order with HTML artifacts and AskUserQuestion
- **Workshop flow:** Run `/design --workshop contract` → verify all 5 phases execute in order
- **HTML rendering:** Open each HTML artifact type in Safari/Chrome → verify layout and readability
- **Consolidation parity:** Compare final Shaped Work Contract (workshop) vs (batch) → format should be identical

## Routing

- [x] **Crafter** — Design complete, ready for implementation
- [ ] **Shaper** — N/A
- [ ] **Scout** — N/A

**Rationale:** Two command files to modify with well-defined workshop phases. Implementation follows the `/brand` pattern exactly. No architectural decisions needed — this is prompt-level content addition.

---

# Implementation

## Implementation Summary

Workshop mode implemented as prompt-level additions to two existing command files. No new files created. All existing batch-mode content preserved verbatim.

## Files Modified

| File | Change | Lines Added |
|------|--------|-------------|
| `.claude/commands/define.md` | Appended `## Workshop Mode` section with 5 phases after `## Notes` | ~100 |
| `.claude/commands/design.md` | Appended `## Workshop Mode` section with 5 phases after `## Notes` | ~110 |

## Implementation Decisions

- **Workshop sections appended after existing content** — all existing command text is untouched, preserving batch-mode behavior exactly
- **Flag detection uses `$ARGUMENTS contains "--workshop"`** — prompt-level conditional, consistent with how other flags (`--appetite`, `--spike`) work
- **HTML artifact paths use `{scratchpad}/workshop/` directory** — session-scoped, automatically cleaned up
- **AskUserQuestion used for all interactive decisions** — consistent with how `/brand` workshop operates
- **Phase numbering explicit in instructions** — each phase has a clear "Workshop Phase N: Name" header for LLM compliance
- **MANDATORY prefix** on visual phases — same enforcement pattern that worked for `/brand` after the "show don't tell" fixes

## AC Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Implemented | define.md Phase 2 writes appetite-explorer.html with 3-column layout |
| AC-2 | Implemented | define.md Phase 3 writes option-comparison.html + AskUserQuestion for direction |
| AC-3 | Implemented | define.md Workshop Mode section gated by `--workshop` flag check |
| AC-4 | Implemented | design.md Phase 1 writes approach-comparison.html with side-by-side panels |
| AC-5 | Implemented | design.md Phase 2 walks through each multi-option decision via AskUserQuestion |
| AC-6 | Implemented | design.md Workshop Mode section gated by `--workshop` flag check |
| AC-7 | Implemented | HTML for visual comparison (appetite, options, architecture, interfaces); AskUserQuestion for simpler choices (problem framing, scope, risk priorities) |
| AC-8 | Implemented | Workshop content appended AFTER all existing content; flag check prevents any workshop behavior without `--workshop` |

## Notes

- No GENIE.md, SPEC.md, or SYSTEM_PROMPT.md files modified (per shaped contract no-go)
- No new files created — purely additive content in 2 existing command files
- Pattern follows `/brand` workshop exactly: HTML for visual decisions, AskUserQuestion for simple choices, consolidation produces standard output format

---

# End of Shaped Work Contract
