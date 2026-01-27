#!/bin/bash
# Headless execution wrapper for spec-driven genie-team execution
# Validates spec + design frontmatter, invokes Claude headlessly, produces execution report
#
# Usage: execute.sh --spec <path> --design <path> --repo <path> [options]
#
# Exit codes:
#   0  Success (all AC met)
#   1  Partial (some AC not met, code committed)
#   2  Failed (execution failed, no commit)
#   3  Blocked (input validation failure, cannot proceed)

# Only set strict mode when running directly (not sourced for testing)
if [[ "${EXECUTE_SOURCED:-false}" != "true" ]]; then
    set -euo pipefail
fi

# ─────────────────────────────────────────────
# Logging
# ─────────────────────────────────────────────

log_info()  { echo "[INFO]  $*" >&2; }
log_error() { echo "[ERROR] $*" >&2; }
log_debug() { [[ "${VERBOSE:-false}" == "true" ]] && echo "[DEBUG] $*" >&2 || true; }

# ─────────────────────────────────────────────
# Frontmatter Parsing
# ─────────────────────────────────────────────

# Extract YAML frontmatter from a markdown file (content between --- delimiters)
# Usage: extract_frontmatter <file_path>
# Returns: frontmatter text (without delimiters), or empty string if none found
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
                # End of frontmatter
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

    # If we never found a closing ---, return empty
    echo ""
}

# Get a single top-level field value from frontmatter text
# Usage: get_field <frontmatter_text> <field_name>
# Returns: field value (quotes stripped), or empty string if not found
get_field() {
    local frontmatter="$1"
    local field="$2"

    local value
    value=$(echo "$frontmatter" | grep -E "^${field}:" | head -1 | sed "s/^${field}:[[:space:]]*//" | sed 's/^"//;s/"$//' | sed "s/^'//;s/'$//" | xargs)

    echo "$value"
}

# ─────────────────────────────────────────────
# Validation
# ─────────────────────────────────────────────

# Validate a spec file has required shaped-work frontmatter fields
# Usage: validate_spec <file_path>
# Returns: 0 on success, 1 on failure (with error messages on stderr)
validate_spec() {
    local file="$1"
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        log_error "No frontmatter found in spec: $file"
        return 1
    fi

    local errors=0

    # Check type field
    local type_val
    type_val=$(get_field "$frontmatter" "type")
    if [[ -z "$type_val" ]]; then
        log_error "Missing required field 'type' in spec: $file"
        ((errors++))
    elif [[ "$type_val" != "shaped-work" ]]; then
        log_error "Invalid type '$type_val' in spec (expected 'shaped-work'): $file"
        ((errors++))
    fi

    # Check required fields
    for field in spec_version id title status created appetite; do
        local val
        val=$(get_field "$frontmatter" "$field")
        if [[ -z "$val" ]]; then
            log_error "Missing required field '$field' in spec: $file"
            ((errors++))
        fi
    done

    # Check acceptance_criteria exists
    if ! echo "$frontmatter" | grep -q "^acceptance_criteria:"; then
        log_error "Missing required field 'acceptance_criteria' in spec: $file"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        return 1
    fi
    return 0
}

# Validate a design file has required design frontmatter fields
# Usage: validate_design <file_path>
# Returns: 0 on success, 1 on failure (with error messages on stderr)
validate_design() {
    local file="$1"
    local frontmatter
    frontmatter=$(extract_frontmatter "$file")

    if [[ -z "$frontmatter" ]]; then
        log_error "No frontmatter found in design: $file"
        return 1
    fi

    local errors=0

    # Check type field
    local type_val
    type_val=$(get_field "$frontmatter" "type")
    if [[ -z "$type_val" ]]; then
        log_error "Missing required field 'type' in design: $file"
        ((errors++))
    elif [[ "$type_val" != "design" ]]; then
        log_error "Invalid type '$type_val' in design (expected 'design'): $file"
        ((errors++))
    fi

    # Check required fields
    for field in spec_version id title created spec_ref; do
        local val
        val=$(get_field "$frontmatter" "$field")
        if [[ -z "$val" ]]; then
            log_error "Missing required field '$field' in design: $file"
            ((errors++))
        fi
    done

    # Check ac_mapping exists
    if ! echo "$frontmatter" | grep -q "^ac_mapping:"; then
        log_error "Missing required field 'ac_mapping' in design: $file"
        ((errors++))
    fi

    if [[ $errors -gt 0 ]]; then
        return 1
    fi
    return 0
}

# ─────────────────────────────────────────────
# Branch & Prompt
# ─────────────────────────────────────────────

