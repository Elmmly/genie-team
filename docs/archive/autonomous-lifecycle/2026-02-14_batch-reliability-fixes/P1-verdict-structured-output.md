---
spec_version: "1.0"
type: shaped-work
id: verdict-structured-output
title: "Reliable Verdict Extraction via Frontmatter"
status: done
verdict: APPROVED
created: "2026-02-14"
appetite: small
priority: P1
target_project: genie-team
author: shaper
spec_ref: docs/specs/workflow/autonomous-lifecycle.md
depends_on: []
tags: [workflow, autonomous, verdict, discern, reliability, parsing]
acceptance_criteria:
  - id: AC-1
    description: >-
      /discern writes a verdict: field to the backlog item frontmatter
      (APPROVED, BLOCKED, or CHANGES_REQUESTED)
    status: pending
  - id: AC-2
    description: >-
      detect_verdict() reads verdict from backlog item frontmatter as primary
      source
    status: pending
  - id: AC-3
    description: >-
      Falls back to regex parsing of Claude output if frontmatter field is
      absent (backwards compatibility)
    status: pending
  - id: AC-4
    description: >-
      Existing detect_verdict unit tests still pass (backwards compat)
    status: pending
---

# Shaped Work Contract: Reliable Verdict Extraction via Frontmatter

## Problem

The `detect_verdict()` function in `run-pdlc.sh` greps free-text Claude output for `APPROVED|BLOCKED|CHANGES REQUESTED`. This is fragile — the critic writes a structured review document with "Verdict: APPROVED" embedded in markdown, but the orchestrator parses the raw `claude -p` stdout which includes preamble, thinking tokens, and formatting. The regex `grep -oE 'APPROVED|BLOCKED|CHANGES REQUESTED'` can miss the verdict if it's buried in context, or match a false positive if "APPROVED" appears in discussion text.

**Evidence:** 2hearted batch run (Feb 13-14, 2026) — P0-social-authentication completed all work ($15 in API costs) but the verdict couldn't be parsed from the critic's output. The pipeline stopped with `[ERROR] Could not parse verdict from /discern output`. The critic had written "APPROVED" in the review document but the orchestrator couldn't extract it from the raw output stream.

**Root cause:** The contract between `/discern` (critic) and `run-pdlc.sh` (orchestrator) is implicit — the critic writes natural language and the orchestrator hopes to find a keyword. There's no machine-readable interface between the two.

## Appetite & Boundaries

- **Appetite:** Small (1 day) — one command prompt update, one script function update
- **No-gos:**
  - Do NOT change the review document format (the human-readable verdict stays)
  - Do NOT remove the regex fallback (backwards compat with runs that used older `/discern`)
  - Do NOT add a separate verdict file (use existing frontmatter)
- **Fixed elements:**
  - The frontmatter field must use the exact values: `APPROVED`, `BLOCKED`, `CHANGES_REQUESTED`
  - The backlog item is already being modified by `/discern` (review section appended)
  - The frontmatter approach makes the verdict auditable in the document trail

## Goals & Outcomes

Verdict extraction becomes reliable by reading a structured field instead of parsing free text. The verdict persists in the backlog item frontmatter, making it auditable and queryable (e.g., `grep "verdict:" docs/backlog/*.md`).

## Risks & Assumptions

| Assumption | Type | Fastest Test |
|---|---|---|
| `/discern` can write frontmatter fields (not just append markdown) | feasibility | Test Edit tool on YAML frontmatter in a backlog item |
| Claude reliably follows "update frontmatter" instructions in prompts | feasibility | Run `/discern` on a test item with the updated prompt |
| Frontmatter field survives multiple `/discern` runs (re-review) | feasibility | Run `/discern` twice on same item, check field is updated not duplicated |
| `get_frontmatter_field` already exists in run-pdlc.sh | feasibility | Check existing helper functions |

## Solution Sketch

Two changes:

1. **`commands/discern.md`** — Add instruction: after writing the review verdict, update the backlog item's YAML frontmatter to include `verdict: APPROVED|BLOCKED|CHANGES_REQUESTED`. This makes the verdict machine-readable.

2. **`scripts/run-pdlc.sh` `detect_verdict()`** — Change primary detection to read the backlog item's frontmatter `verdict` field using the existing `get_frontmatter_field` helper. Fall back to regex parsing of Claude output only if the frontmatter field is absent.

The detection priority becomes:
1. Read `verdict:` from backlog item frontmatter (reliable, structured)
2. Fall back to `grep -oE 'APPROVED|BLOCKED|CHANGES REQUESTED'` on output (legacy)
3. Return error if neither source has a verdict (safe default — stop pipeline)

## Options

| Option | Pros | Cons | Recommendation |
|---|---|---|---|
| Frontmatter field (proposed) | Auditable, structured, uses existing infrastructure | Requires prompt change to `/discern` | **Recommended** |
| Structured JSON output from critic | Machine-parseable | Requires `--output-format` changes, complex | Over-engineered |
| Sentinel line format (e.g., `##VERDICT:APPROVED##`) | Easy to grep | Ugly in human-readable output, fragile | Not recommended |

