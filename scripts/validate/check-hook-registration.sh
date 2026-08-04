#!/bin/bash
# Validate hook registration parity.
# Every hooks/*.sh must be registered in BOTH hooks/hooks.json (plugin install)
# and install.sh's merge_hook_config heredoc (script install), and the two
# registrations must be structurally identical (same events, matchers, order).
# The verify-stack.sh orphaning happened because these two drifted.
# Exit: 0 if in sync, 1 otherwise.

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"
HOOKS_JSON="$REPO_ROOT/hooks/hooks.json"
INSTALL_SH="$REPO_ROOT/install.sh"
errors=0

if ! command -v jq &>/dev/null; then
    echo "[HOOK-REG] jq not found — cannot validate hook registration" >&2
    exit 1
fi

if [[ ! -f "$HOOKS_JSON" ]]; then
    echo "[HOOK-REG] $HOOKS_JSON not found" >&2
    exit 1
fi

# Extract the HOOKJSON heredoc from install.sh's merge_hook_config
heredoc=$(awk '/cat << HOOKJSON/{f=1;next} /^HOOKJSON$/{f=0} f' "$INSTALL_SH")
if [[ -z "$heredoc" ]]; then
    echo "[HOOK-REG] could not extract HOOKJSON heredoc from install.sh" >&2
    exit 1
fi

# Normalize: reduce every command string to the script basename so
# ${CLAUDE_PLUGIN_ROOT}/hooks/x.sh and ${cmd_prefix}/x.sh compare equal.
normalize() {
    jq -S '.hooks | walk(
        if type == "object" and has("command")
        then .command |= (split("/") | last)
        else . end
    )'
}

norm_json=$(normalize < "$HOOKS_JSON")
norm_heredoc=$(echo "$heredoc" | normalize)

if [[ "$norm_json" != "$norm_heredoc" ]]; then
    echo "[HOOK-REG] hooks/hooks.json and install.sh merge_hook_config have drifted:" >&2
    diff <(echo "$norm_json") <(echo "$norm_heredoc") | sed 's/^/  /' >&2 || true
    echo "  → left: hooks/hooks.json, right: install.sh HOOKJSON heredoc" >&2
    errors=$((errors + 1))
fi

# Every hooks/*.sh must appear in both registrations
for script in "$REPO_ROOT"/hooks/*.sh; do
    name=$(basename "$script")
    if ! echo "$norm_json" | grep -qF "\"$name\""; then
        echo "[HOOK-REG] hooks/$name is not registered in hooks/hooks.json" >&2
        errors=$((errors + 1))
    fi
    if ! echo "$norm_heredoc" | grep -qF "\"$name\""; then
        echo "[HOOK-REG] hooks/$name is not registered in install.sh merge_hook_config" >&2
        errors=$((errors + 1))
    fi
done

if [[ $errors -gt 0 ]]; then
    exit 1
fi
exit 0
