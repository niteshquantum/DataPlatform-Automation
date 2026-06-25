bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/install_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/validate_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_java_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_tools.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/start_mysql.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/validate_mysql.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/create_database.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/run_liquibase.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/setup/validate_environment.sh"