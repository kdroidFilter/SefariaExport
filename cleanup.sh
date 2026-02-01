#!/bin/bash

echo "=========================================="
echo "Sefaria Export - Cleanup Script"
echo "=========================================="
echo ""
echo "This will remove:"
echo "  - Docker containers and volumes"
echo "  - exports/ directory"
echo "  - releases/ directory"
echo "  - Temporary files"
echo ""
read -p "Are you sure? (y/N): " confirm

if [[ ! "$confirm" =~ ^[Yy]$ ]]; then
    echo "Cleanup cancelled."
    exit 0
fi

echo ""
echo "Stopping and removing Docker containers..."
docker-compose down -v

echo ""
echo "Removing output directories..."
rm -rf exports/
rm -rf releases/

echo ""
echo "Removing temporary files..."
rm -f ts.txt
rm -f ts_env.sh
rm -rf mongo_dump_pkg/
rm -rf Sefaria-Project/

echo ""
echo "=========================================="
echo "Cleanup completed!"
echo "=========================================="
