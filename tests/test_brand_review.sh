#!/bin/bash
# Tests for P3-multimodal-design-review deliverables
# Structural validation of commands/brand-review.md, agents/designer.md
# Visual Review Mode, and skills/brand-awareness/SKILL.md /brand:review behavior
#
# Run: bash tests/test_brand_review.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Test helpers (same pattern as other test files)
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

echo "=== P3: Multimodal Design Review — Structural Tests ==="
echo ""

# ─────────────────────────────────────────────
# AC-8: commands/brand-review.md exists and follows brand-image.md pattern
# ─────────────────────────────────────────────
echo -e "${YELLOW}--- AC-8: commands/brand-review.md structure ---${NC}"

BRAND_REVIEW="$PROJECT_DIR/commands/brand-review.md"

assert_file_exists "$BRAND_REVIEW" \
    "AC-8: commands/brand-review.md exists"

if [[ -f "$BRAND_REVIEW" ]]; then
    br_content=$(cat "$BRAND_REVIEW")

    # Must have the command header matching brand-image.md pattern
    assert_contains "$br_content" "# /brand:review" \
        "AC-8: has /brand:review command header"

    # Section structure must mirror brand-image.md
    assert_contains "$br_content" "## Arguments" \
        "AC-8: has Arguments section"

    assert_contains "$br_content" "## Agent Identity" \
        "AC-8: has Agent Identity section"

    assert_contains "$br_content" "## Context Loading" \
        "AC-8: has Context Loading section"

    assert_contains "$br_content" "## Routing" \
        "AC-8: has Routing section"

    assert_contains "$br_content" "## Notes" \
        "AC-8: has Notes section"

    assert_contains "$br_content" "## Usage Examples" \
        "AC-8: has Usage Examples section"

    # shellcheck disable=SC2016 # Literal $ARGUMENTS is intentional — checking for unexpanded marker
    assert_contains "$br_content" 'ARGUMENTS: $ARGUMENTS' \
        "AC-8: ends with ARGUMENTS: \$ARGUMENTS"
fi

# ─────────────────────────────────────────────
# AC-1: /brand:review invokes designer agent in visual review mode
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- AC-1: command invokes designer agent in visual review mode ---${NC}"

if [[ -f "$BRAND_REVIEW" ]]; then
    br_content=$(cat "$BRAND_REVIEW")

    assert_contains "$br_content" "image-path" \
        "AC-1: accepts image-path argument"

    assert_contains "$br_content" "designer.md" \
        "AC-1: references designer agent"

    assert_contains "$br_content" "visual review" \
        "AC-1: references visual review mode"

    assert_contains "$br_content" "Read tool" \
        "AC-1: references Read tool for image loading (ADR-004)"
fi

# ─────────────────────────────────────────────
# AC-7: Image path validation
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- AC-7: image path validation ---${NC}"

if [[ -f "$BRAND_REVIEW" ]]; then
    br_content=$(cat "$BRAND_REVIEW")

    assert_contains "$br_content" "Image Path Validation" \
        "AC-7: has Image Path Validation section"

    assert_contains "$br_content" ".png" \
        "AC-7: mentions .png as supported format"

    assert_contains "$br_content" ".jpg" \
        "AC-7: mentions .jpg as supported format"

    assert_contains "$br_content" ".webp" \
        "AC-7: mentions .webp as supported format"

    assert_contains "$br_content" "Image not found" \
        "AC-7: includes error message for missing file"

    assert_contains "$br_content" "Unsupported file type" \
        "AC-7: includes error message for unsupported type"
fi

# ─────────────────────────────────────────────
# AC-2: Report output structure
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- AC-2: Design Review Report structure ---${NC}"

