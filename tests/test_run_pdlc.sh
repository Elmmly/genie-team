#!/bin/bash
# Tests for scripts/genies — autonomous PDLC runner
# Run: bash tests/test_run_pdlc.sh
#
# TDD Phase 1: All tests written first (RED). Implementation follows.

# Note: set -e intentionally omitted — test harness manages its own exit codes
# via assert_* helpers and TESTS_FAILED counter

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_PDLC="$PROJECT_DIR/scripts/genies"
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
# Source genies script for unit testing functions
# ─────────────────────────────────────────────

if [[ -f "$RUN_PDLC" ]]; then
    # shellcheck disable=SC2034  # Used by genies source guard
    GENIES_SOURCED=true
    # shellcheck source=/dev/null
    source "$RUN_PDLC"
    # genies sets -e; disable it — test harness manages its own exit codes
    set +e
else
    echo -e "${RED}ERROR${NC} genies not found at $RUN_PDLC"
    echo "Tests require the implementation to exist (even if incomplete)."
    echo "Create a minimal scripts/genies to start TDD."
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

echo "=== genies Tests ==="
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

# Test: --no-worktree flag (worktree is default-on)
# Arrange
# Act
parse_args --no-worktree "test topic"
# Assert
assert_eq "false" "$USE_WORKTREE" "parse_args: --no-worktree disables USE_WORKTREE"

# Test: default USE_WORKTREE is true
# Arrange
# Act
parse_args "test topic"
# Assert
assert_eq "true" "$USE_WORKTREE" "parse_args: USE_WORKTREE defaults to true"

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
# Category 5: detect_verdict (8 tests)
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

# Test: case-insensitive matching (lowercase "approved")
# Arrange
output="The review is complete. Verdict: approved."
# Act
result=$(detect_verdict "$output")
ec=$?
# Assert
assert_eq "APPROVED" "$result" "detect_verdict: case-insensitive 'approved' → APPROVED"

# Test: mixed case "Approved"
# Arrange
output="Verdict: Approved — all criteria met."
# Act
result=$(detect_verdict "$output")
ec=$?
# Assert
assert_eq "APPROVED" "$result" "detect_verdict: mixed case 'Approved' → APPROVED"

# Test: case-insensitive "blocked"
# Arrange
output="Review verdict: blocked due to missing tests."
# Act
result=$(detect_verdict "$output")
ec=$?
# Assert
assert_eq "BLOCKED" "$result" "detect_verdict: case-insensitive 'blocked' → BLOCKED"

# Test: last resort — reads verdict from backlog item body
# Arrange
setup_temp
cat > "$TEMP_DIR/item-body-verdict.md" << 'FRONTMATTER'
---
status: reviewed
---
# Review

**Verdict:** APPROVED

All criteria met.
FRONTMATTER
output="I've completed the review and updated the backlog item."
# Act
result=$(detect_verdict "$output" "$TEMP_DIR/item-body-verdict.md")
ec=$?
# Assert
assert_eq "APPROVED" "$result" "detect_verdict: reads verdict from item body as last resort"
assert_exit_code "0" "$ec" "detect_verdict: exit 0 for item body verdict"
teardown_temp

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

# Test: --trunk preserves default worktree isolation
# Arrange
# Act
parse_args --trunk "docs/backlog/P2-item.md"
# Assert
assert_eq "true" "$TRUNK_MODE" "parse_args: --trunk sets TRUNK_MODE"
assert_eq "true" "$USE_WORKTREE" "parse_args: --trunk preserves default USE_WORKTREE=true"

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

# Test: --verbose combined with --trunk (worktree is default)
# Arrange
# Act
parse_args --verbose --trunk "docs/backlog/P2-item.md"
# Assert
assert_eq "true" "$VERBOSE_LOGGING" "parse_args: --verbose + --trunk sets VERBOSE_LOGGING"
assert_eq "true" "$TRUNK_MODE" "parse_args: --verbose doesn't interfere with --trunk"
assert_eq "true" "$USE_WORKTREE" "parse_args: --verbose preserves default USE_WORKTREE"

# Test: --no-skip-permissions flag
# Arrange
# Act
parse_args --no-skip-permissions "test topic"
# Assert
assert_eq "false" "$SKIP_PERMISSIONS" "parse_args: --no-skip-permissions sets SKIP_PERMISSIONS to false"

# Test: skip-permissions default is true (headless runs skip by default)
# Arrange
# Act
parse_args "test topic"
# Assert
assert_eq "true" "$SKIP_PERMISSIONS" "parse_args: default SKIP_PERMISSIONS is true"

# Test: unrecognized --flag is rejected (exit 3)
# Arrange/Act
output=$(parse_args --bogus-flag "test topic" 2>&1) && ec=0 || ec=$?
# Assert
assert_eq "3" "$ec" "parse_args: unrecognized --flag exits 3"
assert_contains "$output" "unknown flag" "parse_args: unrecognized --flag prints error"

# Test: single-dash unrecognized flag is also rejected
# Arrange/Act
output=$(parse_args -bogus "test topic" 2>&1) && ec=0 || ec=$?
# Assert
assert_eq "3" "$ec" "parse_args: unrecognized -flag exits 3"

# Test: valid flags still work after adding unknown-flag guard
# Arrange/Act
parse_args --trunk --verbose "test topic"
# Assert
assert_eq "true" "$TRUNK_MODE" "parse_args: --trunk still works with unknown-flag guard"
assert_eq "true" "$VERBOSE_LOGGING" "parse_args: --verbose still works with unknown-flag guard"

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

# Test: --finish-mode combined with --trunk (worktree is default)
# Arrange
# Act
parse_args --finish-mode --leave-branch --trunk "docs/backlog/P2-item.md"
# Assert
assert_eq "--leave-branch" "$FINISH_MODE" "parse_args: --finish-mode with --trunk sets FINISH_MODE"
assert_eq "true" "$USE_WORKTREE" "parse_args: --finish-mode preserves default USE_WORKTREE"
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

# Test: --slug preserves default worktree
# Arrange
# Act
parse_args --slug discover-2 "test topic"
# Assert
assert_eq "discover-2" "$WORKTREE_SLUG" "parse_args: --slug sets WORKTREE_SLUG"
assert_eq "true" "$USE_WORKTREE" "parse_args: --slug preserves default USE_WORKTREE"

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
# shellcheck disable=SC2034  # Used by sourced genies
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
# shellcheck disable=SC2034  # Used by sourced genies
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
# Act — run as subprocess to test main() (--no-preflight: skip env checks in test)
output=$("$RUN_PDLC" --no-preflight --no-worktree --through define "test topic" 2>&1)
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
# Act — run full lifecycle (includes discern) (--no-preflight: skip env checks in test)
output=$("$RUN_PDLC" --no-preflight --no-worktree "test topic" 2>&1)
ec=$?
# Assert
assert_exit_code "1" "$ec" "main: BLOCKED verdict exits 1"
export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
teardown_temp

