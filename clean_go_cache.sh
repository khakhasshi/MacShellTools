#!/bin/bash

# Go Module Cache Cleanup Script
# Clean Go module cache and build cache

set -e

echo "🐹 Go Cache Cleanup Tool"
echo "========================"

# Check if Go is installed
if ! command -v go &> /dev/null; then
    echo "❌ Error: Go is not installed"
    exit 1
fi

# Show Go version
echo ""
echo "Go version: $(go version | awk '{print $3}')"

# Get cache directories
GOMODCACHE=$(go env GOMODCACHE)
GOCACHE=$(go env GOCACHE)
GOPATH=$(go env GOPATH)

# Show status before cleanup
echo ""
echo "📊 Current Cache Status:"

if [ -d "$GOMODCACHE" ]; then
    MOD_SIZE=$(du -sh "$GOMODCACHE" 2>/dev/null | cut -f1)
    echo "   Module cache (GOMODCACHE): $MOD_SIZE"
    echo "   Path: $GOMODCACHE"
fi

if [ -d "$GOCACHE" ]; then
    BUILD_SIZE=$(du -sh "$GOCACHE" 2>/dev/null | cut -f1)
    echo "   Build cache (GOCACHE):     $BUILD_SIZE"
    echo "   Path: $GOCACHE"
fi

echo ""
echo "🧹 Starting cleanup..."

# 1. Clean build cache
echo "   → Cleaning build cache..."
go clean -cache
echo "     ✅ Build cache cleaned"

# 2. Clean test cache
echo "   → Cleaning test cache..."
go clean -testcache
echo "     ✅ Test cache cleaned"

# 3. Clean fuzz test cache
echo "   → Cleaning fuzz test cache..."
go clean -fuzzcache 2>/dev/null || true
echo "     ✅ Fuzz test cache cleaned"

# 4. Module cache cleanup (requires confirmation)
echo ""
echo "⚠️  Module Cache Cleanup Options:"
if [ -d "$GOMODCACHE" ]; then
    MOD_SIZE=$(du -sh "$GOMODCACHE" 2>/dev/null | cut -f1)
    echo "   Module cache size: $MOD_SIZE"
    echo ""
    read -p "   Clean module cache? This will delete all downloaded dependencies (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        echo "   → Cleaning module cache..."
        go clean -modcache
        echo "     ✅ Module cache cleaned"
    else
        echo "     ⏭️  Skipped module cache cleanup"
    fi
fi

# 5. Clean GOPATH/pkg directory (legacy)
PKG_DIR="$GOPATH/pkg"
if [ -d "$PKG_DIR" ]; then
    PKG_SIZE=$(du -sh "$PKG_DIR" 2>/dev/null | cut -f1)
    if [ "$PKG_SIZE" != "0B" ] && [ "$PKG_SIZE" != "0" ]; then
        echo ""
        echo "   Found GOPATH/pkg directory ($PKG_SIZE)"
        read -p "   Clean it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            rm -rf "${PKG_DIR:?}"/*
            echo "     ✅ GOPATH/pkg cleaned"
        fi
    fi
fi

# Show status after cleanup
echo ""
echo "========================"
echo "✅ Go cache cleanup complete!"
echo ""
echo "📊 Status after cleanup:"

if [ -d "$GOMODCACHE" ]; then
    MOD_SIZE=$(du -sh "$GOMODCACHE" 2>/dev/null | cut -f1)
    echo "   Module cache: $MOD_SIZE"
fi

if [ -d "$GOCACHE" ]; then
    BUILD_SIZE=$(du -sh "$GOCACHE" 2>/dev/null | cut -f1)
    echo "   Build cache:  $BUILD_SIZE"
fi

echo ""
echo "💡 Tips:"
echo "   - go env GOMODCACHE  View module cache path"
echo "   - go env GOCACHE     View build cache path"
echo "   - go mod tidy        Clean unused dependencies in project"
