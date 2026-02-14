#!/bin/bash
# Tests for scripts/run-pdlc.sh — autonomous PDLC runner
# Run: bash tests/test_run_pdlc.sh
#
# TDD Phase 1: All tests written first (RED). Implementation follows.

# Note: set -e intentionally omitted — test harness manages its own exit codes
# via assert_* helpers and TESTS_FAILED counter

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_PDLC="$PROJECT_DIR/scripts/run-pdlc.sh"
MOCK_CLAUDE="$SCRIPT_DIR/fixtures/mock_claude.sh"
MOCK_RESPONSES="$SCRIPT_DIR/fixtures/mock_claude_responses"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
# shellcheck disable=SC2034  # YELLOW used in log output
YELLOW='\033[1;33m'
NC='\033[0m'

# ─────────────────────────────────────────────
# Test helpers (same framework as test_worktree.sh)
# ─────────────────────────────────────────────

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
        echo "  Actual: '$haystack'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# shellcheck disable=SC2329  # Available for tests that need it
assert_not_contains() {
    local haystack="$1"
    local needle="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if ! echo "$haystack" | grep -qF -- "$needle"; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected NOT to contain: '$needle'"
        echo "  Actual: '$haystack'"
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

assert_file_exists() {
    local path="$1"
    local test_name="$2"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -e "$path" ]]; then
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

    if [[ ! -e "$path" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  File should not exist: $path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ─────────────────────────────────────────────
# Source run-pdlc.sh for unit testing functions
# ─────────────────────────────────────────────

if [[ -f "$RUN_PDLC" ]]; then
    # shellcheck disable=SC2034  # Used by run-pdlc.sh source guard
    RUN_PDLC_SOURCED=true
    # shellcheck source=/dev/null
    source "$RUN_PDLC"
    # run-pdlc.sh sets -e; disable it — test harness manages its own exit codes
    set +e
else
    echo -e "${RED}ERROR${NC} run-pdlc.sh not found at $RUN_PDLC"
    echo "Tests require the implementation to exist (even if incomplete)."
    echo "Create a minimal scripts/run-pdlc.sh to start TDD."
    exit 2
fi

# ─────────────────────────────────────────────
# Setup / teardown for tests that need temp dirs
# ─────────────────────────────────────────────

setup_temp() {
    TEMP_DIR="$(mktemp -d)"
    export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
    export MOCK_INVOCATION_LOG="$TEMP_DIR/invocations.log"
    # Create mock bin dir with mock claude on PATH
    MOCK_BIN="$TEMP_DIR/bin"
    mkdir -p "$MOCK_BIN"
    cp "$MOCK_CLAUDE" "$MOCK_BIN/claude"
    chmod +x "$MOCK_BIN/claude"
    export PATH="$MOCK_BIN:$PATH"
}

teardown_temp() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        rm -rf "$TEMP_DIR"
    fi
}

echo "=== run-pdlc.sh Tests ==="
echo ""

# ═══════════════════════════════════════════════
# Category 1: phase_index (3 tests)
# ═══════════════════════════════════════════════

echo "--- phase_index ---"

# Arrange — discover is the first phase
# Act
result=$(phase_index "discover")
ec=$?
# Assert
assert_eq "0" "$result" "phase_index: discover returns 0"

# Arrange — done is the last phase
# Act
result=$(phase_index "done")
ec=$?
# Assert
assert_eq "6" "$result" "phase_index: done returns 6"

# Arrange — invalid phase name
# Act
result=$(phase_index "invalid" 2>/dev/null)
ec=$?
# Assert
assert_exit_code "1" "$ec" "phase_index: invalid phase returns exit 1"

# ═══════════════════════════════════════════════
# Category 2: parse_args (8 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- parse_args ---"

# Test: defaults (no flags)
# Arrange — no flags, just topic
# Act
parse_args "test topic"
# Assert
assert_eq "discover" "$FROM_PHASE" "parse_args: default FROM_PHASE is discover"
assert_eq "done" "$THROUGH_PHASE" "parse_args: default THROUGH_PHASE is done"
assert_eq "test topic" "$INPUT" "parse_args: captures topic as INPUT"

# Test: --from and --through
# Arrange
# Act
parse_args --from design --through deliver "docs/backlog/P2-item.md"
# Assert
assert_eq "design" "$FROM_PHASE" "parse_args: --from sets FROM_PHASE"
assert_eq "deliver" "$THROUGH_PHASE" "parse_args: --through sets THROUGH_PHASE"
assert_eq "docs/backlog/P2-item.md" "$INPUT" "parse_args: captures file path as INPUT"

# Test: --deliver-turns override
# Arrange
# Act
parse_args --deliver-turns 200 "test topic"
# Assert
assert_eq "200" "$DELIVER_TURNS" "parse_args: --deliver-turns sets DELIVER_TURNS"

# Test: --turns-per-phase override
# Arrange
# Act
parse_args --turns-per-phase 80 "test topic"
# Assert
assert_eq "80" "$TURNS_PER_PHASE" "parse_args: --turns-per-phase sets TURNS_PER_PHASE"

# Test: --worktree flag
# Arrange
# Act
parse_args --worktree "test topic"
# Assert
assert_eq "true" "$USE_WORKTREE" "parse_args: --worktree sets USE_WORKTREE"

# Test: --log-dir
# Arrange
# Act
parse_args --log-dir /var/log/genie "test topic"
# Assert
assert_eq "/var/log/genie" "$LOG_DIR" "parse_args: --log-dir sets LOG_DIR"

# Test: --lock flag
# Arrange
# Act
parse_args --lock "test topic"
# Assert
assert_eq "true" "$USE_LOCK" "parse_args: --lock sets USE_LOCK"

# Test: --no-resume flag
# Arrange
# Act
parse_args --no-resume "test topic"
# Assert
assert_eq "true" "$NO_RESUME" "parse_args: --no-resume sets NO_RESUME"

# ═══════════════════════════════════════════════
# Category 3: validate_args (3 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- validate_args ---"

# Test: design+ phases need a file path, not a topic string
# Arrange
FROM_PHASE="design"
THROUGH_PHASE="done"
INPUT="just a topic string"
# Act
result=$(validate_args 2>&1)
ec=$?
# Assert
assert_exit_code "3" "$ec" "validate_args: design+ with topic string exits 3"

# Test: --from after --through exits 3
# Arrange
FROM_PHASE="design"
THROUGH_PHASE="define"
INPUT="docs/backlog/P2-item.md"
# Act
result=$(validate_args 2>&1)
ec=$?
# Assert
assert_exit_code "3" "$ec" "validate_args: from after through exits 3"

# Test: valid args pass
# Arrange
FROM_PHASE="discover"
THROUGH_PHASE="define"
INPUT="test topic"
# Act
result=$(validate_args 2>&1)
ec=$?
# Assert
assert_exit_code "0" "$ec" "validate_args: valid discover-through-define passes"

# ═══════════════════════════════════════════════
# Category 4: parse_artifact_path (5 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- parse_artifact_path ---"

# Test: extract analysis path
# Arrange
output="Discovery complete. Created opportunity snapshot at docs/analysis/20260212_discover_test_topic.md"
# Act
result=$(parse_artifact_path "$output" "analysis")
ec=$?
# Assert
assert_eq "docs/analysis/20260212_discover_test_topic.md" "$result" \
    "parse_artifact_path: extracts analysis path"

# Test: extract backlog path
# Arrange
output="Shaped work contract created at docs/backlog/P2-test-topic.md"
# Act
result=$(parse_artifact_path "$output" "backlog")
ec=$?
# Assert
assert_eq "docs/backlog/P2-test-topic.md" "$result" \
    "parse_artifact_path: extracts backlog path"

# Test: first match wins when multiple paths present
# Arrange
output="Created docs/analysis/20260212_a.md and also mentioned docs/analysis/20260212_b.md"
# Act
result=$(parse_artifact_path "$output" "analysis")
# Assert
assert_eq "docs/analysis/20260212_a.md" "$result" \
    "parse_artifact_path: first match wins"

# Test: no match returns 1
# Arrange
output="No paths here, just text."
# Act
result=$(parse_artifact_path "$output" "analysis" 2>/dev/null)
ec=$?
# Assert
assert_exit_code "1" "$ec" "parse_artifact_path: no match returns 1"

# Test: fallback via git diff (parse_artifact_fallback)
# Arrange — set up a temp git repo with a new file
setup_temp
mkdir -p "$TEMP_DIR/repo/docs/backlog"
git -C "$TEMP_DIR/repo" init -q
git -C "$TEMP_DIR/repo" commit --allow-empty -m "init" -q
echo "test" > "$TEMP_DIR/repo/docs/backlog/P2-new-item.md"
git -C "$TEMP_DIR/repo" add docs/backlog/P2-new-item.md
# Act
result=$(cd "$TEMP_DIR/repo" && parse_artifact_fallback "backlog")
ec=$?
# Assert
assert_eq "docs/backlog/P2-new-item.md" "$result" \
    "parse_artifact_fallback: finds newly added backlog file via git diff"
teardown_temp

# ═══════════════════════════════════════════════
# Category 5: detect_verdict (4 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- detect_verdict ---"

# Test: APPROVED
# Arrange
output="Verdict: APPROVED\nAll criteria met."
# Act
result=$(detect_verdict "$output")
ec=$?
# Assert
assert_eq "APPROVED" "$result" "detect_verdict: detects APPROVED"

# Test: BLOCKED
# Arrange
output="Verdict: BLOCKED\nAC-2 not met."
# Act
result=$(detect_verdict "$output")
ec=$?
# Assert
assert_eq "BLOCKED" "$result" "detect_verdict: detects BLOCKED"

# Test: CHANGES REQUESTED
# Arrange
output="Verdict: CHANGES REQUESTED\nMinor issues."
# Act
result=$(detect_verdict "$output")
ec=$?
# Assert
assert_eq "CHANGES REQUESTED" "$result" "detect_verdict: detects CHANGES REQUESTED"

# Test: no verdict returns 1
# Arrange
output="Review complete but no verdict keyword here."
# Act
result=$(detect_verdict "$output" 2>/dev/null)
ec=$?
# Assert
assert_exit_code "1" "$ec" "detect_verdict: no verdict returns 1"

# ═══════════════════════════════════════════════
# Category 6: lockfile (4 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- lockfile ---"

# Test: acquire_lock creates file with PID
# Arrange
setup_temp
LOCK_DIR="$TEMP_DIR/locks"
mkdir -p "$LOCK_DIR"
# Act
acquire_lock "test-input" "$LOCK_DIR"
ec=$?
# Assert
assert_exit_code "0" "$ec" "acquire_lock: succeeds"
lockfile=$(find "$LOCK_DIR" -name '*.lock' -print -quit 2>/dev/null)
if [[ -n "$lockfile" ]]; then
    lock_content=$(cat "$lockfile")
    assert_contains "$lock_content" "$$" "acquire_lock: lockfile contains PID"
else
    assert_file_exists "$LOCK_DIR/nonexistent" "acquire_lock: lockfile was created"
fi
release_lock 2>/dev/null
teardown_temp

# Test: acquire_lock exits 3 when lock held by running process
# Arrange
setup_temp
LOCK_DIR="$TEMP_DIR/locks"
mkdir -p "$LOCK_DIR"
# Create a lock with a process that's actually running (use our own PID)
acquire_lock "test-input" "$LOCK_DIR"
# Act — try to acquire the same lock again
result=$(acquire_lock "test-input" "$LOCK_DIR" 2>&1)
ec=$?
# Assert
assert_exit_code "3" "$ec" "acquire_lock: exits 3 when lock held"
release_lock 2>/dev/null
teardown_temp

# Test: acquire_lock overwrites stale lock (old PID)
# Arrange
setup_temp
LOCK_DIR="$TEMP_DIR/locks"
mkdir -p "$LOCK_DIR"
# Create a stale lock with a PID that doesn't exist
input_hash=$(echo -n "test-stale" | shasum | cut -d' ' -f1)
stale_lock="$LOCK_DIR/${input_hash}.lock"
echo "99999" > "$stale_lock"
# Backdate the lock file to be stale (5 hours old)
touch -t "$(date -v-5H +%Y%m%d%H%M.%S 2>/dev/null || date -d '5 hours ago' +%Y%m%d%H%M.%S 2>/dev/null)" "$stale_lock" 2>/dev/null || true
# Act
acquire_lock "test-stale" "$LOCK_DIR"
ec=$?
# Assert
assert_exit_code "0" "$ec" "acquire_lock: overwrites stale lock"
release_lock 2>/dev/null
teardown_temp

# Test: release_lock removes lockfile
# Arrange
setup_temp
LOCK_DIR="$TEMP_DIR/locks"
mkdir -p "$LOCK_DIR"
acquire_lock "test-release" "$LOCK_DIR"
lockfile=$(find "$LOCK_DIR" -name '*.lock' -print -quit 2>/dev/null)
# Act
release_lock
# Assert
assert_file_not_exists "${lockfile:-$LOCK_DIR/nonexistent.lock}" \
    "release_lock: removes lockfile"
teardown_temp

# ═══════════════════════════════════════════════
# Category 7: build_phase_prompt (3 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- build_phase_prompt ---"

# Test: discover + topic
# Arrange
# Act
result=$(build_phase_prompt "discover" "user authentication")
# Assert
assert_contains "$result" "/discover" "build_phase_prompt: discover includes /discover"
assert_contains "$result" "user authentication" "build_phase_prompt: discover includes topic"

# Test: define + analysis path
# Arrange
# Act
result=$(build_phase_prompt "define" "docs/analysis/20260212_discover_auth.md")
# Assert
assert_contains "$result" "/define" "build_phase_prompt: define includes /define"
assert_contains "$result" "docs/analysis/20260212_discover_auth.md" \
    "build_phase_prompt: define includes analysis path"

# Test: design + backlog path
# Arrange
# Act
result=$(build_phase_prompt "design" "docs/backlog/P2-auth.md")
# Assert
assert_contains "$result" "/design" "build_phase_prompt: design includes /design"
assert_contains "$result" "docs/backlog/P2-auth.md" \
    "build_phase_prompt: design includes backlog path"

# ═══════════════════════════════════════════════
# Category 7b: --trunk flag and trunk mode (6 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- --trunk flag ---"

# Test: --trunk default is false
# Arrange
# Act
parse_args "test topic"
# Assert
assert_eq "false" "$TRUNK_MODE" "parse_args: default TRUNK_MODE is false"

# Test: --trunk sets TRUNK_MODE=true
# Arrange
# Act
parse_args --trunk "test topic"
# Assert
assert_eq "true" "$TRUNK_MODE" "parse_args: --trunk sets TRUNK_MODE=true"

# Test: build_phase_prompt with TRUNK_MODE=true prepends git-mode prefix
# Arrange
TRUNK_MODE="true"
# Act
result=$(build_phase_prompt "deliver" "docs/backlog/P2-item.md")
# Assert
assert_eq "git-mode: trunk. /deliver docs/backlog/P2-item.md" "$result" \
    "build_phase_prompt: trunk mode prepends git-mode prefix"

# Test: build_phase_prompt with TRUNK_MODE=false produces normal prompt
# Arrange
TRUNK_MODE="false"
# Act
result=$(build_phase_prompt "deliver" "docs/backlog/P2-item.md")
# Assert
assert_eq "/deliver docs/backlog/P2-item.md" "$result" \
    "build_phase_prompt: non-trunk mode produces normal prompt"

# Test: --trunk combined with --worktree both set correctly
# Arrange
# Act
parse_args --trunk --worktree "docs/backlog/P2-item.md"
# Assert
assert_eq "true" "$TRUNK_MODE" "parse_args: --trunk + --worktree sets TRUNK_MODE"
assert_eq "true" "$USE_WORKTREE" "parse_args: --trunk + --worktree sets USE_WORKTREE"

# Test: --trunk combined with other flags doesn't interfere
# Arrange
# Act
parse_args --trunk --from deliver --through "done" --lock "docs/backlog/P2-item.md"
# Assert
assert_eq "true" "$TRUNK_MODE" "parse_args: --trunk with other flags sets TRUNK_MODE"
assert_eq "deliver" "$FROM_PHASE" "parse_args: --trunk doesn't interfere with --from"
assert_eq "done" "$THROUGH_PHASE" "parse_args: --trunk doesn't interfere with --through"
assert_eq "true" "$USE_LOCK" "parse_args: --trunk doesn't interfere with --lock"

# ═══════════════════════════════════════════════
# Category 7c: --verbose flag (3 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- --verbose flag ---"

# Test: --verbose default is false
# Arrange
# Act
parse_args "test topic"
# Assert
assert_eq "false" "$VERBOSE_LOGGING" "parse_args: default VERBOSE_LOGGING is false"

# Test: --verbose sets VERBOSE_LOGGING=true
# Arrange
# Act
parse_args --verbose "test topic"
# Assert
assert_eq "true" "$VERBOSE_LOGGING" "parse_args: --verbose sets VERBOSE_LOGGING=true"

# Test: --verbose combined with --trunk and --worktree
# Arrange
# Act
parse_args --verbose --trunk --worktree "docs/backlog/P2-item.md"
# Assert
assert_eq "true" "$VERBOSE_LOGGING" "parse_args: --verbose + --trunk + --worktree sets VERBOSE_LOGGING"
assert_eq "true" "$TRUNK_MODE" "parse_args: --verbose doesn't interfere with --trunk"
assert_eq "true" "$USE_WORKTREE" "parse_args: --verbose doesn't interfere with --worktree"

# Test: --skip-permissions flag
# Arrange
# Act
parse_args --skip-permissions "test topic"
# Assert
assert_eq "true" "$SKIP_PERMISSIONS" "parse_args: --skip-permissions sets SKIP_PERMISSIONS"

# Test: --skip-permissions default is false
# Arrange
# Act
parse_args "test topic"
# Assert
assert_eq "false" "$SKIP_PERMISSIONS" "parse_args: default SKIP_PERMISSIONS is false"

# ═══════════════════════════════════════════════
# Category 7d: --finish-mode flag (5 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- --finish-mode flag ---"

# Test: --finish-mode default is --merge
# Arrange
# Act
parse_args "test topic"
# Assert
assert_eq "--merge" "$FINISH_MODE" "parse_args: default FINISH_MODE is --merge"

# Test: --finish-mode --leave-branch sets FINISH_MODE
# Arrange
# Act
parse_args --finish-mode --leave-branch "test topic"
# Assert
assert_eq "--leave-branch" "$FINISH_MODE" "parse_args: --finish-mode --leave-branch sets FINISH_MODE"

# Test: --finish-mode --pr sets FINISH_MODE
# Arrange
# Act
parse_args --finish-mode --pr "test topic"
# Assert
assert_eq "--pr" "$FINISH_MODE" "parse_args: --finish-mode --pr sets FINISH_MODE"

# Test: --finish-mode combined with --worktree --trunk
# Arrange
# Act
parse_args --finish-mode --leave-branch --worktree --trunk "docs/backlog/P2-item.md"
# Assert
assert_eq "--leave-branch" "$FINISH_MODE" "parse_args: --finish-mode with --worktree --trunk sets FINISH_MODE"
assert_eq "true" "$USE_WORKTREE" "parse_args: --finish-mode doesn't interfere with --worktree"
assert_eq "true" "$TRUNK_MODE" "parse_args: --finish-mode doesn't interfere with --trunk"

# Test: worktree_teardown_success passes finish mode to session_finish
# Arrange — mock session_finish to capture args
setup_temp
_original_session_finish=$(declare -f session_finish)
session_finish() { echo "CALLED:$1:$2" > "$TEMP_DIR/session_finish_call.log"; return 0; }
# Act
worktree_teardown_success "P2-test-item" "--leave-branch"
# Assert
call_log=$(cat "$TEMP_DIR/session_finish_call.log" 2>/dev/null)
assert_eq "CALLED:P2-test-item:--leave-branch" "$call_log" \
    "worktree_teardown_success: passes finish mode to session_finish"
# Restore original
eval "$_original_session_finish"
teardown_temp

# ═══════════════════════════════════════════════
# Category 7e: --slug flag (3 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- --slug flag ---"

# Test: --slug default is empty
# Arrange
# Act
parse_args "test topic"
# Assert
assert_eq "" "$WORKTREE_SLUG" "parse_args: default WORKTREE_SLUG is empty"

# Test: --slug my-item sets WORKTREE_SLUG
# Arrange
# Act
parse_args --slug discover-1 "test topic"
# Assert
assert_eq "discover-1" "$WORKTREE_SLUG" "parse_args: --slug sets WORKTREE_SLUG"

# Test: --slug combined with --worktree
# Arrange
# Act
parse_args --slug discover-2 --worktree "test topic"
# Assert
assert_eq "discover-2" "$WORKTREE_SLUG" "parse_args: --slug with --worktree sets WORKTREE_SLUG"
assert_eq "true" "$USE_WORKTREE" "parse_args: --slug doesn't interfere with --worktree"

# ═══════════════════════════════════════════════
# Category 8: run_phase (5 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- run_phase ---"

# Test: captures output, session_id, and phase metrics
# Arrange
setup_temp
NO_RESUME="false"
TURNS_PER_PHASE=""
VERBOSE_LOGGING="false"
# shellcheck disable=SC2034  # Used by sourced run-pdlc.sh
DISCOVER_TURNS=""
# Act
run_phase "discover" "test topic"
ec=$?
# Assert
assert_exit_code "0" "$ec" "run_phase: succeeds for discover"
# shellcheck disable=SC2153  # OUTPUT is set by run_phase()
assert_contains "$OUTPUT" "Discovery complete" "run_phase: captures output text"
assert_contains "$SESSION_ID" "mock-session" "run_phase: captures session_id"
assert_eq "38" "$PHASE_NUM_TURNS" "run_phase: captures num_turns from JSON"
teardown_temp

# Test: propagates claude exit code 1
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/fail_responses"
cp "$MOCK_RESPONSES"/*.json "$TEMP_DIR/fail_responses/"
touch "$TEMP_DIR/fail_responses/discover_fail"
export MOCK_CLAUDE_RESPONSES_DIR="$TEMP_DIR/fail_responses"
NO_RESUME="false"
TURNS_PER_PHASE=""
# shellcheck disable=SC2034  # Used by sourced run-pdlc.sh
DISCOVER_TURNS=""
# Act
run_phase "discover" "test topic"
ec=$?
# Assert
assert_exit_code "1" "$ec" "run_phase: propagates exit code 1 on failure"
export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
teardown_temp

# Test: propagates claude exit code 2 (turn exhaustion)
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/exhaust_responses"
cp "$MOCK_RESPONSES"/*.json "$TEMP_DIR/exhaust_responses/"
touch "$TEMP_DIR/exhaust_responses/deliver_exhaust"
export MOCK_CLAUDE_RESPONSES_DIR="$TEMP_DIR/exhaust_responses"
SESSION_ID=""
NO_RESUME="false"
TURNS_PER_PHASE=""
DELIVER_TURNS=""
# Act
run_phase "deliver" "docs/backlog/P2-item.md"
ec=$?
# Assert
assert_exit_code "2" "$ec" "run_phase: propagates exit code 2 for turn exhaustion"
export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
teardown_temp

# Test: correct --max-turns passed
# Arrange
setup_temp
SESSION_ID=""
NO_RESUME="false"
TURNS_PER_PHASE=""
DELIVER_TURNS="200"
# Act
run_phase "deliver" "docs/backlog/P2-item.md"
# Assert — check invocation log for max_turns
log_content=$(cat "$MOCK_INVOCATION_LOG" 2>/dev/null)
assert_contains "$log_content" "max_turns=200" \
    "run_phase: passes --deliver-turns override to claude"
teardown_temp

# ═══════════════════════════════════════════════
# Category 9: retry (2 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- retry_phase ---"

# Test: retry succeeds → continue
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/retry_responses"
cp "$MOCK_RESPONSES"/*.json "$TEMP_DIR/retry_responses/"
# First call exhausts (exit 2), resume call succeeds (normal response)
touch "$TEMP_DIR/retry_responses/deliver_exhaust"
export MOCK_CLAUDE_RESPONSES_DIR="$TEMP_DIR/retry_responses"
NO_RESUME="false"
TURNS_PER_PHASE=""
DELIVER_TURNS=""
# Act
retry_phase "deliver" "docs/backlog/P2-item.md" "mock-session-deliver"
ec=$?
# Assert
assert_exit_code "0" "$ec" "retry_phase: succeeds when retry works"
export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
teardown_temp

# Test: double exhaust → exit 1
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/double_responses"
cp "$MOCK_RESPONSES"/*.json "$TEMP_DIR/double_responses/"
touch "$TEMP_DIR/double_responses/deliver_exhaust"
touch "$TEMP_DIR/double_responses/deliver_double_exhaust"
export MOCK_CLAUDE_RESPONSES_DIR="$TEMP_DIR/double_responses"
NO_RESUME="false"
TURNS_PER_PHASE=""
DELIVER_TURNS=""
# Act
retry_phase "deliver" "docs/backlog/P2-item.md" "mock-session-deliver"
ec=$?
# Assert
assert_exit_code "1" "$ec" "retry_phase: exits 1 on double exhaustion"
export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
teardown_temp

# ═══════════════════════════════════════════════
# Category 10: log_phase_usage (2 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- log_phase_usage ---"

# Test: writes JSON to log dir
# Arrange
setup_temp
LOG_DIR="$TEMP_DIR/logs"
# Act
log_phase_usage "discover" "38" "12847" "15"
# Assert
assert_file_exists "$LOG_DIR/run-pdlc.jsonl" "log_phase_usage: creates jsonl file"
log_line=$(head -1 "$LOG_DIR/run-pdlc.jsonl" 2>/dev/null)
assert_contains "$log_line" '"phase":"discover"' "log_phase_usage: logs phase name"
assert_contains "$log_line" '"turns":38' "log_phase_usage: logs turn count"
assert_contains "$log_line" '"tokens":12847' "log_phase_usage: logs token count"
teardown_temp

# Test: no-op when LOG_DIR is empty
# Arrange
setup_temp
LOG_DIR=""
# Act — should not create any files
log_phase_usage "discover" "38" "12847" "15"
# Assert
assert_file_not_exists "$TEMP_DIR/logs/run-pdlc.jsonl" \
    "log_phase_usage: no-op when LOG_DIR empty"
teardown_temp

# ═══════════════════════════════════════════════
# Category 11: main / exit codes (3 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- main / exit codes ---"

# Test: successful through-define run exits 0
# Arrange
setup_temp
# Act — run as subprocess to test main()
output=$("$RUN_PDLC" --through define "test topic" 2>&1)
ec=$?
# Assert
assert_exit_code "0" "$ec" "main: --through define exits 0 on success"
teardown_temp

# Test: BLOCKED verdict exits 1
# Arrange
setup_temp
# Override discern response to blocked
mkdir -p "$TEMP_DIR/blocked_responses"
cp "$MOCK_RESPONSES"/*.json "$TEMP_DIR/blocked_responses/"
cp "$MOCK_RESPONSES/discern_blocked.json" "$TEMP_DIR/blocked_responses/discern.json"
export MOCK_CLAUDE_RESPONSES_DIR="$TEMP_DIR/blocked_responses"
# Act — run full lifecycle (includes discern)
output=$("$RUN_PDLC" "test topic" 2>&1)
ec=$?
# Assert
assert_exit_code "1" "$ec" "main: BLOCKED verdict exits 1"
export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
teardown_temp

# Test: validation error exits 3
# Arrange
setup_temp
# Act — --from after --through
output=$("$RUN_PDLC" --from design --through define "docs/backlog/P2-item.md" 2>&1)
ec=$?
# Assert
assert_exit_code "3" "$ec" "main: validation error exits 3"
teardown_temp

# ═══════════════════════════════════════════════
# Category 12: Batch mode — status_to_phase (7 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- status_to_phase ---"

# Test: defined maps to design
result=$(status_to_phase "defined")
assert_eq "design" "$result" "status_to_phase: defined → design"

# Test: shaped maps to design
result=$(status_to_phase "shaped")
assert_eq "design" "$result" "status_to_phase: shaped → design"

# Test: designed maps to deliver
result=$(status_to_phase "designed")
assert_eq "deliver" "$result" "status_to_phase: designed → deliver"

# Test: implemented maps to discern
result=$(status_to_phase "implemented")
assert_eq "discern" "$result" "status_to_phase: implemented → discern"

# Test: reviewed maps to done
result=$(status_to_phase "reviewed")
assert_eq "done" "$result" "status_to_phase: reviewed → done"

# Test: done returns empty (skip)
result=$(status_to_phase "done")
assert_eq "" "$result" "status_to_phase: done → empty (skip)"

# Test: abandoned returns empty (skip)
result=$(status_to_phase "abandoned")
assert_eq "" "$result" "status_to_phase: abandoned → empty (skip)"

# ═══════════════════════════════════════════════
# Category 13: Batch mode — get_frontmatter_field (3 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- get_frontmatter_field ---"

# Test: extracts fields from frontmatter
# Arrange
setup_temp
cat > "$TEMP_DIR/test_item.md" << 'FRONTMATTER'
---
status: designed
priority: P2
title: "Test Item"
---
# Content
FRONTMATTER

# Act / Assert
result=$(get_frontmatter_field "$TEMP_DIR/test_item.md" "status")
assert_eq "designed" "$result" "get_frontmatter_field: extracts status"

result=$(get_frontmatter_field "$TEMP_DIR/test_item.md" "priority")
assert_eq "P2" "$result" "get_frontmatter_field: extracts priority"

result=$(get_frontmatter_field "$TEMP_DIR/test_item.md" "title")
assert_eq "Test Item" "$result" "get_frontmatter_field: extracts quoted title"

teardown_temp

# ═══════════════════════════════════════════════
# Category 14: Batch mode — parse_args batch flags (10 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- parse_args batch flags ---"

# Test: --parallel sets PARALLEL_JOBS
# Arrange / Act
parse_args --parallel 3 "topic"
# Assert
assert_eq "3" "$PARALLEL_JOBS" "parse_args: --parallel sets PARALLEL_JOBS"
assert_eq "topic" "$INPUT" "parse_args: --parallel doesn't interfere with INPUT"

# Test: --priority repeatable
# Arrange / Act
parse_args --priority P1 --priority P2 "topic"
# Assert
assert_eq "2" "${#PRIORITIES[@]}" "parse_args: --priority repeatable (2 values)"
assert_eq "P1" "${PRIORITIES[0]}" "parse_args: --priority first value is P1"
assert_eq "P2" "${PRIORITIES[1]}" "parse_args: --priority second value is P2"

# Test: --dry-run
# Arrange / Act
parse_args --dry-run "topic"
# Assert
assert_eq "true" "$DRY_RUN" "parse_args: --dry-run sets DRY_RUN"

# Test: --continue-on-failure
# Arrange / Act
parse_args --continue-on-failure "topic"
# Assert
assert_eq "true" "$CONTINUE_ON_FAILURE" "parse_args: --continue-on-failure sets CONTINUE_ON_FAILURE"

# Test: multiple inputs populate INPUTS array
# Arrange / Act
parse_args "docs/backlog/P1-a.md" "docs/backlog/P2-b.md"
# Assert
assert_eq "2" "${#INPUTS[@]}" "parse_args: multiple positional args populate INPUTS"
assert_eq "docs/backlog/P1-a.md" "${INPUTS[0]}" "parse_args: first input correct"
assert_eq "docs/backlog/P2-b.md" "${INPUTS[1]}" "parse_args: second input correct"

# Test: defaults for batch flags
# Arrange / Act
parse_args "topic"
# Assert
assert_eq "0" "$PARALLEL_JOBS" "parse_args: default PARALLEL_JOBS is 0"
assert_eq "false" "$DRY_RUN" "parse_args: default DRY_RUN is false"
assert_eq "false" "$CONTINUE_ON_FAILURE" "parse_args: default CONTINUE_ON_FAILURE is false"
assert_eq "0" "${#PRIORITIES[@]}" "parse_args: default PRIORITIES is empty"
assert_eq "1" "${#INPUTS[@]}" "parse_args: single topic creates 1-element INPUTS"

# Test: --parallel with --trunk --verbose combined
# Arrange / Act
parse_args --parallel 5 --trunk --verbose --priority P1 "topic"
# Assert
assert_eq "5" "$PARALLEL_JOBS" "parse_args: --parallel 5 with other flags"
assert_eq "true" "$TRUNK_MODE" "parse_args: --trunk still works with batch flags"
assert_eq "true" "$VERBOSE_LOGGING" "parse_args: --verbose still works with batch flags"
assert_eq "P1" "${PRIORITIES[0]}" "parse_args: --priority works with other batch flags"

# ═══════════════════════════════════════════════
# Category 15: Batch mode — resolve_batch_items (5 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- resolve_batch_items ---"

# Test: scans backlog when no inputs
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/docs/backlog"
cat > "$TEMP_DIR/docs/backlog/P1-item-a.md" << 'EOF'
---
status: designed
priority: P1
title: "Item A"
---
EOF
cat > "$TEMP_DIR/docs/backlog/P2-item-b.md" << 'EOF'
---
status: implemented
priority: P2
title: "Item B"
---
EOF
# Add a non-actionable item (done)
cat > "$TEMP_DIR/docs/backlog/P3-item-c.md" << 'EOF'
---
status: done
priority: P3
title: "Item C"
---
EOF
# Add a README (no frontmatter)
echo "# Backlog" > "$TEMP_DIR/docs/backlog/README.md"

# Act
INPUTS=()
PRIORITIES=()
FROM_PHASE="discover"
(cd "$TEMP_DIR" && resolve_batch_items)
# Need to run in subshell that can access the function; use cd trick
pushd "$TEMP_DIR" > /dev/null || exit
INPUTS=()
PRIORITIES=()
resolve_batch_items
popd > /dev/null || exit

# Assert
assert_eq "2" "${#BATCH_ITEMS[@]}" "resolve_batch_items: finds 2 actionable items (skips done + README)"

teardown_temp

# Test: priority filter
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/docs/backlog"
cat > "$TEMP_DIR/docs/backlog/P1-item.md" << 'EOF'
---
status: designed
priority: P1
title: "P1 Item"
---
EOF
cat > "$TEMP_DIR/docs/backlog/P2-item.md" << 'EOF'
---
status: designed
priority: P2
title: "P2 Item"
---
EOF

# Act
pushd "$TEMP_DIR" > /dev/null || exit
INPUTS=()
PRIORITIES=("P1")
resolve_batch_items
popd > /dev/null || exit

# Assert
assert_eq "1" "${#BATCH_ITEMS[@]}" "resolve_batch_items: priority filter keeps only P1"
assert_contains "${BATCH_ITEMS[0]}" "P1-item.md" "resolve_batch_items: filtered item is P1"

teardown_temp

# Test: explicit file inputs with auto-detect
# Arrange
setup_temp
cat > "$TEMP_DIR/test-item.md" << 'EOF'
---
status: implemented
priority: P2
title: "Explicit Item"
---
EOF

# Act
INPUTS=("$TEMP_DIR/test-item.md")
PRIORITIES=()
resolve_batch_items

# Assert
assert_eq "1" "${#BATCH_ITEMS[@]}" "resolve_batch_items: explicit file input creates 1 item"
assert_contains "${BATCH_ITEMS[0]}" "discern:" "resolve_batch_items: implemented → discern phase"

teardown_temp

# Test: topic string inputs start from discover
# Arrange / Act
INPUTS=("explore user auth" "add dark mode")
PRIORITIES=()
resolve_batch_items

# Assert
assert_eq "2" "${#BATCH_ITEMS[@]}" "resolve_batch_items: topic strings create 2 items"
assert_contains "${BATCH_ITEMS[0]}" "discover:" "resolve_batch_items: topic starts from discover"

# Test: topics-file loading
# Arrange
setup_temp
cat > "$TEMP_DIR/topics.txt" << 'EOF'
# Comment line
explore user auth

add dark mode
EOF

# Act
INPUTS=()
PRIORITIES=()
TOPICS_FILE="$TEMP_DIR/topics.txt"
resolve_batch_items
TOPICS_FILE=""

# Assert
assert_eq "2" "${#BATCH_ITEMS[@]}" "resolve_batch_items: loads topics from file (skips comments and blanks)"
assert_contains "${BATCH_ITEMS[0]}" "discover:" "resolve_batch_items: topics-file items start from discover"

teardown_temp

# ═══════════════════════════════════════════════
# Summary
# ═══════════════════════════════════════════════

echo ""
echo "==========================="
echo -e "Tests: $TESTS_RUN | ${GREEN}Passed: $TESTS_PASSED${NC} | ${RED}Failed: $TESTS_FAILED${NC}"
echo "==========================="

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
else
    exit 0
fi
