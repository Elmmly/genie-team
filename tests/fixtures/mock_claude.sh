#!/bin/bash
# Mock claude CLI for genies tests
# Reads MOCK_CLAUDE_RESPONSES_DIR env var to find per-phase JSON responses
# Detects phase from the -p argument content

MOCK_RESPONSES_DIR="${MOCK_CLAUDE_RESPONSES_DIR:-}"
MOCK_INVOCATION_LOG="${MOCK_INVOCATION_LOG:-/dev/null}"

if [[ -z "$MOCK_RESPONSES_DIR" ]]; then
    echo '{"type":"result","result":"mock error: MOCK_CLAUDE_RESPONSES_DIR not set"}' >&2
    exit 1
fi

# Parse arguments to detect phase and capture flags
phase=""
max_turns=""
prompt_text=""
resume_id=""

while [[ $# -gt 0 ]]; do
    case "$1" in
        -p)              prompt_text="$2"; shift 2 ;;
        --output-format) shift 2 ;;
        --max-turns)     max_turns="$2"; shift 2 ;;
        --resume)        resume_id="$2"; shift 2 ;;
        --allowedTools)  shift 2 ;;
        *)               shift ;;
    esac
done

# Phase list with "done" quoted to avoid shell keyword conflict
MOCK_PHASES=(discover define design deliver discern commit "done")

# Detect phase from prompt text
for p in "${MOCK_PHASES[@]}"; do
    if echo "$prompt_text" | grep -qi "/$p\b"; then
        phase="$p"
        break
    fi
done

# Fallback: check for phase name as keyword
if [[ -z "$phase" ]]; then
    for p in "${MOCK_PHASES[@]}"; do
        if echo "$prompt_text" | grep -qi "$p"; then
            phase="$p"
            break
        fi
    done
fi

# Log invocation for test verification
echo "phase=$phase max_turns=$max_turns resume=$resume_id prompt=$prompt_text" >> "$MOCK_INVOCATION_LOG"

# Check for simulated failure
if [[ -f "$MOCK_RESPONSES_DIR/${phase}_fail" ]]; then
    exit 1
fi

# Check for simulated turn exhaustion
if [[ -f "$MOCK_RESPONSES_DIR/${phase}_exhaust" ]]; then
    # On first call (no resume), simulate exhaustion exit
    if [[ -z "$resume_id" ]]; then
        # Return partial output that indicates exhaustion
        if [[ -f "$MOCK_RESPONSES_DIR/${phase}_exhaust.json" ]]; then
            cat "$MOCK_RESPONSES_DIR/${phase}_exhaust.json"
        fi
        exit 2
    fi
    # On resume (retry), check for double exhaustion
    if [[ -f "$MOCK_RESPONSES_DIR/${phase}_double_exhaust" ]]; then
        exit 2
    fi
fi

# Find response file
response_file="$MOCK_RESPONSES_DIR/${phase}.json"
if [[ ! -f "$response_file" ]]; then
    echo '{"type":"result","result":"mock error: no response for phase '"$phase"'","session_id":"mock-session-001"}'
    exit 0
fi

cat "$response_file"
exit 0
