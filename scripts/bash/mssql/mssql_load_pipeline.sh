#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

cd "$PROJECT_ROOT"

echo
echo "====================================="
echo "MSSQL AUTOMATION PIPELINE"
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

# 6. Validate Tools
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/validate_tools.sh"

# 7. Start MSSQL Server
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/start_mssql.sh"

# 8. Validate MSSQL Server
bash "$PROJECT_ROOT/scripts/bash/mssql/setup/validate_mssql.sh"

# 9. Download Dataset
bash "$PROJECT_ROOT/scripts/bash/common/download_dataset.sh"

# 10. Load Data
bash "$PROJECT_ROOT/scripts/bash/mssql/load/load_data.sh"

# 11. Validate Loaded Data
bash "$PROJECT_ROOT/scripts/bash/mssql/load/validate_loaded_data.sh"

# 12. Deploy Database Objects (generate + Liquibase deploy)
bash "$PROJECT_ROOT/scripts/bash/mssql/objects/deploy_objects.sh"

# 13. Validate Database Objects
bash "$PROJECT_ROOT/scripts/bash/mssql/objects/validate_objects.sh"

# 14. Database Assessment
bash "$PROJECT_ROOT/scripts/bash/mssql/assessment/run_assessment.sh" all

# 15. Generate Assessment Report
bash "$PROJECT_ROOT/scripts/bash/common/generate_assessment_report.sh"

echo
echo "====================================="
echo "MSSQL AUTOMATION PIPELINE COMPLETED"
echo "====================================="
echo

exit 0