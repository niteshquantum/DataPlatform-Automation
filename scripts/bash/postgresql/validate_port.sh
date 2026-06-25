#!/bin/bash

set -e

PROJECT_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")"/../../.. && pwd)"

python \
"${PROJECT_ROOT}/scripts/python/postgresql/validate_port.py"

echo "Port validation successful"