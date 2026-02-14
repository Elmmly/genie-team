#!/bin/bash
# Headless PDLC runner — chains claude -p per phase for autonomous lifecycle execution
# Usage: run-pdlc.sh [OPTIONS] <topic|backlog-item-path>
#
# Exit codes:
#   0  Completed through --through phase
#   1  Phase failure, BLOCKED verdict, or turn exhaustion (after retry)
#   2  Merge conflict during PR creation
#   3  Input validation error (bad args, missing file, lock held)

# Only set strict mode when running directly (not sourced for testing)
if [[ "${RUN_PDLC_SOURCED:-false}" != "true" ]]; then
    set -euo pipefail
fi

# ─────────────────────────────────────────────
# Constants
# ─────────────────────────────────────────────

PHASES=(discover define design deliver discern commit "done")
DEFAULT_TURNS=(50 50 50 100 50 10 20)

# Per-phase allowed tools (from CLI contract)
PHASE_TOOLS=(
    "Read,Grep,Glob,WebSearch,WebFetch,Task"         # discover
    "Read,Grep,Glob,Write,Task"                       # define
    "Read,Grep,Glob,Write,Edit,Task"                  # design
    "Read,Grep,Glob,Write,Edit,Bash,Task"             # deliver
    "Read,Grep,Glob,Bash,Task"                        # discern
    "Bash"                                            # commit
    "Read,Grep,Glob,Write,Edit,Bash"                  # done
)

# ─────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────

log_info()  { echo "[INFO]  $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_debug() { [[ "${VERBOSE:-false}" == "true" ]] && echo "[DEBUG] $*" >&2 || true; }

# ─────────────────────────────────────────────
# Frontmatter Parsing (self-contained, per design decision)
# ─────────────────────────────────────────────

extract_frontmatter() {
    local file="$1"

    if [[ ! -f "$file" ]]; then
        log_error "File not found: $file"
        return 1
    fi

    local in_frontmatter=false
    local found_start=false
    local result=""

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" ]]; then
            if [[ "$found_start" == "false" ]]; then
                found_start=true
                in_frontmatter=true
                continue
            else
                echo "$result"
                return 0
            fi
        fi

        if [[ "$in_frontmatter" == "true" ]]; then
            if [[ -n "$result" ]]; then
                result="$result"$'\n'"$line"
            else
                result="$line"
            fi
        fi
    done < "$file"

    echo ""
}

get_field() {
    local frontmatter="$1"
    local field="$2"

    local value
    value=$(echo "$frontmatter" | grep -E "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//" | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//" | xargs)
    echo "$value"
}

# Convenience: extract a field directly from a file's frontmatter
get_frontmatter_field() {
    local file="$1"
    local field="$2"
    local fm
    fm=$(extract_frontmatter "$file")
    get_field "$fm" "$field"
}

# Map backlog item status to the next phase to run
# Returns empty string for non-actionable statuses (done, abandoned)
status_to_phase() {
    local status="$1"
    case "$status" in
        defined|shaped) echo "design" ;;
        designed)       echo "deliver" ;;
        implemented)    echo "discern" ;;
        reviewed)       echo "done" ;;
        *)              echo "" ;;
    esac
}

# ─────────────────────────────────────────────
# Core Functions
# ─────────────────────────────────────────────

# Get the index of a phase name (0-6)
# Usage: phase_index <name>
# Returns: index on stdout, exit 1 if invalid
phase_index() {
    local name="$1"
    local i
    for i in "${!PHASES[@]}"; do
        if [[ "${PHASES[$i]}" == "$name" ]]; then
            echo "$i"
            return 0
        fi
    done
    log_error "Invalid phase: $name"
    return 1
}

