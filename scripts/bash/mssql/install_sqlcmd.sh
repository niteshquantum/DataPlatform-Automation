#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING SQLCMD"
echo "====================================="
echo

if command -v sqlcmd >/dev/null 2>&1
then
    echo "sqlcmd already installed"

    sqlcmd -?

    exit 0
fi

curl -fsSL https://packages.microsoft.com/keys/microsoft.asc \
| sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

UBUNTU_VERSION=$(lsb_release -rs)

curl -fsSL \
https://packages.microsoft.com/config/ubuntu/${UBUNTU_VERSION}/prod.list \
| sudo tee /etc/apt/sources.list.d/mssql-tools.list > /dev/null

sudo apt-get update

sudo ACCEPT_EULA=Y apt-get install -y \
mssql-tools18 \
unixodbc-dev

echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' \
| sudo tee /etc/profile.d/mssql-tools.sh

export PATH="$PATH:/opt/mssql-tools18/bin"

sqlcmd -?

echo
echo "====================================="
echo "SQLCMD INSTALLED SUCCESSFULLY"
echo "====================================="
echo

exit 0