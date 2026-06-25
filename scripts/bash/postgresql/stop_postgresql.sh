#!/bin/bash

set -e

if ! systemctl is-active --quiet postgresql; then
    echo "PostgreSQL already stopped"
    exit 0
fi

sudo systemctl stop postgresql

echo "PostgreSQL stopped successfully"