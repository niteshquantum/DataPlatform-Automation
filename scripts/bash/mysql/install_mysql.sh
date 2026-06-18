#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING MYSQL"
echo "====================================="
echo

if command -v mysqld >/dev/null 2>&1
then
    echo "MySQL already installed"

    mysqld --version

    exit 0
fi

sudo apt-get update

sudo apt-get install -y mysql-server

mysqld --version

echo
echo "====================================="
echo "MYSQL INSTALLED SUCCESSFULLY"
echo "====================================="
echo

exit 0