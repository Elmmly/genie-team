#!/bin/bash
# Tests for `genies status` subcommand (issue #10)
# Run: bash tests/test_status.sh
#
# TDD Phase 1: Tests written first (RED). Implementation follows.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
RUN_PDLC="$PROJECT_DIR/scripts/genies"

TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# ─────────────────────────────────────────────
# Test helpers
# ─────────────────────────────────────────────

assert_eq() {
    local expected="$1" actual="$2" test_name="$3"
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

assert_exit_code() {
    local expected="$1" actual="$2" test_name="$3"
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

assert_contains() {
    local haystack="$1" needle="$2" test_name="$3"
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
    local haystack="$1" needle="$2" test_name="$3"
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

# ─────────────────────────────────────────────
# Source genies for unit testing
# ─────────────────────────────────────────────

if [[ -f "$RUN_PDLC" ]]; then
    GENIES_SOURCED=true
    # shellcheck source=/dev/null
    source "$RUN_PDLC"
    set +euo pipefail
else
    echo -e "${RED}ERROR${NC} genies not found at $RUN_PDLC"
    exit 2
fi

# ─────────────────────────────────────────────
# Setup / teardown
# ─────────────────────────────────────────────

TEMP_DIR=""

setup_temp() {
    TEMP_DIR="$(mktemp -d)"
}

teardown_temp() {
    [[ -n "${TEMP_DIR:-}" && -d "$TEMP_DIR" ]] && rm -rf "$TEMP_DIR"
}

# Write a minimal manifest to $1/batch-manifest.json
write_manifest() {
    local log_dir="$1"
    shift
    local succeeded=() failed=() conflicts=()
    local section="succeeded"
    for arg in "$@"; do
        case "$arg" in
            ---) [[ "$section" == "succeeded" ]] && section="failed" || section="conflicts" ;;
            *)
                case "$section" in
                    succeeded)  succeeded+=("$arg") ;;
                    failed)     failed+=("$arg") ;;
                    conflicts)  conflicts+=("$arg") ;;
                esac ;;
        esac
    done

    {
        printf '{\n'
        printf '  "timestamp": "2026-01-01T00:00:00Z",\n'
        printf '  "succeeded": ['
        local first=true
        for s in "${succeeded[@]+"${succeeded[@]}"}"; do
            [[ "$first" == "true" ]] && first=false || printf ','
            printf '"%s"' "$s"
        done
        printf '],\n'
        printf '  "failed": ['
        first=true
        for s in "${failed[@]+"${failed[@]}"}"; do
            [[ "$first" == "true" ]] && first=false || printf ','
            printf '"%s"' "$s"
        done
        printf '],\n'
        printf '  "conflicts": ['
        first=true
        for s in "${conflicts[@]+"${conflicts[@]}"}"; do
            [[ "$first" == "true" ]] && first=false || printf ','
            printf '"%s"' "$s"
        done
        printf ']\n'
        printf '}\n'
    } > "$log_dir/batch-manifest.json"
}

echo "=== genies status Tests ==="
echo ""

# ═══════════════════════════════════════════════
# Category 1: argument parsing
# ═══════════════════════════════════════════════

echo "--- genies_status: argument parsing ---"

# Test: missing log dir exits non-zero
setup_temp
ec=0
STATUS_LOG_DIR="" LOG_DIR="" genies_status 2>/dev/null || ec=$?
assert_exit_code "1" "$ec" "genies_status: missing log dir exits 1"
teardown_temp

# Test: non-existent log dir exits non-zero
setup_temp
ec=0
STATUS_LOG_DIR="/nonexistent/path/that/does/not/exist" genies_status 2>/dev/null || ec=$?
assert_exit_code "1" "$ec" "genies_status: non-existent log dir exits 1"
teardown_temp

# Test: empty log dir exits 0 (no items = nothing stuck/failed)
setup_temp
ec=0
STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null || ec=$?
assert_exit_code "0" "$ec" "genies_status: empty log dir exits 0"
teardown_temp

# ═══════════════════════════════════════════════
# Category 2: status classification from manifest
# ═══════════════════════════════════════════════

echo ""
echo "--- genies_status: status from manifest ---"

# Test: item in manifest succeeded → status=done, exit 0
setup_temp
touch "$TEMP_DIR/p1-auth.log"
write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "---"
ec=0
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null) || ec=$?
assert_exit_code "0" "$ec" "genies_status: all done exits 0"
assert_contains "$out" "done" "genies_status: succeeded item shows done"
assert_contains "$out" "p1-auth" "genies_status: succeeded item shows slug"
teardown_temp

