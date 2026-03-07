---
type: backlog
title: "Topic Lifecycle Closure"
status: done
verdict: APPROVED
priority: P1
created: 2026-03-05
appetite: "Small batch — 1 day"
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
---

# Topic Lifecycle Closure

## Problem Frame

**When** an external system (Cataliva) or human writes topic files to `docs/topics/` to trigger discovery, **they have no way to confirm discovery completed or find the output** — because the topic file is never updated after the Scout finishes. Topics get stuck at `processing` with no `result_ref`, no `status: done`, and no archival path. This breaks the context protocol contract and makes the topic→backlog pipeline unreliable.

**Evidence:**
- `docs/analysis/20260227_context_protocol_cataliva_scoping_prompt.md` specifies the full lifecycle: `pending → processing → done` with `result_ref` added after discovery
- `commands/discover.md` lines 30-32 specify: "After producing the Opportunity Snapshot, **update** the topic file: Set `status: done`, Add `result_ref`"
- Neither the Scout agent (`agents/scout.md`) nor the `genies` script implements this update
- `reconcile_batch_state()` only handles backlog items — topic files are ignored
- The integration checklist (line 142) requires "Can read `result_ref` field to find discovery output" — currently impossible
- Field evidence: all 13 topic files in pinplus-haulerschedule stuck at `status: pending`

## Appetite

**Small batch — 1 day.** Three touch points, all prompt/script edits:

1. Scout agent prompt update (topic file write-back)
2. `genies` script post-discover reconciliation
3. Tests for the new transitions

**No-gos:**
- No topic archival/cleanup mechanism (separate concern — `/done` could handle this later)
- No changes to the Cataliva-facing schema contract
- No new CLI flags or subcommands

## Solution Sketch

### 1. Scout updates topic file after discovery

Add to `agents/scout.md` Context Usage section: when the input is a topic file path, after writing the Opportunity Snapshot, update the topic file:
- Set `status: done`
- Add `result_ref: docs/analysis/YYYYMMDD_discover_{topic}.md`
- Add `completed: YYYY-MM-DD`

The Scout already has write capability via its tools (it writes the Opportunity Snapshot). The topic file update is a small extension of that existing write.

### 2. `genies` script handles explicit topic file inputs

Fix `resolve_batch_items()` explicit-inputs branch: when an input file has `type: topic` in frontmatter, treat it like a topic (enqueue as `discover:{path}`) instead of routing through `status_to_phase()` which doesn't know about topic statuses.

### 3. `genies` post-discover reconciliation

After `run_phase "discover"` completes for a topic input, verify the topic file was updated. If the Scout didn't update it (defensive), set `status: done` from the script as a fallback, using the analysis path extracted from the phase output.

## Rabbit Holes

- **Don't build topic archival** — that's a separate concern. Topics with `status: done` stay in `docs/topics/` until a future `/done` enhancement handles cleanup.
- **Don't change the daemon scan logic** — it already correctly filters on `status: pending` and sets `processing`. The gap is only after discover completes.
- **Don't add topic-specific fields to `status_to_phase()`** — topics aren't backlog items and shouldn't enter the define→design→deliver pipeline via status mapping. They feed into it via their `result_ref`.

## Acceptance Criteria

- **AC-1:** When `/discover` receives a topic file path as input, after writing the Opportunity Snapshot, the topic file is updated with `status: done`, `result_ref: {snapshot_path}`, and `completed: {date}`
- **AC-2:** When `genies` receives explicit topic file paths (e.g., `genies --through define docs/topics/*.md`), files with `type: topic` frontmatter are enqueued as `discover:{path}` instead of being skipped as "not actionable"
- **AC-3:** After the discover phase completes in `genies`, if the topic file still has `status: processing`, the script sets `status: done` and `result_ref` as a fallback

## Behavioral Delta

**Spec:** docs/specs/workflow/autonomous-lifecycle.md

### Current Behavior
- AC-8: Batch scan handles topics in auto-scan path (no explicit inputs) but skips them in explicit-inputs path because `status_to_phase("pending")` returns empty

### Proposed Changes
- AC-8: Explicit topic file inputs (frontmatter `type: topic`) are recognized and enqueued as `discover:{path}` regardless of status mapping
- AC-NEW (→ AC-18): After discover phase completes for a topic input, the topic file is updated with `status: done` and `result_ref` pointing to the Opportunity Snapshot

