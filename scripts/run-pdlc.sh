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
            --discover-turns)    DISCOVER_TURNS="$2"; shift 2 ;;
            --define-turns)      DEFINE_TURNS="$2"; shift 2 ;;
            --design-turns)      DESIGN_TURNS="$2"; shift 2 ;;
            --deliver-turns)     DELIVER_TURNS="$2"; shift 2 ;;
            --discern-turns)     DISCERN_TURNS="$2"; shift 2 ;;
            --commit-turns)      COMMIT_TURNS="$2"; shift 2 ;;
            --done-turns)        DONE_TURNS="$2"; shift 2 ;;
            -h|--help)
                echo "Usage: run-pdlc.sh [OPTIONS] <topic|backlog-item-path>"
                echo ""
                echo "Phase range:"
                echo "  --from <phase>          Start phase (default: discover)"
                echo "  --through <phase>       End phase (default: done)"
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
                echo "Worktree:"
                echo "  --cleanup-on-failure    Remove worktree on failure (default: preserve)"
                exit 0
                ;;
            *)
                # Positional argument is the input (topic or path)
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

    echo "/$phase $input"
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

    local claude_args=(-p "$prompt" --output-format json --max-turns "$max_turns" --allowedTools "$tools")

    # Add --resume if we have a session and resume is enabled
    if [[ -n "${SESSION_ID:-}" && "$NO_RESUME" != "true" ]]; then
        claude_args+=(--resume "$SESSION_ID")
    fi

    log_info "[$phase] Starting (max turns: $max_turns)"

    local raw_output
    raw_output=$(claude "${claude_args[@]}" 2>/dev/null)
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
        OUTPUT=$(echo "$raw_output" | jq -r '.result // empty')
        SESSION_ID=$(echo "$raw_output" | jq -r '.session_id // empty')
        PHASE_NUM_TURNS=$(echo "$raw_output" | jq -r '.num_turns // 0')
        local input_tokens output_tokens
        input_tokens=$(echo "$raw_output" | jq -r '.usage.input_tokens // 0')
        output_tokens=$(echo "$raw_output" | jq -r '.usage.output_tokens // 0')
        PHASE_TOKENS=$((input_tokens + output_tokens))
        local cost
        cost=$(echo "$raw_output" | jq -r '.total_cost_usd // 0')
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

    local raw_output
    raw_output=$(claude -p "$prompt" --output-format json --max-turns "$max_turns" --allowedTools "$tools" --resume "$prev_session" 2>/dev/null)
    local ec=$?

    if [[ $ec -ne 0 ]]; then
        log_error "[$phase] Retry also failed (exit $ec). Scope may exceed appetite."
        OUTPUT=""
        return 1
    fi

    # Parse JSON output
    if command -v jq &>/dev/null; then
        OUTPUT=$(echo "$raw_output" | jq -r '.result // empty')
        SESSION_ID=$(echo "$raw_output" | jq -r '.session_id // empty')
        local num_turns
        num_turns=$(echo "$raw_output" | jq -r '.num_turns // 0')
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

# Worktree stubs — TODO: source genie-session.sh when P2-session-management is delivered
worktree_setup() {
    # shellcheck disable=SC2034
    local item_slug="$1"
    log_info "TODO: worktree_setup not yet implemented (source genie-session.sh)"
    return 1
}

worktree_teardown_success() {
    local item_slug="$1"
    log_info "TODO: worktree_teardown_success not yet implemented"
    return 1
}

worktree_teardown_failure() {
    # shellcheck disable=SC2034
    local item_slug="$1"
    log_info "TODO: worktree_teardown_failure not yet implemented"
    return 1
}

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

main() {
    parse_args "$@"
    validate_args

    local from_idx through_idx
    from_idx=$(phase_index "$FROM_PHASE")
    through_idx=$(phase_index "$THROUGH_PHASE")

    log_info "Running PDLC: $FROM_PHASE → $THROUGH_PHASE"
    log_info "Input: $INPUT"

    # Acquire lockfile if requested
    if [[ "$USE_LOCK" == "true" ]]; then
        acquire_lock "$INPUT"
        trap release_lock EXIT
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
                    exit 1
                fi
            else
                log_error "Phase '$phase' failed. Stopping."
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

    log_info "PDLC completed: $FROM_PHASE → $THROUGH_PHASE"
    exit 0
}

# Support sourcing for tests (skip main dispatch)
if [[ "${RUN_PDLC_SOURCED:-}" == "true" ]]; then
    # shellcheck disable=SC2317
    return 0 2>/dev/null || true
fi

main "$@"
