---
spec_version: "1.0"
type: spike
id: spike-agent-teams-council-review
title: "Spike: Agent Teams Council Pattern for /discern"
status: shaped
created: 2026-02-05
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [spike, agent-teams, council, review, experimental]
acceptance_criteria:
  - id: AC-1
    description: "3 specialized critic agents defined (correctness, security, maintainability) and spawned as an Agent Teams council"
    status: pending
  - id: AC-2
    description: "Side-by-side comparison of single /discern vs 3-agent council review on the same implementation, documenting issues found, false positives, and total token cost"
    status: pending
  - id: AC-3
    description: "Findings document answers: Does multi-perspective review catch more real issues? Is the token cost justified? Is Agent Teams stable enough for this pattern?"
    status: pending
---

# Spike: Agent Teams Council Pattern for /discern

**Date:** 2026-02-05
**Question:** Does parallel multi-perspective review produce better outcomes than a single Critic pass?

---

## Context

Agent Teams (research preview, `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`) enables multiple independent Claude Code sessions to work as a coordinated team with peer-to-peer messaging. One documented pattern is the **Council** — multiple agents examine the same thing from different perspectives, then the lead synthesizes findings.

Currently, `/discern` runs a single Critic genie that checks:
- Acceptance criteria met/not met
- Pattern adherence
- Code quality
- Security concerns
- Test coverage

A council pattern would split this into specialized reviewers running in parallel, potentially catching issues a generalist reviewer misses due to attention dilution.

---

## Prerequisites

- Agent Teams experimental flag: `CLAUDE_CODE_EXPERIMENTAL_AGENT_TEAMS=1`
- Terminal that supports split panes (tmux or iTerm2) for visibility, or use in-process mode

---

## Test Plan

### Step 1: Define 3 specialized critic agents

Create in `.claude/agents/`:

**critic-correctness.md:**
```yaml
---
name: critic-correctness
description: "Acceptance criteria reviewer. Verifies each AC is met with evidence. Checks behavioral correctness against specs."
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
skills:
  - spec-awareness
---
```

**critic-security.md:**
```yaml
---
name: critic-security
description: "Security reviewer. Checks for OWASP top 10, input validation, injection vulnerabilities, secret exposure, and auth/authz issues."
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
---
```

**critic-maintainability.md:**
```yaml
---
name: critic-maintainability
description: "Maintainability reviewer. Checks pattern adherence, code quality, naming consistency, error handling, and test coverage."
model: sonnet
tools: Read, Grep, Glob, Bash
permissionMode: plan
skills:
  - pattern-enforcement
  - code-quality
---
```

### Step 2: Pick an implementation to review

Use a recent implementation with enough substance to review (e.g., the Designer genie implementation from earlier this session, or any non-trivial feature).

### Step 3: Run single Critic review

Standard `/discern` — note time, token cost, issues found.

### Step 4: Run council review

Spawn an Agent Teams council:
- Lead coordinates and assigns the same codebase to all 3 critics
- Each critic reviews independently from their specialization
- Lead synthesizes findings into a unified verdict

Note time, token cost per critic, total token cost, issues found per critic.

### Step 5: Document findings

Compare:

| Metric | Single /discern | Council (3 critics) |
|--------|----------------|---------------------|
| Total issues found | | |
| Unique issues (found by only one approach) | | |
| False positives | | |
| Token cost | | |
| Wall clock time | | |
| Missed issues (found by the other approach) | | |

Also evaluate:
- **Agent Teams stability:** Did task status lag? Did teammates finish cleanly? Any crashes?
- **Synthesis quality:** Did the lead successfully merge 3 review reports into a coherent verdict?
- **Cost/benefit:** Is 3x token cost justified by the additional issues found?

---

## Expected Outcomes

**If council is significantly better:** Worth building into genie-team as an opt-in `--council` flag on `/discern` for high-stakes reviews. Token cost justified for critical features.

**If council is marginally better:** Not worth the complexity and cost for routine reviews. Single Critic with good prompts is sufficient. Reserve council for pre-release audits.

**If council is equivalent or worse:** Multi-agent coordination overhead (synthesis, deduplication) negates the benefit of parallel perspectives. Single focused Critic wins on efficiency.

**If Agent Teams is too unstable:** Document the specific issues. Revisit when the feature graduates from research preview.

---

## Risk

This spike depends on an experimental feature. Known limitations:
- Task status can lag (teammates don't mark completion)
- No session resumption with in-process teammates
- Shutdown can be slow

If Agent Teams is too unstable to complete the spike, document the blockers and defer.

---

## Appetite

**Small batch (1 day).** 3 agent files, 2 review runs, comparison analysis. Slightly larger than other spikes due to Agent Teams setup, but the review itself is fast.

---

## Portfolio Orchestration Value Context (added 2026-02-10)

Multi-perspective review is directly relevant to autonomous PDLC workflows. When an orchestrator dispatches work across a product portfolio, the `/discern` gate determines whether implementation proceeds to merge. A council pattern could improve quality gate confidence for:

- **High-stakes PRs** — Security-critical changes, public API modifications
- **Unfamiliar codebases** — When the single Critic may lack domain context
- **Pre-release audits** — Final review before production deployment

If the spike shows the council pattern catches meaningfully more real issues, it becomes an opt-in `--council` flag on `/discern` that orchestrators can enable for specific review tiers.

**Priority rationale (P3 → P2):** With the backlog simplified (5 items removed), this spike is now the second most valuable item after autonomous execution readiness. Agent Teams stability is the main risk.

---

# End of Spike
