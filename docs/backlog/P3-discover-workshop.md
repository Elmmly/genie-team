---
spec_version: "1.0"
type: shaped-work
id: discover-workshop
title: "Discovery Workshop Mode"
status: shaped
created: 2026-02-12
appetite: medium
priority: P3
target_project: genie-team
author: shaper
depends_on: []
builds_on: []
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
tags: [workshop, discovery, scout, interactive, product-management]
acceptance_criteria:
  - id: AC-1
    description: "/discover --workshop runs a multi-phase interactive product discovery workshop with iteration loops, producing an Opportunity Snapshot"
    status: pending
  - id: AC-2
    description: "Workshop has at least 4 phases: Landscape Scan (market/competitor context), Opportunity Mapping (Teresa Torres opportunity tree), Assumption Surfacing (rank by risk/evidence), and Evidence Plan (what to validate and how)"
    status: pending
  - id: AC-3
    description: "Each phase produces a viewable HTML artifact (like /define --workshop and /design --workshop) for visual comparison and user decision"
    status: pending
  - id: AC-4
    description: "Each phase has an iteration loop — user can request adjustments and the HTML is regenerated until approved"
    status: pending
  - id: AC-5
    description: "Workshop consolidation produces the same Opportunity Snapshot format as batch /discover, so downstream /define can consume it identically"
    status: pending
  - id: AC-6
    description: "Source commands/discover.md includes the workshop mode (not just the installed .claude/commands/ copy)"
    status: pending
---

# Discovery Workshop Mode

## Problem/Opportunity Statement

`/discover` is a single-pass command — the Scout genie explores a topic and produces an Opportunity Snapshot. This works well for well-scoped research, but when bootstrapping a new project or exploring a broad problem space, users need a structured multi-phase workshop with iteration loops. The `/brand --workshop`, `/define --workshop`, and `/design --workshop` commands demonstrate the pattern: interactive phases, HTML artifacts for visual decision-making, and iteration until the user is satisfied. `/discover` is the only major lifecycle command missing this workshop mode.

## Evidence

- README review (2026-02-12) identified this as a gap in the new-project bootstrap journey
- `/brand --workshop` (6 phases), `/define --workshop` (4 phases), and `/design --workshop` (4 phases) all follow the same pattern successfully
- Users bootstrapping new projects need guided product discovery before they can shape work

## Appetite

**Medium batch (3-5 days).** The workshop pattern is well-established — this is applying it to the Scout genie's domain.

## Solution Sketch

Add `--workshop` flag to `/discover` command following the established pattern:

1. **Landscape Scan** — Market context, competitor landscape, user segments. HTML artifact showing the landscape map.
2. **Opportunity Mapping** — Teresa Torres opportunity tree. HTML artifact showing opportunities organized by outcome.
3. **Assumption Surfacing** — Rank assumptions by risk (high impact + low evidence = test first). HTML artifact with assumption matrix.
4. **Evidence Plan** — For top assumptions: what evidence would change our mind? HTML artifact with validation approaches.
5. **Consolidation** — Standard Opportunity Snapshot document.

## Rabbit Holes

- Don't build a full product strategy tool — this is structured discovery, not roadmap planning
- Don't require external data sources (web search is optional enrichment, not a dependency)
- Don't try to replace human product intuition — surface and organize, don't decide

## No-Gos

- No integration with external PM tools (Linear, Jira) — that's a separate concern
- No automated assumption validation — the workshop surfaces what to validate, humans validate

# End of Shaped Work Contract
