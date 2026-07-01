#!/bin/bash

set -e
 
source "$(dirname "$0")/../../common/set_project_root.sh"
 
CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/postgresql.conf"
 
PORT=$(grep "^POSTGRESQL_PORT=" "$CONFIG_FILE" | cut -d'=' -f2)
 
echo "Using PostgreSQL port: $PORT"
 
PG_CONF=$(find /etc/postgresql -name postgresql.conf | head -1)
 
sudo sed -i "s/^#\?port = .*/port = $PORT/" "$PG_CONF"
 
sudo systemctl restart postgresql
 
sleep 5
 
sudo ss -ltn | grep ":$PORT" || {

    echo "PostgreSQL not listening on port $PORT"

    exit 1

}
 
echo "PostgreSQL started successfully on port $PORT"
 