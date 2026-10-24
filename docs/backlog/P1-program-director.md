---
spec_version: "1.0"
type: shaped-work
id: P1-program-director
title: "Direct a program of slices from one session"
status: designed
created: 2026-10-24
updated: 2026-10-24
appetite: medium
complexity: moderate
priority: P1
author: shaper
spec_ref: docs/specs/workflow/program-direction.md
adr_refs:
  - docs/decisions/ADR-008-in-session-program-direction.md
tags: [workflow, orchestration, director, worktrees, subagents]
acceptance_criteria:
  - id: AC-1
    description: >-
      Program and slice items are in the schema. The shaped-work schema gains optional fields:
      kind (program | slice), slices, starts_when, verdict, design_section, plus the
      program-level verify, regenerate, and health_check. A new schemas/program-board.schema.md
      defines the Slice protocol and the Program board. lint-docs rejects a slices path that does
      not exist and a starts_when entry that is not a slice of the same program.
    status: pending
  - id: AC-2
    description: >-
      agents/director.md ports the trial charter, generalized: no project names, absolute paths,
      or tools from outside genie-team, and genie-team vocabulary with no separate persona.
      Verify, regenerate, and health-check commands come from
      the program item. Only verify falls back, to the stack profile's Verification section;
      with no verify command anywhere, /direct reports that and stops.
    status: pending
  - id: AC-3
    description: >-
      commands/direct.md: one tick per call; no path ticks every open program; flags --one,
      --status, --merge, --tidy, --no-wake; /loop /direct runs it unattended with self-paced
      wake-ups; a blocked or held slice stops only itself and its dependents; the loop ends when
      no slice can move without the Navigator.
    status: pending
  - id: AC-4
    description: >-
      Everything runs in the session. Crafters, Critics, and Tidiers are subagents of the
      directing session, and Crafters and Tidiers run with worktree isolation. The charter
      forbids claude -p, genies run, and budget or turn caps. tests/test_director.sh fails if
      director.md or direct.md tells the Director to spawn out of process.
    status: pending
  - id: AC-5
    description: >-
      Mid-run coordination. Crafters write cross-slice needs under Requests in their own slice
      item on their branch. Every tick the Director answers each open request by message. It
      records each cross-slice decision under Shared contracts in the program item and messages
      every live Crafter it affects. A request that changes scope goes to the Navigator.
    status: pending
  - id: AC-6
    description: >-
      The merge gate:
      1. Rebase in the worktree.
      2. Run the regenerate command.
      3. Verify in the worktree.
      4. Check ownership, counting paths granted under Shared contracts.
      5. Merge to main with ff-only.
      6. Verify again on main.
      7. Run /done, then /commit.
      8. Remove the worktree and the branch.
      A slice passes only with verdict APPROVED and the /deliver verification block on its item.
      A red main is restored with a forward revert.
    status: pending
  - id: AC-7
    description: >-
      Health check after each merge: /diagnose scoped to the merged paths, plus the
      health_check command if the program sets one. A finding over the threshold becomes a tidy-<slug> item
      for a Tidier. A tidy item never touches a path a live slice owns.
    status: pending
  - id: AC-8
    description: >-
      Recovery. Attempts cap at 3 per slice and count only failures handed back to the Crafter.
      Misfires and usage-limit interruptions are logged but not counted. An ended Crafter is
      respawned on its existing worktree. The tick rebuilds the board from git and ListAgents
      after a compaction.
    status: pending
  - id: AC-9
    description: >-
      Trunk-based only: in PR mode /direct reports why and stops. templates/settings.json and
      README carry the permission rules the merge gate and Crafters need, including git rebase inside
      .claude/worktrees/.
    status: pending
  - id: AC-10
    description: >-
      Docs and distribution:
      - rules/workflow.md, commands/genie-help.md, and README list /direct.
      - rules/autonomous-execution.md gains an "In-session program direction" section beside the
        human-led and orchestrator-driven patterns.
      - rules/agent-conventions.md allows a Crafter or Tidier to write files inside its own
        worktree.
      - commands/define.md shapes programs as one item per slice.
      - install.sh installs the new genie and command through copy_dir.
      - make ci passes.
    status: pending
---

# Shaped Work Contract: Direct a program of slices from one session

## Problem

genie-team runs one item at a time well. `/feature` guides it, `/run` takes it through unattended, and `genies daemon` runs a batch of items headless. None of those handles a **program**: a body of work split into slices that depend on one another, where several slices can build at once, each merge has to keep `main` green, and the slices need coordinating while they build.

