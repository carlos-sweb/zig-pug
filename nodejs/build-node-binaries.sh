#!/usr/bin/env bash
# Build precompiled .node binaries for multiple platforms
# This script builds the native addon for each platform and stores them

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
BINARIES_DIR="$SCRIPT_DIR/prebuilt-binaries"

echo "Building precompiled .node binaries..."
echo "Project root: $PROJECT_ROOT"
echo "Binaries directory: $BINARIES_DIR"

# Clean previous builds
rm -rf "$BINARIES_DIR"
mkdir -p "$BINARIES_DIR"

# First, ensure prebuilt libraries exist
if [ ! -d "$SCRIPT_DIR/prebuilts" ]; then
    echo "Error: prebuilts/ directory not found. Run build-prebuilts.sh first."
    exit 1
fi

cd "$SCRIPT_DIR"

# Define target platforms
# Format: "platform-arch:node-platform:node-arch"
TARGETS=(
    "linux-x64:linux:x64"
    "linux-arm64:linux:arm64"
    "darwin-x64:darwin:x64"
    "darwin-arm64:darwin:arm64"
    "win32-x64:win32:x64"
)

echo ""
echo "Note: Cross-compilation of .node files requires platform-specific builds."
echo "This script will only build for the current platform: $(uname -s)-$(uname -m)"
echo ""
echo "For a full multi-platform build, you need to run this on each platform or use CI/CD."
echo ""

# Detect current platform
CURRENT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
CURRENT_ARCH=$(uname -m)

# Normalize architecture names
case "$CURRENT_ARCH" in
    x86_64) CURRENT_ARCH="x64" ;;
    aarch64|arm64) CURRENT_ARCH="arm64" ;;
esac

case "$CURRENT_OS" in
    darwin) CURRENT_OS="darwin" ;;
    linux) CURRENT_OS="linux" ;;
    mingw*|msys*|cygwin*) CURRENT_OS="win32" ;;
esac

CURRENT_PLATFORM="${CURRENT_OS}-${CURRENT_ARCH}"

echo "Building for current platform: $CURRENT_PLATFORM"
echo ""

# Clean and rebuild for current platform
npm run rebuild

# Check if build succeeded
if [ -f "build/Release/zigpug.node" ]; then
    mkdir -p "$BINARIES_DIR/$CURRENT_PLATFORM"
    cp "build/Release/zigpug.node" "$BINARIES_DIR/$CURRENT_PLATFORM/"
    size=$(du -h "$BINARIES_DIR/$CURRENT_PLATFORM/zigpug.node" | cut -f1)
    echo "✓ Created $CURRENT_PLATFORM/zigpug.node ($size)"
else
    echo "✗ Failed to create zigpug.node"
    exit 1
fi

echo ""
echo "========================================="
echo "Build complete for current platform!"
echo "========================================="
echo ""
echo "To build for other platforms, run this script on each target platform,"
echo "or use GitHub Actions / CI/CD to build all platforms automatically."
echo ""
ls -lh "$BINARIES_DIR"/*/*.node 2>/dev/null || true
