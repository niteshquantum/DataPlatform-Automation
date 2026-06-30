#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "VALIDATING LOADED DATA"
echo "====================================="
echo

export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"

cd "$PROJECT_ROOT"

python3 scripts/python/mongodb/load/validate_loaded_data.py

echo
echo "LOADED DATA VALIDATION SUCCESSFUL"
echo
echo "====================================="
echo