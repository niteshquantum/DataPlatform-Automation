#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING MSSQL SERVER AND TOOLS"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"

export DEBIAN_FRONTEND=noninteractive

if [ -x "/opt/mssql/bin/sqlservr" ]
then
    echo "MSSQL Server is already installed."
else
    echo "Installing prerequisite packages..."

    sudo apt-get update
    sudo apt-get install -y \
        curl \
        gnupg \
        ca-certificates

    echo
    echo "Registering Microsoft GPG Key..."
    echo

    if [ ! -f "/usr/share/keyrings/microsoft-prod.gpg" ]
    then
        curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
        | sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg
    else
        echo "Microsoft GPG Key already exists."
    fi

    echo
    echo "Registering SQL Server 2025 Repository..."
    echo

    if [ ! -f "/etc/apt/sources.list.d/mssql-server-2025.list" ]
    then
        curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/mssql-server-2025.list \
        | sudo tee /etc/apt/sources.list.d/mssql-server-2025.list > /dev/null
    else
        echo "SQL Server 2025 repository already exists."
    fi

    echo
    echo "Registering Microsoft Product Repository..."
    echo

    if [ ! -f "/etc/apt/sources.list.d/microsoft-prod.list" ]
    then
        curl -fsSL https://packages.microsoft.com/config/ubuntu/24.04/prod.list \
        | sudo tee /etc/apt/sources.list.d/microsoft-prod.list > /dev/null
    else
        echo "Microsoft Product repository already exists."
    fi

    echo
    echo "Updating package index..."
    echo

    sudo apt-get update

    echo
    echo "Installing SQL Server..."
    echo

    sudo apt-get install -y mssql-server

    echo
    echo "Installing SQL Server Tools..."
    echo

    sudo ACCEPT_EULA=Y apt-get install -y \
        msodbcsql18 \
        mssql-tools18 \
        unixodbc-dev
fi

if [ ! -L "/usr/local/bin/sqlcmd" ]
then
    sudo ln -sf /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd
fi

echo
echo "Installed SQL Server Version:"
echo "-------------------------------------"
dpkg -s mssql-server | grep Version

echo
echo "Installed sqlcmd Version:"
echo "-------------------------------------"
/opt/mssql-tools18/bin/sqlcmd -? >/dev/null

echo
echo "====================================="
echo "MSSQL SERVER INSTALLATION COMPLETED"
echo "====================================="
echo

exit 0