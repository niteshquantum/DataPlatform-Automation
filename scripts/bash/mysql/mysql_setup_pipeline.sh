#!/bin/bash

set -e

PROJECT_ROOT=$(pwd)

bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"
bash "$PROJECT_ROOT/scripts/bash/common/validate_java_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/install_python_requirements.sh"
bash "$PROJECT_ROOT/scripts/bash/mysql/setup/validate_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_terraform.sh"
bash "$PROJECT_ROOT/scripts/bash/common/install_liquibase.sh"
bash "$PROJECT_ROOT/scripts/bash/common/install_mysql_driver.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_tools.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/install_mysql.sh"
bash "$PROJECT_ROOT/scripts/bash/mysql/setup/start_mysql.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/create_database.sh"
bash "$PROJECT_ROOT/scripts/bash/mysql/setup/run_liquibase.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/validate_environment.sh"

echo
echo "====================================="
echo "MYSQL SETUP SUCCESSFUL"
echo "====================================="
echo