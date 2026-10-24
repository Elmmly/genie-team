---
schema_name: program-board
schema_version: "1.0"
type: schema
description: Defines program and slice items, the Slice Protocol, Shared Contracts, the Board, and Requests used by /direct
created: 2026-10-24
---

# Program Board Schema v1.0

> A **program** is a body of work split into slices whose dependencies are known. It is one
> program item plus one backlog item per slice. The Director genie runs it with `/direct`.
> Program and slice items are Shaped Work Contracts (`schemas/shaped-work-contract.schema.md`)
> with the extra fields and body sections below.

## Program Item

### Frontmatter

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `kind` | string | yes | `program` |
| `slices` | array of strings | yes | Paths to the slice items, as a block list (one `  - path` per line; flow-style `[a, b]` is rejected). Each must exist, have `kind: slice`, and contain no `..` (checked by `lint-docs`) |
| `verify` | string | no | Command that must pass in a slice's worktree and again on `main`. When absent, the Director uses the stack profile's Verification section; with neither, `/direct` stops |
| `regenerate` | string | no | Command run after each rebase to rebuild git-ignored generated files |
| `health_check` | object | no | `command`: writes a complexity report the Director reads. `threshold`: the score above which a function becomes tidy work (default: cyclomatic complexity 15) |

```yaml
kind: program
slices:
  - docs/backlog/P1-billing-01-skeleton.md
  - docs/backlog/P1-billing-02-invoices.md
  - docs/backlog/P1-billing-03-reminders.md
verify: make test
regenerate: make generate
health_check:
  command: make complexity-report
  threshold: 15
```

`main` in this schema means the repository's default branch, whether it is named `main` or `master`.

### Body sections

The program item's body carries three sections the Director reads and writes, beside the
usual shaped-work narrative.

## Slice Protocol

Written by `/define` when the program is shaped. It tells every Crafter where its slice ends.

| Part | Content |
|------|---------|
| **Order** | The dependency map in words; it must agree with each slice's `starts_when` |
| **Ownership map** | A table of path globs and the slice that owns each. A slice changes only its rows, shared seams, paths granted under Shared Contracts, and its own docs |
| **Shared seams** | Files more than one slice may edit (a route table, a DI container, a migrations index), with the rule for editing them (append only, one block per slice) |
| **Numbering ranges** | Ranges each slice uses for anything numbered (migrations, error codes, ports) so parallel slices never collide |
| **Runtime isolation** | How parallel worktrees avoid sharing runtime state: ports, database names, cache prefixes, temp directories |

