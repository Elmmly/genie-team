---
type: architecture-doc
title: "CLI Contract: Orchestrator Integration"
updated: 2026-02-10
updated_by: "/deliver P1-autonomous-execution-readiness"
adr_refs:
  - docs/decisions/ADR-001-thin-orchestrator.md
backlog_ref: docs/archive/orchestration/2026-02-11_autonomous-execution-readiness/P1-autonomous-execution-readiness.md
tags: [orchestration, cli, contract, streaming, portfolio]
---

# CLI Contract: Orchestrator Integration

How external orchestrators invoke genie-team commands and interpret results via Claude Code CLI.

Per ADR-001: Thin Orchestrator architecture — orchestrators spawn CLI processes, capture output, no shared runtime.

---

## Invocation Patterns

### Batch Mode (final result only)

For commands where the orchestrator needs the final output:

```bash
claude -p "/define 'add user authentication'" \
  --output-format json \
  --max-turns 50 \
  --allowedTools "Read,Grep,Glob,Write,Edit,WebSearch,WebFetch,Task"
```

Returns JSON with `session_id`, result content, and usage stats.

### Streaming Mode (real-time progress)

For commands where the orchestrator shows live progress:

```bash
claude -p "/deliver docs/backlog/P1-feature.md" \
  --output-format stream-json \
  --verbose \
  --max-turns 100 \
  --allowedTools "Read,Grep,Glob,Write,Edit,Bash,Task"
```

Emits NDJSON events. Key event types for progress tracking:

| Event Type | Meaning | Use |
|------------|---------|-----|
| `text_delta` | Text output chunk | Liveness indicator |
| `tool_use` | Tool call starting | Progress (work happening) |
| `tool_result` | Tool call completed | Progress (step done) |

### Session Continuation

For multi-phase workflows where context should carry across phases:

```bash
# Phase 1: Define
session=$(claude -p "/define 'add auth'" --output-format json \
  | jq -r '.session_id')

# Phase 2: Design (continues session context)
claude -p "/design docs/backlog/P1-auth.md" \
  --resume "$session" --output-format json
```

### Parallel Invocation via Worktrees

For running multiple jobs concurrently on the same repository:

```bash
# Create a worktree per job (each on a unique branch)
git worktree add "../${repo}--${job_id}" -b "genie/${backlog_id}-${phase}"

# Launch Claude session in the worktree directory
cd "../${repo}--${job_id}"
claude -p "/deliver docs/backlog/${backlog_id}.md" \
  --output-format stream-json \
  --max-turns 100

# After job completes: merge/PR, then clean up
cd ..
git worktree remove "${repo}--${job_id}"
```

Each worktree has its own working directory, branch, and index.
No coordination needed between parallel sessions — git's branch-per-worktree
constraint prevents conflicts. Genie-team's PR mode branch naming
(`genie/{item}-{phase}`) produces unique branches naturally.

Note: `--resume` does not work across worktrees (different project paths).
Each worktree session is independent. Cross-session context transfers via
the document trail (`docs/`).

---

## Streaming Conventions

Genie-team commands produce structured text output that orchestrators can parse from the stream.

### Phase Signals

| Signal | How to Detect | Notes |
|--------|---------------|-------|
| Phase start | First `text_delta` events after process launch | Orchestrator already knows the phase (it dispatched the command) |
| Tool activity | `tool_use` / `tool_result` events | Indicates active work; absence may indicate thinking |
| Artifact created | `tool_use` with `Write` tool | Parse `file_path` parameter for `docs/` paths |
| Phase complete | Final `text_delta` events with routing line | Parse for "Next:" or "Ready for:" |
| Process complete | Stream ends, process exits | Exit code determines success/failure |

### Key Insight

An orchestrator dispatches one command per process (`/deliver`, `/discern`, etc.), so it already knows the current phase. Stream parsing for phase detection is unnecessary. What the orchestrator needs is:

1. **Liveness** — events flowing = process alive
2. **Progress** — tool calls = work happening
3. **Result** — JSON output with usage stats + exit code

---

## Tool Allowlisting by Phase

Each genie phase has different tool needs. Recommended `--allowedTools`:

| Command | Recommended Tools |
|---------|-------------------|
| `/discover` | `Read,Grep,Glob,WebSearch,WebFetch,Task` |
| `/define` | `Read,Grep,Glob,Write,Task` |
| `/design` | `Read,Grep,Glob,Write,Edit,Task` |
| `/deliver` | `Read,Grep,Glob,Write,Edit,Bash,Task` |
| `/discern` | `Read,Grep,Glob,Bash,Task` |
| `/commit` | `Bash` (git operations) |

