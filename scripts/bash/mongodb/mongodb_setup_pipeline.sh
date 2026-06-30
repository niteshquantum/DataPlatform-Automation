#!/bin/bash

set -e

PROJECT_ROOT=$(pwd)

bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/validate_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/common/validate_java_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_tools.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/install_mongodb.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/install_mongosh.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/start_mongodb.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/setup/validate_mongodb.sh"

echo
echo "====================================="
echo "MONGODB SETUP SUCCESSFUL"
echo "====================================="
echo
