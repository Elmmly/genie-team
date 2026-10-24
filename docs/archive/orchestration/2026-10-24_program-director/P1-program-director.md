---
spec_version: "1.0"
type: shaped-work
id: P1-program-director
title: "Direct a program of slices from one session"
status: done
verdict: APPROVED
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
    status: met
  - id: AC-2
    description: >-
      agents/director.md ports the trial charter, generalized: no project names, absolute paths,
      or tools from outside genie-team, and genie-team vocabulary with no separate persona.
      Verify, regenerate, and health-check commands come from
      the program item. Only verify falls back, to the stack profile's Verification section;
      with no verify command anywhere, /direct reports that and stops.
    status: met
  - id: AC-3
    description: >-
      commands/direct.md: one tick per call; no path ticks every open program; flags --one,
      --status, --merge, --tidy, --no-wake; /loop /direct runs it unattended with self-paced
      wake-ups; a blocked or held slice stops only itself and its dependents; the loop ends when
      no slice can move without the Navigator.
    status: met
  - id: AC-4
    description: >-
      Everything runs in the session. Crafters, Critics, and Tidiers are subagents of the
      directing session, and Crafters and Tidiers run with worktree isolation. The charter
      forbids claude -p, genies run, and budget or turn caps. tests/test_director.sh fails if
      director.md or direct.md tells the Director to spawn out of process.
    status: met
  - id: AC-5
    description: >-
      Mid-run coordination. Crafters write cross-slice needs under Requests in their own slice
      item on their branch. Every tick the Director answers each open request by message. It
      records each cross-slice decision under Shared contracts in the program item and messages
      every live Crafter it affects. A request that changes scope goes to the Navigator.
    status: met
  - id: AC-6
    description: >-
      The merge gate:
      1. Rebase in the worktree.
      2. Run the regenerate command.
      3. Verify in the worktree.
      4. Check ownership, counting paths granted under Shared contracts.
      5. Merge to main with ff-only.
      6. Verify again on main.
      7. Mark the slice done (status: done, kept in docs/backlog/ until the program is done),
         then /commit with explicit paths.
      8. Remove the worktree and the branch.
      A slice passes only with a Critic approval logged at its branch head and the /deliver
      verification block on its item. A red main is restored with a forward revert of the
      recorded merged range.
    status: met
  - id: AC-7
    description: >-
      Health check after each merge: /diagnose scoped to the merged paths, plus the
      health_check command if the program sets one. A finding over the threshold becomes a tidy-<slug> item
      for a Tidier. A tidy item never touches a path a live slice owns.
    status: met
  - id: AC-8
    description: >-
      Recovery. Attempts cap at 3 per slice and count only failures handed back to the Crafter.
      Misfires and usage-limit interruptions are logged but not counted. An ended Crafter is
      respawned on its existing worktree. The tick rebuilds the board from git and ListAgents
      after a compaction.
    status: met
  - id: AC-9
    description: >-
      Trunk-based only: in PR mode /direct reports why and stops. templates/settings.json and
      README carry the permission rules the merge gate and Crafters need, including git rebase inside
      .claude/worktrees/.
    status: met
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
    status: met
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

Done 2026-10-24: delivered on `genie/P1-program-director-deliver`, reviewed APPROVED, archived.

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

---

# Implementation

Delivered on `genie/P1-program-director-deliver` (2026-10-24), test-first: `tests/test_director.sh` and its fixtures were written and run red (82 failing) before any artifact.

## What was built

| Artifact | Change |
|---|---|
| `agents/director.md` | **New.** The Director's charter in genie-team vocabulary: Charter (WILL / WILL NOT), Inputs, The Board, The Tick (with a lock), Preflight, Dispatch, Requests and Shared Contracts, The Merge Gate, Health Check, Failure Handling, Reporting, Memory Guidance, Routing |
| `commands/direct.md` | **New.** `/direct [program]` with `--one`, `--status`, `--merge`, `--tidy`, `--no-wake`; mode and verify checks; `/loop /direct` for unattended direction |
| `schemas/program-board.schema.md` | **New.** Program and slice frontmatter; Slice Protocol, Shared Contracts, Board (columns, states, log), and Requests sections, with examples |
| `schemas/shaped-work-contract.schema.md` | Program and slice fields, pointing to the board schema |
| `scripts/validate/validate-frontmatter.sh` | Enums for `kind` and `verdict` |
| `scripts/validate/check-crossrefs.sh` | Program `slices` must exist; each slice's `starts_when` must be a slice of the same program |
| `agents/crafter.md`, `critic.md`, `tidier.md` | `Skill` added to `tools`; a "Working Under the Director" section each |
| `rules/agent-conventions.md`, `autonomous-execution.md`, `workflow.md` | Worktree-write exception; "In-Session Program Direction"; `/direct` in the command reference |
| `commands/define.md`, `commands/genie-help.md`, `README.md` | Programs subsection; `/direct` in help; README "Programs (`/direct`)" section with permission rules, `.gitignore` entries, and the CLAUDE.md paragraph |
| `templates/settings.json` | `Bash(git rebase *)` and `Bash(git -C * rebase *)` |
| `tests/test_director.sh`, `tests/fixtures/program/` | **New.** 88 structural and validation tests |

