# /direct [program]

Activate the Director genie to coordinate and oversee a program of dependent slices: one tick per call.

---

## Arguments

- `program` - Path to a program item (`kind: program`) (optional — with no path, tick every open program in `docs/backlog/`)
- Optional flags:
  - `--one` - Dispatch at most one new slice this tick (for a first, watched run)
  - `--status` - Reconcile and report the board; dispatch, answer, and merge nothing
  - `--merge` - Run only the merge gate (and health check) for slices already `ready-to-merge`
  - `--tidy` - Run only the health check over `main` and open tidy items
  - `--no-wake` - Do not schedule the next tick

---

## Genie Invoked

**Director** - Continuous coordination and oversight of a program:
- Dispatches Crafters into worktrees, one per ready slice
- Answers mid-run requests and records shared contracts
- The only path into `main`, through a serial, verified, fast-forward merge gate
- Health check after every merge

---

## Agent Identity

Read and internalize the Director's identity file for your identity, charter, and judgment rules: `<repo>/.claude/agents/director.md` if the project has one (a project install wins), otherwise `~/.claude/agents/director.md` (a global install). If neither exists, report "genie director not installed" and stop. You run on the main thread of this session. Never spawn the Director as a subagent: it must dispatch genies itself.

---

## Context Loading

**READ (automatic):**
- The program item, or every `docs/backlog/*.md` with `kind: program` whose `status` is not `done` or `abandoned`
- Each slice item listed under `slices` (from `main`, and from its branch when one exists)
- `schemas/program-board.schema.md`
- `.claude/rules/stack-*.md` (Verification section, when the program has no `verify`)
- Project `CLAUDE.md` and rules (git workflow mode)
- `ListAgents` (live genies)
- `.claude/director/` (tick lock, health-check snapshots)

---

## Context Writing

**WRITE:**
- `docs/backlog/tidy-<slug>.md` (tidy items opened by the health check)
- `.claude/director/lock`, `.claude/director/health/` (git-ignored)

**UPDATE:**
- Program item: `## Board` (every tick), `## Shared Contracts`, `slices` (when a tidy item opens)
- Slice items, on their branches: `verdict`, the Critic's review, and spec AC updates (recorded by the Director from the Critic's result)
- Slice items, on `main`: `status: done` at the merge gate (merged slices stay in `docs/backlog/` until the program is done)
- `main`: only through the merge gate, plus Shared Contracts and board commits

---

## Behavior

1. **Mode check.** In PR mode, report "Programs need trunk-based mode (see rules/autonomous-execution.md)" and stop.
2. **Verify check.** No `verify` in the program item and no stack profile Verification section: report "No verify command: set `verify` in the program item" and stop.
3. **Run one tick** as the Director's charter defines it:
   lock → reconcile → promote → preflight → dispatch → listen (and answer requests) → merge gate → health check → report → schedule.
4. **Flags** narrow the tick: `--status` stops after reconcile and report; `--merge` runs only the merge gate and health check; `--tidy` runs only the health check; `--one` caps new dispatches at one.
5. **Schedule the next tick only under `/loop`**, unless `--no-wake` or the loop has ended (no slice can move without the Navigator). Outside `/loop`, report the suggested next tick instead.

**Unattended direction** is `/loop /direct`. Each tick picks its own wake-up: one or two minutes when a slice is `ready-to-merge` or a request is blocking, 20 to 30 minutes while genies are working. Subagent notifications also wake the Director when a genie returns.

---

## Usage Examples

```
/direct docs/backlog/P1-billing.md --status
> Program: P1-billing   tick 14:05
> merged 1/3 · building 1 · review 0 · waiting 1 · blocked 0 · held 0
> Waiting on you: nothing
> Next tick: none (--status)

/direct docs/backlog/P1-billing.md --one
> Preflight: P1-billing-02-invoices passes
> Dispatched a Crafter (agent a3f…) for P1-billing-02-invoices; worktree under .claude/worktrees/, branch genie/P1-billing-02-invoices-deliver
> Next tick: suggested in 25 minutes (a Crafter is working); run /direct again or /loop /direct

/loop /direct
> Program: P1-billing   tick 15:40
> Answered P1-billing-02-invoices#R1: key format recorded under Shared Contracts
> Critic: P1-billing-02-invoices APPROVED
> Merge gate: P1-billing-02-invoices merged (ff), verify green on main
> Health check: no new findings
> Promoted P1-billing-03-reminders to ready; dispatched
> Next tick: in 25 minutes

/direct --merge
> Merge gate: P1-billing-03-reminders rebased, verified, ownership clean, merged
> All slices merged. Loop ended.
```

---

## Safety Rules

- **Trunk-based only.** PR mode stops at the mode check.
- **In-session only.** Every genie is a subagent of this session. Never spawn one out of process (`claude -p`, `genies run`), and never set a budget or turn cap (`maxBudgetUsd`, `maxTurns`).
- **One way into `main`.** Fast-forward only, one slice at a time, verified in the worktree and again on `main`. Never force-push, reset, or rebase `main`.
- **Nothing unapproved merges.** Verdict `APPROVED` and the `/deliver` verification block, or the slice waits.
- **Red `main` is restored forward** with `git revert`, never by rewriting history.
- **Worktrees stay inside the repository**, under `.claude/worktrees/`. Run `git worktree list` before removing anything.
- **Scope belongs to the Navigator.** A request that changes scope blocks that slice only.

---

## Routing

After a tick:
- **Genies working:** next tick (scheduled, or on a genie's return)
- **Every slice merged:** Navigator — program complete; `/done` the program item
- **A slice blocked or held:** Navigator, while the other slices keep going
- **A Slice Protocol gap:** `/define` to amend the program

---

## Notes

- The program is shaped with `/define` (see its Programs section): one backlog item per slice, plus a program item with the Slice Protocol
- Genies run on this session's model and account; switch models between slices, not during one
- The program lives as long as the session. Worktrees and commits survive; the next `/direct` respawns live slices
- Programs run in-session, beside the headless `genies daemon`: genies use this session's account, and the Director can answer them mid-run
