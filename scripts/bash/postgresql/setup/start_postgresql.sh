#!/bin/bash
 
set -e
 
source "$(dirname "$0")/../../common/set_project_root.sh"
 
CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/postgresql.conf"
 
PORT=$(grep "^POSTGRESQL_PORT=" "$CONFIG_FILE" | cut -d'=' -f2)

VERSION=$(grep "^POSTGRESQL_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2)
 
echo "Using PostgreSQL version: $VERSION"

echo "Using PostgreSQL port: $PORT"
 
PG_CONF="/etc/postgresql/$VERSION/main/postgresql.conf"
 
if [ ! -f "$PG_CONF" ]; then

    echo "PostgreSQL config not found: $PG_CONF"

    exit 1

fi
 
sudo sed -i "s/^#\?port = .*/port = $PORT/" "$PG_CONF"
 
sudo pg_ctlcluster "$VERSION" main restart
 
sleep 5
 
if ! sudo ss -ltn | grep -q ":$PORT "; then

    echo "PostgreSQL not listening on port $PORT"

    exit 1

fi
 
echo

echo "PostgreSQL started successfully on port $PORT"

echo
 