## Deviations from the design

1. **Critic stays read-only; the Director records the verdict.** The Critic genie has `permissionMode: plan` and no Write tool, so it cannot write `verdict` to the slice item as the spec's ownership wording assumed. The Critic returns its verdict and review; the Director writes them into the slice item on the slice branch (a docs write, not code). This keeps review independent.
2. **Tidy work uses D2's fallback from the start.** The Tidier genie is also `permissionMode: plan`, so a native Tidier subagent cannot edit its worktree. The Director dispatches tidy items as `general-purpose` with the Tidier identity file. Making the Tidier writable everywhere would change its analysis role, so that is left as a separate decision.
3. **Install test uses a real install.** `install.sh --dry-run` prints only component names, not files, so the test installs agents, commands, and schemas into a temporary project and checks the files exist.
4. **Installed artifacts don't cite genie-team's history.** `director.md` and `direct.md` install into other projects, so they state each trial-derived rule as a known failure ("A Crafter has worked in the main checkout before") instead of referring to "the trial" or to ADR-008.
5. **The `.gitignore` entries live in README guidance**, not in `install.sh`, matching the reviewed design text.

## Wiring check (Phase 4)

Prompt-only change; no service bootstrap. Reachability: `install.sh project --agents --commands --schemas` installs `director.md`, `direct.md`, and `program-board.schema.md` (tested). The new validation rules run in `make lint-docs` and the pre-commit hook.

**Not yet done: the D2 smoke slice.** Whether a native `crafter` subagent honours `isolation: "worktree"` and can run `Skill` has not been exercised in a live session. The charter carries the fallback. Run one smoke slice after installing this branch.

## AC coverage

| AC | Evidence |
|---|---|
| AC-1 | Schema docs, both validators, 4 fixtures, 37 tests |
| AC-2 | `director.md` sections, no home paths, trial rules ported, verify fallback: 21 tests |
| AC-3 | `direct.md` sections, flags, `/loop /direct`, identity load: 16 tests |
| AC-4 | WILL NOT forbids out-of-process spawns and caps; no mention elsewhere; worktree isolation; `Skill` on three genies: 9 tests |
| AC-5 to AC-8 | Charter sections present (Requests and Shared Contracts, The Merge Gate, Health Check, Failure Handling), checked structurally only. Their behavior is prompt-level and needs a live program to verify |
| AC-9 | PR-mode refusal text, rebase allow rules: 3 tests |
| AC-10 | Rules, help, README, define, install: 10 tests |

### Verification
- **Tests:** `make test` → `tests/test_director.sh` 113 passed, 0 failed; `tests/test_hooks.sh` 32 passed, 0 failed; `tests/test_install.sh` 14 passed, 0 failed; vitest 382 passed, 0 failed, 0 skipped (after review fixes)
- **Pre-existing failures:** none
- **Build/lint:** `make ci` (shellcheck, lint-docs, lint-hooks, tests) → exit 0, clean
- **Docs updated:** README, rules (workflow, autonomous-execution, agent-conventions), define, genie-help, both schemas, `docs/specs/workflow/program-direction.md` (Implementation Evidence)
- **Lands as:** 13 modified files (agents ×3, commands ×2, rules ×3, schemas ×1, validate scripts ×2, README, settings template) and new `agents/director.md`, `commands/direct.md`, `schemas/program-board.schema.md`, `tests/test_director.sh`, `tests/fixtures/program/` (9 files); plus this backlog item and the spec

---

# Review

**Reviewer:** Critic genie (independent subagent, two rounds), 2026-10-24
**Verdict:** APPROVED (after fixes)

## Round 1: CHANGES_REQUESTED

