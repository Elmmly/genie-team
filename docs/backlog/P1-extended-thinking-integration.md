---
id: P1-extended-thinking-integration
title: Deep Reasoning as Default for Scout and Architect
type: feature
status: designed
priority: P1
appetite: small
spec_ref: docs/specs/genies/extended-thinking.md
adr_refs:
  - docs/decisions/ADR-003-extended-thinking-activation-strategy.md
created: 2026-02-25
discovery_ref: docs/analysis/20260225_discover_ai_pdlc_trends.md
spike_refs:
  - docs/analysis/20260225_spike_extended_thinking_feasibility.md
---

# Shaped Work Contract: Deep Reasoning as Default for Scout and Architect

## Problem

Genie-team's two analysis-heavy genies — Scout (discovery) and Architect (design) — don't leverage Claude's reasoning depth intentionally. Scout runs on haiku (cheapest, shallowest model), and neither genie has prompt instructions guiding *what* to reason deeply about.

The consequence: discovery analysis is shallow on complex questions, and design documents miss edge cases that deeper reasoning would catch. Meanwhile, Claude Code already has extended thinking enabled by default — we're just not directing it effectively.

This is not a platform capability gap. It's a prompt engineering gap: we haven't told our analysis genies to think harder, and Scout's model choice (haiku) limits reasoning quality regardless of instructions.

**Who is affected:** All genie-team users running `/discover` or `/design`. The impact scales with problem complexity — simple tasks are fine; complex strategic or architectural questions suffer most.

**Evidence:** Spike confirmed Claude Code already has thinking enabled. Effort levels exist on Opus 4.6. Haiku 4.5 supports thinking but has weakest reasoning. Sonnet provides significantly deeper analysis at modest cost increase.

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days) — this is 4 file edits (2 agent definitions + 2 command definitions)
- **No-gos:**
  - Do NOT upgrade to Opus (cost/quality tradeoff not justified for default)
  - Do NOT add deep reasoning to Crafter, Critic, or Tidier (out of scope — they have different reasoning needs)
  - Do NOT build cost-tracking infrastructure
  - Do NOT modify the CLI contract or runner
  - Do NOT change output formats (Opportunity Snapshot, Design Document stay the same)
- **Fixed elements:**
  - Pure prompt engineering (markdown/YAML files only)
  - Scout and Architect output formats unchanged
  - `--fast` is opt-out, not `--deep` opt-in

## Goals & Outcomes

- Scout produces deeper discovery analysis by default — richer evidence grading, more thorough assumption surfacing, better JTBD analysis
- Architect produces more thorough designs by default — better risk identification, more considered tradeoffs, stronger pattern analysis
- Reasoning depth is traceable via `reasoning_mode: deep|fast` in output frontmatter
- Users who need speed can pass `--fast` to skip exhaustive analysis
- Zero change for users who don't pass any flag — they just get better output

## Solution Sketch

### 1. Upgrade Scout model: haiku → sonnet

In `agents/scout.md` frontmatter, change `model: haiku` to `model: sonnet`. Sonnet provides substantially deeper reasoning for discovery tasks. The cost increase (~5x per token) is justified: shallow discovery leads to shallow products.

### 2. Add deep reasoning instructions to Scout

Add a section to `agents/scout.md` instructing Scout to:
- Reason through each assumption before categorizing its evidence level
- Challenge its own initial framing before settling on the reframed question
- Explicitly consider counter-evidence and alternative interpretations
- Grade evidence quality with specific justification (not just "moderate")

### 3. Add deep reasoning instructions to Architect

Add a section to `agents/architect.md` instructing Architect to:
- Consider at least 2 alternative approaches before recommending one
- Reason through failure modes for each component interaction
- Explicitly justify pattern choices (not just "use factory pattern" — *why* factory?)
- Assess each risk with concrete scenario, not abstract likelihood labels

### 4. Add `--fast` opt-out to `/discover` and `/design`

Update `commands/discover.md` and `commands/design.md` to recognize `--fast` flag. When present, include a prompt instruction: "Prioritize speed over exhaustive analysis. Use heuristic judgment. Be concise."

### 5. Reasoning mode tracking

Scout's Opportunity Snapshot frontmatter gets `reasoning_mode: deep` (default) or `reasoning_mode: fast`. Same for Architect's Design Document.

## Behavioral Delta Against Existing Specs

**Affected spec:** `docs/specs/genies/scout-discovery.md`

### Current Behavior
- AC-1: Scout runs on haiku with read-only tools and plan permission mode

### Proposed Changes
- AC-1: Scout runs on **sonnet** (upgraded from haiku) with read-only tools and plan permission mode
- AC-NEW: Scout's Opportunity Snapshot includes `reasoning_mode: deep|fast` in frontmatter

