#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "MYSQL CLEANUP PIPELINE"
echo "====================================="
echo

# =====================================
# CLEANUP MODE
# =====================================

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

# =====================================
# CLEANUP SCRIPT PATHS
# =====================================

STOP_SCRIPT="$PROJECT_ROOT/scripts/bash/mysql/cleanup/stop_mysql.sh"

REMOVE_SCRIPT="$PROJECT_ROOT/scripts/bash/mysql/cleanup/remove_mysql.sh"

RESET_TERRAFORM_SCRIPT="$PROJECT_ROOT/scripts/bash/mysql/cleanup/reset_terraform_state.sh"

XML_CLEANUP_SCRIPT="$PROJECT_ROOT/scripts/bash/mysql/cleanup/cleanup_mysql_xml.sh"

LOAD_ARTIFACTS_SCRIPT="$PROJECT_ROOT/scripts/bash/mysql/cleanup/cleanup_mysql_load_artifacts.sh"

VALIDATE_SCRIPT="$PROJECT_ROOT/scripts/bash/mysql/cleanup/validate_cleanup.sh"

# =====================================
# VALIDATE CLEANUP SCRIPTS
# =====================================

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

echo "All MySQL cleanup scripts found successfully."
echo

# =====================================
# STEP 1 - STOP MYSQL
# =====================================

echo "====================================="
echo "STEP 1 - STOP MYSQL"
echo "====================================="
echo

bash "$STOP_SCRIPT"

echo
echo "MySQL stop stage completed successfully."
echo

# =====================================
# STEP 2 - REMOVE MYSQL
# =====================================

echo "====================================="
echo "STEP 2 - REMOVE MYSQL DEPLOYMENT"
echo "====================================="
echo

bash "$REMOVE_SCRIPT"

echo
echo "MySQL removal stage completed successfully."
echo

# =====================================
# STEP 3 - RESET TERRAFORM STATE
# =====================================

echo "====================================="
echo "STEP 3 - RESET TERRAFORM STATE"
echo "====================================="
echo

bash "$RESET_TERRAFORM_SCRIPT"

echo
echo "MySQL Terraform reset stage completed successfully."
echo

# =====================================
# STEP 4 - CLEANUP LIQUIBASE XML
# =====================================

echo "====================================="
echo "STEP 4 - CLEANUP LIQUIBASE XML"
echo "====================================="
echo

bash "$XML_CLEANUP_SCRIPT"

echo
echo "MySQL Liquibase XML cleanup completed successfully."
echo

# =====================================
# STEP 5 - CLEANUP LOAD ARTIFACTS
# =====================================

echo "====================================="
echo "STEP 5 - CLEANUP LOAD ARTIFACTS"
echo "====================================="
echo

bash "$LOAD_ARTIFACTS_SCRIPT"

echo
echo "MySQL load artifacts cleanup completed successfully."
echo

# =====================================
# STEP 6 - VALIDATE CLEANUP
# =====================================

echo "====================================="
echo "STEP 6 - VALIDATE CLEANUP"
echo "====================================="
echo

bash "$VALIDATE_SCRIPT"

echo
echo "MySQL cleanup validation completed successfully."
echo

# =====================================
# SUCCESS
# =====================================

echo
echo "====================================="
echo "MYSQL CLEANUP PIPELINE COMPLETED"
echo "====================================="
echo

echo "Project Root : $PROJECT_ROOT"
echo "Cleanup Mode : $CLEANUP_MODE"
echo "Status       : SUCCESS"
echo

exit 0