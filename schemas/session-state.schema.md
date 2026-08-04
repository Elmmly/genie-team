# Session State File Schema

**File:** `.claude/session-state.md` (per-project, gitignored)
**Version:** 1.0

The session state file is the shared contract between the session-tracking
hooks. It was previously an implicit contract between two scripts; this schema
makes it explicit. Any hook or command that reads or writes the file MUST
follow this format.

## Producers and Consumers

| Script | Role |
|--------|------|
| `hooks/track-command.sh` | Creates/rewrites the file on each slash command (UserPromptSubmit). Preserves Command History and Artifacts Written across rewrites. |
| `hooks/track-artifacts.sh` | Appends to Artifacts Written on Write/Edit tool use (PostToolUse). |
| `hooks/reinject-context.sh` | Reads the file on SessionStart (compact\|clear) and replays it, reconciled against live git state. |
| `/commit` (in `/run` context) | Reads Artifacts Written to stage files (never `git add -A`). |

## Format

```markdown
# Genie Session State
<!-- Auto-maintained by hooks. Do not edit manually. Format: schemas/session-state.schema.md -->

## Active Command
command: /deliver docs/backlog/P1-example.md
started: 2026-08-03T14:00:00Z
base_commit: abc1234

## Backlog Item
title: Example item title
status: designed
spec_ref: docs/specs/platform/example.md
adr_refs: docs/decisions/ADR-007-example.md

## Command History
- 2026-08-03T13:00:00Z abc1234 /design docs/backlog/P1-example.md
- 2026-08-03T14:00:00Z abc1234 /deliver docs/backlog/P1-example.md

## Artifacts Written
- src/example.ts
- docs/backlog/P1-example.md
```

## Sections

### `## Active Command` (required)
Key-value lines describing the most recent slash command.

| Key | Meaning |
|-----|---------|
| `command:` | The full prompt as typed (command + arguments). |
| `started:` | UTC timestamp (`%Y-%m-%dT%H:%M:%SZ`) when the command was submitted. |
| `base_commit:` | Short SHA of HEAD when the command started, or `none` outside a git repo. Diff against this anchor to recover what the command changed. |

Replaced wholesale on each new slash command.

### `## Backlog Item` (optional)
Present only when the command's first argument resolved to a
`docs/backlog/*.md` file with frontmatter. Keys: `title:`, `status:`,
`spec_ref:`, `adr_refs:` (comma-separated). Replaced wholesale on each new
slash command.

### `## Command History` (required)
One `- ` line per slash command, oldest first:

```
- {started} {base_commit} {command}
```

Appended (never overwritten) by `track-command.sh`. Capped at the 20 most
recent entries.

### `## Artifacts Written` (required, MUST be the final section)
One `- ` line per file path (relative to the project root) touched via Write
or Edit during tracked commands. Deduplicated; capped at 20 entries (oldest
evicted first). `track-artifacts.sh` appends to the end of the file, which is
why this section must stay last.

## Parsing Rules

- Sections are delimited by `## ` headings; list items are lines starting
  with `- `. Consumers MUST scope list extraction to the owning section
  (Command History and Artifacts Written both use `- ` lines).
- Key-value lines are `key: value` with a single space after the colon.
- The file is disposable state, not project knowledge: deleting it loses only
  session-resumption convenience. Project knowledge belongs in `docs/`.
