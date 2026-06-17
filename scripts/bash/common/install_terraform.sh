#!/bin/bash

set -e

source "$(dirname "$0")/set_project_root.sh"

TOOLS_DIR="$PROJECT_ROOT/tools/terraform"

mkdir -p "$TOOLS_DIR"

if [ -f "$TOOLS_DIR/terraform" ]
then
    echo "Terraform already installed"
    exit 0
fi

wget -O "$PROJECT_ROOT/tools/terraform.zip" \
https://releases.hashicorp.com/terraform/1.13.0/terraform_1.13.0_linux_amd64.zip

sudo apt-get update
sudo apt-get install -y unzip

unzip -o "$PROJECT_ROOT/tools/terraform.zip" -d "$TOOLS_DIR"

chmod +x "$TOOLS_DIR/terraform"

rm -f "$PROJECT_ROOT/tools/terraform.zip"

"$TOOLS_DIR/terraform" version

echo "Terraform Installed Successfully"

exit 0