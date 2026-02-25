---
spec_version: "1.0"
type: spec
id: critic-review
title: Critic Code Review
status: active
created: 2026-02-25
domain: genies
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      Critic genie definition exists at agents/critic.md with sonnet model, read + bash tools
      (Read, Grep, Glob, Bash), plan permission mode, and spec-awareness + architecture-awareness +
      brand-awareness + code-quality skills
    status: met
  - id: AC-2
    description: >-
      /discern command activates Critic to review implementation against spec ACs, producing a
      Review Document with verdict (APPROVED/CHANGES_REQUESTED/BLOCKED) and AC status table
    status: met
  - id: AC-3
    description: >-
      Critic evaluates issues by risk-first priority (security > data integrity > correctness >
      performance > maintainability) with severity levels (critical/major/minor) and actionable
      fix suggestions including file, line, and suggested resolution
    status: met
  - id: AC-4
    description: >-
      Critic updates spec frontmatter AC statuses (pending to met or unmet) and writes verdict
      to backlog item frontmatter for structured gate detection by the autonomous lifecycle runner
    status: met
---

# Critic Code Review

The Critic genie reviews implementations against acceptance criteria using risk-based evaluation, evidence-based acceptance decisions, and constructive feedback. It validates AC fulfillment with evidence (test results, actual code, coverage metrics — not intentions or promises), identifies code quality issues by severity, checks pattern adherence and security, and makes verdicts: APPROVED, CHANGES REQUESTED, or BLOCKED.

The Critic is the automated quality gate in autonomous lifecycle runs — its verdict determines whether the lifecycle continues (APPROVED) or stops (BLOCKED/CHANGES REQUESTED).

## Acceptance Criteria

### AC-1: Genie definition with correct configuration
Critic genie definition at `agents/critic.md` specifies sonnet model for review judgment, read + bash tools (Bash restricted to test runners and git diff), plan permission mode, and spec-awareness + architecture-awareness + brand-awareness + code-quality skills. The Critic is the only genie with all three awareness skills, enabling it to check spec compliance, ADR compliance, and brand compliance in a single review.

### AC-2: Review Document with verdict
The `/discern` command produces a Review Document with YAML frontmatter per `schemas/review-document.schema.md`. The document includes a verdict (APPROVED / CHANGES_REQUESTED / BLOCKED), AC status table (pass/fail per criterion with evidence notes), code quality assessment (strengths and issues), test coverage analysis, security review checklist, and risk assessment. The verdict is also written to the backlog item's frontmatter `verdict` field.

### AC-3: Risk-first evaluation with severity levels
Issues are evaluated in risk-first priority order: security (can block deployment), data integrity (irreversible harm), correctness (does it work), performance (will it scale), maintainability (can we live with it). Each issue has severity (critical: must fix, major: should fix, minor: nice to fix), location (file:line), risk description, and suggested fix.

### AC-4: Spec and backlog frontmatter updates
After review, the Critic updates spec frontmatter AC statuses from `pending` to `met` or `unmet` based on evidence. It writes the `verdict` field to backlog item frontmatter for structured gate detection by the autonomous lifecycle runner (which reads `verdict:` from frontmatter as primary source, falling back to regex output parsing).

## Evidence

### Source Code
- `agents/critic.md`: Genie definition with charter, judgment rules, verdict authority, anti-patterns
- `genies/critic/CRITIC_SPEC.md`: Detailed specification
- `genies/critic/CRITIC_SYSTEM_PROMPT.md`: System prompt
- `genies/critic/REVIEW_DOCUMENT_TEMPLATE.md`: Review document template
- `commands/discern.md`: Slash command definition
- `schemas/review-document.schema.md`: Review document schema

### Tests
- `tests/test_execute.sh`: 62 tests covering command execution and genie invocation patterns
- `tests/test_run_pdlc.sh`: 273 tests — verdict detection tests validate gate integration
