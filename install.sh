#!/bin/bash

# MacShellTool Installation Script

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
LIBDIR="${LIBDIR:-$PREFIX/lib/shelltools}"

# Colors
GREEN='\033[0;32m'
NC='\033[0m'

echo "Installing MacShellTool..."

# Create directories
mkdir -p "$BINDIR"
mkdir -p "$LIBDIR"

# Copy scripts to lib directory
cp clean_*.sh "$LIBDIR/"
cp check_network.sh "$LIBDIR/"
cp port_killer.sh "$LIBDIR/"

# Copy main tool and update TOOL_DIR path
sed "s|TOOL_DIR=\"\$HOME/ShellTools\"|TOOL_DIR=\"$LIBDIR\"|g" tool > "$BINDIR/tool"

# Set permissions
chmod +x "$BINDIR/tool"
chmod +x "$LIBDIR"/*.sh

echo -e "${GREEN}✓ MacShellTool installed successfully!${NC}"
echo ""
echo "Run 'tool' to start."
