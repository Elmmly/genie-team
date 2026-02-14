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

# Map backlog item status to the next phase to run
# Usage: status_to_phase <status>
status_to_phase() {
    local status="$1"
    case "$status" in
        shaped)       echo "design" ;;
        designed)     echo "deliver" ;;
        implemented)  echo "discern" ;;
        reviewed)     echo "commit" ;;
        *)            echo "" ;;  # unknown/done/abandoned — skip
    esac
}

# ─────────────────────────────────────────────
# Deliver subcommand
# ─────────────────────────────────────────────

deliver_usage() {
    cat >&2 <<'EOF'
Usage: run-batch.sh deliver [OPTIONS] [ITEM...]

Run lifecycle phases on backlog items. By default finds all actionable
items (shaped/designed/implemented/reviewed) and auto-detects the starting
phase from each item's status. Specific items can be passed as arguments.

Options:
  --priority P1|P2|P3    Filter by priority (repeatable)
  --from <phase>         Override start phase (default: auto-detect from status)
  --through <phase>      End phase (default: done)
  --log-dir <dir>        Log directory for run-pdlc.sh
  --verbose              Write full claude session traces to log dir
  --continue-on-failure  Keep going when an item fails (default: stop)
  --trunk                Use trunk-based mode (commit to main, no PRs)
  --parallel N           Run N items concurrently (implies --worktree)
  --dry-run              List matching items without executing
  -h, --help             Show this help
EOF
}

