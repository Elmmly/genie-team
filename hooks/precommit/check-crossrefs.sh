#!/bin/bash
# Tier 3: Check cross-reference integrity in frontmatter
# Validates that spec_ref, adr_refs, backlog_ref, etc. point to existing files.
# Input: file paths as positional arguments (pre-commit convention)
# Exit: 0 if all refs resolve, 1 if any broken

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
errors=0

# Single-path reference fields
SINGLE_REF_FIELDS="spec_ref backlog_ref design_ref execution_ref"

# Extract frontmatter from a file
extract_frontmatter() {
    local file="$1"
    local first_line
    first_line=$(head -1 "$file")
    if [[ "$first_line" != "---" ]]; then
        return 1
    fi
    local close_line
    close_line=$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$file")
    if [[ -z "$close_line" ]]; then
        return 1
    fi
    sed -n "2,$((close_line - 1))p" "$file"
}

# Get a simple scalar value from frontmatter
get_field() {
    local frontmatter="$1"
    local field="$2"
    local line
    line=$(echo "$frontmatter" | grep -E "^${field}:" | head -1) || true
    if [[ -n "$line" ]]; then
        echo "$line" | sed "s/^${field}:[[:space:]]*//" | sed 's/^["'"'"']//' | sed 's/["'"'"']$//'
    fi
}

# Get array values from frontmatter (YAML list items: "  - value")
get_array_field() {
    local frontmatter="$1"
    local field="$2"
    local in_field=0
    while IFS= read -r line; do
        if [[ "$line" =~ ^${field}: ]]; then
            in_field=1
            continue
        fi
        if [[ $in_field -eq 1 ]]; then
            if [[ "$line" =~ ^[[:space:]]*-[[:space:]]+(.*) ]]; then
                echo "${BASH_REMATCH[1]}" | sed 's/^["'"'"']//' | sed 's/["'"'"']$//'
            else
                break  # No longer in array
            fi
        fi
    done <<< "$frontmatter"
}

# Check if a file exists relative to repo root
check_ref() {
    local file="$1"
    local field="$2"
    local ref_path="$3"

    if [[ -z "$ref_path" ]]; then
        return 0
    fi

    local full_path="$REPO_ROOT/$ref_path"
    if [[ ! -f "$full_path" ]]; then
        echo "[TIER-3] $file — $field '$ref_path' not found" >&2
        echo "  → Check the path or remove the reference" >&2
        errors=$((errors + 1))
    fi
}

for file in "$@"; do
    [[ -f "$file" ]] || continue

    # Extract frontmatter — skip if none
    frontmatter=$(extract_frontmatter "$file") || continue
    [[ -z "$frontmatter" ]] && continue

    # Check single-path reference fields
    for field in $SINGLE_REF_FIELDS; do
        ref_value=$(get_field "$frontmatter" "$field")
        if [[ -n "$ref_value" ]]; then
            check_ref "$file" "$field" "$ref_value"
        fi
    done

    # Check adr_refs array
    while IFS= read -r adr_ref; do
        [[ -z "$adr_ref" ]] && continue
        check_ref "$file" "adr_refs" "$adr_ref"
    done < <(get_array_field "$frontmatter" "adr_refs")

    # Check spec_refs array (used in ADRs)
    while IFS= read -r spec_ref; do
        [[ -z "$spec_ref" ]] && continue
        check_ref "$file" "spec_refs" "$spec_ref"
    done < <(get_array_field "$frontmatter" "spec_refs")
done

if [[ $errors -gt 0 ]]; then
    exit 1
fi
exit 0
