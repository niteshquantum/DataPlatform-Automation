#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "VALIDATING TOOLS"
echo "====================================="
echo

# =====================================
# VALIDATE TERRAFORM
# =====================================

if [ ! -f "$PROJECT_ROOT/tools/terraform/terraform" ]
then
    echo "TERRAFORM NOT FOUND"
    exit 1
fi

echo "Checking Terraform..."
"$PROJECT_ROOT/tools/terraform/terraform" version

# =====================================
# VALIDATE LIQUIBASE
# =====================================

echo
echo "Checking Liquibase..."

if [ ! -f "$PROJECT_ROOT/tools/liquibase/liquibase" ]
then
    echo "LIQUIBASE NOT FOUND"
    exit 1
fi

"$PROJECT_ROOT/tools/liquibase/liquibase" --version

# =====================================
# VALIDATE POSTGRESQL JDBC DRIVER
# =====================================

echo
echo "Checking PostgreSQL Driver..."

bash "$PROJECT_ROOT/scripts/bash/postgresql/setup/validate_postgresql_driver.sh"

if [ $? -ne 0 ]
then
    exit 1
fi

echo
echo "====================================="
echo "TOOLS VALIDATED SUCCESSFULLY"
echo "====================================="
echo

exit 0