#!/bin/bash

set -e

PROJECT_ROOT=$(pwd)

bash "$PROJECT_ROOT/scripts/bash/mysql/load_data.sh"

bash "$PROJECT_ROOT/scripts/bash/mysql/validate_loaded_data.sh"

echo
echo "====================================="
echo "MYSQL DATA LOAD SUCCESSFUL"
echo "====================================="
echo