**Affected spec:** `docs/specs/genies/architect-design.md`

### Current Behavior
- AC-1: Architect runs on sonnet with read-only tools + Bash (git only)

### Proposed Changes
- AC-1: Unchanged (already on sonnet)
- AC-NEW: Architect's Design Document includes `reasoning_mode: deep|fast` in frontmatter
- AC-NEW: Architect agent definition includes deep reasoning instructions for design analysis

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Sonnet produces meaningfully deeper Scout analysis than haiku | value | Compare a discovery run on the same topic with haiku vs sonnet |
| Deep reasoning instructions improve output quality beyond model upgrade alone | value | Compare sonnet with and without reasoning instructions on the same topic |
| `--fast` flag is sufficient escape hatch for speed-sensitive users | usability | Observe usage after shipping; if >50% use --fast, reconsider default |
| Cost increase (haiku → sonnet) is acceptable | viability | Scout sessions on sonnet ~$0.50-2.00; haiku was ~$0.10-0.40 |

## Acceptance Criteria

- id: AC-1
  description: >-
    Scout agent definition (`agents/scout.md`) uses `model: sonnet` instead of
    `model: haiku`
  status: pending

- id: AC-2
  description: >-
    Scout agent definition includes a "Deep Reasoning" section with instructions
    to reason through assumptions, challenge initial framing, consider
    counter-evidence, and justify evidence grades
  status: pending

- id: AC-3
  description: >-
    Architect agent definition (`agents/architect.md`) includes a "Deep Reasoning"
    section with instructions to consider alternative approaches, reason through
    failure modes, justify pattern choices, and ground risk assessments in
    concrete scenarios
  status: pending

- id: AC-4
  description: >-
    `/discover` command supports `--fast` flag that adds a prompt instruction
    to prioritize speed over depth; Scout's Opportunity Snapshot frontmatter
    includes `reasoning_mode: fast` when flag is present
  status: pending

- id: AC-5
  description: >-
    `/design` command supports `--fast` flag with the same speed-over-depth
    behavior; Architect's Design Document frontmatter includes
    `reasoning_mode: fast` when flag is present
  status: pending

- id: AC-6
  description: >-
    When no flag is passed, Scout and Architect output includes
    `reasoning_mode: deep` in frontmatter — deep is the default, not opt-in
  status: pending

- id: AC-7
  description: >-
    Output formats (Opportunity Snapshot, Design Document) are unchanged except
    for the new `reasoning_mode` frontmatter field — no structural changes
  status: pending

## Routing

- **Next genie:** Crafter — no spike needed. ADR-003 is decided. This is a small batch of 4 file edits.
- **Crafter scope:** Edit `agents/scout.md` (model + reasoning instructions), `agents/architect.md` (reasoning instructions), `commands/discover.md` (--fast flag), `commands/design.md` (--fast flag)
- **After Crafter:** Critic to verify reasoning quality improvement on a sample discovery/design run

---

# Design

## Design Summary

Four targeted edits to existing markdown files: upgrade Scout's model field from `haiku` to `sonnet`, add a Deep Reasoning section to both `agents/scout.md` and `agents/architect.md` with domain-specific reasoning guidance, and add `--fast` flag handling plus `reasoning_mode` frontmatter tracking to `commands/discover.md` and `commands/design.md`. ADR-003 (accepted) governs all architectural decisions — no new decisions needed here. This is the smallest possible prompt-engineering change that achieves meaningfully deeper analysis by default.

Per the spike (`docs/analysis/20260225_spike_extended_thinking_feasibility.md`), extended thinking cannot be activated via agent YAML frontmatter — Claude Code does not expose a `thinking` field. ADR-003 resolves this: deep reasoning is achieved via prompt instruction (chain-of-thought guidance directing what to reason about), not API-level extended thinking parameters. Claude Code already enables thinking at the runtime level; our job is to provide domain-specific reasoning guidance.

## Architecture

This is a pure prompt engineering change with no new components, no new files, and no runtime changes. The four existing files act as the "architecture" of this feature:

```
commands/discover.md ──→ reads --fast flag
        │                         │
        └──► agents/scout.md ◄────┘
             (model: sonnet,           reasoning_mode tracking
              Deep Reasoning section)  in Opportunity Snapshot frontmatter

commands/design.md  ──→ reads --fast flag
        │                         │
        └──► agents/architect.md ◄─┘
             (Deep Reasoning section)  reasoning_mode tracking
                                       in Design Document frontmatter
```

Data flow: command reads `$ARGUMENTS` → detects `--fast` presence → conditionally adds speed-over-depth instruction to prompt → agent definition governs reasoning behavior → output template includes `reasoning_mode` field.

