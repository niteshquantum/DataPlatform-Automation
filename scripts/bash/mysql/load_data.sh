#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "MYSQL DATA LOAD"
echo "====================================="
echo

cd "$PROJECT_ROOT"

python3 scripts/python/mysql/load_all.py

echo
echo "DATA LOAD SUCCESSFUL"
echo

exit 0