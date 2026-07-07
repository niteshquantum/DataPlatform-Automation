#!/bin/bash

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/../../common/set_project_root.sh"

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mongodb.conf"

MONGODB_HOST=$(grep "^MONGODB_HOST=" "$CONFIG_FILE" | cut -d'=' -f2)
MONGODB_PORT=$(grep "^MONGODB_PORT=" "$CONFIG_FILE" | cut -d'=' -f2)

MONGOSH_BINARY="$PROJECT_ROOT/databases/mongodb/mongosh/bin/mongosh"
GLOBAL_MONGOSH="/usr/local/bin/mongosh"

echo
echo "====================================="
echo "CONFIGURING GLOBAL MONGOSH COMMAND"
echo "====================================="
echo

if [ ! -f "$MONGOSH_BINARY" ]; then
    echo "ERROR: mongosh binary not found"
    echo "Expected: $MONGOSH_BINARY"
    exit 1
fi

echo "Creating global mongosh command..."

sudo ln -sf "$MONGOSH_BINARY" "$GLOBAL_MONGOSH"

echo
echo "Validating global mongosh command..."

if ! command -v mongosh >/dev/null 2>&1; then
    echo "ERROR: Global mongosh command configuration failed"
    exit 1
fi

mongosh --version

echo
echo "====================================="
echo "GLOBAL MONGOSH CONFIGURED SUCCESSFULLY"
echo "====================================="
echo

echo "MongoDB connection command:"
echo
echo "mongosh --host $MONGODB_HOST --port $MONGODB_PORT"
echo

exit 0
