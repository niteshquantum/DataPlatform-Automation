#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

cd "$PROJECT_ROOT"

export PYTHONPATH="$PROJECT_ROOT:$PYTHONPATH"

echo
echo "====================================="
echo "MSSQL DATA LOAD"
echo "====================================="
echo

echo
echo "-------------------------------------"
echo "DETECTING SCHEMA"
echo "-------------------------------------"
echo

python3 scripts/schema_detector.py mssql

echo
echo "-------------------------------------"
echo "GENERATING LIQUIBASE XML"
echo "-------------------------------------"
echo

python3 scripts/python/mssql/setup/generate_liquibase_xml.py

echo
echo "-------------------------------------"
echo "UPDATING MASTER XML"
echo "-------------------------------------"
echo

rm -f "$PROJECT_ROOT/liquibase/mssql/master.xml"

python3 scripts/python/mssql/setup/update_master_xml.py

echo
echo "-------------------------------------"
echo "APPLYING LIQUIBASE CHANGELOG"
echo "-------------------------------------"
echo

bash "$PROJECT_ROOT/scripts/bash/mssql/setup/run_liquibase.sh"

echo
echo "-------------------------------------"
echo "LOADING DATA"
echo "-------------------------------------"
echo

echo "LOAD MODE : ${LOAD_MODE:-skip}"

export LOAD_MODE=${LOAD_MODE:-skip}

python3 scripts/data_loader.py mssql

echo
echo "-------------------------------------"
echo "VALIDATING DATA"
echo "-------------------------------------"
echo

python3 scripts/python/mssql/load/validate_data.py

echo
echo "====================================="
echo "DATA LOAD SUCCESSFUL"
echo "====================================="
echo

exit 0