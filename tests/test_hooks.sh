#!/bin/bash
# Tests for hooks/ scripts (canonical sources)
# Run: bash tests/test_hooks.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"

# Hook scripts under test (canonical sources)
TRACK_COMMAND="$PROJECT_DIR/hooks/track-command.sh"
TRACK_ARTIFACTS="$PROJECT_DIR/hooks/track-artifacts.sh"
REINJECT_CONTEXT="$PROJECT_DIR/hooks/reinject-context.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Temp directory for test isolation
TEST_TMP=""

setup() {
    TEST_TMP=$(mktemp -d)
    mkdir -p "$TEST_TMP/.claude/hooks"
    mkdir -p "$TEST_TMP/docs/backlog"
    # Copy the test fixture backlog item
    cp "$FIXTURES_DIR/hook_test_backlog.md" "$TEST_TMP/docs/backlog/P2-test-feature.md"
}

teardown() {
    rm -rf "$TEST_TMP"
}

# Test helpers (same pattern as test_execute.sh)
assert_eq() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected: '$expected'"
        echo "  Actual:   '$actual'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if echo "$haystack" | grep -qF -- "$needle"; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected to contain: '$needle'"
        echo "  In: '$(echo "$haystack" | head -5)...'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if echo "$haystack" | grep -qF -- "$needle"; then
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected NOT to contain: '$needle'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
}

