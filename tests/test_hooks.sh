#!/bin/bash
# Smoke tests for hooks/*.sh
# Pipes synthetic hook payloads (JSON on stdin) and asserts output + exit codes.
# Run: bash tests/test_hooks.sh (or via `make test`)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
HOOKS_DIR="$REPO_ROOT/hooks"

pass=0
fail=0

report() {
    local status="$1" name="$2" detail="${3:-}"
    if [[ "$status" == "PASS" ]]; then
        pass=$((pass + 1))
        echo "  PASS: $name"
    else
        fail=$((fail + 1))
        echo "  FAIL: $name"
        [[ -n "$detail" ]] && echo "        $detail"
    fi
}

assert_contains() {
    local name="$1" haystack="$2" needle="$3"
    if echo "$haystack" | grep -qF -- "$needle"; then
        report PASS "$name"
    else
        report FAIL "$name" "expected output to contain: $needle"
    fi
}

assert_not_contains() {
    local name="$1" haystack="$2" needle="$3"
    if echo "$haystack" | grep -qF -- "$needle"; then
        report FAIL "$name" "expected output NOT to contain: $needle"
    else
        report PASS "$name"
    fi
}

assert_exit0() {
    local name="$1" code="$2"
    if [[ "$code" -eq 0 ]]; then
        report PASS "$name"
    else
        report FAIL "$name" "expected exit 0, got $code"
    fi
}

assert_count() {
    local name="$1" actual="$2" expected="$3"
    if [[ "$actual" -eq "$expected" ]]; then
        report PASS "$name"
    else
        report FAIL "$name" "expected count $expected, got $actual"
    fi
}

# ── Scratch git repo fixture ─────────────────────────────────
scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT
(
    cd "$scratch"
    git init -q -b main
    git config user.email test@example.com
    git config user.name "Test"
    echo hello > readme.md
    git add readme.md
    git commit -qm "initial scratch commit"
) || { echo "FATAL: could not set up scratch repo"; exit 1; }

payload() { # payload <json>
    printf '%s' "$1"
}

# ── session-ground-truth.sh ──────────────────────────────────
echo "=== session-ground-truth.sh ==="

out=$(payload "{\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/session-ground-truth.sh" 2>&1)
code=$?
assert_exit0 "ground-truth exits 0 in git repo" "$code"
assert_contains "ground-truth prints branch" "$out" "Branch: main"
assert_contains "ground-truth prints recent commits" "$out" "initial scratch commit"
assert_contains "ground-truth prints working tree state" "$out" "Working tree"
assert_contains "ground-truth prints env health" "$out" "Environment (advisory)"

# Dirty tree shows up
echo dirty > "$scratch/dirty.txt"
out=$(payload "{\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/session-ground-truth.sh" 2>&1)
assert_contains "ground-truth lists dirty files" "$out" "dirty.txt"
rm "$scratch/dirty.txt"

# Non-git directory: still exit 0, no crash
nogit=$(mktemp -d)
out=$(payload "{\"cwd\":\"$nogit\"}" | bash "$HOOKS_DIR/session-ground-truth.sh" 2>&1)
code=$?
assert_exit0 "ground-truth exits 0 outside git repo" "$code"
rm -rf "$nogit"

# Garbage stdin: exit 0
out=$(printf 'not json' | bash "$HOOKS_DIR/session-ground-truth.sh" 2>&1)
code=$?
assert_exit0 "ground-truth exits 0 on garbage stdin" "$code"

# ── track-command.sh ─────────────────────────────────────────
echo "=== track-command.sh ==="

state="$scratch/.claude/session-state.md"
rm -rf "$scratch/.claude"

payload "{\"prompt\":\"/deliver docs/backlog/x.md\",\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/track-command.sh"
code=$?
assert_exit0 "track-command exits 0" "$code"
if [[ -f "$state" ]]; then
    report PASS "track-command creates state file"
else
    report FAIL "track-command creates state file" "no file at $state"
fi
content=$(cat "$state" 2>/dev/null || true)
assert_contains "state records active command" "$content" "command: /deliver docs/backlog/x.md"
assert_contains "state records base commit anchor" "$content" "base_commit:"
head_sha=$(git -C "$scratch" rev-parse --short HEAD)
assert_contains "base commit matches HEAD" "$content" "$head_sha"
assert_contains "state has command history section" "$content" "## Command History"