if [[ -f "$BRAND_REVIEW" ]]; then
    br_content=$(cat "$BRAND_REVIEW")

    assert_contains "$br_content" "docs/brand/reviews/" \
        "AC-2: references docs/brand/reviews/ output path"

    assert_contains "$br_content" "Brand Adherence" \
        "AC-2: report includes Brand Adherence section"

    assert_contains "$br_content" "Accessibility Signals" \
        "AC-2: report includes Accessibility Signals section"

    assert_contains "$br_content" "UX Quality" \
        "AC-2: report includes UX Quality section"

    assert_contains "$br_content" "Recommendations" \
        "AC-2: report includes Recommendations section"

    assert_contains "$br_content" "type: design-review" \
        "AC-2: report template has type: design-review frontmatter"
fi

# ─────────────────────────────────────────────
# AC-3: Brand Adherence references specific brand rules
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- AC-3: brand-aware review criteria ---${NC}"

if [[ -f "$BRAND_REVIEW" ]]; then
    br_content=$(cat "$BRAND_REVIEW")

    assert_contains "$br_content" "brand guide" \
        "AC-3: references brand guide loading"

    assert_contains "$br_content" "brand-awareness" \
        "AC-3: references brand-awareness skill"
fi

# ─────────────────────────────────────────────
# AC-4: Heuristics-only fallback
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- AC-4: heuristics-only fallback ---${NC}"

if [[ -f "$BRAND_REVIEW" ]]; then
    br_content=$(cat "$BRAND_REVIEW")

    assert_contains "$br_content" "heuristics-only" \
        "AC-4: mentions heuristics-only mode"

    assert_contains "$br_content" "No brand guide found" \
        "AC-4: includes no-brand-guide fallback message"

    assert_contains "$br_content" "Nielsen" \
        "AC-4: references Nielsen's heuristics"
fi

# ─────────────────────────────────────────────
# AC-5: Actionable recommendations
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- AC-5: actionable recommendations ---${NC}"

if [[ -f "$BRAND_REVIEW" ]]; then
    br_content=$(cat "$BRAND_REVIEW")

    assert_contains "$br_content" "actionable" \
        "AC-5: mentions actionable recommendations"

    assert_contains "$br_content" "WCAG" \
        "AC-5: references WCAG standards"

    assert_contains "$br_content" "4.5:1" \
        "AC-5: references specific WCAG AA contrast ratio"
fi

# ─────────────────────────────────────────────
# AC-6: Review reports directory
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- AC-6: persistent review reports ---${NC}"

assert_dir_exists "$PROJECT_DIR/docs/brand/reviews" \
    "AC-6: docs/brand/reviews/ directory exists"

assert_file_exists "$PROJECT_DIR/docs/brand/reviews/.gitkeep" \
    "AC-6: docs/brand/reviews/.gitkeep exists"

# ─────────────────────────────────────────────
# Designer agent: Visual Review Mode section
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- Designer agent: Visual Review Mode ---${NC}"

DESIGNER="$PROJECT_DIR/agents/designer.md"

