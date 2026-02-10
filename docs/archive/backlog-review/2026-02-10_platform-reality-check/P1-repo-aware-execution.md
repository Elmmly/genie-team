---
spec_version: "1.0"
type: shaped-work
id: repo-aware-execution
title: "Repo-Aware Execution with Git Integration"
status: superseded
created: 2026-02-04
superseded: 2026-02-10
superseded_by: docs/backlog/P1-autonomous-execution-readiness.md
appetite: big
priority: P1
target_project: genie-team
author: shaper
depends_on: []
tags: [worker, git, execution, repositories, pr-automation]
acceptance_criteria:
  - id: AC-1
    description: "Crafter can clone target repository to isolated workspace before execution"
    status: pending
  - id: AC-2
    description: "Feature branch created (genie/{backlog-item}-{phase}) for isolation"
    status: pending
  - id: AC-3
    description: "Code written directly to files in workspace (not markdown artifacts)"
    status: pending
  - id: AC-4
    description: "Changes committed with conventional commit message including genie attribution"
    status: pending
  - id: AC-5
    description: "Branch pushed and PR created with design document as description"
    status: pending
  - id: AC-6
    description: "Workspace cleaned up after execution (success or failure)"
    status: pending
  - id: AC-7
    description: "Safety constraints enforced: no force push, no push to main/master, no branch deletion"
    status: pending
---

# Shaped Work Contract: Repo-Aware Execution with Git Integration

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Original input:** `docs/analysis/20260204_discover_worker_based_execution.md`

**Reframed problem:** How do we enable genies to clone repos, create branches, write files, and open PRs so that implemented code lands in version control without manual intervention?

## Evidence & Insights

- **From Discovery:** 5-10 minutes per feature for manual code transfer; copy/paste errors common
- **Current limitation:** Crafter produces code as markdown artifacts, not actual file changes
- **Git workflow:** Feature branch isolation + PR review gate provides safety net
- **JTBD:** "When Crafter finishes implementing, I want code committed to a branch so I can review the diff and merge."

## Appetite & Boundaries

- **Appetite:** Big (2-3 weeks)
- **Boundaries:**
  - Workspace lifecycle management (clone, execute, cleanup)
  - Git operations: clone, branch, commit, push
  - GitHub PR creation with metadata
  - Credential management for repository access
- **No-gos:**
  - No force push or destructive git operations
  - No direct push to main/master
  - No submodule handling (future)
  - No monorepo sparse checkout (future)
- **Fixed elements:**
  - Must use feature branches (never commit to default branch)
  - Must include conventional commit format with genie attribution
  - Must require explicit GitHub credentials (no inference)

## Goals

**Outcome Hypothesis:** "We believe repo-aware execution will eliminate manual code transfer time (5-10 min) and reduce copy/paste errors to zero while maintaining code review gates."

**Success Signals:**
- Code lands in branch within 30 seconds of Crafter completion
- PR created automatically with backlog item reference
- Zero manual file operations required

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| Git operations from genie are safe | Feasibility | Spike: branch/commit/push to test repo |
| Feature branch isolation is sufficient | Viability | Review: can branch break main? |
| Workspace cleanup prevents disk bloat | Feasibility | Measure workspace size over 10 runs |
| GitHub App provides adequate permissions | Feasibility | Test: clone private repo, create PR |

## Solution Sketch

### Execution Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Repo-Aware Execution Flow                                │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Pre-execution setup                                                     │
│     ├─► Create workspace: /workspaces/{job_id}/                             │
│     ├─► Clone repo (shallow clone, default branch)                          │
│     ├─► Create branch: genie/{backlog-item}-{phase}                         │
│     └─► Set working directory context                                       │
│                                                                             │
│  2. Genie execution (existing behavior)                                     │
│     ├─► Read existing code                                                  │
│     ├─► Write new/modified files                                            │
│     └─► (normal genie workflow)                                             │
│                                                                             │
│  3. Post-execution git operations                                           │
│     ├─► Stage changed files (git add)                                       │
│     ├─► Create commit with conventional message                             │
│     │   └─► "feat(scope): description\n\nCo-Authored-By: Crafter..."       │
│     ├─► Push branch to remote                                               │
│     └─► Create PR with design doc as description                            │
│                                                                             │
│  4. Cleanup                                                                 │
│     └─► Remove /workspaces/{job_id}/                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### Safety Constraints

- **Never** push to main/master
- **Never** use force push
- **Never** delete branches
- **Always** create PR (no direct merge)
- **Always** include Co-Authored-By attribution

## Options (Ranked)

### Option 1: Integrated Git Tools for Crafter (Recommended)
- **Description:** Add git tools to Crafter's tool set via native `.claude/agents/` format
- **Pros:** Crafter controls git operations; aligns with tool use pattern; native enforcement
- **Cons:** Requires careful prompt engineering to avoid misuse
- **Appetite fit:** Good

### Option 2: Post-Execution Git Handler
- **Description:** Separate process handles git after Crafter writes files
- **Pros:** Simpler Crafter; separation of concerns
- **Cons:** Can't react to git errors during execution
- **Appetite fit:** Acceptable

## Dependencies

- Git workspace management (new)
- GitHub API access (gh CLI or direct API)
- Git credentials (GitHub App or PAT)

## Routing

- [x] **Architect** — Needs design for workspace lifecycle, credential flow, and git safety

**Rationale:** Git operations require careful design for safety and error handling.

## Artifacts

- **Contract saved to:** `docs/backlog/P1-repo-aware-execution.md`
- **Discovery referenced:** `docs/analysis/20260204_discover_worker_based_execution.md`
- **Consolidates:** `P1-worker-execution.md` + `P1-crafter-repo-aware-execution.md`

---

## Superseded — 2026-02-10

**Reason:** Claude Code natively supports full git workflow: clone repos, create branches, stage/commit/push changes, and create PRs with `Co-Authored-By` attribution. The Crafter genie already writes code directly to files — that's how Claude Code works. The proposed items (clone, branch, commit, push, PR creation) are all platform-native capabilities, not things genie-team needs to build.

The remaining genie-team-specific work is safety constraints for autonomous execution:
- Branch naming convention (`genie/{item}-{phase}`)
- No force push, no push to main/master
- Conventional commit format with genie attribution
- Workspace isolation (Cataliva's responsibility, not genie-team's)

These are `.claude/rules/` entries, not a big-batch implementation. Absorbed into `P1-autonomous-execution-readiness.md`.

---

# End of Shaped Work Contract
