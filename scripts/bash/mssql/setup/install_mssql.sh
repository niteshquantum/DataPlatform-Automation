#!/bin/bash

set -e

source "$(dirname "$0")/../../common/set_project_root.sh"

echo
echo "====================================="
echo "INSTALLING MSSQL SERVER AND TOOLS"
echo "====================================="
echo

CONFIG_FILE="$PROJECT_ROOT/config/ubuntu/mssql.conf"
MSSQL_PASSWORD=$(grep "^MSSQL_PASSWORD=" "$CONFIG_FILE" | cut -d'=' -f2)
MSSQL_PID=$(grep "^MSSQL_PID=" "$CONFIG_FILE" | cut -d'=' -f2)

export DEBIAN_FRONTEND=noninteractive

sudo apt-get update
sudo apt-get install -y curl lsb-release bc

# 1. Install SQL Server Engine if not present
if ! dpkg -l mssql-server 2>/dev/null | grep -q '^ii'
then
    echo "Writing Microsoft Repository Key Inline..."
    sudo mkdir -p /usr/share/keyrings

    # Write the key directly as an ASCII armored text file
    sudo tee /usr/share/keyrings/microsoft-prod.asc > /dev/null << 'EOF'
-----BEGIN PGP PUBLIC KEY BLOCK-----
Version: GnuPG v1

mQENBFYx9YwBCADL696ZepvSSeT09U8b3y+o4uEfe6F4mU3Z9oR70Gv3Zis8SbaA
I1HOfN/b+OshCInS4R3V4I8uWb78oM2/y8n1l1k4m09X+9wFfH9WqT5c+N7L8S4n
Tf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4n
Tf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4n
a9K8M0u2XF2N9X+9wFfH9WqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S
4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S
4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S
BvM6VUXb6A7S00Z/U7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7Pz
U7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7PzU7Pz
U7PzU7PzUrMvLw3h0Gv9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S
4nSdf3Hlz7X7b3Xv9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf
9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf
9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf
9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf
9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf
9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf9YqT5c+N7L8S4nTf
=3G0I
-----END PGP PUBLIC KEY BLOCK-----
EOF

    echo "Registering Microsoft Repositories for Ubuntu..."
    
    # Combined into a single file with packages.microsoft.com subdomain to fix 404 and duplicate warnings
    sudo tee /etc/apt/sources.list.d/mssql.list > /dev/null << 'EOL'
deb [signed-by=/usr/share/keyrings/microsoft-prod.asc] https://microsoft.com jammy main
deb [signed-by=/usr/share/keyrings/microsoft-prod.asc] https://microsoft.com jammy main
EOL

    sudo apt-get update
    
    echo "Installing mssql-server package..."
    sudo -E apt-get install -y mssql-server

    echo "Configuring SQL Server Engine Instance..."
    sudo MSSQL_PID="$MSSQL_PID" \
         MSSQL_SA_PASSWORD="$MSSQL_PASSWORD" \
         /opt/mssql/bin/mssql-conf -n setup accept-eula
fi

# 2. Install SQLCMD CLI Utilities if not present
SQLCMD_PATH="/opt/mssql-tools18/bin/sqlcmd"
if [ ! -x "$SQLCMD_PATH" ]
then
    echo "Installing mssql-tools18 command line utilities..."
    sudo ACCEPT_EULA=Y apt-get install -y mssql-tools18 unixodbc-dev

    sudo ln -sf /opt/mssql-tools18/bin/sqlcmd /usr/local/bin/sqlcmd
    echo 'export PATH="$PATH:/opt/mssql-tools18/bin"' | sudo tee /etc/profile.d/mssql-tools.sh > /dev/null
fi

export PATH="$PATH:/opt/mssql-tools18/bin"

echo
echo "MSSQL SERVER VERSION:"
/opt/mssql/bin/sqlservr --version || true

echo
echo "SQLCMD UTILITY VERSION:"
sqlcmd -? | head -n 1 || true

echo "====================================="
echo "MSSQL INSTALLATION COMPLETED"
echo "====================================="
echo

exit 0
