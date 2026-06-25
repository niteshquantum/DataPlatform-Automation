#!/bin/bash
set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/../../.." && pwd)"
PG_DIR="$PROJECT_ROOT/databases/postgresql"
PG_BIN="$PG_DIR/bin"
PG_DATA="$PG_DIR/data"
PG_PORT=5432

export PATH="$PG_BIN:$PATH"

# Already installed in project folder check
if [ -f "$PG_BIN/pg_ctl" ]; then
    echo "PostgreSQL already installed in project folder: $PG_DIR"
    exit 0
fi

echo "Installing PostgreSQL binaries via apt..."
sudo apt-get update -y
sudo apt-get install -y postgresql-14 postgresql-client-14

# Copy binaries to project folder
echo "Copying binaries to project folder..."
mkdir -p "$PG_DIR/bin" "$PG_DIR/lib" "$PG_DIR/share"

sudo cp -r /usr/lib/postgresql/14/bin/. "$PG_DIR/bin/"
sudo cp -r /usr/lib/postgresql/14/lib/. "$PG_DIR/lib/" 2>/dev/null || true
sudo cp -r /usr/share/postgresql/14/. "$PG_DIR/share/" 2>/dev/null || true

sudo chown -R $(whoami):$(whoami) "$PG_DIR"
chmod -R +x "$PG_DIR/bin/"

echo "Binaries copied to: $PG_DIR"

# Initialize data directory
if [ ! -d "$PG_DATA/base" ]; then
    echo "Initializing PostgreSQL data directory..."
    "$PG_BIN/initdb" -D "$PG_DATA" --auth=trust --username=postgres
    echo "Data directory initialized: $PG_DATA"
fi

echo "PostgreSQL project folder installation complete"