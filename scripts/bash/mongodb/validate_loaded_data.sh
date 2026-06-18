#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "VALIDATING LOADED DATA"
echo "====================================="
echo

python3 "$PROJECT_ROOT/scripts/python/mongodb/validate_data.py"

echo
echo "====================================="
echo "DATA VALIDATION SUCCESSFUL"
echo "====================================="
echo

exit 0