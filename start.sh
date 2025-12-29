#!/bin/bash
# Main startup script that ensures Chamilo is downloaded before starting Docker
# Usage: ./start.sh [docker-compose-args]
# Example: ./start.sh up -d

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
cd "$SCRIPT_DIR"

echo "========================================="
echo "Chamilo Docker Startup Script"
echo "========================================="
echo ""

# Check if Docker is available
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed or not in PATH"
    echo "   Install Docker: https://docs.docker.com/get-docker/"
    exit 1
fi

# Check if docker compose is available
if ! docker compose version &> /dev/null && ! command -v docker-compose &> /dev/null; then
    echo "❌ Error: Docker Compose is not installed or not in PATH"
    echo "   Install Docker Compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Check if Chamilo is downloaded
if [ ! -d "chamilo" ] || [ -z "$(ls -A chamilo 2>/dev/null)" ]; then
    echo "Chamilo not found. Downloading..."
    echo ""
    
    # Make setup script executable
    chmod +x setup-chamilo.sh
    
    # Run setup script
    if ! ./setup-chamilo.sh; then
        echo "❌ Failed to download Chamilo"
        exit 1
    fi
    echo ""
fi

# Ensure web/build directory exists with correct permissions
if [ ! -d "chamilo/web/build" ]; then
    echo "Creating web/build directory..."
    mkdir -p chamilo/web/build
    if chmod -R 777 chamilo/web/build 2>/dev/null; then
        echo "✓ Created web/build directory"
    else
        echo "⚠ Warning: Could not set permissions automatically"
        echo "  Please run: sudo chmod -R 777 chamilo/web/build"
    fi
    echo ""
fi

# Use docker compose (v2) or docker-compose (v1)
if docker compose version &> /dev/null; then
    COMPOSE_CMD="docker compose"
else
    COMPOSE_CMD="docker-compose"
fi

# If no arguments provided, default to "up -d"
if [ $# -eq 0 ]; then
    echo "Building Docker images..."
    $COMPOSE_CMD build
    
    echo ""
    echo "Starting containers..."
    $COMPOSE_CMD up -d
    
    echo ""
    echo "========================================="
    echo "✓ Chamilo Docker containers started!"
    echo "========================================="
    echo ""
    echo "Access the application at: http://localhost:1234"
    echo "View logs: $COMPOSE_CMD logs -f"
    echo "Stop containers: $COMPOSE_CMD down"
    echo ""
else
    # Pass all arguments to docker compose
    echo "Running: $COMPOSE_CMD $@"
    echo ""
    $COMPOSE_CMD "$@"
fi

