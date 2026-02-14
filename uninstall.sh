#!/bin/bash

# MacShellTool Uninstallation Script

PREFIX="${PREFIX:-/usr/local}"
BINDIR="${BINDIR:-$PREFIX/bin}"
LIBDIR="${LIBDIR:-$PREFIX/lib/shelltools}"

echo "Uninstalling MacShellTool..."

# Remove files
rm -f "$BINDIR/tool"
rm -rf "$LIBDIR"

echo "✓ MacShellTool uninstalled."