# Parse command-line arguments into global variables
# Usage: parse_args "$@"
# shellcheck disable=SC2034
parse_args() {
    # Reset defaults
    FROM_PHASE="discover"
    THROUGH_PHASE="done"
    INPUT=""
    USE_WORKTREE="false"
    NO_RESUME="false"
    USE_LOCK="false"
    LOG_DIR=""
    TURNS_PER_PHASE=""
    CLEANUP_ON_FAILURE="false"
    TRUNK_MODE="false"
    FINISH_MODE="--merge"
    WORKTREE_SLUG=""
    VERBOSE_LOGGING="false"
    SKIP_PERMISSIONS="false"

    # Batch mode
    PARALLEL_JOBS=0
    PRIORITIES=()
    DRY_RUN="false"
    CONTINUE_ON_FAILURE="false"
    TOPICS_FILE=""
    INPUTS=()

    # Per-phase turn overrides
    DISCOVER_TURNS=""
    DEFINE_TURNS=""
    DESIGN_TURNS=""
    DELIVER_TURNS=""
    DISCERN_TURNS=""
    COMMIT_TURNS=""
    DONE_TURNS=""

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --from)              FROM_PHASE="$2"; shift 2 ;;
            --through)           THROUGH_PHASE="$2"; shift 2 ;;
            --worktree)          USE_WORKTREE="true"; shift ;;
            --no-resume)         NO_RESUME="true"; shift ;;
            --lock)              USE_LOCK="true"; shift ;;
            --log-dir)           LOG_DIR="$2"; shift 2 ;;
            --turns-per-phase)   TURNS_PER_PHASE="$2"; shift 2 ;;
            --cleanup-on-failure) CLEANUP_ON_FAILURE="true"; shift ;;
            --trunk)             TRUNK_MODE="true"; shift ;;
            --finish-mode)       FINISH_MODE="$2"; shift 2 ;;
            --slug)              WORKTREE_SLUG="$2"; shift 2 ;;
            --verbose)           VERBOSE_LOGGING="true"; shift ;;
            --skip-permissions)  SKIP_PERMISSIONS="true"; shift ;;
            --parallel)          PARALLEL_JOBS="$2"; shift 2 ;;
            --priority)          PRIORITIES+=("$2"); shift 2 ;;
            --dry-run)           DRY_RUN="true"; shift ;;
            --continue-on-failure) CONTINUE_ON_FAILURE="true"; shift ;;
            --topics-file)       TOPICS_FILE="$2"; shift 2 ;;
            --discover-turns)    DISCOVER_TURNS="$2"; shift 2 ;;
            --define-turns)      DEFINE_TURNS="$2"; shift 2 ;;
            --design-turns)      DESIGN_TURNS="$2"; shift 2 ;;
            --deliver-turns)     DELIVER_TURNS="$2"; shift 2 ;;
            --discern-turns)     DISCERN_TURNS="$2"; shift 2 ;;
            --commit-turns)      COMMIT_TURNS="$2"; shift 2 ;;
            --done-turns)        DONE_TURNS="$2"; shift 2 ;;
            -h|--help)
                echo "Usage: run-pdlc.sh [OPTIONS] [<topic|backlog-item-path>...]"
                echo ""
                echo "Single item (one input, no --parallel):"
                echo "  run-pdlc.sh [OPTIONS] <topic|backlog-item-path>"
                echo ""
                echo "Batch mode (triggers: --parallel, multiple inputs, or no inputs):"
                echo "  run-pdlc.sh --parallel 3 --trunk      # scan backlog, 3 workers"
                echo "  run-pdlc.sh --dry-run                  # preview actionable items"
                echo "  run-pdlc.sh item1.md item2.md          # specific items"
                echo ""
                echo "Phase range:"
                echo "  --from <phase>          Start phase (default: discover)"
                echo "  --through <phase>       End phase (default: done)"
                echo ""
                echo "Batch:"
                echo "  --parallel <N>          Run N items concurrently in worktrees"
                echo "  --priority <P1|P2|P3>   Filter by priority (repeatable)"
                echo "  --dry-run               Preview matching items without executing"
                echo "  --continue-on-failure   Don't stop on first failure"
                echo "  --topics-file <file>    Load discovery topics from file"
                echo ""
                echo "Execution:"
                echo "  --worktree              Run in isolated worktree"
                echo "  --no-resume             Fresh session per phase (default: chained)"
                echo "  --turns-per-phase <N>   Override default --max-turns for all phases"
                echo "  --{phase}-turns <N>     Override --max-turns for a specific phase"
                echo ""
                echo "Cron:"
                echo "  --log-dir <dir>         Log directory (enables structured JSON logging)"
                echo "  --lock                  Enable lockfile"
                echo ""
                echo "Logging:"
                echo "  --verbose               Write full claude session trace to log dir"
                echo "  --skip-permissions      Pass --dangerously-skip-permissions to claude"
                echo ""
                echo "Git:"
                echo "  --trunk                 Use trunk-based mode (commit to main, no PRs)"
                echo "  --finish-mode <mode>    Worktree finish mode (--merge|--pr|--leave-branch)"
                echo ""
                echo "Worktree:"
                echo "  --cleanup-on-failure    Remove worktree on failure (default: preserve)"
                exit 0
                ;;
            *)
                # Positional argument — append to INPUTS array
                INPUTS+=("$1")
                if [[ -z "$INPUT" ]]; then
                    INPUT="$1"
                fi
                shift
                ;;
        esac
    done
}

# Validate parsed arguments
# Usage: validate_args
# Exit 3 on invalid state
validate_args() {
    local from_idx through_idx

    # Validate phase names
    from_idx=$(phase_index "$FROM_PHASE") || exit 3
    through_idx=$(phase_index "$THROUGH_PHASE") || exit 3

    # --from must not be after --through
    if [[ "$from_idx" -gt "$through_idx" ]]; then
        log_error "--from ($FROM_PHASE) must precede --through ($THROUGH_PHASE)"
        exit 3
    fi

    # design+ phases require a file path, not a topic string
    if [[ "$from_idx" -ge 2 ]]; then
        if [[ ! "$INPUT" =~ ^docs/ ]] && [[ ! -f "$INPUT" ]]; then
            log_error "Phase '$FROM_PHASE' requires an existing backlog item path, not a topic string"
            exit 3
        fi
    fi

    return 0
}

# Extract artifact path from phase output
# Usage: parse_artifact_path <output> <type>
# type: "analysis" or "backlog"
# Returns: path on stdout, exit 1 if not found
parse_artifact_path() {
    local output="$1"
    local type="$2"

    local path
    path=$(echo "$output" | grep -oE "docs/${type}/[^ )\"']+" | head -1)

    if [[ -n "$path" ]]; then
        echo "$path"
        return 0
    fi

    return 1
}

# Fallback artifact resolution via git diff
# Usage: parse_artifact_fallback <type>
# type: "analysis" or "backlog"
parse_artifact_fallback() {
    local type="$1"

    local path
    path=$(git diff --cached --name-only 2>/dev/null | grep "^docs/${type}/" | head -1)

    if [[ -z "$path" ]]; then
        path=$(git diff --name-only 2>/dev/null | grep "^docs/${type}/" | head -1)
    fi

    if [[ -n "$path" ]]; then
        echo "$path"
        return 0
    fi

    return 1
}