# Test: validation error exits 3
# Arrange
setup_temp
# Act — --from after --through (--no-preflight: skip env checks in test)
output=$("$RUN_PDLC" --no-preflight --no-worktree --from design --through define "docs/backlog/P2-item.md" 2>&1)
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

# Test: reviewed is non-actionable (skipped in batch — already complete)
result=$(status_to_phase "reviewed")
assert_eq "" "$result" "status_to_phase: reviewed → (skipped)"

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
# Category 16: maybe_utility_commit (P1-always-commit)
# ═══════════════════════════════════════════════

echo ""
echo "--- maybe_utility_commit ---"

# Test: utility commit fires when through < commit and changes exist
# Arrange
setup_temp
through_idx=0  # discover
PHASE_NUM_TURNS=0
PHASE_TOKENS=0
COMMIT_RAN=""
run_phase() { COMMIT_RAN="$1"; return 0; }
log_info() { :; }
log_debug() { :; }
log_phase_usage() { :; }
# Mock git status to report changes
git() {
    if [[ "$1" == "status" && "$2" == "--porcelain" ]]; then
        echo "M scripts/genies"
        return 0
    fi
    command git "$@"
}
export -f git 2>/dev/null || true

# Act
maybe_utility_commit "" "" "$TEMP_DIR/test-input.md"

# Assert
assert_eq "commit" "$COMMIT_RAN" "maybe_utility_commit: fires when through < commit with changes"

unset -f run_phase log_info log_debug log_phase_usage git 2>/dev/null || true
teardown_temp

# Test: utility commit skipped when through=done (idx 6)
# Arrange
through_idx=6
COMMIT_RAN=""
run_phase() { COMMIT_RAN="$1"; return 0; }
log_info() { :; }
log_debug() { :; }

# Act
maybe_utility_commit "" "" "input.md"

# Assert
assert_eq "" "$COMMIT_RAN" "maybe_utility_commit: skipped when through=done (idx 6)"

unset -f run_phase log_info log_debug 2>/dev/null || true

# Test: utility commit skipped when through=commit (idx 5)
# Arrange
through_idx=5
COMMIT_RAN=""
run_phase() { COMMIT_RAN="$1"; return 0; }
log_info() { :; }
log_debug() { :; }

# Act
maybe_utility_commit "" "" "input.md"

# Assert
assert_eq "" "$COMMIT_RAN" "maybe_utility_commit: skipped when through=commit (idx 5)"

unset -f run_phase log_info log_debug 2>/dev/null || true

# Test: utility commit skipped when no changes
# Arrange
through_idx=0
COMMIT_RAN=""
run_phase() { COMMIT_RAN="$1"; return 0; }
log_info() { :; }
log_debug() { :; }
git() {
    if [[ "$1" == "status" && "$2" == "--porcelain" ]]; then
        echo ""
        return 0
    fi
    command git "$@"
}
export -f git 2>/dev/null || true

# Act
maybe_utility_commit "" "" "input.md"

# Assert
assert_eq "" "$COMMIT_RAN" "maybe_utility_commit: skipped when no changes"

unset -f run_phase log_info log_debug git 2>/dev/null || true

# ═══════════════════════════════════════════════
# Category 17: detect_verdict with frontmatter (P1-verdict-structured-output)
# ═══════════════════════════════════════════════

echo ""
echo "--- detect_verdict with frontmatter ---"

# Test: reads APPROVED from frontmatter
# Arrange
setup_temp
cat > "$TEMP_DIR/item-approved.md" << 'FRONTMATTER'
---
status: reviewed
verdict: APPROVED
---
# Test Item
FRONTMATTER

# Act
result=$(detect_verdict "" "$TEMP_DIR/item-approved.md")
ec=$?

# Assert
assert_eq "APPROVED" "$result" "detect_verdict: reads APPROVED from frontmatter"
assert_exit_code "0" "$ec" "detect_verdict: exit 0 for frontmatter APPROVED"

# Test: reads CHANGES_REQUESTED from frontmatter (normalizes to CHANGES REQUESTED)
# Arrange
cat > "$TEMP_DIR/item-changes.md" << 'FRONTMATTER'
---
status: reviewed
verdict: CHANGES_REQUESTED
---
# Test Item
FRONTMATTER

# Act
result=$(detect_verdict "" "$TEMP_DIR/item-changes.md")
ec=$?

# Assert
assert_eq "CHANGES REQUESTED" "$result" "detect_verdict: normalizes CHANGES_REQUESTED to CHANGES REQUESTED"
assert_exit_code "0" "$ec" "detect_verdict: exit 0 for frontmatter CHANGES_REQUESTED"

# Test: reads BLOCKED from frontmatter
# Arrange
cat > "$TEMP_DIR/item-blocked.md" << 'FRONTMATTER'
---
status: reviewed
verdict: BLOCKED
---
# Test Item
FRONTMATTER

# Act
result=$(detect_verdict "" "$TEMP_DIR/item-blocked.md")
ec=$?

# Assert
assert_eq "BLOCKED" "$result" "detect_verdict: reads BLOCKED from frontmatter"
assert_exit_code "0" "$ec" "detect_verdict: exit 0 for frontmatter BLOCKED"

# Test: falls back to regex when frontmatter has no verdict field
# Arrange
cat > "$TEMP_DIR/item-no-verdict.md" << 'FRONTMATTER'
---
status: reviewed
---
# Test Item
FRONTMATTER

# Act
result=$(detect_verdict "The review is APPROVED and ready" "$TEMP_DIR/item-no-verdict.md")
ec=$?

# Assert
assert_eq "APPROVED" "$result" "detect_verdict: falls back to regex when no frontmatter verdict"
assert_exit_code "0" "$ec" "detect_verdict: exit 0 for regex fallback"

# Test: fails when no frontmatter verdict and no regex match
# Arrange
cat > "$TEMP_DIR/item-empty.md" << 'FRONTMATTER'
---
status: reviewed
---
# Test Item
FRONTMATTER

# Act
result=$(detect_verdict "No verdict keywords here" "$TEMP_DIR/item-empty.md" 2>/dev/null)
ec=$?

# Assert
assert_exit_code "1" "$ec" "detect_verdict: exit 1 when no verdict found anywhere"

teardown_temp

# ═══════════════════════════════════════════════
# Category 18: write_batch_manifest (P1-integration-diagnostics)
# ═══════════════════════════════════════════════

echo ""
echo "--- write_batch_manifest ---"

# Test: writes valid JSON manifest
# Arrange
setup_temp
LOG_DIR="$TEMP_DIR"

# Act
write_batch_manifest \
    "item-a" "item-b" \
    "---" \
    "item-c" \
    "---" \
    "item-d"

