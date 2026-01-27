#!/bin/bash
# Tests for commands/execute.sh
# Run: bash tests/test_execute.sh

# Note: set -e intentionally omitted — test harness manages its own exit codes
# via assert_* helpers and TESTS_FAILED counter

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures"
EXECUTE_SH="$PROJECT_DIR/commands/execute.sh"

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

# Source execute.sh functions (it must support being sourced)
if [[ -f "$EXECUTE_SH" ]]; then
    # Source in a subshell-safe way: set EXECUTE_SOURCED to skip main()
    EXECUTE_SOURCED=true
    source "$EXECUTE_SH"
else
    echo -e "${RED}ERROR${NC} commands/execute.sh not found at $EXECUTE_SH"
    echo "Tests require the implementation to exist (even if incomplete)."
    exit 2
fi

echo "=== execute.sh Tests ==="
echo ""

# ─────────────────────────────────────────────
# Test: extract_frontmatter
# ─────────────────────────────────────────────
echo "--- extract_frontmatter ---"

result=$(extract_frontmatter "$FIXTURES_DIR/valid_spec.md")
assert_contains "$result" "type: shaped-work" \
    "extract_frontmatter: returns type field from valid spec"

assert_contains "$result" "id: TEST-1" \
    "extract_frontmatter: returns id field from valid spec"

assert_contains "$result" "acceptance_criteria:" \
    "extract_frontmatter: returns acceptance_criteria from valid spec"

result=$(extract_frontmatter "$FIXTURES_DIR/valid_design.md")
assert_contains "$result" "type: design" \
    "extract_frontmatter: returns type field from valid design"

assert_contains "$result" "ac_mapping:" \
    "extract_frontmatter: returns ac_mapping from valid design"

result=$(extract_frontmatter "$FIXTURES_DIR/no_frontmatter.md" 2>/dev/null)
assert_eq "" "$result" \
    "extract_frontmatter: returns empty for file without frontmatter"

# ─────────────────────────────────────────────
# Test: get_field
# ─────────────────────────────────────────────
echo ""
echo "--- get_field ---"

frontmatter=$(extract_frontmatter "$FIXTURES_DIR/valid_spec.md")

result=$(get_field "$frontmatter" "type")
assert_eq "shaped-work" "$result" \
    "get_field: extracts type field"

result=$(get_field "$frontmatter" "id")
assert_eq "TEST-1" "$result" \
    "get_field: extracts id field"

result=$(get_field "$frontmatter" "title")
assert_eq "Test Feature" "$result" \
    "get_field: extracts title field"

result=$(get_field "$frontmatter" "spec_version")
assert_eq "1.0" "$result" \
    "get_field: extracts spec_version (strips quotes)"

result=$(get_field "$frontmatter" "appetite")
assert_eq "small" "$result" \
    "get_field: extracts appetite field"

result=$(get_field "$frontmatter" "nonexistent")
assert_eq "" "$result" \
    "get_field: returns empty for nonexistent field"

# ─────────────────────────────────────────────
# Test: validate_spec
# ─────────────────────────────────────────────
echo ""
echo "--- validate_spec ---"

output=$(validate_spec "$FIXTURES_DIR/valid_spec.md" 2>&1)
ec=$?
assert_exit_code "0" "$ec" \
    "validate_spec: valid spec passes"

