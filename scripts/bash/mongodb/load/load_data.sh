#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "LOADING MONGODB DATA"
echo "====================================="
echo

python3 "$PROJECT_ROOT/scripts/python/mongodb/load_all.py"

echo
echo "====================================="
echo "MONGODB DATA LOAD SUCCESSFUL"
echo "====================================="
echo

exit 0