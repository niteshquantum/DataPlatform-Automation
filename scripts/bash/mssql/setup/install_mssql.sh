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

# Ensure prerequisite tools are available
sudo apt-get update
sudo apt-get install -y curl gnupg2 lsb-release

# 1. Install SQL Server Engine if not present
if ! dpkg -l mssql-server 2>/dev/null | grep -q '^ii'
then
    echo "Adding Microsoft Repository Keys..."
    curl -fsSL https://microsoft.com | sudo gpg --dearmor --yes -o /usr/share/keyrings/microsoft-prod.gpg

    UBUNTU_VERSION=$(lsb_release -rs)
    echo "Registering Microsoft Ubuntu ${UBUNTU_VERSION} Repository..."
    curl -fsSL "https://microsoft.com{UBUNTU_VERSION}/mssql-server-2022.list" | sudo tee /etc/apt/sources.list.d/mssql-server-2022.list > /dev/null
    curl -fsSL "https://microsoft.com{UBUNTU_VERSION}/prod.list" | sudo tee /etc/apt/sources.list.d/mssql-tools.list > /dev/null

    sudo apt-get update
    
    echo "Installing mssql-server package..."
    sudo apt-get install -y mssql-server

    echo "Configuring SQL Server Engine Instance..."
    sudo MSSQL_PID="$MSSQL_PID" \
         MSSQL_SA_PASSWORD="$MSSQL_PASSWORD" \
         /opt/mssql/bin/mssql-conf -n setup accept-eula
fi

# 2. Install SQLCMD CLI Utilities if not present
SQLCMD_PATH="/opt/mssql-tools18/bin/sqlcmd"
if [ ! -x "$SQLCMD_PATH" ]
then
    echo "Installing mssql-tools18 command line utilities..."
    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev

    # Symlink to traditional bin location for execution parity
    sudo ln -sf /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd
    
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' | sudo tee /etc/profile.d/mssql-tools.sh > /dev/null
fi

export PATH="$PATH:/opt/mssql-tools18/bin"

echo
echo "MSSQL SERVER VERSION:"
/opt/mssql/bin/sqlservr --version || true

echo
echo "SQLCMD UTILITY VERSION:"
sqlcmd -? | head -n 1 || true

echo
echo "====================================="
echo "MSSQL INSTALLATION COMPLETED"
echo "====================================="
echo

exit 0
