#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/install_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/validate_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/start_mongodb.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/validate_mongodb.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/load/load_data.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/load/validate_loaded_data.sh"

echo
echo "====================================="
echo "MONGODB LOAD SUCCESSFUL"
echo "====================================="
echo