#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

echo "=================================="
echo "POSTGRESQL DEPLOYMENT"
echo "=================================="

bash "${SCRIPT_DIR}/install_postgresql.sh"

bash "${SCRIPT_DIR}/start_postgresql.sh"

bash "${SCRIPT_DIR}/create_database.sh"

bash "${SCRIPT_DIR}/run_liquibase.sh"

bash "${SCRIPT_DIR}/validate_postgresql.sh"

echo "Deployment completed successfully"