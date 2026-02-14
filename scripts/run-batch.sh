#!/bin/bash
# Batch runner for overnight autonomous execution
# Two modes:
#   deliver  — Run delivery on designed backlog items (filtered by priority)
#   discover — Run discovery+shaping on a list of topics
#
# Usage:
#   run-batch.sh deliver [OPTIONS]
#   run-batch.sh discover [OPTIONS] [TOPIC...]
#
# Exit codes:
#   0  All items completed successfully
#   1  One or more items failed (with --continue-on-failure)
#   2  Stopped on first failure (default for deliver)
#   3  Input validation error

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
RUN_PDLC="$SCRIPT_DIR/run-pdlc.sh"

# ─────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────

log_info()  { echo "[INFO]  $(date +%H:%M:%S) $*" >&2; }
log_error() { echo "[ERROR] $(date +%H:%M:%S) $*" >&2; }

# ─────────────────────────────────────────────
# Frontmatter helpers (minimal, reuses run-pdlc.sh patterns)
# ─────────────────────────────────────────────

get_frontmatter_field() {
    local file="$1"
    local field="$2"

    # Extract value between --- markers
    sed -n '/^---$/,/^---$/p' "$file" | \
        grep -E "^${field}:" | head -1 | \
        sed "s/^${field}:[[:space:]]*//" | \
        sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//" | xargs
}

# ─────────────────────────────────────────────
# Deliver subcommand
# ─────────────────────────────────────────────

deliver_usage() {
    cat >&2 <<'EOF'
Usage: run-batch.sh deliver [OPTIONS]

Run delivery on backlog items at 'designed' status.

Options:
  --priority P1|P2|P3    Filter by priority (repeatable)
  --from <phase>         Start phase (default: deliver)
  --through <phase>      End phase (default: done)
  --log-dir <dir>        Log directory for run-pdlc.sh
  --continue-on-failure  Keep going when an item fails (default: stop)
  --trunk                Use trunk-based mode (commit to main, no PRs)
  --parallel N           Run N items concurrently (implies --worktree --trunk)
  --dry-run              List matching items without executing
  -h, --help             Show this help
EOF
}