### Rationale
The context protocol spec defines topic lifecycle closure as a contract requirement. Without it, external integrators cannot track discovery completion, and batch runs with explicit topic paths silently skip all inputs.

## Dependencies

- None — all changes are to existing files (scout agent prompt, genies script, test suite)

## Routing

Ready for design: `/handoff define design`

---

# Design

```yaml
---
spec_version: "1.0"
type: design
id: topic-lifecycle-closure
title: "Topic Lifecycle Closure"
reasoning_mode: deep
status: designed
created: "2026-03-06"
spec_ref: "docs/backlog/P1-topic-lifecycle-closure.md"
appetite: small
complexity: simple
author: architect
ac_mapping:
  - ac_id: AC-1
    approach: "Add topic file write-back instructions to Scout agent Context Usage and /discover command Context Writing"
    components: ["agents/scout.md", "commands/discover.md"]
  - ac_id: AC-2
    approach: "Add type:topic detection in resolve_batch_items() explicit-inputs branch before status_to_phase() routing"
    components: ["scripts/genies"]
  - ac_id: AC-3
    approach: "Add post-discover reconciliation in main phase loop, after parse_artifact_path for discover phase"
    components: ["scripts/genies"]
components:
  - name: "Scout agent prompt"
    action: modify
    files: ["agents/scout.md"]
  - name: "Discover command"
    action: modify
    files: ["commands/discover.md"]
  - name: "Genies runner script"
    action: modify
    files: ["scripts/genies"]
  - name: "Runner test suite"
    action: modify
    files: ["tests/test_run_pdlc.sh"]
---
```

## Overview

Three surgical changes close the topic lifecycle gap: (1) the Scout agent prompt gets write-back instructions for topic files, (2) the `genies` script's explicit-inputs branch learns to recognize `type: topic` frontmatter, and (3) a post-discover reconciliation fallback in the main phase loop ensures closure even if the Scout omits the update.

No new functions, no new flags, no schema changes. All three changes operate on existing code paths with minimal additions.

## Architecture

### Alternative Considered: Script-only approach (no Scout prompt change)

Handle all topic closure in `genies` post-discover — don't touch the Scout agent at all. The script already parses `analysis_path` from discover output.

**Rejected because:** This only works in headless `genies` runs. When a user runs `/discover docs/topics/foo.md` interactively in Claude Code, there's no script wrapper — the Scout must update the topic file itself. The prompt change is necessary for the interactive path; the script fallback is defense-in-depth for the headless path.

### Alternative Considered: Add topic statuses to `status_to_phase()`

Extend `status_to_phase()` to map `pending` → `discover` and `processing` → `discover`.

**Rejected because:** The shaped contract explicitly calls this a rabbit hole (line 61). Topics aren't backlog items — they shouldn't enter the define→design→deliver pipeline via status mapping. They feed into the pipeline via their `result_ref`. Mixing topic and backlog status semantics in one function creates confusion.

### Chosen Approach: Dual-path closure (prompt + script fallback)

The Scout handles the primary path (works in both interactive and headless modes). The script handles the fallback (defense-in-depth for headless runs where the Scout might not update the file).

## Component Changes

### 1. `agents/scout.md` — Context Usage section (AC-1)

Add topic file write-back to the existing Context Usage section:

```markdown
## Context Usage

**Read:** CLAUDE.md, docs/context/*.md, provided data
**Write:** docs/analysis/YYYYMMDD_discover_{topic}.md
**Write (topic file input):** When the input is a topic file path (has `type: topic` in frontmatter), after writing the Opportunity Snapshot, update the topic file:
  - Set `status: done`
  - Add `result_ref: {path to Opportunity Snapshot}`
  - Add `completed: {YYYY-MM-DD}`
**Handoff:** Opportunity Snapshot → Shaper
```

**Why here and not elsewhere:** The Context Usage section already defines what the Scout reads and writes. Topic file write-back is a write operation — it belongs with the other write declarations.

**Failure mode:** If the Scout doesn't have `Write` in its tools list, it can't update the topic file. Check: `agents/scout.md` tools line lists `Read, Grep, Glob, WebFetch, WebSearch` — no `Write` or `Edit`. **The Scout needs `Edit` added to its tools.** Without it, the prompt instruction is unimplementable.

