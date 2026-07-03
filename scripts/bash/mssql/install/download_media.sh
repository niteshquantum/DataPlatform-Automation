#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "MSSQL MEDIA PRE-FLIGHT VALIDATION"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"
MEDIA_DIR="$PROJECT_ROOT/databases/mssql/media"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: MSSQL CONFIG NOT FOUND"
    exit 1
fi

MSSQL_MEDIA_URL=$(grep "^MSSQL_MEDIA_URL=" "$CONFIG_FILE" | cut -d'=' -f2-)

if [ -z "$MSSQL_MEDIA_URL" ]; then
    echo "ERROR: MSSQL_MEDIA_URL NOT FOUND"
    exit 1
fi

mkdir -p "$MEDIA_DIR"

ISO_NAME=$(basename "${MSSQL_MEDIA_URL%%\?*}")
MEDIA_FILE="$MEDIA_DIR/$ISO_NAME"

echo "Source : $MSSQL_MEDIA_URL"
echo "Target : $MEDIA_FILE"
echo

if [ -f "$MEDIA_FILE" ]; then
    echo "MSSQL installation media already downloaded."
    exit 0
fi

echo "Downloading SQL Server installation media..."

curl --fail \
     --location \
     --connect-timeout 30 \
     --retry 3 \
     --output "$MEDIA_FILE" \
     "$MSSQL_MEDIA_URL"

if [ ! -f "$MEDIA_FILE" ]; then
    echo "ERROR: MEDIA DOWNLOAD FAILED"
    exit 1
fi

echo
echo "====================================="
echo "MEDIA DOWNLOAD SUCCESSFUL"
echo "====================================="
echo "Media : $MEDIA_FILE"
echo

exit 0