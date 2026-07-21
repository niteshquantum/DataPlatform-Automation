#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mysql.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: Configuration file not found: $CONFIG_FILE"
    echo "INSTANCE_STATE=NO_INSTANCE"
    exit 1
fi

MYSQL_PORT=$(grep "^MYSQL_PORT=" "$CONFIG_FILE" | cut -d'=' -f2)

echo
echo "====================================="
echo "CHECKING MYSQL INSTANCE STATE"
echo "====================================="
echo

if ! command -v mysqld >/dev/null 2>&1; then
    echo "MySQL is not installed."
    echo
    echo "INSTANCE_STATE=NO_INSTANCE"
    exit 1
fi

if systemctl is-active --quiet mysql; then
    if ss -ltn | grep -q ":${MYSQL_PORT}\b"; then
        echo "MySQL is running and port ${MYSQL_PORT} is listening."
        echo
        echo "INSTANCE_STATE=INSTANCE_RUNNING_AND_USABLE"
        exit 0
    else
        echo "MySQL is running but port ${MYSQL_PORT} is not listening."
        echo
        echo "INSTANCE_STATE=INSTANCE_INSTALLED_BUT_STOPPED"
        exit 1
    fi
else
    echo "MySQL is installed but not running."
    echo
    echo "INSTANCE_STATE=INSTANCE_INSTALLED_BUT_STOPPED"
    exit 1
fi
