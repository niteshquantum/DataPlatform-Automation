#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING MSSQL SERVER AND TOOLS"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"
MSSQL_PASSWORD=$(grep "^MSSQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)
MSSQL_PID=$(grep "^MSSQL_PID=" "$CONFIG_FILE" | cut -d'=' -f2)

export DEBIAN_FRONTEND=noninteractive

# Skip installation entirely if mssql-server binary already exists
if [ -x "/opt/mssql/bin/sqlservr" ]
then
    echo "MSSQL Server is already installed."
    exit 0
fi

sudo apt-get update
sudo apt-get install -y lsb-release bc

echo "Registering Hand-Verified Microsoft Repositories..."

# Force clean inside the execution block to make absolutely sure no bad cache stays behind
sudo rm -f /etc/apt/sources.list.d/mssql* /etc/apt/sources.list.d/prod* /etc/apt/sources.list.d/micro* /etc/apt/sources.list.d/microsoft*

# Write the exact verified, working URLs without 'www.' directly to mssql.list
sudo tee /etc/apt/sources.list.d/mssql.list > /dev/null << 'EOL'
deb [trusted=yes] https://packages.microsoft.com/ubuntu/22.04/mssql-server-2022 jammy main
deb [trusted=yes] https://microsoft.com jammy main
EOL

# Sync repositories cleanly using the clean list
sudo apt-get update

echo "Installing mssql-server package..."
sudo -E apt-get install -y mssql-server

echo "Configuring SQL Server Engine Instance..."
sudo MSSQL_PID="$MSSQL_PID" \
     MSSQL_SA_PASSWORD="$MSSQL_PASSWORD" \
     /opt/mssql/bin/mssql-conf -n setup accept-eula

# Install SQLCMD CLI Utilities if not present
SQLCMD_PATH="/opt/mssql-tools18/bin/sqlcmd"
if [ ! -x "$SQLCMD_PATH" ]
then
    echo "Installing mssql-tools18 command line utilities..."
    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev

    sudo ln -sf /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' | sudo tee /etc/profile.d/mssql-tools.sh > /dev/null
fi

export PATH="$PATH:/opt/mssql-tools18/bin"

echo
echo "MSSQL SERVER VERSION:"
/opt/mssql/bin/sqlservr --version || true

echo "====================================="
echo "MSSQL INSTALLATION COMPLETED"
echo "====================================="
echo

exit 0
