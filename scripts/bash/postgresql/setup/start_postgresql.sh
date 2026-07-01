#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "STARTING POSTGRESQL"
echo "====================================="
echo

sudo systemctl start postgresql

sleep 5

if ! systemctl is-active --quiet postgresql
then
    echo
    echo "POSTGRESQL START FAILED"
    exit 1
fi

echo
echo "POSTGRESQL START SUCCESSFUL"
echo

exit 0