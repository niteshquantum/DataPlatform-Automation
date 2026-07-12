#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "STARTING MSSQL SERVER"
echo "====================================="
echo

sudo systemctl start mssql-server

sleep 5

if ! systemctl is-active --quiet mssql-server
then
    echo
    echo "MSSQL SERVER START FAILED"
    exit 1
fi

echo
echo "MSSQL SERVER START SUCCESSFUL"
echo

exit 0