if [[ -f "$DESIGNER" ]]; then
    designer_content=$(cat "$DESIGNER")

    assert_contains "$designer_content" "## Visual Review Mode" \
        "Designer: has '## Visual Review Mode' section"

    assert_contains "$designer_content" "Entry Condition" \
        "Designer: Visual Review Mode has Entry Condition subsection"

    assert_contains "$designer_content" "Analysis Criteria" \
        "Designer: Visual Review Mode has Analysis Criteria subsection"

    assert_contains "$designer_content" "Brand Adherence" \
        "Designer: Visual Review Mode covers Brand Adherence analysis"

    assert_contains "$designer_content" "Accessibility Signals" \
        "Designer: Visual Review Mode covers Accessibility Signals analysis"

    assert_contains "$designer_content" "UX Quality" \
        "Designer: Visual Review Mode covers UX Quality analysis"

    assert_contains "$designer_content" "Provider Limitation" \
        "Designer: Visual Review Mode has Provider Limitation Note"

    assert_contains "$designer_content" "18588" \
        "Designer: Visual Review Mode references GitHub #18588"

    assert_contains "$designer_content" "WILL NOT" \
        "Designer: Visual Review Mode has WILL NOT Do list"

    # Visual Review Mode must come AFTER Image Generation and BEFORE Agent Result Format
    # Test ordering: Image Generation should appear before Visual Review Mode
    img_gen_line=$(echo "$designer_content" | grep -n "## Image Generation" | head -1 | cut -d: -f1)
    visual_review_line=$(echo "$designer_content" | grep -n "## Visual Review Mode" | head -1 | cut -d: -f1)
    agent_result_line=$(echo "$designer_content" | grep -n "## Agent Result Format" | head -1 | cut -d: -f1)

    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -n "$img_gen_line" && -n "$visual_review_line" && -n "$agent_result_line" ]] \
        && [[ "$img_gen_line" -lt "$visual_review_line" ]] \
        && [[ "$visual_review_line" -lt "$agent_result_line" ]]; then
        echo -e "${GREEN}PASS${NC} Designer: Visual Review Mode ordered between Image Generation and Agent Result Format"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} Designer: Visual Review Mode ordered between Image Generation and Agent Result Format"
        echo "  Image Generation: line $img_gen_line, Visual Review: line $visual_review_line, Agent Result: line $agent_result_line"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
fi

# ─────────────────────────────────────────────
# Brand-awareness skill: /brand:review behavior
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- Brand-awareness skill: /brand:review behavior ---${NC}"

SKILL="$PROJECT_DIR/skills/brand-awareness/SKILL.md"

if [[ -f "$SKILL" ]]; then
    skill_content=$(cat "$SKILL")

    assert_contains "$skill_content" "### During /brand:review" \
        "Skill: has '### During /brand:review' behavior entry"

    assert_contains "$skill_content" "/brand:review" \
        "Skill: mentions /brand:review command"

    # /brand:review behavior must come AFTER /brand:image and BEFORE /brand:tokens
    brand_image_line=$(echo "$skill_content" | grep -n "### During /brand:image" | head -1 | cut -d: -f1)
    brand_review_line=$(echo "$skill_content" | grep -n "### During /brand:review" | head -1 | cut -d: -f1)
    brand_tokens_line=$(echo "$skill_content" | grep -n "### During /brand:tokens" | head -1 | cut -d: -f1)

    TESTS_RUN=$((TESTS_RUN + 1))
    if [[ -n "$brand_image_line" && -n "$brand_review_line" && -n "$brand_tokens_line" ]] \
        && [[ "$brand_image_line" -lt "$brand_review_line" ]] \
        && [[ "$brand_review_line" -lt "$brand_tokens_line" ]]; then
        echo -e "${GREEN}PASS${NC} Skill: /brand:review ordered between /brand:image and /brand:tokens"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} Skill: /brand:review ordered between /brand:image and /brand:tokens"
        echo "  /brand:image: line $brand_image_line, /brand:review: line $brand_review_line, /brand:tokens: line $brand_tokens_line"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi

    # Behavior content checks
    assert_contains "$skill_content" "review criteria" \
        "Skill: /brand:review injects brand rules as review criteria"

    assert_regex "$skill_content" "Reads:.*docs/brand" \
        "Skill: /brand:review has Reads summary referencing docs/brand"

    assert_regex "$skill_content" "Writes:.*Nothing" \
        "Skill: /brand:review has Writes: Nothing (read-only)"
fi

# ─────────────────────────────────────────────
# Skill activation list includes /brand:review
# ─────────────────────────────────────────────
echo ""
echo -e "${YELLOW}--- Skill activation list ---${NC}"

if [[ -f "$SKILL" ]]; then
    skill_content=$(cat "$SKILL")

    # The "When Active" section should list /brand:review
    assert_regex "$skill_content" "brand:review" \
        "Skill: activation list includes /brand:review"
fi

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
