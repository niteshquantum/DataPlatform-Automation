#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/postgresql.conf"

USER=$(grep "^POSTGRESQL_USER=" "$CONFIG_FILE" | cut -d'=' -f2)
PASSWORD=$(grep "^POSTGRESQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)

echo
echo "====================================="
echo "CONFIGURING POSTGRESQL USER"
echo "====================================="
echo

sudo -u postgres psql <<EOF
ALTER USER $USER WITH PASSWORD '$PASSWORD';
EOF

echo
echo "PostgreSQL user configured successfully"
echo

exit 0
