#!/bin/bash
# Tests for spec-aware test generation (P2-spec-aware-test-generation)
# Validates that agents/crafter.md contains the required spec-to-stub
# mapping pass instructions per the design specification.
# Run: bash tests/test_spec_aware_stubs.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
CRAFTER_MD="$PROJECT_DIR/agents/crafter.md"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

# Test helpers
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
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_regex() {
    local haystack="$1"
    local pattern="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if echo "$haystack" | grep -qE -- "$pattern"; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected to match pattern: '$pattern'"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# Load crafter.md content
if [[ ! -f "$CRAFTER_MD" ]]; then
    echo -e "${RED}ERROR${NC} agents/crafter.md not found at $CRAFTER_MD"
    exit 2
fi

CRAFTER_CONTENT=$(cat "$CRAFTER_MD")

echo "=== Spec-Aware Test Generation Tests ==="
echo ""

# ─────────────────────────────────────────────
# ac_id: AC-1
# Spec-to-stub mapping pass exists as first step of RED phase
# ─────────────────────────────────────────────
echo "--- AC-1: Spec-to-stub mapping pass ---"

# Arrange - crafter.md content loaded above

# Act - check for mapping pass section
# (no action needed; content is static)

# Assert - mapping pass section exists within RED phase
assert_contains "$CRAFTER_CONTENT" "Spec-to-Stub Mapping Pass" \
    "AC-1: crafter.md contains Spec-to-Stub Mapping Pass section"

assert_regex "$CRAFTER_CONTENT" "RED Phase Preamble" \
    "AC-1: mapping pass is labeled as RED Phase Preamble"

assert_contains "$CRAFTER_CONTENT" "one failing test stub per AC" \
    "AC-1: instruction specifies one stub per AC minimum"

assert_contains "$CRAFTER_CONTENT" "before any" \
    "AC-1: mapping pass runs before other test writing"

# ─────────────────────────────────────────────
# ac_id: AC-2
# Each stub includes ac_id comment linking to source AC
# ─────────────────────────────────────────────
echo ""
echo "--- AC-2: ac_id comment in stubs ---"

# Arrange - crafter.md content loaded above

# Act - check for ac_id comment instruction

# Assert - ac_id comment syntax is documented
assert_contains "$CRAFTER_CONTENT" "ac_id" \
    "AC-2: crafter.md mentions ac_id"

assert_regex "$CRAFTER_CONTENT" "# ac_id: AC-" \
    "AC-2: shows Python/Bash ac_id comment syntax example"

assert_regex "$CRAFTER_CONTENT" "// ac_id: AC-" \
    "AC-2: shows JS/TS/Go ac_id comment syntax example"

assert_contains "$CRAFTER_CONTENT" "first line inside the test" \
    "AC-2: ac_id comment placed as first line inside test"

# ─────────────────────────────────────────────
# ac_id: AC-3
# AAA pattern with TODO markers and failing assertion
# ─────────────────────────────────────────────
echo ""
echo "--- AC-3: AAA stub template with TODO and fail ---"

# Arrange - crafter.md content loaded above

# Act - check for AAA stub template instructions

# Assert - TODO markers and failing assertions documented
assert_contains "$CRAFTER_CONTENT" "TODO" \
    "AC-3: stub template includes TODO markers"

assert_regex "$CRAFTER_CONTENT" "(fail|assert False|expect.*false)" \
    "AC-3: stub template includes failing assertion example"

assert_regex "$CRAFTER_CONTENT" "Arrange.*TODO" \
    "AC-3: Arrange section has TODO marker instruction"

assert_regex "$CRAFTER_CONTENT" "Act.*TODO" \
    "AC-3: Act section has TODO marker instruction"

assert_regex "$CRAFTER_CONTENT" "(Assert.*fail|failing assertion)" \
    "AC-3: Assert section has failing assertion instruction"

# ─────────────────────────────────────────────
# ac_id: AC-4
# Edge-case tests added after mapping pass
# ─────────────────────────────────────────────
echo ""
echo "--- AC-4: Edge-case tests after mapping pass ---"

# Arrange - crafter.md content loaded above

# Act - check for edge-case test instruction

# Assert - edge-case instruction exists after mapping pass
assert_contains "$CRAFTER_CONTENT" "edge-case" \
    "AC-4: crafter.md mentions edge-case tests"

assert_regex "$CRAFTER_CONTENT" "at least one edge-case" \
    "AC-4: instruction to add at least one edge-case test per AC"

assert_regex "$CRAFTER_CONTENT" "(after|After).*stubs.*written" \
    "AC-4: edge-case tests come after all stubs are written"

# ─────────────────────────────────────────────
# ac_id: AC-5
# Coverage table at end of RED phase
# ─────────────────────────────────────────────
echo ""
echo "--- AC-5: Coverage table ---"

# Arrange - crafter.md content loaded above

# Act - check for coverage table instruction

# Assert - coverage table documented
assert_contains "$CRAFTER_CONTENT" "Coverage Table" \
    "AC-5: crafter.md contains coverage table instruction"

assert_contains "$CRAFTER_CONTENT" "Coverage Type" \
    "AC-5: coverage table has Coverage Type column"

assert_regex "$CRAFTER_CONTENT" "direct.*edge-case" \
    "AC-5: coverage types include direct and edge-case"

assert_regex "$CRAFTER_CONTENT" "(end of RED|before.*GREEN|before running tests)" \
    "AC-5: coverage table is output at end of RED phase"

# ─────────────────────────────────────────────
# ac_id: AC-6
# Graceful handling when no acceptance_criteria
# ─────────────────────────────────────────────
echo ""
echo "--- AC-6: No ACs graceful fallback ---"

# Arrange - crafter.md content loaded above

# Act - check for guard clause instruction

# Assert - warning message and fallback behavior documented
assert_regex "$CRAFTER_CONTENT" "[Nn]o.*AC.*found" \
    "AC-6: guard clause logs warning when no ACs found"

assert_contains "$CRAFTER_CONTENT" "manual test writing" \
    "AC-6: falls back to manual test writing when no ACs"

assert_regex "$CRAFTER_CONTENT" "(skip|Skip).*mapping" \
    "AC-6: skips mapping pass when no acceptance_criteria"

# ─────────────────────────────────────────────
# ac_id: AC-7
# Documented in TDD Cycle section of crafter.md
# ─────────────────────────────────────────────
echo ""
echo "--- AC-7: Documented in TDD Cycle section ---"

# Arrange - crafter.md content loaded above

# Act - check section placement

# Assert - mapping pass lives in TDD Cycle section
assert_contains "$CRAFTER_CONTENT" "TDD Cycle" \
    "AC-7: TDD Cycle section exists in crafter.md"

assert_contains "$CRAFTER_CONTENT" "Spec-to-Stub Mapping Pass" \
    "AC-7: mapping pass section is present for all invocations"

# Verify headless mode also references the mapping pass
assert_regex "$CRAFTER_CONTENT" "[Hh]eadless.*mapping pass" \
    "AC-7: headless mode references the mapping pass"

assert_regex "$CRAFTER_CONTENT" "automatic.*headless|headless.*automatic" \
    "AC-7: mapping pass is automatic in headless mode"

# ─────────────────────────────────────────────
# Edge-case tests beyond direct AC coverage
# ─────────────────────────────────────────────
echo ""
echo "--- Edge cases ---"

# ac_id: AC-2
# Edge: ac_id comment syntax table covers multiple languages
assert_regex "$CRAFTER_CONTENT" "Python.*ac_id|pytest.*ac_id" \
    "AC-2 edge: ac_id syntax documented for Python"

assert_regex "$CRAFTER_CONTENT" "JavaScript.*ac_id|jest.*ac_id" \
    "AC-2 edge: ac_id syntax documented for JavaScript"

assert_regex "$CRAFTER_CONTENT" "Bash.*ac_id|bats.*ac_id" \
    "AC-2 edge: ac_id syntax documented for Bash"

assert_regex "$CRAFTER_CONTENT" "Go.*ac_id|testing.*ac_id" \
    "AC-2 edge: ac_id syntax documented for Go"

# ac_id: AC-3
# Edge: multiple language examples for failing assertions
assert_regex "$CRAFTER_CONTENT" "assert False" \
    "AC-3 edge: Python failing assertion example"

assert_regex "$CRAFTER_CONTENT" "fail\(\"AC-" \
    "AC-3 edge: JS/Go failing assertion with AC reference"

# ac_id: AC-5
# Edge: coverage table includes 'missing' type for safety
assert_contains "$CRAFTER_CONTENT" "missing" \
    "AC-5 edge: coverage table documents 'missing' type"

# ac_id: AC-1
# Edge: large spec guard (>10 ACs) grouping instruction
assert_regex "$CRAFTER_CONTENT" "AC count.*>.*10|more than 10 AC|exceeds 10" \
    "AC-1 edge: large spec guard documented for >10 ACs"

assert_regex "$CRAFTER_CONTENT" "(group|Group).*describe|describe.*block" \
    "AC-1 edge: grouping into describe blocks for large specs"

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
