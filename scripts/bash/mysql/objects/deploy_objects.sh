#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

cd "$PROJECT_ROOT"

export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"

echo
echo "====================================="
echo "MYSQL OBJECTS DEPLOYMENT"
echo "====================================="
echo

# Generate Liquibase object XMLs
python3 scripts/python/common/objects/generate_liquibase_objects.py mysql

# Generate master_objects.xml
python3 scripts/python/common/objects/generate_master_objects.py mysql

# Deploy objects
python3 scripts/python/common/objects/deploy_objects.py mysql

echo
echo "====================================="
echo "MYSQL OBJECTS DEPLOYMENT SUCCESSFUL"
echo "====================================="
echo

exit 0
