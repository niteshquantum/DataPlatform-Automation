#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING SQL SERVER"
echo "====================================="
echo

if dpkg -l mssql-server 2>/dev/null | grep -q '^ii'
then
    echo "SQL Server already installed"

    /opt/mssql/bin/sqlservr --version || true

    exit 0
fi

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"

MSSQL_PASSWORD=$(grep "^MSSQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)

echo "Adding Microsoft Repository..."

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
| sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

UBUNTU_VERSION=$(lsb_release -rs)

curl -fsSL \
https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/mssql-server-2022.list \
| sudo tee /etc/apt/sources.list.d/mssql-server-2022.list > /dev/null

sudo apt-get update

sudo apt-get install -y mssql-server

echo "Configuring SQL Server..."

sudo MSSQL_PID=Developer \
MSSQL_SA_PASSWORD="$MSSQL_PASSWORD" \
/opt/mssql/bin/mssql-conf -n setup accept-eula

echo
echo "====================================="
echo "SQL SERVER INSTALLED SUCCESSFULLY"
echo "====================================="
echo

exit 0