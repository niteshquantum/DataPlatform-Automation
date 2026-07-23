#!/bin/bash
set -euo pipefail
source "$(dirname "$0")/../../common/set_project_root.sh"
python3 "$PROJECT_ROOT/scripts/python/mssql/rbac/rbac.py" configure
