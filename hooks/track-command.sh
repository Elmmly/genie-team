#!/bin/bash
# Hook: UserPromptSubmit — capture genie command invocations
# Updates the session state file when a slash command is detected: replaces the
# Active Command section, records the HEAD SHA as a base anchor, appends to the
# Command History section, and preserves accumulated artifacts.
# Format: schemas/session-state.schema.md
# Zero LLM cost — pure shell operations.

set -uo pipefail

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // empty' 2>/dev/null) || prompt=""
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null) || cwd=""

# Only track slash commands
if [[ -z "$prompt" ]] || [[ "$prompt" != /* ]]; then
    exit 0
fi

state_file="$cwd/.claude/session-state.md"
mkdir -p "$(dirname "$state_file")"

# Base anchor: HEAD at the moment the command started. Diffing against this
# SHA later recovers what the command actually changed.
base_commit=$(git -C "$cwd" rev-parse --short HEAD 2>/dev/null) || base_commit="none"

# Preserve prior history and artifacts (section-aware extraction)
prior_history=""
prior_artifacts=""
if [[ -f "$state_file" ]]; then
    prior_history=$(awk '/^## Command History/{f=1;next} /^## /{f=0} f && /^- /' "$state_file") || prior_history=""
    prior_artifacts=$(awk '/^## Artifacts Written/{f=1;next} /^## /{f=0} f && /^- /' "$state_file") || prior_artifacts=""
fi

# Extract command name and first argument
command_args=$(echo "$prompt" | cut -d' ' -f2- -s)

# Try to extract backlog item context if argument points to a docs/backlog/ file
backlog_title=""
backlog_status=""
backlog_spec_ref=""
backlog_adr_refs=""

if [[ -n "$command_args" ]]; then
    # Normalize: add .md if missing
    backlog_path="$command_args"
    [[ "$backlog_path" != *.md ]] && backlog_path="${backlog_path}.md"

    # Try absolute path, then relative to cwd
    if [[ -f "$backlog_path" ]]; then
        backlog_file="$backlog_path"
    elif [[ -f "$cwd/$backlog_path" ]]; then
        backlog_file="$cwd/$backlog_path"
    else
        backlog_file=""
    fi

    if [[ -n "$backlog_file" ]] && [[ -f "$backlog_file" ]]; then
        # Extract frontmatter (between first two --- lines)
        frontmatter=$(sed -n '/^---$/,/^---$/p' "$backlog_file" | sed '1d;$d')

        if [[ -n "$frontmatter" ]]; then
            backlog_title=$(echo "$frontmatter" | grep '^title:' | sed 's/^title:[[:space:]]*//' | sed 's/^"//;s/"$//') || backlog_title=""
            backlog_status=$(echo "$frontmatter" | grep '^status:' | sed 's/^status:[[:space:]]*//') || backlog_status=""
            backlog_spec_ref=$(echo "$frontmatter" | grep '^spec_ref:' | sed 's/^spec_ref:[[:space:]]*//') || backlog_spec_ref=""
            backlog_adr_refs=$(echo "$frontmatter" | grep -A 20 '^adr_refs:' | grep '^\s*-' | sed 's/^\s*-\s*//' | tr '\n' ', ' | sed 's/,$//') || backlog_adr_refs=""
        fi
    fi
fi

started=$(date -u +%Y-%m-%dT%H:%M:%SZ)

# Rewrite the state file, carrying history + artifacts forward.
# Artifacts Written MUST stay the final section (track-artifacts.sh appends).
{
    echo "# Genie Session State"
    echo "<!-- Auto-maintained by hooks. Do not edit manually. Format: schemas/session-state.schema.md -->"
    echo ""
    echo "## Active Command"
    echo "command: $prompt"
    echo "started: $started"
    echo "base_commit: $base_commit"

    if [[ -n "$backlog_title" ]]; then
        echo ""
        echo "## Backlog Item"
        echo "title: $backlog_title"
        echo "status: $backlog_status"
        echo "spec_ref: $backlog_spec_ref"
        echo "adr_refs: $backlog_adr_refs"
    fi

    echo ""
    echo "## Command History"
    # Keep the most recent 19 prior entries; the new entry makes 20 max
    [[ -n "$prior_history" ]] && echo "$prior_history" | tail -19
    echo "- $started $base_commit $prompt"

    echo ""
    echo "## Artifacts Written"
    [[ -n "$prior_artifacts" ]] && echo "$prior_artifacts"
} > "$state_file"

exit 0
