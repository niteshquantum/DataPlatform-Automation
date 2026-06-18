#!/bin/bash

set -e

PROJECT_ROOT=$(pwd)

bash "$PROJECT_ROOT/scripts/bash/common/install_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/load_data.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/validate_loaded_data.sh"

echo
echo "====================================="
echo "MONGODB LOAD SUCCESSFUL"
echo "====================================="
echo