## Routing

- [x] **Crafter** — Small appetite, prompt update + script function change
- [ ] **Architect** — Not needed (no design unknowns)

---

# Design

## Overview

Two-sided change: the critic writes a machine-readable `verdict:` field to the backlog item frontmatter, and the orchestrator reads it as the primary verdict source. The existing regex fallback is preserved for backwards compatibility with items reviewed before this change.

## Architecture

**Pattern: Structured contract between producer and consumer.**

The current implicit contract (critic writes free text, orchestrator greps for keywords) is replaced with a structured contract:
- **Producer** (`/discern` via `commands/discern.md`): writes `verdict: APPROVED|BLOCKED|CHANGES_REQUESTED` to backlog frontmatter
- **Consumer** (`detect_verdict()` in `run-pdlc.sh`): reads `verdict` from frontmatter using existing `get_frontmatter_field` helper
- **Fallback**: regex parsing of Claude output (preserved for backwards compat)

The frontmatter field is the single source of truth. It's auditable (in the document trail), queryable (`grep "verdict:" docs/backlog/*.md`), and survives re-reviews (the field is overwritten, not appended).

## Component Design

### 1. `commands/discern.md` — Verdict frontmatter instruction

**Location:** The "Context Writing" section (line ~54-61).

**Modify the UPDATE list.** After the existing bullet:
```markdown
- Backlog frontmatter: `status: implemented` → `status: reviewed`
```

**Add:**
```markdown
- Backlog frontmatter: add `verdict: APPROVED|BLOCKED|CHANGES_REQUESTED` field (machine-readable verdict for the autonomous runner)
```

This is a single-line addition to the prompt. The critic already modifies frontmatter (`status: implemented` → `status: reviewed`), so adding one more field is natural — no new capability needed.

**Frontmatter value convention:**
- `APPROVED` — ready for deployment
- `BLOCKED` — critical issues, cannot proceed
- `CHANGES_REQUESTED` — issues found, fixable (underscore, not space, for YAML safety)

### 2. `scripts/run-pdlc.sh` — Updated `detect_verdict()`

**Replace the current function (lines 320-336):**

```bash
# Detect verdict from /discern output
# Usage: detect_verdict <output> [item_path]
# Primary: reads verdict from backlog item frontmatter (structured, reliable)
# Fallback: greps output text for verdict keywords (legacy compat)
# Returns: APPROVED, BLOCKED, or CHANGES REQUESTED on stdout; exit 1 if not found
detect_verdict() {
    local output="$1"
    local item_path="${2:-}"

    # Primary: frontmatter verdict field
    if [[ -n "$item_path" && -f "$item_path" ]]; then
        local fm_verdict
        fm_verdict=$(get_frontmatter_field "$item_path" "verdict")
        if [[ -n "$fm_verdict" ]]; then
            # Normalize CHANGES_REQUESTED → CHANGES REQUESTED for display consistency
            echo "${fm_verdict//_/ }"
            return 0
        fi
    fi

    # Fallback: regex parse from Claude output (backwards compat)
    local verdict
    verdict=$(echo "$output" | grep -oE 'APPROVED|BLOCKED|CHANGES REQUESTED' | head -1)
    if [[ -n "$verdict" ]]; then
        echo "$verdict"
        return 0
    fi

    log_error "Could not parse verdict from /discern output"
    return 1
}
```

**Key changes from current:**
- New optional second parameter `item_path`
- Frontmatter read via existing `get_frontmatter_field` (no new helpers needed)
- `CHANGES_REQUESTED` normalized to `CHANGES REQUESTED` for display consistency (the rest of the code already uses the space-separated form)
- Original regex fallback preserved verbatim

### 3. `scripts/run-pdlc.sh` — Updated call site

**Location:** The discern case in the phase loop (line ~1249).

**Current:**
```bash
verdict=$(detect_verdict "$OUTPUT" 2>/dev/null) || true
```

**New:**
```bash
verdict=$(detect_verdict "$OUTPUT" "${item_path:-}" 2>/dev/null) || true
```