# Assert
assert_file_exists "$TEMP_DIR/batch-manifest.json" "write_batch_manifest: creates manifest file"
if [[ -f "$TEMP_DIR/batch-manifest.json" ]]; then
    # Validate JSON structure
    local_json=$(cat "$TEMP_DIR/batch-manifest.json")
    assert_contains "$local_json" '"succeeded"' "write_batch_manifest: JSON has succeeded key"
    assert_contains "$local_json" '"failed"' "write_batch_manifest: JSON has failed key"
    assert_contains "$local_json" '"conflicts"' "write_batch_manifest: JSON has conflicts key"
    assert_contains "$local_json" '"item-a"' "write_batch_manifest: succeeded contains item-a"
    assert_contains "$local_json" '"item-c"' "write_batch_manifest: failed contains item-c"
    assert_contains "$local_json" '"item-d"' "write_batch_manifest: conflicts contains item-d"
fi

# Test: handles empty items
# Arrange

# Act
write_batch_manifest "---" "---"

# Assert
assert_file_exists "$TEMP_DIR/batch-manifest.json" "write_batch_manifest: creates manifest with empty items"
if [[ -f "$TEMP_DIR/batch-manifest.json" ]]; then
    local_json=$(cat "$TEMP_DIR/batch-manifest.json")
    assert_contains "$local_json" '"succeeded": []' "write_batch_manifest: empty succeeded array"
fi

teardown_temp

# ═══════════════════════════════════════════════
# Category 19: --recover flag (P1-integration-diagnostics)
# ═══════════════════════════════════════════════

echo ""
echo "--- --recover flag ---"

# Test: RECOVER_MODE defaults to false
# Arrange
parse_args

# Assert
assert_eq "false" "$RECOVER_MODE" "--recover: default is false"

# Test: --recover sets RECOVER_MODE to true
# Arrange
parse_args --recover

# Assert
assert_eq "true" "$RECOVER_MODE" "--recover: sets RECOVER_MODE to true"

# Test: --recover works with --priority
# Arrange
parse_args --recover --priority P1

# Assert
assert_eq "true" "$RECOVER_MODE" "--recover: works with --priority (recover mode set)"
assert_eq "1" "${#PRIORITIES[@]}" "--recover: works with --priority (priority captured)"
assert_eq "P1" "${PRIORITIES[0]}" "--recover: works with --priority (correct priority value)"

# ═══════════════════════════════════════════════
# Category 20: Subcommand dispatch (AC-1, AC-2)
# ═══════════════════════════════════════════════
echo ""
echo "--- Category 20: Subcommand dispatch ---"

# Test: genies --help still works (no subcommand = PDLC mode)
# Arrange/Act
output=$("$RUN_PDLC" --help 2>&1)
ec=$?

# Assert
assert_eq "0" "$ec" "AC-1: genies --help exits 0 (PDLC mode preserved)"
assert_contains "$output" "Usage:" "AC-1: genies --help shows usage"

# Test: genies session --help dispatches to session help
# Arrange/Act
output=$("$RUN_PDLC" session --help 2>&1)
ec=$?

# Assert
assert_eq "0" "$ec" "AC-1: genies session --help exits 0"
assert_contains "$output" "start" "AC-1: genies session --help lists start command"
assert_contains "$output" "list" "AC-1: genies session --help lists list command"
assert_contains "$output" "finish" "AC-1: genies session --help lists finish command"
assert_contains "$output" "cleanup" "AC-1: genies session --help lists cleanup command"

# Test: genies session (no subcommand) shows help
# Arrange/Act
output=$("$RUN_PDLC" session 2>&1)
ec=$?

# Assert
assert_eq "0" "$ec" "AC-1: genies session (bare) exits 0"
assert_contains "$output" "start" "AC-1: genies session (bare) shows help"

# Test: genies session invalid-cmd fails
# Arrange/Act
"$RUN_PDLC" session invalid-cmd >/dev/null 2>&1
ec=$?

# Assert
assert_eq "1" "$ec" "AC-1: genies session invalid-cmd exits 1"

# Test: genies quality --help / no args shows quality behavior
# Arrange/Act — quality with no args should run validate scripts (may fail with no files, but should dispatch)
output=$("$RUN_PDLC" quality 2>&1)
ec=$?

# Assert — quality dispatches (exit code 0 = all validators pass with no files)
assert_eq "0" "$ec" "AC-2: genies quality exits 0 with no files"

# Test: genies help includes subcommands
# Arrange/Act
output=$("$RUN_PDLC" --help 2>&1)

# Assert
assert_contains "$output" "session" "AC-1: genies --help mentions session subcommand"
assert_contains "$output" "quality" "AC-2: genies --help mentions quality subcommand"

# ═══════════════════════════════════════════════
# Category 21: Retry resilience (P1-retry-resilience)
# ═══════════════════════════════════════════════

echo ""
echo "--- retry resilience ---"

# Test: worktree_setup calls session_cleanup_item before session_start (AC-1)
# Use file-based tracking since worktree_setup runs in command substitution (subshell)
# Arrange
setup_temp
CLEANUP_LOG="$TEMP_DIR/cleanup_calls.log"
session_cleanup_item() { echo "$1" >> "$CLEANUP_LOG"; }
session_start() { echo "$TEMP_DIR/fake-worktree"; return 0; }
FROM_PHASE="deliver"
# Act
result=$(worktree_setup "test-item" 2>/dev/null)
ec=$?
# Assert
cleanup_arg=$(cat "$CLEANUP_LOG" 2>/dev/null)
assert_eq "test-item" "$cleanup_arg" "AC-1: worktree_setup calls session_cleanup_item before session_start"
assert_eq "0" "$ec" "AC-1: worktree_setup succeeds after cleanup"
teardown_temp

# Test: worktree_setup still works when session_cleanup_item fails (AC-1)
# Arrange
setup_temp
session_cleanup_item() { return 1; }
session_start() { echo "$TEMP_DIR/fake-worktree"; return 0; }
FROM_PHASE="deliver"
# Act
result=$(worktree_setup "test-item" 2>/dev/null)
ec=$?
# Assert
assert_eq "0" "$ec" "AC-1: worktree_setup succeeds even when cleanup fails"
teardown_temp

# Test: status_to_phase returns empty for "reviewed" (AC-2)
# Arrange/Act
result=$(status_to_phase "reviewed")
# Assert
assert_eq "" "$result" "AC-2: status_to_phase returns empty for reviewed"

# Test: status_to_phase returns empty for "done" (AC-2, existing behavior)
# Arrange/Act
result=$(status_to_phase "done")
# Assert
assert_eq "" "$result" "AC-2: status_to_phase returns empty for done"

# Test: resolve_batch_items skips reviewed items in backlog scan (AC-2)
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/docs/backlog"
cat > "$TEMP_DIR/docs/backlog/P1-item-active.md" << 'EOF'
---
status: designed
priority: P1
title: "Active Item"
---
EOF
cat > "$TEMP_DIR/docs/backlog/P1-item-reviewed.md" << 'EOF'
---
status: reviewed
priority: P1
title: "Reviewed Item"
---
EOF
cat > "$TEMP_DIR/docs/backlog/P1-item-done.md" << 'EOF'
---
status: done
priority: P1
title: "Done Item"
---
EOF
# Act
pushd "$TEMP_DIR" > /dev/null || exit
INPUTS=()
PRIORITIES=()
resolve_batch_items
popd > /dev/null || exit
# Assert
assert_eq "1" "${#BATCH_ITEMS[@]}" "AC-2: resolve_batch_items skips reviewed and done items"
assert_contains "${BATCH_ITEMS[0]}" "P1-item-active.md" "AC-2: only active item remains"
teardown_temp

