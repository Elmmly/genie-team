---
spec_version: "1.0"
type: capability-spec
id: parallel-sessions
title: "Parallel Sessions via Git Worktrees"
status: active
domain: workflow
created: 2026-02-12
updated: 2026-02-12
author: shaper
tags: [workflow, parallel, git-worktrees, isolation, sessions]
acceptance_criteria:
  - id: AC-1
    description: "Multiple Claude Code sessions can operate on the same repository simultaneously using git worktrees, each on a separate branch with no file or index conflicts during parallel operation; merge conflicts when merging to main are resolved via standard git merge workflow"
    status: met
  - id: AC-2
    description: "install.sh supports installing genie-team into a worktree (not just the main working tree)"
    status: met
  - id: AC-3
    description: "Autonomous execution rules document worktree-aware behavior: branch naming, worktree lifecycle, and conflict avoidance"
    status: met
  - id: AC-4
    description: "Target project CLAUDE.md template includes parallel session guidance when worktree mode is configured"
    status: met
  - id: AC-5
    description: "Genie memory (.claude/agent-memory/) is either shared via symlink or isolated per worktree, with a documented convention"
    status: met
  - id: AC-6
    description: "Safety rules prevent destructive operations that affect sibling worktrees (e.g., force-pushing shared branches, deleting the main worktree's branch)"
    status: met
---

# Parallel Sessions via Git Worktrees

## Overview

Enable multiple genie-team sessions — both human-led (interactive) and orchestrator-driven (autonomous) — to work on the same local git repository simultaneously. Each session operates in its own git worktree — a separate working directory that shares the repository's object store but has its own branch checkout and file state.

## Primary Use Cases

1. **Autonomous lifecycle runner (primary):** Cron-triggered or API-dispatched execution of multiple backlog items in parallel, each in its own worktree
2. **Human parallel sessions (secondary):** Developer manually creates worktrees to work on multiple features simultaneously in separate terminal windows

## Workflow Domain

The `workflow` domain covers how genie-team sessions are structured, how phases connect, and how parallel work is coordinated:

| Concern | Domain | Artifacts |
|---------|--------|-----------|
| WHAT to build | `specs/{domain}/` | Capability specs |
| HOW to build | `decisions/` | ADRs |
| HOW IT LOOKS | `brand/` | Brand guides |
| HOW IT FLOWS | `specs/workflow/` | Workflow specs |

## Core Concept

```
repo/                          # Main worktree (user's interactive session)
  .git/                        # Shared object store
  .claude/                     # Installed genie-team (tracked)
  docs/                        # Document trail

../repo--session-A/            # Worktree A (claude session on branch genie/P1-auth-deliver)
  .claude/                     # Same tracked files, own working state
  docs/                        # Own copy (changes visible after merge)

../repo--session-B/            # Worktree B (claude session on branch genie/P2-search-design)
  .claude/                     # Same tracked files, own working state
  docs/                        # Own copy
```

Git worktrees share the `.git/` object store but give each session:
- Its own working directory (no file conflicts)
- Its own branch (required by git — no two worktrees on the same branch)
- Its own index (no staging conflicts)
- Its own copy of tracked files (`.claude/`, `docs/`, source code)

## Alignment with Existing Conventions

This capability builds on existing genie-team patterns:

- **PR mode branch naming** (`genie/{item}-{phase}`) already produces unique branches per work item — one branch per worktree is natural
- **ADR-001 Thin Orchestrator** — orchestrators spawn CLI processes, each in its own worktree
- **Workspace Boundaries** rule — genies operate within repo root, which in a worktree is the worktree directory
- **Stateless commands** — genie-team commands are already designed for independent invocation

## Constraints

- Genie-team is a prompt engineering project — deliverables are conventions, rules, docs, and install.sh changes
- No application code, no process manager, no runtime coordination
- Worktree lifecycle management is the user's or orchestrator's responsibility
- Git worktree is a built-in git feature requiring no additional tooling

