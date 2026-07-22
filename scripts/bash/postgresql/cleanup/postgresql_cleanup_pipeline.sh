#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "POSTGRESQL CLEANUP PIPELINE"
echo "====================================="
echo

CLEANUP_MODE="${CLEANUP_MODE:-PRESERVE_DATA}"
CLEANUP_MODE="$(echo "$CLEANUP_MODE" | tr '[:lower:]' '[:upper:]')"

export CLEANUP_MODE

if [[ "$CLEANUP_MODE" != "PRESERVE_DATA" && \
      "$CLEANUP_MODE" != "DELETE_DATA" ]]
then
    echo "ERROR: Invalid CLEANUP_MODE: $CLEANUP_MODE"
    echo
    echo "Valid cleanup modes:"
    echo "  PRESERVE_DATA"
    echo "  DELETE_DATA"
    exit 1
fi

echo "Project Root : $PROJECT_ROOT"
echo "Cleanup Mode : $CLEANUP_MODE"
echo

STOP_SCRIPT="$PROJECT_ROOT/scripts/bash/postgresql/cleanup/stop_postgresql.sh"

REMOVE_SCRIPT="$PROJECT_ROOT/scripts/bash/postgresql/cleanup/remove_postgresql.sh"

RESET_TERRAFORM_SCRIPT="$PROJECT_ROOT/scripts/bash/postgresql/cleanup/reset_terraform_state.sh"

XML_CLEANUP_SCRIPT="$PROJECT_ROOT/scripts/bash/postgresql/cleanup/cleanup_postgresql_xml.sh"

LOAD_ARTIFACTS_SCRIPT="$PROJECT_ROOT/scripts/bash/postgresql/cleanup/cleanup_postgresql_load_artifacts.sh"

VALIDATE_SCRIPT="$PROJECT_ROOT/scripts/bash/postgresql/cleanup/validate_cleanup.sh"

echo "====================================="
echo "VALIDATING CLEANUP SCRIPTS"
echo "====================================="
echo

for SCRIPT in \
    "$STOP_SCRIPT" \
    "$REMOVE_SCRIPT" \
    "$RESET_TERRAFORM_SCRIPT" \
    "$XML_CLEANUP_SCRIPT" \
    "$LOAD_ARTIFACTS_SCRIPT" \
    "$VALIDATE_SCRIPT"
do

    if [ ! -f "$SCRIPT" ]
    then
        echo "ERROR: Cleanup script not found:"
        echo "$SCRIPT"
        exit 1
    fi

done

echo "All PostgreSQL cleanup scripts found successfully."
echo

echo "====================================="
echo "STEP 1 - STOP POSTGRESQL"
echo "====================================="
echo

bash "$STOP_SCRIPT"

echo
echo "PostgreSQL stop stage completed successfully."
echo

echo "====================================="
echo "STEP 2 - REMOVE POSTGRESQL DEPLOYMENT"
echo "====================================="
echo

bash "$REMOVE_SCRIPT"

echo
echo "PostgreSQL removal stage completed successfully."
echo

echo "====================================="
echo "STEP 3 - RESET TERRAFORM STATE"
echo "====================================="
echo

bash "$RESET_TERRAFORM_SCRIPT"

echo
echo "PostgreSQL Terraform reset stage completed successfully."
echo

echo "====================================="
echo "STEP 4 - CLEANUP LIQUIBASE XML"
echo "====================================="
echo

bash "$XML_CLEANUP_SCRIPT"

echo
echo "PostgreSQL Liquibase XML cleanup completed successfully."
echo

echo "====================================="
echo "STEP 5 - CLEANUP LOAD ARTIFACTS"
echo "====================================="
echo

bash "$LOAD_ARTIFACTS_SCRIPT"

echo
echo "PostgreSQL load artifacts cleanup completed successfully."
echo

echo "====================================="
echo "STEP 6 - VALIDATE CLEANUP"
echo "====================================="
echo

bash "$VALIDATE_SCRIPT"

echo
echo "PostgreSQL cleanup validation completed successfully."
echo

echo
echo "====================================="
echo "POSTGRESQL CLEANUP PIPELINE COMPLETED"
echo "====================================="
echo

echo "Project Root : $PROJECT_ROOT"
echo "Cleanup Mode : $CLEANUP_MODE"
echo "Status       : SUCCESS"
echo

exit 0