# Detect verdict from /discern output
# Usage: detect_verdict <output>
# Returns: APPROVED, BLOCKED, or CHANGES REQUESTED on stdout; exit 1 if not found
detect_verdict() {
    local output="$1"

    local verdict
    verdict=$(echo "$output" | grep -oE 'APPROVED|BLOCKED|CHANGES REQUESTED' | head -1)

    if [[ -n "$verdict" ]]; then
        echo "$verdict"
        return 0
    fi

    log_error "Could not parse verdict from /discern output"
    return 1
}

# Get max turns for a phase (override > global > default)
# Usage: get_max_turns <phase>
get_max_turns() {
    local phase="$1"
    local idx
    idx=$(phase_index "$phase")

    # Check per-phase override (compatible with bash 3)
    local override_val=""
    case "$phase" in
        discover) override_val="${DISCOVER_TURNS:-}" ;;
        define)   override_val="${DEFINE_TURNS:-}" ;;
        design)   override_val="${DESIGN_TURNS:-}" ;;
        deliver)  override_val="${DELIVER_TURNS:-}" ;;
        discern)  override_val="${DISCERN_TURNS:-}" ;;
        commit)   override_val="${COMMIT_TURNS:-}" ;;
        done)     override_val="${DONE_TURNS:-}" ;;
    esac

    if [[ -n "$override_val" ]]; then
        echo "$override_val"
        return
    fi

    # Check global override
    if [[ -n "$TURNS_PER_PHASE" ]]; then
        echo "$TURNS_PER_PHASE"
        return
    fi

    # Default
    echo "${DEFAULT_TURNS[$idx]}"
}

# Build the prompt for a phase invocation
# Usage: build_phase_prompt <phase> <input>
build_phase_prompt() {
    local phase="$1"
    local input="$2"

    if [[ "${TRUNK_MODE:-false}" == "true" ]]; then
        echo "git-mode: trunk. /$phase $input"
    else
        echo "/$phase $input"
    fi
}

# Execute a single phase via claude -p
# Usage: run_phase <phase> <input>
# Sets: OUTPUT, SESSION_ID, PHASE_NUM_TURNS, PHASE_TOKENS
# Returns: claude's exit code (0=success, 2=turn exhaustion, other=failure)
run_phase() {
    local phase="$1"
    local input="$2"

    local prompt max_turns tools idx
    prompt=$(build_phase_prompt "$phase" "$input")
    max_turns=$(get_max_turns "$phase")
    idx=$(phase_index "$phase")
    tools="${PHASE_TOOLS[$idx]}"

    local claude_args=(-p "$prompt" --max-turns "$max_turns" --allowedTools "$tools")

    # Skip permissions for unattended execution
    if [[ "${SKIP_PERMISSIONS:-false}" == "true" ]]; then
        claude_args+=(--dangerously-skip-permissions)
    fi

    # Verbose mode: stream-json for full trace; otherwise json for compact output
    if [[ "${VERBOSE_LOGGING:-false}" == "true" ]]; then
        claude_args+=(--verbose --output-format stream-json)
    else
        claude_args+=(--output-format json)
    fi

    # Add --resume if we have a session and resume is enabled
    if [[ -n "${SESSION_ID:-}" && "$NO_RESUME" != "true" ]]; then
        claude_args+=(--resume "$SESSION_ID")
    fi

    log_info "[$phase] Starting (max turns: $max_turns)"

    local raw_output
    if [[ "${VERBOSE_LOGGING:-false}" == "true" && -n "$LOG_DIR" ]]; then
        local verbose_log="$LOG_DIR/${phase}_verbose.jsonl"
        mkdir -p "$LOG_DIR"
        raw_output=$(claude "${claude_args[@]}" 2>/dev/null | tee "$verbose_log")
        log_info "[$phase] Verbose trace: $verbose_log"
    else
        raw_output=$(claude "${claude_args[@]}" 2>/dev/null)
    fi
    local ec=$?

    # Reset phase metrics
    PHASE_NUM_TURNS=0
    PHASE_TOKENS=0

    if [[ $ec -ne 0 ]]; then
        log_error "[$phase] claude exited with code $ec"
        OUTPUT=""
        return "$ec"
    fi

    # Parse JSON output
    if command -v jq &>/dev/null; then
        local json_blob="$raw_output"
        # stream-json: extract the last result message from the stream
        if [[ "${VERBOSE_LOGGING:-false}" == "true" ]]; then
            json_blob=$(echo "$raw_output" | grep '"type":"result"' | tail -1)
            if [[ -z "$json_blob" ]]; then
                # Fallback: try last non-empty line
                json_blob=$(echo "$raw_output" | tail -1)
            fi
        fi
        OUTPUT=$(echo "$json_blob" | jq -r '.result // empty')
        SESSION_ID=$(echo "$json_blob" | jq -r '.session_id // empty')
        PHASE_NUM_TURNS=$(echo "$json_blob" | jq -r '.num_turns // 0')
        local input_tokens output_tokens
        input_tokens=$(echo "$json_blob" | jq -r '.usage.input_tokens // 0')
        output_tokens=$(echo "$json_blob" | jq -r '.usage.output_tokens // 0')
        PHASE_TOKENS=$((input_tokens + output_tokens))
        local cost
        cost=$(echo "$json_blob" | jq -r '.total_cost_usd // 0')
        log_info "[$phase] Completed ($PHASE_NUM_TURNS turns, $PHASE_TOKENS tokens, \$$cost)"
    else
        OUTPUT="$raw_output"
        SESSION_ID=""
        log_info "[$phase] Completed (jq not available for parsing)"
    fi

    return 0
}