The text was complete and CI green, but tracing one slice through its life found seven Majors. All were fixed on this branch:

| # | Finding | Fix |
|---|---|---|
| 1 | After a forward revert the slice could never re-merge (rebase dropped its commits) | Record `<pre-merge>`/`<merged>`, revert that exact range, then ff the worktree to `main` and revert the revert before hand-back. Replayed in a scratch repo: re-merge works |
| 2 | `/done` at the gate archived the slice, breaking the program's `slices` crossref and sweeping siblings | Step 7 sets `status: done` and keeps the slice in `docs/backlog/`; the program archives with all its slices at the end; explicit-path staging |
| 3 | Respawned genies and the Critic ran in the main checkout (cwd resets every Bash call, confirmed by probe) | `cd <worktree> && ` on every call, absolute paths under the worktree |
| 4 | A Crafter could write `verdict: APPROVED` and pass the gate | Gate trusts a board log line "Critic APPROVED at `<sha>`" at the branch head; every hand-back clears `verdict`; Crafters never set it |
| 5 | Worktree path unknown before dispatch; harness base commit stale (probe: `a706304`, not `main`) | Crafter's first step is `git checkout -B genie/<id>-deliver main`; Director finds the worktree by branch, records agent IDs, background dispatch |
| 6 | "Git wins" erased `held`, `blocked`, and attempt counts | Board split into derived and Director-owned columns; Director-owned carried from the committed board; ordered first-match state table |
| 7 | Tool assumptions unverified | Rewritten from live probe facts (`ListAgents` main-thread only, `SendMessage` by agent ID, locked harness worktrees) |

Minor fixes in the same pass: tidy items committed on `main` with allowed paths, ACs, and design; scheduling only under `/loop`; cross-session lock released on every exit; trunk mode's commit-to-main limited to the gate; validators reject flow-style lists, `..`, non-slice entries, and unsafe ids, and strip inline comments; the Critic may run `verify`; misfires capped at 3 in a row with usage-limit backoff; settings narrowed to `rebase main|master|--continue|--abort`; README notes that `trunk-based` affects every workflow.

## Round 2: APPROVED once one line was fixed

All seven Majors were confirmed resolved. One new Major, now fixed: the `.gitignore` preflight passed two paths to `git check-ignore -q`, which exits 128, so every tick would have stopped. It now checks each path separately (verified in a scratch repo), and a test guards it. Minors 1–5 were also fixed: the harness's temporary branch is deleted at step 8, examples match harness naming, a `merging` state covers a merged slice waiting on a red `main`, the Navigator's hold must be committed, and the program is archived with every listed slice, with `exclude: ^docs/archive/` added to the template pre-commit crossrefs hook.

## ADR Compliance

| ADR | Decision | Compliant? | Notes |
|-----|----------|------------|-------|
| ADR-008 | In-session Director; Crafters/Tidiers as background subagents with worktree isolation; Director-only, ff-only writes to `main`; board rebuilt from git | YES | Respawns and Critics run without isolation but are confined by the cd discipline |
| ADR-005 | Daemon stays for headless runs | YES | `genies daemon` untouched |

## Adversarial Security Pass

1. **XSS (incl. SVG):** N/A, no rendered markup.
2. **CSS injection:** N/A.
3. **Authorization:** the merge gate is the trust boundary. Self-approval closed (#4). Residual, low: a genie with a malicious absolute-path write into the main checkout's program item could plant a fake approval line that rides along in the next board commit. Worktrees are not a sandbox. Accepted for v1; a follow-up could check the approval line came from a Director commit.
4. **Injection:** validators run no `eval`; frontmatter values were probed with `$(…)` and executed nothing. Program/slice ids restricted to `[A-Za-z0-9._-]`; `..` rejected in `slices`. `verify`/`regenerate`/`health_check` are shell commands by design and are read from `main` only, never from a slice branch.
5. **Secrets:** none introduced; in-session billing removes the API-key path.
6. **Over-required fields:** none (`starts_when: []` is the only required addition).
7. **Silently failing credentials:** N/A; the analogous runaway (uncapped misfire respawn on a usage limit) is capped.

## Open items (not blocking)

- **Smoke slice not run.** The live behavior of AC-5 (requests by `SendMessage`) and whether the plan-mode Critic may run `verify` need one real slice end to end after installing. Fallback for the Critic: a general-purpose genie with the Critic identity.
- **Pre-commit with only a slice staged** skips the `starts_when` scope check (a slice has no pointer to its program). `make lint-docs` still checks it.
