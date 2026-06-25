#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "VALIDATING POSTGRESQL"
echo "====================================="
echo

PG_BIN="$PROJECT_ROOT/databases/postgresql/bin"

if [ ! -f "$PG_BIN/psql" ]; then
    echo "ERROR: psql not found at: $PG_BIN/psql"
    echo "Run install_postgresql.sh first"
    exit 1
fi

export LD_LIBRARY_PATH="$PROJECT_ROOT/databases/postgresql/lib:$LD_LIBRARY_PATH"
export PATH="$PG_BIN:$PATH"

echo "psql path  : $PG_BIN/psql"
echo "psql version:"
"$PG_BIN/psql" --version

echo
echo "====================================="
echo "POSTGRESQL VALIDATION SUCCESSFUL"
echo "====================================="
echo

exit 0