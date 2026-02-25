---
spec_version: "1.0"
type: spec
id: document-validation
title: Document Validation
status: active
created: 2026-02-25
domain: quality
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      lint-frontmatter-yaml.sh validates YAML syntax in frontmatter blocks (between ---
      delimiters) of markdown files, reporting parsing errors with file path context
    status: met
  - id: AC-2
    description: >-
      validate-frontmatter.sh checks required fields per document type (shaped-work, adr,
      architecture-diagram, spec, brand-spec, review, execution-report), validates enum
      values (status, appetite, level), and verifies acceptance_criteria is a non-empty
      array with id/description/status per entry
    status: met
  - id: AC-3
    description: >-
      check-crossrefs.sh verifies that cross-reference fields (spec_ref, adr_refs,
      brand_ref, superseded_by, supersedes) point to existing files or valid ADR ids,
      reporting broken references with source file context
    status: met
  - id: AC-4
    description: >-
      check-source-sync.sh detects drift between canonical source files in the repo root
      (commands/, agents/, skills/, rules/) and installed copies in .claude/, reporting
      out-of-sync artifacts that need reinstallation
    status: met
---

# Document Validation

Four validation scripts in `scripts/validate/` provide quality checks for the document trail. They can be run as pre-commit hooks (via `install.sh prehook`) or on-demand via the `genies quality` subcommand. Together they ensure that the project's persistent knowledge artifacts (specs, ADRs, diagrams, backlog items, brand guides, reviews) maintain structural integrity.

All scripts are pure bash with no runtime dependencies beyond standard Unix tools and optionally `yq` for YAML parsing. They follow a consistent pattern: scan files matching document patterns, validate against known schemas, and report issues with file path context.

## Acceptance Criteria

### AC-1: YAML frontmatter syntax validation
`lint-frontmatter-yaml.sh` extracts the YAML block between `---` delimiters in markdown files and validates syntax. It catches: malformed YAML (indentation errors, missing colons), unclosed strings, invalid characters, and missing frontmatter entirely (for files that should have it). Reports include the file path and nature of the syntax error.

### AC-2: Schema-aware field validation
`validate-frontmatter.sh` validates frontmatter content against the expected schema based on the `type` field. For each document type it checks: required fields are present, enum fields have valid values (e.g., status must be one of shaped/designed/implemented/reviewed/done/abandoned for shaped-work), field formats are correct (dates, IDs), and acceptance_criteria is a properly structured array with id, description, and status per entry.

### AC-3: Cross-reference integrity
`check-crossrefs.sh` validates that all cross-reference fields point to valid targets: `spec_ref` points to an existing spec file in `docs/specs/`, `adr_refs` entries point to existing ADRs in `docs/decisions/`, `brand_ref` points to an existing brand guide in `docs/brand/`, `superseded_by` and `supersedes` reference valid ADR ids. Broken references are reported with the source file path and the broken target.

### AC-4: Source-install sync detection
`check-source-sync.sh` compares canonical source files in the repo root directories (commands/, agents/, skills/, rules/, hooks/) against their installed copies in the target `.claude/` directory. It reports files that are out of sync (installed copy differs from source), missing from the installation, or present in the installation but removed from the source. This catches stale installations after upgrades.

## Evidence

### Source Code
- `scripts/validate/lint-frontmatter-yaml.sh`: YAML syntax validation
- `scripts/validate/validate-frontmatter.sh`: Schema-aware field validation
- `scripts/validate/check-crossrefs.sh`: Cross-reference integrity checking
- `scripts/validate/check-source-sync.sh`: Source-install drift detection

### Tests
- `tests/test_precommit.sh`: 47 tests covering all four validation scripts with valid and invalid fixtures
- `tests/fixtures/precommit/`: Test fixtures including valid docs, broken crossrefs, invalid YAML, missing fields, invalid enums