# Test: resolve_batch_items skips reviewed explicit input (AC-2)
# Arrange
setup_temp
cat > "$TEMP_DIR/reviewed-item.md" << 'EOF'
---
status: reviewed
priority: P1
title: "Reviewed Explicit"
---
EOF
# Act
INPUTS=("$TEMP_DIR/reviewed-item.md")
PRIORITIES=()
resolve_batch_items
# Assert
assert_eq "0" "${#BATCH_ITEMS[@]}" "AC-2: resolve_batch_items skips reviewed explicit input"
teardown_temp

# Test: acquire_lock overwrites dead PID lock (AC-3)
# Arrange
setup_temp
LOCK_DIR="$TEMP_DIR/locks"
mkdir -p "$LOCK_DIR"
input_hash=$(echo -n "test-dead-pid" | shasum | cut -d' ' -f1)
dead_lock="$LOCK_DIR/${input_hash}.lock"
echo "99998" > "$dead_lock"
# Act
acquire_lock "test-dead-pid" "$LOCK_DIR"
ec=$?
# Assert
assert_exit_code "0" "$ec" "AC-3: acquire_lock overwrites dead PID lock"
lock_content=$(cat "$dead_lock" 2>/dev/null)
assert_contains "$lock_content" "$$" "AC-3: lock now contains current PID"
release_lock 2>/dev/null
teardown_temp

# Test: single-item mode has worktree on by default, --no-worktree opts out (AC-4)
# Arrange/Act
parse_args --from deliver --through deliver test-input.md
# Assert
assert_eq "true" "$USE_WORKTREE" "AC-4: worktree isolation is default-on"
assert_eq "deliver" "$FROM_PHASE" "AC-4: --from works with default worktree"

# Arrange/Act
parse_args --no-worktree --from deliver --through deliver test-input.md
# Assert
assert_eq "false" "$USE_WORKTREE" "AC-4: --no-worktree opts out of isolation"
assert_eq "deliver" "$FROM_PHASE" "AC-4: --from works with --no-worktree"

# ═══════════════════════════════════════════════
# Category 22: Minimum-turn guard (P1-minimum-turn-guard)
# ═══════════════════════════════════════════════

echo ""
echo "--- minimum-turn guard ---"

# Test: MIN_TURNS array exists with correct defaults (AC-1, AC-2)
# Arrange/Act — MIN_TURNS should be defined after sourcing genies
# Assert
assert_eq "7" "${#MIN_TURNS[@]}" "AC-1: MIN_TURNS array has 7 elements"
assert_eq "0" "${MIN_TURNS[0]}" "AC-1: discover min turns is 0"
assert_eq "0" "${MIN_TURNS[1]}" "AC-1: define min turns is 0"
assert_eq "0" "${MIN_TURNS[2]}" "AC-1: design min turns is 0"
assert_eq "3" "${MIN_TURNS[3]}" "AC-2: deliver min turns is 3"
assert_eq "0" "${MIN_TURNS[4]}" "AC-1: discern min turns is 0"
assert_eq "0" "${MIN_TURNS[5]}" "AC-1: commit min turns is 0"
assert_eq "0" "${MIN_TURNS[6]}" "AC-1: done min turns is 0"

# Test: get_min_turns returns correct default for deliver (AC-2)
# Arrange/Act
result=$(get_min_turns "deliver")
# Assert
assert_eq "3" "$result" "AC-2: get_min_turns deliver returns 3"

# Test: get_min_turns returns 0 for discover (AC-1)
# Arrange/Act
result=$(get_min_turns "discover")
# Assert
assert_eq "0" "$result" "AC-1: get_min_turns discover returns 0"

# Test: --deliver-min-turns overrides default (AC-4)
# Arrange/Act
parse_args --deliver-min-turns 5 test-input.md
result=$(get_min_turns "deliver")
# Assert
assert_eq "5" "$result" "AC-4: --deliver-min-turns overrides default"

# Test: check_min_turns returns 0 when turns >= minimum (AC-1)
# Arrange
PHASE_NUM_TURNS=5
# Act
check_min_turns "deliver" 2>/dev/null
ec=$?
# Assert
assert_exit_code "0" "$ec" "AC-1: check_min_turns passes when turns >= minimum"

# Test: check_min_turns returns 1 when turns < minimum (AC-1)
# Arrange
PHASE_NUM_TURNS=1
# Act
check_min_turns "deliver" 2>/dev/null
ec=$?
# Assert
assert_exit_code "1" "$ec" "AC-1: check_min_turns fails when turns < minimum"

# Test: check_min_turns always passes for phases with min=0 (AC-1)
# Arrange
PHASE_NUM_TURNS=1
# Act
check_min_turns "discover" 2>/dev/null
ec=$?
# Assert
assert_exit_code "0" "$ec" "AC-1: check_min_turns passes for discover (min=0)"

# ═══════════════════════════════════════════════
# Category 23: Post-batch state reconciliation (P2-post-batch-state-update)
# ═══════════════════════════════════════════════

echo ""
echo "--- post-batch state reconciliation ---"

# Test: set_frontmatter_field updates existing field (AC-2)
# Arrange
setup_temp
cat > "$TEMP_DIR/test-item.md" << 'EOF'
---
status: implemented
priority: P1
title: "Test Item"
---
# Content
EOF
# Act
set_frontmatter_field "$TEMP_DIR/test-item.md" "status" "done"
result=$(get_frontmatter_field "$TEMP_DIR/test-item.md" "status")
# Assert
assert_eq "done" "$result" "AC-2: set_frontmatter_field updates existing field"
teardown_temp

# Test: set_frontmatter_field preserves other fields (AC-2)
# Arrange
setup_temp
cat > "$TEMP_DIR/test-item.md" << 'EOF'
---
status: implemented
priority: P1
title: "Test Item"
---
# Content
EOF
# Act
set_frontmatter_field "$TEMP_DIR/test-item.md" "status" "done"
title=$(get_frontmatter_field "$TEMP_DIR/test-item.md" "title")
priority=$(get_frontmatter_field "$TEMP_DIR/test-item.md" "priority")
# Assert
assert_eq "Test Item" "$title" "AC-2: set_frontmatter_field preserves title"
assert_eq "P1" "$priority" "AC-2: set_frontmatter_field preserves priority"
teardown_temp