```markdown
## Slice Protocol

### Ownership map
| Paths | Owner |
|-------|-------|
| `src/billing/invoices/**` | P1-billing-02-invoices |
| `src/billing/reminders/**` | P1-billing-03-reminders |

### Shared seams
- `src/app/routes.ts`: append one block per slice, never reorder

### Numbering ranges
- migrations: skeleton 001-019, invoices 020-039, reminders 040-059

### Runtime isolation
- each worktree uses `PORT=40<slice number>` and database `app_<slice id>`
```

## Shared Contracts

Written by the Director. Every decision that binds more than one slice, newest last. A
granted path counts as owned by the slice at the merge gate.

| Column | Content |
|--------|---------|
| Date | ISO date of the decision |
| Request | The request id that raised it (`<slice-id>#R<n>`), or `—` |
| Contract | What was decided, in one or two sentences |
| Home | The path where the contract lives (an interface file, a doc) |
| Implements | The slice that builds it; every slice that consumes it |
| Grants | Paths granted to a slice outside its rows, or `—` |

```markdown
## Shared Contracts

| Date | Request | Contract | Home | Implements | Grants |
|------|---------|----------|------|------------|--------|
| 2026-10-22 | P1-billing-02-invoices#R1 | Keys are 32 raw bytes, never trimmed or re-encoded | `src/crypto/keys.ts` | skeleton builds; invoices, reminders consume | — |
```

## Board

Written only by the Director, and committed on `main` whenever a Director-owned column,
Shared Contracts, or a merge changes it. Two kinds of columns:

- **Derived** (Branch, Worktree, Genie, and the states `building`, `review`, `orphaned`,
  `ready-to-merge`, `merged`): rewritten from git and the session's live genies every tick.
  Git wins: when they disagree, the tick corrects the board.
- **Director-owned** (the states `held` and `blocked`, Attempts, Notes, and the Log): exist
  only here, and carry over from the committed board every tick. The Navigator holds or
  releases a slice by setting its state to `held`.

| Column | Content |
|--------|---------|
| Slice | Slice item id (tidy items: `tidy-<slug>`) |
| State | One of the states below |
| Branch | `genie/<item>-deliver`, or `genie/<item>-tidy` |
| Worktree | Path of the slice's worktree, or `—` |
| Attempts | Failures handed back to the Crafter, out of 3 |
| Genie | Name of the live genie working on it, or `—` |
| Notes | Open request ids, `waiting-on-director`, what a held or blocked slice is waiting on |

### States

| State | Meaning |
|-------|---------|
| `waiting` | At least one `starts_when` slice has not merged |
| `ready` | Every `starts_when` slice has merged; not yet dispatched |
| `building` | A Crafter is working in the slice's worktree |
| `review` | The Crafter returned; a Critic is reviewing |
| `ready-to-merge` | Verdict `APPROVED` and the `/deliver` verification block are present |
| `merging` | Fast-forwarded into `main`, but `main` is red (forward revert or the hold-red exception pending). Not reviewed again |
| `merged` | Fast-forwarded into `main`, verified, slice item set to `status: done` (it stays in `docs/backlog/` until the program is done), worktree and branch removed |
| `blocked` | Waiting on the Navigator (scope change, attempt cap, unrecoverable failure). Stops only this slice and the slices that start after it |
| `held` | Deliberately paused by the Navigator. Never dispatched until released |
| `orphaned` | The slice's Crafter ended without returning. Respawned on its existing worktree and branch |
| `tidy` | A tidy item opened by the health check, run by a Tidier through the same merge gate |

```
waiting → ready → building → review → ready-to-merge → merged
                     ↑          │
                     └──────────┘  CHANGES_REQUESTED (attempt + 1)
```

### Log

Below the board table, one line per event, newest last: dispatches (with the agent ID),
verdicts, answered requests, merges (with the `<pre-merge>` and `<merged>` commits), reverts,
health-check findings, and misfires. Misfires are logged but not counted as attempts.

An approval is logged as `Critic APPROVED at <sha>`, where `<sha>` is the branch head the
Critic reviewed. The merge gate admits a slice only when its branch head is that commit, or
only the slice item changed after it. Every hand-back clears `verdict`, so an approval never
carries over to reworked code.

```markdown
## Board

| Slice | State | Branch | Worktree | Attempts | Genie | Notes |
|-------|-------|--------|----------|----------|-------|-------|
| P1-billing-01-skeleton | merged | — | — | 0 | — | — |
| P1-billing-02-invoices | building | genie/P1-billing-02-invoices-deliver | .claude/worktrees/P1-billing-02-invoices | 1 | crafter-invoices | R2 open |
| P1-billing-03-reminders | waiting | — | — | 0 | — | starts after invoices |

### Log
- 2026-10-22 14:05 dispatched P1-billing-02-invoices
- 2026-10-22 15:40 answered P1-billing-02-invoices#R1 (Shared Contracts)
```

## Slice Item

### Frontmatter

| Field | Type | Required | Description |
|-------|------|----------|-------------|
| `kind` | string | yes | `slice` |
| `starts_when` | array of strings | yes | Paths to slices of the same program that must merge first, as a block list; `[]` for none. Checked by `lint-docs` |
| `verdict` | string | no | `APPROVED`, `CHANGES_REQUESTED`, or `BLOCKED`. Recorded only by the Director from the Critic's result, and cleared on every hand-back. A genie never sets it; the merge gate trusts the board's approval log, not this field |
| `design_section` | string | no | Heading in the program item's design that this slice delivers |

Slice ids end up in branch names and git commands, so `lint-docs` accepts only letters,
digits, `.`, `_`, and `-` in the `id` of a program or slice.

A **tidy item** (`docs/backlog/tidy-<slug>.md`, opened by the health check) is a slice with
`starts_when: []`, acceptance criteria (finding resolved, behavior unchanged, verify green), a
short design, and an **Allowed paths** list that acts as its ownership rows.

## Requests

A section in the **slice** item, written only by that slice's Crafter or Tidier, on its own
branch, and committed as soon as it is written. The Director reads it from every live branch
each tick (`git show <branch>:<item>`) and answers by message. A genie never edits another
slice's item.

| Column | Content |
|--------|---------|
| Id | `R1`, `R2`, … within the slice |
| Need | What the genie needs, in one sentence |
| Path or contract | The path outside its rows, or the shared contract involved |
| Blocking | `yes` if the genie cannot continue without an answer |
| Status | `open`, or `answered <date>`. The genie sets it when the Director's answer arrives by message; the Director logs the answer on the board |

```markdown
## Requests

| Id | Need | Path or contract | Blocking | Status |
|----|------|------------------|----------|--------|
| R1 | Register the invoices routes | `src/app/routes.ts` | no | open |
| R2 | Agree the key format shared with reminders | encryption key contract | yes | open |
```
