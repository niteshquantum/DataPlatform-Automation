#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "CONFIGURING MSSQL SERVER"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"

if [ ! -f "$CONFIG_FILE" ]
then
    echo "Configuration file not found:"
    echo "$CONFIG_FILE"
    exit 1
fi

MSSQL_PASSWORD=$(grep "^MSSQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)
MSSQL_PID=$(grep "^MSSQL_PID=" "$CONFIG_FILE" | cut -d'=' -f2)

if [ ! -x "/opt/mssql/bin/mssql-conf" ]
then
    echo "SQL Server is not installed."
    exit 1
fi

echo "Running SQL Server setup..."

sudo MSSQL_PID="$MSSQL_PID" \
MSSQL_SA_PASSWORD="$MSSQL_PASSWORD" \
/opt/mssql/bin/mssql-conf -n setup accept-eula

echo
echo "Enabling SQL Server service..."

sudo systemctl enable mssql-server

echo
echo "Restarting SQL Server service..."

sudo systemctl restart mssql-server

echo
echo "Waiting for SQL Server to initialize..."

sleep 10

if ! systemctl is-active --quiet mssql-server
then
    echo "SQL Server service failed to start."
    exit 1
fi

echo
echo "SQL Server service is running."

echo
echo "====================================="
echo "MSSQL CONFIGURATION COMPLETED"
echo "====================================="
echo

exit 0