## Design Constraints
<!-- Updated by /design on 2026-02-12 from parallel-sessions-git-worktrees -->
- Worktree detection uses `git rev-parse --git-dir` vs `--git-common-dir` comparison (no external tools)
- install.sh auto-detects worktree context — no `--worktree` flag needed (backwards compatible)
- MCP scope switches from `local` to `user` when installing in a worktree (shared across sessions)
- Genie memory defaults to shared via symlink to main worktree; isolation is opt-out (remove symlink)
- CLAUDE.md template uses `<!-- worktree-enabled -->` comment pattern (consistent with `<!-- trunk-based -->`)
- Claude Code `--resume` works WITHIN a single worktree across chained commands, does NOT work ACROSS worktrees (Claude Code treats each worktree path as a separate project)
- No cross-worktree coordination protocol — git's branch-per-worktree constraint is the isolation mechanism
- No in-session dispatch from active Claude sessions — human users create worktrees and open new terminals; orchestrators use the CLI contract. Rationale: in-session dispatch degrades the human experience (no unified view, no result injection, log file monitoring instead of interactive control). The human IS the orchestrator in interactive mode.

## Cost Implications

Parallel sessions multiply per-session costs:
- 3 parallel `claude -p` invocations with `--max-budget-usd 5` each = $15 max spend
- Orchestrators should implement aggregate budget tracking if cost control is critical
- Convention for shared budget is not yet standardized — this is the orchestrator's responsibility per ADR-001

## Autonomous Runner Forward-Compatibility
<!-- Added by architect+shaper review on 2026-02-12 -->

The following gaps were identified during review for the upcoming autonomous lifecycle runner:

| Gap | Severity | Resolution |
|-----|----------|------------|
| No worktree cleanup convention for failed autonomous runs | Critical | Runner must implement: delete orphaned branch + worktree before retry |
| No merge conflict resolution policy for autonomous context | Critical | Runner should rebase before PR; exit code 2 = conflict needing human resolution |
| No retry branch naming convention | Important | Clean retry (delete + recreate) or rename failed branch with timestamp suffix |
| Pre-commit hook scripts need symlink convention per worktree | Important | Symlink `hooks/` directory in worktree to main worktree's `hooks/` |
| MCP `user` scope may conflict across multiple projects | Important | Check-before-install; skip if MCP already present at user scope |
| Concurrent write contention on shared agent memory | Low | Last-write-wins acceptable for metadata; file-per-topic convention mitigates |

These are NOT blocking for human-led parallel sessions (this item's primary delivery). They WILL need to be addressed when the autonomous lifecycle runner is built.

## Implementation Evidence
<!-- Updated by /deliver on 2026-02-12 from parallel-sessions-git-worktrees -->

### Test Coverage
- tests/test_worktree.sh: 23 test cases covering AC-1, AC-2, AC-3, AC-4, AC-5, AC-6

### Implementation Files
- install.sh: Added detect_worktree(), get_main_worktree(), worktree-aware cmd_project() with MCP scope and memory symlink
- .claude/rules/autonomous-execution.md: Added "Parallel Sessions via Git Worktrees" section with safety rules, branch conventions, human-led and orchestrator-driven patterns
- templates/CLAUDE.md: Added "Parallel Sessions" section with worktree-enabled comment marker
- docs/architecture/cli-contract.md: Added "Parallel Invocation via Worktrees" section with orchestrator examples

## Review Verdict
<!-- Updated by /discern on 2026-02-12 from parallel-sessions-git-worktrees -->

**Verdict:** APPROVED
**ACs verified:** 6/6 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | cli-contract.md documents worktree invocation; safety rules address merge conflicts; design validated concurrent commits |
| AC-2 | met | detect_worktree() and get_main_worktree() in install.sh; cmd_project() adjusts MCP scope and creates memory symlink |
| AC-3 | met | autonomous-execution.md "Parallel Sessions via Git Worktrees" section with detection, safety, branch convention, human/orchestrator patterns |
| AC-4 | met | templates/CLAUDE.md "## Parallel Sessions" with `<!-- worktree-enabled -->` marker following `<!-- trunk-based -->` pattern |
| AC-5 | met | install.sh creates memory symlink to main worktree; isolation documented as opt-out |
| AC-6 | met | 5 safety rules in autonomous-execution.md covering force-push, file boundaries, main branch, branch checkout, merge conflicts |
