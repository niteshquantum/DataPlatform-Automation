#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING MSSQL PYTHON REQUIREMENTS"
echo "====================================="
echo

python3 --version

python3 -m pip install --break-system-packages -r "$PROJECT_ROOT/requirements/mssql.txt"

echo
echo "====================================="
echo "MSSQL PYTHON REQUIREMENTS INSTALLED"
echo "====================================="
echo

exit 0
