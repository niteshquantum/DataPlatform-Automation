#!/bin/bash

set -e

PROJECT_ROOT=$(pwd)

bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

bash "$PROJECT_ROOT/scripts/bash/common/install_python_requirements.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/install_mongodb.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/install_mongosh.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/start_mongodb.sh"

bash "$PROJECT_ROOT/scripts/bash/mongodb/validate_mongodb.sh"

echo
echo "====================================="
echo "MONGODB SETUP SUCCESSFUL"
echo "====================================="
echo