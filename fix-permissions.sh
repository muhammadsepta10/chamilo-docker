#!/bin/bash
# Script to fix permissions for Chamilo directories on host system
# Run this script from the project root directory

echo "Fixing permissions for Chamilo directories..."

# Fix permissions for courses directory (required for test course creation)
if [ -d "chamilo/app/courses" ]; then
    echo "Setting permissions for chamilo/app/courses..."
    chmod 777 chamilo/app/courses
    echo "✓ chamilo/app/courses permissions updated"
else
    echo "✗ chamilo/app/courses directory not found"
fi

# Fix permissions for other writable directories
for dir in "chamilo/app" "chamilo/app/cache" "chamilo/app/logs" "chamilo/app/upload" \
           "chamilo/main/default_course_document/images" "chamilo/main/lang" "chamilo/web"; do
    if [ -d "$dir" ]; then
        chmod -R 755 "$dir" 2>/dev/null || true
        echo "✓ $dir permissions updated"
    fi
done

echo ""
echo "Permissions fixed! You may need to run this with sudo if you get permission errors."
echo "Example: sudo ./fix-permissions.sh"