cmd_deliver() {
    local priorities=()
    local from_phase=""
    local through_phase="done"
    local log_dir=""
    local continue_on_failure="false"
    local dry_run="false"
    local trunk_mode="false"
    local parallel_jobs=0
    local verbose_mode="false"
    local explicit_items=()

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --priority)          priorities+=("$2"); shift 2 ;;
            --from)              from_phase="$2"; shift 2 ;;
            --through)           through_phase="$2"; shift 2 ;;
            --log-dir)           log_dir="$2"; shift 2 ;;
            --verbose)           verbose_mode="true"; shift ;;
            --continue-on-failure) continue_on_failure="true"; shift ;;
            --trunk)             trunk_mode="true"; shift ;;
            --parallel)          parallel_jobs="$2"; shift 2 ;;
            --dry-run)           dry_run="true"; shift ;;
            -h|--help)           deliver_usage; exit 0 ;;
            -*)                  log_error "Unknown option: $1"; deliver_usage; exit 3 ;;
            *)                   explicit_items+=("$1"); shift ;;
        esac
    done

    # --parallel implies --worktree (branches are left for serialized integration)
    # trunk_mode is independent — determines integration strategy (merge vs PR)

    # Build item list: explicit items or auto-discover from backlog
    # Format: "priority:phase:file" (phase is auto-detected or overridden)
    local items=()

    if [[ ${#explicit_items[@]} -gt 0 ]]; then
        # Explicit items passed as arguments
        for file in "${explicit_items[@]}"; do
            if [[ ! -f "$file" ]]; then
                log_error "Item not found: $file"
                exit 3
            fi
            local status priority item_phase
            status=$(get_frontmatter_field "$file" "status")
            priority=$(get_frontmatter_field "$file" "priority")
            item_phase="${from_phase:-$(status_to_phase "$status")}"
            if [[ -z "$item_phase" ]]; then
                log_info "Skipping $file (status: $status — not actionable)"
                continue
            fi
            items+=("$priority:$item_phase:$file")
        done
    else
        # Auto-discover from backlog
        local backlog_dir="docs/backlog"

        if [[ ! -d "$backlog_dir" ]]; then
            log_error "Backlog directory not found: $backlog_dir"
            exit 3
        fi

        for file in "$backlog_dir"/*.md; do
            [[ -f "$file" ]] || continue

            local status priority item_phase
            status=$(get_frontmatter_field "$file" "status")
            priority=$(get_frontmatter_field "$file" "priority")

            # Auto-detect starting phase from status (skip done/abandoned)
            item_phase="${from_phase:-$(status_to_phase "$status")}"
            [[ -n "$item_phase" ]] || continue

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

            items+=("$priority:$item_phase:$file")
        done
    fi

    # Sort by priority (P1 < P2 < P3)
    local sorted
    sorted=$(printf '%s\n' "${items[@]}" | sort)
    items=()
    while IFS= read -r line; do
        items+=("$line")
    done <<< "$sorted"

    if [[ ${#items[@]} -eq 0 ]]; then
        log_info "No actionable backlog items found matching filters."
        exit 0
    fi

    log_info "Found ${#items[@]} actionable item(s):"
    for entry in "${items[@]}"; do
        # Format: priority:phase:file
        local file="${entry#*:}" # phase:file
        file="${file#*:}"        # file
        local item_phase="${entry#*:}"
        item_phase="${item_phase%%:*}"
        local title
        title=$(get_frontmatter_field "$file" "title")
        log_info "  $(basename "$file"): $title (from: $item_phase)"
    done

    if [[ "$dry_run" == "true" ]]; then
        if [[ "$parallel_jobs" -gt 0 && "$trunk_mode" == "true" ]]; then
            log_info "Mode: parallel ($parallel_jobs workers, trunk-based, worktrees)"
        elif [[ "$parallel_jobs" -gt 0 ]]; then
            log_info "Mode: parallel ($parallel_jobs workers, PR-based, worktrees)"
        elif [[ "$trunk_mode" == "true" ]]; then
            log_info "Mode: sequential (trunk-based)"
        else
            log_info "Mode: sequential"
        fi
        if [[ "$verbose_mode" == "true" ]]; then
            log_info "Verbose logging: enabled"
        fi
        log_info "(dry run — not executing)"
        exit 0
    fi

    # Dispatch to parallel or sequential execution
    if [[ "$parallel_jobs" -gt 0 ]]; then
        deliver_parallel "$parallel_jobs" "$through_phase" "$log_dir" "$verbose_mode" "$trunk_mode" "${items[@]}"
        return $?
    fi

    # Execute each item sequentially
    local succeeded=0
    local failed=0
    local failed_items=()
    local start_time
    start_time=$(date +%s)

    for entry in "${items[@]}"; do
        # Parse priority:phase:file
        local file="${entry#*:}"
        file="${file#*:}"
        local item_phase="${entry#*:}"
        item_phase="${item_phase%%:*}"
        local title
        title=$(get_frontmatter_field "$file" "title")

        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
        log_info "Running: $title ($item_phase → $through_phase)"
        log_info "Item: $file"
        log_info "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"

        local pdlc_args=(--from "$item_phase" --through "$through_phase" --lock)
        if [[ "$trunk_mode" == "true" ]]; then
            pdlc_args+=(--trunk)
        fi
        if [[ "$verbose_mode" == "true" ]]; then
            pdlc_args+=(--verbose)
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
    local through_phase="$2"
    local log_dir="$3"
    local verbose_mode="$4"
    local trunk_mode="$5"
    shift 5
    local items=("$@")

    # Ensure log dir exists for per-item logs
    if [[ -z "$log_dir" ]]; then
        log_dir="logs/batch-$(date +%Y%m%d-%H%M%S)"
    fi
    mkdir -p "$log_dir"

    log_info "Parallel mode: ${#items[@]} items, $max_jobs workers"
    log_info "Log directory: $log_dir"
    if [[ "$verbose_mode" == "true" ]]; then
        log_info "Verbose logging: enabled"
    fi

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

    # Helper: parse entry and launch worker
    _launch_worker() {
        local entry="$1"
        local item_idx="$2"
        # Parse priority:phase:file
        local item_phase="${entry#*:}"
        item_phase="${item_phase%%:*}"
        local file="${entry#*:}"
        file="${file#*:}"
        local item_basename
        item_basename=$(basename "$file" .md)
        local item_log="$log_dir/${item_basename}.log"

        log_info "Starting [$item_idx/$total]: $item_basename ($item_phase → $through_phase)"

        local pdlc_args=(--worktree --finish-mode --leave-branch --from "$item_phase" --through "$through_phase"
            --lock --cleanup-on-failure --log-dir "$log_dir")
        if [[ "$trunk_mode" == "true" ]]; then
            pdlc_args+=(--trunk)
        fi
        if [[ "$verbose_mode" == "true" ]]; then
            pdlc_args+=(--verbose)
        fi
        pdlc_args+=("$file")

        "$RUN_PDLC" "${pdlc_args[@]}" >"$item_log" 2>&1 &

        # Return values via stdout (caller captures)
        echo "$!:$file:$item_log"
    }

    # Launch initial batch of workers
    while [[ $queue_idx -lt $total && ${#pids[@]} -lt $max_jobs ]]; do
        local worker_info
        worker_info=$(_launch_worker "${items[$queue_idx]}" "$((queue_idx + 1))")
        pids+=("${worker_info%%:*}")
        local rest="${worker_info#*:}"
        pid_files+=("${rest%%:*}")
        pid_logs+=("${rest#*:}")

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
                    local worker_info
                    worker_info=$(_launch_worker "${items[$queue_idx]}" "$((queue_idx + 1))")
                    new_pids+=("${worker_info%%:*}")
                    local rest="${worker_info#*:}"
                    new_files+=("${rest%%:*}")
                    new_logs+=("${rest#*:}")

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

    # ── Integration phase: serialize merges/PRs ──
    if [[ ${#succeeded_items[@]} -gt 0 ]]; then
        log_info "Integration phase: ${#succeeded_items[@]} items to integrate"

        # Source genie-session.sh for integrate functions
        source "$SCRIPT_DIR/genie-session.sh"

        local integrate_idx=0
        while [[ $integrate_idx -lt ${#succeeded_items[@]} ]]; do
            local file="${succeeded_items[$integrate_idx]}"
            local item_slug
            item_slug=$(basename "$file" .md)
            log_info "Integrating: $item_slug"

            if [[ "$trunk_mode" == "true" ]]; then
                if session_integrate_trunk "$item_slug"; then
                    log_info "Merged to trunk: $item_slug"
                else
                    local ec=$?
                    if [[ $ec -eq 2 ]]; then
                        merge_conflicts=$((merge_conflicts + 1))
                        conflict_items+=("$file")
                        log_error "Rebase conflict: $item_slug"
                    else
                        failed=$((failed + 1))
                        failed_items+=("$file")
                        log_error "Integration failed: $item_slug"
                    fi
                    succeeded=$((succeeded - 1))
                fi
            else
                if session_integrate_pr "$item_slug"; then
                    log_info "PR created: $item_slug"
                else
                    failed=$((failed + 1))
                    failed_items+=("$file")
                    log_error "PR creation failed: $item_slug"
                    succeeded=$((succeeded - 1))
                fi
            fi

            integrate_idx=$((integrate_idx + 1))
        done
    fi

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
  # Run all actionable items (auto-detects phase from status)
  run-batch.sh deliver --log-dir logs/overnight

  # Only P1 and P2 items
  run-batch.sh deliver --priority P1 --priority P2

  # Preview what would run
  run-batch.sh deliver --dry-run

  # Run specific items (pick up from their current stage)
  run-batch.sh deliver --parallel 2 --verbose \
    docs/backlog/P2-item-a.md docs/backlog/P2-item-b.md

  # Deliver 3 items in parallel with verbose traces
  run-batch.sh deliver --parallel 3 --verbose --log-dir logs/overnight

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
