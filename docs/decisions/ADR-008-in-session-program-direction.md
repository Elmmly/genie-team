---
adr_version: "1.0"
type: adr
id: ADR-008
title: "Run programs of slices in-session, with subagent genies in worktrees"
status: accepted
created: 2026-10-24
deciders: [architect, navigator]
domain: workflow
spec_refs:
  - docs/specs/workflow/program-direction.md
backlog_ref: docs/backlog/P1-program-director.md
tags: [architecture, orchestration, subagents, worktrees, billing]
---

# ADR-008: Run programs of slices in-session, with subagent genies in worktrees

## Context

ADR-005 moved autonomous execution into an SDK process. `genies daemon` and `genies run` call `query()` once per phase. They get budget caps, hooks, and resume. They bill whatever credential the process holds.

A multi-slice program needs something the daemon doesn't give it:

- Several slices build at the same time.
- A slice can start only after the slices it depends on have merged.
- Each merge has to keep `main` green.
- While genies work, someone has to answer their needs, such as an interface two slices share or a file another slice owns.

In short, a program needs continuous coordination and oversight for the whole run, not handoffs at phase boundaries.

A trial ran a program like this in a downstream product repo on 2026-10-22 and 23: six slices, five merged, plus two tidy items. The out-of-process path failed three times in a row before it ever produced a commit:

1. The process billed an API key that had no credit.
2. The SDK's bundled CLI was too old for the session's model. Commit 940a304 fixed that.
3. A single `genies run` worked in the main checkout, not in a worktree.

Moving the same program into the session, with Crafters as background subagents in their own worktrees, merged every slice without another orchestration failure. The Navigator then set a rule that holds for this kind of work: genies run inside the session and are billed to the account, never to API credits, and they carry no budget or turn caps.

## Decision

Add a Director genie and a `/direct` command:

- **The Director** runs on the main thread of an interactive session.
- **Crafters and Tidiers** are spawned with `Agent` and `isolation: "worktree"`.
- **Critics** are spawned without isolation and pointed at the slice's worktree.
- **Messages** to a working genie go through `SendMessage`.
- **Wake-ups** come from subagent notifications. A self-paced `/loop /direct` is the fallback.
- **Local `main`** is changed only by the Director, at the merge gate: fast-forward only, verified before and after.
- **Oversight is continuous.** Each tick reconciles the board, answers open requests, merges what is ready, runs the health check, and schedules the next tick.

Durable state lives in two places. Git holds the branches, worktrees, and the slice items' status and verdict. The program item holds the `## Board` section. Every tick rebuilds the board from git and `ListAgents`, so a compaction or a new session loses nothing.

ADR-005 stands for headless and scheduled runs. Program direction sits beside it, not on top of it.

## Consequences

**Positive**
- No API credential, bundled CLI, or process supervisor is involved. The genies use the session's account and model.
- Parallelism is limited only by the program's dependency map.
- The Director can answer a working Crafter in the middle of its run, which a phase-per-process runner cannot.
- One merge gate covers every slice and every tidy item.

**Negative**
- The program lives only as long as the session. When the session ends, live genies stop. Their worktrees and commits survive, and the next tick respawns them (AC-8).
- Nothing caps cost per genie. The slice's appetite and the cap of three attempts are the limits. A runaway Crafter is caught by the silence check and the attempt count, not by a budget.
- Usage limits hit every genie at once. Recovery depends on Crafters committing at each phase boundary.
- Trunk-based only for now. PR mode would chain dependents onto unmerged PRs, which this design leaves out.

**Neutral**
- Subagents run on the session's model, so changing the model mid-program changes every later genie.

## Alternatives Considered

| Alternative | Pros | Cons | Why not |
|---|---|---|---|
| Extend `genies daemon` with dependencies and a merge gate | headless; reuses ADR-005 governance | bills the process credential; can't answer a genie mid-phase; the trial's three misfires were on this path | conflicts with the in-session billing rule; coordination stays phase-granular |
| Human-led parallel sessions, one terminal per slice | already supported | the human is the director, merge gate, and messenger; nobody watches while they're away | the problem is walking away |
| One session, slices delivered serially | simplest | runs one at a time the slices the dependency map allows to run together; one context holds every slice | gives up the parallelism the slice protocol buys |
| **In-session Director with subagent genies in worktrees** | in-session billing; parallel tracks; mid-run answers; one gate | session-bound; no per-genie budget | **Chosen** |