# Retry a phase once with --resume
# Usage: retry_phase <phase> <input> <session_id>
retry_phase() {
    local phase="$1"
    local input="$2"
    local prev_session="$3"

    log_info "[$phase] Retrying with --resume $prev_session"

    local prompt max_turns tools idx
    prompt=$(build_phase_prompt "$phase" "$input")
    max_turns=$(get_max_turns "$phase")
    idx=$(phase_index "$phase")
    tools="${PHASE_TOOLS[$idx]}"

    local claude_args=(-p "$prompt" --max-turns "$max_turns" --allowedTools "$tools" --resume "$prev_session")

    if [[ "${SKIP_PERMISSIONS:-false}" == "true" ]]; then
        claude_args+=(--dangerously-skip-permissions)
    fi

    if [[ "${VERBOSE_LOGGING:-false}" == "true" ]]; then
        claude_args+=(--verbose --output-format stream-json)
    else
        claude_args+=(--output-format json)
    fi

    local raw_output
    if [[ "${VERBOSE_LOGGING:-false}" == "true" && -n "$LOG_DIR" ]]; then
        local verbose_log="$LOG_DIR/${phase}_retry_verbose.jsonl"
        mkdir -p "$LOG_DIR"
        raw_output=$(claude "${claude_args[@]}" 2>/dev/null | tee "$verbose_log")
    else
        raw_output=$(claude "${claude_args[@]}" 2>/dev/null)
    fi
    local ec=$?

    if [[ $ec -ne 0 ]]; then
        log_error "[$phase] Retry also failed (exit $ec). Scope may exceed appetite."
        OUTPUT=""
        return 1
    fi

    # Parse JSON output
    if command -v jq &>/dev/null; then
        local json_blob="$raw_output"
        if [[ "${VERBOSE_LOGGING:-false}" == "true" ]]; then
            json_blob=$(echo "$raw_output" | grep '"type":"result"' | tail -1)
            if [[ -z "$json_blob" ]]; then
                json_blob=$(echo "$raw_output" | tail -1)
            fi
        fi
        OUTPUT=$(echo "$json_blob" | jq -r '.result // empty')
        SESSION_ID=$(echo "$json_blob" | jq -r '.session_id // empty')
        local num_turns
        num_turns=$(echo "$json_blob" | jq -r '.num_turns // 0')
        log_info "[$phase] Retry completed ($num_turns turns)"
    else
        OUTPUT="$raw_output"
        log_info "[$phase] Retry completed"
    fi

    return 0
}

# Log phase usage (turns, tokens, duration)
# Usage: log_phase_usage <phase> <turns> <tokens> <duration_secs>
log_phase_usage() {
    local phase="$1"
    local turns="$2"
    local tokens="$3"
    local duration="$4"

    if [[ -n "$LOG_DIR" ]]; then
        # JSON logging for cron/CI
        mkdir -p "$LOG_DIR"
        echo "{\"phase\":\"$phase\",\"turns\":$turns,\"tokens\":$tokens,\"duration_secs\":$duration,\"timestamp\":\"$(date -u +%Y-%m-%dT%H:%M:%SZ)\"}" \
            >> "$LOG_DIR/run-pdlc.jsonl"
    fi
}

# Acquire a lockfile
# Usage: acquire_lock <input_key> [lock_dir]
acquire_lock() {
    local input_key="$1"
    local lock_dir="${2:-.genie-locks}"

    local input_hash
    input_hash=$(echo -n "$input_key" | shasum | cut -d' ' -f1)
    LOCKFILE="$lock_dir/${input_hash}.lock"

    mkdir -p "$lock_dir"

    if [[ -f "$LOCKFILE" ]]; then
        local lock_pid
        lock_pid=$(cat "$LOCKFILE" 2>/dev/null)

        # Check if lock is stale (4 hours = 14400 seconds)
        local lock_age=0
        if [[ -f "$LOCKFILE" ]]; then
            local now lock_mtime
            now=$(date +%s)
            lock_mtime=$(stat -c %Y "$LOCKFILE" 2>/dev/null || stat -f %m "$LOCKFILE" 2>/dev/null || echo "$now")
            lock_age=$((now - lock_mtime))
        fi

        if [[ $lock_age -gt 14400 ]]; then
            log_info "Stale lock detected (age: ${lock_age}s, pid: $lock_pid). Overwriting."
        elif kill -0 "$lock_pid" 2>/dev/null; then
            log_error "Lock held by running process $lock_pid ($LOCKFILE)"
            return 3
        else
            log_info "Lock held by dead process $lock_pid. Overwriting."
        fi
    fi

    echo "$$" > "$LOCKFILE"
    return 0
}

# Release the lockfile
# Usage: release_lock
release_lock() {
    if [[ -n "${LOCKFILE:-}" && -f "$LOCKFILE" ]]; then
        rm -f "$LOCKFILE"
        LOCKFILE=""
    fi
}

# Source genie-session.sh for worktree lifecycle management
SCRIPT_DIR="${SCRIPT_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
SELF="$SCRIPT_DIR/$(basename "${BASH_SOURCE[0]}")"
GENIE_SESSION="$SCRIPT_DIR/genie-session.sh"
if [[ -f "$GENIE_SESSION" ]]; then
    # shellcheck source=genie-session.sh
    source "$GENIE_SESSION"
fi

worktree_setup() {
    local item_slug="$1"
    local worktree_path
    worktree_path=$(session_start "$item_slug" "$FROM_PHASE") || {
        log_error "Failed to create worktree for $item_slug"
        return 1
    }
    echo "$worktree_path"
    return 0
}

