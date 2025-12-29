#!/bin/bash
# Script to download and setup Chamilo LMS
# Usage: ./setup-chamilo.sh [VERSION]
# Example: ./setup-chamilo.sh 1.11.26

set -e

CHAMILO_VERSION=${1:-"1.11.26"}
CHAMILO_DIR="chamilo"
DOWNLOAD_URL="https://github.com/chamilo/chamilo-lms/releases/download/v${CHAMILO_VERSION}/chamilo-lms-${CHAMILO_VERSION}.zip"

echo "========================================="
echo "Chamilo LMS Setup Script"
echo "========================================="
echo "Version: ${CHAMILO_VERSION}"
echo ""

# Check if chamilo directory already exists
if [ -d "$CHAMILO_DIR" ] && [ "$(ls -A $CHAMILO_DIR 2>/dev/null)" ]; then
    echo "✓ Chamilo directory already exists: $CHAMILO_DIR"
    echo "  Skipping download..."
    exit 0
fi

# Check if wget or curl is available
if command -v wget &> /dev/null; then
    DOWNLOAD_CMD="wget"
elif command -v curl &> /dev/null; then
    DOWNLOAD_CMD="curl"
else
    echo "❌ Error: wget or curl is required to download Chamilo"
    echo "   Install one of them:"
    echo "   - sudo apt-get install wget"
    echo "   - sudo apt-get install curl"
    exit 1
fi

# Check if unzip is available
if ! command -v unzip &> /dev/null; then
    echo "❌ Error: unzip is required to extract Chamilo"
    echo "   Install it: sudo apt-get install unzip"
    exit 1
fi

# Download Chamilo
ZIP_FILE="chamilo-lms-${CHAMILO_VERSION}.zip"
echo "Downloading Chamilo ${CHAMILO_VERSION}..."
echo "URL: ${DOWNLOAD_URL}"
echo ""

if [ "$DOWNLOAD_CMD" = "wget" ]; then
    wget --progress=bar:force "$DOWNLOAD_URL" -O "$ZIP_FILE" 2>&1 || {
        echo "❌ Download failed!"
        exit 1
    }
else
    curl -L --progress-bar "$DOWNLOAD_URL" -o "$ZIP_FILE" || {
        echo "❌ Download failed!"
        exit 1
    }
fi

if [ ! -f "$ZIP_FILE" ]; then
    echo "❌ Error: Failed to download Chamilo"
    exit 1
fi

echo ""
echo "Extracting Chamilo..."

# Extract Chamilo
unzip -q "$ZIP_FILE" -d temp_extract 2>/dev/null || {
    echo "❌ Error: Failed to extract Chamilo"
    rm -f "$ZIP_FILE"
    exit 1
}

# Move extracted files to chamilo directory
if [ -d "temp_extract/chamilo-lms-${CHAMILO_VERSION}" ]; then
    mv "temp_extract/chamilo-lms-${CHAMILO_VERSION}" "$CHAMILO_DIR"
elif [ -d "temp_extract/chamilo" ]; then
    mv "temp_extract/chamilo" "$CHAMILO_DIR"
else
    # Find the actual extracted directory
    EXTRACTED_DIR=$(find temp_extract -maxdepth 1 -type d ! -path temp_extract | head -1)
    if [ -n "$EXTRACTED_DIR" ]; then
        mv "$EXTRACTED_DIR" "$CHAMILO_DIR"
    else
        echo "❌ Error: Could not find extracted Chamilo directory"
        rm -rf temp_extract
        rm -f "$ZIP_FILE"
        exit 1
    fi
fi

# Cleanup
rm -rf temp_extract
rm -f "$ZIP_FILE"

# Create web/build directory with correct permissions
echo "Creating web/build directory..."
mkdir -p "$CHAMILO_DIR/web/build"
if chmod -R 777 "$CHAMILO_DIR/web/build" 2>/dev/null; then
    echo "✓ Set permissions on web/build"
else
    echo "⚠ Warning: Could not set permissions automatically"
    echo "  Please run: sudo chmod -R 777 $CHAMILO_DIR/web/build"
fi

echo ""
echo "========================================="
echo "✓ Chamilo ${CHAMILO_VERSION} downloaded successfully!"
echo "========================================="
echo ""
echo "Location: $CHAMILO_DIR/"
echo ""
echo "Next steps:"
echo "  docker compose build"
echo "  docker compose up -d"
echo ""

