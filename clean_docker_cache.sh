#!/bin/bash

# Docker Cache Cleanup Script
# Clean Docker images, containers, volumes, networks and build cache

set -e

echo "🐳 Docker Cache Cleanup Tool"
echo "============================"

# Check if Docker is installed and running
if ! command -v docker &> /dev/null; then
    echo "❌ Error: Docker is not installed"
    exit 1
fi

if ! docker info &> /dev/null; then
    echo "❌ Error: Docker is not running, please start Docker first"
    exit 1
fi

# Show status before cleanup
echo ""
echo "📊 Current Docker Status:"
docker system df

echo ""
echo "🧹 Starting cleanup..."

# 1. Stop all running containers (optional)
RUNNING=$(docker ps -q)
if [ -n "$RUNNING" ]; then
    echo ""
    echo "⚠️  Found running containers:"
    docker ps --format "   {{.Names}} ({{.Image}})"
    echo ""
    read -p "   Stop all containers? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   → Stopping all containers..."
        docker stop $(docker ps -q) 2>/dev/null || true
    fi
fi

# 2. Remove stopped containers
echo ""
echo "   → Removing stopped containers..."
docker container prune -f

# 3. Remove dangling images (untagged images)
echo "   → Removing dangling images..."
docker image prune -f

# 4. Remove unused volumes
echo "   → Removing unused volumes..."
docker volume prune -f

# 5. Remove unused networks
echo "   → Removing unused networks..."
docker network prune -f

# 6. Clean build cache
echo "   → Cleaning build cache..."
docker builder prune -f 2>/dev/null || true

echo ""
echo "✅ Basic cleanup complete!"
echo ""
docker system df

# Deep cleanup options
echo ""
echo "━━━━━━━━━━━━━━━━━━━━━━"
echo "⚠️  Deep Cleanup Options (use with caution):"
echo ""
read -p "Remove all unused images (not just dangling)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   → Removing all unused images..."
    docker image prune -a -f
fi

read -p "Perform full system cleanup (remove all unused resources)? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   → Performing full system cleanup..."
    docker system prune -a -f --volumes
fi

echo ""
echo "============================"
echo "✅ Docker cleanup complete!"
echo ""
docker system df

echo ""
echo "💡 Tips:"
echo "   - docker system df     View disk usage"
echo "   - docker images        List all images"
echo "   - docker ps -a         List all containers"
