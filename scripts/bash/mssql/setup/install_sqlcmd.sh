#!/bin/bash

set -e

echo
echo "====================================="
echo "INSTALLING SQLCMD"
echo "====================================="
echo

if command -v sqlcmd >/dev/null 2>&1; then
    echo "SQLCMD already installed."
    exit 0
fi

curl https://packages.microsoft.com/keys/microsoft.asc | \
sudo gpg --dearmor -o /usr/share/keyrings/microsoft-prod.gpg

curl https://packages.microsoft.com/config/ubuntu/22.04/prod.list | \
sudo tee /etc/apt/sources.list.d/mssql-release.list >/dev/null

sudo apt-get update

sudo ACCEPT_EULA=Y apt-get install -y \
    msodbcsql18 \
    mssql-tools18

if ! command -v sqlcmd >/dev/null 2>&1; then
    echo "ERROR: SQLCMD INSTALLATION FAILED"
    exit 1
fi

echo
echo "SQLCMD INSTALLATION SUCCESSFUL"
echo

exit 0