worktree_teardown_success() {
    local item_slug="$1"
    local finish_mode="${2:---merge}"
    session_finish "$item_slug" "$finish_mode" || {
        local ec=$?
        if [[ $ec -eq 2 ]]; then
            log_error "Merge conflict for $item_slug"
            return 2
        fi
        log_error "Failed to finish session for $item_slug"
        return 1
    }
    return 0
}

worktree_teardown_failure() {
    local item_slug="$1"
    session_cleanup_item "$item_slug"
    return 0
}

# ─────────────────────────────────────────────
# Batch Mode Functions
# ─────────────────────────────────────────────

# Resolve batch items from inputs or backlog scan
# Sets: BATCH_ITEMS array (format: "phase:input")
resolve_batch_items() {
    BATCH_ITEMS=()

    # Load topics from --topics-file
    if [[ -n "${TOPICS_FILE:-}" ]]; then
        if [[ ! -f "$TOPICS_FILE" ]]; then
            log_error "Topics file not found: $TOPICS_FILE"
            exit 3
        fi
        while IFS= read -r line || [[ -n "$line" ]]; do
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            INPUTS+=("$line")
        done < "$TOPICS_FILE"
    fi

    if [[ ${#INPUTS[@]} -eq 0 ]]; then
        # Auto-scan backlog for actionable items
        local backlog_dir="docs/backlog"
        if [[ ! -d "$backlog_dir" ]]; then
            log_error "Backlog directory not found: $backlog_dir"
            exit 3
        fi

        for file in "$backlog_dir"/*.md; do
            [[ -f "$file" ]] || continue
            # Skip files without frontmatter (e.g., README.md)
            head -1 "$file" | grep -q '^---$' || continue

            local status item_phase priority
            status=$(get_frontmatter_field "$file" "status")
            item_phase=$(status_to_phase "$status")
            [[ -n "$item_phase" ]] || continue

            # Priority filter
            if [[ ${#PRIORITIES[@]} -gt 0 ]]; then
                priority=$(get_frontmatter_field "$file" "priority")
                local match="false"
                for p in "${PRIORITIES[@]}"; do
                    [[ "$priority" == "$p" ]] && { match="true"; break; }
                done
                [[ "$match" == "true" ]] || continue
            fi

            BATCH_ITEMS+=("$item_phase:$file")
        done
    else
        # Process explicit inputs
        for input in "${INPUTS[@]}"; do
            if [[ -f "$input" ]]; then
                # File — auto-detect phase from status
                head -1 "$input" | grep -q '^---$' || {
                    log_info "Skipping $input (no frontmatter)"
                    continue
                }
                local status item_phase
                status=$(get_frontmatter_field "$input" "status")
                item_phase=$(status_to_phase "$status")
                [[ -n "$item_phase" ]] || {
                    log_info "Skipping $input (status: $status — not actionable)"
                    continue
                }
                BATCH_ITEMS+=("$item_phase:$input")
            else
                # Topic string — start from discover
                BATCH_ITEMS+=("discover:$input")
            fi
        done
    fi

    # Sort (P1-* files sort before P2-*)
    if [[ ${#BATCH_ITEMS[@]} -gt 1 ]]; then
        local sorted
        sorted=$(printf '%s\n' "${BATCH_ITEMS[@]}" | sort)
        BATCH_ITEMS=()
        while IFS= read -r line; do
            BATCH_ITEMS+=("$line")
        done <<< "$sorted"
    fi
}

# Print batch dry-run preview
print_batch_dry_run() {
    log_info "Found ${#BATCH_ITEMS[@]} actionable item(s):"
    for entry in "${BATCH_ITEMS[@]}"; do
        local item_phase="${entry%%:*}"
        local input="${entry#*:}"
        if [[ -f "$input" ]]; then
            local title
            title=$(get_frontmatter_field "$input" "title")
            log_info "  $(basename "$input"): $title (from: $item_phase)"
        else
            log_info "  $input (from: $item_phase)"
        fi
    done

    if [[ "$PARALLEL_JOBS" -gt 0 && "$TRUNK_MODE" == "true" ]]; then
        log_info "Mode: parallel ($PARALLEL_JOBS workers, trunk-based, worktrees)"
    elif [[ "$PARALLEL_JOBS" -gt 0 ]]; then
        log_info "Mode: parallel ($PARALLEL_JOBS workers, PR-based, worktrees)"
    elif [[ "$TRUNK_MODE" == "true" ]]; then
        log_info "Mode: sequential (trunk-based)"
    else
        log_info "Mode: sequential"
    fi
    log_info "(dry run — not executing)"
}

# Print batch summary (sequential mode)
print_batch_summary() {
    local succeeded="$1"
    local failed="$2"
    local start_time="$3"
    shift 3
    local failed_items=("$@")

    local end_time duration_mins
    end_time=$(date +%s)
    duration_mins=$(( (end_time - start_time) / 60 ))

    echo >&2
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "BATCH SUMMARY"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Succeeded: $succeeded"
    log_info "Failed:    $failed"
    log_info "Duration:  ${duration_mins}m"

    if [[ ${#failed_items[@]} -gt 0 ]]; then
        log_info "Failed items:"
        for item in "${failed_items[@]}"; do
            log_info "  - $item"
        done
    fi
}

# Print batch summary (parallel mode)
print_batch_parallel_summary() {
    local succeeded="$1"
    local failed="$2"
    local conflicts="$3"
    local start_time="$4"
    shift 4

    # Parse delimiter-separated lists
    local succeeded_items=()
    local failed_items=()
    local conflict_items=()
    local current_list="succeeded"

    for arg in "$@"; do
        if [[ "$arg" == "---" ]]; then
            if [[ "$current_list" == "succeeded" ]]; then
                current_list="failed"
            else
                current_list="conflict"
            fi
            continue
        fi
        case "$current_list" in
            succeeded)  succeeded_items+=("$arg") ;;
            failed)     failed_items+=("$arg") ;;
            conflict)   conflict_items+=("$arg") ;;
        esac
    done

    local end_time duration_mins
    end_time=$(date +%s)
    duration_mins=$(( (end_time - start_time) / 60 ))

    echo >&2
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "BATCH SUMMARY (parallel)"
    log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
    log_info "Succeeded:       $succeeded"
    log_info "Failed:          $failed"
    log_info "Merge conflicts: $conflicts"
    log_info "Duration:        ${duration_mins}m"
    log_info "Logs:            $LOG_DIR/"

    if [[ ${#succeeded_items[@]} -gt 0 ]]; then
        log_info ""
        log_info "Succeeded:"
        for item in "${succeeded_items[@]}"; do
            log_info "  $(basename "$item" .md)"
        done
    fi

    if [[ ${#failed_items[@]} -gt 0 ]]; then
        log_info ""
        log_info "Failed:"
        for item in "${failed_items[@]}"; do
            local item_basename
            item_basename=$(basename "$item" .md)
            log_info "  $item_basename → $LOG_DIR/${item_basename}.log"
        done
    fi

    if [[ ${#conflict_items[@]} -gt 0 ]]; then
        log_info ""
        log_info "Merge conflicts:"
        for item in "${conflict_items[@]}"; do
            local item_basename
            item_basename=$(basename "$item" .md)
            log_info "  $item_basename → $LOG_DIR/${item_basename}.log"
        done
    fi
}

# Execute batch items sequentially
run_batch_sequential() {
    local succeeded=0
    local failed=0
    local failed_items=()
    local start_time
    start_time=$(date +%s)

    for entry in "${BATCH_ITEMS[@]}"; do
        local item_phase="${entry%%:*}"
        local input="${entry#*:}"
        local display_name
        if [[ -f "$input" ]]; then
            display_name=$(basename "$input" .md)
        else
            display_name="$input"
        fi

        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "Running: $display_name ($item_phase → $THROUGH_PHASE)"
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local pdlc_args=(--from "$item_phase" --through "$THROUGH_PHASE" --lock)
        [[ "$TRUNK_MODE" == "true" ]] && pdlc_args+=(--trunk)
        [[ "$VERBOSE_LOGGING" == "true" ]] && pdlc_args+=(--verbose)
        [[ "$SKIP_PERMISSIONS" == "true" ]] && pdlc_args+=(--skip-permissions)
        [[ -n "$LOG_DIR" ]] && pdlc_args+=(--log-dir "$LOG_DIR")
        pdlc_args+=("$input")

        if "$SELF" "${pdlc_args[@]}"; then
            succeeded=$((succeeded + 1))
            log_info "Completed: $display_name"
        else
            local ec=$?
            failed=$((failed + 1))
            failed_items+=("$input")
            log_error "Failed (exit $ec): $display_name"

            if [[ "$CONTINUE_ON_FAILURE" != "true" ]]; then
                log_error "Stopping batch (use --continue-on-failure to keep going)"
                print_batch_summary "$succeeded" "$failed" "$start_time" "${failed_items[@]}"
                exit 2
            fi
        fi
    done

    print_batch_summary "$succeeded" "$failed" "$start_time" "${failed_items[@]+"${failed_items[@]}"}"

    if [[ $failed -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Execute batch items in parallel with worker pool
run_batch_parallel() {
    # Ensure log dir exists
    if [[ -z "$LOG_DIR" ]]; then
        LOG_DIR="logs/batch-$(date +%Y%m%d-%H%M%S)"
    fi
    mkdir -p "$LOG_DIR"

    log_info "Parallel mode: ${#BATCH_ITEMS[@]} items, $PARALLEL_JOBS workers"
    log_info "Log directory: $LOG_DIR"

    local succeeded=0
    local failed=0
    local merge_conflicts=0
    local start_time
    start_time=$(date +%s)

    # Parallel indexed arrays (Bash 3.2 compatible — no associative arrays, no wait -n)
    local pids=()
    local pid_inputs=()
    local pid_logs=()
    local pid_slugs=()

    local failed_items=()
    local conflict_items=()
    local succeeded_items=()
    local succeeded_slugs=()

    local queue_idx=0
    local total=${#BATCH_ITEMS[@]}

    # Launch a parallel worker
    _launch_batch_worker() {
        local entry="$1"
        local item_idx="$2"
        local item_phase="${entry%%:*}"
        local input="${entry#*:}"
        local slug
        if [[ -f "$input" ]]; then
            slug=$(basename "$input" .md)
        else
            slug="batch-$item_idx"
        fi
        local item_log="$LOG_DIR/${slug}.log"

        log_info "Starting [$item_idx/$total]: $slug ($item_phase → $THROUGH_PHASE)"

        local pdlc_args=(--worktree --finish-mode --leave-branch
            --from "$item_phase" --through "$THROUGH_PHASE"
            --lock --cleanup-on-failure --log-dir "$LOG_DIR"
            --slug "$slug")
        [[ "$TRUNK_MODE" == "true" ]] && pdlc_args+=(--trunk)
        [[ "$VERBOSE_LOGGING" == "true" ]] && pdlc_args+=(--verbose)
        [[ "$SKIP_PERMISSIONS" == "true" ]] && pdlc_args+=(--skip-permissions)
        pdlc_args+=("$input")

        "$SELF" "${pdlc_args[@]}" >"$item_log" 2>&1 &

        echo "$!:$input:$item_log:$slug"
    }

    # Launch initial batch of workers
    while [[ $queue_idx -lt $total && ${#pids[@]} -lt $PARALLEL_JOBS ]]; do
        local worker_info
        worker_info=$(_launch_batch_worker "${BATCH_ITEMS[$queue_idx]}" "$((queue_idx + 1))")
        pids+=("${worker_info%%:*}")
        local rest="${worker_info#*:}"
        pid_inputs+=("${rest%%:*}")
        rest="${rest#*:}"
        pid_logs+=("${rest%%:*}")
        pid_slugs+=("${rest#*:}")

        queue_idx=$((queue_idx + 1))
    done

    # Poll for completion and refill slots
    while [[ ${#pids[@]} -gt 0 ]]; do
        local new_pids=()
        local new_inputs=()
        local new_logs=()
        local new_slugs=()

        local idx=0
        while [[ $idx -lt ${#pids[@]} ]]; do
            local pid="${pids[$idx]}"
            local input="${pid_inputs[$idx]}"
            local item_log="${pid_logs[$idx]}"
            local slug="${pid_slugs[$idx]}"

            if ! kill -0 "$pid" 2>/dev/null; then
                wait "$pid" 2>/dev/null
                local ec=$?

                if [[ $ec -eq 0 ]]; then
                    succeeded=$((succeeded + 1))
                    succeeded_items+=("$input")
                    succeeded_slugs+=("$slug")
                    log_info "Completed: $slug"
                elif [[ $ec -eq 2 ]]; then
                    merge_conflicts=$((merge_conflicts + 1))
                    conflict_items+=("$input")
                    log_error "Merge conflict: $slug (log: $item_log)"
                else
                    failed=$((failed + 1))
                    failed_items+=("$input")
                    log_error "Failed (exit $ec): $slug (log: $item_log)"
                fi

                # Fill the slot with next queued item
                if [[ $queue_idx -lt $total ]]; then
                    local worker_info
                    worker_info=$(_launch_batch_worker "${BATCH_ITEMS[$queue_idx]}" "$((queue_idx + 1))")
                    new_pids+=("${worker_info%%:*}")
                    local rest="${worker_info#*:}"
                    new_inputs+=("${rest%%:*}")
                    rest="${rest#*:}"
                    new_logs+=("${rest%%:*}")
                    new_slugs+=("${rest#*:}")

                    queue_idx=$((queue_idx + 1))
                fi
            else
                new_pids+=("$pid")
                new_inputs+=("$input")
                new_logs+=("$item_log")
                new_slugs+=("$slug")
            fi

            idx=$((idx + 1))
        done

        pids=("${new_pids[@]+"${new_pids[@]}"}")
        pid_inputs=("${new_inputs[@]+"${new_inputs[@]}"}")
        pid_logs=("${new_logs[@]+"${new_logs[@]}"}")
        pid_slugs=("${new_slugs[@]+"${new_slugs[@]}"}")

        if [[ ${#pids[@]} -gt 0 ]]; then
            sleep 5
        fi
    done

    # ── Integration phase: serialize merges/PRs ──
    if [[ ${#succeeded_items[@]} -gt 0 ]]; then
        log_info "Integration phase: ${#succeeded_items[@]} items to integrate"

        local integrate_idx=0
        while [[ $integrate_idx -lt ${#succeeded_items[@]} ]]; do
            local slug="${succeeded_slugs[$integrate_idx]}"
            local input="${succeeded_items[$integrate_idx]}"
            log_info "Integrating: $slug"

            if [[ "$TRUNK_MODE" == "true" ]]; then
                if session_integrate_trunk "$slug"; then
                    log_info "Merged to trunk: $slug"
                else
                    local ec=$?
                    if [[ $ec -eq 2 ]]; then
                        merge_conflicts=$((merge_conflicts + 1))
                        conflict_items+=("$input")
                        log_error "Rebase conflict: $slug"
                    else
                        failed=$((failed + 1))
                        failed_items+=("$input")
                        log_error "Integration failed: $slug"
                    fi
                    succeeded=$((succeeded - 1))
                fi
            else
                if session_integrate_pr "$slug"; then
                    log_info "PR created: $slug"
                else
                    failed=$((failed + 1))
                    failed_items+=("$input")
                    log_error "PR creation failed: $slug"
                    succeeded=$((succeeded - 1))
                fi
            fi

            integrate_idx=$((integrate_idx + 1))
        done
    fi

    # Print summary
    print_batch_parallel_summary "$succeeded" "$failed" "$merge_conflicts" "$start_time" \
        "${succeeded_items[@]+"${succeeded_items[@]}"}" \
        "---" \
        "${failed_items[@]+"${failed_items[@]}"}" \
        "---" \
        "${conflict_items[@]+"${conflict_items[@]}"}"

    if [[ $failed -gt 0 || $merge_conflicts -gt 0 ]]; then
        return 1
    fi
    return 0
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
    parse_args "$@"

    # Batch mode check: --parallel, multiple inputs, or no inputs
    if [[ "$PARALLEL_JOBS" -gt 0 || ${#INPUTS[@]} -gt 1 || ${#INPUTS[@]} -eq 0 ]]; then
        resolve_batch_items
        if [[ ${#BATCH_ITEMS[@]} -eq 0 ]]; then
            log_info "No actionable items found matching filters."
            exit 0
        fi
        if [[ "$DRY_RUN" == "true" ]]; then
            print_batch_dry_run
            exit 0
        fi
        if [[ "$PARALLEL_JOBS" -gt 0 ]]; then
            run_batch_parallel
            exit $?
        else
            run_batch_sequential
            exit $?
        fi
    fi

    # Single-item mode (unchanged from here down)
    INPUT="${INPUTS[0]:-$INPUT}"
    validate_args

    local from_idx through_idx
    from_idx=$(phase_index "$FROM_PHASE")
    through_idx=$(phase_index "$THROUGH_PHASE")

    log_info "Running PDLC: $FROM_PHASE → $THROUGH_PHASE"
    log_info "Input: $INPUT"
    if [[ "$TRUNK_MODE" == "true" ]]; then
        log_info "Git mode: trunk-based"
    fi

    # Acquire lockfile if requested
    if [[ "$USE_LOCK" == "true" ]]; then
        acquire_lock "$INPUT"
        trap release_lock EXIT
    fi

    # Worktree setup
    local item_slug=""
    local original_dir=""
    if [[ "$USE_WORKTREE" == "true" ]]; then
        item_slug="${WORKTREE_SLUG:-$(basename "$INPUT" .md)}"
        log_info "Setting up worktree for $item_slug"
        local worktree_path
        worktree_path=$(worktree_setup "$item_slug") || exit 1
        original_dir="$(pwd)"
        cd "$worktree_path"
        log_info "Working in worktree: $worktree_path"
    fi

    # State variables
    local analysis_path=""
    local item_path=""
    SESSION_ID=""
    OUTPUT=""
    PHASE_NUM_TURNS=0
    PHASE_TOKENS=0

    # If starting from design+, input is the item_path
    if [[ "$from_idx" -ge 2 ]]; then
        item_path="$INPUT"
    fi

    # Execute phase range
    local i
    for ((i = from_idx; i <= through_idx; i++)); do
        local phase="${PHASES[$i]}"
        local phase_input=""

        # Determine input for this phase
        case "$phase" in
            discover)
                phase_input="$INPUT"
                ;;
            define)
                phase_input="${analysis_path:-$INPUT}"
                ;;
            *)
                phase_input="${item_path:-$INPUT}"
                ;;
        esac

        # Run the phase
        local start_time
        start_time=$(date +%s)

        run_phase "$phase" "$phase_input"
        local ec=$?

        local end_time duration
        end_time=$(date +%s)
        duration=$((end_time - start_time))

        # Handle phase failure
        if [[ $ec -ne 0 ]]; then
            # Check if it's turn exhaustion (exit 2 from claude)
            if [[ $ec -eq 2 && -n "$SESSION_ID" ]]; then
                retry_phase "$phase" "$phase_input" "$SESSION_ID"
                local retry_ec=$?
                if [[ $retry_ec -ne 0 ]]; then
                    log_error "Phase '$phase' exhausted turns after retry. Stopping."
                    if [[ "$USE_WORKTREE" == "true" && "$CLEANUP_ON_FAILURE" == "true" && -n "$item_slug" ]]; then
                        cd "${original_dir:-/}"
                        worktree_teardown_failure "$item_slug"
                    fi
                    exit 1
                fi
            else
                log_error "Phase '$phase' failed. Stopping."
                if [[ "$USE_WORKTREE" == "true" && "$CLEANUP_ON_FAILURE" == "true" && -n "$item_slug" ]]; then
                    cd "${original_dir:-/}"
                    worktree_teardown_failure "$item_slug"
                fi
                exit 1
            fi
        fi

        # Log phase usage
        log_phase_usage "$phase" "${PHASE_NUM_TURNS:-0}" "${PHASE_TOKENS:-0}" "$duration"

        # Parse artifacts from output
        case "$phase" in
            discover)
                analysis_path=$(parse_artifact_path "$OUTPUT" "analysis" 2>/dev/null) || \
                    analysis_path=$(parse_artifact_fallback "analysis" 2>/dev/null) || true
                log_debug "analysis_path=$analysis_path"
                ;;
            define)
                item_path=$(parse_artifact_path "$OUTPUT" "backlog" 2>/dev/null) || \
                    item_path=$(parse_artifact_fallback "backlog" 2>/dev/null) || true
                log_debug "item_path=$item_path"
                ;;
            discern)
                # Gate check
                local verdict
                verdict=$(detect_verdict "$OUTPUT" 2>/dev/null) || true

                if [[ "$verdict" == "BLOCKED" || "$verdict" == "CHANGES REQUESTED" ]]; then
                    log_error "Verdict: $verdict — stopping"
                    exit 1
                elif [[ "$verdict" != "APPROVED" ]]; then
                    log_error "Could not parse verdict from /discern output — stopping (safe default)"
                    exit 1
                fi

                log_info "Verdict: APPROVED — continuing"
                ;;
        esac
    done

    # Worktree teardown on success
    if [[ "$USE_WORKTREE" == "true" && -n "$item_slug" ]]; then
        cd "${original_dir:-/}"
        worktree_teardown_success "$item_slug" "$FINISH_MODE"
        local teardown_ec=$?
        if [[ $teardown_ec -ne 0 ]]; then
            log_error "Worktree teardown failed (exit $teardown_ec)"
            exit "$teardown_ec"
        fi
    fi

    log_info "PDLC completed: $FROM_PHASE → $THROUGH_PHASE"
    exit 0
}

# Support sourcing for tests (skip main dispatch)
if [[ "${RUN_PDLC_SOURCED:-}" == "true" ]]; then
    # shellcheck disable=SC2317
    return 0 2>/dev/null || true
fi

main "$@"
