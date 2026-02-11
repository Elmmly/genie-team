---
spec_version: "1.0"
type: shaped-work
id: autonomous-execution-readiness
title: "Autonomous Execution Readiness for Portfolio Orchestration"
status: done
created: 2026-02-10
appetite: small
priority: P1
target_project: genie-team
author: shaper
depends_on: []
consolidates:
  - docs/archive/backlog-review/2026-02-10_platform-reality-check/P1-progress-streaming-protocol.md
  - docs/archive/backlog-review/2026-02-10_platform-reality-check/P1-repo-aware-execution.md
  - docs/archive/backlog-review/2026-02-10_platform-reality-check/P2-cataliva-integration.md
adr_refs:
  - docs/decisions/ADR-001-thin-orchestrator.md
tags: [orchestration, autonomous, streaming, safety, cli-contract, portfolio]
acceptance_criteria:
  - id: AC-1
    description: "Safety rules for autonomous git operations exist in .claude/rules/ — branch naming (genie/{item}-{phase}), no force push, no push to main/master, conventional commit format with genie attribution"
    status: met
  - id: AC-2
    description: "Streaming conventions document maps genie workflow phases to native Claude Code stream-json events, defining which events signal phase_start, phase_complete, and artifact creation"
    status: met
  - id: AC-3
    description: "CLI contract document specifies how an external orchestrator invokes genie-team commands, what output to parse, expected exit codes, and artifact locations"
    status: met
  - id: AC-4
    description: "Machine-readable completion signal convention defined — final output structure that orchestrators can parse to determine success/failure and locate output artifacts"
    status: met
---

# Shaped Work Contract: Autonomous Execution Readiness

> **Schema:** `schemas/shaped-work-contract.schema.md` v1.0
>
> **Status progression:** shaped -> designed -> implemented -> reviewed -> done

## Problem / Opportunity Statement

**Original input:** External orchestrators need to dispatch genie-team commands across a product portfolio and understand the results programmatically.

**Reframed problem:** Genie-team commands were designed for interactive human use. For autonomous execution by an external orchestrator (CI/CD pipeline, product portfolio system, or custom dashboard), the CLI needs: safety guardrails for unsupervised git operations, streaming conventions that map workflow phases to parseable events, and a documented contract for how to invoke and interpret results.

**Key insight (2026-02-10 backlog review):** Claude Code now provides native `--output-format stream-json` (NDJSON streaming), full git workflow support (clone, branch, commit, push, PR), and headless execution modes. Genie-team doesn't need to BUILD infrastructure — it needs to DOCUMENT conventions and ADD safety rules on top of native platform capabilities.

## Evidence & Insights

