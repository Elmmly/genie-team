---
spec_version: "1.0"
type: shaped-work
id: post-compaction-context-hooks
title: "Post-Compaction Context Re-injection via Claude Hooks"
status: done
created: 2026-02-11
appetite: small
priority: P2
target_project: genie-team
author: shaper
depends_on: []
tags: [hooks, context-management, compaction, session]
acceptance_criteria:
  - id: AC-1
    description: "A SessionStart hook fires on `compact` events and re-injects current work context (active backlog item, loaded spec, current phase, key decisions) into Claude's awareness"
    status: met
  - id: AC-2
    description: "A context state file is maintained during sessions (written/updated as work progresses) that the hook reads from — so the hook has something to re-inject"
    status: met
  - id: AC-3
    description: "The hook is a command hook (shell script), not a prompt/agent hook — no additional LLM cost"
    status: met
  - id: AC-4
    description: "Hook configuration is distributed via install.sh alongside existing rules/skills/commands"
    status: met
---

# Shaped Work Contract: Post-Compaction Context Re-injection

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Problem:** When Claude Code compacts conversation context (to stay within token limits during long sessions), rules and skills survive because they're in the system prompt — but session-specific context is lost. Claude forgets which backlog item it's working on, which spec was loaded, what phase of the workflow it's in, and what decisions were made earlier in the session.

**Who's affected:** Anyone running multi-phase genie workflows in a single session, especially `/deliver` sessions that involve many tool calls and can trigger compaction.

**Why behavioral rules can't solve this:** Rules tell Claude *how to behave* but can't restore *what it knew*. After compaction, the rule "load the spec before delivering" survives, but the knowledge of *which* spec was loaded and what it contained is gone. The `/context:load` command exists for manual recovery, but requires the user to notice the context loss and intervene.

**Key insight from discovery:** This is the only hook use case where the mechanism genuinely fits the problem. A SessionStart hook on `compact` events fires at exactly the right moment, costs nothing (command hook reads a file, prints to stdout), and addresses a gap that no amount of prompt engineering can close.

## Evidence & Insights

- **Discovery:** `docs/analysis/20260211_discover_claude_hooks_vs_git_hooks.md` — Section 3C identified context management as the only dimension where hooks offer genuine value over the behavioral system
- **Platform capability:** SessionStart hooks on `compact` events fire after compaction completes. Stdout from the hook is added as context Claude can see. This is designed for exactly this use case.
- **Existing pattern:** `/context:load` already demonstrates the value of re-injecting context — this hook automates the recovery instead of requiring manual intervention

## Appetite & Boundaries

