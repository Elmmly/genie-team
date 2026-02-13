#!/bin/bash
# Tests for P1-context-aware-transition-guidance
# Validates structural correctness of transition guidance in skill and command files.
# Run: bash tests/test_transition_guidance.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"

# Files under test (canonical sources)
BRAND_SKILL="$PROJECT_DIR/skills/brand-awareness/SKILL.md"
SPEC_SKILL="$PROJECT_DIR/skills/spec-awareness/SKILL.md"
ARCH_SKILL="$PROJECT_DIR/skills/architecture-awareness/SKILL.md"
HANDOFF_CMD="$PROJECT_DIR/commands/handoff.md"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
NC='\033[0m'

assert_contains() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if grep -qF -- "$pattern" "$file"; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected file to contain: '$pattern'"
        echo "  File: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_regex() {
    local file="$1"
    local pattern="$2"
    local test_name="$3"
    TESTS_RUN=$((TESTS_RUN + 1))

    if grep -qE -- "$pattern" "$file"; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected file to match regex: '$pattern'"
        echo "  File: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

assert_section_order() {
    local file="$1"
    local first="$2"
    local second="$3"
    local test_name="$4"
    TESTS_RUN=$((TESTS_RUN + 1))

    local first_line
    local second_line
    first_line=$(grep -nF -- "$first" "$file" | head -1 | cut -d: -f1)
    second_line=$(grep -nF -- "$second" "$file" | head -1 | cut -d: -f1)

    if [[ -n "$first_line" && -n "$second_line" && "$first_line" -lt "$second_line" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  Expected '$first' (L${first_line:-missing}) before '$second' (L${second_line:-missing})"
        echo "  File: $file"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================
# AC-1: Consistent transition guidance format across skills
# ============================================================
echo ""
echo "=== AC-1: Consistent transition guidance format ==="

assert_contains "$BRAND_SKILL" \
    '**Transition guidance** (conditional):' \
    "AC-1: brand-awareness has transition guidance step"

assert_contains "$SPEC_SKILL" \
    '**Transition guidance** (conditional):' \
    "AC-1: spec-awareness has transition guidance step"

assert_contains "$ARCH_SKILL" \
    '**Transition guidance** (conditional):' \
    "AC-1: architecture-awareness has transition guidance step"

# Verify numbered step format (N. **Transition guidance**)
assert_regex "$BRAND_SKILL" \
    '^[0-9]+\. \*\*Transition guidance\*\*' \
    "AC-1: brand-awareness uses numbered step format"

assert_regex "$SPEC_SKILL" \
    '^[0-9]+\. \*\*Transition guidance\*\*' \
    "AC-1: spec-awareness uses numbered step format"

assert_regex "$ARCH_SKILL" \
    '^[0-9]+\. \*\*Transition guidance\*\*' \
    "AC-1: architecture-awareness uses numbered step format"

# ============================================================
# AC-2: brand-awareness visual verification in /deliver + /discern
# ============================================================
echo ""
echo "=== AC-2: Visual verification reminders ==="

assert_contains "$BRAND_SKILL" \
    '**Visual verification recommended:**' \
    "AC-2: brand-awareness /deliver has visual verification reminder"

assert_contains "$BRAND_SKILL" \
    '**Visual evidence:**' \
    "AC-2: brand-awareness /discern has visual evidence reminder"

# ============================================================
# AC-3: brand-awareness asset review in /deliver
# ============================================================
echo ""
echo "=== AC-3: Asset review reminder ==="

assert_contains "$BRAND_SKILL" \
    '**Brand assets available:**' \
    "AC-3: brand-awareness /deliver has asset review reminder"

assert_contains "$BRAND_SKILL" \
    'docs/brand/assets/manifest.md' \
    "AC-3: brand-awareness references manifest.md for asset detection"

# ============================================================
# AC-4: brand-awareness staleness warning in /context:refresh
# ============================================================
echo ""
echo "=== AC-4: Asset staleness warning ==="

assert_contains "$BRAND_SKILL" \
    'Brand asset images may be stale' \
    "AC-4: brand-awareness /context:refresh has staleness warning"

assert_contains "$BRAND_SKILL" \
    'manifest entries have dates older than the brand guide' \
    "AC-4: staleness compares manifest dates vs brand guide updated field"

# ============================================================
# AC-5: spec-awareness spec-delta reminder in /deliver
# ============================================================
echo ""
echo "=== AC-5: Spec delta reminder ==="

assert_contains "$SPEC_SKILL" \
    '**Spec delta active:**' \
    "AC-5: spec-awareness /deliver has spec delta reminder"

assert_contains "$SPEC_SKILL" \
    '**Regression watch:**' \
    "AC-5: spec-awareness /deliver has regression watch reminder"

assert_contains "$SPEC_SKILL" \
    'Behavioral Delta' \
    "AC-5: spec-awareness detects Behavioral Delta section"

# ============================================================
# AC-6: architecture-awareness ADR compliance in /deliver
# ============================================================
echo ""
echo "=== AC-6: ADR compliance reminder ==="

assert_contains "$ARCH_SKILL" \
    '**ADR compliance:**' \
    "AC-6: architecture-awareness /deliver has ADR compliance reminder"

assert_contains "$ARCH_SKILL" \
    'adr_refs' \
    "AC-6: architecture-awareness detects adr_refs in frontmatter"

# ============================================================
# AC-7: /handoff integration with awareness skills
# ============================================================
echo ""
echo "=== AC-7: Handoff integration ==="

# Each skill adds /handoff to activation triggers
assert_contains "$BRAND_SKILL" \
    '/handoff' \
    "AC-7: brand-awareness frontmatter includes /handoff trigger"

assert_contains "$SPEC_SKILL" \
    '/handoff' \
    "AC-7: spec-awareness frontmatter includes /handoff trigger"

assert_contains "$ARCH_SKILL" \
    '/handoff' \
    "AC-7: architecture-awareness frontmatter includes /handoff trigger"

# Each skill has "During /handoff" section
assert_contains "$BRAND_SKILL" \
    '### During /handoff' \
    "AC-7: brand-awareness has 'During /handoff' section"

assert_contains "$SPEC_SKILL" \
    '### During /handoff' \
    "AC-7: spec-awareness has 'During /handoff' section"

assert_contains "$ARCH_SKILL" \
    '### During /handoff' \
    "AC-7: architecture-awareness has 'During /handoff' section"

# Handoff command has domain guidance sections
assert_contains "$HANDOFF_CMD" \
    'Domain-Specific Guidance' \
    "AC-7: handoff command has Domain-Specific Guidance section"

assert_contains "$HANDOFF_CMD" \
    'domain context' \
    "AC-7: handoff command has domain context blocks in templates"

# ============================================================
# AC-8: Zero-cost — guidance gated by conditions
# ============================================================
echo ""
echo "=== AC-8: Zero-cost guarantee ==="

# Brand guidance is conditional on brand guide existing
assert_contains "$BRAND_SKILL" \
    'If no brand guide: Silently continue (no guidance injected)' \
    "AC-8: brand /handoff has zero-cost guard"

assert_contains "$SPEC_SKILL" \
    'If no spec: Silently continue (no guidance injected)' \
    "AC-8: spec /handoff has zero-cost guard"

assert_contains "$ARCH_SKILL" \
    'If no ADRs: Silently continue (no guidance injected)' \
    "AC-8: arch /handoff has zero-cost guard"

# ============================================================
# Structural: Section ordering
# ============================================================
echo ""
echo "=== Structural: Section ordering ==="

# brand-awareness: /handoff section comes before Brand Update Rules
assert_section_order "$BRAND_SKILL" \
    '### During /handoff' \
    '## Brand Update Rules' \
    "Structural: brand /handoff section before Brand Update Rules"

# spec-awareness: /handoff section comes before /discover
assert_section_order "$SPEC_SKILL" \
    '### During /handoff' \
    '### During /discover' \
    "Structural: spec /handoff section before /discover"

# architecture-awareness: /handoff section comes before /context:load
assert_section_order "$ARCH_SKILL" \
    '### During /handoff' \
    '### During /context:load' \
    "Structural: arch /handoff section before /context:load"

# ============================================================
# Structural: /handoff in When Active lists
# ============================================================
echo ""
echo "=== Structural: When Active lists ==="

assert_contains "$BRAND_SKILL" \
    '/handoff' \
    "Structural: brand-awareness When Active list includes /handoff"

assert_contains "$SPEC_SKILL" \
    '/handoff' \
    "Structural: spec-awareness When Active list includes /handoff"

assert_contains "$ARCH_SKILL" \
    '/handoff' \
    "Structural: architecture-awareness When Active list includes /handoff"

# ============================================================
# Summary
# ============================================================
echo ""
echo "========================================"
echo "Results: $TESTS_PASSED/$TESTS_RUN passed, $TESTS_FAILED failed"
echo "========================================"

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi
