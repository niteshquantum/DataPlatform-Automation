#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

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

python3 scripts/python/mysql/generate_liquibase_xml.py

echo
echo "-------------------------------------"
echo "UPDATING MASTER XML"
echo "-------------------------------------"
echo

rm -f "$PROJECT_ROOT/liquibase/mysql/master.xml"

python3 scripts/python/mysql/update_master_xml.py

echo
echo "-------------------------------------"
echo "RUNNING LIQUIBASE"
echo "-------------------------------------"
echo

bash scripts/bash/mysql/run_liquibase.sh

echo
echo "-------------------------------------"
echo "LOADING DATA"
echo "-------------------------------------"
echo
echo "LOAD MODE : ${LOAD_MODE:-skip}"
export LOAD_MODE=${LOAD_MODE}
python3 scripts/python/common/data_loader.py mysql

echo
echo "-------------------------------------"
echo "VALIDATING DATA"
echo "-------------------------------------"
echo

python3 scripts/python/mysql/validate_data.py

echo
echo "====================================="
echo "DATA LOAD SUCCESSFUL"
echo "====================================="
echo

exit 0
