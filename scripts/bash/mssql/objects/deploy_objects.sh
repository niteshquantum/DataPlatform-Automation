#!/bin/bash
set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

cd "$PROJECT_ROOT"

export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"

echo "====================================="
echo "MSSQL OBJECTS DEPLOYMENT"
echo "====================================="

echo "----------------------------------------"
echo "Generating Liquibase Objects : mssql"
echo "----------------------------------------"

python3 scripts/python/common/objects/generate_liquibase_objects.py mssql

python3 scripts/python/common/objects/generate_master_objects.py mssql

python3 scripts/python/common/objects/deploy_objects.py mssql

echo "====================================="
echo "MSSQL OBJECTS DEPLOYMENT SUCCESSFUL"
echo "====================================="