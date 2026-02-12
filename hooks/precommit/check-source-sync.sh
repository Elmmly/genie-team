#!/bin/bash
# Tier 4: Check source/installed copy sync
# Validates that installed copies match their canonical source files.
# Input: file paths as positional arguments (pre-commit convention)
# Exit: 0 if all synced, 1 if any drift detected

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
errors=0

# Sync mapping: installed_prefix → canonical_source_prefix
# Format: "installed_prefix:source_prefix"
# Override by setting GENIE_SYNC_MAP environment variable (colon-separated pairs, semicolon between entries)
if [[ -n "${GENIE_SYNC_MAP:-}" ]]; then
    IFS=';' read -ra SYNC_MAP <<< "$GENIE_SYNC_MAP"
else
    SYNC_MAP=(
        "dist/commands/:commands/"
        ".claude/commands/:commands/"
        ".claude/agents/:agents/"
    )
fi

# Find the canonical source for a given file path
find_source() {
    local file="$1"
    for mapping in "${SYNC_MAP[@]}"; do
        local installed_prefix="${mapping%%:*}"
        local source_prefix="${mapping#*:}"

        if [[ "$file" == ${installed_prefix}* ]]; then
            local relative="${file#$installed_prefix}"
            echo "${source_prefix}${relative}"
            return 0
        fi
    done
    return 1  # Not in sync map
}

for file in "$@"; do
    # Find canonical source for this file
    source_path=$(find_source "$file") || continue

    local_file="$REPO_ROOT/$file"
    local_source="$REPO_ROOT/$source_path"

    # Skip if source doesn't exist (might be a new file not yet in source)
    if [[ ! -f "$local_source" ]]; then
        echo "[TIER-4] $file — canonical source '$source_path' not found" >&2
        echo "  → Create '$source_path' or remove the installed copy" >&2
        errors=$((errors + 1))
        continue
    fi

    # Skip if installed copy doesn't exist (being deleted)
    [[ -f "$local_file" ]] || continue

    # Compare contents
    if ! diff -q "$local_source" "$local_file" &>/dev/null; then
        echo "[TIER-4] $file — differs from canonical source '$source_path'" >&2
        echo "  → Edit '$source_path' (source of truth), then run install.sh --sync" >&2
        errors=$((errors + 1))
    fi
done

if [[ $errors -gt 0 ]]; then
    exit 1
fi
exit 0