What a program needs is **continuous coordination and oversight**: someone who watches every slice for the whole run, not a handoff at each phase boundary. Today, that falls to the human. They keep the dependency map in their head, open one terminal per slice, notice when two slices need the same file, rebase and merge by hand, and decide when the code needs tidying. They can't walk away.

**Who is affected:** anyone whose shaped work is bigger than one item, for example a walking skeleton followed by features that build on it.

## Evidence

A trial ran a Director in a downstream product repo on 2026-10-22 and 2026-10-23. It was a project-local genie and command over a program of six slices.

- **Outcome.** Five slices and two tidy items merged into local `main`, all verified, each in its own worktree. Two pairs ran in parallel. One slice was held on purpose for a human decision.
- **Review.** The Critic returned CHANGES_REQUESTED once on each of four slices and found a real Major every time: a key loader that trimmed raw key bytes, a hidden password error, job uniqueness that blocked periodic jobs, and a document frame blocked by its own CSP. Each fix went back to the same Crafter and passed on re-review.
- **Mid-run coordination happened, but ad hoc.** One Crafter asked for four wiring paths outside its rows. Another raised an encryption-key contract shared by three slices. The Director fixed that contract and told every live Crafter. These requests arrived only when a Crafter returned or happened to mention them, which is the gap AC-5 closes.
- **Every failure became a rule.** Each of these is now a rule in the charter:

  | Failure | Rule now in the charter |
  |---|---|
  | Out-of-process runs billed an empty API key | genies run in the session (ADR-008) |
  | The SDK's bundled CLI was too old for the model | fixed in commit 940a304 |
  | A Crafter ran in the main checkout | the Crafter checks its worktree first |
  | A fixture was git-ignored, so `main` went red after a merge | the one-tick hold-red exception |
  | Generated clients were stale after a rebase | a regenerate step at the merge gate |
  | The permission classifier refused `git rebase` | the permission rules in AC-9 |
  | Usage limits stopped two Crafters mid-fix | respawn on the existing worktree; a misfire is not an attempt |

## Appetite & Boundaries

- **Appetite:** medium (3 to 5 days). The charter and command already exist in a proven form. The work is generalizing them, adding schema support, adding the request channel, and wiring docs, install, and tests.
- **No-gos:**
  - PR mode: no chaining dependents onto unmerged PRs (v1 is trunk-based only).
  - No changes to `genies daemon` or the SDK runner.
  - No dashboard; the board is markdown in the program item.
  - No cost tracking, budgets, or turn caps.
  - No genie-to-genie messaging. Every request goes through the Director (see Rabbit holes).
- **Fixed elements:**
  - The Director never writes code.
  - One merge at a time, fast-forward only, verified before and after.
  - Git wins over the board.
  - One vocabulary: the Director uses genie-team terms (Crafter, Critic, Tidier, dispatch, merge gate, health check) and has no separate persona.

## Rabbit holes

- **A subagent messaging its parent mid-run.** Whether a subagent can `SendMessage` the directing thread isn't established. The request channel is a committed section of the slice item instead. It survives compaction, is visible in git, and needs no new capability.
- **Merge queues and stacked branches.** The merge gate is serial on purpose. Don't build speculative merges.
- **A general complexity engine.** The health check calls `/diagnose` and, optionally, one command the program names. genie-team doesn't ship or pin that tool.

## Goals

- A person shapes a program with `/define`, starts `/loop /direct`, and walks away. When they come back, every slice that wasn't held or blocked has merged, `main` is green, and the board says exactly what is waiting on them.
- A Crafter with a need outside its slice gets an answer within one tick, without stopping its work.
- Continuous coordination and oversight becomes a reusable genie-team pattern: a genie on the main thread that reconciles from git, coordinates subagent genies, gates what reaches `main`, and schedules its own next tick.

## Routing

Designed (below). Next: `/deliver docs/backlog/P1-program-director.md` on `genie/P1-program-director-deliver`.

---

# Design

## Summary

The work ports a proven project-local charter into genie-team's installable artifacts:

- a Director genie
- a `/direct` command
- a program-board schema
- small edits to schema validation, rules, define, help, README, and templates

One new behavior comes on top: the **Requests / Shared contracts** channel for coordinating Crafters mid-run. Nothing touches `src/`; this is prompt engineering plus lint and test scripts.

## Components

