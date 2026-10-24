---
spec_version: "1.0"
type: capability-spec
id: program-direction
title: "In-Session Program Direction"
status: active
domain: workflow
created: 2026-10-24
updated: 2026-10-24
author: shaper
tags: [workflow, parallel, git-worktrees, orchestration, director, subagents]
acceptance_criteria:
  - id: AC-1
    description: >-
      A program is a backlog item with kind: program that lists its slice items under slices:.
      Each slice item has kind: slice and starts_when (the slice items that must merge first).
      The program body carries a Slice protocol (ownership map, shared seams, numbering ranges,
      runtime isolation) and a Program board. The shaped-work schema documents these fields,
      the board has its own schema, and lint-docs rejects a slices path that does not exist
      or a starts_when entry that is not a slice of the same program.
    status: met
  - id: AC-2
    description: >-
      The Director genie (agents/director.md) holds the program's intent, coordinates and
      oversees every genie in it, and never writes code. Its charter covers the board, the tick,
      preflight, dispatch, requests and shared contracts, the merge gate, the health check,
      failure handling, and reporting. It uses genie-team vocabulary and has no separate persona.
      It names no project, path, or tool installed outside genie-team. Verify, regenerate, and
      health-check commands come from the program item. Only verify falls back, to the stack
      profile's Verification section; with no verify command anywhere, /direct reports that and
      stops.
    status: met
  - id: AC-3
    description: >-
      /direct [program] runs one tick. With no path it ticks every open program in
      docs/backlog/. Flags: --one, --status, --merge, --tidy, --no-wake. Unattended direction is
      /loop /direct. Each tick schedules its own wake-up: a minute or two when a slice is ready
      to merge or a request is blocking, 20 to 30 minutes while genies are working. A blocked or
      held slice stops only itself and the slices that start after it; the others keep going.
      The loop ends when no slice can move without the Navigator: every slice is merged, held,
      blocked, or waiting on a held or blocked slice.
    status: met
  - id: AC-4
    description: >-
      Everything runs inside the directing session. Crafters, Critics, and Tidiers are subagents
      of that session, and each Crafter or Tidier works in its own git worktree. The charter
      forbids out-of-process spawns (claude -p, genies run) and any budget or turn cap. A
      structural test fails if director.md or direct.md tells the Director to spawn out of
      process.
    status: met
  - id: AC-5
    description: >-
      Mid-run coordination. A Crafter that needs something outside its rows (a path another slice
      owns, a contract shared across slices, or a missing dependency) writes it under Requests in
      its own slice item and commits it on its branch. Every tick the Director reads each live
      branch's item and answers each open request by message to that Crafter. It records each
      cross-slice decision under Shared contracts in the program item, and messages every live
      Crafter the decision touches. A request that changes product scope goes to the Navigator
      and leaves that slice blocked.
    status: met
  - id: AC-6
    description: >-
      The merge gate, one slice at a time:
      1. Rebase in the slice's worktree.
      2. Regenerate generated files.
      3. Verify in the worktree.
      4. Check ownership: every changed path is in the slice's rows, a shared seam, a path the
         Director granted the slice under Shared contracts, or the slice's own docs.
      5. Merge to main with ff-only.
      6. Verify again on main.
      7. Mark the slice done (status: done; merged slices stay in docs/backlog/ until /done
         archives the whole program), then /commit with explicit paths.
      8. Remove the worktree and the branch.
      Nothing passes without a Critic approval logged at the branch head and the /deliver
      verification block; every hand-back clears the verdict. When main goes red after a merge,
      the Director forward-reverts the recorded merged range and puts the slice's work back on
      its branch before handing it back.
    status: met
  - id: AC-7
    description: >-
      After every merge the Director runs the health check: /diagnose scoped to the merged slice's
      paths, plus the program's configured complexity tool if there is one. A finding over the
      threshold becomes a tidy-<slug> item that a Tidier runs through the same gate. A tidy item
      never touches a path a live slice owns.
    status: met
  - id: AC-8
    description: >-
      Recovery. Attempts cap at 3 per slice and count only failures handed back to the Crafter
      (a verdict, a red verify, a rebase conflict). Misfires and usage-limit interruptions do not
      count. A Crafter whose subagent ended is respawned on its existing worktree and branch.
      After a compaction or in a new session, the next tick rebuilds the board from git and
      ListAgents.
    status: met
  - id: AC-9
    description: >-
      /direct runs only in trunk-based mode, merging into local main. In PR mode it reports why
      and stops. The settings template and README carry the permission rules the merge gate
      and Crafters need, including git rebase inside worktrees.
    status: met
---

# In-Session Program Direction

## Overview

Some work is too big for one backlog item but splits into slices whose dependencies are known. The Director genie runs a program like that from one Claude Code session, and its purpose is **continuous coordination and oversight**: genie-team's other workflows hand off at phase boundaries, while the Director watches every slice for the whole run.

