#!/bin/bash
# Tier 1: Lint YAML frontmatter syntax in markdown files
# Extracts frontmatter block (between --- delimiters) and validates YAML syntax.
# Input: file paths as positional arguments (pre-commit convention)
# Exit: 0 if all clean, 1 if any syntax errors

set -euo pipefail

REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

# Line-length limit — must match .yamllint.yml max
MAX_LINE_LENGTH=200

# Detect available YAML validator once
YAML_VALIDATOR="none"
if command -v yamllint &>/dev/null; then
    YAML_VALIDATOR="yamllint"
elif command -v python3 &>/dev/null && python3 -c "import yaml" 2>/dev/null; then
    YAML_VALIDATOR="python3"
fi

if [[ "$YAML_VALIDATOR" == "none" && $# -gt 0 ]]; then
    echo "[TIER-1] WARNING: No YAML validator available (install yamllint or python3-yaml)" >&2
fi

errors=0

for file in "$@"; do
    # Skip files that don't exist
    [[ -f "$file" ]] || continue

    # Check if file has frontmatter (starts with ---)
    first_line=$(head -1 "$file")
    if [[ "$first_line" != "---" ]]; then
        continue
    fi

    # Find the closing --- line number (second occurrence)
    close_line=$(awk 'NR > 1 && /^---$/ { print NR; exit }' "$file")
    if [[ -z "$close_line" ]]; then
        echo "[TIER-1] $file — unclosed frontmatter (no closing ---)" >&2
        errors=$((errors + 1))
        continue
    fi

    # Extract frontmatter (between line 2 and close_line - 1)
    frontmatter_start=2
    frontmatter_end=$((close_line - 1))

    if [[ $frontmatter_end -lt $frontmatter_start ]]; then
        continue  # Empty frontmatter block
    fi

    # Extract and validate with available tool
    extracted=$(sed -n "${frontmatter_start},${frontmatter_end}p" "$file")

    if [[ "$YAML_VALIDATOR" == "yamllint" ]]; then
        # Use yamllint with config if available
        yamllint_config="$REPO_ROOT/.yamllint.yml"
        yamllint_args=("-d" "relaxed")
        if [[ -f "$yamllint_config" ]]; then
            yamllint_args=("-c" "$yamllint_config")
        fi

        lint_output=$(echo "$extracted" | yamllint "${yamllint_args[@]}" - 2>&1) || {
            # Offset line numbers to match original file
            # yamllint output: "stdin\n  LINE:COL  level  message"
            while IFS= read -r line; do
                if [[ "$line" =~ ^[[:space:]]+([0-9]+):([0-9]+)[[:space:]]+(.*)$ ]]; then
                    orig_line=$(( BASH_REMATCH[1] + frontmatter_start - 1 ))
                    echo "[TIER-1] $file:$orig_line:${BASH_REMATCH[2]} ${BASH_REMATCH[3]}" >&2
                fi
            done <<< "$lint_output"
            echo "[TIER-1] $file — invalid YAML syntax in frontmatter" >&2
            errors=$((errors + 1))
        }
    elif [[ "$YAML_VALIDATOR" == "python3" ]]; then
        # Check syntax
        if ! echo "$extracted" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" 2>/dev/null; then
            echo "[TIER-1] $file — invalid YAML syntax in frontmatter" >&2
            errors=$((errors + 1))
            continue
        fi
        # Check line length (matches .yamllint.yml max)
        line_num=$frontmatter_start
        has_long_line=0
        while IFS= read -r yaml_line; do
            if [[ ${#yaml_line} -gt $MAX_LINE_LENGTH ]]; then
                echo "[TIER-1] $file:$line_num: line too long (${#yaml_line} > $MAX_LINE_LENGTH)" >&2
                has_long_line=1
            fi
            line_num=$((line_num + 1))
        done <<< "$extracted"
        if [[ $has_long_line -eq 1 ]]; then
            echo "[TIER-1] $file — line too long in frontmatter" >&2
            errors=$((errors + 1))
        fi
    fi
    # No validator: skip validation (better than false positives)
done

if [[ $errors -gt 0 ]]; then
    exit 1
fi
exit 0