cmd_deliver() {
    local priorities=()
    local from_phase="deliver"
    local through_phase="done"
    local log_dir=""
    local continue_on_failure="false"
    local dry_run="false"
    local trunk_mode="false"
    local parallel_jobs=0

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --priority)          priorities+=("$2"); shift 2 ;;
            --from)              from_phase="$2"; shift 2 ;;
            --through)           through_phase="$2"; shift 2 ;;
            --log-dir)           log_dir="$2"; shift 2 ;;
            --continue-on-failure) continue_on_failure="true"; shift ;;
            --trunk)             trunk_mode="true"; shift ;;
            --parallel)          parallel_jobs="$2"; shift 2 ;;
            --dry-run)           dry_run="true"; shift ;;
            -h|--help)           deliver_usage; exit 0 ;;
            *)                   log_error "Unknown option: $1"; deliver_usage; exit 3 ;;
        esac
    done

    # --parallel implies --worktree --trunk
    if [[ "$parallel_jobs" -gt 0 ]]; then
        trunk_mode="true"
    fi

    # Find designed backlog items
    local items=()
    local backlog_dir="docs/backlog"

    if [[ ! -d "$backlog_dir" ]]; then
        log_error "Backlog directory not found: $backlog_dir"
        exit 3
    fi

    for file in "$backlog_dir"/*.md; do
        [[ -f "$file" ]] || continue

        local status priority
        status=$(get_frontmatter_field "$file" "status")
        priority=$(get_frontmatter_field "$file" "priority")

        # Only designed items
        [[ "$status" == "designed" ]] || continue

        # Priority filter (if specified)
        if [[ ${#priorities[@]} -gt 0 ]]; then
            local match="false"
            for p in "${priorities[@]}"; do
                if [[ "$priority" == "$p" ]]; then
                    match="true"
                    break
                fi
            done
            [[ "$match" == "true" ]] || continue
        fi

        items+=("$priority:$file")
    done

    # Sort by priority (P1 < P2 < P3)
    local sorted
    sorted=$(printf '%s\n' "${items[@]}" | sort)
    items=()
    while IFS= read -r line; do
        items+=("$line")
    done <<< "$sorted"

    if [[ ${#items[@]} -eq 0 ]]; then
        log_info "No designed backlog items found matching filters."
        exit 0
    fi

    log_info "Found ${#items[@]} designed item(s):"
    for entry in "${items[@]}"; do
        local file="${entry#*:}"
        local title
        title=$(get_frontmatter_field "$file" "title")
        log_info "  $(basename "$file"): $title"
    done

    if [[ "$dry_run" == "true" ]]; then
        if [[ "$parallel_jobs" -gt 0 ]]; then
            log_info "Mode: parallel ($parallel_jobs workers, trunk-based, worktrees)"
        elif [[ "$trunk_mode" == "true" ]]; then
            log_info "Mode: sequential (trunk-based)"
        else
            log_info "Mode: sequential"
        fi
        log_info "(dry run — not executing)"
        exit 0
    fi

    # Dispatch to parallel or sequential execution
    if [[ "$parallel_jobs" -gt 0 ]]; then
        deliver_parallel "$parallel_jobs" "$from_phase" "$through_phase" "$log_dir" "${items[@]}"
        return $?
    fi

    # Execute each item
    local succeeded=0
    local failed=0
    local failed_items=()
    local start_time
    start_time=$(date +%s)

    for entry in "${items[@]}"; do
        local file="${entry#*:}"
        local title
        title=$(get_frontmatter_field "$file" "title")

        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "Delivering: $title"
        log_info "Item: $file"
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local pdlc_args=(--from "$from_phase" --through "$through_phase" --lock)
        if [[ "$trunk_mode" == "true" ]]; then
            pdlc_args+=(--trunk)
        fi
        if [[ -n "$log_dir" ]]; then
            pdlc_args+=(--log-dir "$log_dir")
        fi
        pdlc_args+=("$file")

        if "$RUN_PDLC" "${pdlc_args[@]}"; then
            succeeded=$((succeeded + 1))
            log_info "Completed: $title"
        else
            local ec=$?
            failed=$((failed + 1))
            failed_items+=("$file")
            log_error "Failed (exit $ec): $title"

            if [[ "$continue_on_failure" != "true" ]]; then
                log_error "Stopping batch (use --continue-on-failure to keep going)"
                print_summary "$succeeded" "$failed" "$start_time" "${failed_items[@]}"
                exit 2
            fi
        fi
    done

    print_summary "$succeeded" "$failed" "$start_time" "${failed_items[@]}"

    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

# ─────────────────────────────────────────────
# Parallel deliver
# ─────────────────────────────────────────────

deliver_parallel() {
    local max_jobs="$1"
    local from_phase="$2"
    local through_phase="$3"
    local log_dir="$4"
    shift 4
    local items=("$@")

    # Ensure log dir exists for per-item logs
    if [[ -z "$log_dir" ]]; then
        log_dir="logs/batch-$(date +%Y%m%d-%H%M%S)"
    fi
    mkdir -p "$log_dir"

    log_info "Parallel mode: ${#items[@]} items, $max_jobs workers"
    log_info "Log directory: $log_dir"

    local succeeded=0
    local failed=0
    local merge_conflicts=0
    local start_time
    start_time=$(date +%s)

    # Parallel indexed arrays (Bash 3.2 compatible — no associative arrays, no wait -n)
    local pids=()       # PIDs of running workers
    local pid_files=()  # Corresponding backlog file for each PID
    local pid_logs=()   # Per-item log file path

    local failed_items=()
    local conflict_items=()
    local succeeded_items=()

    # Queue index — tracks next item to dispatch
    local queue_idx=0
    local total=${#items[@]}

    # Launch initial batch of workers
    while [[ $queue_idx -lt $total && ${#pids[@]} -lt $max_jobs ]]; do
        local entry="${items[$queue_idx]}"
        local file="${entry#*:}"
        local item_basename
        item_basename=$(basename "$file" .md)
        local item_log="$log_dir/${item_basename}.log"

        log_info "Starting [$((queue_idx + 1))/$total]: $item_basename"

        "$RUN_PDLC" --worktree --trunk --from "$from_phase" --through "$through_phase" \
            --lock --cleanup-on-failure --log-dir "$log_dir" "$file" \
            >"$item_log" 2>&1 &

        pids+=($!)
        pid_files+=("$file")
        pid_logs+=("$item_log")

        queue_idx=$((queue_idx + 1))
    done

    # Poll for completion and refill slots
    while [[ ${#pids[@]} -gt 0 ]]; do
        local new_pids=()
        local new_files=()
        local new_logs=()

        local idx=0
        while [[ $idx -lt ${#pids[@]} ]]; do
            local pid="${pids[$idx]}"
            local file="${pid_files[$idx]}"
            local item_log="${pid_logs[$idx]}"
            local item_basename
            item_basename=$(basename "$file" .md)

            if ! kill -0 "$pid" 2>/dev/null; then
                # Process finished — collect exit code
                wait "$pid" 2>/dev/null
                local ec=$?

                if [[ $ec -eq 0 ]]; then
                    succeeded=$((succeeded + 1))
                    succeeded_items+=("$file")
                    log_info "Completed: $item_basename"
                elif [[ $ec -eq 2 ]]; then
                    merge_conflicts=$((merge_conflicts + 1))
                    conflict_items+=("$file")
                    log_error "Merge conflict: $item_basename (log: $item_log)"
                else
                    failed=$((failed + 1))
                    failed_items+=("$file")
                    log_error "Failed (exit $ec): $item_basename (log: $item_log)"
                fi

                # Fill the slot with next queued item
                if [[ $queue_idx -lt $total ]]; then
                    local next_entry="${items[$queue_idx]}"
                    local next_file="${next_entry#*:}"
                    local next_basename
                    next_basename=$(basename "$next_file" .md)
                    local next_log="$log_dir/${next_basename}.log"

                    log_info "Starting [$((queue_idx + 1))/$total]: $next_basename"

                    "$RUN_PDLC" --worktree --trunk --from "$from_phase" --through "$through_phase" \
                        --lock --cleanup-on-failure --log-dir "$log_dir" "$next_file" \
                        >"$next_log" 2>&1 &

                    new_pids+=($!)
                    new_files+=("$next_file")
                    new_logs+=("$next_log")

                    queue_idx=$((queue_idx + 1))
                fi
            else
                # Still running — keep in active list
                new_pids+=("$pid")
                new_files+=("$file")
                new_logs+=("$item_log")
            fi

            idx=$((idx + 1))
        done

        pids=("${new_pids[@]+"${new_pids[@]}"}")
        pid_files=("${new_files[@]+"${new_files[@]}"}")
        pid_logs=("${new_logs[@]+"${new_logs[@]}"}")

        # Avoid busy-wait
        if [[ ${#pids[@]} -gt 0 ]]; then
            sleep 5
        fi
    done

    # Print summary
    print_parallel_summary "$succeeded" "$failed" "$merge_conflicts" "$start_time" "$log_dir" \
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

print_parallel_summary() {
    local succeeded="$1"
    local failed="$2"
    local conflicts="$3"
    local start_time="$4"
    local log_dir="$5"
    shift 5

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
    log_info "Logs:            $log_dir/"

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
            log_info "  $item_basename → $log_dir/${item_basename}.log"
        done
    fi

    if [[ ${#conflict_items[@]} -gt 0 ]]; then
        log_info ""
        log_info "Merge conflicts:"
        for item in "${conflict_items[@]}"; do
            local item_basename
            item_basename=$(basename "$item" .md)
            log_info "  $item_basename → $log_dir/${item_basename}.log"
        done
    fi
}

# ─────────────────────────────────────────────
# Discover subcommand
# ─────────────────────────────────────────────

discover_usage() {
    cat >&2 <<'EOF'
Usage: run-batch.sh discover [OPTIONS] [TOPIC...]

Run discovery and shaping on a list of topics.

Topics can be provided as positional arguments or via --topics-file.

Options:
  --through <phase>      End phase (default: define)
  --topics-file <file>   Read topics from file (one per line)
  --log-dir <dir>        Log directory for run-pdlc.sh
  --continue-on-failure  Keep going when a topic fails (default: continue)
  -h, --help             Show this help
EOF
}

cmd_discover() {
    local through_phase="define"
    local topics_file=""
    local log_dir=""
    local continue_on_failure="true"  # Default: continue for discover
    local topics=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --through)           through_phase="$2"; shift 2 ;;
            --topics-file)       topics_file="$2"; shift 2 ;;
            --log-dir)           log_dir="$2"; shift 2 ;;
            --stop-on-failure)   continue_on_failure="false"; shift ;;
            -h|--help)           discover_usage; exit 0 ;;
            -*)                  log_error "Unknown option: $1"; discover_usage; exit 3 ;;
            *)                   topics+=("$1"); shift ;;
        esac
    done

    # Load topics from file if specified
    if [[ -n "$topics_file" ]]; then
        if [[ ! -f "$topics_file" ]]; then
            log_error "Topics file not found: $topics_file"
            exit 3
        fi
        while IFS= read -r line || [[ -n "$line" ]]; do
            # Skip empty lines and comments
            [[ -z "$line" || "$line" =~ ^# ]] && continue
            topics+=("$line")
        done < "$topics_file"
    fi

    if [[ ${#topics[@]} -eq 0 ]]; then
        log_error "No topics provided. Pass topics as arguments or use --topics-file."
        discover_usage
        exit 3
    fi

    log_info "Queued ${#topics[@]} topic(s) for discovery:"
    for topic in "${topics[@]}"; do
        log_info "  - $topic"
    done

    # Execute each topic
    local succeeded=0
    local failed=0
    local failed_items=()
    local start_time
    start_time=$(date +%s)

    for topic in "${topics[@]}"; do
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "Discovering: $topic"
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local pdlc_args=(--through "$through_phase" --lock)
        if [[ -n "$log_dir" ]]; then
            pdlc_args+=(--log-dir "$log_dir")
        fi
        pdlc_args+=("$topic")

        if "$RUN_PDLC" "${pdlc_args[@]}"; then
            succeeded=$((succeeded + 1))
            log_info "Completed: $topic"
        else
            local ec=$?
            failed=$((failed + 1))
            failed_items+=("$topic")
            log_error "Failed (exit $ec): $topic"

            if [[ "$continue_on_failure" != "true" ]]; then
                log_error "Stopping batch."
                print_summary "$succeeded" "$failed" "$start_time" "${failed_items[@]}"
                exit 2
            fi
        fi
    done

    print_summary "$succeeded" "$failed" "$start_time" "${failed_items[@]}"

    if [[ $failed -gt 0 ]]; then
        exit 1
    fi
    exit 0
}

# ─────────────────────────────────────────────
# Shared helpers
# ─────────────────────────────────────────────

print_summary() {
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

# ─────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────

usage() {
    cat >&2 <<'EOF'
Usage: run-batch.sh <subcommand> [OPTIONS]

Batch runner for overnight autonomous execution.

Subcommands:
  deliver     Run delivery on designed backlog items
  discover    Run discovery+shaping on a list of topics

Run 'run-batch.sh <subcommand> --help' for subcommand options.

Examples:
  # Deliver all designed items
  run-batch.sh deliver --log-dir logs/overnight

  # Deliver only P1 and P2 items
  run-batch.sh deliver --priority P1 --priority P2

  # Preview what would run
  run-batch.sh deliver --dry-run

  # Deliver with trunk-based mode (no PRs)
  run-batch.sh deliver --trunk --log-dir logs/overnight

  # Deliver 3 items in parallel (implies worktree + trunk)
  run-batch.sh deliver --parallel 3 --log-dir logs/overnight

  # Discover several topics overnight
  run-batch.sh discover --log-dir logs/overnight \
    "add user preferences page" \
    "improve CLI error messages" \
    "add export to PDF"

  # Discover topics from a file
  run-batch.sh discover --topics-file topics.txt
EOF
}

main() {
    if [[ $# -eq 0 ]]; then
        usage
        exit 3
    fi

    local subcommand="$1"
    shift

    case "$subcommand" in
        deliver)  cmd_deliver "$@" ;;
        discover) cmd_discover "$@" ;;
        help|-h|--help) usage; exit 0 ;;
        *)
            log_error "Unknown subcommand: $subcommand"
            usage
            exit 3
            ;;
    esac
}

main "$@"
