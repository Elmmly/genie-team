#!/bin/bash
# Tests for scripts/genie-session — Session management for parallel worktree sessions
# Run: bash tests/test_session.sh
#
# Covers backlog ACs: AC-1 through AC-8
# Covers spec ACs: AC-7, AC-8, AC-9, AC-10, AC-11

# Note: set -e intentionally omitted — test harness manages its own exit codes
# via assert_* helpers and TESTS_FAILED counter

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SESSION_SH="$PROJECT_DIR/scripts/genie-session"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# ── Test Helpers (matching test_worktree.sh pattern) ───────────

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

assert_dir_exists() {
    local path="$1"
    local test_name="$2"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -d "$path" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Directory not found: $path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_dir_not_exists() {
    local path="$1"
    local test_name="$2"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ ! -d "$path" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Directory should not exist: $path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ── Source genie-session ───────────────────────────────────────

if [[ -f "$SESSION_SH" ]]; then
    source "$SESSION_SH"
    set +eu  # Disable strict mode from sourced script — test harness manages exits
    # Clear git env vars set by pre-commit (they override -C and break temp repo commands)
    unset GIT_DIR GIT_WORK_TREE GIT_INDEX_FILE GIT_OBJECT_DIRECTORY GIT_ALTERNATE_OBJECT_DIRECTORIES
else
    echo -e "${RED}ERROR${NC} genie-session not found at $SESSION_SH"
    echo "Tests require the implementation to exist (even if incomplete)."
    exit 2
fi

# ── Common Setup/Teardown ─────────────────────────────────────

setup() {
    TEMP_DIR="$(mktemp -d)"
    TEMP_DIR="$(cd "$TEMP_DIR" && pwd -P)"  # Resolve symlinks (macOS /tmp → /private/tmp)
    MAIN_REPO="$TEMP_DIR/main-repo"
    ORIGIN_DIR="$TEMP_DIR/origin.git"

    # Create main repo with initial commit on main branch
    mkdir -p "$MAIN_REPO"
    git -C "$MAIN_REPO" init -q
    git -C "$MAIN_REPO" checkout -b main -q 2>/dev/null || true
    git -C "$MAIN_REPO" config user.email "test@test.com"
    git -C "$MAIN_REPO" config user.name "Test"
    git -C "$MAIN_REPO" commit --allow-empty -m "initial" -q

    # Create bare origin and push
    git init --bare "$ORIGIN_DIR" -q
    git -C "$MAIN_REPO" remote add origin "$ORIGIN_DIR"
    git -C "$MAIN_REPO" push -u origin main -q 2>/dev/null
}

teardown() {
    if [[ -n "${TEMP_DIR:-}" && -d "${TEMP_DIR:-}" ]]; then
        # Remove all worktrees first to avoid git warnings
        local wt
        git -C "$MAIN_REPO" worktree list --porcelain 2>/dev/null | \
            grep "^worktree " | sed 's/^worktree //' | while read -r wt; do
                if [[ "$wt" != "$MAIN_REPO" ]]; then
                    git -C "$MAIN_REPO" worktree remove --force "$wt" 2>/dev/null || true
                fi
            done
        rm -rf "$TEMP_DIR"
    fi
}

echo "=== Session Management Tests ==="
echo ""

# ─────────────────────────────────────────────
# Test: Internal Helpers
# ─────────────────────────────────────────────
echo "--- Internal Helpers ---"

setup

# Arrange — repo named "main-repo"
# Act
name=$(cd "$MAIN_REPO" && _gs_repo_name 2>/dev/null)
ec=$?
# Assert
assert_exit_code "0" "$ec" "_gs_repo_name: returns 0"
assert_eq "main-repo" "$name" "_gs_repo_name: returns repo basename"

# Arrange — repo with main branch
# Act
branch=$(cd "$MAIN_REPO" && _gs_default_branch 2>/dev/null)
ec=$?
# Assert
assert_exit_code "0" "$ec" "_gs_default_branch: returns 0"
assert_eq "main" "$branch" "_gs_default_branch: returns main"

# Arrange — item "test-item" in main-repo
# Act
wt_dir=$(cd "$MAIN_REPO" && _gs_worktree_dir "test-item" 2>/dev/null)
# Assert
assert_contains "$wt_dir" "main-repo--test-item" \
    "_gs_worktree_dir: path contains repo--item"

# Arrange — item "test-item", phase "deliver"
# Act
br=$(cd "$MAIN_REPO" && _gs_branch_name "test-item" "deliver" 2>/dev/null)
# Assert
assert_eq "genie/test-item-deliver" "$br" \
    "_gs_branch_name: returns genie/{item}-{phase}"

teardown

# ─────────────────────────────────────────────
# Test: session_start (AC-1, Spec AC-7)
# ─────────────────────────────────────────────
echo ""
echo "--- session_start ---"

setup

# Arrange — clean repo, no existing sessions
# Act
stdout=$(cd "$MAIN_REPO" && session_start "test-item" "deliver" 2>/dev/null)
ec=$?
# Assert
assert_exit_code "0" "$ec" \
    "AC-1: session_start returns 0 on success"
assert_contains "$stdout" "main-repo--test-item" \
    "AC-1: session_start prints worktree path to stdout"
assert_dir_exists "$TEMP_DIR/main-repo--test-item" \
    "AC-1: session_start creates worktree directory"

# Assert — branch was created with correct name
branch_exists=$(git -C "$MAIN_REPO" branch --list "genie/test-item-deliver" 2>/dev/null)
assert_contains "$branch_exists" "genie/test-item-deliver" \
    "AC-1: session_start creates branch with correct naming convention"

# Arrange — session already exists (worktree + branch from above)
# Act
stdout2=$(cd "$MAIN_REPO" && session_start "test-item" "deliver" 2>/dev/null)
ec=$?
# Assert
assert_exit_code "0" "$ec" \
    "AC-1: session_start returns 0 when resuming existing session"
assert_contains "$stdout2" "main-repo--test-item" \
    "AC-1: session_start returns worktree path on resume"

# Arrange — orphaned branch (worktree removed, branch remains)
git -C "$MAIN_REPO" worktree remove --force "$TEMP_DIR/main-repo--test-item" 2>/dev/null || true
# Act
stdout3=$(cd "$MAIN_REPO" && session_start "test-item" "deliver" 2>/dev/null)
ec=$?
# Assert
assert_exit_code "0" "$ec" \
    "AC-1: session_start reattaches orphaned branch"
assert_contains "$stdout3" "main-repo--test-item" \
    "AC-1: session_start returns worktree path after reattach"
assert_dir_exists "$TEMP_DIR/main-repo--test-item" \
    "AC-1: session_start recreates worktree for orphaned branch"

# Arrange — check stderr contains next steps
# Act
stderr=$(cd "$MAIN_REPO" && session_start "other-item" "design" 2>&1 1>/dev/null)
ec=$?
# Assert
assert_exit_code "0" "$ec" \
    "AC-1: session_start succeeds for different item"
assert_contains "$stderr" "cd" \
    "AC-1: session_start stderr contains cd instruction"
assert_contains "$stderr" "claude" \
    "AC-1: session_start stderr contains claude instruction"

teardown

# ─────────────────────────────────────────────
# Test: session_worktree_path (AC-5, Spec AC-9)
# ─────────────────────────────────────────────
echo ""
echo "--- session_worktree_path ---"

setup

# Arrange — create a session first
cd "$MAIN_REPO" && session_start "path-item" "deliver" >/dev/null 2>&1

# Act — resolve path for existing session
path=$(cd "$MAIN_REPO" && session_worktree_path "path-item" 2>/dev/null)
ec=$?
# Assert
assert_exit_code "0" "$ec" \
    "AC-5: session_worktree_path returns 0 for existing session"
assert_contains "$path" "main-repo--path-item" \
    "AC-5: session_worktree_path prints correct path"

# Act — resolve path for nonexistent session
path=$(cd "$MAIN_REPO" && session_worktree_path "nonexistent" 2>/dev/null)
ec=$?
# Assert
assert_exit_code "1" "$ec" \
    "AC-5: session_worktree_path returns 1 for nonexistent session"

teardown

# ─────────────────────────────────────────────
# Test: session_cleanup_item (AC-7, Spec AC-10)
# ─────────────────────────────────────────────
echo ""
echo "--- session_cleanup_item ---"

setup

# Arrange — create a session
cd "$MAIN_REPO" && session_start "cleanup-item" "deliver" >/dev/null 2>&1

# Assert precondition — worktree exists
assert_dir_exists "$TEMP_DIR/main-repo--cleanup-item" \
    "AC-7: precondition — worktree exists before cleanup"

# Act — cleanup the item
cd "$MAIN_REPO" && session_cleanup_item "cleanup-item" >/dev/null 2>&1
ec=$?

# Assert — worktree removed, branch removed, returns 0
assert_exit_code "0" "$ec" \
    "AC-7: session_cleanup_item returns 0"
assert_dir_not_exists "$TEMP_DIR/main-repo--cleanup-item" \
    "AC-7: session_cleanup_item removes worktree"
branch_exists=$(git -C "$MAIN_REPO" branch --list "genie/cleanup-item-deliver" 2>/dev/null)
assert_eq "" "$branch_exists" \
    "AC-7: session_cleanup_item removes branch"

# Arrange — nothing to clean up
# Act
cd "$MAIN_REPO" && session_cleanup_item "nonexistent" >/dev/null 2>&1
ec=$?
# Assert — still returns 0
assert_exit_code "0" "$ec" \
    "AC-7: session_cleanup_item returns 0 when nothing to clean up"

teardown

# ─────────────────────────────────────────────
# Test: session_finish --force (AC-8, Spec AC-11)
# ─────────────────────────────────────────────
echo ""
echo "--- session_finish --force ---"

setup

# Arrange — create a session with uncommitted work
cd "$MAIN_REPO" && session_start "force-item" "deliver" >/dev/null 2>&1
echo "dirty" > "$TEMP_DIR/main-repo--force-item/dirty.txt"

# Act
cd "$MAIN_REPO" && session_finish "force-item" --force >/dev/null 2>&1
ec=$?

# Assert
assert_exit_code "0" "$ec" \
    "AC-8: session_finish --force returns 0"
assert_dir_not_exists "$TEMP_DIR/main-repo--force-item" \
    "AC-8: session_finish --force removes worktree"
branch_exists=$(git -C "$MAIN_REPO" branch --list "genie/force-item-deliver" 2>/dev/null)
assert_eq "" "$branch_exists" \
    "AC-8: session_finish --force removes branch"

# Arrange — nothing to force-remove
# Act
cd "$MAIN_REPO" && session_finish "nonexistent" --force >/dev/null 2>&1
ec=$?
# Assert
assert_exit_code "0" "$ec" \
    "AC-8: session_finish --force returns 0 even if nothing exists"

teardown

# ─────────────────────────────────────────────
# Test: session_finish --merge (AC-3, Spec AC-7)
# ─────────────────────────────────────────────
echo ""
echo "--- session_finish --merge ---"

setup

# Arrange — create session and commit a file on the branch
cd "$MAIN_REPO" && session_start "merge-item" "deliver" >/dev/null 2>&1
git -C "$TEMP_DIR/main-repo--merge-item" config user.email "test@test.com"
git -C "$TEMP_DIR/main-repo--merge-item" config user.name "Test"
echo "feature" > "$TEMP_DIR/main-repo--merge-item/feature.txt"
git -C "$TEMP_DIR/main-repo--merge-item" add feature.txt
git -C "$TEMP_DIR/main-repo--merge-item" commit -m "add feature" -q

# Act — merge finish
cd "$MAIN_REPO" && session_finish "merge-item" --merge >/dev/null 2>&1
ec=$?

# Assert
assert_exit_code "0" "$ec" \
    "AC-3: session_finish --merge returns 0 on clean merge"
assert_dir_not_exists "$TEMP_DIR/main-repo--merge-item" \
    "AC-3: session_finish --merge removes worktree"

# Assert — branch deleted after merge
branch_exists=$(git -C "$MAIN_REPO" branch --list "genie/merge-item-deliver" 2>/dev/null)
assert_eq "" "$branch_exists" \
    "AC-3: session_finish --merge deletes branch"

# Assert — changes are on main
assert_eq "feature" "$(cat "$MAIN_REPO/feature.txt" 2>/dev/null)" \
    "AC-3: session_finish --merge integrates changes to main"

teardown

# ── Merge conflict test ──
setup

# Arrange — create session
cd "$MAIN_REPO" && session_start "conflict-item" "deliver" >/dev/null 2>&1

# Arrange — create conflicting changes on both branches
echo "main content" > "$MAIN_REPO/shared.txt"
git -C "$MAIN_REPO" add shared.txt
git -C "$MAIN_REPO" commit -m "main change" -q

git -C "$TEMP_DIR/main-repo--conflict-item" config user.email "test@test.com"
git -C "$TEMP_DIR/main-repo--conflict-item" config user.name "Test"
echo "branch content" > "$TEMP_DIR/main-repo--conflict-item/shared.txt"
git -C "$TEMP_DIR/main-repo--conflict-item" add shared.txt
git -C "$TEMP_DIR/main-repo--conflict-item" commit -m "branch change" -q

# Act — merge should conflict
cd "$MAIN_REPO" && session_finish "conflict-item" --merge >/dev/null 2>&1
ec=$?

# Assert
assert_exit_code "2" "$ec" \
    "AC-3: session_finish --merge returns 2 on merge conflict"

# Clean up the conflict state
git -C "$MAIN_REPO" merge --abort 2>/dev/null || true

teardown

# ─────────────────────────────────────────────
# Test: session_finish --pr (AC-3, AC-6, Spec AC-8)
# ─────────────────────────────────────────────
echo ""
echo "--- session_finish --pr ---"

setup

# Arrange — create session and commit on branch
cd "$MAIN_REPO" && session_start "pr-item" "deliver" >/dev/null 2>&1
git -C "$TEMP_DIR/main-repo--pr-item" config user.email "test@test.com"
git -C "$TEMP_DIR/main-repo--pr-item" config user.name "Test"
echo "pr feature" > "$TEMP_DIR/main-repo--pr-item/pr-feature.txt"
git -C "$TEMP_DIR/main-repo--pr-item" add pr-feature.txt
git -C "$TEMP_DIR/main-repo--pr-item" commit -m "add pr feature" -q

# Arrange — create mock gh CLI
MOCK_BIN="$TEMP_DIR/mock-bin"
mkdir -p "$MOCK_BIN"
cat > "$MOCK_BIN/gh" << 'MOCK_GH'
#!/bin/bash
echo "https://github.com/test/repo/pull/42"
MOCK_GH
chmod +x "$MOCK_BIN/gh"

# Act — PR finish with mock gh
stdout=$(cd "$MAIN_REPO" && PATH="$MOCK_BIN:$PATH" session_finish "pr-item" --pr 2>/dev/null)
ec=$?

# Assert
assert_exit_code "0" "$ec" \
    "AC-6: session_finish --pr returns 0 on success"
assert_contains "$stdout" "https://github.com" \
    "AC-6: session_finish --pr prints PR URL to stdout"
assert_dir_not_exists "$TEMP_DIR/main-repo--pr-item" \
    "AC-3: session_finish --pr removes worktree"

# Assert — branch was pushed to remote
remote_branch=$(git -C "$MAIN_REPO" branch -r --list "origin/genie/pr-item-deliver" 2>/dev/null)
assert_contains "$remote_branch" "origin/genie/pr-item-deliver" \
    "AC-6: session_finish --pr pushes branch to remote"

teardown

# ── gh unavailable fallback test ──
setup

# Arrange — create session and commit
cd "$MAIN_REPO" && session_start "nogh-item" "deliver" >/dev/null 2>&1
git -C "$TEMP_DIR/main-repo--nogh-item" config user.email "test@test.com"
git -C "$TEMP_DIR/main-repo--nogh-item" config user.name "Test"
echo "nogh feature" > "$TEMP_DIR/main-repo--nogh-item/nogh.txt"
git -C "$TEMP_DIR/main-repo--nogh-item" add nogh.txt
git -C "$TEMP_DIR/main-repo--nogh-item" commit -m "add nogh" -q

# Arrange — ensure gh is NOT available (use empty PATH with just git)
GIT_PATH="$(dirname "$(which git)")"

# Act — PR finish without gh (only git in PATH)
stderr=$(cd "$MAIN_REPO" && PATH="$GIT_PATH:/usr/bin:/bin" session_finish "nogh-item" --pr 2>&1 1>/dev/null)
ec=$?

# Assert — should still succeed (graceful fallback)
assert_exit_code "0" "$ec" \
    "AC-6: session_finish --pr returns 0 even without gh"
assert_contains "$stderr" "compare" \
    "AC-6: session_finish --pr prints manual compare URL when gh unavailable"

teardown

# ─────────────────────────────────────────────
# Test: session_list (AC-2, Spec AC-7)
# ─────────────────────────────────────────────
echo ""
echo "--- session_list ---"

setup

# Arrange — no sessions
# Act
stdout=$(cd "$MAIN_REPO" && session_list 2>/dev/null)
ec=$?
# Assert
assert_exit_code "0" "$ec" \
    "AC-2: session_list returns 0 with no sessions"
assert_contains "$stdout" "No active sessions" \
    "AC-2: session_list shows no sessions message"

# Arrange — create two sessions
cd "$MAIN_REPO" && session_start "list-a" "deliver" >/dev/null 2>&1
cd "$MAIN_REPO" && session_start "list-b" "design" >/dev/null 2>&1

# Act
stdout=$(cd "$MAIN_REPO" && session_list 2>/dev/null)
ec=$?

# Assert
assert_exit_code "0" "$ec" \
    "AC-2: session_list returns 0"
assert_contains "$stdout" "list-a" \
    "AC-2: session_list shows first session"
assert_contains "$stdout" "list-b" \
    "AC-2: session_list shows second session"
assert_contains "$stdout" "genie/list-a-deliver" \
    "AC-2: session_list shows branch name"

teardown

# ─────────────────────────────────────────────
# Test: session_cleanup (AC-4, Spec AC-7)
# ─────────────────────────────────────────────
echo ""
echo "--- session_cleanup ---"

setup

# Arrange — create two sessions: one merged, one not
cd "$MAIN_REPO" && session_start "merged-item" "deliver" >/dev/null 2>&1
cd "$MAIN_REPO" && session_start "active-item" "deliver" >/dev/null 2>&1

# Arrange — commit on merged-item, merge it, but leave worktree
git -C "$TEMP_DIR/main-repo--merged-item" config user.email "test@test.com"
git -C "$TEMP_DIR/main-repo--merged-item" config user.name "Test"
echo "merged" > "$TEMP_DIR/main-repo--merged-item/merged.txt"
git -C "$TEMP_DIR/main-repo--merged-item" add merged.txt
git -C "$TEMP_DIR/main-repo--merged-item" commit -m "merged feature" -q
git -C "$MAIN_REPO" merge "genie/merged-item-deliver" -q

# Act
cd "$MAIN_REPO" && session_cleanup >/dev/null 2>&1
ec=$?

# Assert
assert_exit_code "0" "$ec" \
    "AC-4: session_cleanup returns 0"
assert_dir_not_exists "$TEMP_DIR/main-repo--merged-item" \
    "AC-4: session_cleanup removes merged session"
assert_dir_exists "$TEMP_DIR/main-repo--active-item" \
    "AC-4: session_cleanup preserves unmerged session"

teardown

# ─────────────────────────────────────────────
# Test: Sourceability (AC-5, Spec AC-9)
# ─────────────────────────────────────────────
echo ""
echo "--- Sourceability ---"

# Assert — functions are available (implicitly proven by all tests above)
# genie-session is a library sourced by genies, NOT a standalone CLI command.
# Verify that sourcing works and functions are callable.

# Arrange — verify key functions are available after sourcing
# Act/Assert
assert_eq "0" "$(type -t session_start >/dev/null 2>&1; echo $?)" \
    "AC-5: session_start available after sourcing"
assert_eq "0" "$(type -t session_finish >/dev/null 2>&1; echo $?)" \
    "AC-5: session_finish available after sourcing"
assert_eq "0" "$(type -t session_list >/dev/null 2>&1; echo $?)" \
    "AC-5: session_list available after sourcing"
assert_eq "0" "$(type -t session_cleanup >/dev/null 2>&1; echo $?)" \
    "AC-5: session_cleanup available after sourcing"
assert_eq "0" "$(type -t session_cleanup_item >/dev/null 2>&1; echo $?)" \
    "AC-5: session_cleanup_item available after sourcing"

# AC-3: genie-session is no longer a standalone CLI command
# Executing it directly should NOT have a CLI dispatcher
# Arrange/Act
"$SESSION_SH" --help >/dev/null 2>&1
ec=$?

# Assert — running directly does nothing (exits 0, no dispatch)
assert_eq "0" "$ec" \
    "AC-3: genie-session direct execution exits 0 (no CLI dispatch)"

# ─────────────────────────────────────────────
# Test: session_integrate_trunk exit codes (P1-integration-diagnostics)
# ─────────────────────────────────────────────
echo ""
echo "--- session_integrate_trunk exit codes ---"

# Test: exit code 3 when checkout fails
# Arrange
setup
SAVED_DIR="$PROJECT_DIR"

# Create a branch that will match genie/checkout-fail-*
command git -C "$MAIN_REPO" checkout -b "genie/checkout-fail-deliver" -q
command git -C "$MAIN_REPO" commit --allow-empty -m "work on branch" -q
command git -C "$MAIN_REPO" checkout main -q

cd "$MAIN_REPO" || true

# Override git to intercept checkout of default branch
git() {
    if [[ "$1" == "-C" && "$3" == "checkout" && "$4" == "main" ]]; then
        return 1
    fi
    command git "$@"
}

# Act
session_integrate_trunk "checkout-fail" >/dev/null 2>&1
ec=$?

# Assert
assert_exit_code "3" "$ec" \
    "session_integrate_trunk: exit 3 on checkout failure"

unset -f git 2>/dev/null || true
cd "$SAVED_DIR" || true
teardown

# Test: exit code 4 when merge fails
# Arrange
setup

# Create a branch that will match genie/merge-fail-*
command git -C "$MAIN_REPO" checkout -b "genie/merge-fail-deliver" -q
command git -C "$MAIN_REPO" commit --allow-empty -m "branch work" -q
command git -C "$MAIN_REPO" checkout main -q

cd "$MAIN_REPO" || true

# Override git to intercept --ff-only merge
git() {
    if [[ "$1" == "-C" && "$3" == "merge" && "$4" == "--ff-only" ]]; then
        return 1
    fi
    command git "$@"
}

# Act
session_integrate_trunk "merge-fail" >/dev/null 2>&1
ec=$?

# Assert
assert_exit_code "4" "$ec" \
    "session_integrate_trunk: exit 4 on merge failure"

unset -f git 2>/dev/null || true
cd "$SAVED_DIR" || true
teardown

# ─────────────────────────────────────────────
# Test: _gs_find_branch exact match
# ─────────────────────────────────────────────
echo ""
echo "--- _gs_find_branch exact match ---"

setup

# Arrange — create a branch with full phase suffix
cd "$MAIN_REPO" || true
git checkout -b "genie/P0-foo-design" -q 2>/dev/null
git checkout main -q 2>/dev/null

# Act — exact match (full branch suffix, no trailing glob needed)
found=$(cd "$MAIN_REPO" && _gs_find_branch "P0-foo-design" 2>/dev/null)
ec=$?

# Assert
assert_exit_code "0" "$ec" \
    "_gs_find_branch: finds exact branch match"
assert_eq "genie/P0-foo-design" "$found" \
    "_gs_find_branch: returns exact branch name"

# Act — glob match (item slug without phase suffix)
found=$(cd "$MAIN_REPO" && _gs_find_branch "P0-foo" 2>/dev/null)
ec=$?

# Assert
assert_exit_code "0" "$ec" \
    "_gs_find_branch: finds branch via glob match"
assert_eq "genie/P0-foo-design" "$found" \
    "_gs_find_branch: returns branch from glob match"

# Act — no match
_gs_find_branch "P0-nonexistent" 2>/dev/null
ec=$?

# Assert
assert_exit_code "1" "$ec" \
    "_gs_find_branch: returns 1 when no branch found"

cd "$SAVED_DIR" || true
teardown

# ─────────────────────────────────────────────
# Test: session_integrate_trunk already-merged branch
# ─────────────────────────────────────────────
echo ""
echo "--- session_integrate_trunk already-merged ---"

setup

# Arrange — create a branch, commit work, merge to main, leave branch behind
cd "$MAIN_REPO" || true
git checkout -b "genie/P0-merged-design" -q 2>/dev/null
echo "new feature" > feature.txt
git add feature.txt
git commit -m "feat: add feature" -q 2>/dev/null
git checkout main -q 2>/dev/null
git merge --ff-only "genie/P0-merged-design" -q 2>/dev/null
# Branch still exists but is fully merged

# Act
session_integrate_trunk "P0-merged-design" >/dev/null 2>&1
ec=$?

# Assert
assert_exit_code "0" "$ec" \
    "session_integrate_trunk: exit 0 for already-merged branch"

# Branch should be deleted
if git rev-parse --verify "genie/P0-merged-design" 2>/dev/null; then
    assert_eq "deleted" "exists" \
        "session_integrate_trunk: deletes already-merged branch"
else
    assert_eq "deleted" "deleted" \
        "session_integrate_trunk: deletes already-merged branch"
fi

cd "$SAVED_DIR" || true
teardown

# ─────────────────────────────────────────────
# Test: session_integrate_trunk redundant branch (same content, different commits)
# ─────────────────────────────────────────────
echo ""
echo "--- session_integrate_trunk redundant branch ---"

setup

# Arrange — branch and main both modify the same file differently
# but the net result is that main already has all the work
cd "$MAIN_REPO" || true
# Create a base file
printf "line1\nline2\nline3\n" > shared.txt
git add shared.txt
git commit -m "add shared file" -q 2>/dev/null
# Branch modifies the file
git checkout -b "genie/P0-redundant-design" -q 2>/dev/null
printf "line1\nmodified-by-branch\nline3\nnew-line-by-branch\n" > shared.txt
git add shared.txt
git commit -m "feat: modify shared (branch)" -q 2>/dev/null
# Main gets the same changes plus more (simulates separate integration + additional work)
git checkout main -q 2>/dev/null
printf "line1\nmodified-by-branch\nline3\nnew-line-by-branch\nextra-main-work\n" > shared.txt
git add shared.txt
git commit -m "feat: modify shared (main, includes branch work)" -q 2>/dev/null

# Act — rebase will conflict, but content is equivalent
session_integrate_trunk "P0-redundant-design" >/dev/null 2>&1
ec=$?

# Assert — should succeed (detect redundant branch and clean up)
assert_exit_code "0" "$ec" \
    "session_integrate_trunk: exit 0 for redundant branch (same content on main)"

# Branch should be deleted
if git rev-parse --verify "genie/P0-redundant-design" 2>/dev/null; then
    assert_eq "deleted" "exists" \
        "session_integrate_trunk: deletes redundant branch"
else
    assert_eq "deleted" "deleted" \
        "session_integrate_trunk: deletes redundant branch"
fi

cd "$SAVED_DIR" || true
teardown

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