# Test: reconcile_batch_state updates succeeded items' status (AC-2)
# Arrange
setup_temp
LOG_DIR="$TEMP_DIR/logs"
mkdir -p "$LOG_DIR"
mkdir -p "$TEMP_DIR/docs/backlog"
cat > "$TEMP_DIR/docs/backlog/P1-item-a.md" << 'EOF'
---
status: implemented
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
# Write a manifest with one succeeded item
cat > "$LOG_DIR/batch-manifest.json" << 'EOF'
{
  "timestamp": "2026-02-14T00:00:00Z",
  "succeeded": ["docs/backlog/P1-item-a.md"],
  "failed": ["docs/backlog/P2-item-b.md"],
  "conflicts": []
}
EOF
# Act
pushd "$TEMP_DIR" > /dev/null || exit
reconcile_batch_state 2>/dev/null
popd > /dev/null || exit
# Assert
result_a=$(get_frontmatter_field "$TEMP_DIR/docs/backlog/P1-item-a.md" "status")
result_b=$(get_frontmatter_field "$TEMP_DIR/docs/backlog/P2-item-b.md" "status")
assert_eq "done" "$result_a" "AC-2: succeeded item status updated to done"
assert_eq "implemented" "$result_b" "AC-2: failed item status unchanged"
teardown_temp

# Test: reconcile_batch_state appends to current_work.md (AC-1)
# Arrange
setup_temp
LOG_DIR="$TEMP_DIR/logs"
mkdir -p "$LOG_DIR"
mkdir -p "$TEMP_DIR/docs/context"
mkdir -p "$TEMP_DIR/docs/backlog"
echo "# Current Work" > "$TEMP_DIR/docs/context/current_work.md"
cat > "$LOG_DIR/batch-manifest.json" << 'EOF'
{
  "timestamp": "2026-02-14T00:00:00Z",
  "succeeded": ["docs/backlog/P1-ok.md"],
  "failed": [],
  "conflicts": []
}
EOF
# Act
pushd "$TEMP_DIR" > /dev/null || exit
reconcile_batch_state 2>/dev/null
popd > /dev/null || exit
# Assert
result=$(cat "$TEMP_DIR/docs/context/current_work.md")
assert_contains "$result" "Batch Run Summary" "AC-1: current_work.md has batch summary"
assert_contains "$result" "P1-ok.md" "AC-1: current_work.md lists succeeded item"
teardown_temp

# Test: reconcile_batch_state skips when no manifest (AC-1)
# Arrange
setup_temp
LOG_DIR="$TEMP_DIR/logs"
mkdir -p "$LOG_DIR"
# No manifest file
# Act
pushd "$TEMP_DIR" > /dev/null || exit
reconcile_batch_state 2>/dev/null
ec=$?
popd > /dev/null || exit
# Assert
assert_exit_code "0" "$ec" "AC-1: reconcile_batch_state exits 0 when no manifest"
teardown_temp

# Test: reconcile_batch_state skips current_work.md when it doesn't exist (AC-1)
# Arrange
setup_temp
LOG_DIR="$TEMP_DIR/logs"
mkdir -p "$LOG_DIR"
cat > "$LOG_DIR/batch-manifest.json" << 'EOF'
{
  "timestamp": "2026-02-14T00:00:00Z",
  "succeeded": ["docs/backlog/P1-ok.md"],
  "failed": [],
  "conflicts": []
}
EOF
# No current_work.md
# Act
pushd "$TEMP_DIR" > /dev/null || exit
reconcile_batch_state 2>/dev/null
ec=$?
popd > /dev/null || exit
# Assert
assert_exit_code "0" "$ec" "AC-1: reconcile_batch_state exits 0 when no current_work.md"
assert_file_not_exists "$TEMP_DIR/docs/context/current_work.md" "AC-1: doesn't create current_work.md"
teardown_temp

# ═══════════════════════════════════════════════
# Category 24: Batch crash recovery (AC-1..AC-4)
# ═══════════════════════════════════════════════
echo ""
echo "--- batch crash recovery ---"

# Test: run_recover integrates genie/* branches (AC-1)
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/.git/refs/heads/genie"
TRUNK_MODE="true"
LOG_DIR=""
PRIORITIES=()
INTEGRATED_SLUGS=()
session_integrate_trunk() {
    INTEGRATED_SLUGS+=("$1")
    return 0
}
session_cleanup_item() { :; }
# Mock git branch --list
git() {
    if [[ "$1" == "branch" && "$2" == "--list" ]]; then
        echo "genie/P0-item-design"
        echo "genie/P1-other-deliver"
        return 0
    fi
    command git "$@"
}
export -f git session_integrate_trunk session_cleanup_item

# Act
pushd "$TEMP_DIR" > /dev/null || exit
run_recover 2>/dev/null
ec=$?
popd > /dev/null || exit

# Assert
assert_exit_code "0" "$ec" "AC-1: run_recover exits 0"
assert_eq "2" "${#INTEGRATED_SLUGS[@]}" "AC-1: run_recover integrates all genie/* branches"
unset -f git session_integrate_trunk session_cleanup_item
teardown_temp

# Test: run_recover respects --priority filter (AC-1)
# Arrange
setup_temp
TRUNK_MODE="true"
LOG_DIR=""
PRIORITIES=("P0")
INTEGRATED_SLUGS=()
session_integrate_trunk() {
    INTEGRATED_SLUGS+=("$1")
    return 0
}
session_cleanup_item() { :; }
git() {
    if [[ "$1" == "branch" && "$2" == "--list" ]]; then
        echo "genie/P0-item-design"
        echo "genie/P1-other-deliver"
        return 0
    fi
    command git "$@"
}
export -f git session_integrate_trunk session_cleanup_item

# Act
pushd "$TEMP_DIR" > /dev/null || exit
run_recover 2>/dev/null
ec=$?
popd > /dev/null || exit

# Assert
assert_eq "1" "${#INTEGRATED_SLUGS[@]}" "AC-1: --priority P0 filters to 1 branch"
assert_eq "P0-item-design" "${INTEGRATED_SLUGS[0]}" "AC-1: --priority integrates correct branch"
unset -f git session_integrate_trunk session_cleanup_item
teardown_temp

# Test: run_recover with manifest only integrates succeeded (AC-3)
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/logs"
LOG_DIR="$TEMP_DIR/logs"
TRUNK_MODE="true"
PRIORITIES=()
INTEGRATED_SLUGS=()
CLEANUP_SLUGS=()
session_integrate_trunk() {
    INTEGRATED_SLUGS+=("$1")
    return 0
}
session_cleanup_item() {
    CLEANUP_SLUGS+=("$1")
}
git() {
    if [[ "$1" == "branch" && "$2" == "--list" ]]; then
        echo "genie/P0-item-design"
        echo "genie/P1-failed-deliver"
        return 0
    fi
    command git "$@"
}
export -f git session_integrate_trunk session_cleanup_item
# Write manifest with P0-item as succeeded and P1-failed as failed
cat > "$TEMP_DIR/logs/batch-manifest.json" << 'MANIFEST'
{
  "succeeded": ["docs/backlog/P0-item.md"],
  "failed": ["docs/backlog/P1-failed.md"],
  "conflict": []
}
MANIFEST