The `reasoning_mode` field appears in two output document templates:
- Opportunity Snapshot (in `agents/scout.md`): add `reasoning_mode: deep|fast` to the YAML frontmatter block
- Design Document (in `agents/architect.md`): add `reasoning_mode: deep|fast` to the YAML frontmatter block

## Component Design

| Component | Action | File | What Changes |
|-----------|--------|------|--------------|
| ScoutModel | modify | `agents/scout.md` | `model: haiku` → `model: sonnet` in frontmatter |
| ScoutReasoning | modify | `agents/scout.md` | Add "## Deep Reasoning" section to agent body |
| ScoutTemplate | modify | `agents/scout.md` | Add `reasoning_mode: deep` to Opportunity Snapshot YAML frontmatter block |
| ArchitectReasoning | modify | `agents/architect.md` | Add "## Deep Reasoning" section to agent body |
| ArchitectTemplate | modify | `agents/architect.md` | Add `reasoning_mode: deep` to Design Document YAML frontmatter block |
| DiscoverCommand | modify | `commands/discover.md` | Add `--fast` flag handling; inject speed instruction when flag present; output `reasoning_mode: fast` |
| DesignCommand | modify | `commands/design.md` | Add `--fast` flag handling; inject speed instruction when flag present; output `reasoning_mode: fast` |

All changes are to existing files. No new files are created.

## AC Mapping

| AC | Approach | Components |
|----|----------|------------|
| AC-1 | Change `model: haiku` to `model: sonnet` in `agents/scout.md` frontmatter | `agents/scout.md` |
| AC-2 | Add "## Deep Reasoning" section to `agents/scout.md` with four reasoning directives | `agents/scout.md` |
| AC-3 | Add "## Deep Reasoning" section to `agents/architect.md` with four reasoning directives | `agents/architect.md` |
| AC-4 | Add `--fast` detection to `commands/discover.md`; when present, inject speed instruction and set `reasoning_mode: fast` in snapshot frontmatter | `commands/discover.md`, `agents/scout.md` |
| AC-5 | Add `--fast` detection to `commands/design.md`; when present, inject speed instruction and set `reasoning_mode: fast` in design document frontmatter | `commands/design.md`, `agents/architect.md` |
| AC-6 | Default path (no `--fast` flag) emits `reasoning_mode: deep` — this is the base template in each agent's output section | `agents/scout.md`, `agents/architect.md` |
| AC-7 | Only additive changes: one new field in frontmatter templates, one new section in agent body — all existing sections unchanged | all four files |

## Interfaces

### Deep Reasoning Section (both agents)

The "## Deep Reasoning" section in each agent definition is a named instruction block that directs what to reason deeply about. It follows the existing section pattern (Charter, Judgment Rules, Anti-Patterns) already in both agent files.

**Scout's Deep Reasoning section instructs:**
1. Before categorizing each assumption's evidence level, reason through: what specific data supports it, what could contradict it, and whether the evidence sample size is sufficient to sustain the confidence grade.
2. After initial problem framing, challenge the framing: what if the problem is downstream of a different root cause? What alternative framings exist?
3. For each opportunity area, explicitly consider counter-evidence: what signals suggest this is NOT a real problem?
4. When grading evidence (strong/moderate/weak/missing), state the specific justification — not just the grade.

**Architect's Deep Reasoning section instructs:**
1. Before recommending an approach, consider at least two alternatives and state why each was not chosen.
2. For each component interaction, reason through failure modes: what happens when component A is unavailable, slow, or returns malformed data?
3. When selecting a pattern (factory, strategy, registry, etc.), state explicitly why that pattern — not just that the pattern is used.
4. For each risk, describe a concrete scenario that would realize it — not just likelihood/impact labels.

### `--fast` Flag Handling (both commands)

Both `commands/discover.md` and `commands/design.md` already have an `$ARGUMENTS` variable at the end of the file. The `--fast` handling is a conditional instruction block added to the command body:

```
**Speed Mode (--fast flag):**
When `$ARGUMENTS` contains `--fast`, append this instruction to the agent prompt:
"Prioritize speed over exhaustive analysis. Use heuristic judgment, skip thorough counter-evidence search, produce concise output. Set reasoning_mode: fast in frontmatter."

When `$ARGUMENTS` does NOT contain `--fast` (default), the agent uses deep reasoning mode.
Set reasoning_mode: deep in frontmatter.
```

### `reasoning_mode` Frontmatter Field

In `agents/scout.md`, the Opportunity Snapshot template already has a YAML frontmatter block:
```yaml
---
type: discover
topic: "{topic}"
status: active
created: "{YYYY-MM-DD}"
---
```

