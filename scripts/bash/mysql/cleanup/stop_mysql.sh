#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "STOPPING MYSQL"
echo "====================================="
echo

if ! systemctl list-unit-files mysql.service >/dev/null 2>&1
then
    echo "MYSQL SERVICE NOT FOUND"
    echo "Nothing to stop."
    exit 0
fi

if systemctl is-active --quiet mysql
then
    echo "Stopping MySQL service..."

    sudo systemctl stop mysql

    sleep 3
else
    echo "MySQL service is already stopped."
fi

echo
echo "Validating MySQL service status..."

if systemctl is-active --quiet mysql
then
    echo
    echo "ERROR: MYSQL SERVICE IS STILL RUNNING"
    exit 1
fi

echo
echo "====================================="
echo "MYSQL STOPPED SUCCESSFULLY"
echo "====================================="
echo

exit 0