#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

GLOBAL_MYSQL="/usr/local/bin/mysql"

echo
echo "====================================="
echo "REMOVING GLOBAL MYSQL COMMAND"
echo "====================================="
echo

if [ -e "$GLOBAL_MYSQL" ]
then
    echo "Removing global MySQL wrapper..."

    sudo rm -f "$GLOBAL_MYSQL"
else
    echo "Global MySQL wrapper not found."
    echo "Nothing to remove."
fi

echo
echo "Validating global MySQL wrapper removal..."

if [ -e "$GLOBAL_MYSQL" ]
then
    echo
    echo "ERROR: GLOBAL MYSQL WRAPPER STILL EXISTS"
    exit 1
fi

echo
echo "====================================="
echo "GLOBAL MYSQL COMMAND REMOVED SUCCESSFULLY"
echo "====================================="
echo

exit 0