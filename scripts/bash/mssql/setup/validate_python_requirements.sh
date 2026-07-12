#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "VALIDATING MSSQL PYTHON REQUIREMENTS"
echo "====================================="
echo

python3 --version

python3 -c "import yaml"
python3 -c "import dotenv"
python3 -c "import pyodbc"
python3 -c "import pandas"

echo
echo "====================================="
echo "MSSQL PYTHON REQUIREMENTS VALIDATED"
echo "====================================="
echo

exit 0