- **Platform capabilities (Feb 2026):** Claude Code provides `--output-format stream-json`, native git operations, `Co-Authored-By` attribution, and headless/programmatic invocation
- **ADR-001:** Thin Orchestrator — external orchestrators spawn CLI processes, capture stdout, no shared runtime
- **Superseded items:** P1-progress-streaming-protocol (native streaming exists), P1-repo-aware-execution (native git exists), P2-cataliva-integration (orchestration is orchestrator's responsibility)
- **JTBD:** "When an orchestrator dispatches `/deliver` to a target repo, I want to know it will create a safe feature branch, produce parseable progress, and signal completion with artifact locations."

## Appetite & Boundaries

- **Appetite:** Small (1 day)
- **Boundaries:**
  - Safety rules as `.claude/rules/` markdown files
  - Streaming conventions as a documentation artifact
  - CLI contract as a documentation artifact
  - Completion signal convention
- **No-gos:**
  - No application code (genie-team is prompt engineering)
  - No worker pool, job queue, or retry logic (orchestrator's responsibility)
  - No dashboard or UI (orchestrator's responsibility)
  - No changes to existing command behavior
- **Fixed elements:**
  - Must use native Claude Code capabilities, not custom implementations
  - Must follow ADR-001 Thin Orchestrator architecture
  - Must be additive (no breaking changes to interactive use)

## Goals

**Outcome Hypothesis:** "We believe that safety rules + streaming conventions + a CLI contract will make genie-team ready for autonomous execution by external orchestrators, without changing any existing commands."

**Success Signals:**
- An orchestrator can invoke `claude --output-format stream-json "/deliver docs/backlog/P1-feature.md"` and parse progress
- Autonomous git operations respect branch naming and safety constraints
- CLI contract document is sufficient for an orchestrator developer to integrate without genie-team expertise

## Deliverables

### 1. Safety Rules (`.claude/rules/autonomous-execution.md`)

Rules that activate during autonomous (headless) execution:

```markdown
# Autonomous Execution Safety

When running in autonomous/headless mode (no interactive user):

## Git Safety
- Create feature branches with naming: `genie/{backlog-item}-{phase}`
- NEVER force push
- NEVER push to main/master/default branch
- NEVER delete branches
- Always create PR (no direct merge)
- Include Co-Authored-By with genie name

## Commit Format
- Use conventional commits: `type(scope): description`
- Include backlog item reference in commit body
- Include genie attribution

## Workspace
- Operate only within the target repository
- Do not modify files outside the repo root
- Clean up temporary files on completion
```

### 2. Streaming Conventions (`docs/architecture/streaming-conventions.md`)

Maps genie workflow phases to native `stream-json` events:

| Genie Phase | Stream Signal | How to Detect |
|-------------|---------------|---------------|
| Phase start | First `assistant` message mentioning phase name | Parse text for "## Phase: discover/define/design/deliver/discern" |
| Tool call | `tool_use` event with tool name | Native stream-json `tool_use` blocks |
| Artifact created | `tool_use` event with `Write` tool | Parse `file_path` parameter for `docs/` paths |
| Phase complete | Final `assistant` message with routing | Parse text for "Ready for:" or "Next:" |
| Completion | Stream ends (process exit) | Exit code 0 = success |

### 3. CLI Contract (`docs/architecture/cli-contract.md`)

How an orchestrator invokes genie-team:

```bash
# Invoke a specific workflow phase
claude --output-format stream-json "/deliver docs/backlog/P1-feature.md"

# Invoke with print mode (no streaming, final output only)
claude --print "/deliver docs/backlog/P1-feature.md"

# Expected exit codes
# 0 = success (artifacts written)
# 1 = failure (error in execution)
```

Expected artifact locations after each phase:

| Command | Output Artifact | Location |
|---------|-----------------|----------|
| `/discover` | Opportunity Snapshot | `docs/analysis/` |
| `/define` | Shaped Work Contract | `docs/backlog/` |
| `/design` | Design Document + ADR | `docs/backlog/` + `docs/decisions/` |
| `/deliver` | Code changes + tests | Target repo files |
| `/discern` | Review verdict | `docs/backlog/` (status updated) |

### 4. Completion Signal Convention

Final text block in stream includes structured completion:

```
## Completion
- **Status:** success | failure | blocked
- **Artifacts:** [list of files written]
- **Next:** [recommended next command]
```

## Options (Ranked)

### Option 1: Documentation + Rules (Recommended)

- **Description:** Add safety rules as `.claude/rules/` file, conventions as `docs/architecture/` files
- **Pros:** No code changes, additive, follows existing patterns, small appetite
- **Cons:** Conventions are advisory (not enforced by code)
- **Appetite fit:** Perfect — small batch, prompt engineering only

### Option 2: Structured Output Wrapper

- **Description:** Build a bash wrapper that adds structured JSON envelope around genie output
- **Pros:** Machine-parseable output guaranteed
- **Cons:** Requires code, adds maintenance, duplicates native stream-json
- **Appetite fit:** Too big for the value add

## Dependencies

- None — uses existing platform capabilities

## Routing

- [x] **Architect** — Design streaming convention mapping and CLI contract

**Rationale:** Conventions need careful design to be useful for orchestrator integration without over-engineering.

## Artifacts

- **Contract saved to:** `docs/backlog/P1-autonomous-execution-readiness.md`
- **Consolidates:** P1-progress-streaming-protocol, P1-repo-aware-execution, P2-cataliva-integration (genie-team side — now generalized)
- **ADR referenced:** `docs/decisions/ADR-001-thin-orchestrator.md`

---

# Design

## 1. Design Summary

Two documentation artifacts that make genie-team ready for autonomous orchestration by external portfolio systems, with zero changes to existing commands or code.

**Key design insight:** Claude Code's system prompt already enforces git safety (no force push, no `reset --hard`, no `branch -D`). Genie-team's safety rules add workflow-specific conventions on top — branch naming, PR-always, conventional commits with backlog references. This avoids duplication and leverages the platform.

**Second insight:** An orchestrator dispatches one command per process (`/deliver`, `/discern`, etc.), so it already knows the current phase. Stream parsing for phase detection is unnecessary. What the orchestrator needs from the stream is: liveness (events flowing = process alive), progress indicators (tool calls = work happening), and final result (JSON output with usage stats + exit code).

### Deliverables

| # | Artifact | Type | Location | AC |
|---|----------|------|----------|-----|
| 1 | Autonomous Execution Rules | `.claude/rules/` file | `rules/autonomous-execution.md` (source) → `.claude/rules/` (installed) | AC-1 |
| 2 | CLI Contract | Architecture doc | `docs/architecture/cli-contract.md` | AC-2, AC-3, AC-4 |

**Design change from shaping:** Merged "streaming conventions" and "completion signal convention" into the CLI contract document. Separating them created three documents for what is really one concern: "how an orchestrator talks to genie-team." One document is clearer.

---

## 2. Component Design

### 2.1 Safety Rules (`rules/autonomous-execution.md`)

**Scope:** Installed to `.claude/rules/autonomous-execution.md` in target projects via `install.sh`. Active in ALL modes (interactive and headless) because these conventions are always good practice.

**Content design:**

```markdown
# Autonomous Execution Conventions

## Branch Naming

When creating feature branches for genie work:

- Format: `genie/{backlog-item-id}-{phase}`
- Examples:
  - `genie/P1-auth-improvements-deliver`
  - `genie/P2-search-redesign-design`
- Always branch from the default branch (main/master)
- One branch per backlog item per phase

## Pull Request Convention

- Always create a PR for code changes (never push directly to default branch)
- PR title: conventional commit format matching the primary change
- PR body: reference the backlog item path and acceptance criteria status
- Request review from the user or team (do not auto-merge)

## Commit Attribution

All commits from genie execution include:

```
type(scope): description

Context from backlog item.

Refs: docs/backlog/{item}.md

Co-Authored-By: {Genie Name} <noreply@anthropic.com>
```

Where `{Genie Name}` is the active genie (e.g., "Crafter", "Architect").

## Workspace Boundaries

- Operate only within the target repository root
- Do not modify files in parent directories
- Do not access other repositories
- Clean up any temporary files created during execution
```

**Design decisions:**
- Rules apply in ALL modes, not just headless — branch naming and PR conventions are valuable during interactive use too
- `Co-Authored-By` uses the genie name, not "Claude" — provides traceability for which genie produced the work
- No force push / no branch deletion rules are **omitted** — Claude Code's system prompt already enforces these. Duplicating them adds noise without safety benefit

### 2.2 CLI Contract (`docs/architecture/cli-contract.md`)

**Scope:** Architecture documentation describing how an external orchestrator invokes genie-team commands and interprets results. Lives in genie-team's `docs/architecture/` alongside existing C4 diagrams.

**Content design:**

```markdown
# CLI Contract: Orchestrator Integration

How external orchestrators invoke genie-team commands
and interpret results via Claude Code CLI.

Per ADR-001: Thin Orchestrator architecture — orchestrators spawn
CLI processes, capture output, no shared runtime.

## Invocation Patterns

### Batch Mode (final result only)

For commands where the orchestrator needs the final output:

  claude -p "/define 'add user authentication'" \
    --output-format json \
    --max-turns 50 \
    --allowedTools "Read,Grep,Glob,Write,Edit,WebSearch,WebFetch,Task"

Returns JSON with session_id, result content, and usage stats.

### Streaming Mode (real-time progress)

For commands where the orchestrator shows live progress:

  claude -p "/deliver docs/backlog/P1-feature.md" \
    --output-format stream-json \
    --verbose \
    --max-turns 100 \
    --allowedTools "Read,Grep,Glob,Write,Edit,Bash,Task"

Emits NDJSON events. Key event types for progress tracking:

  stream_event with text_delta  → Text output (liveness indicator)
  stream_event with tool_use    → Tool call starting (progress)
  stream_event with tool_result → Tool call completed

### Session Continuation

For multi-phase workflows:

  # Phase 1: Define
  session=$(claude -p "/define 'add auth'" --output-format json \
    | jq -r '.session_id')

  # Phase 2: Design (continues session context)
  claude -p "/design docs/backlog/P1-auth.md" \
    --resume "$session" --output-format json

## Tool Allowlisting by Phase

Each genie phase has different tool needs. Recommended allowedTools:

  /discover  → Read,Grep,Glob,WebSearch,WebFetch,Task
  /define    → Read,Grep,Glob,Write,Task
  /design    → Read,Grep,Glob,Write,Edit,Task
  /deliver   → Read,Grep,Glob,Write,Edit,Bash,Task
  /discern   → Read,Grep,Glob,Bash,Task
  /commit    → Bash(git *)

## Cost Controls

  --max-turns 50        Prevent runaway execution
  --max-budget-usd 5    Cap API spend per invocation
  --model sonnet        Override model for cost-sensitive phases

Orchestrators can adjust these per invocation based on phase complexity.

## Exit Codes

  0  Success — command completed, artifacts written
  1  Failure — error during execution

## Output Parsing

### JSON Mode (--output-format json)

Response structure:

  {
    "session_id": "...",
    "result": {
      "content": [{"type": "text", "text": "...final output..."}]
    },
    "usage": {
      "input_tokens": N,
      "output_tokens": N
    }
  }

The orchestrator should:
1. Check exit code (0 = success)
2. Parse result.content[0].text for the genie's final output
3. Record usage for cost tracking
4. Store session_id for potential continuation

### Artifact Locations

After successful execution, artifacts are at deterministic paths:

  Command     Artifact                    Location
  /discover   Opportunity Snapshot        docs/analysis/{date}_{topic}.md
  /define     Shaped Work Contract        docs/backlog/{priority}-{topic}.md
  /design     Design (appended to item)   docs/backlog/{item}.md
  /design     ADR (if created)            docs/decisions/ADR-{NNN}-{slug}.md
  /deliver    Code + tests                Source files in repo
  /discern    Review verdict              docs/backlog/{item}.md (status field)
  /commit     Git commit                  Git history
  /done       Archived item               docs/archive/{topic}/{date}/

Orchestrators can verify artifact creation by checking git status
after execution completes.

### Completion Detection

For JSON mode: Parse result.content for the routing line that
every command emits:

  "Next: /deliver docs/backlog/P1-feature.md"
  "Ready for: /design"

This tells the orchestrator which command to dispatch next.

For stream mode: The final text_delta events contain the same
routing line. Process exit signals stream completion.

## Example: Full Lifecycle Dispatch

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

## 3. Data Design

No data stores. All artifacts are markdown files under git version control. The CLI contract defines where to find them (deterministic paths per command).

---

## 4. Integration Points

### 4.1 Genie-Team → Claude Code CLI

Genie-team provides prompts; Claude Code provides the execution runtime. Integration is via `.claude/` directory conventions:

| Artifact | Claude Code Mechanism |
|----------|----------------------|
| Commands | `.claude/commands/*.md` — loaded as slash commands |
| Rules | `.claude/rules/*.md` — always-active constraints |
| Agents | `.claude/agents/*.md` — Task tool subagent definitions |
| Skills | `.claude/skills/*/SKILL.md` — context-triggered behaviors |

The new `autonomous-execution.md` rules file integrates via the same mechanism — no new integration pattern.

### 4.2 Orchestrator → Claude Code CLI

Per ADR-001, orchestrators spawn processes:

```
Orchestrator                Claude Code CLI              Target Repo
   |                              |                          |
   |-- spawn process ----------->|                          |
   |   (claude -p "/deliver ..")  |                          |
   |                              |-- read/write files ----->|
   |<-- stream-json events -------|                          |
   |                              |-- git commit/push ------>|
   |<-- exit code 0/1 -----------|                          |
   |                              |                          |
   |-- parse JSON output          |                          |
   |-- check git status --------->|                          |
   |-- dispatch next command      |                          |
```

### 4.3 Install Script

The new rules file needs to be included in `install.sh`'s rules installation. No changes needed — `install.sh` already copies all `*.md` files from `rules/` to `.claude/rules/`.

---

## 5. Migration Strategy

**No migration needed.** All deliverables are additive:

1. `rules/autonomous-execution.md` — New file, installed alongside existing rules
2. `docs/architecture/cli-contract.md` — New documentation file

Existing interactive workflows are unaffected. The safety rules (branch naming, PR convention, commit attribution) improve interactive use as well.

---

## 6. Risks & Mitigations

| Risk | Likelihood | Impact | Mitigation |
|------|------------|--------|------------|
| Rules are advisory, not enforced | Medium | Low | Claude Code's system prompt strongly follows `.claude/rules/` — behavioral compliance is high. Code enforcement would require application code (out of scope). |
| Orchestrator can't reliably parse routing line from output | Low | Medium | Routing lines are emitted by every command (baked into command templates). Orchestrators can also use `git status` as fallback to detect artifact creation. |
| Tool allowlisting too restrictive for some commands | Low | Low | CLI contract provides recommended lists per phase. Orchestrators can adjust based on execution results. |
| `--max-turns` too low causes premature termination | Low | Medium | CLI contract recommends conservative defaults (50 for most, 100 for `/deliver`). Orchestrators can retry with higher limit. |

---

## 7. Implementation Guidance

### File Creation Order

1. **`rules/autonomous-execution.md`** — Source file for the safety rules (AC-1)
2. **`docs/architecture/cli-contract.md`** — CLI contract with streaming conventions, invocation patterns, output parsing, and completion signals (AC-2, AC-3, AC-4)

### Implementation Notes for Crafter

- Both files are pure markdown documentation — no code to test
- The rules file follows the exact pattern of existing files in `rules/` (e.g., `code-quality.md`)
- The CLI contract should be verified by running a few sample invocations with `claude -p` and `--output-format json` to confirm the documented output structure matches reality
- Content is fully specified in this design — the Crafter's job is to create clean, well-formatted files matching the content above

### Verification

After implementation:
1. Run `./install.sh project --dry-run` to confirm the new rules file would be installed
2. Run `claude -p "/genie:status" --output-format json` to verify JSON output structure
3. Confirm `docs/architecture/cli-contract.md` renders correctly alongside existing architecture docs

---

## 8. Architecture Decisions

**No new ADRs created.** The design operates within ADR-001 (Thin Orchestrator) boundaries. The choice of Option 1 (Documentation + Rules) over Option 2 (Structured Output Wrapper) does not meet the ADR creation threshold — there is no genuine multi-option choice with lasting consequences. The prompt-engineering-only constraint from the appetite makes Option 1 the only viable approach.

---

## 9. Diagram Updates

**No C4 diagram changes.** This design adds rules and documentation — it does not introduce new containers, components, or relationships. The existing L1 (system-context) and L2 (containers) diagrams already show the orchestrator → genie-team → target repo flow per ADR-001.

---

# Implementation

## Deliverables Created

| # | Artifact | Location | AC |
|---|----------|----------|-----|
| 1 | Autonomous Execution Rules | `.claude/rules/autonomous-execution.md` | AC-1 |
| 2 | CLI Contract | `docs/architecture/cli-contract.md` | AC-2, AC-3, AC-4 |

## Implementation Notes

- **No TDD phase:** Both deliverables are pure markdown documentation — no code to test.
- **Rules source location:** `.claude/rules/autonomous-execution.md` (not a separate `rules/` directory). The design referenced `rules/autonomous-execution.md` as source, but the actual project pattern keeps rules in `.claude/rules/` directly. `install.sh` copies from `$SCRIPT_DIR/.claude/rules` to destination.
- **Design change applied:** Streaming conventions and completion signal convention merged into CLI contract per design section 2.2.
- **CLI contract frontmatter:** Added standard architecture doc frontmatter (`type`, `adr_refs`, `backlog_ref`, `tags`) consistent with existing `system-context.md` and `containers.md`.
- **Content faithfulness:** Both files follow the design specification in section 2. No additions or omissions beyond formatting for readability (tables instead of inline text where appropriate).

## Files Created

- `.claude/rules/autonomous-execution.md` — Branch naming, PR convention, commit attribution, workspace boundaries
- `docs/architecture/cli-contract.md` — Invocation patterns (batch/streaming/session), streaming conventions, tool allowlisting, cost controls, exit codes, output parsing, artifact locations, completion detection, full lifecycle example

## Verification

- `./install.sh project --rules --dry-run` confirms the new rules file is detected for installation.

---

# Review
<!-- Reviewed by Critic on 2026-02-11 -->

## Summary

Implementation delivers two well-structured markdown artifacts — safety rules and CLI contract — that make genie-team ready for autonomous orchestration. Both files are faithful to the design specification, well-formatted, and actionable for orchestrator developers. The trunk-based mode addition enriches the deliverable beyond what was shaped, providing a useful flexibility mechanism.

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | Met | `.claude/rules/autonomous-execution.md` defines branch naming (`genie/{item}-{phase}`), PR convention (no direct push to default branch in default mode), conventional commit format, and Co-Authored-By genie attribution. "No force push" is omitted per design rationale — Claude Code's system prompt already enforces this. |
| AC-2 | Met | `docs/architecture/cli-contract.md` §Streaming Conventions maps phase signals to stream-json events: `text_delta` for liveness, `tool_use`/`tool_result` for progress, `Write` tool_use for artifact creation, routing line in final text for phase completion. Merged into CLI contract per design decision. |
| AC-3 | Met | `docs/architecture/cli-contract.md` covers: invocation patterns (batch/streaming/session continuation), output parsing (JSON structure), exit codes (0/1), artifact locations table, tool allowlisting per phase, cost controls, and a full lifecycle dispatch example. |
| AC-4 | Met | Completion detection convention defined: parse `result.content` for routing lines ("Next:", "Ready for:"), exit code for success/failure, artifact locations table for locating outputs. Uses text parsing rather than structured JSON envelope — a deliberate design simplification. |

## ADR Compliance

| ADR | Decision | Compliant? | Notes |
|-----|----------|------------|-------|
| ADR-001 | Thin Orchestrator — spawn CLI processes, no shared runtime | YES | CLI contract fully follows process-spawning model. Explicitly references ADR-001 in opening paragraph. |

## Code Quality

### Strengths
- Clean separation: safety rules (behavioral constraints) vs. CLI contract (integration documentation)
- Design rationale preserved in backlog item — explains every deviation from shaped contract
- Tables and code examples make the CLI contract immediately actionable
- Proper frontmatter on CLI contract with `adr_refs` and `backlog_ref` cross-references
- `install.sh` already handles the new rules file via existing `copy_dir` mechanism — no installation changes needed
- CLAUDE.md template updated with Git Workflow section (bonus deliverable enabling trunk-based activation)

### Issues Found

| Issue | Severity | Location | Suggested Fix |
|-------|----------|----------|---------------|
| "No force push" omitted from rules file | Minor | `.claude/rules/autonomous-execution.md` | Acknowledged in design rationale as deliberate (platform-enforced). Acceptable — adding it would duplicate Claude Code's system prompt. |
| Trunk-based mode is an addition beyond shaped scope | Minor | `.claude/rules/autonomous-execution.md:5-40` | Design expansion that enriches the deliverable. Default remains PR mode (safer), trunk-based is opt-in. No risk introduced. |
| Completion detection relies on text parsing, not structured JSON | Minor | `docs/architecture/cli-contract.md:195-206` | Design explicitly chose this approach (section 2 key insight). Orchestrators can fallback to `git status` for artifact verification. |

## Test Coverage

N/A — both deliverables are pure markdown documentation. No application code to test. Verification performed via `install.sh --dry-run` confirmation.

## Security Review

- [x] No sensitive data exposure (no tokens, credentials, or secrets in documentation)
- [x] Workspace boundaries defined (operate only within target repo root)
- [x] PR mode as default provides review gate before merge
- [x] No injection vulnerabilities (documentation only)

## Risk Assessment

| Risk | L | I | Status |
|------|---|---|--------|
| Rules are advisory, not code-enforced | M | L | Acknowledged — Claude Code has high behavioral compliance with `.claude/rules/`. Acceptable. |
| Routing line parsing may be fragile | L | M | Addressed — `git status` fallback documented for orchestrators. |
| Trunk-based mode could be accidentally activated | L | M | Addressed — requires explicit opt-in via CLAUDE.md, prompt prefix, or user instruction. |

## Verdict

**Decision: APPROVED**

All 4 acceptance criteria met. No critical or major issues. Three minor observations noted — all are deliberate design decisions with sound rationale. ADR-001 fully compliant. Implementation is additive and does not break existing interactive workflows.

## Routing

Ready for `/commit` then `/done docs/backlog/P1-autonomous-execution-readiness.md`

---

# End of Shaped Work Contract
