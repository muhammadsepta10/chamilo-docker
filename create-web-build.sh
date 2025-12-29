#!/bin/bash
# Script to create web/build directory with correct permissions
# Run this script from the project root directory with sudo if needed

echo "Creating web/build directory for Chamilo..."

# Create directory if it doesn't exist
if [ ! -d "chamilo/web/build" ]; then
    mkdir -p chamilo/web/build
    echo "✓ Created chamilo/web/build directory"
else
    echo "✓ chamilo/web/build directory already exists"
fi

# Set permissions
if chmod -R 777 chamilo/web/build 2>/dev/null; then
    echo "✓ Set permissions on chamilo/web/build"
else
    echo "⚠ Could not set permissions automatically."
    echo "  Please run: sudo chmod -R 777 chamilo/web/build"
    exit 1
fi

echo ""
echo "Done! You can now restart the container:"
echo "  docker-compose restart chamilo_app"

