#!/bin/bash

set -e

source "$(dirname "$0")/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING PYTHON REQUIREMENTS"
echo "====================================="
echo

if ! python3 -m pip --version >/dev/null 2>&1
then

    echo "pip not found"

    sudo apt-get update

    sudo apt-get install -y python3-pip

fi

python3 -m pip install --upgrade pip

python3 -m pip install -r "$PROJECT_ROOT/requirements.txt"

echo
echo "====================================="
echo "PYTHON REQUIREMENTS INSTALLED"
echo "====================================="
echo

exit 0