# Generate a git branch name from spec id and title
# Usage: generate_branch_name <id> <title>
# Returns: feat/{id}-{title-slug} (lowercase, alphanumeric + hyphens)
generate_branch_name() {
    local id="$1"
    local title="$2"

    # Lowercase, replace non-alphanumeric with hyphens, collapse multiple hyphens, strip trailing
    local slug
    slug=$(echo "$title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/-$//')

    local branch_id
    branch_id=$(echo "$id" | tr '[:upper:]' '[:lower:]')

    echo "feat/${branch_id}-${slug}"
}

# Build the headless prompt for Claude invocation
# Usage: build_prompt <spec_path> <design_path>
# Returns: prompt text incorporating spec, design, and execution report instructions
build_prompt() {
    local spec_path="$1"
    local design_path="$2"

    local spec_content
    spec_content=$(cat "$spec_path")

    local design_content
    design_content=$(cat "$design_path")

    cat <<PROMPT
You are the Crafter genie operating in headless execution mode.

## Spec (Shaped Work Contract)

$spec_content

## Design

$design_content

## Instructions

1. Read the acceptance_criteria from the spec frontmatter above.
2. Follow the design to implement all acceptance criteria using TDD (Red-Green-Refactor).
3. Tag each test with the ac_id of the acceptance criterion it verifies.
4. After implementation, produce an execution report as your final output.

## Required Output: Execution Report

Your final output MUST be a markdown document with YAML frontmatter following the
execution-report schema. The frontmatter must include:

- spec_version: "1.0"
- type: execution-report
- id, title (from spec)
- status: complete | partial | failed | blocked
- files_changed, test_results (with ac_id per test), acceptance_criteria verdicts

The execution report is the ONLY output. Do not include conversational text outside the report.
PROMPT
}

# ─────────────────────────────────────────────
# Report Extraction
# ─────────────────────────────────────────────

# Extract execution report from Claude output
# Finds the report by looking for frontmatter containing type: execution-report
# Usage: echo "$output" | extract_report
# Returns: the report (frontmatter + body), or empty string if not found
extract_report() {
    local input
    input=$(cat)

    # Look for --- that starts report frontmatter containing execution-report
    local in_frontmatter=false
    local found_report=false
    local frontmatter_buf=""
    local result=""
    local past_frontmatter=false

    while IFS= read -r line || [[ -n "$line" ]]; do
        if [[ "$line" == "---" && "$found_report" == "false" && "$in_frontmatter" == "false" ]]; then
            in_frontmatter=true
            frontmatter_buf="---"$'\n'
            continue
        fi

        if [[ "$in_frontmatter" == "true" && "$found_report" == "false" ]]; then
            if [[ "$line" == "---" ]]; then
                # End of a frontmatter block — check if it's an execution report
                if echo "$frontmatter_buf" | grep -q "type: execution-report"; then
                    found_report=true
                    past_frontmatter=true
                    result="${frontmatter_buf}---"$'\n'
                else
                    # Not the right frontmatter, reset
                    in_frontmatter=false
                    frontmatter_buf=""
                fi
            else
                frontmatter_buf="${frontmatter_buf}${line}"$'\n'
            fi
            continue
        fi

        if [[ "$found_report" == "true" ]]; then
            result="${result}${line}"$'\n'
        fi
    done <<< "$input"

    if [[ "$found_report" == "true" ]]; then
        # Output result, trimming trailing blank lines
        printf '%s\n' "$result" | sed -e '/^[[:space:]]*$/{ :a; N; /^[[:space:]]*$/ba; }' 2>/dev/null || printf '%s\n' "$result"
    else
        echo ""
    fi
}

# ─────────────────────────────────────────────
# Exit Code Mapping
# ─────────────────────────────────────────────

# Map execution report status to exit code
# Usage: get_exit_code_from_status <status>
# Returns: 0 (complete), 1 (partial), 2 (failed), 3 (blocked)
get_exit_code_from_status() {
    local status="$1"

    case "$status" in
        complete) echo "0" ;;
        partial)  echo "1" ;;
        failed)   echo "2" ;;
        blocked)  echo "3" ;;
        *)        echo "2" ;;
    esac
}

# ─────────────────────────────────────────────
# Main CLI
# ─────────────────────────────────────────────

