#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "CREATE DATABASE"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/mysql.conf"

MYSQL_HOST=$(grep "^MYSQL_HOST=" "$CONFIG_FILE" | cut -d'=' -f2)
MYSQL_PORT=$(grep "^MYSQL_PORT=" "$CONFIG_FILE" | cut -d'=' -f2)
MYSQL_DB=$(grep "^MYSQL_DB=" "$CONFIG_FILE" | cut -d'=' -f2)
MYSQL_USER=$(grep "^MYSQL_USER=" "$CONFIG_FILE" | cut -d'=' -f2)
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)

echo "Host     : $MYSQL_HOST"
echo "Port     : $MYSQL_PORT"
echo "Database : $MYSQL_DB"
echo "User     : $MYSQL_USER"
echo

echo "Creating database if not exists..."

mysql \
-h "$MYSQL_HOST" \
-P "$MYSQL_PORT" \
-u "$MYSQL_USER" \
-p"$MYSQL_PASSWORD" \
-e "CREATE DATABASE IF NOT EXISTS $MYSQL_DB;"

echo
echo "DATABASE READY : $MYSQL_DB"

echo
echo "====================================="
echo "DATABASE VALIDATED"
echo "====================================="
echo

exit 0