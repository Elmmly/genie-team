#!/bin/bash
# Tests for hooks/precommit/ scripts
# Run: bash tests/test_precommit.sh

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
FIXTURES_DIR="$SCRIPT_DIR/fixtures/precommit"

# Scripts under test
LINT_FRONTMATTER="$PROJECT_DIR/hooks/precommit/lint-frontmatter-yaml.sh"
VALIDATE_FRONTMATTER="$PROJECT_DIR/hooks/precommit/validate-frontmatter.sh"
CHECK_CROSSREFS="$PROJECT_DIR/hooks/precommit/check-crossrefs.sh"
CHECK_SOURCE_SYNC="$PROJECT_DIR/hooks/precommit/check-source-sync.sh"

# Test counters
TESTS_RUN=0
TESTS_PASSED=0
TESTS_FAILED=0

# Colors
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Temp directory for test isolation
TEST_TMP=""

setup() {
    TEST_TMP=$(mktemp -d)
}

teardown() {
    rm -rf "$TEST_TMP"
}

# Run a command and capture exit code + output without || true swallowing it
run_cmd() {
    local _exit_code=0
    _output=$("$@" 2>&1) || _exit_code=$?
    _last_exit=$_exit_code
}

# Test helpers (same pattern as test_hooks.sh)
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
        echo "  In: '$(echo "$haystack" | head -5)...'"
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

    if [[ -f "$path" ]]; then
        echo -e "${GREEN}PASS${NC} $test_name"
        TESTS_PASSED=$((TESTS_PASSED + 1))
    else
        echo -e "${RED}FAIL${NC} $test_name"
        echo "  File not found: $path"
        TESTS_FAILED=$((TESTS_FAILED + 1))
    fi
}

# ============================================================
# TIER 1: lint-frontmatter-yaml.sh (AC-1)
# ============================================================
echo ""
echo -e "${YELLOW}=== TIER 1: lint-frontmatter-yaml.sh (AC-1) ===${NC}"
echo ""

# T1.1: Valid YAML frontmatter passes
setup
run_cmd "$LINT_FRONTMATTER" "$FIXTURES_DIR/valid_backlog.md"
assert_exit_code "0" "$_last_exit" "T1.1: valid YAML frontmatter passes"
teardown

# T1.2: Invalid YAML syntax fails
setup
run_cmd "$LINT_FRONTMATTER" "$FIXTURES_DIR/invalid_yaml_syntax.md"
assert_exit_code "1" "$_last_exit" "T1.2: invalid YAML syntax fails"
teardown

# T1.3: File without frontmatter is skipped (passes)
setup
run_cmd "$LINT_FRONTMATTER" "$FIXTURES_DIR/no_frontmatter.md"
assert_exit_code "0" "$_last_exit" "T1.3: no frontmatter file is skipped"
teardown

# T1.4: Multiple files — one bad, one good — fails overall
setup
run_cmd "$LINT_FRONTMATTER" "$FIXTURES_DIR/valid_backlog.md" "$FIXTURES_DIR/invalid_yaml_syntax.md"
assert_exit_code "1" "$_last_exit" "T1.4: mixed valid/invalid files fails"
teardown

# T1.5: Valid ADR frontmatter passes
setup
run_cmd "$LINT_FRONTMATTER" "$FIXTURES_DIR/valid_adr.md"
assert_exit_code "0" "$_last_exit" "T1.5: valid ADR frontmatter passes"
teardown

# T1.6: Error output includes filename
setup
run_cmd "$LINT_FRONTMATTER" "$FIXTURES_DIR/invalid_yaml_syntax.md"
assert_contains "$_output" "invalid_yaml_syntax.md" "T1.6: error output includes filename"
teardown

# ============================================================
# TIER 2: validate-frontmatter.sh (AC-2)
# ============================================================
echo ""
echo -e "${YELLOW}=== TIER 2: validate-frontmatter.sh (AC-2) ===${NC}"
echo ""

# T2.1: Valid shaped-work frontmatter passes
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/valid_backlog.md"
assert_exit_code "0" "$_last_exit" "T2.1: valid shaped-work passes schema"
teardown

# T2.2: Valid ADR frontmatter passes
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/valid_adr.md"
assert_exit_code "0" "$_last_exit" "T2.2: valid ADR passes schema"
teardown

# T2.3: Valid architecture-diagram frontmatter passes
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/valid_architecture.md"
assert_exit_code "0" "$_last_exit" "T2.3: valid architecture-diagram passes schema"
teardown

