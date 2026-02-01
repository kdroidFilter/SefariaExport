#!/bin/bash

echo "=========================================="
echo "Sefaria Export - Local Docker Runner"
echo "=========================================="

# Check if Docker is running
if ! docker info > /dev/null 2>&1; then
    echo "ERROR: Docker is not running. Please start Docker and try again."
    exit 1
fi

# Check if docker-compose is available
if ! command -v docker-compose &> /dev/null; then
    echo "ERROR: docker-compose is not installed."
    echo "Please install docker-compose: https://docs.docker.com/compose/install/"
    exit 1
fi

# Create .env file if it doesn't exist
if [ ! -f .env ]; then
    echo "Creating .env file from .env.example..."
    cp .env.example .env
    echo "Please edit .env file if you need to customize settings."
fi

# Create directories for outputs
mkdir -p exports
mkdir -p releases

echo ""
echo "Building Docker images..."
docker-compose build

echo ""
echo "Starting services..."
docker-compose up --abort-on-container-exit

echo ""
echo "=========================================="
echo "Workflow finished!"
echo "=========================================="
echo ""
echo "Check the following directories for outputs:"
echo "  - ./exports/    - Exported files"
echo "  - ./releases/   - Release archives"
