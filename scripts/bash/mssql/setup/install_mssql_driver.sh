#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING MSSQL JDBC DRIVER"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: MSSQL CONFIG NOT FOUND"
    exit 1
fi

MSSQL_DRIVER_VERSION=$(grep "^MSSQL_DRIVER_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2)

if [ -z "$MSSQL_DRIVER_VERSION" ]; then
    echo "ERROR: MSSQL_DRIVER_VERSION NOT FOUND"
    exit 1
fi

DRIVER_DIR="$PROJECT_ROOT/tools/drivers"
mkdir -p "$DRIVER_DIR"

JAR_FILE="$DRIVER_DIR/mssql-jdbc-${MSSQL_DRIVER_VERSION}.jre11.jar"

if [ -f "$JAR_FILE" ]; then
    echo "MSSQL JDBC Driver already installed."
    exit 0
fi

DOWNLOAD_URL="https://repo1.maven.org/maven2/com/microsoft/sqlserver/mssql-jdbc/${MSSQL_DRIVER_VERSION}.jre11/mssql-jdbc-${MSSQL_DRIVER_VERSION}.jre11.jar"

echo "Version : $MSSQL_DRIVER_VERSION"
echo "URL     : $DOWNLOAD_URL"
echo

curl --fail --location \
     --connect-timeout 30 \
     --retry 3 \
     --output "$JAR_FILE" \
     "$DOWNLOAD_URL"

if [ ! -f "$JAR_FILE" ]; then
    echo "ERROR: MSSQL JDBC Driver download failed."
    exit 1
fi

echo
echo "====================================="
echo "MSSQL JDBC DRIVER INSTALLED"
echo "====================================="
echo "Driver : $JAR_FILE"
echo "====================================="
echo

exit 0