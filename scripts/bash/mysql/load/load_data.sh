#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "MYSQL DATA LOAD"
echo "====================================="
echo

cd "$PROJECT_ROOT"

echo
echo "-------------------------------------"
echo "DETECTING SCHEMA"
echo "-------------------------------------"
echo

python3 scripts/schema_detector.py mysql

echo
echo "-------------------------------------"
echo "GENERATING LIQUIBASE XML"
echo "-------------------------------------"
echo

python3 -m scripts.python.mysql.setup.generate_liquibase_xml

echo
echo "-------------------------------------"
echo "UPDATING MASTER XML"
echo "-------------------------------------"
echo

python3 -m scripts.python.mysql.setup.update_master_xml

echo
echo "-------------------------------------"
echo "RUNNING LIQUIBASE"
echo "-------------------------------------"
echo

bash scripts/bash/mysql/setup/run_liquibase.sh

echo
echo "-------------------------------------"
echo "LOADING DATA"
echo "-------------------------------------"
echo

python3 -m scripts.python.mysql.load.load_data

echo
echo "-------------------------------------"
echo "VALIDATING DATA"
echo "-------------------------------------"
echo

cd "$PROJECT_ROOT"

python3 -m scripts.python.mysql.load.validate_data

echo
echo "====================================="
echo "DATA LOAD SUCCESSFUL"
echo "====================================="
echo

exit 0