Add one field:
```yaml
reasoning_mode: deep  # or: fast (when --fast flag passed)
```

Same pattern for the Design Document frontmatter in `agents/architect.md`.

## Pattern Adherence

This design follows all established patterns in the codebase:

- **Prompt instruction pattern:** Both agents already have named sections (Charter, Judgment Rules, Routing) that direct behavior. The new "## Deep Reasoning" section follows this exact pattern.
- **Flag detection pattern:** `commands/discover.md` already uses `$ARGUMENTS` with `--workshop` flag detection (workshop mode). The `--fast` flag follows the same conditional block pattern.
- **Frontmatter tracking pattern:** Both output templates already track metadata in YAML frontmatter (type, topic, status, created). Adding `reasoning_mode` follows this exact pattern.
- **No new file pattern:** The appetite is "small" — all changes are additive edits to existing files. No new components, no new files. This matches how existing agent enhancements have been made (e.g., the spec-awareness skill was added as a field to existing agent frontmatter).

No deviations from established patterns.

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Scout on sonnet is noticeably slower for simple discovery tasks | M | L | `--fast` flag provides escape hatch; simple tasks should still be fast enough on sonnet |
| Deep reasoning instructions make Scout/Architect verbose rather than deep | L | M | Instructions direct *what* to reason about, not *how much to write* — conciseness constraint is implicit in existing output templates |
| Users pass `--fast` to every invocation, negating the feature | L | L | If usage shows >50% `--fast` usage, reconsider default per ADR-003 revisit condition |
| `reasoning_mode` field in frontmatter breaks downstream consumers | L | L | Downstream consumers of Opportunity Snapshot and Design Document are humans and other genies (via spec-awareness); both treat additional frontmatter fields as additive |
| Crafter modifies the wrong section of a file | L | M | Implementation guidance below specifies exact section locations |

Rollback: All changes are additive to existing files. If deep reasoning degrades output quality, revert the "## Deep Reasoning" sections and `reasoning_mode` field without affecting any other functionality.

## Implementation Guidance

**Sequence for Crafter (ordered — each step is independent):**

1. **`agents/scout.md` — model field** (1 line change)
   - In the YAML frontmatter, change `model: haiku` to `model: sonnet`
   - Location: line 5 of the file (the `model:` field)

2. **`agents/scout.md` — Deep Reasoning section** (new section, ~15 lines)
   - Add a new `## Deep Reasoning` section after the existing `## Anti-Patterns to Catch` section and before `## Opportunity Snapshot Template`
   - The section contains four numbered directives (see Interfaces above)
   - Section header: `## Deep Reasoning`
   - Opening line: "When executing a discovery task, reason through each of the following before producing your Opportunity Snapshot:"

3. **`agents/scout.md` — Opportunity Snapshot template** (1 line addition)
   - Find the YAML frontmatter block in the Opportunity Snapshot Template section
   - Add `reasoning_mode: deep` as a new field (default; command will override to `fast` when `--fast` is passed)

4. **`agents/architect.md` — Deep Reasoning section** (new section, ~15 lines)
   - Add a new `## Deep Reasoning` section after the existing `## Judgment Rules` section and before `## Design Document Template`
   - The section contains four numbered directives (see Interfaces above)
   - Section header: `## Deep Reasoning`
   - Opening line: "When executing a design task, reason through each of the following before producing your Design Document:"

5. **`agents/architect.md` — Design Document template** (1 line addition)
   - Find the YAML frontmatter block in the Design Document Template section
   - Add `reasoning_mode: deep` as a new field (default)

6. **`commands/discover.md` — `--fast` flag handling** (new conditional block, ~8 lines)
   - Add a `## Speed Mode (--fast)` section near the top of the file, after the `## Arguments` section
   - The section defines the behavior when `$ARGUMENTS` contains `--fast`
   - Pattern matches the existing `## Workshop Mode (--workshop)` section at the bottom

7. **`commands/design.md` — `--fast` flag handling** (same pattern as step 6)
   - Add the same `## Speed Mode (--fast)` section structure to `commands/design.md`

**Test scenarios for Critic:**
- Run `/discover "test topic"` and confirm output frontmatter contains `reasoning_mode: deep`
- Run `/discover "test topic" --fast` and confirm frontmatter contains `reasoning_mode: fast`
- Run `/design docs/backlog/any-item.md` and confirm design document frontmatter contains `reasoning_mode: deep`
- Confirm Scout's model field reads `sonnet` in `agents/scout.md`
- Confirm no existing sections in any of the four files were removed or reordered

## Routing

Ready for Crafter. All decisions are made (ADR-003 accepted). Implementation is mechanical: 7 targeted edits across 4 files, all additive, no deletions.