# Second command: history appends, active command replaced, artifacts preserved
echo "- docs/some/artifact.md" >> "$state"
payload "{\"prompt\":\"/discern docs/backlog/x.md\",\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/track-command.sh"
content=$(cat "$state")
assert_contains "second command replaces active command" "$content" "command: /discern docs/backlog/x.md"
history_count=$(awk '/^## Command History/{f=1;next} /^## /{f=0} f && /^- /' "$state" | wc -l | tr -d ' ')
assert_count "history has 2 entries after 2 commands" "$history_count" 2
assert_contains "artifacts preserved across commands" "$content" "- docs/some/artifact.md"

# Non-slash prompt: ignored
payload "{\"prompt\":\"just a question\",\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/track-command.sh"
content=$(cat "$state")
assert_contains "non-slash prompt does not clobber state" "$content" "command: /discern docs/backlog/x.md"

# ── track-artifacts.sh ───────────────────────────────────────
echo "=== track-artifacts.sh ==="

artifact_lines() {
    awk '/^## Artifacts Written/{f=1;next} /^## /{f=0} f && /^- /' "$state"
}

payload "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$scratch/src/written.ts\"},\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/track-artifacts.sh"
code=$?
assert_exit0 "track-artifacts exits 0 (Write)" "$code"
assert_contains "Write payload tracked" "$(artifact_lines)" "- src/written.ts"

payload "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$scratch/src/edited.ts\"},\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/track-artifacts.sh"
code=$?
assert_exit0 "track-artifacts exits 0 (Edit)" "$code"
assert_contains "Edit payload tracked" "$(artifact_lines)" "- src/edited.ts"

# Dedup: same path again → still one entry
payload "{\"tool_name\":\"Edit\",\"tool_input\":{\"file_path\":\"$scratch/src/edited.ts\"},\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/track-artifacts.sh"
dedup_count=$(artifact_lines | grep -cF -- "- src/edited.ts")
assert_count "duplicate edits tracked once" "$dedup_count" 1

# A path mentioned in command history must not block artifact tracking (section-aware dedup)
payload "{\"prompt\":\"/deliver docs/backlog/x.md\",\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/track-command.sh"
payload "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$scratch/docs/backlog/x.md\"},\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/track-artifacts.sh"
assert_contains "artifact tracked even when path appears in history" "$(artifact_lines)" "- docs/backlog/x.md"

# ── reinject-context.sh ──────────────────────────────────────
echo "=== reinject-context.sh ==="

out=$(payload "{\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/reinject-context.sh" 2>&1)
code=$?
assert_exit0 "reinject exits 0 with state file" "$code"
assert_contains "reinject replays active command" "$out" "/deliver docs/backlog/x.md"
assert_contains "reinject includes live git state" "$out" "Branch: main"
assert_contains "reinject tells model to trust git" "$out" "git state"

# Without a state file: still emit git state instead of exiting silently
rm -rf "$scratch/.claude"
out=$(payload "{\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/reinject-context.sh" 2>&1)
code=$?
assert_exit0 "reinject exits 0 without state file" "$code"
assert_contains "reinject emits git state without state file" "$out" "Branch: main"

# ── verify-stack.sh (regression: still exits 0 on unknown ext) ──
echo "=== verify-stack.sh ==="
out=$(payload "{\"tool_name\":\"Write\",\"tool_input\":{\"file_path\":\"$scratch/readme.md\"},\"cwd\":\"$scratch\"}" | bash "$HOOKS_DIR/verify-stack.sh" 2>&1)
code=$?
assert_exit0 "verify-stack exits 0 for markdown" "$code"

# ── hook registration parity ─────────────────────────────────
echo "=== hook registration parity ==="
out=$(bash "$REPO_ROOT/scripts/validate/check-hook-registration.sh" 2>&1)
code=$?
assert_exit0 "all hooks registered in hooks.json and install.sh" "$code"
[[ $code -ne 0 ]] && while IFS= read -r line; do echo "        $line"; done <<< "$out"

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "test_hooks.sh: $pass passed, $fail failed"
[[ $fail -eq 0 ]] || exit 1
exit 0
