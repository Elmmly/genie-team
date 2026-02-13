#!/bin/bash
# Tests for systematic-debugging skill
# Validates skill file structure, required content, and crafter integration
# Run: bash tests/test_systematic_debugging.sh

# Note: set -e intentionally omitted — test harness manages its own exit codes
# via assert_* helpers and TESTS_FAILED counter

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
SKILL_FILE="$PROJECT_DIR/.claude/skills/systematic-debugging/SKILL.md"
CRAFTER_FILE="$PROJECT_DIR/agents/crafter.md"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
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

assert_file_exists() {
    local file_path="$1"
    local test_name="$2"
    TESTS_RUN=$((TESTS_RUN + 1))

    if [[ -f "$file_path" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  File not found: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_grep() {
    local file_path="$1"
    local pattern="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if grep -q "$pattern" "$file_path" 2>/dev/null; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Pattern not found: '$pattern'"
        echo "  In file: $file_path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

echo "=== systematic-debugging Skill Tests ==="
echo ""

# ─────────────────────────────────────────────
# AC-1: Skill file exists with proper frontmatter
# ─────────────────────────────────────────────
echo "--- AC-1: Skill file exists with frontmatter ---"

assert_file_exists "$SKILL_FILE" \
    "AC-1: SKILL.md exists at .claude/skills/systematic-debugging/"

assert_grep "$SKILL_FILE" "^name: systematic-debugging" \
    "AC-1: frontmatter has name field"

assert_grep "$SKILL_FILE" "^description:" \
    "AC-1: frontmatter has description field"

assert_grep "$SKILL_FILE" "^allowed-tools:" \
    "AC-1: frontmatter has allowed-tools field"

# ─────────────────────────────────────────────
# AC-2: 4-phase root cause investigation protocol
# ─────────────────────────────────────────────
echo ""
echo "--- AC-2: 4-phase protocol ---"

assert_grep "$SKILL_FILE" "## Phase 1" \
    "AC-2: Phase 1 exists (reproduce and read)"

assert_grep "$SKILL_FILE" "## Phase 2" \
    "AC-2: Phase 2 exists (pattern analysis)"

assert_grep "$SKILL_FILE" "## Phase 3" \
    "AC-2: Phase 3 exists (hypothesis testing)"

assert_grep "$SKILL_FILE" "## Phase 4" \
    "AC-2: Phase 4 exists (implement the fix)"

assert_grep "$SKILL_FILE" "ONE change" \
    "AC-2: Phase 3 enforces one change at a time"

assert_grep "$SKILL_FILE" "failing test" \
    "AC-2: Phase 4 references failing test first (TDD integration)"

# ─────────────────────────────────────────────
# AC-3: 3-strike escalation rule
# ─────────────────────────────────────────────
echo ""
echo "--- AC-3: Escalation rule ---"

assert_grep "$SKILL_FILE" "Escalation" \
    "AC-3: escalation section exists"

assert_grep "$SKILL_FILE" "3" \
    "AC-3: references 3-attempt threshold"

assert_grep "$SKILL_FILE" "STOP" \
    "AC-3: includes STOP directive"

assert_grep "$SKILL_FILE" "assumptions" \
    "AC-3: requires questioning assumptions"

# ─────────────────────────────────────────────
# AC-4: RED FLAGS section
# ─────────────────────────────────────────────
echo ""
echo "--- AC-4: RED FLAGS section ---"

assert_grep "$SKILL_FILE" "RED FLAG" \
    "AC-4: RED FLAGS section exists"

assert_grep "$SKILL_FILE" "Shotgun debugging" \
    "AC-4: blocks shotgun debugging"

assert_grep "$SKILL_FILE" "Symptom fixing" \
    "AC-4: blocks symptom fixing"

assert_grep "$SKILL_FILE" "It works now" \
    "AC-4: blocks 'it works now' without understanding"

# ─────────────────────────────────────────────
# AC-5: Trigger-context framing in description
# ─────────────────────────────────────────────
echo ""
echo "--- AC-5: Description uses trigger-context framing ---"

# Extract description from frontmatter
if [[ -f "$SKILL_FILE" ]]; then
    desc_line=$(grep "^description:" "$SKILL_FILE" 2>/dev/null || echo "")
    assert_contains "$desc_line" "Use when" \
        "AC-5: description uses 'Use when' trigger-context framing"

    # Verify description does NOT summarize the 4-phase process
    TESTS_RUN=$((TESTS_RUN + 1))
    if echo "$desc_line" | grep -qi "4.phase\|four.phase\|reproduce.*analyze.*hypothesis.*implement"; then
        echo -e "${RED}FAIL${NC} AC-5: description should NOT summarize the debugging process"
        echo "  Description summarizes the protocol — should only describe trigger context"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    else
        echo -e "${GREEN}PASS${NC} AC-5: description does not summarize the debugging process"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    fi
else
    TESTS_RUN=$((TESTS_RUN + 2))
    echo -e "${RED}FAIL${NC} AC-5: description uses 'Use when' trigger-context framing"
    echo "  File not found: $SKILL_FILE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
    echo -e "${RED}FAIL${NC} AC-5: description does not summarize the debugging process"
    echo "  File not found: $SKILL_FILE"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi

# ─────────────────────────────────────────────
# AC-6: Crafter agent lists systematic-debugging
# ─────────────────────────────────────────────
echo ""
echo "--- AC-6: Crafter agent integration ---"

assert_grep "$CRAFTER_FILE" "systematic-debugging" \
    "AC-6: crafter.md lists systematic-debugging in skills"

# ─────────────────────────────────────────────
# AC-7: Install.sh installs the skill
# ─────────────────────────────────────────────
echo ""
echo "--- AC-7: install.sh compatibility ---"

# Verify install_skills copies from .claude/skills/ (which includes our new dir)
assert_file_exists "$PROJECT_DIR/.claude/skills/systematic-debugging/SKILL.md" \
    "AC-7: skill is in .claude/skills/ (install source directory)"

# Verify install.sh install_skills function exists and references .claude/skills
assert_grep "$PROJECT_DIR/install.sh" 'install_skills' \
    "AC-7: install.sh has install_skills function"

assert_grep "$PROJECT_DIR/install.sh" '\.claude/skills' \
    "AC-7: install_skills copies from .claude/skills directory"

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