main() {
    local spec_path=""
    local design_path=""
    local repo_path=""
    local branch_override=""
    local report_path=""
    local dry_run="false"
    local model=""
    VERBOSE="false"

    while [[ $# -gt 0 ]]; do
        case "$1" in
            --spec)     spec_path="$2"; shift 2 ;;
            --design)   design_path="$2"; shift 2 ;;
            --repo)     repo_path="$2"; shift 2 ;;
            --branch)   branch_override="$2"; shift 2 ;;
            --report)   report_path="$2"; shift 2 ;;
            --dry-run)  dry_run="true"; shift ;;
            --verbose)  VERBOSE="true"; shift ;;
            --model)    model="$2"; shift 2 ;;
            -h|--help)
                echo "Usage: execute.sh --spec <path> --design <path> --repo <path> [options]"
                echo ""
                echo "Options:"
                echo "  --branch NAME       Override branch name"
                echo "  --dry-run           Validate inputs only"
                echo "  --report PATH       Override report output path"
                echo "  --verbose           Detailed stderr logging"
                echo "  --model MODEL       Override Claude model"
                exit 0
                ;;
            *)
                log_error "Unknown argument: $1"
                exit 3
                ;;
        esac
    done

    # Validate required arguments
    if [[ -z "$spec_path" ]]; then
        log_error "Missing required argument: --spec"
        exit 3
    fi

    if [[ -z "$design_path" ]]; then
        log_error "Missing required argument: --design"
        exit 3
    fi

    if [[ -z "$repo_path" ]]; then
        log_error "Missing required argument: --repo"
        exit 3
    fi

    # Validate files exist
    if [[ ! -f "$spec_path" ]]; then
        log_error "Spec file not found: $spec_path"
        exit 3
    fi

    if [[ ! -f "$design_path" ]]; then
        log_error "Design file not found: $design_path"
        exit 3
    fi

    # Validate spec frontmatter
    log_debug "Validating spec: $spec_path"
    if ! validate_spec "$spec_path"; then
        log_error "Spec validation failed"
        exit 3
    fi

    # Validate design frontmatter
    log_debug "Validating design: $design_path"
    if ! validate_design "$design_path"; then
        log_error "Design validation failed"
        exit 3
    fi

    # Extract spec metadata
    local frontmatter
    frontmatter=$(extract_frontmatter "$spec_path")
    local spec_id
    spec_id=$(get_field "$frontmatter" "id")
    local spec_title
    spec_title=$(get_field "$frontmatter" "title")

    log_info "Spec: $spec_id — $spec_title"

    # Determine branch name
    local branch
    if [[ -n "$branch_override" ]]; then
        branch="$branch_override"
    else
        branch=$(generate_branch_name "$spec_id" "$spec_title")
    fi
    log_debug "Branch: $branch"

    # Dry-run: validate only (skip repo and execution)
    if [[ "$dry_run" == "true" ]]; then
        log_info "Dry run — validation passed"
        echo "id: $spec_id"
        echo "title: $spec_title"
        echo "branch: $branch"
        echo "status: valid"
        exit 0
    fi

    # Full execution requires repo directory
    if [[ ! -d "$repo_path" ]]; then
        log_error "Repository not found: $repo_path"
        exit 3
    fi

    log_info "Starting headless execution in $repo_path"

    # Check for clean working tree
    cd "$repo_path"
    if [[ -n "$(git status --porcelain 2>/dev/null)" ]]; then
        log_error "Working tree is not clean in $repo_path"
        log_error "Commit or stash changes before headless execution"
        exit 3
    fi

    # Create branch
    log_debug "Creating branch: $branch"
    git checkout -b "$branch" 2>/dev/null || git checkout "$branch" 2>/dev/null || {
        log_error "Failed to create or switch to branch: $branch"
        exit 2
    }

    # Build prompt
    local prompt
    prompt=$(build_prompt "$spec_path" "$design_path")

    # Invoke Claude headlessly
    log_info "Invoking Claude headlessly..."
    local claude_output
    local allowed_tools="Read,Write,Edit,Bash,Glob,Grep"

    local claude_args=(-p "$prompt" --allowedTools "$allowed_tools")
    if [[ -n "$model" ]]; then
        claude_args+=(--model "$model")
    fi

    claude_output=$(claude "${claude_args[@]}" 2>/dev/null) || {
        log_error "Claude invocation failed"
        exit 2
    }

    # Extract execution report
    log_debug "Extracting execution report..."
    local report
    report=$(echo "$claude_output" | extract_report)

    if [[ -z "$report" ]]; then
        log_error "No execution report found in Claude output"
        exit 2
    fi

    # Determine report output path
    if [[ -z "$report_path" ]]; then
        local slug
        slug=$(echo "$spec_title" | tr '[:upper:]' '[:lower:]' | sed 's/[^a-z0-9]/-/g' | sed 's/--*/-/g' | sed 's/-$//')
        report_path="docs/reports/${spec_id}-${slug}.md"
    fi

    # Write report
    mkdir -p "$(dirname "$report_path")"
    echo "$report" > "$report_path"
    log_info "Report written to: $report_path"

    # Git commit
    log_debug "Committing changes..."
    git add -A
    local commit_msg="feat(${spec_id}): ${spec_title}"
    git commit -m "$commit_msg" 2>/dev/null || {
        log_error "Git commit failed"
        exit 2
    }

    local commit_sha
    commit_sha=$(git rev-parse --short HEAD)
    log_info "Committed: $commit_sha"

    # Extract status directly from report text
    local report_status
    report_status=$(echo "$report" | grep -E "^status:" | head -1 | sed 's/^status:[[:space:]]*//')
    local exit_code
    exit_code=$(get_exit_code_from_status "$report_status")

    # Output report path
    echo "$report_path"

    exit "$exit_code"
}

# Support being sourced for testing
if [[ "${EXECUTE_SOURCED:-false}" != "true" ]]; then
    main "$@"
fi
