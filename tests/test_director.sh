#!/bin/bash
# Structural tests for in-session program direction (the Director genie, /direct)
# Spec: docs/specs/workflow/program-direction.md
# Run: bash tests/test_director.sh (or via `make test`)

set -uo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
cd "$REPO_ROOT" || exit 1

DIRECTOR="agents/director.md"
DIRECT="commands/direct.md"
BOARD_SCHEMA="schemas/program-board.schema.md"
FIXTURES="tests/fixtures/program"
VALIDATE="scripts/validate/validate-frontmatter.sh"
CROSSREFS="scripts/validate/check-crossrefs.sh"

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

assert_exit() {
    local name="$1" actual="$2" expected="$3"
    if [[ "$actual" -eq "$expected" ]]; then
        report PASS "$name"
    else
        report FAIL "$name" "expected exit $expected, got $actual"
    fi
}

assert_file() {
    local name="$1" path="$2"
    if [[ -f "$path" ]]; then
        report PASS "$name"
    else
        report FAIL "$name" "missing file: $path"
    fi
}

# read_file <path> — file contents, or empty when the file is missing
read_file() {
    [[ -f "$1" ]] && cat "$1"
}

# frontmatter <path> — lines between the first two '---' markers
frontmatter() {
    [[ -f "$1" ]] && awk 'NR == 1 && /^---$/ { open = 1; next } open && /^---$/ { exit } open' "$1"
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

# without_section <path> <heading-regex> — the file with that section removed
without_section() {
    [[ -f "$1" ]] || return 0
    awk -v pat="$2" '
        /^#+ / {
            level = length($1)
            if (in_sec && level <= sec_level) in_sec = 0
            if (!in_sec && $0 ~ pat) { in_sec = 1; sec_level = level; next }
        }
        !in_sec' "$1"
}

OUT_OF_PROCESS='claude +(-p|--print)|genies +run|SDK runner|maxBudgetUsd|maxTurns'
KITCHEN_TERMS='chef|cook|cooking|brigade|mise en place|the pass|at-pass|## Service'

# ── AC-2: the Director genie ─────────────────────────────────
echo "=== AC-2: Director genie definition ==="

# Arrange
director_fm=$(frontmatter "$DIRECTOR")

# Act
director_desc=$(echo "$director_fm" | grep -E '^description:')

# Assert
assert_file "AC-2: agents/director.md exists" "$DIRECTOR"
assert_contains "AC-2: frontmatter names the director" "$director_fm" "name: director"
assert_contains "AC-2: description says it runs on the main thread" "$director_desc" "main thread"
assert_contains "AC-2: description says it is never spawned as a subagent" "$director_desc" "never spawned as a subagent"

# Arrange
director_body=$(read_file "$DIRECTOR")

# Act / Assert — one heading per charter area
for heading in "WILL Do" "WILL NOT Do" "The Board" "The Tick" "Preflight" "Dispatch" \
    "Requests and Shared Contracts" "The Merge Gate" "Health Check" "Failure Handling" "Reporting"; do
    assert_contains "AC-2: charter has a '$heading' section" "$director_body" "## $heading"
done

# Arrange / Act
# shellcheck disable=SC2088  # '~/' is a literal pattern, not a path
home_paths=$(grep -nE '~/|/Users/' "$DIRECTOR" "$DIRECT" 2>/dev/null)

# Assert
assert_empty "AC-2: director.md and direct.md name no home paths" "$home_paths"

# Arrange / Act — rules learned from the trial must survive the port
# Assert
assert_contains "AC-2: Crafter checks its worktree before working" "$director_body" "git rev-parse --show-toplevel"
assert_contains "AC-2: hold-red exception is ported" "$director_body" "hold-red"
assert_contains "AC-2: regenerate step is ported" "$director_body" "regenerate"
assert_contains "AC-2: a misfire is not an attempt" "$director_body" "misfire is not an attempt"
assert_contains "AC-2: verify falls back to the stack profile" "$director_body" "Verification"
assert_contains "AC-2: verify and regenerate are read from main, never a slice branch" \
    "$director_body" "never from a slice branch"
assert_contains "AC-2: preflight checks the Director's paths are git-ignored" "$director_body" "git check-ignore"
assert_contains "AC-2: commits stage explicit paths only" "$director_body" "explicit paths"
# git check-ignore -q accepts a single path; with two it exits 128 and preflight always stops
# shellcheck disable=SC2016  # the backtick is a literal in the regex
assert_empty "AC-2: every check-ignore -q names exactly one path" \
    "$(grep -nE 'check-ignore -q [^ `&]+ [^ `&]+' "$DIRECTOR" "$DIRECT" 2>/dev/null)"
assert_contains "AC-8: a merged slice waiting on a red main has its own state" "$director_body" "\`merging\`"

# Arrange
gate=$(section "$DIRECTOR" '^## The Merge Gate')
failures=$(section "$DIRECTOR" '^## Failure Handling')
dispatch=$(section "$DIRECTOR" '^## Dispatch')

