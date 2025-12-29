#!/bin/bash
set -e

# Set permissions for Chamilo directories that need to be writable
# Only set permissions on directory level, not recursive to avoid delays
WRITABLE_DIRS=(
    "/var/www/html/app"
    "/var/www/html/app/courses"
    "/var/www/html/app/config"
    "/var/www/html/main/default_course_document/images"
    "/var/www/html/main/lang"
    "/var/www/html/web"
    "/var/www/html/app/cache"
    "/var/www/html/app/logs"
    "/var/www/html/app/upload"
)

# Set directory permissions to allow writing
# For volume mounts, we try to set permissions, but may fail due to host filesystem
for dir in "${WRITABLE_DIRS[@]}"; do
    if [ -d "$dir" ]; then
        chown www-data:www-data "$dir" 2>/dev/null || true
        # Try to set writable permissions
        chmod 755 "$dir" 2>/dev/null || true
        # For courses and cache directories, ensure they're writable (using named volumes)
        if [ "$dir" = "/var/www/html/app/courses" ] || [ "$dir" = "/var/www/html/app/cache" ] || [ "$dir" = "/var/www/html/app/logs" ]; then
            chmod 755 "$dir" 2>/dev/null || true
        fi
    fi
done

# Special handling for courses directory: ensure it's writable
# If we can't change permissions due to volume mount, create a workaround
COURSES_DIR="/var/www/html/app/courses"
if [ -d "$COURSES_DIR" ] && [ ! -w "$COURSES_DIR" ]; then
    # Try to set ACL or use setfacl if available
    setfacl -R -m u:www-data:rwx "$COURSES_DIR" 2>/dev/null || true
    setfacl -R -d -m u:www-data:rwx "$COURSES_DIR" 2>/dev/null || true
fi

# Ensure cache structure exists for Doctrine proxies
CACHE_DIR="/var/www/html/app/cache"
if [ -d "$CACHE_DIR" ] && [ -w "$CACHE_DIR" ]; then
    mkdir -p "$CACHE_DIR/__CG__" 2>/dev/null || true
    chown www-data:www-data "$CACHE_DIR/__CG__" 2>/dev/null || true
    chmod 755 "$CACHE_DIR/__CG__" 2>/dev/null || true
fi

# Ensure web/build directory exists and is writable
WEB_BUILD_DIR="/var/www/html/web/build"
if [ ! -d "$WEB_BUILD_DIR" ]; then
    mkdir -p "$WEB_BUILD_DIR" 2>/dev/null || true
fi
if [ -d "$WEB_BUILD_DIR" ]; then
    chown www-data:www-data "$WEB_BUILD_DIR" 2>/dev/null || true
    chmod 755 "$WEB_BUILD_DIR" 2>/dev/null || true
fi

# Ensure profile.conf.php exists (create if not exists)
if [ ! -f "/var/www/html/app/config/profile.conf.php" ]; then
    cat > /var/www/html/app/config/profile.conf.php << 'EOF'
<?php

/**
 *	This file holds the configuration constants and variables
 *	for the user profile tool.
 *
 *	@package chamilo.configuration
 */

// Autentication, password
define('CHECK_PASS_EASY_TO_FIND', true);

$profileIsEditable = true;

// User photos
define('PREFIX_IMAGE_FILENAME_WITH_UID', true);
define('RESIZE_IMAGE_TO_THIS_HEIGTH', 180);
define('IMAGE_THUMBNAIL_WIDTH', 100);

// Replacing user photos
define('KEEP_THE_NAME_WHEN_CHANGE_IMAGE', true);
define('KEEP_THE_OLD_IMAGE_AFTER_CHANGE', true);

// Official code
define('CONFVAL_ASK_FOR_OFFICIAL_CODE', true);
define('CONFVAL_CHECK_OFFICIAL_CODE', false);

// For stats
define('NB_LINE_OF_EVENTS', 15);
EOF
    chown www-data:www-data /var/www/html/app/config/profile.conf.php 2>/dev/null || true
    chmod 644 /var/www/html/app/config/profile.conf.php 2>/dev/null || true
fi

# Ensure web/build directory exists (try to create if web is writable)
WEB_BUILD_DIR="/var/www/html/web/build"
WEB_DIR="/var/www/html/web"
if [ -d "$WEB_DIR" ] && [ -w "$WEB_DIR" ]; then
    if [ ! -d "$WEB_BUILD_DIR" ]; then
        mkdir -p "$WEB_BUILD_DIR" 2>/dev/null || true
    fi
    if [ -d "$WEB_BUILD_DIR" ]; then
        chown www-data:www-data "$WEB_BUILD_DIR" 2>/dev/null || true
        chmod 755 "$WEB_BUILD_DIR" 2>/dev/null || true
    fi
fi

# Execute the original entrypoint immediately
exec "$@"

