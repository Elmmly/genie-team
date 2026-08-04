#!/bin/bash
# Hook: SessionStart (startup|resume|compact|clear) — print git + environment ground truth
# Gives the model verified session state at every session start so recaps are
# derived from reality, not memory. Advisory only — always exits 0.
# Zero LLM cost — pure shell operations.

set -uo pipefail

input=$(cat 2>/dev/null) || input=""
cwd=$(echo "$input" | jq -r '.cwd // empty' 2>/dev/null) || cwd=""
[[ -z "$cwd" || ! -d "$cwd" ]] && cwd=$(pwd)

# Run a command with a wall-clock bound so a hung daemon or network call
# can never stall session start. Falls back to unbounded if perl is absent.
run_bounded() {
    local secs="$1"
    shift
    if command -v perl &>/dev/null; then
        perl -e 'alarm shift; exec @ARGV' "$secs" "$@" 2>/dev/null
    else
        "$@" 2>/dev/null
    fi
}

echo "[Session ground truth]"

# ── Git state ────────────────────────────────────────────────
if git -C "$cwd" rev-parse --git-dir &>/dev/null; then
    branch=$(git -C "$cwd" rev-parse --abbrev-ref HEAD 2>/dev/null) || branch="(detached)"

    upstream=$(git -C "$cwd" rev-parse --abbrev-ref --symbolic-full-name '@{upstream}' 2>/dev/null) || upstream=""
    if [[ -n "$upstream" ]]; then
        counts=$(git -C "$cwd" rev-list --left-right --count "HEAD...$upstream" 2>/dev/null) || counts=""
        ahead=$(echo "$counts" | awk '{print $1}')
        behind=$(echo "$counts" | awk '{print $2}')
        echo "Branch: $branch (ahead ${ahead:-?}, behind ${behind:-?} vs $upstream)"
    else
        echo "Branch: $branch (no upstream)"
    fi

    echo ""
    echo "Recent commits:"
    git -C "$cwd" log --oneline -5 2>/dev/null || echo "(no commits)"

    echo ""
    dirty=$(git -C "$cwd" status --short 2>/dev/null) || dirty=""
    if [[ -z "$dirty" ]]; then
        echo "Working tree: clean"
    else
        count=$(echo "$dirty" | wc -l | tr -d ' ')
        echo "Working tree: $count changed/untracked file(s):"
        echo "$dirty" | head -15
        [[ "$count" -gt 15 ]] && echo "  ... and $((count - 15)) more"
    fi
else
    echo "Not a git repository: $cwd"
fi

# ── Environment health (advisory) ────────────────────────────
echo ""
echo "Environment (advisory):"

if command -v docker &>/dev/null; then
    if run_bounded 4 docker info --format '{{.ServerVersion}}' >/dev/null; then
        echo "- docker: daemon running"
    else
        echo "- docker: daemon NOT running (start Docker if this session needs containers)"
    fi
else
    echo "- docker: not installed"
fi

if command -v gh &>/dev/null; then
    if run_bounded 6 gh auth status --hostname github.com >/dev/null; then
        echo "- gh auth: ok"
    else
        echo "- gh auth: FAILED — token expired, revoked, or offline (run 'gh auth status' / 'gh auth login'). PR creation and gh API calls will fail silently until fixed."
    fi
else
    echo "- gh auth: gh not installed"
fi

if command -v lsof &>/dev/null; then
    dev_ports="3000|3001|4200|5173|8000|8080|5432|6379"
    listeners=$(run_bounded 4 lsof -nP -iTCP -sTCP:LISTEN | awk -v ports="$dev_ports" '
        NR > 1 {
            n = split($9, a, ":"); port = a[n]
            if (port ~ "^(" ports ")$" && !seen[port]++)
                printf "  %s: %s (pid %s)\n", port, $1, $2
        }') || listeners=""
    if [[ -n "$listeners" ]]; then
        echo "- dev ports in use:"
        echo "$listeners"
    else
        echo "- dev ports (3000/3001/4200/5173/8000/8080/5432/6379): all free"
    fi
fi

exit 0
