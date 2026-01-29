---
spec_version: "1.0"
type: execution-report
id: "{ID}"
title: "{Title}"
status: "{complete|partial|failed|blocked}"
created: "{YYYY-MM-DDTHH:MM:SSZ}"
spec_ref: "{docs/specs/domain/capability.md or docs/backlog/Pn-topic.md}"
design_ref: "{docs/backlog/Pn-topic.md}"
execution_mode: "{interactive|headless}"
exit_code: 0
confidence: "{high|medium|low}"
branch: "{feat/id-title-slug}"
commit_sha: "{sha}"
files_changed:
  - action: "{added|modified|deleted}"
    path: "{path/to/file}"
    purpose: "{Why this file changed}"
test_results:
  passed: 0
  failed: 0
  skipped: 0
  command: "{npm test|pytest|etc}"
  tests:
    - name: "{test_name}"
      status: "{pass|fail|skip|error}"
      duration_ms: 0
      ac_id: "{AC-n}"
acceptance_criteria:
  - id: AC-1
    status: "{met|not_met|partial|skipped}"
    evidence: "{How verified or why not met}"
---

# Execution Report: {Title}

> **Schema:** `schemas/execution-report.schema.md` v1.0
>
> All structured data lives in the YAML frontmatter above. The body below
> is free-form narrative for human context. Machines parse frontmatter only.

## Summary

[What was built -- 2-3 sentences]
[Key decisions made during implementation]

## Implementation Decisions

- [Decision 1]: [What and why]
- [Decision 2]: [What and why]

## Quality Checklist

- [ ] Tests written first (TDD)
- [ ] All tests passing
- [ ] No hardcoded values
- [ ] Error handling complete
- [ ] Type hints on public methods
- [ ] Follows project patterns

## Warnings & Blockers

[Any issues encountered, deferred items, or concerns for the Critic]

## Handoff to Critic

**Ready for review:** [Yes / No]
**Test command:** `{test command}`
**Key review areas:** [What to focus on]
