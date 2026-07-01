#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING POSTGRESQL"
echo "====================================="
echo

if command -v psql >/dev/null 2>&1
then
    echo "PostgreSQL already installed"
    psql --version
    exit 0
fi

sudo apt-get update

sudo apt-get install -y \
postgresql \
postgresql-client

sudo systemctl enable postgresql

# =====================================
# VERIFY INSTALLATION
# =====================================

if ! command -v psql >/dev/null 2>&1
then
    echo "POSTGRESQL INSTALLATION FAILED"
    exit 1
fi

echo
echo "PostgreSQL Version:"
psql --version

echo
echo "====================================="
echo "POSTGRESQL INSTALLED SUCCESSFULLY"
echo "====================================="
echo

exit 0