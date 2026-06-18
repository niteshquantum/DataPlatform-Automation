#!/bin/bash

set -e

PROJECT_ROOT=$(pwd)

bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"
bash "$PROJECT_ROOT/scripts/bash/common/validate_java_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_terraform.sh"
bash "$PROJECT_ROOT/scripts/bash/common/install_liquibase.sh"
bash "$PROJECT_ROOT/scripts/bash/common/install_mysql_driver.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_tools.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/install_mysql.sh"
bash "$PROJECT_ROOT/scripts/bash/mysql/start_mysql.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/create_database.sh"
bash "$PROJECT_ROOT/scripts/bash/mysql/run_liquibase.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/validate_environment.sh"

echo
echo "====================================="
echo "MYSQL SETUP SUCCESSFUL"
echo "====================================="
echo