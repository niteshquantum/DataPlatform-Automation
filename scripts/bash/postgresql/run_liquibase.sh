#!/bin/bash

set -e

source "$(dirname "$0")/../common/set_project_root.sh"

echo
echo "====================================="
echo "RUNNING LIQUIBASE"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/postgresql.conf"

PG_HOST=$(grep    "^POSTGRESQL_HOST="               "$CONFIG_FILE" | cut -d'=' -f2)
PG_PORT=$(grep    "^POSTGRESQL_PORT="               "$CONFIG_FILE" | cut -d'=' -f2)
PG_DB=$(grep      "^POSTGRESQL_DATABASE="           "$CONFIG_FILE" | cut -d'=' -f2)
PG_USER=$(grep    "^POSTGRESQL_ADMIN_USER="         "$CONFIG_FILE" | cut -d'=' -f2)
PG_PASSWORD=$(grep "^POSTGRESQL_ADMIN_PASSWORD="    "$CONFIG_FILE" | cut -d'=' -f2)
LIQUIBASE_VERSION=$(grep "^LIQUIBASE_VERSION="      "$CONFIG_FILE" | cut -d'=' -f2)
DRIVER_VERSION=$(grep "^POSTGRESQL_DRIVER_VERSION=" "$CONFIG_FILE" | cut -d'=' -f2)

LB="$PROJECT_ROOT/tools/liquibase/liquibase"
DRIVER="$PROJECT_ROOT/tools/drivers/postgresql-${DRIVER_VERSION}.jar"

# ---- Auto-download Liquibase if missing ----
if [ ! -f "$LB" ]; then
    echo "Liquibase not found - downloading version ${LIQUIBASE_VERSION}..."
    mkdir -p "$PROJECT_ROOT/tools/liquibase"
    sudo apt-get update -qq
    sudo apt-get install -y wget unzip
    wget -q -O "$PROJECT_ROOT/tools/liquibase.zip" \
        "https://github.com/liquibase/liquibase/releases/download/v${LIQUIBASE_VERSION}/liquibase-${LIQUIBASE_VERSION}.zip"
    unzip -q -o "$PROJECT_ROOT/tools/liquibase.zip" -d "$PROJECT_ROOT/tools/liquibase"
    chmod +x "$LB"
    rm -f "$PROJECT_ROOT/tools/liquibase.zip"
    echo "Liquibase installed"
else
    echo "Liquibase already present"
fi

# ---- Auto-download JDBC driver if missing ----
if [ ! -f "$DRIVER" ]; then
    echo "PostgreSQL JDBC driver not found - downloading version ${DRIVER_VERSION}..."
    mkdir -p "$PROJECT_ROOT/tools/drivers"
    wget -q -O "$DRIVER" \
        "https://jdbc.postgresql.org/download/postgresql-${DRIVER_VERSION}.jar"
    echo "Driver downloaded: $DRIVER"
else
    echo "JDBC driver already present"
fi

echo "Database : $PG_DB"
echo "Host     : $PG_HOST"
echo "Port     : $PG_PORT"
echo "User     : $PG_USER"
echo "Driver   : $DRIVER"
echo

java -version

echo

# CRITICAL: cd into changelog dir first — Liquibase 5.x resolves
# relative <include> files from CWD, not from --changeLogFile path.
cd "$PROJECT_ROOT/liquibase/postgresql"

"$LB" \
  --classpath="$DRIVER" \
  --driver=org.postgresql.Driver \
  --changeLogFile=master.xml \
  --url="jdbc:postgresql://$PG_HOST:$PG_PORT/$PG_DB" \
  --username="$PG_USER" \
  --password="$PG_PASSWORD" \
  update

echo
echo "====================================="
echo "LIQUIBASE UPDATE COMPLETED"
echo "====================================="
echo

exit 0