| Artifact | Change |
|---|---|
| `agents/director.md` | **New.** Ported charter, generalized, in genie-team vocabulary. The Director coordinates and oversees; the Navigator decides. Sections: Charter (WILL / WILL NOT), Inputs, The board, The tick, Preflight, Dispatch, Requests and shared contracts, The merge gate, Health check, Failure handling, Reporting. |
| `commands/direct.md` | **New.** Same shape as the other commands: Arguments, Genie Invoked, Context Loading, Context Writing, Behavior, Usage Examples, Safety Rules, Routing. |
| `schemas/program-board.schema.md` | **New.** Program frontmatter (`kind`, `slices`, `verify`, `regenerate`, `health_check`). Slice frontmatter (`kind`, `starts_when`, `verdict`, `design_section`). Body sections: Slice protocol, Shared contracts, Program board (columns and states), and a slice's Requests section. |
| `schemas/shaped-work-contract.schema.md` | Optional fields listed, with a pointer to the program-board schema. |
| `scripts/validate/validate-frontmatter.sh` | Enums `shaped-work:kind` = `program\|slice`; `verdict` = `APPROVED\|CHANGES_REQUESTED\|BLOCKED`. |
| `scripts/validate/check-crossrefs.sh` | `slices` paths exist. Each `starts_when` entry is one of the same program's `slices`. |
| `agents/crafter.md`, `agents/critic.md`, `agents/tidier.md` | Add `Skill` to `tools`, so a subagent genie can run `/deliver`, `/discern`, or `/tidy`. Add one line each on Requests (Crafter, Tidier) and on writing the verdict to frontmatter (Critic). |
| `rules/agent-conventions.md` | Exception: a Crafter or Tidier dispatched by the Director writes files inside its own worktree, and a Critic writes only the `verdict` field and its review into the slice's worktree. The return-content-to-orchestrator rule still holds for analysis genies. |
| `rules/autonomous-execution.md` | New subsection "In-Session Program Direction" after "Orchestrator-Driven Parallel Sessions": trunk mode required, worktree naming, the Director as the only writer to `main`. |
| `rules/workflow.md`, `commands/genie-help.md`, `README.md` | `/direct` in the command tables. README gets a "Programs" section with permission rules. |
| `commands/define.md` | A "Programs" subsection: one backlog item per slice; the parent names order, ownership map, numbering ranges, shared seams, and runtime isolation; never fold slices into one multi-cut item. |
| `templates/settings.json` | Allow rules for `git rebase main` and `git rebase master`, `--continue`, and `--abort`, plainly and as `git -C <worktree> ...`. |
| Project CLAUDE.md guidance | `templates/` has no CLAUDE.md template today, so the README "Programs" section carries the paragraph a project copies into its CLAUDE.md. |
| `tests/test_director.sh` | **New.** Structural tests (below). Picked up by `make test` through `TEST_FILES`. |

## Decisions

**D1. In-session, beside the daemon (ADR-008).** Program direction doesn't replace `genies daemon`. The Director refuses to start a Crafter out of process, and the daemon doesn't learn about programs.

**D2. Native genie subagent types instead of general-purpose.** This differs from the trial.
- The trial used general-purpose subagents told to read the Crafter identity, because the installed Crafter had no `Skill` tool and couldn't run `/deliver`.
- In genie-team the fix belongs at the source: add `Skill` to the Crafter, Critic, and Tidier, and dispatch `subagent_type: crafter`, `critic`, or `tidier`.
- That gives each genie its preloaded skills and project memory.
- Delivery confirms it with one smoke slice. If isolation or `Skill` misbehaves on a custom type, the charter falls back to general-purpose plus the identity file, which the trial proved.

**D3. Requests are committed, not messaged upward.**
- A Crafter appends to `## Requests` in its own slice item and commits. Each request has an id, what it needs, the path or contract involved, and whether it is blocking.
- Tick step 1 already reads every branch's item (`git show <branch>:<item>`), so requests arrive without new machinery.
- The Director answers each request with `SendMessage` to that Crafter and marks it answered in the board's log. A Crafter never edits another slice's item.
- A decision that binds more than one slice goes under `## Shared contracts` in the program item, with the date, the contract, its home (path), and who implements it. The Director messages every live Crafter the contract touches.
- An ownership-map change inside scope is the Director's call. A scope change goes to the Navigator.
- A blocking request marks the slice `waiting-on-director` in the notes, which shortens the next wake-up to one or two minutes.

**D4. Project commands live in the program item.** The program item sets them in frontmatter:
- `verify`: the command that must pass in the worktree and on `main`. If absent, use the stack profile's verification line.
- `regenerate`: optional; runs after a rebase to rebuild git-ignored generated files.
- `health_check`: optional; `{command, threshold}`, where the command writes a report the Director reads for functions over the threshold. Default threshold: cyclomatic complexity 15.

