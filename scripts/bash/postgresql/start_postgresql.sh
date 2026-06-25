#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PG_BIN="$PROJECT_ROOT/databases/postgresql/bin"
PG_DATA="$PROJECT_ROOT/databases/postgresql/data"
PG_LOG="$PROJECT_ROOT/outputs/logs/postgresql.log"
PG_PORT=5432

export PATH="$PG_BIN:$PATH"
export LD_LIBRARY_PATH="$PROJECT_ROOT/databases/postgresql/lib:$LD_LIBRARY_PATH"

mkdir -p "$PROJECT_ROOT/outputs/logs"

# Already running check
if "$PG_BIN/pg_ctl" -D "$PG_DATA" status > /dev/null 2>&1; then
    echo "PostgreSQL already running from project folder"
    exit 0
fi

echo "Starting PostgreSQL from project folder..."

"$PG_BIN/pg_ctl" -D "$PG_DATA" \
    -l "$PG_LOG" \
    -o "-p $PG_PORT -k /tmp" \
    start

sleep 5

# Status check
"$PG_BIN/pg_ctl" -D "$PG_DATA" status

echo "PostgreSQL started successfully on port $PG_PORT"