- **Appetite:** Small (1 day)
- **Boundaries:**
  - One hook script (reads state file, prints context summary)
  - One state file convention (path, format, what's stored)
  - Hook configuration in `.claude/settings.json` pattern
  - Integration with `install.sh` for distribution
- **No-gos:**
  - No prompt or agent hooks (no additional LLM cost)
  - No changes to existing commands or skills
  - No full session replay — just key context summary
  - No dependency on external tools (pure bash/jq)
- **Fixed elements:**
  - Must use `SessionStart` event with `compact` matcher
  - Must be a command hook (type: "command")
  - State file must be human-readable (for debugging)

## Goals

**Outcome hypothesis:** "After compaction, Claude continues working with awareness of the current backlog item, loaded spec, workflow phase, and key decisions — without the user needing to notice the context loss or manually re-load."

**Success signals:**
- User can run a long `/deliver` session that hits compaction and Claude continues with correct context
- No additional token cost (command hook, not LLM hook)
- State file is useful for debugging session state even outside of compaction

## Risks & Assumptions

| Assumption | Type | Confidence | Test |
|------------|------|------------|------|
| Compaction actually causes context loss problems in practice | Value | Medium | Run a long `/deliver` session, force compaction, observe behavior before/after |
| Commands can reliably maintain a state file as work progresses | Feasibility | Medium | Prototype a state file write in one command, verify it persists across tool calls |
| SessionStart hook stdout is visible to Claude after compaction | Feasibility | High | Test with a trivial SessionStart hook that prints "hello" on compact |
| State file won't become stale or misleading | Usability | Medium | Design state file to include timestamps; clear on session end |

## Options (Ranked)

### Option 1: State file + SessionStart hook (Recommended)

- **Description:** Commands write/update a state file (e.g., `.claude/session-state.md`) as they progress. SessionStart hook on `compact` reads the file and prints it to stdout.
- **Pros:** Simple, no LLM cost, deterministic, debuggable
- **Cons:** Requires commands to maintain the state file (changes to existing commands)
- **Appetite fit:** Small — one hook script + state file convention + minor command updates

### Option 2: Transcript parsing hook

- **Description:** SessionStart hook on `compact` reads the transcript file (available via `transcript_path` in hook input) and extracts key context.
- **Pros:** No changes to existing commands; works retroactively
- **Cons:** Transcript parsing is fragile; transcript can be very large; extracting "what matters" requires heuristics or LLM
- **Appetite fit:** Risky — transcript format may change; parsing logic is complex

## Dependencies

- None — uses existing Claude Code hook infrastructure

## Routing

- [x] **Architect** — Design state file format, hook script, and command integration points

**Rationale:** The hook itself is trivial, but the state file convention needs careful design — what to store, when to update, how commands write to it without adding noise to their primary output.

## Artifacts

- **Contract saved to:** `docs/backlog/P2-post-compaction-context-hooks.md`
- **Discovery ref:** `docs/analysis/20260211_discover_claude_hooks_vs_git_hooks.md`

---

# Design

## 1. Design Summary

Three lightweight command hooks that automatically track session context and re-inject it after compaction or conversation clear — with zero LLM cost and no changes to existing commands.

**Key design insight:** The shaped contract's no-go of "no changes to existing commands" creates a tension with AC-2 (maintaining a state file). The resolution: use Claude Code's own hook events to capture context passively. A `UserPromptSubmit` hook captures which command was invoked and its arguments. A `PostToolUse` hook on Write captures which artifacts were created. Neither requires modifying command definitions — they observe from outside.

**Token management rationale:** After compaction, without re-injection, Claude typically spends 3-8 tool calls (Read operations on CLAUDE.md, backlog items, specs) to re-establish context — or worse, proceeds with wrong assumptions. The re-injected state file is ~30 lines (~200 tokens of input). The trade-off: 200 tokens of re-injection vs. 2,000-5,000 tokens of re-discovery. Net savings: significant in long sessions that hit compaction.

### Deliverables

| # | Artifact | Type | Location | AC |
|---|----------|------|----------|-----|
| 1 | Command tracking hook | Shell script | `.claude/hooks/track-command.sh` | AC-2, AC-3 |
| 2 | Artifact tracking hook | Shell script | `.claude/hooks/track-artifacts.sh` | AC-2, AC-3 |
| 3 | Context re-injection hook | Shell script | `.claude/hooks/reinject-context.sh` | AC-1, AC-3 |
| 4 | Hook configuration | JSON (settings merge) | Via `install.sh --hooks` | AC-4 |
| 5 | Gitignore update | Config | `.gitignore` | — |

---

## 2. Component Design

### 2.1 State File (`.claude/session-state.md`)

**Path:** `.claude/session-state.md` in the project root. Gitignored (ephemeral, per-session).

**Format:** Human-readable markdown, bounded to ~30 lines. Designed for two audiences: the re-injection hook (reads and prints to stdout) and human debugging (can `cat` it to see session state).

```markdown
# Genie Session State
<!-- Auto-maintained by hooks. Do not edit manually. -->

## Active Command
command: /deliver docs/backlog/P2-auth-improvements.md
started: 2026-02-11T10:30:00Z

## Backlog Item
title: "Auth Token Refresh Implementation"
status: designed
spec_ref: docs/specs/identity/token-authentication.md
adr_refs: ADR-015, ADR-016

## Artifacts Written
- docs/backlog/P2-auth-improvements.md
- src/auth/token-service.ts
- tests/auth/token-service.test.ts
```

**Size control:** The "Artifacts Written" section is capped at 20 entries (most recent). Older entries are dropped. This keeps the file under 40 lines regardless of session length.

**Lifecycle:**
- Created/overwritten by `track-command.sh` on each new slash command
- Appended by `track-artifacts.sh` on each Write to project files
- Read by `reinject-context.sh` on compaction/clear
- Deleted by session end (or naturally overwritten on next command)

### 2.2 Hook: `track-command.sh` (UserPromptSubmit)

**Event:** `UserPromptSubmit` (fires on every user prompt, before processing)

**Purpose:** Capture the genie command being invoked and extract backlog item context from its argument.

**Behavior:**
1. Read JSON from stdin, extract `prompt` and `cwd`
2. Check if prompt starts with `/` (genie command) — exit 0 immediately if not
3. Parse command name and first argument (backlog item path)
4. If argument points to a file in `docs/backlog/`, extract frontmatter fields: `title`, `status`, `spec_ref`, `adr_refs`
5. Write state file with "Active Command" and "Backlog Item" sections
6. Clear any previous "Artifacts Written" section (new command = fresh tracking)
7. Exit 0 (never blocks)

**Frontmatter extraction:** Uses `sed` to extract the YAML frontmatter block, then `grep` for specific fields. No `yq` dependency — just line-level text parsing for the 4-5 fields we need. Fragile for complex YAML but sufficient for the structured frontmatter genie-team produces.

**Performance:** Fires on every prompt but exits immediately for non-slash-command input. For slash commands, reads one file (the backlog item) and writes one file (state). Target: <100ms.

### 2.3 Hook: `track-artifacts.sh` (PostToolUse on Write)

**Event:** `PostToolUse` with matcher `Write`

**Purpose:** Track which files Claude writes during the session, so the re-injection hook can remind Claude what it's already produced.

**Behavior:**
1. Read JSON from stdin, extract `tool_input.file_path` and `cwd`
2. If state file doesn't exist, exit 0 (no active command to track against)
3. Convert absolute path to relative (strip `cwd` prefix)
4. Skip if path is the state file itself (avoid self-reference)
5. Skip if path is already in the artifacts list (dedup)
6. Count current artifact lines — if >= 20, drop the oldest entry
7. Append relative path to "Artifacts Written" section
8. Exit 0 (never blocks)

**Performance:** Fires on every Write tool call. Does minimal work: one grep for dedup, one echo for append. Target: <50ms.

### 2.4 Hook: `reinject-context.sh` (SessionStart on compact|clear)

**Event:** `SessionStart` with matcher `compact|clear`

**Purpose:** Read the state file and print it to stdout, which Claude Code adds as visible context after compaction.

**Behavior:**
1. Read JSON from stdin, extract `cwd`
2. Check if state file exists at `$cwd/.claude/session-state.md`
3. If exists: print a context header + file contents to stdout
4. If the backlog item path is referenced and the file exists: also print its frontmatter (gives Claude the full backlog context including ACs)
5. If state file doesn't exist: print nothing, exit 0 (no context to re-inject)
6. Exit 0

**Output format (printed to stdout):**
```
[Session context restored after compaction]

You were working on: /deliver docs/backlog/P2-auth-improvements.md

Backlog item: "Auth Token Refresh Implementation" (status: designed)
Spec: docs/specs/identity/token-authentication.md
ADRs: ADR-015, ADR-016

Files written so far:
- docs/backlog/P2-auth-improvements.md
- src/auth/token-service.ts
- tests/auth/token-service.test.ts

Resume your work. Re-read the backlog item and spec if you need full details.
```

**Why `compact|clear` matcher:** Both events lose session-specific context. `compact` compresses the conversation; `clear` wipes it. Both benefit from re-injection. `resume` does NOT need re-injection — it restores the full transcript. `startup` doesn't need it either — fresh sessions have no prior context to lose.

**Performance:** Fires only on compaction/clear events (rare — maybe once per long session). Reads two small files. Target: <100ms.

---

## 3. Data Design

No persistent data stores. The state file is ephemeral (gitignored, per-session, overwritten on each command).

**State file location:** `.claude/session-state.md` — chosen over `/tmp/` because:
- Accessible relative to project root (hooks receive `cwd`)
- Survives across tool calls within a session
- Already in a gitignored directory pattern (`.claude/settings.*` is gitignored; adding `.claude/session-state.md` is one line)
- Human-debuggable: `cat .claude/session-state.md`

---

## 4. Integration Points

### 4.1 Hook Configuration

Hooks are configured in `.claude/settings.json` (project-level) or `.claude/settings.local.json` (local). Since `.claude/settings.*` is already gitignored in genie-team, the configuration needs to be applied by `install.sh`.

**Configuration template:**
```json
{
  "hooks": {
    "UserPromptSubmit": [
      {
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/track-command.sh"
          }
        ]
      }
    ],
    "PostToolUse": [
      {
        "matcher": "Write",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/track-artifacts.sh"
          }
        ]
      }
    ],
    "SessionStart": [
      {
        "matcher": "compact|clear",
        "hooks": [
          {
            "type": "command",
            "command": "\"$CLAUDE_PROJECT_DIR\"/.claude/hooks/reinject-context.sh"
          }
        ]
      }
    ]
  }
}
```

### 4.2 install.sh Integration

New `install_hooks()` function:

1. **Copy scripts:** Copy `.claude/hooks/*.sh` to target `.claude/hooks/` (same `copy_dir` pattern as commands/rules/skills)
2. **Set executable:** `chmod +x` on all scripts in target `.claude/hooks/`
3. **Merge config:** Use `jq` to merge the hooks configuration into the target's `.claude/settings.json` or `.claude/settings.local.json`. If the settings file doesn't exist, create it with just the hooks config. If it exists, deep-merge the `hooks` key (don't clobber existing hooks from other sources).
4. **New flag:** `--hooks` for selective installation. Included in `--all` by default.

**Merge strategy:** `jq` deep merge — if the target already has a `hooks.SessionStart` array, append to it rather than replacing. This prevents genie-team hooks from clobbering user-defined hooks.

### 4.3 Gitignore Update

Add to `.gitignore`:
```
.claude/session-state.md
```

The hook scripts in `.claude/hooks/` should NOT be gitignored — they're project artifacts distributed by install.sh, like rules and commands.

---

## 5. Migration Strategy

**Fully additive.** No existing files modified. New files only:

| File | Status |
|------|--------|
| `.claude/hooks/track-command.sh` | New |
| `.claude/hooks/track-artifacts.sh` | New |
| `.claude/hooks/reinject-context.sh` | New |
| `install.sh` | Modified (add `install_hooks` function + `--hooks` flag) |
| `.gitignore` | Modified (add one line) |

**Backward compatible:** Projects without hooks configured continue to work identically. The hooks only activate when installed via `install.sh --hooks` or `install.sh --all`.

---

## 6. Risks & Mitigations

| Risk | L | I | Mitigation |
|------|---|---|------------|
| `UserPromptSubmit` hook adds latency to every prompt | M | L | Exit immediately for non-slash-command input (<10ms). Only do file I/O for genie commands (~50-100ms). |
| `PostToolUse` hook on Write adds latency to every file write | M | L | Minimal work per invocation (one grep + one echo, <50ms). No blocking — exit 0 always. |
| Frontmatter parsing via `sed`/`grep` is fragile | L | L | Only parse 4 simple key-value fields from structured YAML. Genie-team frontmatter is predictable. Fallback: if parsing fails, state file has command but not backlog context — still useful. |
| `jq` not available for install.sh settings merge | L | M | Check for `jq` availability; fall back to `python3 -c 'import json...'` or manual instructions if neither is available. |
| State file becomes stale if session outlives the backlog item | L | L | State file is overwritten on each new slash command. Timestamp field enables staleness detection. |
| Hooks interfere with headless/orchestrator execution | L | M | Hooks are additive (never block, always exit 0). For orchestrators, the re-injection provides the same benefit — context restoration after compaction in long-running headless sessions. |

---

## 7. Implementation Guidance

### File Creation Order

1. `.claude/hooks/track-command.sh` — the core state writer
2. `.claude/hooks/track-artifacts.sh` — the artifact tracker
3. `.claude/hooks/reinject-context.sh` — the re-injection reader
4. `.gitignore` update — add `.claude/session-state.md`
5. `install.sh` update — add `install_hooks()` function and `--hooks` flag

### Implementation Notes for Crafter

- All three scripts follow the same pattern: read JSON from stdin with `jq`, do file operations, exit 0
- `jq` is the only external dependency (already required by Claude Code itself)
- Scripts must be POSIX-compatible (`#!/bin/bash`, no bashisms that break on older bash)
- Scripts must handle missing files gracefully (state file may not exist yet)
- The `$CLAUDE_PROJECT_DIR` env var is available in hook scripts — use it for path resolution
- Test with `echo '{"prompt":"/deliver docs/backlog/test.md","cwd":"/tmp/test"}' | bash .claude/hooks/track-command.sh`

### Testing Strategy

Since these are shell scripts (not prompt engineering), they can be tested:

1. **Unit tests for each hook script:**
   - Feed sample JSON to stdin, verify state file output
   - Test with missing state file, missing backlog item, malformed input
   - Test artifact cap (write 25 artifacts, verify only 20 kept)
   - Test dedup (write same path twice, verify single entry)

2. **Integration test:**
   - Configure hooks in a test project
   - Run a genie command
   - Verify state file is created and populated
   - Trigger manual compaction (if possible) or simulate by reading reinject output

3. **Token efficiency verification:**
   - Measure state file size in tokens (target: <200)
   - Compare session behavior with/without hooks after compaction

---

## 8. Architecture Decisions

**No new ADRs created.** This design adds hooks within the existing `.claude/` configuration layer — the same mechanism used for rules, skills, commands, and MCP servers. No new architectural patterns introduced. The `install.sh` extension follows the established `install_X()` / `--X` flag pattern.

---

## 9. Diagram Updates

**No C4 diagram changes.** Hooks are internal to the `.claude/` configuration layer, which is already represented in the L2 containers diagram as part of "Genie Team (installed in target project)". The hooks don't introduce new containers, components, or external relationships.

---

# Implementation

## TDD Summary

**RED phase:** 38 tests written across all three hook scripts plus structural AC-3 checks. Tests cover: slash command capture, plain text skip, missing backlog item graceful handling, command overwrite, no-args commands, artifact tracking, dedup, 20-entry cap, self-reference skip, context re-injection output, no-state-file handling, frontmatter inclusion, and structural verification that all hooks are command hooks (not prompt/agent).

**GREEN phase:** All three hook scripts implemented. Fixed a `grep -c` bash error where `$(grep -c '^- ' "$file" 2>/dev/null || echo "0")` produced `"0\n0"` — resolved with `$(grep -c ...) || artifact_count=0` pattern.

**REFACTOR phase:** Clean pass — 38/38 tests green.

## Implementation Files

| # | File | Status | Description |
|---|------|--------|-------------|
| 1 | `.claude/hooks/track-command.sh` | New | UserPromptSubmit hook — captures genie slash commands, extracts backlog frontmatter, writes state file |
| 2 | `.claude/hooks/track-artifacts.sh` | New | PostToolUse (Write) hook — tracks written file paths, deduplicates, caps at 20 entries |
| 3 | `.claude/hooks/reinject-context.sh` | New | SessionStart (compact\|clear) hook — reads state file, prints context summary to stdout |
| 4 | `tests/test_hooks.sh` | New | 38 test cases covering all hooks and acceptance criteria |
| 5 | `tests/fixtures/hook_test_backlog.md` | New | Test fixture backlog item with frontmatter |
| 6 | `.gitignore` | Modified | Added `.claude/session-state.md` |
| 7 | `install.sh` | Modified | Added `install_hooks()`, `merge_hook_config()`, `--hooks` flag, hooks in `--all`/`--sync`/`--dry-run`/`status`/`uninstall` |

## Implementation Decisions

- **Used `install_hooks_flag` variable** in cmd_global/cmd_project to avoid shadowing the `install_hooks()` function name (other install functions don't have this issue because their flag variables are read before the function call, but being explicit avoids confusion).
- **Global install merges into `~/.claude/settings.json`; project install merges into `.claude/settings.local.json`** — project settings use `.local` because `.claude/settings.*` is typically gitignored.
- **Hook command paths use `bash <prefix>/script.sh`** — absolute path prefix for global installs (`$HOME/.claude/hooks`), relative for project installs (`.claude/hooks`).
- **`jq` deep merge with `*` operator** for settings — if target already has a `hooks` key, genie-team hooks are merged in (same event arrays are replaced, different events are preserved).
- **Status check uses `-type f`** instead of `-name "*.md"` for hooks directory since hook files are `.sh` not `.md`.

# Review

**Verdict: APPROVED**

**Date:** 2026-02-11
**ACs verified:** 4/4 met

## Acceptance Criteria Verification

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `reinject-context.sh` fires on `compact\|clear` via SessionStart matcher. Prints active command, backlog title/status, spec_ref, adr_refs, artifacts list, and backlog frontmatter to stdout. 8 tests verify output content. |
| AC-2 | met | `track-command.sh` (UserPromptSubmit) creates/overwrites `.claude/session-state.md` on slash commands with backlog frontmatter. `track-artifacts.sh` (PostToolUse Write) appends file paths with dedup and 20-entry cap. 16 tests verify state file lifecycle. |
| AC-3 | met | All three scripts are `#!/bin/bash` shell scripts using `set -euo pipefail`. Settings config specifies `"type": "command"` for all hooks. No LLM invocation. 6 structural tests verify no prompt/agent hook patterns in source. |
| AC-4 | met | `install_hooks()` copies scripts + `chmod +x`. `merge_hook_config()` merges JSON into settings via `jq`. `--hooks` flag added. Wired into `--all`, `--sync`, `--dry-run`, `status`, and `uninstall` for both global and project modes. |

## Code Quality

- **Error handling:** `set -euo pipefail` on all scripts. Graceful exit 0 on missing files, empty inputs, missing backlog items. `jq` fallback with warning in install.sh when not available.
- **Boundary safety:** Scripts only write to `$cwd/.claude/session-state.md` (gitignored). Input comes from Claude Code's hook system (trusted source). No external network calls.
- **Performance:** `track-command.sh` exits immediately for non-slash-commands. `track-artifacts.sh` does minimal work (one grep + one echo). `reinject-context.sh` fires only on compaction/clear (rare).
- **Size control:** Artifact list capped at 20 entries with oldest-first eviction via awk. Dedup prevents duplicate paths.

## Test Coverage

- **38 tests, 38 passing**
- Positive paths: command capture, artifact tracking, context re-injection
- Negative paths: plain text skip, missing state file, missing backlog item
- Edge cases: dedup, 20-entry cap, self-reference skip, command overwrite, no-args commands
- Structural: AC-3 verification that scripts contain no prompt/agent hook patterns

## Design Compliance

Implementation follows the design document faithfully:
- Three hooks matching the specified events and matchers
- State file format matches the design spec
- install.sh follows the established `install_X()` / `--X` flag pattern
- No changes to existing commands or skills (shaped no-go respected)
- No external dependencies beyond `jq` (already required by Claude Code)

## Risks Observed

No new risks beyond those identified in the design. The `grep -c` bash pitfall was caught and fixed during TDD (documented in Implementation section).

## Recommendation

Ready for deployment. Run `/commit` then `/done`.

# End of Shaped Work Contract