Nothing in the charter names a tool path.

**D5. Trunk-based only in v1.** The merge gate merges into the local default branch (`main` or `master`; these docs say `main`). In PR mode, `/direct` reports "Programs need trunk-based mode (see rules/autonomous-execution.md)" and stops.

**D6. Worktree and branch naming follow parallel sessions.**
- The harness creates the worktree under `.claude/worktrees/`.
- The Director renames the branch to `genie/<item>-deliver`, or `genie/<item>-tidy` for a tidy item.
- When the merge gate has to recreate a worktree, it uses `.claude/worktrees/<item>`, inside the repository root as the workspace boundary rule requires.
- Director state that isn't in git (the lock file and health-check snapshots) lives in `.claude/director/`. The lock keeps a notification-driven tick and a `/loop` tick from running the merge gate at the same time; a lock older than the longest wake-up interval is stale and is taken over.
- The README's `.gitignore` guidance lists both `.claude/director/` and `.claude/worktrees/`.

## The tick (unchanged from the trial except step 5a)

The tick is the oversight loop. Every step reconciles from git before it acts, and the lock in `.claude/director/` stops ticks from overlapping, so a missed or doubled tick does no harm.

1. Reconcile from git and `ListAgents`.
2. Promote waiting slices whose `starts_when` items have merged. Skip held slices.
3. Run preflight on every ready slice.
4. Dispatch every slice that passed preflight, and respawn every orphaned slice.
5. Listen for genies returning; start the Critic; route the verdict.
   - **5a. Read Requests on every live branch, answer them, and record shared contracts.**
6. Take `ready-to-merge` slices through the merge gate one at a time.
7. Health check after each merge.
8. Report and schedule the next wake-up.

## Board states

`waiting → ready → building → review → ready-to-merge → merged`. The side states are `blocked`, `held`, `orphaned` (the slice's Crafter ended; respawn it on the existing worktree), and `tidy`. The board avoids `abandoned`, which is already a shaped-work `status` value with a different meaning.

## Tests (`tests/test_director.sh`, AAA via the existing assert helpers)

- `director.md` and `direct.md` have valid frontmatter, and the genie's description says it runs on the main thread and is never spawned as a subagent.
- No line outside the WILL NOT section of `director.md` contains `claude -p`, `genies run`, `maxBudgetUsd`, or `maxTurns`. The WILL NOT section names out-of-process spawns and budget or turn caps.
- `director.md` names no absolute home path and no tool outside genie-team (`grep -E '~/|/Users/'` finds nothing).
- `director.md`, `direct.md`, and `program-board.schema.md` use genie-team vocabulary. A whole-word, case-insensitive match (`grep -wiE`) finds none of `chef`, `cook`, `cooking`, `brigade`, `mise en place`, `the pass`, `at-pass`, or `## Service`. Whole words keep `cookie` and `the password` from failing the test.
- `crafter.md`, `critic.md`, and `tidier.md` list `Skill` in `tools`.
- Validation fixtures under `tests/fixtures/program/`:
  - a valid program with two slices passes `lint-docs`
  - a missing `slices` path fails
  - a `starts_when` entry outside the program fails
  - `kind: banana` fails
- `templates/settings.json` contains the rebase allow rules.
- `install.sh --dry-run` lists `director.md` and `direct.md`.

## Risks

| Risk | Mitigation |
|---|---|
| Custom genie types don't honor `isolation: "worktree"` or `Skill` | One smoke slice at delivery; fall back as in D2 |
| A Crafter forgets to commit its request | The Crafter's charter line plus the dispatch prompt; the Director also reads the Crafter's returned result for unlisted needs |
| Cost runs on with no caps | Attempt cap, silence check (45 minutes with no commit, then a status message, then a stop and respawn), and the slice's appetite. Documented as a consequence in ADR-008 |
| The board drifts from git | Git wins; the board is rewritten every tick |
| Changing the model mid-program shifts quality | The README notes that subagents inherit the session model; switch between slices, not during one |

## Implementation guidance

Deliver in this order, committing at each step:

1. Schema and validation, with fixtures and tests.
2. Agent `tools` edits.
3. `director.md`, ported from the trial and generalized; add the Requests section.
4. `direct.md`.
5. Rules, define, help, README, and template.
6. `tests/test_director.sh`.
7. `make ci`.

Port every rule faithfully, but not the trial's vocabulary. The trial's charter lines each record a failure that happened, so a line dropped while generalizing reopens that failure. Translate the trial's kitchen terms into the terms in the spec's Terms table as you port. Finish with the `/deliver` verification block.
