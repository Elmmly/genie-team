#!/bin/bash
# Tests for P1-extended-thinking-integration
# Validates: agents/scout.md, agents/architect.md, commands/discover.md, commands/design.md
# Run: bash tests/test_extended_thinking.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Files under test
SCOUT="$PROJECT_DIR/agents/scout.md"
ARCHITECT="$PROJECT_DIR/agents/architect.md"
DISCOVER="$PROJECT_DIR/commands/discover.md"
DESIGN="$PROJECT_DIR/commands/design.md"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

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

# ─────────────────────────────────────────────
echo "=== Extended Thinking Integration Tests ==="
echo ""

scout=$(cat "$SCOUT")
architect=$(cat "$ARCHITECT")
discover=$(cat "$DISCOVER")
design=$(cat "$DESIGN")

# ─────────────────────────────────────────────
# AC-1: Scout has no hardcoded model (inherits from parent)
# ─────────────────────────────────────────────
echo "--- AC-1: Scout model inheritance ---"

assert_not_contains "$scout" "model:" \
    "AC-1: Scout frontmatter has no hardcoded model"

# ─────────────────────────────────────────────
# AC-2: Scout Deep Reasoning section
# ─────────────────────────────────────────────
echo ""
echo "--- AC-2: Scout Deep Reasoning section ---"

assert_contains "$scout" "## Deep Reasoning" \
    "AC-2: Scout has Deep Reasoning section header"

assert_contains "$scout" "reason through" \
    "AC-2: Scout Deep Reasoning includes reasoning-through directive"

assert_contains "$scout" "counter-evidence" \
    "AC-2: Scout Deep Reasoning includes counter-evidence directive"

assert_contains "$scout" "challenge" \
    "AC-2: Scout Deep Reasoning includes challenge-framing directive"

assert_contains "$scout" "justification" \
    "AC-2: Scout Deep Reasoning includes evidence justification directive"

# ─────────────────────────────────────────────
# AC-3: Architect Deep Reasoning section
# ─────────────────────────────────────────────
echo ""
echo "--- AC-3: Architect Deep Reasoning section ---"

assert_contains "$architect" "## Deep Reasoning" \
    "AC-3: Architect has Deep Reasoning section header"

assert_contains "$architect" "alternative" \
    "AC-3: Architect Deep Reasoning includes alternatives directive"

assert_contains "$architect" "failure mode" \
    "AC-3: Architect Deep Reasoning includes failure modes directive"

assert_contains "$architect" "why that pattern" \
    "AC-3: Architect Deep Reasoning includes pattern justification directive"

assert_contains "$architect" "concrete scenario" \
    "AC-3: Architect Deep Reasoning includes concrete risk scenarios directive"

# ─────────────────────────────────────────────
# AC-4: /discover --fast flag support
# ─────────────────────────────────────────────
echo ""
echo "--- AC-4: /discover --fast flag ---"

assert_contains "$discover" "--fast" \
    "AC-4: discover command references --fast flag"

assert_contains "$discover" "reasoning_mode" \
    "AC-4: discover command references reasoning_mode"

assert_contains "$discover" "speed" \
    "AC-4: discover command includes speed instruction concept"

# ─────────────────────────────────────────────
# AC-5: /design --fast flag support
# ─────────────────────────────────────────────
echo ""
echo "--- AC-5: /design --fast flag ---"

assert_contains "$design" "--fast" \
    "AC-5: design command references --fast flag"

assert_contains "$design" "reasoning_mode" \
    "AC-5: design command references reasoning_mode"

assert_contains "$design" "speed" \
    "AC-5: design command includes speed instruction concept"

# ─────────────────────────────────────────────
# AC-6: Default reasoning_mode is deep
# ─────────────────────────────────────────────
echo ""
echo "--- AC-6: Default reasoning_mode: deep ---"

assert_contains "$scout" "reasoning_mode: deep" \
    "AC-6: Scout Opportunity Snapshot template has reasoning_mode: deep"

assert_contains "$architect" "reasoning_mode: deep" \
    "AC-6: Architect Design Document template has reasoning_mode: deep"

# ─────────────────────────────────────────────
# AC-7: Existing structure preserved
# ─────────────────────────────────────────────
echo ""
echo "--- AC-7: Existing structure preserved ---"

# Scout existing sections
assert_contains "$scout" "## Charter" \
    "AC-7: Scout still has Charter section"
assert_contains "$scout" "## Judgment Rules" \
    "AC-7: Scout still has Judgment Rules section"
assert_contains "$scout" "## Anti-Patterns to Catch" \
    "AC-7: Scout still has Anti-Patterns section"
assert_contains "$scout" "## Opportunity Snapshot Template" \
    "AC-7: Scout still has Opportunity Snapshot Template section"
assert_contains "$scout" "## Routing" \
    "AC-7: Scout still has Routing section"

# Architect existing sections
assert_contains "$architect" "## Charter" \
    "AC-7: Architect still has Charter section"
assert_contains "$architect" "## Judgment Rules" \
    "AC-7: Architect still has Judgment Rules section"
assert_contains "$architect" "## Design Document Template" \
    "AC-7: Architect still has Design Document Template section"
assert_contains "$architect" "## Routing" \
    "AC-7: Architect still has Routing section"

# Scout template structure preserved (type, topic, status, created fields still present)
assert_contains "$scout" "type: discover" \
    "AC-7: Scout template still has type: discover"
assert_regex "$scout" 'topic:.*\{topic\}' \
    "AC-7: Scout template still has topic field"
assert_contains "$scout" "status: active" \
    "AC-7: Scout template still has status: active"

# Architect template structure preserved
assert_contains "$architect" "type: design" \
    "AC-7: Architect template still has type: design"
assert_regex "$architect" 'status: designed' \
    "AC-7: Architect template still has status: designed"

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
