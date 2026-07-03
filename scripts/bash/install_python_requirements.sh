#!/bin/bash

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING PYTHON REQUIREMENTS"
echo "====================================="
echo

python3 -m pip install --upgrade pip

python3 -m pip install -r "$PROJECT_ROOT/requirements.txt"

echo
echo "====================================="
echo "PYTHON REQUIREMENTS INSTALLED"
echo "====================================="
echo

exit 0