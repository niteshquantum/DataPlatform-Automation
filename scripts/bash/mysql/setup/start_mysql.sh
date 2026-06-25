#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "STARTING MYSQL"
echo "====================================="
echo

sudo systemctl start mysql

sleep 5

if ! systemctl is-active --quiet mysql
then
    echo "MYSQL FAILED TO START"
    exit 1
fi

echo
echo "====================================="
echo "MYSQL STARTED SUCCESSFULLY"
echo "====================================="
echo

exit 0