# T2.4: Missing required field fails
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/missing_required_field.md"
assert_exit_code "1" "$_last_exit" "T2.4: missing required field fails"
teardown

# T2.5: Missing field error mentions the field name
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/missing_required_field.md"
assert_contains "$_output" "appetite" "T2.5: error mentions missing 'appetite' field"
teardown

# T2.6: Invalid enum value fails
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/invalid_enum_value.md"
assert_exit_code "1" "$_last_exit" "T2.6: invalid enum value fails"
teardown

# T2.7: Invalid enum error mentions the bad value
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/invalid_enum_value.md"
assert_contains "$_output" "invented" "T2.7: error mentions invalid status 'invented'"
teardown

# T2.8: No frontmatter — skipped silently (passes)
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/no_frontmatter.md"
assert_exit_code "0" "$_last_exit" "T2.8: no frontmatter file is skipped"
teardown

# T2.9: Unknown type — skipped silently (passes)
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/unknown_type.md"
assert_exit_code "0" "$_last_exit" "T2.9: unknown type is skipped"
teardown

# T2.10: Error output includes TIER-2 prefix
setup
run_cmd "$VALIDATE_FRONTMATTER" "$FIXTURES_DIR/missing_required_field.md"
assert_contains "$_output" "TIER-2" "T2.10: error output includes TIER-2 prefix"
teardown

# ============================================================
# TIER 3: check-crossrefs.sh (AC-3)
# ============================================================
echo ""
echo -e "${YELLOW}=== TIER 3: check-crossrefs.sh (AC-3) ===${NC}"
echo ""

# T3.1: Valid cross-references pass (create referenced files)
setup
mkdir -p "$TEST_TMP/docs/backlog" "$TEST_TMP/docs/specs/test" "$TEST_TMP/docs/decisions"
echo "---" > "$TEST_TMP/docs/specs/test/capability.md"
echo "type: spec" >> "$TEST_TMP/docs/specs/test/capability.md"
echo "---" >> "$TEST_TMP/docs/specs/test/capability.md"
echo "---" > "$TEST_TMP/docs/decisions/ADR-001-test.md"
echo "type: adr" >> "$TEST_TMP/docs/decisions/ADR-001-test.md"
echo "---" >> "$TEST_TMP/docs/decisions/ADR-001-test.md"
cp "$FIXTURES_DIR/valid_crossrefs.md" "$TEST_TMP/docs/backlog/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_CROSSREFS" "docs/backlog/test.md" 2>&1) || _exit_code=$?
assert_exit_code "0" "$_exit_code" "T3.1: valid cross-references pass"
teardown

# T3.2: Broken cross-references fail
setup
mkdir -p "$TEST_TMP/docs/backlog"
cp "$FIXTURES_DIR/broken_crossrefs.md" "$TEST_TMP/docs/backlog/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_CROSSREFS" "docs/backlog/test.md" 2>&1) || _exit_code=$?
assert_exit_code "1" "$_exit_code" "T3.2: broken cross-references fail"
teardown

# T3.3: Broken ref error mentions the missing path
setup
mkdir -p "$TEST_TMP/docs/backlog"
cp "$FIXTURES_DIR/broken_crossrefs.md" "$TEST_TMP/docs/backlog/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_CROSSREFS" "docs/backlog/test.md" 2>&1) || _exit_code=$?
assert_contains "$_output" "docs/specs/nonexistent/ghost.md" "T3.3: error mentions broken spec_ref path"
teardown

# T3.4: Broken adr_refs mentioned
setup
mkdir -p "$TEST_TMP/docs/backlog"
cp "$FIXTURES_DIR/broken_crossrefs.md" "$TEST_TMP/docs/backlog/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_CROSSREFS" "docs/backlog/test.md" 2>&1) || _exit_code=$?
assert_contains "$_output" "ADR-999" "T3.4: error mentions broken adr_refs"
teardown

# T3.5: No refs — passes silently
setup
mkdir -p "$TEST_TMP/docs/backlog"
cp "$FIXTURES_DIR/no_refs.md" "$TEST_TMP/docs/backlog/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_CROSSREFS" "docs/backlog/test.md" 2>&1) || _exit_code=$?
assert_exit_code "0" "$_exit_code" "T3.5: file with no refs passes"
teardown

# T3.6: No frontmatter — passes silently
setup
mkdir -p "$TEST_TMP/docs"
cp "$FIXTURES_DIR/no_frontmatter.md" "$TEST_TMP/docs/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_CROSSREFS" "docs/test.md" 2>&1) || _exit_code=$?
assert_exit_code "0" "$_exit_code" "T3.6: no frontmatter file passes"
teardown

