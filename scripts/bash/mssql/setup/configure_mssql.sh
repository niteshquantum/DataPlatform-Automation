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

MSSQL_HOST=$(grep "^MSSQL_HOST=" "$CONFIG_FILE" | cut -d'=' -f2)
MSSQL_PORT=$(grep "^MSSQL_PORT=" "$CONFIG_FILE" | cut -d'=' -f2)
MSSQL_USER=$(grep "^MSSQL_USER=" "$CONFIG_FILE" | cut -d'=' -f2)
MSSQL_PASSWORD=$(grep "^MSSQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)

# =====================================
# VALIDATE INSTALLATION
# =====================================

if [ ! -x "/opt/mssql/bin/mssql-conf" ]
then
    echo "SQL Server is not installed."
    exit 1
fi

SQLCMD="/opt/mssql-tools18/bin/sqlcmd"

if [ ! -x "$SQLCMD" ]
then
    echo "sqlcmd not found."
    exit 1
fi

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

for i in {1..60}
do
    if sudo systemctl is-active --quiet mssql-server
    then
        break
    fi

    sleep 2
done

# =====================================
# VALIDATE SERVICE
# =====================================

if ! sudo systemctl is-active --quiet mssql-server
then
    echo "SQL Server service failed to start."
    exit 1
fi

echo
echo "Validating SQL Server connection..."

"$SQLCMD" \
-S "${MSSQL_HOST},${MSSQL_PORT}" \
-U "$MSSQL_USER" \
-P "$MSSQL_PASSWORD" \
-C \
-Q "SELECT @@VERSION;"

echo
echo "SQL Server connection validated."

echo
echo "====================================="
echo "MSSQL CONFIGURATION COMPLETED"
echo "====================================="
echo

exit 0