Orchestrators can adjust these per invocation based on phase complexity.

---

## Git Workflow Mode

**Default: PR mode** (feature branches + pull requests). Trunk-based mode is opt-in.

### Activating Trunk-Based Mode

| Method | Scope | How |
|--------|-------|-----|
| **CLAUDE.md** | Project (persistent) | Add `## Git Workflow` section with `trunk-based` to the target project's `CLAUDE.md` |
| **Prompt prefix** | Per-invocation | Prepend `git-mode: trunk.` to the command prompt |
| **User instruction** | Interactive session | Tell the genie "use trunk-based mode" |

Example — project-level activation in the target project's `CLAUDE.md`:

```markdown
## Git Workflow
trunk-based
```

Example — per-invocation activation by an orchestrator:

```bash
claude -p "git-mode: trunk. /deliver docs/backlog/P1-feature.md" \
  --output-format json
```

### Mode Comparison

| Behavior | PR Mode | Trunk-Based Mode |
|----------|---------|------------------|
| Branching | `genie/{item}-{phase}` | None (commits to default branch) |
| Pull request | Always | Never |
| Commit size | Per-phase | Small, self-contained |
| Review gate | PR review | CI / post-commit |
| Commit attribution | Conventional commits + Co-Authored-By | Same |

---

## Cost Controls

| Flag | Purpose | Recommended Default |
|------|---------|---------------------|
| `--max-turns` | Prevent runaway execution | 50 (most phases), 100 (`/deliver`) |
| `--max-budget-usd` | Cap API spend per invocation | 5 |
| `--model` | Override model for cost-sensitive phases | `sonnet` for `/discover`, `/define` |

---

## Exit Codes

| Code | Meaning |
|------|---------|
| `0` | Success — command completed, artifacts written |
| `1` | Failure — error during execution |

---

## Output Parsing

### JSON Mode (`--output-format json`)

Response structure:

```json
{
  "session_id": "...",
  "result": {
    "content": [{"type": "text", "text": "...final output..."}]
  },
  "usage": {
    "input_tokens": 0,
    "output_tokens": 0
  }
}
```

The orchestrator should:

1. Check exit code (`0` = success)
2. Parse `result.content[0].text` for the genie's final output
3. Record `usage` for cost tracking
4. Store `session_id` for potential continuation

### Completion Detection

Parse `result.content` for the routing line that every command emits:

```
Next: /deliver docs/backlog/P1-feature.md
Ready for: /design
```

This tells the orchestrator which command to dispatch next.

For stream mode: The final `text_delta` events contain the same routing line. Process exit signals stream completion.

---

## Artifact Locations

After successful execution, artifacts are at deterministic paths:

| Command | Artifact | Location |
|---------|----------|----------|
| `/discover` | Opportunity Snapshot | `docs/analysis/{date}_{topic}.md` |
| `/define` | Shaped Work Contract | `docs/backlog/{priority}-{topic}.md` |
| `/design` | Design (appended to item) | `docs/backlog/{item}.md` |
| `/design` | ADR (if created) | `docs/decisions/ADR-{NNN}-{slug}.md` |
| `/deliver` | Code + tests | Source files in repo |
| `/discern` | Review verdict | `docs/backlog/{item}.md` (status field) |
| `/commit` | Git commit | Git history |
| `/done` | Archived item | `docs/archive/{topic}/{date}/` |

Orchestrators can verify artifact creation by checking `git status` after execution completes.

---

## Example: Full Lifecycle Dispatch

```bash
# 1. Define the work
claude -p "/define 'add password reset'" \
  --output-format json > define.json

# 2. Parse the backlog item path from output
item=$(jq -r '.result.content[0].text' define.json \
  | grep -o 'docs/backlog/[^ ]*\.md')

# 3. Design
session=$(jq -r '.session_id' define.json)
claude -p "/design $item" --resume "$session" \
  --output-format json > design.json

# 4. Deliver (with streaming for progress)
claude -p "/deliver $item" \
  --output-format stream-json --verbose \
  --max-turns 100 \
  --allowedTools "Read,Grep,Glob,Write,Edit,Bash,Task"

# 5. Review
claude -p "/discern $item" --output-format json > review.json

# 6. Check verdict
verdict=$(jq -r '.result.content[0].text' review.json \
  | grep -o 'APPROVED\|BLOCKED')
```

---

## Related Documents

- **ADR-001:** [Thin Orchestrator](../decisions/ADR-001-thin-orchestrator.md) — architectural decision
- **System Context:** [L1 Diagram](system-context.md) — shows orchestrator → genie-team → target repo flow
- **Containers:** [L2 Diagram](containers.md) — internal genie-team structure
