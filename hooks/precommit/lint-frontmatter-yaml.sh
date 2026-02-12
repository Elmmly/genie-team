#!/bin/bash
# Tier 1: Lint YAML frontmatter syntax in markdown files
# Extracts frontmatter block (between --- delimiters) and validates YAML syntax.
# Input: file paths as positional arguments (pre-commit convention)
# Exit: 0 if all clean, 1 if any syntax errors

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
REPO_ROOT="$(git rev-parse --show-toplevel 2>/dev/null || echo ".")"

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

    # Extract and validate with yamllint if available, otherwise basic check
    extracted=$(sed -n "${frontmatter_start},${frontmatter_end}p" "$file")

    if command -v yamllint &>/dev/null; then
        # Use yamllint with config if available
        yamllint_config="$REPO_ROOT/.yamllint.yml"
        yamllint_args=("-d" "relaxed")
        if [[ -f "$yamllint_config" ]]; then
            yamllint_args=("-c" "$yamllint_config")
        fi

        lint_output=$(echo "$extracted" | yamllint "${yamllint_args[@]}" - 2>&1) || {
            # Offset line numbers to match original file
            while IFS= read -r line; do
                # yamllint output format: "stdin:LINE:COL: [severity] message"
                if [[ "$line" =~ ^stdin:([0-9]+):(.*)$ ]]; then
                    orig_line=$(( ${BASH_REMATCH[1]} + frontmatter_start - 1 ))
                    echo "[TIER-1] $file:$orig_line:${BASH_REMATCH[2]}" >&2
                elif [[ "$line" =~ ^[[:space:]] ]]; then
                    echo "  $line" >&2
                fi
            done <<< "$lint_output"
            errors=$((errors + 1))
        }
    else
        # Fallback: basic YAML syntax check using python if available
        if command -v python3 &>/dev/null; then
            if ! echo "$extracted" | python3 -c "import sys, yaml; yaml.safe_load(sys.stdin)" 2>/dev/null; then
                echo "[TIER-1] $file — invalid YAML syntax in frontmatter" >&2
                errors=$((errors + 1))
            fi
        else
            # Last resort: check for obvious issues (unmatched quotes, bad indentation)
            if echo "$extracted" | grep -qE '^[^#]*"[^"]*$'; then
                echo "[TIER-1] $file — possible unclosed quote in frontmatter" >&2
                errors=$((errors + 1))
            fi
        fi
    fi
done

if [[ $errors -gt 0 ]]; then
    exit 1
fi
exit 0
