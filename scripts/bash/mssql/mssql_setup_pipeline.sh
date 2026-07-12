#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "STARTING LOCAL MSSQL SETUP PIPELINE"
echo "====================================="
echo

# 1. Validate Python Runtime
bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

# 2. Install Python Requirements
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/install_python_requirements.sh"

# 3. Validate Python Requirements
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/validate_python_requirements.sh"

# 4. Validate Java Runtime
bash "$PROJECT_ROOT/scripts/bash/common/validate_java_runtime.sh"

# 5. Install Common Tools
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/install_tools.sh"

# 6. Deploy SQL Server
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/deploy_mssql.sh"

echo
echo "====================================="
echo "LOCAL MSSQL SETUP PIPELINE COMPLETED"
echo "====================================="
echo

exit 0