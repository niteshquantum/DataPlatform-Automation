#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "STARTING LOCAL MSSQL LOAD PIPELINE"
echo "====================================="
echo

# 1. Validate Python Runtime
bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

# 2. Install Python Requirements
bash "$PROJECT_ROOT/scripts/bash/mssql/load/install_python_requirements.sh"

# 3. Validate Python Requirements
bash "$PROJECT_ROOT/scripts/bash/mssql/load/validate_python_requirements.sh"

# 4. Install Tools
bash "$PROJECT_ROOT/scripts/bash/mssql/load/install_tools.sh"

# 5. Validate Tools
bash "$PROJECT_ROOT/scripts/bash/mssql/load/validate_tools.sh"

# 6. Validate SQL Server
bash "$PROJECT_ROOT/scripts/bash/mssql/load/validate_mssql.sh"

# 7. Download Dataset
bash "$PROJECT_ROOT/scripts/bash/common/download_dataset.sh"

# 8. Load Data
bash "$PROJECT_ROOT/scripts/bash/mssql/load/load_data.sh"

# 9. Validate Loaded Data
bash "$PROJECT_ROOT/scripts/bash/mssql/load/validate_loaded_data.sh"

echo
echo "====================================="
echo "LOCAL MSSQL LOAD PIPELINE COMPLETED"
echo "====================================="
echo

exit 0