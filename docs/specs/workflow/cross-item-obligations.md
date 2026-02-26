---
spec_version: "1.0"
type: capability-spec
id: cross-item-obligations
title: "Cross-Item Obligation Tracking"
status: active
domain: workflow
created: 2026-02-26
author: shaper
tags: [workflow, obligations, deferrals, cross-item, quality-gate]
acceptance_criteria:
  - id: AC-1
    description: >-
      Backlog items support a deferred_to frontmatter field containing structured
      entries with target (backlog item id), description (what was deferred), and
      phase (which phase the target must complete it in)
    status: pending
  - id: AC-2
    description: >-
      Crafter convention enforced in deliver command: when implementation defers
      any integration, wiring, or activation step to another item, Crafter MUST
      add a deferred_to entry to the source item AND add a corresponding AC to
      the destination item
    status: pending
  - id: AC-3
    description: >-
      Critic review checklist includes deferral check: does this implementation
      defer any steps to another task, and if so, has that task been updated with
      the obligation as an acceptance criterion
    status: pending
  - id: AC-4
    description: >-
      /done command scans all active backlog items for deferred_to entries
      pointing at the item being archived; warns with specific obligation
      details if any unresolved inbound deferrals exist
    status: pending
  - id: AC-5
    description: >-
      Pre-commit check-crossrefs.sh validates that deferred_to target fields
      resolve to existing backlog files, reporting broken references with
      source file and obligation description context
    status: pending
---

# Cross-Item Obligation Tracking

## Overview

When work on one backlog item defers a step to another item (e.g., "wire this component after Firebase setup is complete"), the obligation must be tracked structurally — not as prose in the source item that the destination never sees. This capability provides structured tracking of cross-item obligations with enforcement at three checkpoints: delivery (Crafter writes the obligation), review (Critic verifies it), and archival (`/done` checks for unresolved inbound obligations).

## Primary Use Cases

1. **Deferred integration:** Component A is built and reviewed, but wiring into the main app is deferred to Component B's delivery. The obligation is tracked so Component B's checklist includes the wiring step.
2. **Phased rollout:** Feature flag activation is deferred from the feature delivery item to a separate rollout item. The `/done` gate prevents archiving the rollout item without activating the flag.
3. **Cross-cutting concerns:** Auth token propagation is built in the auth item but session cache integration is deferred to the session item. The Critic catches this at review time.

## Constraints

- Pure prompt engineering — changes to command definitions, agent prompts, and one shell script
- The `deferred_to` field is optional — most items won't have deferrals
- Obligations are one-directional: source item defers TO destination item
- The destination item owns the obligation as an AC — the source just records the reference
