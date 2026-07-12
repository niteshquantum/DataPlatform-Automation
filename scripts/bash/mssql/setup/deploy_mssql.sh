#!/bin/bash

set -e

# =====================================
# ROOT PATH
# =====================================
source "$(dirname "$0")/../../common/set_project_root.sh"
ROOT="$PROJECT_ROOT"

# =====================================
# TERRAFORM PATH
# =====================================
TF="$ROOT/tools/terraform/terraform"

# =====================================
# CHECK TERRAFORM
# =====================================
if [ ! -f "$TF" ]; then
    echo "Terraform is not installed."
    echo "Run install_tools.sh first."
    exit 1
fi

# =====================================
# GO TO MSSQL TERRAFORM
# =====================================
cd "$ROOT/terraform/mssql"

echo
echo "====================================="
echo "TERRAFORM INIT"
echo "====================================="
echo

"$TF" init

echo
echo "====================================="
echo "TERRAFORM APPLY"
echo "====================================="
echo

"$TF" apply \
-target=null_resource.install_mssql_linux \
-target=null_resource.start_mssql_linux \
-auto-approve

echo
echo "====================================="
echo "TERRAFORM APPLY COMPLETE"
echo "====================================="
echo

exit 0
