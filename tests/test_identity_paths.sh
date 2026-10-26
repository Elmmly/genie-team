#!/bin/bash
# Structural tests: every genie identity path resolves on a project or a global install
# A global install puts genies in ~/.claude/agents/, so a project may have no
# .claude/agents/ of its own; a relative identity path then names nothing.
# Run: bash tests/test_identity_paths.sh (or via `make test`)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

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
        report FAIL "$name" "expected to contain: $needle"
    fi
}

assert_empty() {
    local name="$1" actual="$2"
    if [[ -z "$actual" ]]; then
        report PASS "$name"
    else
        report FAIL "$name" "expected nothing, got: $(echo "$actual" | head -3)"
    fi
}

# section <path> <heading-regex> — body of the first heading matching the regex,
# up to the next heading of the same or higher level
section() {
    [[ -f "$1" ]] || return 0
    awk -v pat="$2" '
        /^#+ / {
            level = length($1)
            if (in_sec && level <= sec_level) exit
            if (!in_sec && $0 ~ pat) { in_sec = 1; sec_level = level; next }
        }
        in_sec' "$1"
}

# A .claude/agents/ path not anchored at <repo>/ or ~/ (or another absolute prefix)
BARE_AGENTS='(^|[^/A-Za-z0-9_.~-])\.claude/agents/'

# command:genie for every command that loads a genie identity on the main thread
IDENTITY_COMMANDS="arch:architect brand:designer brand-image:designer brand-review:designer
brand-tokens:designer define:shaper design:architect direct:director"

# ── No bare identity paths in installable artifacts ──────────
echo "=== Bare paths ==="

# Arrange / Act
bare=$(grep -rnE "$BARE_AGENTS" commands agents skills rules hooks 2>/dev/null)

# Assert
assert_empty "identity: no installable artifact names a bare .claude/agents/ path" "$bare"

# ── Each command resolves its genie's identity ───────────────
echo "=== Command identity resolution ==="

for pair in $IDENTITY_COMMANDS; do
    # Arrange
    cmd="${pair%%:*}"
    genie="${pair##*:}"

    # Act
    identity=$(section "commands/$cmd.md" '^## Agent Identity')

    # Assert
    assert_contains "identity: /$cmd resolves the project install first" "$identity" "<repo>/.claude/agents/$genie.md"
    # shellcheck disable=SC2088  # '~/' is literal text in the command, not a path
    assert_contains "identity: /$cmd falls back to the global install" "$identity" "~/.claude/agents/$genie.md"
    assert_contains "identity: /$cmd stops when the genie is missing" "$identity" "genie $genie not installed"
done

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "test_identity_paths: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
