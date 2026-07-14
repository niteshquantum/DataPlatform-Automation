#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/postgresql/setup/validate_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/postgresql/setup/start_postgresql.sh"

bash "$PROJECT_ROOT/scripts/bash/postgresql/setup/validate_postgresql.sh"

bash "$PROJECT_ROOT/scripts/bash/common/download_dataset.sh"

bash "$PROJECT_ROOT/scripts/bash/postgresql/load/load_data.sh"

bash "$PROJECT_ROOT/scripts/bash/postgresql/load/validate_loaded_data.sh"

echo
echo "====================================="
echo "POSTGRESQL LOAD SUCCESSFUL"
echo "====================================="
echo

exit 0
