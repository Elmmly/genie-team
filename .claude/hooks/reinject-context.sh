#!/bin/bash
# Hook: SessionStart (compact|clear) — re-inject session context
# Reads state file and prints to stdout so Claude sees it after compaction.
# Zero LLM cost — pure shell operations.

set -euo pipefail

input=$(cat)
cwd=$(echo "$input" | jq -r '.cwd // empty')

state_file="$cwd/.claude/session-state.md"

# Nothing to re-inject if no state file
if [[ ! -f "$state_file" ]]; then
    exit 0
fi

state_content=$(cat "$state_file")

# Extract the command line from state
command_line=$(echo "$state_content" | grep '^command:' | sed 's/^command:[[:space:]]*//')

# Print context header
echo "[Session context restored after compaction]"
echo ""
echo "You were working on: $command_line"
echo ""

# Print backlog context if present
backlog_title=$(echo "$state_content" | grep '^title:' | sed 's/^title:[[:space:]]*//')
backlog_status=$(echo "$state_content" | grep '^status:' | head -1 | sed 's/^status:[[:space:]]*//')
backlog_spec=$(echo "$state_content" | grep '^spec_ref:' | sed 's/^spec_ref:[[:space:]]*//')
backlog_adrs=$(echo "$state_content" | grep '^adr_refs:' | sed 's/^adr_refs:[[:space:]]*//')

if [[ -n "$backlog_title" ]]; then
    echo "Backlog item: $backlog_title (status: $backlog_status)"
    [[ -n "$backlog_spec" ]] && echo "Spec: $backlog_spec"
    [[ -n "$backlog_adrs" ]] && echo "ADRs: $backlog_adrs"
    echo ""
fi

# Print artifacts written
artifacts=$(echo "$state_content" | grep '^- ' || true)
if [[ -n "$artifacts" ]]; then
    echo "Files written so far:"
    echo "$artifacts"
    echo ""
fi

# Also print backlog item frontmatter if the file exists
if [[ -n "$command_line" ]]; then
    backlog_ref=$(echo "$command_line" | grep -o 'docs/backlog/[^ ]*\.md' || true)
    if [[ -n "$backlog_ref" ]] && [[ -f "$cwd/$backlog_ref" ]]; then
        echo "Backlog item frontmatter:"
        sed -n '/^---$/,/^---$/p' "$cwd/$backlog_ref"
        echo ""
    fi
fi

echo "Resume your work. Re-read the backlog item and spec if you need full details."

exit 0
