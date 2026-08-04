# Session Resumption Discipline

After any session resume, restart, or context compaction, re-derive the state
of the work from the repository before summarizing or continuing. Replayed
context and your own memory of the session are hypotheses; git is the record.

## Before summarizing resumed work

Run (or read from the injected session ground truth, which contains the same):

- `git status --short` — what is actually uncommitted right now
- `git log --oneline -10` — what has actually landed
- `git diff --stat` — the real shape of pending changes

Then reconcile: if a replayed recap, session-state file, or your recollection
disagrees with git, **git wins**.

## Hard rules

- **Never assert what is or isn't committed from memory.** "I still need to
  commit X" and "X is already committed" are claims about git state — verify
  them with git before stating them.
- **Never re-do work that already landed.** Before re-creating a file, a fix,
  or a commit you remember planning, check whether a commit in
  `git log --oneline -10` already contains it.
- **Treat `.claude/session-state.md` as a pointer, not proof.** Its artifact
  list says what was touched during tracked commands, not what survived,
  changed, or was committed since (format: `schemas/session-state.schema.md`).
- **When resumed mid-task**, state one line of re-derived ground truth
  (branch, dirty/clean, last relevant commit) before continuing the task, so
  a stale recap cannot silently steer the session.
