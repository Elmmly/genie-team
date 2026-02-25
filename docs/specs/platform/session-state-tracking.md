---
spec_version: "1.0"
type: spec
id: session-state-tracking
title: Session State Tracking
status: active
created: 2026-02-25
domain: platform
source: spec-init
acceptance_criteria:
  - id: AC-1
    description: >-
      track-command.sh captures slash command invocations on UserPromptSubmit, writing
      session-state.md with command name, timestamp, and backlog item context (title,
      status, spec_ref, adr_refs) extracted from YAML frontmatter
    status: met
  - id: AC-2
    description: >-
      track-artifacts.sh appends written file paths to session-state.md on PostToolUse:Write,
      with deduplication (grep -qF), relative path conversion, self-reference exclusion,
      and cap at 20 entries with FIFO eviction
    status: met
  - id: AC-3
    description: >-
      reinject-context.sh re-injects session context on SessionStart after compaction or
      clear, printing active command, backlog item summary, artifacts written list, and
      backlog frontmatter so the genie can resume work
    status: met
  - id: AC-4
    description: >-
      All three hooks are zero LLM cost (pure shell operations using jq, grep, sed, awk),
      configured via hooks.json with event matchers (UserPromptSubmit, PostToolUse:Write,
      SessionStart:compact|clear), and compatible with both plugin and script installation
    status: met
---

# Session State Tracking

Three event hooks maintain session state across context compactions without any LLM token cost. When Claude Code compacts conversation context (which happens automatically as conversations grow), critical session state — what command is running, what backlog item is being worked on, what files have been written — would otherwise be lost. These hooks capture that state in a lightweight file and re-inject it after compaction.

This is essential for long-running genie sessions (especially `/deliver` and `/run`) where context compaction is inevitable and losing track of the active work item would waste significant effort.

## Acceptance Criteria

### AC-1: Command invocation tracking
The `track-command.sh` hook fires on every UserPromptSubmit event. When a slash command is detected (prompt starts with `/`), it writes `.claude/session-state.md` with: the full command line, a UTC timestamp, and backlog item context extracted from frontmatter if the argument points to a `docs/backlog/*.md` file (title, status, spec_ref, adr_refs). Non-slash-command prompts are ignored (exit 0).

### AC-2: Artifact file tracking
The `track-artifacts.sh` hook fires on every PostToolUse:Write event. It appends the written file's relative path to the "Artifacts Written" section of session-state.md. Features: absolute-to-relative path conversion, self-reference exclusion (state file itself), deduplication via grep, and a cap at 20 entries with FIFO eviction (oldest entry removed when cap is reached using awk).

### AC-3: Context re-injection on compaction
The `reinject-context.sh` hook fires on SessionStart events triggered by compaction or clear. It reads session-state.md and prints to stdout (which Claude sees as context): the active command, backlog item summary (title, status, spec, ADRs), list of artifacts written so far, and the backlog item's full YAML frontmatter if the file exists. It ends with "Resume your work" to prompt continuation.

### AC-4: Zero cost and plugin compatibility
All hooks use only shell operations (jq for JSON parsing, grep/sed/awk for text processing) with no LLM API calls. They're configured in `hooks.json` using Claude Code's hook event system: UserPromptSubmit for command tracking, PostToolUse with Write matcher for artifact tracking, SessionStart with compact|clear matcher for re-injection. The hook configuration uses `${CLAUDE_PLUGIN_ROOT}` for plugin compatibility.

## Evidence

### Source Code
- `hooks/track-command.sh`: UserPromptSubmit hook — command capture and backlog context extraction
- `hooks/track-artifacts.sh`: PostToolUse:Write hook — file path tracking with dedup and cap
- `hooks/reinject-context.sh`: SessionStart hook — context re-injection after compaction
- `hooks/hooks.json`: Hook event configuration with matchers

### Tests
- `tests/test_hooks.sh`: 38 tests covering all three hooks — command tracking, artifact tracking, context re-injection, edge cases (non-slash prompts, missing state files, deduplication, cap eviction)
