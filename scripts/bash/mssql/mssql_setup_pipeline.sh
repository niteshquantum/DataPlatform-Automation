#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_java_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_terraform.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_liquibase.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_mssql_driver.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/validate_tools.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/install_mssql.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/install_sqlcmd.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/start_mssql.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/create_database.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/run_liquibase.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/validate_environment.sh"