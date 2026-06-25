#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "LOADING DATA"
echo "====================================="
echo

PG_BIN="$PROJECT_ROOT/databases/postgresql/bin"

export LD_LIBRARY_PATH="$PROJECT_ROOT/databases/postgresql/lib:$LD_LIBRARY_PATH"
export PATH="$PG_BIN:$PATH"

python3 \
"${PROJECT_ROOT}/scripts/python/postgresql/load_all.py"

echo
echo "====================================="
echo "DATA LOAD SUCCESSFUL"
echo "====================================="
echo

exit 0