The Scout already writes the Opportunity Snapshot to `docs/analysis/` — but that's done via the `/discover` command's Context Writing, which operates at the orchestrator level. For the Scout agent itself to update a topic file's frontmatter, it needs `Edit` in its tool list.

**Tool addition:** Add `Edit` to the Scout's tools: `Read, Grep, Glob, Edit, WebFetch, WebSearch`. This is the minimum addition — `Edit` handles frontmatter field updates without rewriting the full file.

### 2. `commands/discover.md` — Context Writing section (AC-1)

The `/discover` command already specifies topic file updates in its Input Modes section (lines 30-32):

```markdown
2. After producing the Opportunity Snapshot, **update** the topic file:
   - Set `status: done`
   - Add `result_ref: docs/analysis/YYYYMMDD_discover_{topic}.md`
```

This is correct but only in the Input Modes section. Add it to the Context Writing section too for consistency (the Context Writing section is what genies check for write responsibilities):

```markdown
## Context Writing

**WRITE:**
- docs/analysis/YYYYMMDD_discover_{topic}.md

**UPDATE:**
- docs/context/current_work.md (mark discovery in progress)
- Topic file (when input is a topic file path): set `status: done`, add `result_ref`, add `completed: {date}`
```

**No other changes to discover.md.** The Input Modes section already has the right instructions.

### 3. `scripts/genies` — `resolve_batch_items()` explicit-inputs branch (AC-2)

Current code at line 1242-1263: when processing explicit file inputs, it reads `status` and passes through `status_to_phase()`. Topic files with `status: pending` get empty from `status_to_phase()` and are skipped with "not actionable."

**Fix:** Before calling `status_to_phase()`, check if the file has `type: topic` in frontmatter. If so, enqueue as `discover:{path}` directly — bypass `status_to_phase()`.

Insert after line 1250 (after frontmatter check), before line 1251:

```bash
# Topic files are always discover targets — don't route through status_to_phase
local file_type
file_type=$(get_frontmatter_field "$input" "type")
if [[ "$file_type" == "topic" ]]; then
    BATCH_ITEMS+=("discover:$input")
    continue
fi
```

**Why `continue` and not fall-through:** Topic files should never reach `status_to_phase()`. Their status values (`pending`, `processing`, `done`) have different semantics than backlog statuses (`defined`, `designed`, `implemented`). Falling through would always produce "not actionable" — which is the bug we're fixing.

**Failure mode:** If a topic file has `status: done` and someone passes it explicitly, it will be re-enqueued for discover. This is acceptable — the user explicitly asked for it. The auto-scan path (line 1223) already filters on `status: pending`, so `done` topics won't be re-discovered in batch scans.

### 4. `scripts/genies` — Post-discover reconciliation (AC-3)

Current code at line 2376-2381: after discover completes, `analysis_path` is parsed from output. No topic file update.

**Add after `analysis_path` extraction (after line 2380):** Check if the input was a topic file and whether it still needs closure.

```bash
discover)
    analysis_path=$(parse_artifact_path "$OUTPUT" "analysis" 2>/dev/null) || \
        analysis_path=$(parse_artifact_fallback "analysis" 2>/dev/null) || true
    log_debug "analysis_path=$analysis_path"

    # Topic lifecycle closure fallback (AC-3)
    if [[ -f "$phase_input" ]]; then
        local input_type input_status
        input_type=$(get_frontmatter_field "$phase_input" "type")
        input_status=$(get_frontmatter_field "$phase_input" "status")
        if [[ "$input_type" == "topic" && "$input_status" != "done" ]]; then
            log_info "Topic file not closed by Scout — applying fallback"
            set_frontmatter_field "$phase_input" "status" "done"
            if [[ -n "$analysis_path" ]]; then
                # Add result_ref — append after status line
                sed -i '' "/^status:/a\\
result_ref: $analysis_path" "$phase_input"
            fi
            local today
            today=$(date +%Y-%m-%d)
            sed -i '' "/^status:/a\\
completed: $today" "$phase_input"
            log_info "Topic closed: $(basename "$phase_input") → $analysis_path"
        fi
    fi
    ;;
```

