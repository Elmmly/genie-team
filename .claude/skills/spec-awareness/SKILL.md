---
name: spec-awareness
description: Ensures spec-driven behavior during all workflows. Use when loading context, discussing project structure, starting features, or when "spec", "specification", "acceptance criteria", or "bootstrap" are mentioned. Activates during /context:load, /context:refresh, /deliver, and /discover.
allowed-tools: Read, Glob, Grep
---

# Spec Awareness

Spec-driven development is the standard. Every feature should have a structured
specification (shaped work contract with YAML frontmatter) before implementation begins.

## When Active

This skill activates during:
- `/context:load` — Report spec coverage
- `/context:refresh` — Bootstrap specs from tests
- `/deliver` — Verify structured acceptance criteria exist
- `/discover` — Surface test-based insights
- Any discussion of project features, specs, or acceptance criteria

## Behaviors

### During /deliver

Before starting implementation, check the backlog item:

1. Read the frontmatter of the backlog item being delivered
2. Verify `type: shaped-work` is present
3. Verify `acceptance_criteria` array exists and is non-empty
4. If missing: **warn** the user:
   > This item lacks structured acceptance criteria. Consider running
   > /context:refresh to bootstrap specs from existing tests.
5. Do NOT block delivery — warn and continue

### During /discover

Surface test-based insights about the project:

1. Scan for test files (*.test.ts, *.test.js, *.spec.ts, *_test.py, test_*.py, etc.)
2. Count test files, describe blocks, and test cases
3. Report: "This project has N tests across M files. K feature areas have tests but no specs."

### During /context:load

Include spec coverage in the context summary:

1. Scan `docs/backlog/*.md` for `type: shaped-work` in frontmatter
2. Count structured vs legacy backlog items
3. Report coverage in the context loaded output

### General

When discussing any feature or component:

1. Check if a spec exists for it in `docs/backlog/`
2. If not, note that the feature is unspecified
3. If tests exist but no spec, note the gap

## What This Skill Does NOT Do

- Does NOT block any workflow — only warns and informs
- Does NOT create specs automatically — that requires human review via /define
- Does NOT modify files — read-only analysis
- Does NOT replace /context:load or /context:refresh — enhances them
