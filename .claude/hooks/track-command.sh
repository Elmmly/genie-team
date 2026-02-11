#!/bin/bash
# Hook: UserPromptSubmit — capture genie command invocations
# Writes session state file when a slash command is detected.
# Zero LLM cost — pure shell operations.

set -euo pipefail

input=$(cat)
prompt=$(echo "$input" | jq -r '.prompt // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Only track slash commands
if [[ -z "$prompt" ]] || [[ "$prompt" != /* ]]; then
    exit 0
fi

state_file="$cwd/.claude/session-state.md"
mkdir -p "$(dirname "$state_file")"

# Extract command name and first argument
command_name=$(echo "$prompt" | awk '{print $1}')
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
            backlog_title=$(echo "$frontmatter" | grep '^title:' | sed 's/^title:[[:space:]]*//' | sed 's/^"//;s/"$//')
            backlog_status=$(echo "$frontmatter" | grep '^status:' | sed 's/^status:[[:space:]]*//')
            backlog_spec_ref=$(echo "$frontmatter" | grep '^spec_ref:' | sed 's/^spec_ref:[[:space:]]*//')
            # Extract adr_refs (multi-line YAML array)
            backlog_adr_refs=$(echo "$frontmatter" | grep -A 20 '^adr_refs:' | grep '^\s*-' | sed 's/^\s*-\s*//' | tr '\n' ', ' | sed 's/,$//')
        fi
    fi
fi

# Write state file
cat > "$state_file" << STATEEOF
# Genie Session State
<!-- Auto-maintained by hooks. Do not edit manually. -->

## Active Command
command: $prompt
started: $(date -u +%Y-%m-%dT%H:%M:%SZ)
STATEEOF

# Add backlog context if available
if [[ -n "$backlog_title" ]]; then
    cat >> "$state_file" << BACKLOGEOF

## Backlog Item
title: $backlog_title
status: $backlog_status
spec_ref: $backlog_spec_ref
adr_refs: $backlog_adr_refs
BACKLOGEOF
fi

# Add empty artifacts section
cat >> "$state_file" << ARTIFACTSEOF

## Artifacts Written
ARTIFACTSEOF

exit 0
