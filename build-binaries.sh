#!/bin/bash
# Build script for zig-pug multi-platform binaries

set -e

echo "🚀 Building zig-pug for multiple platforms..."
echo ""

# Colors
GREEN='\033[0;32m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Clean previous builds
echo "🧹 Cleaning previous builds..."
rm -rf zig-out/bin/*
echo ""

# Build for all platforms
echo "📦 Building binaries..."
echo ""

# Linux x86_64
echo -e "${BLUE}Building for Linux x86_64...${NC}"
zig build cross-linux-x86_64
echo -e "${GREEN}✓ Linux x86_64 complete${NC}"
echo ""

# Linux aarch64 (ARM)
echo -e "${BLUE}Building for Linux aarch64 (ARM64)...${NC}"
zig build cross-linux-aarch64
echo -e "${GREEN}✓ Linux aarch64 complete${NC}"
echo ""

# Windows x86_64
echo -e "${BLUE}Building for Windows x86_64...${NC}"
zig build cross-windows-x86_64
echo -e "${GREEN}✓ Windows x86_64 complete${NC}"
echo ""

# macOS x86_64 (Intel)
echo -e "${BLUE}Building for macOS x86_64 (Intel)...${NC}"
zig build cross-macos-x86_64
echo -e "${GREEN}✓ macOS x86_64 complete${NC}"
echo ""

# macOS aarch64 (Apple Silicon)
echo -e "${BLUE}Building for macOS aarch64 (Apple Silicon)...${NC}"
zig build cross-macos-aarch64
echo -e "${GREEN}✓ macOS aarch64 complete${NC}"
echo ""

# Create release directory
RELEASE_DIR="zig-out/release"
mkdir -p "$RELEASE_DIR"

# Package binaries
echo "📦 Packaging binaries..."
echo ""

# Function to create archive
create_archive() {
    local platform=$1
    local binary_name=$2
    local archive_name="zig-pug-v0.2.0-${platform}"

    echo "Creating ${archive_name}..."

    mkdir -p "$RELEASE_DIR/$archive_name"

    # Copy binary
    cp "zig-out/bin/${platform}/${binary_name}" "$RELEASE_DIR/$archive_name/"

    # Copy documentation
    cp README.md "$RELEASE_DIR/$archive_name/"
    cp LICENSE "$RELEASE_DIR/$archive_name/" 2>/dev/null || echo "No LICENSE file found"

    # Create archive
    cd "$RELEASE_DIR"
    tar czf "${archive_name}.tar.gz" "$archive_name"
    cd - > /dev/null

    # Clean up directory
    rm -rf "$RELEASE_DIR/$archive_name"

    echo -e "${GREEN}✓ Created ${archive_name}.tar.gz${NC}"
}

# Create archives for each platform
create_archive "linux-x86_64" "zpug"
create_archive "linux-aarch64" "zpug"
create_archive "windows-x86_64" "zpug.exe"
create_archive "macos-x86_64" "zpug"
create_archive "macos-aarch64" "zpug"

echo ""
echo "✅ Build complete!"
echo ""
echo "Binaries available in:"
echo "  - zig-out/bin/linux-x86_64/zpug"
echo "  - zig-out/bin/linux-aarch64/zpug"
echo "  - zig-out/bin/windows-x86_64/zpug.exe"
echo "  - zig-out/bin/macos-x86_64/zpug"
echo "  - zig-out/bin/macos-aarch64/zpug"
echo ""
echo "Release archives available in:"
echo "  - zig-out/release/zig-pug-v0.2.0-*.tar.gz"
echo ""

# Show sizes
echo "Binary sizes:"
du -h zig-out/bin/*/zpug* 2>/dev/null | sed 's/^/  /'
echo ""

echo "Release archive sizes:"
du -h zig-out/release/*.tar.gz 2>/dev/null | sed 's/^/  /'
echo ""

echo "🎉 Done!"
