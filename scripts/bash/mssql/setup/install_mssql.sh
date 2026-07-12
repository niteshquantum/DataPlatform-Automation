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

# Check if mssql-server binary exists before installing
if [ -x "/opt/mssql/bin/sqlservr" ]
then
    echo "MSSQL Server is already installed."
    exit 0
fi

sudo apt-get update
sudo apt-get install -y wget ca-certificates gnupg lsb-release bc

echo "Adding official Microsoft PGDG-style repository..."

# Download and install key exactly like your PostgreSQL script
wget -qO- https://microsoft.com | sudo gpg --dearmor --yes -o /usr/share/keyrings/microsoft-prod.gpg

# Register the exact working repository endpoints for Ubuntu (Using 22.04 packages as mandated for 24.04 compatibility)
echo "deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://microsoft.com jammy main" | sudo tee /etc/apt/sources.list.d/mssql-server.list > /dev/null
echo "deb [signed-by=/usr/share/keyrings/microsoft-prod.gpg] https://microsoft.com jammy main" | sudo tee /etc/apt/sources.list.d/mssql-tools.list > /dev/null

sudo apt-get update

echo "Installing mssql-server package..."
sudo -E apt-get install -y mssql-server

echo "Configuring SQL Server Engine Instance..."
sudo MSSQL_PID="$MSSQL_PID" \
     MSSQL_SA_PASSWORD="$MSSQL_PASSWORD" \
     /opt/mssql/bin/mssql-conf -n setup accept-eula

# 2. Install SQLCMD CLI Utilities if not present
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

echo
echo "====================================="
echo "MSSQL INSTALLATION COMPLETED"
echo "====================================="
echo

exit 0