# Test: item in manifest failed → status=failed, exit 1
setup_temp
touch "$TEMP_DIR/p1-auth.log"
write_manifest "$TEMP_DIR" "---" "docs/backlog/p1-auth.md" "---"
ec=0
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null) || ec=$?
assert_exit_code "1" "$ec" "genies_status: failed item exits 1"
assert_contains "$out" "failed" "genies_status: failed item shows failed status"
teardown_temp

# Test: item in manifest conflict → status=conflict, exit 1
setup_temp
touch "$TEMP_DIR/p1-auth.log"
write_manifest "$TEMP_DIR" "---" "---" "docs/backlog/p1-auth.md"
ec=0
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null) || ec=$?
assert_exit_code "1" "$ec" "genies_status: conflict item exits 1"
assert_contains "$out" "conflict" "genies_status: conflict item shows conflict status"
teardown_temp

# Test: mix of done and failed → exit 1
setup_temp
touch "$TEMP_DIR/p1-auth.log"
touch "$TEMP_DIR/p1-search.log"
write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "docs/backlog/p1-search.md" "---"
ec=0
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null) || ec=$?
assert_exit_code "1" "$ec" "genies_status: mix of done+failed exits 1"
assert_contains "$out" "done" "genies_status: done item shown in mix"
assert_contains "$out" "failed" "genies_status: failed item shown in mix"
teardown_temp

# ═══════════════════════════════════════════════
# Category 3: running and stuck detection
# ═══════════════════════════════════════════════

echo ""
echo "--- genies_status: running and stuck detection ---"

# Test: log present + process alive + recent log → running, exit 2
setup_temp
echo "[INFO] [deliver] Starting (max turns: 20)" > "$TEMP_DIR/p1-auth.log"
# No manifest entry — still running
ec=0
# Mock pgrep to return true for this slug
_orig_pgrep=$(declare -f _genies_status_process_alive)
_genies_status_process_alive() { [[ "$1" == "p1-auth" ]]; }
out=$(STATUS_LOG_DIR="$TEMP_DIR" STATUS_STUCK_MINS=10 genies_status 2>/dev/null) || ec=$?
assert_exit_code "2" "$ec" "genies_status: running item exits 2"
assert_contains "$out" "running" "genies_status: active item shows running"
[[ -n "$_orig_pgrep" ]] && eval "$_orig_pgrep" || unset -f _genies_status_process_alive
teardown_temp

# Test: log present + process alive + stale log → stuck, exit 1
setup_temp
echo "[INFO] [deliver] Starting (max turns: 20)" > "$TEMP_DIR/p1-auth.log"
# Backdate log file mtime by 20 minutes
touch -m -t "$(date -v-20M '+%Y%m%d%H%M.%S' 2>/dev/null || date -d '20 minutes ago' '+%Y%m%d%H%M.%S' 2>/dev/null || echo "202601010000.00")" "$TEMP_DIR/p1-auth.log"
_genies_status_process_alive() { [[ "$1" == "p1-auth" ]]; }
ec=0
out=$(STATUS_LOG_DIR="$TEMP_DIR" STATUS_STUCK_MINS=10 genies_status 2>/dev/null) || ec=$?
assert_exit_code "1" "$ec" "genies_status: stuck item exits 1"
assert_contains "$out" "stuck" "genies_status: stale-log item shows stuck"
unset -f _genies_status_process_alive
teardown_temp

# Test: log present + no process + not in manifest → failed, exit 1
setup_temp
echo "[INFO] [deliver] Starting (max turns: 20)" > "$TEMP_DIR/p1-auth.log"
_genies_status_process_alive() { return 1; }
ec=0
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null) || ec=$?
assert_exit_code "1" "$ec" "genies_status: crashed item exits 1"
assert_contains "$out" "failed" "genies_status: no-process item shows failed"
unset -f _genies_status_process_alive
teardown_temp

# Test: manifest done takes precedence over no-process check
setup_temp
echo "[INFO] [done] Completed" > "$TEMP_DIR/p1-auth.log"
write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "---"
_genies_status_process_alive() { return 1; }
ec=0
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null) || ec=$?
assert_exit_code "0" "$ec" "genies_status: manifest done takes precedence over no-process"
assert_contains "$out" "done" "genies_status: manifest done shown when no process"
unset -f _genies_status_process_alive
teardown_temp

