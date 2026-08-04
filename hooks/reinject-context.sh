#!/bin/bash
# Hook: SessionStart (compact|clear) — re-inject session context
# Replays the session state file AND appends live git state so the replayed
# document state is reconciled against reality. Emits git state even when no
# state file exists (a session without a tracked slash command still needs
# ground truth after compaction).
# Zero LLM cost — pure shell operations.

set -uo pipefail

input=$(cat 2>/dev/null) || input=""
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null) || cwd=""
[[ -z "$cwd" || ! -d "$cwd" ]] && cwd=$(pwd)

state_file="$cwd/.claude/session-state.md"

# Print live git state — the source of truth the replayed context must be
# reconciled against.
print_git_state() {
    if ! git -C "$cwd" rev-parse --git-dir &>/dev/null; then
        return 0
    fi
    echo "Live git state (source of truth — trust this over any replayed or remembered state):"
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null) || branch="(detached)"
    upstream=$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) || upstream=""
    if [[ -n "$upstream" ]]; then
        counts=$(git -C "$cwd" rev-list --left-right --count "HEAD...$upstream" 2>/dev/null) || counts=""
        echo "Branch: $branch (ahead $(echo "$counts" | awk '{print $1}'), behind $(echo "$counts" | awk '{print $2}') vs $upstream)"
    else
        echo "Branch: $branch (no upstream)"
    fi
    git -C "$cwd" log --oneline -5 2>/dev/null || true
    dirty=$(git -C "$cwd" status --short 2>/dev/null) || dirty=""
    if [[ -z "$dirty" ]]; then
        echo "Working tree: clean"
    else
        echo "Working tree:"
        echo "$dirty" | head -15
    fi
}

# ── No state file: still ground the session in git ───────────
if [[ ! -f "$state_file" ]]; then
    echo "[Session context after compaction]"
    echo ""
    echo "No session state file found — re-derive your working state from git"
    echo "before summarizing. Never assert what is or isn't committed from memory."
    echo ""
    print_git_state
    exit 0
fi

state_content=$(cat "$state_file")

# Extract the command line from state
command_line=$(echo "$state_content" | grep '^command:' | head -1 | sed 's/^command:[[:space:]]*//') || command_line=""

# Print context header
echo "[Session context restored after compaction]"
echo ""
echo "You were working on: $command_line"
echo ""

# Print backlog context if present
backlog_title=$(echo "$state_content" | grep '^title:' | head -1 | sed 's/^title:[[:space:]]*//') || backlog_title=""
backlog_status=$(echo "$state_content" | grep '^status:' | head -1 | sed 's/^status:[[:space:]]*//') || backlog_status=""
backlog_spec=$(echo "$state_content" | grep '^spec_ref:' | head -1 | sed 's/^spec_ref:[[:space:]]*//') || backlog_spec=""
backlog_adrs=$(echo "$state_content" | grep '^adr_refs:' | head -1 | sed 's/^adr_refs:[[:space:]]*//') || backlog_adrs=""

if [[ -n "$backlog_title" ]]; then
    echo "Backlog item: $backlog_title (status: $backlog_status)"
    [[ -n "$backlog_spec" ]] && echo "Spec: $backlog_spec"
    [[ -n "$backlog_adrs" ]] && echo "ADRs: $backlog_adrs"
    echo ""
fi

# Print artifacts written (section-aware — history lines also start with "- ")
artifacts=$(echo "$state_content" | awk '/^## Artifacts Written/{f=1;next} /^## /{f=0} f && /^- /') || artifacts=""
if [[ -n "$artifacts" ]]; then
    echo "Files written so far (per session state — verify against git below):"
    echo "$artifacts"
    echo ""
fi

# Also print backlog item frontmatter if the file exists
if [[ -n "$command_line" ]]; then
    backlog_ref=$(echo "$command_line" | grep -o 'docs/backlog/[^ ]*\.md') || backlog_ref=""
    if [[ -n "$backlog_ref" ]] && [[ -f "$cwd/$backlog_ref" ]]; then
        echo "Backlog item frontmatter:"
        sed -n '/^---$/,/^---$/p' "$cwd/$backlog_ref"
        echo ""
    fi
fi

# Reconcile the replayed document state against reality
print_git_state
echo ""
echo "Reconcile the replayed state above against the live git state — the git"
echo "state wins. Resume your work; re-read the backlog item and spec if you"
echo "need full details."

exit 0
