
#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mysql.conf"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "ERROR: MySQL config file not found"
    echo "Expected: $CONFIG_FILE"
    exit 1
fi

MYSQL_HOST=$(grep "^MYSQL_HOST=" "$CONFIG_FILE" | cut -d'=' -f2)
MYSQL_PORT=$(grep "^MYSQL_PORT=" "$CONFIG_FILE" | cut -d'=' -f2)
MYSQL_DB=$(grep "^MYSQL_DB=" "$CONFIG_FILE" | cut -d'=' -f2)
MYSQL_USER=$(grep "^MYSQL_USER=" "$CONFIG_FILE" | cut -d'=' -f2)
MYSQL_PASSWORD=$(grep "^MYSQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)

REAL_MYSQL="/usr/bin/mysql"
GLOBAL_MYSQL="/usr/local/bin/mysql"

sanitize_name() {
    echo "$1" | tr -c '[:alnum:]' '_'
}

create_wrapper() {
    local target="$1"
    local database="$2"

    sudo mkdir -p "$(dirname "$target")"

    sudo tee "$target" > /dev/null <<EOF
#!/bin/bash

exec "$REAL_MYSQL" \
--host="$MYSQL_HOST" \
--port="$MYSQL_PORT" \
--user="$MYSQL_USER" \
--password="$MYSQL_PASSWORD" \
"$database" \
"\$@"
EOF

    sudo chmod +x "$target"
}

echo
echo "====================================="
echo "CONFIGURING GLOBAL MYSQL COMMAND"
echo "====================================="
echo

if [ ! -x "$REAL_MYSQL" ]; then
    echo "ERROR: MySQL client binary not found"
    echo "Expected: $REAL_MYSQL"
    exit 1
fi

echo "Host     : $MYSQL_HOST"
echo "Port     : $MYSQL_PORT"
echo "Database : $MYSQL_DB"
echo "User     : $MYSQL_USER"

echo

db_key=$(sanitize_name "$MYSQL_DB")
instance_wrapper="/usr/local/bin/mysql_${db_key}_${MYSQL_PORT}"

echo "Creating instance-aware mysql wrapper..."
create_wrapper "$instance_wrapper" "$MYSQL_DB"

echo "Updating default mysql wrapper for current configuration..."
create_wrapper "$GLOBAL_MYSQL" "$MYSQL_DB"

echo
echo "Validating mysql wrappers..."
"$instance_wrapper" --version
"$GLOBAL_MYSQL" --version

echo
echo "====================================="
echo "GLOBAL MYSQL CONFIGURED SUCCESSFULLY"
echo "====================================="
echo

echo "Command:"
echo "mysql"
echo "Instance wrapper:"
echo "$instance_wrapper"

exit 0
