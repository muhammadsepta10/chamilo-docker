#!/bin/bash
# Run this script with sudo to create web/build directory
# Example: sudo ./create-web-build-sudo.sh

cd "$(dirname "$0")"
mkdir -p chamilo/web/build
chmod -R 777 chamilo/web/build
echo "✓ Created chamilo/web/build with permissions 777"
