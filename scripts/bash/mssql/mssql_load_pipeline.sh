#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/validate_tools.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/validate_mssql.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/load_data.sh"

bash "$PROJECT_ROOT/scripts/bash/mssql/validate_loaded_data.sh"