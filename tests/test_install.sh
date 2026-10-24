#!/bin/bash
# Install/uninstall tests for install.sh: files land and leave, and hook registration in
# settings preserves the user's own hooks.
# Run: bash tests/test_install.sh (or via `make test`)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
INSTALL="$REPO_ROOT/install.sh"

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

assert_eq() {
    local name="$1" actual="$2" expected="$3"
    if [[ "$actual" == "$expected" ]]; then
        report PASS "$name"
    else
        report FAIL "$name" "expected '$expected', got '$actual'"
    fi
}

assert_file() {
    local name="$1" path="$2"
    if [[ -f "$path" ]]; then report PASS "$name"; else report FAIL "$name" "missing: $path"; fi
}

assert_no_file() {
    local name="$1" path="$2"
    if [[ ! -e "$path" ]]; then report PASS "$name"; else report FAIL "$name" "still present: $path"; fi
}

if ! command -v jq &>/dev/null; then
    echo "SKIP: jq not found — hook registration tests need jq"
    exit 0
fi

# count_command <settings> <substring> — hook entries whose command contains the substring
count_command() {
    jq --arg s "$2" '[.hooks // {} | .[] | .[] | .hooks[]? | select(.command | contains($s))] | length' "$1"
}

scratch=$(mktemp -d)
trap 'rm -rf "$scratch"' EXIT

# Keep the real claude CLI out of reach: install.sh calls it for MCP checks, and it would
# read and rewrite the scratch HOME's settings. Only jq is needed beyond the system tools.
mkdir -p "$scratch/bin"
ln -s "$(command -v jq)" "$scratch/bin/jq"
export PATH="/usr/bin:/bin:/usr/sbin:/sbin:$scratch/bin"

# ── Global: hooks merge without clobbering the user's own ────
echo "=== global hooks ==="

# Arrange
home="$scratch/home"
mkdir -p "$home/.claude"
cat > "$home/.claude/settings.json" <<'EOF'
{
  "model": "opus",
  "hooks": {
    "SessionStart": [
      { "hooks": [ { "type": "command", "command": "bash /opt/mine/on-start.sh" } ] }
    ]
  }
}
EOF

# Act
HOME="$home" bash "$INSTALL" global --hooks >/dev/null 2>&1
HOME="$home" bash "$INSTALL" global --hooks --force >/dev/null 2>&1
settings="$home/.claude/settings.json"

# Assert
assert_eq "install keeps the user's own SessionStart hook" "$(count_command "$settings" /opt/mine/on-start.sh)" 1
assert_eq "install keeps unrelated settings" "$(jq -r .model "$settings")" "opus"
assert_eq "install registers session-ground-truth once after two installs" \
    "$(count_command "$settings" hooks/session-ground-truth.sh)" 1
assert_eq "install registers track-command once after two installs" \
    "$(count_command "$settings" hooks/track-command.sh)" 1

# Act
HOME="$home" bash "$INSTALL" uninstall global >/dev/null 2>&1

# Assert
assert_eq "uninstall removes every genie-team hook registration" \
    "$(count_command "$settings" "$home/.claude/hooks/")" 0
assert_eq "uninstall keeps the user's own hook" "$(count_command "$settings" /opt/mine/on-start.sh)" 1
assert_eq "uninstall keeps unrelated settings" "$(jq -r .model "$settings")" "opus"

# ── Project: files and hooks come and go ─────────────────────
echo "=== project install / uninstall ==="

# Arrange
project="$scratch/project"
mkdir -p "$project"
git -C "$project" init -q

# Act
HOME="$home" bash "$INSTALL" project "$project" --agents --commands --schemas --hooks >/dev/null 2>&1

# Assert
assert_file "project install copies the Director genie" "$project/.claude/agents/director.md"
assert_file "project install copies /direct" "$project/.claude/commands/direct.md"
assert_eq "project install registers hooks in settings.local.json" \
    "$(count_command "$project/.claude/settings.local.json" .claude/hooks/session-ground-truth.sh)" 1

# Act
(cd "$project" && HOME="$home" bash "$INSTALL" uninstall project >/dev/null 2>&1)

# Assert
assert_no_file "project uninstall removes the Director genie" "$project/.claude/agents/director.md"
assert_no_file "project uninstall removes /direct" "$project/.claude/commands/direct.md"
assert_no_file "project uninstall removes the board schema" "$project/.claude/schemas/program-board.schema.md"
assert_eq "project uninstall removes hook registrations" \
    "$(count_command "$project/.claude/settings.local.json" .claude/hooks/)" 0

echo ""
echo "test_install: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
