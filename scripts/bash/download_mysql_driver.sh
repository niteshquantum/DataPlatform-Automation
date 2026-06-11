#!/bin/bash

set -e

# Project root directory
PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

# tools/drivers directory
DRIVER_DIR="$PROJECT_ROOT/tools/drivers"

mkdir -p "$DRIVER_DIR"

JAR_FILE="$DRIVER_DIR/mysql-connector-j-9.5.0.jar"

# Skip download if jar already exists
if [ -f "$JAR_FILE" ]; then
    echo "MySQL Connector already exists."
    exit 0
fi

echo "Downloading MySQL Connector..."

if command -v wget >/dev/null 2>&1; then

    wget -O "$JAR_FILE" \
    "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/9.5.0/mysql-connector-j-9.5.0.jar"

elif command -v curl >/dev/null 2>&1; then

    curl -L \
    "https://repo1.maven.org/maven2/com/mysql/mysql-connector-j/9.5.0/mysql-connector-j-9.5.0.jar" \
    -o "$JAR_FILE"

else

    echo "ERROR: wget or curl is required."
    exit 1

fi

if [ ! -f "$JAR_FILE" ]; then
    echo "MySQL connector download failed."
    exit 1
fi

echo "MySQL Driver downloaded successfully."