#!/bin/bash
# Tier 2: Validate frontmatter schema — required fields and enum values
# Input: file paths as positional arguments (pre-commit convention)
# Exit: 0 if all valid, 1 if any violations
# Compatible with bash 3.2+ (macOS default)

set -euo pipefail

errors=0

# Schema lookup — returns required fields for a document type
required_fields_for() {
    case "$1" in
        shaped-work)         echo "spec_version type id title status created appetite" ;;
        adr)                 echo "adr_version type id title status created deciders" ;;
        architecture-diagram) echo "diagram_version type level title updated updated_by" ;;
        brand-spec)          echo "spec_version type brand_name status identity visual" ;;
        *)                   echo "" ;;  # Unknown type — no validation
    esac
}

# Enum lookup — returns valid values (pipe-separated) for a type:field pair
valid_enum_values() {
    local doc_type="$1"
    local field="$2"
    case "${doc_type}:${field}" in
        shaped-work:status)          echo "shaped|designed|implemented|reviewed|done|abandoned" ;;
        shaped-work:appetite)        echo "small|medium|big" ;;
        adr:status)                  echo "proposed|accepted|deprecated|superseded" ;;
        architecture-diagram:level)  echo "1|2|3" ;;
        brand-spec:status)           echo "draft|active|deprecated" ;;
        *)                           echo "" ;;  # No enum constraint
    esac
}

# Fields that have enum constraints, by type
enum_fields_for() {
    case "$1" in
        shaped-work)          echo "status appetite" ;;
        adr)                  echo "status" ;;
        architecture-diagram) echo "level" ;;
        brand-spec)           echo "status" ;;
        *)                    echo "" ;;
    esac
}

# Extract frontmatter from a file (between first --- and second ---)
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

# Get a simple scalar value from frontmatter text
get_field() {
    local frontmatter="$1"
    local field="$2"
    local line
    line=$(echo "$frontmatter" | grep -E "^${field}:" | head -1) || true
    if [[ -n "$line" ]]; then
        echo "$line" | sed "s/^${field}:[[:space:]]*//" | sed 's/^["'"'"']//' | sed 's/["'"'"']$//' | tr -d ' '
    fi
}

# Check if a field exists in frontmatter (including array/object fields)
has_field() {
    local frontmatter="$1"
    local field="$2"
    echo "$frontmatter" | grep -qE "^${field}:"
}

for file in "$@"; do
    [[ -f "$file" ]] || continue

    # Extract frontmatter — skip if none
    frontmatter=$(extract_frontmatter "$file") || continue
    [[ -z "$frontmatter" ]] && continue

    # Get document type
    doc_type=$(get_field "$frontmatter" "type")
    if [[ -z "$doc_type" ]]; then
        continue  # No type field — skip
    fi

    # Get required fields for this type
    required=$(required_fields_for "$doc_type")
    if [[ -z "$required" ]]; then
        continue  # Unknown type — skip silently
    fi

    # Check required fields
    for field in $required; do
        if ! has_field "$frontmatter" "$field"; then
            echo "[TIER-2] $file — missing required field '$field' for type '$doc_type'" >&2
            echo "  → Add '$field' to frontmatter" >&2
            errors=$((errors + 1))
        fi
    done

    # Check enum values
    for field in $(enum_fields_for "$doc_type"); do
        value=$(get_field "$frontmatter" "$field")
        if [[ -n "$value" ]]; then
            valid=$(valid_enum_values "$doc_type" "$field")
            if [[ -n "$valid" ]] && ! echo "$value" | grep -qE "^(${valid})$"; then
                echo "[TIER-2] $file — invalid value '$value' for field '$field'" >&2
                echo "  → Valid values: ${valid//|/, }" >&2
                errors=$((errors + 1))
            fi
        fi
    done
done

if [[ $errors -gt 0 ]]; then
    exit 1
fi
exit 0
