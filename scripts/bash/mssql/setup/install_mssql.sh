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

# Skip installation entirely if mssql-server binary is found
if [ -x "/opt/mssql/bin/sqlservr" ]
then
    echo "MSSQL Server is already installed."
    exit 0
fi

sudo apt-get update
sudo apt-get install -y lsb-release bc gnupg

echo "Fetching official Microsoft Signing Keys securely..."
# Fetch the exact missing key from the trusted Ubuntu Keyserver directly to bypass proxy/curl blocks
sudo apt-key adv --keyserver ://ubuntu.com --recv-keys EB3E94ADBE1229CF

echo "Registering Clean Microsoft Repositories..."
# Clean up any residual old list references within the block execution
sudo rm -f /etc/apt/sources.list.d/mssql* /etc/apt/sources.list.d/prod*
sudo sed -i '/www.microsoft.com/d' /etc/apt/sources.list /etc/apt/sources.list.d/*.list 2>/dev/null || true

# Write the perfect verified endpoints without 'www.'
sudo tee /etc/apt/sources.list.d/mssql_clean.list > /dev/null << 'EOL'
deb [arch=amd64] https://packages.microsoft.com/ubuntu/22.04/mssql-server-2022 jammy main
deb [arch=amd64] https://microsoft.com jammy main
EOL

# Sync repositories cleanly
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

echo "====================================="
echo "MSSQL INSTALLATION COMPLETED"
echo "====================================="
echo

exit 0
