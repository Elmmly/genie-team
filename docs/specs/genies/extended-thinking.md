---
spec_version: "1.0"
type: spec
id: extended-thinking
title: Deep Reasoning for Analysis Genies
status: active
created: 2026-02-25
domain: genies
source: define
acceptance_criteria:
  - id: AC-1
    description: >-
      Scout agent definition uses model: sonnet (upgraded from haiku) for
      deeper reasoning on discovery tasks
    status: pending
  - id: AC-2
    description: >-
      Scout agent definition includes deep reasoning instructions directing
      thorough assumption analysis, counter-evidence consideration, and
      justified evidence grading
    status: pending
  - id: AC-3
    description: >-
      Architect agent definition includes deep reasoning instructions directing
      alternative approach consideration, failure mode analysis, justified
      pattern choices, and concrete risk scenarios
    status: pending
  - id: AC-4
    description: >-
      /discover supports --fast flag that adds speed-over-depth prompt
      instruction; Opportunity Snapshot frontmatter includes
      reasoning_mode: fast when flag is present
    status: pending
  - id: AC-5
    description: >-
      /design supports --fast flag with the same speed-over-depth behavior;
      Design Document frontmatter includes reasoning_mode: fast when flag
      is present
    status: pending
  - id: AC-6
    description: >-
      Default behavior (no flag) produces reasoning_mode: deep in output
      frontmatter for both Scout and Architect
    status: pending
  - id: AC-7
    description: >-
      Output formats (Opportunity Snapshot, Design Document) are unchanged
      except for the new reasoning_mode frontmatter field
    status: pending
---

# Deep Reasoning for Analysis Genies

## Overview

Scout and Architect are genie-team's analysis-heavy genies — discovery research and technical design, respectively. Both benefit from deeper reasoning: richer evidence analysis, more thorough assumption surfacing, better risk identification.

Claude Code already enables extended thinking by default. This spec governs how genie-team directs that reasoning capability intentionally:

1. **Scout upgrades from haiku to sonnet** for meaningfully deeper discovery analysis
2. **Both genies get domain-specific deep reasoning instructions** — not just "think harder" but guidance on *what* to reason deeply about
3. **`--fast` opt-out flag** on `/discover` and `/design` for speed-sensitive invocations
4. **`reasoning_mode: deep|fast` tracking** in output frontmatter for traceability

The design philosophy: deep is the default because analysis quality matters more than speed. Users who need speed have an explicit escape hatch.

## Design Constraints
<!-- Updated by /design on 2026-02-25 from P1-extended-thinking-integration -->
- Pure prompt engineering — agent YAML frontmatter + markdown instructions only; no API-level changes
- Extended thinking cannot be configured in agent YAML (no `thinking` field in Claude Code frontmatter schema); reasoning improvement is via prompt instruction (chain-of-thought guidance)
- Output formats unchanged (Opportunity Snapshot, Design Document keep their structure) except for the new `reasoning_mode: deep|fast` frontmatter field
- Scope limited to Scout and Architect; Crafter, Critic, Tidier are out of scope
- `--fast` flag detection follows the `$ARGUMENTS` conditional pattern established by `--workshop` in existing commands
- Scout model upgrade (haiku → sonnet) is in YAML frontmatter `model:` field only — no other changes to Scout's tool list, permissionMode, or skills
- `reasoning_mode` default is `deep` (in agent template); commands override to `fast` when `--fast` is passed
- Four files total, all additive edits: `agents/scout.md`, `agents/architect.md`, `commands/discover.md`, `commands/design.md`

## Implementation Evidence

_To be populated by Crafter during /deliver phase._

## Review Verdict

_To be populated by Critic during /discern phase._
