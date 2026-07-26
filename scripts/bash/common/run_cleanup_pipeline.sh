#!/bin/bash
set -euo pipefail

CLEANUP_MODE="${1:-}"
DATABASE="${2:-}"

if [[ -z "$CLEANUP_MODE" ]]; then
    echo "[ERROR] Missing required argument: cleanupMode" >&2
    exit 1
fi

if [[ -z "$DATABASE" ]]; then
    echo "[ERROR] Missing required argument: database" >&2
    exit 1
fi

case "$CLEANUP_MODE" in
    full|partial|dryrun)
        ;;
    *)
        echo "[ERROR] Invalid cleanup mode: $CLEANUP_MODE. Allowed: full, partial, dryrun" >&2
        exit 1
        ;;
esac

echo "[INFO] Common cleanup runner invoked"
echo "[INFO] Cleanup mode: $CLEANUP_MODE"
echo "[INFO] Database: $DATABASE"
echo "[INFO] Operating system: Linux"

exit 0