- **Coordination.** It dispatches one Crafter per ready slice, each in its own git worktree, as parallel tracks inside the session. It answers the Crafters' requests while they work and records every decision that binds more than one slice.
- **Oversight.** It is the only path into local `main`: every merge is rebased, verified, ownership-checked, and fast-forwarded. After each merge it runs a health check and opens tidy work when the code drifts.
- **Continuity.** It works in ticks. Each tick rebuilds the board from git, acts, reports, and schedules the next tick, so oversight carries on while the person is away and survives a compaction or a new session.

## Relationship to the other workflow capabilities

| Capability | Who orchestrates | Where genies run | Unit of work |
|---|---|---|---|
| Lifecycle orchestration (`/feature`, `/run`) | the session | the session's thread | one item |
| Parallel sessions | the human, across terminals | one session per worktree | one item per session |
| Autonomous lifecycle (`genies daemon`, ADR-005) | the SDK process | out-of-process `query()` calls | a batch of items |
| **Program direction (`/direct`)** | **the Director, in the session** | **subagents of the session, one worktree each** | **a program of dependent slices** |

The daemon is for headless runs on a schedule. The Director is for a program a person starts from an interactive session and then leaves running. Its genies bill whatever that session bills (ADR-008).

## Terms

The Director uses the same vocabulary as every other genie-team document. It has no separate persona.

| Term | Meaning |
|---|---|
| program | a backlog item with `kind: program` that lists its slices |
| slice | a backlog item with `kind: slice`, delivered by one Crafter in its own worktree |
| tick | one cycle of the Director's loop: reconcile, coordinate, merge, check, report, schedule. A lock keeps two ticks from overlapping |
| preflight | the checks a slice must pass before the Director dispatches a Crafter |
| dispatch | spawning a Crafter or Tidier subagent for a slice or tidy item |
| merge gate | the serial rebase, verify, ownership check, and fast-forward into local `main` |
| `main` | the repository's default branch, whether it is named `main` or `master` |
| health check | `/diagnose` plus the program's complexity command, run after each merge |
| board | the `## Board` section of the program item, rewritten every tick |

## Implementation Evidence
<!-- Updated by /deliver on 2026-10-24 from P1-program-director -->

### Test Coverage
- tests/test_director.sh: 37 test cases covering AC-1
- tests/test_director.sh: 21 test cases covering AC-2
- tests/test_director.sh: 16 test cases covering AC-3
- tests/test_director.sh: 9 test cases covering AC-4
- tests/test_director.sh: 3 test cases covering AC-9
- tests/test_director.sh: 2 vocabulary test cases (no kitchen terms in installed artifacts)
- AC-5 to AC-8: charter sections checked structurally under AC-2; behavior needs a live program

### Implementation Files
- agents/director.md: the Director genie's charter
- commands/direct.md: the /direct command
- schemas/program-board.schema.md: program, slice, Slice Protocol, Shared Contracts, Board, Requests
- scripts/validate/validate-frontmatter.sh: kind and verdict enums
- scripts/validate/check-crossrefs.sh: slices exist; starts_when stays inside the program
- agents/crafter.md, agents/critic.md, agents/tidier.md: Skill tool; working under the Director
- templates/settings.json: git rebase allow rules

## Review Verdict
<!-- Updated by /discern on 2026-10-24 from P1-program-director -->

**Verdict:** APPROVED (after two review rounds; all findings fixed)
**ACs verified:** 9/9 met

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | Schemas document the fields; validators enforce enums, id format, slice existence and kind, block lists, no `..`, and starts_when scope; fixtures and tests green |
| AC-2 | met | All charter sections in genie-team vocabulary; commands read from `main`; verify falls back to the stack profile; no verify stops the tick |
| AC-3 | met | Flags, no-path ticking, scheduling only under `/loop`, held/blocked stop only their dependents, loop-end rule consistent across director, direct, and spec |
| AC-4 | met | In-session only, no caps (WILL NOT plus tests); worktree isolation for Crafters and Tidiers; cd discipline for respawns and Critics |
| AC-5 | met | Requests read per branch, answered by `SendMessage` to the agent ID, Shared Contracts committed on `main`. Live messaging awaits the smoke slice |
| AC-6 | met | Eight gate steps in order; entry needs a Critic approval at the branch head; exact-range forward revert plus revert-of-revert; `status: done` at step 7 |
| AC-7 | met | Health check after each merge; tidy items with ACs, design, allowed paths, committed before dispatch; never touch a live slice's paths |
| AC-8 | met | Attempt cap 3; misfires not counted, capped at 3 in a row; respawn on the existing worktree; rebuild from git plus the committed board |
| AC-9 | met | PR mode refused; narrowed rebase rules in the settings template and README |
