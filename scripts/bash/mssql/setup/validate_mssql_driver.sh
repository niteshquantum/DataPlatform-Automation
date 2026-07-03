#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "VALIDATING MSSQL JDBC DRIVER"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: MSSQL CONFIG NOT FOUND"
    exit 1
fi

MSSQL_DRIVER_VERSION=$(grep "^MSSQL_DRIVER_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2)

if [ -z "$MSSQL_DRIVER_VERSION" ]; then
    echo "ERROR: MSSQL_DRIVER_VERSION NOT FOUND IN mssql.conf"
    exit 1
fi

echo "Expected Driver Version : $MSSQL_DRIVER_VERSION"
echo

DRIVER_DIR="$PROJECT_ROOT/tools/drivers"

if [ ! -d "$DRIVER_DIR" ]; then
    echo "ERROR: DRIVER DIRECTORY NOT FOUND"
    exit 1
fi

EXPECTED_DRIVER="$DRIVER_DIR/mssql-jdbc-${MSSQL_DRIVER_VERSION}.jre11.jar"

if [ ! -f "$EXPECTED_DRIVER" ]; then
    echo "ERROR: EXPECTED JDBC DRIVER NOT FOUND"
    echo "Expected: $EXPECTED_DRIVER"
    exit 1
fi

echo "Driver Found:"
echo "$EXPECTED_DRIVER"

echo
echo "====================================="
echo "MSSQL JDBC DRIVER VALIDATED"
echo "====================================="
echo

exit 0