# T3.7: Error output includes TIER-3 prefix
setup
mkdir -p "$TEST_TMP/docs/backlog"
cp "$FIXTURES_DIR/broken_crossrefs.md" "$TEST_TMP/docs/backlog/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_CROSSREFS" "docs/backlog/test.md" 2>&1) || _exit_code=$?
assert_contains "$_output" "TIER-3" "T3.7: error output includes TIER-3 prefix"
teardown

# ============================================================
# TIER 4: check-source-sync.sh (AC-4)
# ============================================================
echo ""
echo -e "${YELLOW}=== TIER 4: check-source-sync.sh (AC-4) ===${NC}"
echo ""

# T4.1: Synced files pass
setup
mkdir -p "$TEST_TMP/commands" "$TEST_TMP/dist/commands" "$TEST_TMP/.claude/commands"
echo "# Same content" > "$TEST_TMP/commands/test.md"
echo "# Same content" > "$TEST_TMP/dist/commands/test.md"
echo "# Same content" > "$TEST_TMP/.claude/commands/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_SOURCE_SYNC" "dist/commands/test.md" ".claude/commands/test.md" 2>&1) || _exit_code=$?
assert_exit_code "0" "$_exit_code" "T4.1: synced files pass"
teardown

# T4.2: Drifted installed copy fails
setup
mkdir -p "$TEST_TMP/commands" "$TEST_TMP/dist/commands"
echo "# Source version" > "$TEST_TMP/commands/test.md"
echo "# Drifted version" > "$TEST_TMP/dist/commands/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_SOURCE_SYNC" "dist/commands/test.md" 2>&1) || _exit_code=$?
assert_exit_code "1" "$_exit_code" "T4.2: drifted installed copy fails"
teardown

# T4.3: Drift error mentions canonical source
setup
mkdir -p "$TEST_TMP/commands" "$TEST_TMP/dist/commands"
echo "# Source version" > "$TEST_TMP/commands/test.md"
echo "# Drifted version" > "$TEST_TMP/dist/commands/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_SOURCE_SYNC" "dist/commands/test.md" 2>&1) || _exit_code=$?
assert_contains "$_output" "commands/test.md" "T4.3: error mentions canonical source"
teardown

# T4.4: Files not in sync map are ignored (pass)
setup
mkdir -p "$TEST_TMP/random"
echo "# Random file" > "$TEST_TMP/random/file.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_SOURCE_SYNC" "random/file.md" 2>&1) || _exit_code=$?
assert_exit_code "0" "$_exit_code" "T4.4: file outside sync map passes"
teardown

# T4.5: Error output includes TIER-4 prefix
setup
mkdir -p "$TEST_TMP/commands" "$TEST_TMP/dist/commands"
echo "# Source" > "$TEST_TMP/commands/test.md"
echo "# Different" > "$TEST_TMP/dist/commands/test.md"
git -C "$TEST_TMP" init -q
_exit_code=0
_output=$(cd "$TEST_TMP" && "$CHECK_SOURCE_SYNC" "dist/commands/test.md" 2>&1) || _exit_code=$?
assert_contains "$_output" "TIER-4" "T4.5: error output includes TIER-4 prefix"
teardown

# ============================================================
# AC-5: Pre-commit config structure
# ============================================================
echo ""
echo -e "${YELLOW}=== AC-5: Pre-commit config structure ===${NC}"
echo ""

# T5.1: .pre-commit-config.yaml exists
assert_file_exists "$PROJECT_DIR/.pre-commit-config.yaml" "T5.1: .pre-commit-config.yaml exists"

# T5.2: .yamllint.yml exists
assert_file_exists "$PROJECT_DIR/.yamllint.yml" "T5.2: .yamllint.yml exists"

# T5.3: Config references shellcheck
config_content=$(cat "$PROJECT_DIR/.pre-commit-config.yaml" 2>/dev/null || echo "")
assert_contains "$config_content" "shellcheck" "T5.3: config references shellcheck"

# T5.4: Config references local hooks
assert_contains "$config_content" "repo: local" "T5.4: config references local hooks"

# T5.5: Config references all 4 custom hook scripts
assert_contains "$config_content" "lint-frontmatter-yaml" "T5.5a: config references lint-frontmatter-yaml"
assert_contains "$config_content" "validate-frontmatter" "T5.5b: config references validate-frontmatter"
assert_contains "$config_content" "check-crossrefs" "T5.5c: config references check-crossrefs"
assert_contains "$config_content" "check-source-sync" "T5.5d: config references check-source-sync"