# Act / Assert — review findings on the gate, hand-backs, and dispatch
assert_contains "AC-6: the gate records the pre-merge commit" "$gate" "pre-merge"
assert_contains "AC-6: the gate works on a branch variable, not a hardcoded suffix" "$gate" "<branch>"
assert_contains "AC-6: a reverted slice gets its revert reverted before rework" "$failures" "revert the revert"
assert_contains "AC-6: every hand-back clears the verdict" "$failures" "clear \`verdict\`"
assert_contains "AC-6: entry needs the Director-logged approval at the branch head" "$gate" "Critic APPROVED at"
assert_contains "AC-4: genies are dispatched in the background" "$dispatch" "background"
assert_contains "AC-4: non-isolated genies cd into the worktree on every call" "$dispatch" "cd <worktree> &&"
assert_contains "AC-8: misfires in a row are capped" "$failures" "misfires in a row"
assert_empty "AC-6: the revert does not rely on ORIG_HEAD" "$(grep -n 'ORIG_HEAD' "$DIRECTOR" "$DIRECT" 2>/dev/null)"
assert_contains "AC-3: /direct schedules only under /loop" "$(read_file "$DIRECT")" "only under \`/loop\`"
assert_contains "AC-4: the Crafter never sets its own verdict" "$(read_file agents/crafter.md)" "Never set \`verdict\`"
assert_contains "AC-4: the Crafter stays on its slice branch" "$(read_file agents/crafter.md)" "Stay on \`genie/<slice-id>-deliver\`"

# ── Vocabulary: genie-team terms only ────────────────────────
echo "=== Vocabulary ==="

# Arrange / Act
kitchen=$(grep -nwiE "$KITCHEN_TERMS" "$DIRECTOR" "$DIRECT" "$BOARD_SCHEMA" 2>/dev/null)

# Assert
assert_file "vocabulary: program-board schema exists" "$BOARD_SCHEMA"
assert_empty "vocabulary: no kitchen terms in director, direct, or board schema" "$kitchen"

# ── AC-3: the /direct command ────────────────────────────────
echo "=== AC-3: /direct command ==="

# Arrange
direct_body=$(read_file "$DIRECT")

# Act / Assert
assert_file "AC-3: commands/direct.md exists" "$DIRECT"
for heading in "Arguments" "Genie Invoked" "Context Loading" "Context Writing" "Behavior" \
    "Usage Examples" "Safety Rules" "Routing"; do
    assert_contains "AC-3: direct.md has a '$heading' section" "$direct_body" "## $heading"
done
for flag in "--one" "--status" "--merge" "--tidy" "--no-wake"; do
    assert_contains "AC-3: direct.md documents $flag" "$direct_body" "$flag"
done
assert_contains "AC-3: unattended direction runs under /loop" "$direct_body" "/loop /direct"
assert_contains "AC-3: direct.md loads the Director identity" "$direct_body" ".claude/agents/director.md"

# ── AC-4: everything runs inside the session ─────────────────
echo "=== AC-4: in-session only ==="

# Arrange
will_not=$(section "$DIRECTOR" '^### WILL NOT Do')

# Act
spawn_outside_will_not=$(without_section "$DIRECTOR" '^### WILL NOT Do' | grep -nE "$OUT_OF_PROCESS")
spawn_outside_safety=$(without_section "$DIRECT" '^## Safety Rules' | grep -nE "$OUT_OF_PROCESS")

# Assert
assert_contains "AC-4: WILL NOT forbids claude -p" "$will_not" "claude -p"
assert_contains "AC-4: WILL NOT forbids genies run" "$will_not" "genies run"
assert_contains "AC-4: WILL NOT forbids budget or turn caps" "$will_not" "budget or turn cap"
assert_empty "AC-4: director.md mentions out-of-process spawns only under WILL NOT" "$spawn_outside_will_not"
assert_empty "AC-4: direct.md mentions out-of-process spawns only under Safety Rules" "$spawn_outside_safety"
assert_contains "AC-4: Crafters run with worktree isolation" "$director_body" 'isolation: "worktree"'

# Arrange / Act
for genie in crafter critic tidier; do
    tools=$(frontmatter "agents/$genie.md" | grep -E '^tools:')
    # Assert
    assert_contains "AC-4: $genie lists Skill in tools" "$tools" "Skill"
done

# ── AC-1: program and slice validation ───────────────────────
echo "=== AC-1: program and slice validation ==="

