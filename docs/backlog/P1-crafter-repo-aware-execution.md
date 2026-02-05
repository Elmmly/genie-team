---
spec_version: "1.0"
type: shaped-work
id: crafter-repo-aware-execution
title: "Repo-Aware Crafter Execution"
status: shaped
created: 2026-02-04
appetite: medium
priority: P1
target_project: genie-team
author: shaper
depends_on: []
tags: [crafter, git, repositories, execution]
spec_ref: docs/specs/crafter-repo-execution.md
acceptance_criteria:
  - id: AC-1
    description: "Crafter can clone target repository to isolated workspace before execution"
    status: pending
  - id: AC-2
    description: "Crafter creates feature branch (genie/{workflow_id}-deliver) for isolation"
    status: pending
  - id: AC-3
    description: "Crafter writes code directly to files in workspace (not markdown artifacts)"
    status: pending
  - id: AC-4
    description: "Crafter commits changes with conventional commit message including genie attribution"
    status: pending
  - id: AC-5
    description: "Crafter pushes branch and can create PR with design document as description"
    status: pending
  - id: AC-6
    description: "Workspace is cleaned up after execution (success or failure)"
    status: pending
---

# Shaped Work Contract: Repo-Aware Crafter Execution

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Original input:** Crafter produces code as markdown artifacts that users must manually copy to files.

**Reframed problem:** How do we enable Crafter to write code directly to a repository, creating branches and commits that integrate with standard git workflows?

## Evidence & Insights

- **From Discovery:** `docs/analysis/20260204_discover_worker_based_execution.md`
- **Behavioral Signals:** 5-10 minutes per feature for manual code transfer; copy/paste errors
- **JTBD:** "When Crafter finishes implementing, I want code committed to a branch so I can review the diff and merge."

## Appetite & Boundaries

- **Appetite:** Medium (3-5 days)
- **Boundaries:**
  - Workspace management (clone, branch, cleanup)
  - Direct file writes via existing `write_file` tool pattern
  - Git operations: branch, commit, push
  - PR creation via GitHub API
  - Commit message with genie attribution
- **No-gos:**
  - No force push or destructive git operations
  - No direct push to main/master
  - No submodule handling (future)
  - No monorepo sparse checkout (future)
- **Fixed elements:**
  - Must use feature branches (never commit to default branch)
  - Must include conventional commit format

## Goals

**Outcome Hypothesis:** "We believe repo-aware execution will eliminate manual code transfer time (5-10 min) and reduce copy/paste errors to zero."

**Success Signals:**
- Code lands in branch within 30 seconds of Crafter completion
- PR description includes linked design document
- Zero manual file operations required

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|------------|------|--------------|
| Git operations from genie are safe | feasibility | Spike: branch/commit/push to test repo |
| Feature branch isolation is sufficient | viability | Review: can branch break main? |
| Workspace cleanup prevents disk bloat | feasibility | Measure workspace size over 10 runs |

## Options (Ranked)

### Option 1: Integrated Git Tools for Crafter (Recommended)
- **Description:** Add `git_branch`, `git_commit`, `git_push`, `create_pr` tools to Crafter's tool set
- **Pros:** Crafter controls git operations; aligns with tool use pattern
- **Cons:** Requires careful prompt engineering to avoid misuse
- **Appetite fit:** Good

### Option 2: Post-Execution Git Handler
- **Description:** Separate process handles git after Crafter writes files
- **Pros:** Simpler Crafter; separation of concerns
- **Cons:** Can't react to git errors during execution
- **Appetite fit:** Good (alternative approach)

## Dependencies

- Genie tool use (completed — P1-genie-tool-use)
- Git workspace management (new)
- GitHub API access (moderate)

## Routing

- [x] **Architect** — Needs design for workspace lifecycle and git tool implementation

**Rationale:** Git operations require careful design for safety and error handling.

## Solution Sketch

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                    Crafter Execution Flow (Repo-Aware)                       │
├─────────────────────────────────────────────────────────────────────────────┤
│                                                                             │
│  1. Pre-execution setup                                                     │
│     ├─► Clone repo to /workspaces/{job_id}/                                 │
│     ├─► Create branch: genie/{workflow_id}-deliver                          │
│     └─► Set working directory context                                       │
│                                                                             │
│  2. Crafter execution (with tools)                                          │
│     ├─► read_file: Understand existing code                                 │
│     ├─► list_files: Find relevant files                                     │
│     ├─► grep_code: Search for patterns                                      │
│     ├─► write_file: Create/modify code files                                │
│     └─► (loop until implementation complete)                                │
│                                                                             │
│  3. Post-implementation git operations                                      │
│     ├─► git_add: Stage changed files                                        │
│     ├─► git_commit: Create commit with conventional message                 │
│     │   └─► Message: "feat(auth): implement user login\n\nCo-Authored-By..."│
│     ├─► git_push: Push branch to remote                                     │
│     └─► create_pr: Open PR with design doc as description                   │
│                                                                             │
│  4. Cleanup                                                                 │
│     └─► Remove /workspaces/{job_id}/                                        │
│                                                                             │
└─────────────────────────────────────────────────────────────────────────────┘
```

### New Tools for Crafter

| Tool | Parameters | Description |
|------|------------|-------------|
| `git_branch` | `name` | Create and checkout new branch |
| `git_add` | `paths[]` | Stage files for commit |
| `git_commit` | `message`, `co_authors[]` | Create commit |
| `git_push` | `branch` | Push branch to remote |
| `create_pr` | `title`, `body`, `base` | Create pull request |

### Commit Message Format

```
<type>(<scope>): <subject>

<body - from design document>

Co-Authored-By: Crafter Genie <crafter@genie.team>
Refs: #<workflow_id>
```

### Workspace Lifecycle

```
Create workspace
    │
    ▼
Clone repo (shallow clone, default branch)
    │
    ▼
Create feature branch
    │
    ▼
Execute Crafter (with file access)
    │
    ├─► Success: Commit, push, PR, cleanup
    │
    └─► Failure: Cleanup only (no commit)
```

## Artifacts

- **Contract saved to:** `docs/backlog/P1-crafter-repo-aware-execution.md`
- **Discovery referenced:** `docs/analysis/20260204_discover_worker_based_execution.md`
