#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mongodb.conf"

MONGODB_PORT=$(grep "^MONGODB_PORT=" "$CONFIG_FILE" | cut -d'=' -f2)

echo
echo "====================================="
echo "VALIDATING MONGODB"
echo "====================================="
echo

if command -v mongosh >/dev/null 2>&1
then

    mongosh \
        --port "$MONGODB_PORT" \
        --eval "db.adminCommand({ ping: 1 })"

else

    echo "mongosh not installed"

    exit 1

fi

echo
echo "====================================="
echo "MONGODB VALIDATION SUCCESSFUL"
echo "====================================="
echo

exit 0