# ============================================================
# AC-6: install.sh prehook command
# ============================================================
echo ""
echo -e "${YELLOW}=== AC-6: install.sh prehook command ===${NC}"
echo ""

INSTALL_SH="$PROJECT_DIR/install.sh"

# T6.1: prehook command installs .pre-commit-config.yaml
setup
mkdir -p "$TEST_TMP/.git"
"$INSTALL_SH" prehook "$TEST_TMP" 2>/dev/null || true
assert_file_exists "$TEST_TMP/.pre-commit-config.yaml" "T6.1: prehook installs .pre-commit-config.yaml"
teardown

# T6.2: prehook command installs .yamllint.yml
setup
mkdir -p "$TEST_TMP/.git"
"$INSTALL_SH" prehook "$TEST_TMP" 2>/dev/null || true
assert_file_exists "$TEST_TMP/.yamllint.yml" "T6.2: prehook installs .yamllint.yml"
teardown

# T6.3: prehook command installs custom hook scripts
setup
mkdir -p "$TEST_TMP/.git"
"$INSTALL_SH" prehook "$TEST_TMP" 2>/dev/null || true
assert_file_exists "$TEST_TMP/hooks/precommit/lint-frontmatter-yaml.sh" "T6.3a: installs lint-frontmatter-yaml.sh"
assert_file_exists "$TEST_TMP/hooks/precommit/validate-frontmatter.sh" "T6.3b: installs validate-frontmatter.sh"
assert_file_exists "$TEST_TMP/hooks/precommit/check-crossrefs.sh" "T6.3c: installs check-crossrefs.sh"
assert_file_exists "$TEST_TMP/hooks/precommit/check-source-sync.sh" "T6.3d: installs check-source-sync.sh"
teardown

# T6.4: prehook bails if .pre-commit-config.yaml already exists
setup
mkdir -p "$TEST_TMP/.git"
echo "existing config" > "$TEST_TMP/.pre-commit-config.yaml"
_exit_code=0
_output=$("$INSTALL_SH" prehook "$TEST_TMP" 2>&1) || _exit_code=$?
assert_eq "1" "$_exit_code" "T6.4: prehook bails on existing config"
teardown

# T6.5: prehook --force overwrites existing config
setup
mkdir -p "$TEST_TMP/.git"
echo "old config" > "$TEST_TMP/.pre-commit-config.yaml"
"$INSTALL_SH" prehook "$TEST_TMP" --force 2>/dev/null || true
new_content=$(cat "$TEST_TMP/.pre-commit-config.yaml")
assert_not_contains "$new_content" "old config" "T6.5: --force overwrites existing config"
teardown

# T6.6: prehook bails on non-git directory
setup
_exit_code=0
_output=$("$INSTALL_SH" prehook "$TEST_TMP" 2>&1) || _exit_code=$?
assert_eq "1" "$_exit_code" "T6.6: prehook bails on non-git directory"
teardown

# T6.7: prehook --dry-run doesn't create files
setup
mkdir -p "$TEST_TMP/.git"
"$INSTALL_SH" prehook "$TEST_TMP" --dry-run 2>/dev/null || true
TESTS_RUN=$((TESTS_RUN + 1))
if [[ ! -f "$TEST_TMP/.pre-commit-config.yaml" ]]; then
    echo -e "${GREEN}PASS${NC} T6.7: --dry-run doesn't create files"
    TESTS_PASSED=$((TESTS_PASSED + 1))
else
    echo -e "${RED}FAIL${NC} T6.7: --dry-run doesn't create files"
    echo "  File should not exist: $TEST_TMP/.pre-commit-config.yaml"
    TESTS_FAILED=$((TESTS_FAILED + 1))
fi
teardown

# T6.8: Template config has header comment
setup
mkdir -p "$TEST_TMP/.git"
"$INSTALL_SH" prehook "$TEST_TMP" 2>/dev/null || true
content=$(cat "$TEST_TMP/.pre-commit-config.yaml" 2>/dev/null || echo "")
assert_contains "$content" "genie-team" "T6.8: template config mentions genie-team"
teardown

# ============================================================
# Summary
# ============================================================
echo ""
echo "======================================="
echo "Tests: $TESTS_RUN  Passed: $TESTS_PASSED  Failed: $TESTS_FAILED"
echo "======================================="

if [[ $TESTS_FAILED -gt 0 ]]; then
    exit 1
fi
exit 0
