#!/bin/bash

echo "=========================================="
echo "Sefaria Export - Requirements Check"
echo "=========================================="
echo ""

all_ok=1

# Check Docker
echo "[1/3] Checking Docker..."
if command -v docker &> /dev/null; then
    echo "  [OK] $(docker --version)"
    
    # Check if Docker is running
    if docker info &> /dev/null; then
        echo "  [OK] Docker is running"
    else
        echo "  [X] Docker is NOT running"
        echo "      Please start Docker"
        all_ok=0
    fi
else
    echo "  [X] Docker is NOT installed"
    echo "      Install from: https://www.docker.com/products/docker-desktop"
    all_ok=0
fi

# Check docker-compose
echo ""
echo "[2/3] Checking docker-compose..."
if command -v docker-compose &> /dev/null; then
    echo "  [OK] $(docker-compose --version)"
else
    echo "  [X] docker-compose is NOT installed"
    echo "      Install from: https://docs.docker.com/compose/install/"
    all_ok=0
fi

# Check disk space
echo ""
echo "[3/3] Checking disk space..."
if command -v df &> /dev/null; then
    free_space=$(df -BG . | tail -1 | awk '{print $4}' | sed 's/G//')
    if [ "$free_space" -lt 20 ]; then
        echo "  [!] Warning: Only ${free_space}GB free space"
        echo "      Recommended: at least 20GB"
    else
        echo "  [OK] ${free_space}GB free space available"
    fi
else
    echo "  [?] Could not check disk space"
fi

echo ""
echo "=========================================="
if [ "$all_ok" -eq 1 ]; then
    echo "[OK] All requirements met!"
    echo "     You can run: ./run_local.sh"
else
    echo "[X] Some requirements are missing"
    echo "    Please install missing components"
fi
echo "=========================================="
