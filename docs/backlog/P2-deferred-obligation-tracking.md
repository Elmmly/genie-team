---
id: P2-deferred-obligation-tracking
title: Cross-Item Obligation Tracking
type: feature
status: shaped
priority: P2
appetite: small
spec_ref: docs/specs/workflow/cross-item-obligations.md
created: 2026-02-26
discovery_ref: null
github_issue: 6
---

# Shaped Work Contract: Cross-Item Obligation Tracking

## Problem

When work on one backlog item defers a step to another item, the obligation is written as prose in the source item's body — never as structured data, never as an AC in the destination item, never checked at archival. The destination item has no record of the inbound obligation. When it archives, the deferred step is silently lost.

**Who is affected:** Any team using the PDLC with multi-item workflows. The impact is silent — the deferred step doesn't visibly break anything until someone discovers the missing wiring months later.

**Evidence:** GitHub issue #6 documents a concrete case: `AuthenticatedApiProvider` was built, tested, and APPROVED. The review deferred wiring into `main.tsx` to the Firebase setup task. Firebase was completed and archived — but the wiring was never on its checklist. The component was never mounted. Every authenticated API call went out with no token for months.

**Root cause analysis:** The PDLC processes each backlog item in isolation. There is no cross-item coordination layer. Three places could have caught the deferral and didn't:

| Checkpoint | What Was Missing |
|------------|-----------------|
| `/discern` (review) | No checklist question about deferred steps |
| `/deliver` (authoring) | No convention to write the deferred step as an AC in the destination item |
| `/done` (archival) | No scan for open obligations pointing at the item being archived |

**Claude Code internals context:** The reinject-context hook preserves within-session context after compaction, but deferrals span across items and sessions — they need to be persisted structurally in the document trail, not in session state. Hooks are observational today (track what happened) but not prescriptive (enforce what should happen next). The `check-crossrefs.sh` pre-commit hook already validates `spec_ref`, `adr_refs`, and `backlog_ref` — extending it to validate `deferred_to` is a natural fit.

## Appetite & Boundaries

- **Appetite:** Small batch (1-2 days) — all changes are prompt engineering + one shell script extension
- **No-gos:**
  - Do NOT build a dependency graph or topological sort of backlog items
  - Do NOT add a Claude hook (C1 structural gate) for write-time validation — that's a future enhancement if pre-commit validation proves insufficient
  - Do NOT change the schema for existing `depends_on` field — that's for blocking dependencies (must complete before starting), not deferred obligations (work pushed from one item to another)
  - Do NOT add automated resolution (auto-closing obligations when target ACs are met) — manual verification is fine for v1
- **Fixed elements:**
  - The `deferred_to` field is optional — most items won't have deferrals
  - The destination item owns the obligation as an AC
  - Pre-commit validation follows the existing `check-crossrefs.sh` pattern
  - All changes are prompt engineering (markdown files) except the crossref script extension

## Goals & Outcomes

- **Primary:** When Crafter defers work to another item, the obligation is tracked structurally and cannot be silently lost at archival
- **Critic catches deferrals at review:** The review checklist explicitly asks "does this defer any steps?" before APPROVED verdict
- **`/done` warns on unresolved obligations:** Before archiving, scan for inbound `deferred_to` references and warn if the corresponding AC in this item is not met
- **Pre-commit catches broken references:** If a `deferred_to` target is renamed or deleted, the commit fails with a clear error

## Solution Sketch

### 1. `deferred_to` frontmatter field

Add to the shaped-work-contract schema:

```yaml
deferred_to:
  - target: P2-firebase-setup
    description: "Wire AuthenticatedApiProvider into main.tsx"
    phase: deliver
```

### 2. Crafter convention (deliver command)

Add to `commands/deliver.md` scope discipline section:

> When deferring any integration, wiring, or activation step to another item: (1) add a `deferred_to` entry to this item's frontmatter, and (2) add a corresponding AC to the destination item. The destination item owns the obligation — this item just records the reference.

### 3. Critic checklist addition (discern command)

Add item 10 to the review checklist in `commands/discern.md`:

> 10. **Deferred obligations?** Does this implementation defer any integration or wiring steps to another task? If so, verify: (a) `deferred_to` field is populated in frontmatter, and (b) destination task has a corresponding AC.

### 4. `/done` obligation scan

Add to `commands/done.md` before archival:

> Before archiving, scan all active `docs/backlog/*.md` files for `deferred_to` entries where `target` matches this item's id. For each inbound obligation: check whether this item has a corresponding AC that is met. If any inbound obligations point to unmet ACs, warn with specific details and ask for confirmation before proceeding.

### 5. Pre-commit cross-reference extension

Extend `scripts/validate/check-crossrefs.sh` to validate `deferred_to[].target` fields resolve to existing files in `docs/backlog/`.

## Behavioral Delta

**Spec:** docs/specs/genies/critic-review.md

### Current Behavior
- AC-2: /discern reviews implementation against spec ACs with 9-item checklist (ACs, spec ACs, code quality, test coverage, security, performance, error handling, risks, ADR compliance)

### Proposed Changes
- AC-2: Review checklist expands to 10 items — adding "deferred obligations?" check
- AC-NEW: Critic verifies `deferred_to` entries have corresponding ACs in destination items

### Rationale
The Critic is the last automated checkpoint before `/done`. If it doesn't ask about deferrals, they silently pass through review.

---

**Spec:** docs/specs/quality/document-validation.md

### Current Behavior
- AC-3: check-crossrefs.sh verifies spec_ref, adr_refs, brand_ref, superseded_by, supersedes

### Proposed Changes
- AC-3: check-crossrefs.sh additionally verifies deferred_to[].target fields resolve to existing backlog files

### Rationale
The cross-reference check already validates all structured references between documents. `deferred_to` is the same pattern — a structured reference that must point to a real file.

---

**Spec:** docs/specs/workflow/lifecycle-orchestration.md

### Current Behavior
- AC-3: /done archives completed work to docs/archive/ while preserving specs, ADRs, and brand guides

### Proposed Changes
- AC-3: /done additionally scans for inbound deferred_to references before archiving and warns if unresolved obligations exist

### Rationale
Archival is the point of no return — once an item is in `docs/archive/`, it drops out of active backlog scans. If unresolved obligations exist, they become invisible.

## Risks & Assumptions

| Assumption | Type | Test |
|------------|------|------|
| Crafter will actually populate `deferred_to` when deferring work | compliance | The Critic checklist catches it at review; pre-commit catches broken refs. If >50% of deferrals are still missed after implementation, consider a Claude hook (C1 gate) for write-time enforcement |
| Most items don't have deferrals | value | Monitor first 10 items through the pipeline. If >30% have deferrals, the mechanism is being used as a crutch for poor scoping |
| Scanning all active backlog items in `/done` is fast enough | feasibility | The backlog directory is small (<20 items typically). grep through YAML frontmatter is sub-second |
| The `deferred_to` field won't be confused with `depends_on` | usability | Document the distinction: `depends_on` = must complete BEFORE this item starts; `deferred_to` = this item pushes work TO another item |

## Acceptance Criteria

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

## Routing

- **Next genie:** Architect — lightweight design pass to confirm the exact prompt changes and shell script extension
- **Or skip to Crafter:** The solution is well-understood enough that a Crafter could implement directly with TDD. The "design" is essentially the prompt diffs described in the solution sketch above.

---

# End of Shaped Work Contract
