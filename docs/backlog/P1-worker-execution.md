---
spec_version: "1.0"
type: shaped-work
id: worker-execution
title: "Worker Execution Mode for Repository Operations"
status: shaped
created: 2026-02-04
appetite: big
priority: P1
target_project: genie-team
author: shaper
depends_on: []
tags: [worker, git, execution, repositories, pr-automation]
acceptance_criteria:
  - id: AC-1
    description: "CLI supports --worker flag or mode that enables repository operations"
    status: pending
  - id: AC-2
    description: "Workspace manager creates isolated workspace per execution in /workspaces/{job_id}/"
    status: pending
  - id: AC-3
    description: "Git operations supported: clone, branch, commit, push (no force push)"
    status: pending
  - id: AC-4
    description: "GitHub integration creates PR with design doc link and backlog item reference"
    status: pending
  - id: AC-5
    description: "Branch naming follows convention: genie/{backlog-item}-{phase}"
    status: pending
  - id: AC-6
    description: "Credential management via GitHub App or environment variables (no hardcoded secrets)"
    status: pending
  - id: AC-7
    description: "Workspace cleaned up after execution (success or failure)"
    status: pending
  - id: AC-8
    description: "CLI without --worker flag works exactly as before (backward compatible)"
    status: pending
---

# Shaped Work Contract: Worker Execution Mode

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
  - New `--worker` flag for CLI
  - Workspace lifecycle management (create, execute, cleanup)
  - Git operations: clone, branch, commit, push
  - GitHub PR creation with metadata
  - Credential management for repository access
- **No-gos:**
  - No force push or destructive git operations
  - No direct push to main/master
  - No submodule handling (future)
  - No monorepo sparse checkout (future)
  - No modifications to existing CLI behavior without --worker
- **Fixed elements:**
  - Must use feature branches (never commit to default branch)
  - Must include conventional commit format with genie attribution
  - Must require explicit GitHub credentials (no inference)

## Goals

**Outcome Hypothesis:** "We believe worker execution will eliminate manual code transfer time (5-10 min) and reduce copy/paste errors to zero while maintaining code review gates."

**Success Signals:**
- Code lands in branch within 30 seconds of Crafter completion
- PR created automatically with backlog item reference
- Zero manual file operations required
- Existing CLI behavior unchanged without --worker flag

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| Git operations from genie are safe | Feasibility | Spike: branch/commit/push to test repo |
| Feature branch isolation is sufficient | Viability | Review: can branch break main? |
| Workspace cleanup prevents disk bloat | Feasibility | Measure workspace size over 10 runs |
| GitHub App provides adequate permissions | Feasibility | Test: clone private repo, create PR |

## Solution Sketch

### CLI Flag

```bash
# Current behavior (unchanged)
genie-team /deliver docs/backlog/P1-feature.md

# Worker mode (new)
genie-team --worker /deliver docs/backlog/P1-feature.md
```

### Execution Flow

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Worker Execution Flow                                     │
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

### Branch Naming Convention

```
genie/{backlog-item}-{phase}

Examples:
- genie/P1-user-auth-deliver
- genie/P1-designer-genie-design
- genie/GT-42-implement
```

### Commit Message Format

```
<type>(<scope>): <subject>

<body from design document summary>

Co-Authored-By: Crafter Genie <crafter@genie.team>
Refs: docs/backlog/P1-feature.md
```

### Credential Management

**Option 1: GitHub App (Recommended)**
- Scoped permissions per repository
- No long-lived tokens
- Audit trail

**Option 2: Environment Variables**
```bash
GITHUB_TOKEN=ghp_... genie-team --worker /deliver ...
```

### Safety Constraints

- **Never** push to main/master
- **Never** use force push
- **Never** delete branches
- **Always** create PR (no direct merge)
- **Always** include Co-Authored-By attribution

### Workspace Lifecycle

```
Create workspace
    │
    ▼
Clone repo (shallow, default branch)
    │
    ▼
Create feature branch
    │
    ▼
Execute genie (with file access)
    │
    ├─► Success: Commit → Push → PR → Cleanup
    │
    └─► Failure: Cleanup only (no commit)
```

## Dependencies

- GitHub API access (gh CLI or direct API)
- Workspace directory permissions
- Git credentials (GitHub App or PAT)
- P1-crafter-repo-aware-execution (related, can be merged)

## Options (Ranked)

### Option 1: Integrated Worker Flag (Recommended)
- **Description:** Add `--worker` flag to existing CLI
- **Pros:** Single codebase, natural extension
- **Cons:** Increases CLI complexity
- **Appetite fit:** Good

### Option 2: Separate Worker Binary
- **Description:** `genie-worker` as separate command
- **Pros:** Clear separation, independent lifecycle
- **Cons:** Two things to install, maintain
- **Appetite fit:** Acceptable

## Routing

- [x] **Architect** — Needs design for workspace lifecycle, credential flow, and git safety

**Rationale:** Git operations require careful design for safety and error handling.

## Artifacts

- **Contract saved to:** `docs/backlog/P1-worker-execution.md`
- **Discovery referenced:** `docs/analysis/20260204_discover_worker_based_execution.md`
- **ADR referenced:** `docs/decisions/ADR-001-thin-orchestrator.md`
- **Related:** `docs/backlog/P1-crafter-repo-aware-execution.md`
