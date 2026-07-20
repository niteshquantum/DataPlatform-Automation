#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "STARTING MYSQL"
echo "====================================="
echo

if systemctl is-active --quiet mysql
then
    echo "MySQL service is already running."
else
    echo "Starting MySQL service..."
    sudo systemctl start mysql
    sleep 5
fi

if ! systemctl is-active --quiet mysql
then
    echo
    echo "MYSQL START FAILED"
    exit 1
fi

echo
echo "MYSQL START SUCCESSFUL"
echo

exit 0