Single change: pass `item_path` as the second argument. The `${item_path:-}` defaults to empty string when not set (e.g., if somehow discern runs without a backlog item — though that shouldn't happen in practice).

## AC Mapping

| AC | Approach | Files |
|----|----------|-------|
| AC-1 | Add `verdict:` to the frontmatter update list in `/discern`'s Context Writing section. The critic already updates frontmatter fields during review — this adds one more. | `commands/discern.md` |
| AC-2 | `detect_verdict()` reads frontmatter first via `get_frontmatter_field`. Primary source before regex fallback. | `scripts/run-pdlc.sh` |
| AC-3 | Original `grep -oE 'APPROVED\|BLOCKED\|CHANGES REQUESTED'` preserved verbatim as fallback when frontmatter field is absent (empty `fm_verdict` → skip to regex). | `scripts/run-pdlc.sh` |
| AC-4 | Existing tests call `detect_verdict "$output"` with one argument. The new function signature is `detect_verdict <output> [item_path]` — the second arg is optional with default `""`. When empty, frontmatter path is skipped and the function falls through to the original regex logic. All existing test calls work unchanged. | `scripts/run-pdlc.sh`, `tests/test_run_pdlc.sh` |

## Implementation Guidance

**Sequence:**
1. Update `detect_verdict()` in `run-pdlc.sh` (add `item_path` parameter, frontmatter read, preserve fallback)
2. Update call site at line ~1249 to pass `item_path`
3. Add new tests for frontmatter-based verdict detection
4. Verify existing `detect_verdict` tests still pass (backwards compat)
5. Update `commands/discern.md` with the frontmatter instruction

**Test strategy:**
- New test: create temp file with `verdict: APPROVED` in frontmatter, call `detect_verdict "" "$temp_file"`, assert output is `APPROVED`
- New test: create temp file with `verdict: CHANGES_REQUESTED`, assert output is `CHANGES REQUESTED` (normalization)
- New test: create temp file with `verdict: BLOCKED`, assert output is `BLOCKED`
- New test: create temp file WITHOUT verdict field, pass output containing `APPROVED`, assert fallback works
- New test: create temp file WITHOUT verdict field, pass output WITHOUT verdict keyword, assert exit code 1
- Existing tests: call `detect_verdict "$output"` with one arg — must still pass (backwards compat)

## Risks

| Risk | L | I | Mitigation |
|------|---|---|------------|
| Claude doesn't reliably write the frontmatter field | Med | Med | The critic already writes `status:` changes to frontmatter. Adding `verdict:` is the same operation. Fallback regex covers any misses. |
| Re-review overwrites verdict from previous review | Low | Low | Desired behavior — the most recent review's verdict is the one that matters |
| `get_frontmatter_field` can't parse multi-word values (CHANGES REQUESTED) | Low | Med | Using `CHANGES_REQUESTED` (underscore) in frontmatter avoids YAML quoting issues. Normalizing on read. |

## Routing

Ready for Crafter. No architectural unknowns — one prompt edit, one function update, backwards-compatible call site change.

# Review

<!-- Appended by /discern on 2026-02-14 -->

**Verdict:** APPROVED

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | designed | Design adds `verdict:` to `/discern`'s Context Writing UPDATE list. Critic already modifies frontmatter (`status: implemented` → `status: reviewed`), so adding one more field is natural. |
| AC-2 | designed | `detect_verdict()` reads frontmatter first via `get_frontmatter_field`. Primary source before regex fallback. |
| AC-3 | designed | Original `grep -oE` preserved verbatim as fallback when `fm_verdict` is empty. |
| AC-4 | designed | New function signature `detect_verdict <output> [item_path]` — second arg optional with default `""`. Existing single-arg test calls skip frontmatter path entirely, falling through to regex. |

## Code Quality

- `CHANGES_REQUESTED` (underscore) in frontmatter avoids YAML quoting issues; normalized to space-separated on read
- Single call site change: add `"${item_path:-}"` as second argument
- One-line prompt addition to `commands/discern.md` — minimal change surface

## Notes

No blocking issues. Elegant two-sided change — producer writes structured field, consumer reads it, fallback preserves backwards compat.

# Implementation

<!-- Appended by /deliver on 2026-02-14 -->

## Changes

| File | Change |
|------|--------|
| `scripts/run-pdlc.sh` | Updated `detect_verdict()` with optional `item_path` parameter; reads frontmatter `verdict` field via `get_frontmatter_field` as primary source, falls back to regex |
| `scripts/run-pdlc.sh` | Updated call site at discern phase to pass `"${item_path:-}"` as second argument |
| `commands/discern.md` | Added `verdict: APPROVED\|BLOCKED\|CHANGES_REQUESTED` to Context Writing UPDATE list |
| `tests/test_run_pdlc.sh` | 9 new tests: frontmatter APPROVED/BLOCKED/CHANGES_REQUESTED, normalization, fallback to regex, exit code 1 on no verdict |

## Test Results

- 148 tests total in `tests/test_run_pdlc.sh`, all passing
- Existing `detect_verdict` tests (4 tests) pass unchanged (backwards compat)
- New frontmatter tests (9 tests) cover all ACs

# Review (Implementation)

<!-- Appended by /discern on 2026-02-14 -->

**Verdict:** APPROVED

## Acceptance Criteria

| AC | Status | Evidence |
|----|--------|----------|
| AC-1 | met | `commands/discern.md` line 59: verdict field added to Context Writing UPDATE list |
| AC-2 | met | `detect_verdict()` reads `get_frontmatter_field "$item_path" "verdict"` as primary source (lines 335-343) |
| AC-3 | met | Original `grep -oE` preserved verbatim as fallback (lines 346-353) |
| AC-4 | met | Existing 4 single-arg tests pass unchanged; new function signature `detect_verdict <output> [item_path]` is backwards compatible |

## Code Quality

- Clean two-sided contract: producer writes `verdict:` to frontmatter, consumer reads it
- `CHANGES_REQUESTED` normalization handles YAML-safe underscore convention
- No new dependencies — reuses existing `get_frontmatter_field` helper
- 9 new tests with AAA pattern, comprehensive coverage