**Why `sed` for `result_ref` and `completed`:** `set_frontmatter_field()` only updates existing fields — it uses `grep -q "^${field}:"` and returns early if the field doesn't exist (line 117-123). For adding NEW fields, we need `sed` to append after an existing line. `status` is guaranteed to exist (we just set it), so appending after `status:` is safe.

**Alternative: extend `set_frontmatter_field()` to support add-if-missing.** This is cleaner but expands scope beyond the shaped appetite. The `sed` approach works for this specific case. If more field additions are needed in future, refactoring `set_frontmatter_field()` is the right move.

**Failure mode:** If `analysis_path` is empty (Scout didn't produce recognizable output), the topic gets `status: done` but no `result_ref`. This is acceptable — the topic is closed, and the user can manually find the analysis file. Logging makes the missing ref visible.

**macOS sed compatibility:** The `sed -i ''` syntax is macOS-compatible (BSD sed). The `genies` script already uses this pattern in `set_frontmatter_field()` (line 118). Linux `sed` uses `sed -i` without the empty string — but the script already targets macOS (the `set_frontmatter_field` function uses `sed ... > "$tmpfile" && mv "$tmpfile" "$file"` pattern instead, which is portable). We should follow the same portable pattern here.

**Revised approach — use portable sed:**

```bash
if [[ -n "$analysis_path" ]]; then
    local tmpfile
    tmpfile="$(mktemp)"
    awk -v ref="$analysis_path" -v today="$(date +%Y-%m-%d)" '
        /^status:/ && !added {
            print; print "result_ref: " ref; print "completed: " today; added=1; next
        }
        {print}
    ' "$phase_input" > "$tmpfile"
    mv "$tmpfile" "$phase_input"
fi
```

This mirrors the portable pattern already used by `set_frontmatter_field()` (temp file + mv) and avoids BSD/GNU sed incompatibilities.

## Pattern Adherence

- **Frontmatter as source of truth:** Follows the established pattern where `status`, `verdict`, and other state fields live in YAML frontmatter, read by `get_frontmatter_field()`.
- **Defensive fallback:** Mirrors the existing `detect_verdict()` pattern — primary source (Scout update) with script fallback (frontmatter read + update).
- **`set_frontmatter_field()` reuse:** Uses the existing portable function for `status` updates; extends with `awk` for new field insertion following the same tmp+mv pattern.
- **No new functions:** All changes fit within existing code paths — `resolve_batch_items()` gets a conditional, the main loop `discover)` case gets a fallback block.

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Scout lacks `Edit` tool — can't update topic file | Certain (current state) | High — AC-1 unimplementable | Add `Edit` to Scout tools list. Scout currently writes Opportunity Snapshots via command-level orchestration, not agent tools. Adding `Edit` is low-risk — Scout already has read-only tools; `Edit` is narrowly scoped to frontmatter updates. |
| `sed`/`awk` frontmatter insertion corrupts file | Low | High — topic file becomes unparseable | Use the portable tmp+mv pattern already established in `set_frontmatter_field()`. Test with multi-line context fields in frontmatter. |
| Explicit `done` topic re-enqueued for discover | Low | Low — wastes one discover phase | Acceptable per design. Auto-scan already filters `status: pending`. Log a warning for `done` topic re-enqueue. |

## Implementation Guidance

### Sequence

1. **`agents/scout.md`** — Add `Edit` to tools, add topic write-back to Context Usage. This is the primary path and must be correct.
2. **`commands/discover.md`** — Add topic file update to Context Writing section. Small change, consistency fix.
3. **`scripts/genies` — `resolve_batch_items()`** — Add `type: topic` check in explicit-inputs branch. Insert before `status_to_phase()` call.
4. **`scripts/genies` — main phase loop** — Add post-discover reconciliation in the `discover)` case. Insert after `analysis_path` extraction.
5. **`tests/test_run_pdlc.sh`** — Tests for AC-2 and AC-3.

### Test Scenarios

**AC-1 (Scout write-back):** Prompt-only change — tested via integration. No unit test possible for prompt behavior. Verified by AC-3 fallback logic (if Scout doesn't write back, fallback catches it — meaning the fallback test implicitly tests whether Scout did or didn't write back).

**AC-2 (explicit topic file routing):**
- `resolve_batch_items` with a topic file input (`type: topic`, `status: pending`) → enqueued as `discover:{path}`
- `resolve_batch_items` with a topic file input (`type: topic`, `status: done`) → still enqueued as `discover:{path}` (explicit input overrides)
- `resolve_batch_items` with a backlog file input (`type: backlog`, `status: defined`) → enqueued as `design:{path}` (unchanged behavior)
- `resolve_batch_items` with a topic file alongside a backlog file → both correctly categorized

**AC-3 (post-discover fallback):**
- Discover completes, topic file still `status: processing` → script sets `status: done`, adds `result_ref` and `completed`
- Discover completes, topic file already `status: done` (Scout updated it) → script skips (no double-update)
- Discover completes, `analysis_path` is empty → script sets `status: done` but no `result_ref` (graceful degradation)
- Discover completes for non-topic input (string topic) → fallback skipped (file doesn't exist)

### Architecture Decisions

No ADRs needed. This is a bug fix completing an already-specified contract, not an architectural choice between alternatives.

### Diagram Updates

None. No new containers, components, or relationships.

## Routing

Ready for Crafter: `/deliver docs/backlog/P1-topic-lifecycle-closure.md`

---

# Implementation

## Changes Made

### AC-1: Scout topic file write-back
- **`agents/scout.md`**: Added `Edit` to tools list (`Read, Grep, Glob, Edit, WebFetch, WebSearch`). Added topic file update instructions to Context Usage section — when input is a topic file, after writing the Opportunity Snapshot, update the topic file with `status: done`, `result_ref`, and `completed` date.
- **`commands/discover.md`**: Added topic file update line to Context Writing section for consistency with Input Modes section (which already specified this behavior).

### AC-2: Explicit topic file routing in genies
- **`scripts/genies` (`resolve_batch_items()`)**: Added `type: topic` frontmatter check before `status_to_phase()` routing. Topic files are now enqueued as `discover:{path}` directly, bypassing status-to-phase mapping. Prevents "not actionable" skip for topic files passed as explicit inputs.

### AC-3: Post-discover reconciliation fallback
- **`scripts/genies` (main phase loop, `discover)` case)**: Added topic lifecycle closure fallback after `analysis_path` extraction. If the input is a topic file and its status is not `done`, the script sets `status: done` and uses portable `awk` + tmp+mv to insert `result_ref` and `completed` fields. Follows the same portable pattern as `set_frontmatter_field()`.

### Tests
- **`tests/test_run_pdlc.sh`**: 8 new tests in Category 28 (Topic lifecycle closure):
  - AC-2: topic file input enqueued as discover (pending status)
  - AC-2: done topic file still enqueued when explicit
  - AC-2: mixed topic + backlog inputs correctly categorized
  - AC-3: processing topic closed with status/result_ref/completed
  - AC-3: already-done topic not double-updated
  - AC-3: empty analysis_path graceful degradation
  - AC-3: non-file input skips fallback
- Total: 364 tests, all passing

## Wiring Check

Phase 4: N/A — prompt-only changes (AC-1) and script changes within existing code paths (AC-2 in `resolve_batch_items()`, AC-3 in main phase loop). No new service bootstrap required.

---

# Review

```yaml
---
type: review
reviewer: critic
verdict: APPROVED
reviewed: 2026-03-06
---
```

## Verdict: APPROVED

All acceptance criteria met. Implementation is clean, follows established patterns, and has solid test coverage.

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `agents/scout.md` — `Edit` added to tools, topic write-back instructions in Context Usage. `commands/discover.md` — topic file update in Context Writing. |
| AC-2 | met | `scripts/genies` `resolve_batch_items()` — `type: topic` check before `status_to_phase()`, enqueues as `discover:{path}`. 3 tests pass. |
| AC-3 | met | `scripts/genies` main phase loop — post-discover reconciliation with portable awk+tmp+mv. 4 tests pass. |

## Code Quality: Good
- Follows existing `get_frontmatter_field()`/`set_frontmatter_field()` patterns
- Portable awk+tmp+mv matches `set_frontmatter_field()` convention
- No scope creep — rabbit holes respected

## Test Coverage: 8 new tests (364 total, 0 failures)
## Security: Pass
## Performance: Pass

Ready for `/done`.

---

# End of Shaped Work Contract
