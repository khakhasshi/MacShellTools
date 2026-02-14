#!/bin/bash

# Cargo (Rust) Cache Cleanup Script
# Clean Cargo registry, cache and build artifacts

set -e

echo "🦀 Cargo (Rust) Cache Cleanup Tool"
echo "=================================="

# Check if Cargo is installed
if ! command -v cargo &> /dev/null; then
    echo "❌ Error: Cargo is not installed"
    exit 1
fi

# Show Rust version
echo ""
echo "Rust version:  $(rustc --version 2>/dev/null | awk '{print $2}')"
echo "Cargo version: $(cargo --version | awk '{print $2}')"

# Cargo directories
CARGO_HOME="${CARGO_HOME:-$HOME/.cargo}"
CARGO_REGISTRY="$CARGO_HOME/registry"
CARGO_GIT="$CARGO_HOME/git"
CARGO_BIN="$CARGO_HOME/bin"

# Calculate directory size
get_size() {
    if [ -d "$1" ]; then
        du -sh "$1" 2>/dev/null | cut -f1
    else
        echo "0B"
    fi
}

# Show status before cleanup
echo ""
echo "📊 Current Cache Status:"
echo "   CARGO_HOME:     $CARGO_HOME"
echo "   Total size:     $(get_size "$CARGO_HOME")"
echo "   Registry cache: $(get_size "$CARGO_REGISTRY")"
echo "   Git cache:      $(get_size "$CARGO_GIT")"

echo ""
echo "🧹 Starting cleanup..."

# Check if cargo-cache is installed
if command -v cargo-cache &> /dev/null; then
    echo "   → Using cargo-cache for cleanup..."
    cargo cache -a
else
    echo "   ℹ️  cargo-cache not installed, using manual cleanup"
    echo ""
    
    # 1. Clean registry cache (downloaded .crate files)
    CACHE_DIR="$CARGO_REGISTRY/cache"
    if [ -d "$CACHE_DIR" ]; then
        echo "   → Cleaning registry cache..."
        rm -rf "${CACHE_DIR:?}"/*
        echo "     ✅ Registry cache cleaned"
    fi
    
    # 2. Clean registry source (extracted source code)
    SRC_DIR="$CARGO_REGISTRY/src"
    if [ -d "$SRC_DIR" ]; then
        echo "   → Cleaning registry source..."
        rm -rf "${SRC_DIR:?}"/*
        echo "     ✅ Registry source cleaned"
    fi
    
    # 3. Clean Git checkouts
    GIT_CHECKOUTS="$CARGO_GIT/checkouts"
    if [ -d "$GIT_CHECKOUTS" ]; then
        echo "   → Cleaning Git checkouts..."
        rm -rf "${GIT_CHECKOUTS:?}"/*
        echo "     ✅ Git checkouts cleaned"
    fi
    
    # 4. Clean Git database
    GIT_DB="$CARGO_GIT/db"
    if [ -d "$GIT_DB" ]; then
        echo "   → Cleaning Git database..."
        rm -rf "${GIT_DB:?}"/*
        echo "     ✅ Git database cleaned"
    fi
fi

# 5. Clean current directory target (if exists)
if [ -d "./target" ]; then
    TARGET_SIZE=$(get_size "./target")
    echo ""
    echo "   Found target folder in current directory ($TARGET_SIZE)"
    read -p "   Clean it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        cargo clean 2>/dev/null || rm -rf ./target
        echo "     ✅ target cleaned"
    fi
fi

# 6. Search and clean all target directories (optional)
echo ""
read -p "Search and clean all Rust project target directories? (y/N): " -n 1 -r
echo
if [[ $REPLY =~ ^[Yy]$ ]]; then
    echo "   → Searching for target directories..."
    # Find target directories in directories containing Cargo.toml
    TARGETS=$(find "$HOME" -name "Cargo.toml" -type f 2>/dev/null | while read -r cargo_file; do
        target_dir="$(dirname "$cargo_file")/target"
        if [ -d "$target_dir" ]; then
            echo "$target_dir"
        fi
    done)
    
    if [ -n "$TARGETS" ]; then
        TOTAL_SIZE=0
        echo "   Found the following target directories:"
        echo "$TARGETS" | while read -r dir; do
            if [ -n "$dir" ]; then
                size=$(du -sh "$dir" 2>/dev/null | cut -f1)
                echo "     $dir ($size)"
            fi
        done
        
        echo ""
        read -p "   Confirm delete all target directories? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            echo "$TARGETS" | while read -r dir; do
                if [ -n "$dir" ] && [ -d "$dir" ]; then
                    rm -rf "$dir"
                fi
            done
            echo "     ✅ All target directories cleaned"
        fi
    else
        echo "   No target directories found"
    fi
fi

# Show status after cleanup
echo ""
echo "=================================="
echo "✅ Cargo cache cleanup complete!"
echo ""
echo "📊 Status after cleanup:"
echo "   CARGO_HOME total: $(get_size "$CARGO_HOME")"
echo "   Registry cache:   $(get_size "$CARGO_REGISTRY")"
echo "   Git cache:        $(get_size "$CARGO_GIT")"

echo ""
echo "💡 Tips:"
echo "   - cargo install cargo-cache  Install cache management tool"
echo "   - cargo cache -i             View cache details"
echo "   - cargo clean                Clean current project build"
