#!/bin/bash

# Node.js Package Manager Cache Cleanup Script
# Clean npm, pnpm, yarn caches

set -e

echo "📦 Node.js Package Manager Cache Cleanup Tool"
echo "=============================================="

# Clean npm cache
clean_npm() {
    if command -v npm &> /dev/null; then
        echo ""
        echo "🔷 npm Cache Cleanup"
        echo "   Cache directory: $(npm cache dir 2>/dev/null)"
        
        # Show cache size
        NPM_CACHE=$(npm cache dir 2>/dev/null)
        if [ -d "$NPM_CACHE" ]; then
            SIZE=$(du -sh "$NPM_CACHE" 2>/dev/null | cut -f1)
            echo "   Cache size: $SIZE"
        fi
        
        echo "   → Cleaning..."
        npm cache clean --force
        echo "   ✅ npm cache cleaned"
    else
        echo ""
        echo "⚪ npm not installed, skipping"
    fi
}

# Clean pnpm cache
clean_pnpm() {
    if command -v pnpm &> /dev/null; then
        echo ""
        echo "🟡 pnpm Cache Cleanup"
        
        # Show store path
        PNPM_STORE=$(pnpm store path 2>/dev/null)
        if [ -n "$PNPM_STORE" ] && [ -d "$PNPM_STORE" ]; then
            SIZE=$(du -sh "$PNPM_STORE" 2>/dev/null | cut -f1)
            echo "   Store directory: $PNPM_STORE"
            echo "   Store size: $SIZE"
        fi
        
        echo "   → Pruning unreferenced packages..."
        pnpm store prune
        
        # Clean cache directory
        PNPM_CACHE="$HOME/.cache/pnpm"
        if [ -d "$PNPM_CACHE" ]; then
            echo "   → Cleaning cache directory..."
            rm -rf "${PNPM_CACHE:?}"/*
        fi
        
        # macOS specific path
        MAC_PNPM_CACHE="$HOME/Library/Caches/pnpm"
        if [ -d "$MAC_PNPM_CACHE" ]; then
            echo "   → Cleaning macOS cache..."
            rm -rf "${MAC_PNPM_CACHE:?}"/*
        fi
        
        echo "   ✅ pnpm cache cleaned"
    else
        echo ""
        echo "⚪ pnpm not installed, skipping"
    fi
}

# Clean yarn cache
clean_yarn() {
    if command -v yarn &> /dev/null; then
        echo ""
        echo "🔵 yarn Cache Cleanup"
        
        # Detect yarn version
        YARN_VERSION=$(yarn --version 2>/dev/null)
        echo "   Yarn version: $YARN_VERSION"
        
        # Show cache directory
        YARN_CACHE=$(yarn cache dir 2>/dev/null)
        if [ -n "$YARN_CACHE" ] && [ -d "$YARN_CACHE" ]; then
            SIZE=$(du -sh "$YARN_CACHE" 2>/dev/null | cut -f1)
            echo "   Cache directory: $YARN_CACHE"
            echo "   Cache size: $SIZE"
        fi
        
        echo "   → Cleaning..."
        yarn cache clean
        echo "   ✅ yarn cache cleaned"
    else
        echo ""
        echo "⚪ yarn not installed, skipping"
    fi
}

# Clean node_modules related temp files
clean_node_temp() {
    echo ""
    echo "🗑️  Cleaning Temporary Files"
    
    # Clean npm temp directory
    NPM_TMP="/tmp/npm-*"
    if ls $NPM_TMP 1> /dev/null 2>&1; then
        echo "   → Cleaning npm temp files..."
        rm -rf /tmp/npm-* 2>/dev/null || true
    fi
    
    # Clean yarn temp directory
    YARN_TMP="/tmp/yarn--*"
    if ls $YARN_TMP 1> /dev/null 2>&1; then
        echo "   → Cleaning yarn temp files..."
        rm -rf /tmp/yarn--* 2>/dev/null || true
    fi
    
    echo "   ✅ Temp files cleaned"
}

# Execute cleanup
clean_npm
clean_pnpm
clean_yarn
clean_node_temp

echo ""
echo "=============================================="
echo "✅ All caches cleaned!"
echo ""
echo "💡 Tips:"
echo "   - npm cache verify  Check cache integrity"
echo "   - pnpm store status View store status"
echo "   - yarn cache list   View cache list"