assert_file_exists() {
    local path="$1"
    local test_name="$2"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -f "$path" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  File not found: $path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_file_not_exists() {
    local path="$1"
    local test_name="$2"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ ! -f "$path" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  File should not exist: $path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_exit_code() {
    local expected="$1"
    local actual="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ "$expected" == "$actual" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected exit code: $expected"
        echo "  Actual exit code:   $actual"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

line_count() {
    echo "$1" | grep -c "$2"
}

# ─────────────────────────────────────────────
echo "=== Hook Tests ==="
echo ""

# ─────────────────────────────────────────────
# Test: track-command.sh
# ─────────────────────────────────────────────
echo "--- track-command.sh ---"

# AC-2: Captures genie slash command and creates state file
setup
echo '{"prompt":"/deliver docs/backlog/P2-test-feature.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"
ec=$?

assert_exit_code "0" "$ec" \
    "track-command: exits 0 for slash command"

assert_file_exists "$TEST_TMP/.claude/session-state.md" \
    "track-command: creates session-state.md for slash command"

state=$(cat "$TEST_TMP/.claude/session-state.md")
assert_contains "$state" "/deliver docs/backlog/P2-test-feature.md" \
    "track-command: state file contains the command invoked"

assert_contains "$state" "Test Feature for Hook Testing" \
    "track-command: state file contains backlog item title"

assert_contains "$state" "designed" \
    "track-command: state file contains backlog item status"

assert_contains "$state" "docs/specs/identity/token-auth.md" \
    "track-command: state file contains spec_ref"

assert_contains "$state" "ADR-015" \
    "track-command: state file contains adr_refs"
teardown

# AC-2: Ignores non-slash-command prompts (no state file created)
setup
echo '{"prompt":"what files handle routing?","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"
ec=$?

assert_exit_code "0" "$ec" \
    "track-command: exits 0 for plain text"

assert_file_not_exists "$TEST_TMP/.claude/session-state.md" \
    "track-command: does NOT create state file for plain text"
teardown

# AC-2: Handles missing backlog item gracefully
setup
echo '{"prompt":"/deliver docs/backlog/nonexistent.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"
ec=$?

assert_exit_code "0" "$ec" \
    "track-command: exits 0 even if backlog item missing"

assert_file_exists "$TEST_TMP/.claude/session-state.md" \
    "track-command: creates state file even without backlog item"

state=$(cat "$TEST_TMP/.claude/session-state.md")
assert_contains "$state" "/deliver docs/backlog/nonexistent.md" \
    "track-command: state file still contains the command"
teardown

# AC-2: Overwrites state file on new command (fresh tracking)
setup
echo '{"prompt":"/define something","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"
echo '{"prompt":"/deliver docs/backlog/P2-test-feature.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"

state=$(cat "$TEST_TMP/.claude/session-state.md")
assert_not_contains "$state" "/define something" \
    "track-command: new command overwrites previous state"
assert_contains "$state" "/deliver" \
    "track-command: state file reflects latest command"
teardown

# AC-2: Handles commands without arguments
setup
echo '{"prompt":"/genie:status","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"
ec=$?

assert_exit_code "0" "$ec" \
    "track-command: exits 0 for command without arguments"

state=$(cat "$TEST_TMP/.claude/session-state.md")
assert_contains "$state" "/genie:status" \
    "track-command: captures command without arguments"
teardown

# ─────────────────────────────────────────────
# Test: track-artifacts.sh
# ─────────────────────────────────────────────
echo ""
echo "--- track-artifacts.sh ---"

# AC-2: Appends written file paths to state file
setup
# First create a state file (as track-command would)
echo '{"prompt":"/deliver docs/backlog/P2-test-feature.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"

echo '{"tool_input":{"file_path":"'"$TEST_TMP"'/src/auth/token-service.ts"},"cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_ARTIFACTS"
ec=$?

assert_exit_code "0" "$ec" \
    "track-artifacts: exits 0"

state=$(cat "$TEST_TMP/.claude/session-state.md")
assert_contains "$state" "src/auth/token-service.ts" \
    "track-artifacts: state file contains written file path"
teardown

# AC-2: Skips if no state file exists
setup
echo '{"tool_input":{"file_path":"'"$TEST_TMP"'/src/foo.ts"},"cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_ARTIFACTS"
ec=$?

assert_exit_code "0" "$ec" \
    "track-artifacts: exits 0 when no state file"

assert_file_not_exists "$TEST_TMP/.claude/session-state.md" \
    "track-artifacts: does not create state file"
teardown

# AC-2: Deduplicates file paths
setup
echo '{"prompt":"/deliver docs/backlog/P2-test-feature.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"

echo '{"tool_input":{"file_path":"'"$TEST_TMP"'/src/auth.ts"},"cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_ARTIFACTS"
echo '{"tool_input":{"file_path":"'"$TEST_TMP"'/src/auth.ts"},"cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_ARTIFACTS"

state=$(cat "$TEST_TMP/.claude/session-state.md")
count=$(echo "$state" | grep -c "src/auth.ts")
assert_eq "1" "$count" \
    "track-artifacts: deduplicates same file path"
teardown

# AC-2: Caps artifact list at 20 entries
setup
echo '{"prompt":"/deliver docs/backlog/P2-test-feature.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"

for i in $(seq 1 25); do
    echo '{"tool_input":{"file_path":"'"$TEST_TMP"'/src/file-'"$i"'.ts"},"cwd":"'"$TEST_TMP"'"}' \
        | bash "$TRACK_ARTIFACTS"
done

state=$(cat "$TEST_TMP/.claude/session-state.md")
artifact_count=$(echo "$state" | grep -c "^- ")
# Should have at most 20 artifact lines
if [[ "$artifact_count" -le 20 ]]; then
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${GREEN}PASS${NC} track-artifacts: caps at 20 entries (found $artifact_count)"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    TESTS_RUN=$((TESTS_RUN + 1))
    echo -e "${RED}FAIL${NC} track-artifacts: caps at 20 entries (found $artifact_count)"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# Most recent files should be kept
assert_contains "$state" "file-25.ts" \
    "track-artifacts: keeps most recent entries"
teardown

# AC-2: Skips self-reference (state file itself)
setup
echo '{"prompt":"/deliver docs/backlog/P2-test-feature.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"

echo '{"tool_input":{"file_path":"'"$TEST_TMP"'/.claude/session-state.md"},"cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_ARTIFACTS"

state=$(cat "$TEST_TMP/.claude/session-state.md")
assert_not_contains "$state" "session-state.md" \
    "track-artifacts: does not track writes to state file itself"
teardown

# ─────────────────────────────────────────────
# Test: reinject-context.sh
# ─────────────────────────────────────────────
echo ""
echo "--- reinject-context.sh ---"

# AC-1: Re-injects context from state file on compact
setup
echo '{"prompt":"/deliver docs/backlog/P2-test-feature.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"
echo '{"tool_input":{"file_path":"'"$TEST_TMP"'/src/auth.ts"},"cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_ARTIFACTS"

output=$(echo '{"cwd":"'"$TEST_TMP"'","hook_event_name":"SessionStart"}' \
    | bash "$REINJECT_CONTEXT")
ec=$?

assert_exit_code "0" "$ec" \
    "reinject-context: exits 0"

assert_contains "$output" "/deliver" \
    "reinject-context: output contains the active command"

assert_contains "$output" "Test Feature" \
    "reinject-context: output contains backlog item title"

assert_contains "$output" "src/auth.ts" \
    "reinject-context: output contains artifacts written"
teardown

# AC-1: Prints nothing if no state file exists
setup
output=$(echo '{"cwd":"'"$TEST_TMP"'","hook_event_name":"SessionStart"}' \
    | bash "$REINJECT_CONTEXT")
ec=$?

assert_exit_code "0" "$ec" \
    "reinject-context: exits 0 when no state file"

assert_eq "" "$output" \
    "reinject-context: prints nothing when no state file"
teardown

# AC-1: Includes backlog item frontmatter when file exists
setup
echo '{"prompt":"/deliver docs/backlog/P2-test-feature.md","cwd":"'"$TEST_TMP"'"}' \
    | bash "$TRACK_COMMAND"

output=$(echo '{"cwd":"'"$TEST_TMP"'","hook_event_name":"SessionStart"}' \
    | bash "$REINJECT_CONTEXT")

assert_contains "$output" "spec_ref" \
    "reinject-context: includes spec_ref from backlog frontmatter"

assert_contains "$output" "adr_refs" \
    "reinject-context: includes adr_refs from backlog frontmatter"
teardown

# AC-3: All hooks are command hooks (no LLM invocation)
# This is a structural test — verify scripts don't contain prompt/agent patterns
for script in "$TRACK_COMMAND" "$TRACK_ARTIFACTS" "$REINJECT_CONTEXT"; do
    if [[ -f "$script" ]]; then
        script_name=$(basename "$script")
        content=$(cat "$script")

        assert_not_contains "$content" '"type": "prompt"' \
            "AC-3: $script_name is not a prompt hook"
        assert_not_contains "$content" '"type": "agent"' \
            "AC-3: $script_name is not an agent hook"
    fi
done

# ─────────────────────────────────────────────
# Summary
# ─────────────────────────────────────────────
echo ""
echo "==========================="
echo -e "Tests: $TESTS_RUN | ${GREEN}Passed: $TESTS_PASSED${NC} | ${RED}Failed: $TESTS_FAILED${NC}"
echo "==========================="

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
else
    exit 0
fi
