#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

cd "$PROJECT_ROOT"

echo
echo "====================================="
echo "MYSQL AUTOMATION PIPELINE"
echo "====================================="
echo

# 1. Validate Python Runtime
bash "$PROJECT_ROOT/scripts/bash/common/validate_python_runtime.sh"

# 2. Install Python Requirements
bash "$PROJECT_ROOT/scripts/bash/mysql/setup/install_python_requirements.sh"

# 3. Validate Python Requirements
bash "$PROJECT_ROOT/scripts/bash/mysql/setup/validate_python_requirements.sh"

# 4. Validate Tools
bash "$PROJECT_ROOT/scripts/bash/common/validate_tools.sh"

# 5. Start MySQL
bash "$PROJECT_ROOT/scripts/bash/mysql/setup/start_mysql.sh"

# 6. Validate MySQL
bash "$PROJECT_ROOT/scripts/bash/mysql/setup/validate_mysql.sh"

# 7. Validate CSV
bash "$PROJECT_ROOT/scripts/bash/mysql/load/validate_csv.sh"

# 8. Load Data
bash "$PROJECT_ROOT/scripts/bash/mysql/load/load_data.sh"

# 9. Validate Loaded Data
bash "$PROJECT_ROOT/scripts/bash/mysql/load/validate_loaded_data.sh"

# 10. Deploy Database Objects (generate + Liquibase deploy)
bash "$PROJECT_ROOT/scripts/bash/mysql/objects/deploy_objects.sh"

# 11. Validate Database Objects
bash "$PROJECT_ROOT/scripts/bash/mysql/objects/validate_objects.sh"

# 12. Database Assessment
bash "$PROJECT_ROOT/scripts/bash/mysql/assessment/run_assessment.sh" all

# 13. Generate Assessment Report
bash "$PROJECT_ROOT/scripts/bash/common/generate_assessment_report.sh"

echo
echo "====================================="
echo "MYSQL AUTOMATION PIPELINE COMPLETED"
echo "====================================="
echo

exit 0