# Act
pushd "$TEMP_DIR" > /dev/null || exit
run_recover 2>/dev/null
ec=$?
popd > /dev/null || exit

# Assert
assert_eq "1" "${#INTEGRATED_SLUGS[@]}" "AC-3: with manifest, only succeeded branch integrated"
assert_eq "P0-item-design" "${INTEGRATED_SLUGS[0]}" "AC-3: correct succeeded branch integrated"
assert_eq "1" "${#CLEANUP_SLUGS[@]}" "AC-3: failed branch cleaned up"
unset -f git session_integrate_trunk session_cleanup_item
teardown_temp

# Test: run_recover exits 0 when no branches found (AC-1)
# Arrange
setup_temp
TRUNK_MODE="true"
LOG_DIR=""
PRIORITIES=()
git() {
    if [[ "$1" == "branch" && "$2" == "--list" ]]; then
        return 0  # no output
    fi
    command git "$@"
}
export -f git

# Act
pushd "$TEMP_DIR" > /dev/null || exit
run_recover 2>/dev/null
ec=$?
popd > /dev/null || exit

# Assert
assert_exit_code "0" "$ec" "AC-1: run_recover exits 0 when no branches"
unset -f git
teardown_temp

# Test: _batch_exit_trap writes partial manifest (AC-2)
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/logs"
LOG_DIR="$TEMP_DIR/logs"
succeeded_items=("docs/backlog/P0-done.md")
failed_items=()
conflict_items=()

# Act
_batch_exit_trap 2>/dev/null

# Assert
assert_file_exists "$TEMP_DIR/logs/batch-manifest.json" "AC-2: exit trap writes manifest"
if command -v jq &>/dev/null; then
    local_succeeded=$(jq -r '.succeeded[0]' "$TEMP_DIR/logs/batch-manifest.json" 2>/dev/null)
    assert_eq "docs/backlog/P0-done.md" "$local_succeeded" "AC-2: manifest contains succeeded item"
fi
teardown_temp

# Test: run_recover uses PR mode when trunk is false (AC-1)
# Arrange
setup_temp
TRUNK_MODE="false"
LOG_DIR=""
PRIORITIES=()
PR_SLUGS=()
session_integrate_pr() {
    PR_SLUGS+=("$1")
    return 0
}
session_cleanup_item() { :; }
git() {
    if [[ "$1" == "branch" && "$2" == "--list" ]]; then
        echo "genie/P0-item-design"
        return 0
    fi
    command git "$@"
}
export -f git session_integrate_pr session_cleanup_item

# Act
pushd "$TEMP_DIR" > /dev/null || exit
run_recover 2>/dev/null
ec=$?
popd > /dev/null || exit

# Assert
assert_eq "1" "${#PR_SLUGS[@]}" "AC-1: PR mode used when trunk=false"
unset -f git session_integrate_pr session_cleanup_item
teardown_temp

# Test: RECOVER_MODE check is first in main (AC-4)
# This is a structural test — single-item flow is unaffected
# Arrange
parse_args --from design --through deliver "docs/backlog/test.md"

# Assert
assert_eq "false" "$RECOVER_MODE" "AC-4: single-item args don't set RECOVER_MODE"
assert_eq "design" "$FROM_PHASE" "AC-4: single-item args preserved"

# ═══════════════════════════════════════════════
# Category 25: Review cycle retry (5 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- review cycle retry ---"

# Test: --review-cycles flag default is 1
# Arrange
parse_args --from deliver --through discern "docs/backlog/test.md"
# Assert
assert_eq "1" "$REVIEW_CYCLES" "--review-cycles: default is 1"

# Test: --review-cycles flag parsed
# Arrange
parse_args --review-cycles 2 --from deliver --through discern "docs/backlog/test.md"
# Assert
assert_eq "2" "$REVIEW_CYCLES" "--review-cycles: parses value"

# Test: --review-cycles 0 means no retry (same as 1)
# Arrange
parse_args --review-cycles 0 --from deliver --through discern "docs/backlog/test.md"
# Assert
assert_eq "0" "$REVIEW_CYCLES" "--review-cycles: accepts 0"

# Test: CHANGES REQUESTED with review_cycles=1 stops (current behavior)
# Arrange — mock detect_verdict to return CHANGES REQUESTED
_orig_detect_verdict=$(declare -f detect_verdict)
detect_verdict() { echo "CHANGES REQUESTED"; return 0; }
REVIEW_CYCLES=1
review_cycle_count=0
# Simulate the discern verdict check logic
verdict=$(detect_verdict "mock output" 2>/dev/null) || true
should_retry="false"
if [[ "$verdict" == "CHANGES REQUESTED" && "$REVIEW_CYCLES" -gt 1 ]]; then
    review_cycle_count=$((review_cycle_count + 1))
    if [[ "$review_cycle_count" -lt "$REVIEW_CYCLES" ]]; then
        should_retry="true"
    fi
fi
# Assert
assert_eq "false" "$should_retry" "review cycle: CHANGES REQUESTED with cycles=1 stops"
eval "$_orig_detect_verdict"

# Test: CHANGES REQUESTED with review_cycles=2 retries first time
# Arrange
detect_verdict() { echo "CHANGES REQUESTED"; return 0; }
REVIEW_CYCLES=2
review_cycle_count=0
verdict=$(detect_verdict "mock output" 2>/dev/null) || true
should_retry="false"
if [[ "$verdict" == "CHANGES REQUESTED" && "$REVIEW_CYCLES" -gt 1 ]]; then
    review_cycle_count=$((review_cycle_count + 1))
    if [[ "$review_cycle_count" -lt "$REVIEW_CYCLES" ]]; then
        should_retry="true"
    fi
fi
# Assert
assert_eq "true" "$should_retry" "review cycle: CHANGES REQUESTED with cycles=2 retries"
eval "$_orig_detect_verdict"

# ═══════════════════════════════════════════════
# Category: preflight_checks (8 tests)
# Spec AC-9: Preflight validation before execution
# ═══════════════════════════════════════════════

echo ""
echo "--- preflight_checks ---"

# Test: --no-preflight flag parsed
# Arrange
# Act
parse_args --no-preflight "test topic"
# Assert
assert_eq "true" "$NO_PREFLIGHT" "preflight: --no-preflight flag sets NO_PREFLIGHT"

# Test: NO_PREFLIGHT defaults to false
# Arrange
# Act
parse_args "test topic"
# Assert
assert_eq "false" "$NO_PREFLIGHT" "preflight: NO_PREFLIGHT defaults to false"

# Test: preflight passes when claude and git are available
# Arrange
setup_temp
cd "$(mktemp -d)" || exit
git init -q .
TRUNK_MODE="true"
# Act
output=$(preflight_checks 2>&1)
ec=$?
# Assert
assert_eq "0" "$ec" "preflight: passes when claude and git available (trunk mode)"
teardown_temp

