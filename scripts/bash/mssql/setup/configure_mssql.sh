#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "CONFIGURING MSSQL SERVER"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"

# =====================================
# VALIDATE CONFIG
# =====================================

if [ ! -f "$CONFIG_FILE" ]
then
    echo "Configuration file not found."
    echo "Expected: $CONFIG_FILE"
    exit 1
fi

MSSQL_PASSWORD=$(grep "^MSSQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)
MSSQL_PID=$(grep "^MSSQL_PID=" "$CONFIG_FILE" | cut -d'=' -f2)

# =====================================
# VALIDATE INSTALLATION
# =====================================

if [ ! -x "/opt/mssql/bin/mssql-conf" ]
then
    echo "SQL Server is not installed."
    exit 1
fi

# =====================================
# CONFIGURE SQL SERVER
# =====================================

if [ -f "/var/opt/mssql/mssql.conf" ]
then
    echo "SQL Server is already configured."
else
    echo "Running SQL Server setup..."

    sudo MSSQL_PID="$MSSQL_PID" \
         MSSQL_SA_PASSWORD="$MSSQL_PASSWORD" \
         /opt/mssql/bin/mssql-conf -n setup accept-eula
fi

echo
echo "Enabling SQL Server service..."

sudo systemctl enable mssql-server

echo

# =====================================
# START / RESTART SERVICE
# =====================================

if sudo systemctl is-active --quiet mssql-server
then
    echo "Restarting SQL Server service..."
    sudo systemctl restart mssql-server
else
    echo "Starting SQL Server service..."
    sudo systemctl start mssql-server
fi

echo
echo "Waiting for SQL Server service..."

sleep 10

# =====================================
# VALIDATE SERVICE
# =====================================

if ! sudo systemctl is-active --quiet mssql-server
then
    echo "SQL Server service failed to start."
    exit 1
fi

# =====================================
# VALIDATE CONNECTION
# =====================================

SQLCMD="/opt/mssql-tools18/bin/sqlcmd"

if [ -x "$SQLCMD" ]
then
    echo
    echo "Validating SQL Server connection..."

    "$SQLCMD" \
    -S localhost \
    -U sa \
    -P "$MSSQL_PASSWORD" \
    -C \
    -Q "SELECT @@VERSION;" > /dev/null

    echo "SQL Server connection validated."
fi

echo
echo "====================================="
echo "MSSQL CONFIGURATION COMPLETED"
echo "====================================="
echo

exit 0
