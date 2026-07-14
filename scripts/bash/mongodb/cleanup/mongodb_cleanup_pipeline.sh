#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "MONGODB CLEANUP PIPELINE"
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

STOP_SCRIPT="$PROJECT_ROOT/scripts/bash/mongodb/cleanup/stop_mongodb.sh"

REMOVE_SCRIPT="$PROJECT_ROOT/scripts/bash/mongodb/cleanup/remove_mongodb.sh"

RESET_TERRAFORM_SCRIPT="$PROJECT_ROOT/scripts/bash/mongodb/cleanup/reset_terraform_state.sh"

LOAD_ARTIFACTS_SCRIPT="$PROJECT_ROOT/scripts/bash/mongodb/cleanup/cleanup_mongodb_load_artifacts.sh"

VALIDATE_SCRIPT="$PROJECT_ROOT/scripts/bash/mongodb/cleanup/validate_cleanup.sh"

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

echo "All MongoDB cleanup scripts found successfully."
echo

# =====================================
# STEP 1 - STOP MONGODB
# =====================================

echo "====================================="
echo "STEP 1 - STOP MONGODB"
echo "====================================="
echo

bash "$STOP_SCRIPT"

echo
echo "MongoDB stop stage completed successfully."
echo

# =====================================
# STEP 2 - REMOVE MONGODB DEPLOYMENT
# =====================================

echo "====================================="
echo "STEP 2 - REMOVE MONGODB DEPLOYMENT"
echo "====================================="
echo

bash "$REMOVE_SCRIPT"

echo
echo "MongoDB removal stage completed successfully."
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
echo "MongoDB Terraform reset stage completed successfully."
echo

# =====================================
# STEP 4 - CLEANUP LOAD ARTIFACTS
# =====================================

echo "====================================="
echo "STEP 4 - CLEANUP LOAD ARTIFACTS"
echo "====================================="
echo

bash "$LOAD_ARTIFACTS_SCRIPT"

echo
echo "MongoDB load artifacts cleanup completed successfully."
echo

# =====================================
# STEP 5 - VALIDATE CLEANUP
# =====================================

echo "====================================="
echo "STEP 5 - VALIDATE CLEANUP"
echo "====================================="
echo

bash "$VALIDATE_SCRIPT"

echo
echo "MongoDB cleanup validation completed successfully."
echo

# =====================================
# SUCCESS
# =====================================

echo
echo "====================================="
echo "MONGODB CLEANUP PIPELINE COMPLETED"
echo "====================================="
echo

echo "Project Root : $PROJECT_ROOT"
echo "Cleanup Mode : $CLEANUP_MODE"
echo "Status       : SUCCESS"
echo

exit 0