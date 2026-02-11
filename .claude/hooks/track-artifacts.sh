#!/bin/bash
# Hook: PostToolUse (Write) — track artifact file paths
# Appends written file paths to session state. Deduplicates. Caps at 20.
# Zero LLM cost — pure shell operations.

set -euo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

state_file="$cwd/.claude/session-state.md"

# Skip if no state file (no active command being tracked)
if [[ ! -f "$state_file" ]]; then
    exit 0
fi

# Skip empty file paths
if [[ -z "$file_path" ]]; then
    exit 0
fi

# Convert absolute path to relative
rel_path="${file_path#"$cwd"/}"

# Skip self-reference (state file itself)
if [[ "$rel_path" == ".claude/session-state.md" ]]; then
    exit 0
fi

# Skip if already tracked (dedup)
if grep -qF -- "- $rel_path" "$state_file" 2>/dev/null; then
    exit 0
fi

# Count current artifact entries
artifact_count=$(grep -c '^- ' "$state_file" 2>/dev/null) || artifact_count=0

# If at cap, remove the oldest entry (first artifact line)
if [[ "$artifact_count" -ge 20 ]]; then
    # Remove the first line matching "^- " after "## Artifacts Written"
    # Use sed to delete the first occurrence of a "- " line after the artifacts header
    tmp_file=$(mktemp)
    awk '
        /^## Artifacts Written/ { in_artifacts=1; print; next }
        in_artifacts && /^- / && !deleted { deleted=1; next }
        { print }
    ' "$state_file" > "$tmp_file"
    mv "$tmp_file" "$state_file"
fi

# Append the new artifact
echo "- $rel_path" >> "$state_file"

exit 0