# spec_version is required
output=$(validate_spec "$FIXTURES_DIR/invalid_spec_no_version.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_spec: missing spec_version fails"
assert_contains "$output" "spec_version" \
    "validate_spec: error mentions missing field 'spec_version'"

output=$(validate_spec "$FIXTURES_DIR/invalid_spec_missing_type.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_spec: missing type field fails"
assert_contains "$output" "type" \
    "validate_spec: error mentions missing field 'type'"

output=$(validate_spec "$FIXTURES_DIR/invalid_spec_wrong_type.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_spec: wrong type value fails"

output=$(validate_spec "$FIXTURES_DIR/invalid_spec_no_ac.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_spec: missing acceptance_criteria fails"

output=$(validate_spec "$FIXTURES_DIR/no_frontmatter.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_spec: no frontmatter fails"

# type: spec (persistent spec) should also pass validation
output=$(validate_spec "$FIXTURES_DIR/valid_spec_type.md" 2>&1)
ec=$?
assert_exit_code "0" "$ec" \
    "validate_spec: type 'spec' passes (persistent spec)"

# ─────────────────────────────────────────────
# Test: validate_design
# ─────────────────────────────────────────────
echo ""
echo "--- validate_design ---"

output=$(validate_design "$FIXTURES_DIR/valid_design.md" 2>&1)
ec=$?
assert_exit_code "0" "$ec" \
    "validate_design: valid design passes"

output=$(validate_design "$FIXTURES_DIR/invalid_design_missing_spec_ref.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_design: missing spec_ref fails"
assert_contains "$output" "spec_ref" \
    "validate_design: error mentions missing field 'spec_ref'"

output=$(validate_design "$FIXTURES_DIR/no_frontmatter.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_design: no frontmatter fails"

output=$(validate_design "$FIXTURES_DIR/invalid_design_no_ac_mapping.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_design: missing ac_mapping fails"
assert_contains "$output" "ac_mapping" \
    "validate_design: error mentions missing field 'ac_mapping'"

output=$(validate_design "$FIXTURES_DIR/invalid_design_no_version.md" 2>&1)
ec=$?
assert_exit_code "1" "$ec" \
    "validate_design: missing spec_version fails"
assert_contains "$output" "spec_version" \
    "validate_design: error mentions missing field 'spec_version'"

# ─────────────────────────────────────────────
# Test: generate_branch_name
# ─────────────────────────────────────────────
echo ""
echo "--- generate_branch_name ---"

result=$(generate_branch_name "GT-1" "Spec-Driven Execution Mode")
assert_eq "feat/gt-1-spec-driven-execution-mode" "$result" \
    "generate_branch_name: lowercase with hyphens"

result=$(generate_branch_name "TEST-1" "Test Feature")
assert_eq "feat/test-1-test-feature" "$result" \
    "generate_branch_name: simple id and title"

result=$(generate_branch_name "AUTH-42" "Token Refresh & Rotation Flow")
assert_eq "feat/auth-42-token-refresh-rotation-flow" "$result" \
    "generate_branch_name: strips special characters"

# ─────────────────────────────────────────────
# Test: CLI argument parsing (dry-run mode)
# ─────────────────────────────────────────────
echo ""
echo "--- CLI dry-run ---"

output=$("$EXECUTE_SH" --dry-run \
    --spec "$FIXTURES_DIR/valid_spec.md" \
    --design "$FIXTURES_DIR/valid_design.md" \
    --repo /tmp/test-repo 2>&1)
ec=$?
assert_exit_code "0" "$ec" \
    "CLI dry-run: valid inputs exit 0"
assert_contains "$output" "TEST-1" \
    "CLI dry-run: output includes spec id"
assert_contains "$output" "Test Feature" \
    "CLI dry-run: output includes spec title"

output=$("$EXECUTE_SH" --dry-run \
    --spec "$FIXTURES_DIR/invalid_spec_missing_type.md" \
    --design "$FIXTURES_DIR/valid_design.md" \
    --repo /tmp/test-repo 2>&1)
ec=$?
assert_exit_code "3" "$ec" \
    "CLI dry-run: invalid spec exits 3 (blocked)"

output=$("$EXECUTE_SH" --dry-run \
    --spec "$FIXTURES_DIR/valid_spec.md" \
    --design "$FIXTURES_DIR/invalid_design_missing_spec_ref.md" \
    --repo /tmp/test-repo 2>&1)
ec=$?
assert_exit_code "3" "$ec" \
    "CLI dry-run: invalid design exits 3 (blocked)"

# type: spec should work as --spec input (persistent spec)
output=$("$EXECUTE_SH" --dry-run \
    --spec "$FIXTURES_DIR/valid_spec_type.md" \
    --design "$FIXTURES_DIR/valid_design.md" \
    --repo /tmp/test-repo 2>&1)
ec=$?
assert_exit_code "0" "$ec" \
    "CLI dry-run: type 'spec' accepted as valid spec"
assert_contains "$output" "SPEC-1" \
    "CLI dry-run: output includes persistent spec id"

# ─────────────────────────────────────────────
# Test: CLI missing required arguments
# ─────────────────────────────────────────────
echo ""
echo "--- CLI argument validation ---"

output=$("$EXECUTE_SH" 2>&1)
ec=$?
assert_exit_code "3" "$ec" \
    "CLI: no arguments exits 3"

output=$("$EXECUTE_SH" --spec "$FIXTURES_DIR/valid_spec.md" 2>&1)
ec=$?
assert_exit_code "3" "$ec" \
    "CLI: missing --design exits 3"

output=$("$EXECUTE_SH" --spec "$FIXTURES_DIR/valid_spec.md" --design "$FIXTURES_DIR/valid_design.md" 2>&1)
ec=$?
assert_exit_code "3" "$ec" \
    "CLI: missing --repo exits 3"

output=$("$EXECUTE_SH" --spec "/nonexistent/path.md" --design "$FIXTURES_DIR/valid_design.md" --repo /tmp 2>&1)
ec=$?
assert_exit_code "3" "$ec" \
    "CLI: nonexistent spec file exits 3"

output=$("$EXECUTE_SH" --help 2>&1)
ec=$?
assert_exit_code "0" "$ec" \
    "CLI: --help exits 0"
assert_contains "$output" "Usage" \
    "CLI: --help output includes Usage"
assert_contains "$output" "--spec" \
    "CLI: --help output mentions --spec"

# ─────────────────────────────────────────────
# Test: build_prompt
# ─────────────────────────────────────────────
echo ""
echo "--- build_prompt ---"

result=$(build_prompt "$FIXTURES_DIR/valid_spec.md" "$FIXTURES_DIR/valid_design.md")
assert_contains "$result" "spec_version" \
    "build_prompt: includes spec content"
assert_contains "$result" "type: design" \
    "build_prompt: includes design content"
assert_contains "$result" "execution report" \
    "build_prompt: instructs to produce execution report"
assert_contains "$result" "execution-report" \
    "build_prompt: references execution-report type"

# ─────────────────────────────────────────────
# Test: extract_report
# ─────────────────────────────────────────────
echo ""
echo "--- extract_report ---"

mock_output="Some preamble text from Claude.

---
spec_version: \"1.0\"
type: execution-report
id: TEST-1
title: Test Feature
status: complete
created: 2026-01-27T14:30:00Z
spec_ref: docs/backlog/P1-test-feature.md
design_ref: docs/backlog/P1-test-feature.md
execution_mode: headless
exit_code: 0
confidence: high
branch: feat/test-1-test-feature
commit_sha: pending
files_changed:
  - action: added
    path: src/test.ts
    purpose: Test component
test_results:
  passed: 2
  failed: 0
  skipped: 0
  command: npm test
acceptance_criteria:
  - id: AC-1
    status: met
    evidence: Test component created
  - id: AC-2
    status: met
    evidence: Validation added
---

# Execution Report: TEST-1 Test Feature

## Summary
Implemented the test feature successfully.

Some trailing text."

result=$(echo "$mock_output" | extract_report)
assert_contains "$result" "type: execution-report" \
    "extract_report: extracts report frontmatter"
assert_contains "$result" "id: TEST-1" \
    "extract_report: includes id field"
assert_contains "$result" "# Execution Report" \
    "extract_report: includes report body"

result=$(echo "No report here at all" | extract_report 2>/dev/null)
assert_eq "" "$result" \
    "extract_report: returns empty for output without report"

# Multiple frontmatter blocks — extract_report should skip non-report blocks
multi_fm_output="Here is the spec I read:

---
spec_version: \"1.0\"
type: shaped-work
id: TEST-1
title: Test Feature
---

And here is the report:

---
spec_version: \"1.0\"
type: execution-report
id: TEST-1
title: Test Feature
status: complete
---

# Execution Report

Done."

result=$(echo "$multi_fm_output" | extract_report)
assert_contains "$result" "type: execution-report" \
    "extract_report: skips non-report frontmatter, finds report"
assert_eq "" "$(echo "$result" | grep 'type: shaped-work')" \
    "extract_report: does not include shaped-work frontmatter"
assert_contains "$result" "# Execution Report" \
    "extract_report: includes body after report frontmatter"

# ─────────────────────────────────────────────
# Test: get_exit_code_from_status
# ─────────────────────────────────────────────
echo ""
echo "--- get_exit_code_from_status ---"

assert_eq "0" "$(get_exit_code_from_status "complete")" \
    "get_exit_code_from_status: complete → 0"
assert_eq "1" "$(get_exit_code_from_status "partial")" \
    "get_exit_code_from_status: partial → 1"
assert_eq "2" "$(get_exit_code_from_status "failed")" \
    "get_exit_code_from_status: failed → 2"
assert_eq "3" "$(get_exit_code_from_status "blocked")" \
    "get_exit_code_from_status: blocked → 3"
assert_eq "2" "$(get_exit_code_from_status "unknown")" \
    "get_exit_code_from_status: unknown defaults to 2"

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
