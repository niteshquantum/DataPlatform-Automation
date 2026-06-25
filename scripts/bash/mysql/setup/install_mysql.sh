#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING MYSQL"
echo "====================================="
echo

if ! command -v mysqld >/dev/null 2>&1
then
    sudo apt-get update
    sudo apt-get install -y mysql-server
fi

echo "MySQL Version:"
mysqld --version

echo
echo "====================================="
echo "CONFIGURING MYSQL USER"
echo "====================================="
echo

sudo mysql <<EOF
CREATE USER IF NOT EXISTS 'rootuser'@'localhost' IDENTIFIED BY 'root123';
ALTER USER 'rootuser'@'localhost' IDENTIFIED BY 'root123';
GRANT ALL PRIVILEGES ON *.* TO 'rootuser'@'localhost' WITH GRANT OPTION;
FLUSH PRIVILEGES;
EOF

echo
echo "====================================="
echo "MYSQL INSTALLED AND CONFIGURED"
echo "====================================="
echo

exit 0