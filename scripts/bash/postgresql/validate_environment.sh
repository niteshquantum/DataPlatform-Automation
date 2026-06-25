#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "============================================"
echo "ENVIRONMENT VALIDATION"
echo "============================================"
echo

echo "--- Python3 ---"
if ! command -v python3 >/dev/null 2>&1; then
    echo "FAIL: python3 not found"
    exit 1
fi
python3 --version

echo
echo "--- Java ---"
if ! command -v java >/dev/null 2>&1; then
    echo "FAIL: java not found"
    exit 1
fi
java -version

echo
echo "--- pip ---"
if ! python3 -m pip --version >/dev/null 2>&1; then
    echo "FAIL: pip not found"
    exit 1
fi
python3 -m pip --version

echo
echo "--- PostgreSQL Client (project folder) ---"
PG_BIN="$PROJECT_ROOT/databases/postgresql/bin"
if [ -f "$PG_BIN/psql" ]; then
    export LD_LIBRARY_PATH="$PROJECT_ROOT/databases/postgresql/lib:$LD_LIBRARY_PATH"
    "$PG_BIN/psql" --version
    echo "PostgreSQL client found in project folder"
else
    echo "WARN: psql not in project folder - run setup pipeline first"
fi

echo
echo "============================================"
echo "ENVIRONMENT VALIDATION COMPLETED"
echo "============================================"
echo

exit 0