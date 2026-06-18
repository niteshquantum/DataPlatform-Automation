#!/bin/bash

set -e

source "$(dirname "$0")/set_project_root.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_terraform.sh"
bash "$PROJECT_ROOT/scripts/bash/common/install_liquibase.sh"
bash "$PROJECT_ROOT/scripts/bash/common/install_mysql_driver.sh"

echo
echo "====================================="
echo "TOOLS INSTALLED SUCCESSFULLY"
echo "====================================="
echo

exit 0