# ═══════════════════════════════════════════════
# Category 4: phase detection from log
# ═══════════════════════════════════════════════

echo ""
echo "--- genies_status: phase detection ---"

# Test: last [phase] Starting line determines current phase
setup_temp
{
    echo "[INFO] [discover] Starting (max turns: 5)"
    echo "[INFO] [discover] Completed (3 turns)"
    echo "[INFO] [deliver] Starting (max turns: 20)"
} > "$TEMP_DIR/p1-auth.log"
write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "---"
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null)
assert_contains "$out" "deliver" "genies_status: phase detected as last Starting phase"
teardown_temp

# Test: no phase lines → shows unknown
setup_temp
echo "some random log output" > "$TEMP_DIR/p1-auth.log"
write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "---"
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null)
assert_contains "$out" "unknown" "genies_status: no phase lines shows unknown"
teardown_temp

# ═══════════════════════════════════════════════
# Category 5: duration
# ═══════════════════════════════════════════════

echo ""
echo "--- genies_status: duration ---"

# Test: duration column appears in output
setup_temp
touch "$TEMP_DIR/p1-auth.log"
write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "---"
out=$(STATUS_LOG_DIR="$TEMP_DIR" genies_status 2>/dev/null)
# Duration should appear (0m or similar since just created)
assert_contains "$out" "m" "genies_status: duration column shows minutes"
teardown_temp

# ═══════════════════════════════════════════════
# Category 6: --json output
# ═══════════════════════════════════════════════

echo ""
echo "--- genies_status: --json output ---"

# Test: --json flag produces JSON with items array
setup_temp
touch "$TEMP_DIR/p1-auth.log"
write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "---"
out=$(STATUS_LOG_DIR="$TEMP_DIR" STATUS_JSON=true genies_status 2>/dev/null)
assert_contains "$out" '"items"' "genies_status: --json has items array"
assert_contains "$out" '"summary"' "genies_status: --json has summary object"
assert_contains "$out" '"status"' "genies_status: --json items have status field"
assert_contains "$out" '"slug"' "genies_status: --json items have slug field"
assert_contains "$out" '"phase"' "genies_status: --json items have phase field"
assert_contains "$out" '"duration_secs"' "genies_status: --json items have duration_secs field"
teardown_temp

# Test: --json summary counts correct
setup_temp
touch "$TEMP_DIR/p1-auth.log"
touch "$TEMP_DIR/p1-search.log"
write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "docs/backlog/p1-search.md" "---"
out=$(STATUS_LOG_DIR="$TEMP_DIR" STATUS_JSON=true genies_status 2>/dev/null)
assert_contains "$out" '"total": 2' "genies_status: --json summary total correct"
assert_contains "$out" '"done": 1' "genies_status: --json summary done count"
assert_contains "$out" '"failed": 1' "genies_status: --json summary failed count"
teardown_temp

# Test: --json is valid JSON (jq can parse it)
if command -v jq &>/dev/null; then
    setup_temp
    touch "$TEMP_DIR/p1-auth.log"
    write_manifest "$TEMP_DIR" "docs/backlog/p1-auth.md" "---" "---"
    out=$(STATUS_LOG_DIR="$TEMP_DIR" STATUS_JSON=true genies_status 2>/dev/null)
    ec=0
    echo "$out" | jq . >/dev/null 2>&1 || ec=$?
    assert_exit_code "0" "$ec" "genies_status: --json output is valid JSON"
    teardown_temp
fi

# ═══════════════════════════════════════════════
# Category 7: subcommand dispatch
# ═══════════════════════════════════════════════

echo ""
echo "--- genies status: subcommand dispatch ---"

# Test: `genies status --log-dir <dir>` is a valid invocation
setup_temp
ec=0
bash "$RUN_PDLC" status --log-dir "$TEMP_DIR" 2>/dev/null || ec=$?
assert_exit_code "0" "$ec" "genies status: --log-dir dispatch works"
teardown_temp

# Test: `genies status` without --log-dir and no LOG_DIR → exits 1
setup_temp
ec=0
LOG_DIR="" bash "$RUN_PDLC" status 2>/dev/null || ec=$?
assert_exit_code "1" "$ec" "genies status: no log dir exits 1"
teardown_temp

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
