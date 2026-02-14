#!/bin/bash

# Ruby Gems Cache Cleanup Script
# Clean Ruby gems cache and old versions

set -e

echo "💎 Ruby Gems Cache Cleanup Tool"
echo "================================"

# Check if gem is installed
if ! command -v gem &> /dev/null; then
    echo "❌ Error: Ruby/gem is not installed"
    exit 1
fi

# Show Ruby version
echo ""
echo "Ruby version: $(ruby --version | awk '{print $2}')"
echo "Gem version:  $(gem --version)"

# Get gem directory
GEM_HOME=$(gem environment gemdir 2>/dev/null)
GEM_CACHE="$GEM_HOME/cache"

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
echo "   GEM_HOME:   $GEM_HOME"
echo "   Total size: $(get_size "$GEM_HOME")"
echo "   Cache size: $(get_size "$GEM_CACHE")"

# Count old version gems
OLD_GEMS=$(gem cleanup --dryrun 2>/dev/null | grep -c "would uninstall" || echo "0")
echo "   Old version gems: $OLD_GEMS"

echo ""
echo "🧹 Starting cleanup..."

# 1. Clean gem cache (downloaded .gem files)
if [ -d "$GEM_CACHE" ]; then
    echo "   → Cleaning gem cache..."
    rm -rf "${GEM_CACHE:?}"/*.gem 2>/dev/null || true
    echo "     ✅ gem cache cleaned"
fi

# 2. Clean old version gems
echo "   → Cleaning old version gems..."
gem cleanup 2>/dev/null || {
    echo "     ⚠️  Some gems failed to clean (may need sudo)"
}
echo "     ✅ Old version gems cleaned"

# 3. Clean Bundler cache
BUNDLER_CACHE="$HOME/.bundle/cache"
if [ -d "$BUNDLER_CACHE" ]; then
    echo "   → Cleaning Bundler cache..."
    rm -rf "${BUNDLER_CACHE:?}"/*
    echo "     ✅ Bundler cache cleaned"
fi

# 4. Clean Bundler temp files
BUNDLER_TMP="$HOME/.bundle/tmp"
if [ -d "$BUNDLER_TMP" ]; then
    echo "   → Cleaning Bundler temp files..."
    rm -rf "${BUNDLER_TMP:?}"/*
    echo "     ✅ Bundler temp files cleaned"
fi

# 5. Clean system-level gem cache (macOS)
SYSTEM_GEM_CACHE="/Library/Ruby/Gems/*/cache"
if ls $SYSTEM_GEM_CACHE 1> /dev/null 2>&1; then
    echo ""
    echo "   Found system-level gem cache"
    read -p "   Clean it? (requires sudo) (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        sudo rm -rf /Library/Ruby/Gems/*/cache/*.gem 2>/dev/null || true
        echo "     ✅ System-level cache cleaned"
    fi
fi

# 6. Clean rbenv/rvm cache (if using)
# rbenv
if [ -d "$HOME/.rbenv/cache" ]; then
    echo "   → Cleaning rbenv cache..."
    rm -rf "$HOME/.rbenv/cache"/*
    echo "     ✅ rbenv cache cleaned"
fi

# rvm
if [ -d "$HOME/.rvm/archives" ]; then
    RVM_SIZE=$(get_size "$HOME/.rvm/archives")
    echo ""
    echo "   Found RVM archives ($RVM_SIZE)"
    read -p "   Clean it? (y/N): " -n 1 -r
    echo
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        rm -rf "$HOME/.rvm/archives"/*
        echo "     ✅ RVM archives cleaned"
    fi
fi

# 7. Clean CocoaPods cache (if installed)
if command -v pod &> /dev/null; then
    POD_CACHE="$HOME/Library/Caches/CocoaPods"
    if [ -d "$POD_CACHE" ]; then
        POD_SIZE=$(get_size "$POD_CACHE")
        echo ""
        echo "   Found CocoaPods cache ($POD_SIZE)"
        read -p "   Clean it? (y/N): " -n 1 -r
        echo
        if [[ $REPLY =~ ^[Yy]$ ]]; then
            pod cache clean --all 2>/dev/null || rm -rf "${POD_CACHE:?}"/*
            echo "     ✅ CocoaPods cache cleaned"
        fi
    fi
fi

# Show status after cleanup
echo ""
echo "================================"
echo "✅ Ruby Gems cleanup complete!"
echo ""
echo "📊 Status after cleanup:"
echo "   GEM_HOME total: $(get_size "$GEM_HOME")"
echo "   Cache size:     $(get_size "$GEM_CACHE")"

echo ""
echo "💡 Tips:"
echo "   - gem list           List installed gems"
echo "   - gem cleanup -d     Preview old versions to clean"
echo "   - bundle clean       Clean unused Bundler gems"
