---
type: context
domain: current_work
updated: 2026-08-18
updated_by: scout
---

# Current Work

## Active

- **domain-ontology (discovery)** — `docs/analysis/20260818_discover_domain_ontology.md` — discovered 2026-08-18.
  Meaning as the missing fourth knowledge pillar (terms/concepts/invariants have no artifact, loader, or
  drift detection). Status: discovery complete. Next: `/handoff discover shape`.
  Quick win flagged: correct the product description in `docs/context/strategy.md` (currently describes a
  different product — see snapshot S1).

## Recently Shipped

- **P0-failure-mode-hardening** — merged to main 2026-08-04 (`7e4be84`) plus installer portability fix
  (`a706304`). Session ground-truth hooks, mandatory security pass, verification-block gates, genies/ tree
  removed, `make test` fixed.

## Open Branches / PRs (informational)

- `genie/P1-npm-distribution-design` — local branch, unmerged: npm distribution design (ADR-007). Has its
  own current_work.md that will conflict with this file on merge — resolve by merging both Active entries.
- **#34** gemini-3-pro default, **#35** discovery batch — open PRs on origin.
- **#21** GitHub Actions genie integration — stale since April; identified as the key unlock for the
  no-terminal PM workflow (2026-08-10 discussion).
