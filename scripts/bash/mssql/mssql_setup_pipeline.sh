#!/bin/bash

# Ensure script stops on unexpected errors
set -e

# Resolve project root dynamically
source "$(dirname "$0")/../../common/set_project_root.sh"

echo "====================================="
echo "STARTING LOCAL MSSQL SETUP PIPELINE"
echo "====================================="

# 1. Validate Python Runtime
bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

# 2. Install Python Requirements
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/install_python_requirements.sh"

# 3. Validate Python Requirements
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/validate_python_requirements.sh"

# 4. Validate Java Runtime
bash "$PROJECT_ROOT/scripts/bash/common/validate_java_runtime.sh"

# 5. Install Tools
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/install_tools.sh"

echo
echo "====================================="
echo "INITIAL SETUP SCOPE SUCCESSFUL"
echo "====================================="
echo "Stopping here before 'Deploy SQL Server' stage."
echo "====================================="

exit 0