# Test: preflight fails exit 3 when claude missing
# Arrange
setup_temp
cd "$(mktemp -d)" || exit
git init -q .
TRUNK_MODE="true"
# Use a PATH with only git (no claude)
_saved_path="$PATH"
PATH="/usr/bin:/bin"
# Act
output=$(preflight_checks 2>&1)
ec=$?
# Assert
PATH="$_saved_path"
assert_eq "3" "$ec" "preflight: exits 3 when claude CLI missing"
assert_contains "$output" "claude" "preflight: error mentions claude"
teardown_temp

# Test: preflight fails exit 3 when not in git repo
# Arrange
setup_temp
cd "$(mktemp -d)" || exit
TRUNK_MODE="true"
# Act
output=$(preflight_checks 2>&1)
ec=$?
# Assert
assert_eq "3" "$ec" "preflight: exits 3 when not in git repo"
teardown_temp

# Test: preflight skips gh check in trunk mode
# Arrange
setup_temp
cd "$(mktemp -d)" || exit
git init -q .
TRUNK_MODE="true"
# Act (gh may or may not be available — trunk mode should skip the check)
output=$(preflight_checks 2>&1)
ec=$?
# Assert
assert_eq "0" "$ec" "preflight: skips gh check in trunk mode"
teardown_temp

# ═══════════════════════════════════════════════
# Category 26: Phase failure error handling (set -e guard)
# ═══════════════════════════════════════════════

echo ""
echo "--- phase failure error handling ---"

