#!/bin/bash
# Tests for install.sh worktree detection and parallel session deliverables
# Run: bash tests/test_worktree.sh

# Note: set -e intentionally omitted — test harness manages its own exit codes
# via assert_* helpers and TESTS_FAILED counter

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
INSTALL_SH="$PROJECT_DIR/install.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test helpers
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

assert_symlink() {
    local path="$1"
    local test_name="$2"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -L "$path" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Not a symlink: $path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Source install.sh functions
if [[ -f "$INSTALL_SH" ]]; then
    INSTALL_SOURCED=true
    source "$INSTALL_SH"
    # install.sh sets -e; disable it — test harness manages its own exit codes
    set +e
else
    echo -e "${RED}ERROR${NC} install.sh not found at $INSTALL_SH"
    echo "Tests require the implementation to exist (even if incomplete)."
    exit 2
fi

# Setup: create temp git repo with a worktree
setup() {
    TEMP_DIR="$(mktemp -d)"
    MAIN_REPO="$TEMP_DIR/main-repo"
    WORKTREE_DIR="$TEMP_DIR/main-repo--session-a"

    # Create main repo
    mkdir -p "$MAIN_REPO"
    git -C "$MAIN_REPO" init -q
    git -C "$MAIN_REPO" commit --allow-empty -m "initial" -q

    # Create worktree
    git -C "$MAIN_REPO" worktree add "$WORKTREE_DIR" -b test-branch -q 2>/dev/null
}

teardown() {
    if [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]]; then
        # Remove worktree first to avoid git warnings
        git -C "$MAIN_REPO" worktree remove "$WORKTREE_DIR" --force 2>/dev/null || true
        rm -rf "$TEMP_DIR"
    fi
}

echo "=== worktree detection Tests ==="
echo ""

# ─────────────────────────────────────────────
# Test: detect_worktree
# ─────────────────────────────────────────────
echo "--- detect_worktree ---"

setup

# Arrange — main repo (not a worktree)
# Act
(cd "$MAIN_REPO" && detect_worktree)
ec=$?
# Assert
assert_exit_code "1" "$ec" \
    "detect_worktree: returns 1 (false) in main working tree"

# Arrange — worktree
# Act
(cd "$WORKTREE_DIR" && detect_worktree)
ec=$?
# Assert
assert_exit_code "0" "$ec" \
    "detect_worktree: returns 0 (true) in a worktree"

# Arrange — non-git directory
# Act
(cd "$TEMP_DIR" && detect_worktree 2>/dev/null)
ec=$?
# Assert
assert_exit_code "1" "$ec" \
    "detect_worktree: returns 1 (false) in non-git directory"

teardown

# ─────────────────────────────────────────────
# Test: get_main_worktree
# ─────────────────────────────────────────────
echo ""
echo "--- get_main_worktree ---"

setup

# Arrange — from inside worktree
# Act
result=$(cd "$WORKTREE_DIR" && get_main_worktree)
ec=$?
# Assert — should return absolute path to main repo
assert_exit_code "0" "$ec" \
    "get_main_worktree: succeeds from worktree"

# Resolve symlinks for comparison (macOS /tmp → /private/tmp)
expected_main="$(cd "$MAIN_REPO" && pwd -P)"
actual_main="$(cd "$result" 2>/dev/null && pwd -P)"
assert_eq "$expected_main" "$actual_main" \
    "get_main_worktree: returns path to main working tree"

# Arrange — from main repo
# Act
result=$(cd "$MAIN_REPO" && get_main_worktree)
ec=$?
# Assert — should also return path to main repo (it's its own main)
assert_exit_code "0" "$ec" \
    "get_main_worktree: succeeds from main working tree"

actual_main="$(cd "$result" 2>/dev/null && pwd -P)"
assert_eq "$expected_main" "$actual_main" \
    "get_main_worktree: returns own path when in main tree"

# Arrange — non-git directory
# Act
result=$(cd "$TEMP_DIR" && get_main_worktree 2>/dev/null)
ec=$?
# Assert
assert_exit_code "1" "$ec" \
    "get_main_worktree: fails in non-git directory"

teardown

# ─────────────────────────────────────────────
# Test: autonomous-execution.md content
# ─────────────────────────────────────────────
echo ""
echo "--- autonomous-execution.md worktree section ---"

ae_file="$PROJECT_DIR/rules/autonomous-execution.md"
ae_content=$(cat "$ae_file")

assert_contains "$ae_content" "Parallel Sessions via Git Worktrees" \
    "autonomous-execution.md: contains worktree section heading"

assert_contains "$ae_content" "NEVER force-push or delete a branch checked out in another worktree" \
    "autonomous-execution.md: contains safety rule about force-push"

assert_contains "$ae_content" "NEVER modify files outside the current worktree directory" \
    "autonomous-execution.md: contains safety rule about file boundaries"

assert_contains "$ae_content" "git worktree list" \
    "autonomous-execution.md: references git worktree list command"

assert_contains "$ae_content" "genie/{backlog-item-id}-{phase}" \
    "autonomous-execution.md: documents branch naming in worktree context"

assert_contains "$ae_content" "Human-Led" \
    "autonomous-execution.md: documents human-led parallel sessions"

assert_contains "$ae_content" "Orchestrator-Driven" \
    "autonomous-execution.md: documents orchestrator-driven parallel sessions"

# ─────────────────────────────────────────────
# Test: cli-contract.md content
# ─────────────────────────────────────────────
echo ""
echo "--- cli-contract.md parallel invocation ---"

cli_file="$PROJECT_DIR/docs/architecture/cli-contract.md"
cli_content=$(cat "$cli_file")

assert_contains "$cli_content" "Parallel Invocation via Worktrees" \
    "cli-contract.md: contains parallel invocation section heading"

assert_contains "$cli_content" "git worktree add" \
    "cli-contract.md: contains worktree creation example"

assert_contains "$cli_content" "git worktree remove" \
    "cli-contract.md: contains worktree cleanup example"

assert_contains "$cli_content" "genie/" \
    "cli-contract.md: references genie branch naming"

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
