#!/bin/bash
# Quick fix script to verify and fix configuration.php
# Usage: ./fix-installation-page.sh

set -e

echo "========================================="
echo "Fix Installation Page Issue"
echo "========================================="
echo ""

# Check if configuration.php exists
CONFIG_FILE="./chamilo/app/config/configuration.php"

if [ ! -f "$CONFIG_FILE" ]; then
    echo "✗ Configuration file not found: $CONFIG_FILE"
    echo ""
    echo "Looking for backup configuration file..."
    
    # Check in backup directory
    BACKUP_CONFIG=$(find . -name "configuration.php" -type f 2>/dev/null | grep -v vendor | head -1)
    
    if [ ! -z "$BACKUP_CONFIG" ]; then
        echo "Found: $BACKUP_CONFIG"
        read -p "Copy to $CONFIG_FILE? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            mkdir -p "$(dirname "$CONFIG_FILE")"
            cp "$BACKUP_CONFIG" "$CONFIG_FILE"
            echo "✓ Configuration file copied"
        else
            echo "Please copy manually: cp $BACKUP_CONFIG $CONFIG_FILE"
            exit 1
        fi
    else
        echo "✗ No backup configuration file found."
        echo ""
        echo "Options:"
        echo "1. If you have a backup, copy it manually:"
        echo "   cp /path/to/backup/configuration.php $CONFIG_FILE"
        echo ""
        echo "2. Or re-run import script:"
        echo "   cd chamilo-backup-* && ./import-installation.sh"
        exit 1
    fi
else
    echo "✓ Configuration file exists: $CONFIG_FILE"
    echo "  - File size: $(du -h "$CONFIG_FILE" | cut -f1)"
    echo "  - Permissions: $(ls -l "$CONFIG_FILE" | awk '{print $1, $3, $4}')"
fi

# Check if file is readable
if [ ! -r "$CONFIG_FILE" ]; then
    echo "⚠ Configuration file is not readable. Fixing permissions..."
    chmod 644 "$CONFIG_FILE" 2>/dev/null || sudo chmod 644 "$CONFIG_FILE"
    echo "✓ Permissions fixed"
fi

# Verify configuration file content
echo ""
echo "Verifying configuration file content..."
if grep -q "\$_configuration\['root_web'\]" "$CONFIG_FILE"; then
    ROOT_WEB=$(grep "\$_configuration\['root_web'\]" "$CONFIG_FILE" | head -1 | sed "s/.*'\(.*\)'.*/\1/" || echo "")
    echo "✓ Configuration file contains root_web: $ROOT_WEB"
else
    echo "⚠ Warning: Configuration file may be invalid (root_web not found)"
fi

# Check if file exists in container
echo ""
echo "Checking in Docker container..."
if docker compose ps | grep -q "chamilo_app.*Up"; then
    if docker compose exec chamilo_app test -f /var/www/html/app/config/configuration.php; then
        echo "✓ Configuration file exists in container"
    else
        echo "⚠ Configuration file NOT found in container"
        echo "  Copying to container..."
        docker compose cp "$CONFIG_FILE" chamilo_app:/var/www/html/app/config/configuration.php
        echo "✓ Configuration file copied to container"
    fi
    
    # Fix permissions in container
    echo "Fixing permissions in container..."
    docker compose exec chamilo_app chown www-data:www-data /var/www/html/app/config/configuration.php 2>/dev/null || true
    docker compose exec chamilo_app chmod 644 /var/www/html/app/config/configuration.php 2>/dev/null || true
    echo "✓ Permissions fixed"
    
    # Restart container
    echo ""
    echo "Restarting container to apply changes..."
    docker compose restart chamilo_app
    echo "✓ Container restarted"
else
    echo "⚠ Container is not running. Start it first:"
    echo "  docker compose up -d"
fi

echo ""
echo "========================================="
echo "✓ Fix completed!"
echo "========================================="
echo ""
echo "Try accessing the website again."
echo "If still showing installation page, check:"
echo "  1. Configuration file path: $CONFIG_FILE"
echo "  2. Container logs: docker compose logs chamilo_app"
echo "  3. File permissions: ls -la $CONFIG_FILE"

