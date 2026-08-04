#!/bin/bash
# Hook: PostToolUse (Write|Edit) — track artifact file paths
# Appends written/edited file paths to the Artifacts Written section of the
# session state file. Section-aware (Command History lines also start with
# "- "). Deduplicates. Caps at 20.
# Format: schemas/session-state.schema.md
# Zero LLM cost — pure shell operations.

set -uo pipefail

input=$(cat)
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty' 2>/dev/null) || file_path=""
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null) || cwd=""

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

# Lines of the Artifacts Written section only
artifact_lines() {
    awk '/^## Artifacts Written/{f=1;next} /^## /{f=0} f && /^- /' "$state_file"
}

# Skip if already tracked (dedup within the artifacts section)
if artifact_lines | grep -qxF -- "- $rel_path"; then
    exit 0
fi

# Count current artifact entries
artifact_count=$(artifact_lines | grep -c '^- ') || artifact_count=0

# If at cap, remove the oldest entry (first "- " line after the artifacts
# header). Artifacts Written is the final section per the schema, so no
# later section can be affected.
if [[ "$artifact_count" -ge 20 ]]; then
    tmp_file=$(mktemp)
    awk '
        /^## Artifacts Written/ { in_artifacts=1; print; next }
        in_artifacts && /^- / && !deleted { deleted=1; next }
        { print }
    ' "$state_file" > "$tmp_file"
    mv "$tmp_file" "$state_file"
fi

# Append the new artifact (Artifacts Written is the final section)
echo "- $rel_path" >> "$state_file"

exit 0
