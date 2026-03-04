#!/bin/bash
# Hook: PostToolUse (Write|Edit) — run language-specific verification
# Matches file extension to verification command and outputs results.
# Non-blocking (exit 0 always) — outputs verification results for Claude
# to read and self-correct.
# Zero LLM cost — pure shell operations.

set -uo pipefail

input=$(cat)
tool_name=$(echo "$input" | jq -r '.tool_name // empty')
file_path=$(echo "$input" | jq -r '.tool_input.file_path // empty')
cwd=$(echo "$input" | jq -r '.cwd // empty')

# Only run for Write and Edit tools
if [[ "$tool_name" != "Write" && "$tool_name" != "Edit" ]]; then
    exit 0
fi

# Skip empty file paths
if [[ -z "$file_path" ]]; then
    exit 0
fi

# Extract file extension
ext="${file_path##*.}"

# Change to project directory for tool commands
cd "$cwd" 2>/dev/null || exit 0

# Match extension to verification command
case "$ext" in
    go)
        if command -v go &>/dev/null; then
            output=$(go vet ./... 2>&1) || true
            if [[ -n "$output" ]]; then
                echo "--- Stack Verification (go vet) ---"
                echo "$output" | head -20
                echo "---"
            fi
        fi
        ;;
    ts|tsx)
        if command -v npx &>/dev/null && [[ -f "tsconfig.json" ]]; then
            output=$(npx tsc --noEmit 2>&1) || true
            if [[ -n "$output" ]]; then
                echo "--- Stack Verification (tsc --noEmit) ---"
                echo "$output" | head -20
                echo "---"
            fi
        fi
        ;;
    rs)
        if command -v cargo &>/dev/null && [[ -f "Cargo.toml" ]]; then
            output=$(cargo check --message-format=short 2>&1) || true
            # Only show errors/warnings, not the "Compiling" lines
            filtered=$(echo "$output" | grep -E "^(error|warning)" | head -20)
            if [[ -n "$filtered" ]]; then
                echo "--- Stack Verification (cargo check) ---"
                echo "$filtered"
                echo "---"
            fi
        fi
        ;;
    cs)
        if command -v dotnet &>/dev/null; then
            output=$(dotnet build --no-restore --verbosity quiet 2>&1) || true
            filtered=$(echo "$output" | grep -E "(error|warning) " | head -20)
            if [[ -n "$filtered" ]]; then
                echo "--- Stack Verification (dotnet build) ---"
                echo "$filtered"
                echo "---"
            fi
        fi
        ;;
    java)
        if [[ -f "pom.xml" ]] && command -v mvn &>/dev/null; then
            output=$(mvn compile -q 2>&1) || true
            if [[ -n "$output" ]]; then
                echo "--- Stack Verification (mvn compile) ---"
                echo "$output" | head -20
                echo "---"
            fi
        elif [[ -f "build.gradle" || -f "build.gradle.kts" ]] && command -v gradle &>/dev/null; then
            output=$(gradle compileJava -q 2>&1) || true
            if [[ -n "$output" ]]; then
                echo "--- Stack Verification (gradle compileJava) ---"
                echo "$output" | head -20
                echo "---"
            fi
        fi
        ;;
    swift)
        if command -v swift &>/dev/null && [[ -f "Package.swift" ]]; then
            output=$(swift build 2>&1) || true
            filtered=$(echo "$output" | grep -E "error:|warning:" | head -20)
            if [[ -n "$filtered" ]]; then
                echo "--- Stack Verification (swift build) ---"
                echo "$filtered"
                echo "---"
            fi
        elif command -v xcodebuild &>/dev/null; then
            output=$(xcodebuild build -quiet 2>&1) || true
            filtered=$(echo "$output" | grep -E "error:|warning:" | head -20)
            if [[ -n "$filtered" ]]; then
                echo "--- Stack Verification (xcodebuild) ---"
                echo "$filtered"
                echo "---"
            fi
        fi
        ;;
    kt|kts)
        if [[ -f "gradlew" ]] || [[ -f "build.gradle.kts" ]] || [[ -f "build.gradle" ]]; then
            gradlew="gradle"
            [[ -f "./gradlew" ]] && gradlew="./gradlew"
            output=$($gradlew compileDebugKotlin -q 2>&1) || true
            filtered=$(echo "$output" | grep -E "^e:|^w:" | head -20)
            if [[ -n "$filtered" ]]; then
                echo "--- Stack Verification (gradle compileDebugKotlin) ---"
                echo "$filtered"
                echo "---"
            fi
        fi
        ;;
    ex|exs)
        if [[ -f "mix.exs" ]] && command -v mix &>/dev/null; then
            output=$(mix compile --warnings-as-errors 2>&1) || true
            filtered=$(echo "$output" | grep -E "^warning:|^\*\* \(|^== Compilation error" | head -20)
            if [[ -n "$filtered" ]]; then
                echo "--- Stack Verification (mix compile) ---"
                echo "$filtered"
                echo "---"
            fi
        fi
        ;;
esac

# Always exit 0 — verification is advisory, not blocking
exit 0
