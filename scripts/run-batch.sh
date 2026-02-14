#!/bin/bash
# Backwards-compatible wrapper — delegates to run-pdlc.sh
#
# run-batch.sh is now a thin wrapper. All batch execution logic lives in
# run-pdlc.sh. See: run-pdlc.sh --help
#
# Existing invocations continue to work:
#   run-batch.sh deliver [OPTIONS]       → run-pdlc.sh [OPTIONS]
#   run-batch.sh discover [OPTIONS]      → run-pdlc.sh --through define [OPTIONS]
#   run-batch.sh [OPTIONS]               → run-pdlc.sh [OPTIONS]

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

case "${1:-}" in
    deliver)
        shift
        exec "$SCRIPT_DIR/run-pdlc.sh" "$@"
        ;;
    discover)
        shift
        exec "$SCRIPT_DIR/run-pdlc.sh" --through define "$@"
        ;;
    help|-h|--help)
        echo "run-batch.sh is now a wrapper for run-pdlc.sh." >&2
        echo "See: run-pdlc.sh --help" >&2
        exec "$SCRIPT_DIR/run-pdlc.sh" --help
        ;;
    *)
        exec "$SCRIPT_DIR/run-pdlc.sh" "$@"
        ;;
esac
