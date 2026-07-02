#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/postgresql.conf"

POSTGRESQL_VERSION=$(grep "^POSTGRESQL_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2)

echo
echo "====================================="
echo "INSTALLING POSTGRESQL $POSTGRESQL_VERSION"
echo "====================================="
echo

# Check if required version already exists
if pg_lsclusters 2>/dev/null | grep -q "^$POSTGRESQL_VERSION "
then
    echo "PostgreSQL $POSTGRESQL_VERSION already installed"
    exit 0
fi

sudo apt-get update

sudo apt-get install -y \
    postgresql-$POSTGRESQL_VERSION \
    postgresql-client-$POSTGRESQL_VERSION

sudo systemctl enable postgresql

# Verify installation
if ! psql --version | grep -q "$POSTGRESQL_VERSION"
then
    echo "POSTGRESQL $POSTGRESQL_VERSION INSTALLATION FAILED"
    exit 1
fi

echo
echo "PostgreSQL Version:"
psql --version

echo
echo "====================================="
echo "POSTGRESQL INSTALLED SUCCESSFULLY"
echo "====================================="
echo

exit 0