# Test: phase failure exits 1 (not 127 from set -e propagation)
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/fail_responses"
cp "$MOCK_RESPONSES"/*.json "$TEMP_DIR/fail_responses/"
touch "$TEMP_DIR/fail_responses/deliver_fail"
export MOCK_CLAUDE_RESPONSES_DIR="$TEMP_DIR/fail_responses"
# Act — run as subprocess with set -e active (--no-preflight: skip env checks in test)
output=$("$RUN_PDLC" --no-preflight --no-worktree --from deliver --through deliver "docs/backlog/P2-item.md" 2>&1)
ec=$?
# Assert
assert_exit_code "1" "$ec" "set-e guard: phase failure exits 1 (not 127)"
export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
teardown_temp

# Test: phase failure logs error message
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/fail_responses"
cp "$MOCK_RESPONSES"/*.json "$TEMP_DIR/fail_responses/"
touch "$TEMP_DIR/fail_responses/deliver_fail"
export MOCK_CLAUDE_RESPONSES_DIR="$TEMP_DIR/fail_responses"
# Act
output=$("$RUN_PDLC" --no-preflight --no-worktree --from deliver --through deliver "docs/backlog/P2-item.md" 2>&1)
# Assert
assert_contains "$output" "failed" "set-e guard: phase failure logs error message"
export MOCK_CLAUDE_RESPONSES_DIR="$MOCK_RESPONSES"
teardown_temp

# Test: claude stderr captured to log file when LOG_DIR set
# Arrange
setup_temp
mkdir -p "$TEMP_DIR/logs" "$TEMP_DIR/bin"
# Create a mock claude that writes to stderr and returns valid JSON
cat > "$TEMP_DIR/bin/claude" << 'MOCK_SCRIPT'
#!/bin/bash
echo "mock stderr warning" >&2
echo '{"type":"result","result":"Discovery complete.","session_id":"mock-session-stderr","usage":{"turns":5,"input_tokens":100,"output_tokens":50}}'
exit 0
MOCK_SCRIPT
chmod +x "$TEMP_DIR/bin/claude"
export PATH="$TEMP_DIR/bin:$PATH"
# Act — run as subprocess to get set -e and fresh function scope
output=$("$RUN_PDLC" --no-preflight --no-worktree --log-dir "$TEMP_DIR/logs" --through discover "test topic" 2>&1)
# Assert
assert_file_exists "$TEMP_DIR/logs/claude_stderr.log" "stderr capture: creates claude_stderr.log"
if [[ -f "$TEMP_DIR/logs/claude_stderr.log" ]]; then
    stderr_content=$(cat "$TEMP_DIR/logs/claude_stderr.log")
    assert_contains "$stderr_content" "mock stderr warning" "stderr capture: log contains stderr output"
fi
teardown_temp

# Test: batch worker includes --no-preflight
# Arrange — check that _prepare_batch_worker includes --no-preflight in args
batch_worker_code=$(grep -A2 '_BW_ARGS=.*--no-preflight' "$RUN_PDLC")
# Assert
assert_contains "$batch_worker_code" "--no-preflight" "batch worker: includes --no-preflight"

# Test: sequential batch uses worktree isolation (default-on, --finish-mode, --leave-branch)
# Arrange — grep the run_batch_sequential function for worktree args
seq_batch_code=$(sed -n '/^run_batch_sequential/,/^}/p' "$RUN_PDLC")
# Assert — worktree is default-on, so batch no longer needs explicit --worktree flag
assert_contains "$seq_batch_code" "--finish-mode" "sequential batch: uses --finish-mode"
assert_contains "$seq_batch_code" "--leave-branch" "sequential batch: uses --leave-branch"
assert_contains "$seq_batch_code" "--cleanup-on-failure" "sequential batch: uses --cleanup-on-failure"

# Test: sequential batch integrates after each item (calls session_integrate)
assert_contains "$seq_batch_code" "session_integrate_trunk" "sequential batch: integrates trunk after success"
assert_contains "$seq_batch_code" "session_integrate_pr" "sequential batch: integrates PR after success"

# ═══════════════════════════════════════════════
# Category 27: LOG_DIR absolute resolution & slug computation
# ═══════════════════════════════════════════════

echo ""
echo "--- LOG_DIR absolute resolution ---"

# Test: relative LOG_DIR resolved to absolute after parse_args in main()
# Arrange — grep main() for the resolution logic
main_code=$(sed -n '/^main()/,/^}/p' "$RUN_PDLC")
# Assert
# shellcheck disable=SC2016  # Single quotes intentional — matching literal string
assert_contains "$main_code" 'LOG_DIR="$(pwd)/$LOG_DIR"' \
    "LOG_DIR: main() resolves relative LOG_DIR to absolute"

# Test: absolute LOG_DIR left unchanged
# Arrange
parse_args --log-dir /tmp/absolute-logs "test topic"
# Simulate the resolution logic from main()
if [[ -n "$LOG_DIR" && "$LOG_DIR" != /* ]]; then
    LOG_DIR="$(pwd)/$LOG_DIR"
fi
# Assert
assert_eq "/tmp/absolute-logs" "$LOG_DIR" "LOG_DIR: absolute path left unchanged"

# Test: relative LOG_DIR resolved correctly
# Arrange
parse_args --log-dir "logs/batch-run" "test topic"
expected_log_dir="$(pwd)/logs/batch-run"
# Simulate the resolution logic from main()
if [[ -n "$LOG_DIR" && "$LOG_DIR" != /* ]]; then
    LOG_DIR="$(pwd)/$LOG_DIR"
fi
# Assert
assert_eq "$expected_log_dir" "$LOG_DIR" "LOG_DIR: relative path resolved to absolute"

echo ""
echo "--- slug computation ---"

# Test: slug computed correctly for directory-prefixed input (no .md)
# Arrange — simulate what run_batch_sequential does
input="docs/backlog/P2-foo"
slug=$(basename "$input" .md)
# Assert
assert_eq "P2-foo" "$slug" "slug: directory-prefixed input without .md produces clean slug"

# Test: slug computed correctly for directory-prefixed input with .md
# Arrange
input="docs/backlog/P2-foo.md"
slug=$(basename "$input" .md)
# Assert
assert_eq "P2-foo" "$slug" "slug: directory-prefixed input with .md strips extension"

# Test: slug computed correctly for bare topic string
# Arrange
input="explore-auth"
slug=$(basename "$input" .md)
# Assert
assert_eq "explore-auth" "$slug" "slug: bare topic string preserved as slug"

# Test: parallel batch worker slug uses basename (structural)
# Arrange — grep _prepare_batch_worker for the slug line
parallel_slug_code=$(sed -n '/_prepare_batch_worker/,/^[[:space:]]*}/p' "$RUN_PDLC" | grep '_BW_SLUG=')
# Assert — should be a single unconditional basename call, not an if/else
assert_contains "$parallel_slug_code" 'basename' "parallel slug: uses basename"
assert_not_contains "$parallel_slug_code" 'batch-' "parallel slug: no fallback to batch-N"

# Test: sequential batch slug uses basename (structural)
# Arrange — grep run_batch_sequential for the slug line
seq_slug_code=$(sed -n '/^run_batch_sequential/,/^}/p' "$RUN_PDLC" | grep 'slug=')
# Assert — should be a single unconditional basename call
assert_contains "$seq_slug_code" 'basename' "sequential slug: uses basename"
# Should not have the old if/else pattern
seq_slug_block=$(sed -n '/^run_batch_sequential/,/^}/p' "$RUN_PDLC")
# shellcheck disable=SC2016  # Single quotes intentional — matching literal string
assert_not_contains "$seq_slug_block" 'slug="$input"' "sequential slug: no raw input fallback"

# ═══════════════════════════════════════════════
# Category 28: sanitize_slug (7 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- sanitize_slug ---"

# Test: spaces replaced with hyphens
result=$(sanitize_slug "user auth flow")
assert_eq "user-auth-flow" "$result" "sanitize_slug: spaces → hyphens"

# Test: smart/curly quotes stripped
result=$(sanitize_slug $'gift\xe2\x80\x9d')
assert_eq "gift" "$result" "sanitize_slug: curly right-quote stripped"

# Test: already-clean slug passes through (lowercased)
result=$(sanitize_slug "P2-search-redesign")
assert_eq "p2-search-redesign" "$result" "sanitize_slug: clean input lowercased"

# Test: long string truncated to 60 chars
long_input="identify-1-2-ways-to-improve-the-core-your-rhythm-engagement-loop-and-ui-design"
result=$(sanitize_slug "$long_input")
assert_eq "60" "${#result}" "sanitize_slug: truncates to 60 chars"

# Test: consecutive hyphens collapsed
result=$(sanitize_slug "foo---bar")
assert_eq "foo-bar" "$result" "sanitize_slug: collapses consecutive hyphens"

# Test: leading/trailing hyphens trimmed
result=$(sanitize_slug "-leading-and-trailing-")
assert_eq "leading-and-trailing" "$result" "sanitize_slug: trims leading/trailing hyphens"

# Test: special chars replaced
result=$(sanitize_slug 'hello world! @#$% test')
assert_eq "hello-world-test" "$result" "sanitize_slug: special chars → hyphens (collapsed)"

# ═══════════════════════════════════════════════
# Category 29: em-dash/en-dash detection (3 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- em-dash/en-dash detection ---"

# Test: em-dash flag rejected with helpful error
# Arrange/Act — use $'...' to embed the em-dash (U+2014)
output=$(parse_args $'\xe2\x80\x94continue-on-failure' "topic" 2>&1) && ec=0 || ec=$?
# Assert
assert_eq "3" "$ec" "em-dash: —flag exits 3"
assert_contains "$output" "non-ASCII dash" "em-dash: error mentions non-ASCII dash"

# Test: en-dash flag rejected
output=$(parse_args $'\xe2\x80\x93from' "topic" 2>&1) && ec=0 || ec=$?
# Assert
assert_eq "3" "$ec" "en-dash: –flag exits 3"

# Test: normal double-dash flags still work (no regression)
parse_args --continue-on-failure "topic"
assert_eq "true" "$CONTINUE_ON_FAILURE" "em-dash guard: --continue-on-failure still works"

# ═══════════════════════════════════════════════
# Category 30: sanitize_slug applied at slug derivation (structural)
# ═══════════════════════════════════════════════

echo ""
echo "--- sanitize_slug integration ---"

# Test: sequential batch uses sanitize_slug
seq_slug_code=$(sed -n '/^run_batch_sequential/,/^}/p' "$RUN_PDLC" | grep 'slug=')
assert_contains "$seq_slug_code" 'sanitize_slug' "sequential batch: slug uses sanitize_slug"

# Test: parallel batch uses sanitize_slug
parallel_slug_code=$(sed -n '/_prepare_batch_worker/,/^[[:space:]]*}/p' "$RUN_PDLC" | grep '_BW_SLUG=')
assert_contains "$parallel_slug_code" 'sanitize_slug' "parallel batch: slug uses sanitize_slug"

# Test: single-item mode uses sanitize_slug
single_slug_code=$(grep 'item_slug=.*basename.*INPUT' "$RUN_PDLC")
assert_contains "$single_slug_code" 'sanitize_slug' "single-item: slug uses sanitize_slug"

# ═══════════════════════════════════════════════
# Category 31: smart/curly quote detection (3 tests)
# ═══════════════════════════════════════════════

echo ""
echo "--- smart/curly quote detection ---"

# Test: left double smart quote in --log-dir value rejected
output=$(parse_args --log-dir $'\xe2\x80\x9clogs/test\xe2\x80\x9d' "topic" 2>&1) && ec=0 || ec=$?
assert_eq "3" "$ec" "smart quote: log-dir with curly quotes exits 3"
assert_contains "$output" "smart/curly quotes" "smart quote: error mentions smart/curly quotes"

# Test: smart single quote in positional arg rejected
output=$(parse_args --trunk $'\xe2\x80\x98topic\xe2\x80\x99' 2>&1) && ec=0 || ec=$?
assert_eq "3" "$ec" "smart quote: single smart quotes in arg exits 3"

# Test: normal ASCII quotes still work (no regression)
parse_args --log-dir "logs/test" "topic"
assert_eq "logs/test" "$LOG_DIR" "smart quote guard: ASCII-quoted --log-dir works"

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