# Arrange
valid_files=("$FIXTURES"/valid/*.md)

# Act
"$VALIDATE" "${valid_files[@]}" >/dev/null 2>&1; valid_schema=$?
"$CROSSREFS" "${valid_files[@]}" >/dev/null 2>&1; valid_refs=$?

# Assert
assert_exit "AC-1: a valid two-slice program passes schema validation" "$valid_schema" 0
assert_exit "AC-1: a valid two-slice program passes cross-reference checks" "$valid_refs" 0

# Arrange / Act
missing_out=$("$CROSSREFS" "$FIXTURES"/missing-slice/program.md 2>&1); missing_code=$?

# Assert
assert_exit "AC-1: a missing slices path fails" "$missing_code" 1
assert_contains "AC-1: the error names the missing slice" "$missing_out" "does-not-exist.md"

# Arrange / Act
outside_out=$("$CROSSREFS" "$FIXTURES"/outside-starts-when/program.md 2>&1); outside_code=$?

# Assert
assert_exit "AC-1: a starts_when entry outside the program fails" "$outside_code" 1
assert_contains "AC-1: the error names the stray starts_when entry" "$outside_out" "valid/slice-a.md"

# Arrange / Act
"$VALIDATE" "$FIXTURES"/bad-kind/item.md >/dev/null 2>&1; banana_code=$?
"$VALIDATE" "$FIXTURES"/bad-verdict/slice.md >/dev/null 2>&1; verdict_code=$?

# Assert
assert_exit "AC-1: kind: banana fails" "$banana_code" 1
assert_exit "AC-1: verdict: MAYBE fails" "$verdict_code" 1

# Arrange / Act
flow_out=$("$CROSSREFS" "$FIXTURES"/flow-style/program.md 2>&1); flow_code=$?
notslice_out=$("$CROSSREFS" "$FIXTURES"/not-a-slice/program.md 2>&1); notslice_code=$?
"$CROSSREFS" "$FIXTURES"/traversal/program.md >/dev/null 2>&1; traversal_code=$?
"$VALIDATE" "$FIXTURES"/bad-id/slice.md >/dev/null 2>&1; bad_id_code=$?

# Assert
assert_exit "AC-1: a flow-style slices list fails instead of being skipped" "$flow_code" 1
assert_contains "AC-1: the flow-style error says to use a block list" "$flow_out" "block list"
assert_exit "AC-1: a listed item without kind: slice fails" "$notslice_code" 1
assert_contains "AC-1: the error names the item that is not a slice" "$notslice_out" "plain.md"
assert_exit "AC-1: a slices path containing '..' fails" "$traversal_code" 1
assert_exit "AC-1: a slice id with spaces or shell characters fails" "$bad_id_code" 1

# Arrange
shaped_schema=$(read_file schemas/shaped-work-contract.schema.md)
board_schema=$(read_file "$BOARD_SCHEMA")

# Act / Assert
for field in kind slices starts_when verdict; do
    assert_contains "AC-1: shaped-work schema documents '$field'" "$shaped_schema" "\`$field\`"
done
assert_contains "AC-1: shaped-work schema points to the board schema" "$shaped_schema" "program-board.schema.md"
for state in waiting ready building review ready-to-merge merged blocked held orphaned tidy; do
    assert_contains "AC-1: board schema defines state '$state'" "$board_schema" "\`$state\`"
done
for heading in "Slice Protocol" "Shared Contracts" "Board" "Requests"; do
    assert_contains "AC-1: board schema defines the '$heading' section" "$board_schema" "## $heading"
done

# ── AC-9: trunk-based only, permission rules ─────────────────
echo "=== AC-9: trunk-based mode and permissions ==="

# Arrange
settings=$(read_file templates/settings.json)

# Act / Assert
assert_contains "AC-9: direct.md refuses PR mode" "$direct_body" "Programs need trunk-based mode"
assert_contains "AC-9: settings allow git rebase main" "$settings" '"Bash(git rebase main)"'
assert_contains "AC-9: settings allow git rebase --abort" "$settings" '"Bash(git rebase --abort)"'
assert_contains "AC-9: settings allow git -C <worktree> rebase main" "$settings" '"Bash(git -C * rebase main)"'
assert_contains "AC-9: settings allow git -C <worktree> rebase master" "$settings" '"Bash(git -C * rebase master)"'

# ── AC-10: docs and distribution ─────────────────────────────
echo "=== AC-10: docs and distribution ==="

# Arrange / Act / Assert
assert_contains "AC-10: rules/workflow.md lists /direct" "$(read_file rules/workflow.md)" "/direct"
assert_contains "AC-10: genie-help lists /direct" "$(read_file commands/genie-help.md)" "/direct"
assert_contains "AC-10: README lists /direct" "$(read_file README.md)" "/direct"
assert_contains "AC-10: README has a Programs section" "$(read_file README.md)" "### Programs"
assert_contains "AC-10: autonomous-execution has the in-session section" \
    "$(read_file rules/autonomous-execution.md)" "### In-Session Program Direction"
assert_contains "AC-10: agent-conventions allows worktree writes" \
    "$(read_file rules/agent-conventions.md)" "inside its own worktree"
assert_contains "AC-10: define.md shapes programs" "$(read_file commands/define.md)" "### Programs"

# Arrange
install_dir=$(mktemp -d)
trap 'rm -rf "$install_dir"' EXIT

# Act
bash install.sh project "$install_dir" --agents --commands --schemas >/dev/null 2>&1

# Assert
assert_file "AC-10: install copies the Director genie" "$install_dir/.claude/agents/director.md"
assert_file "AC-10: install copies /direct" "$install_dir/.claude/commands/direct.md"
assert_file "AC-10: install copies the board schema" "$install_dir/.claude/schemas/program-board.schema.md"

# ── Summary ──────────────────────────────────────────────────
echo ""
echo "test_director: $pass passed, $fail failed"
[[ $fail -eq 0 ]]
