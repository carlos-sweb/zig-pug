#!/usr/bin/env bash
# Build Node.js addon for current platform only

set -e

# Colores
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  Building Node.js Addon (.node) for Current Platform     ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Check Node.js
if ! command -v node &> /dev/null; then
    echo -e "${YELLOW}⚠️  Node.js not found. Please install Node.js first.${NC}"
    exit 1
fi

echo "📍 Node.js version: $(node --version)"
echo "📍 npm version: $(npm --version)"
echo ""

# Detect platform
CURRENT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
CURRENT_ARCH=$(uname -m)

case "$CURRENT_ARCH" in
    x86_64) CURRENT_ARCH="x64" ;;
    aarch64|arm64) CURRENT_ARCH="arm64" ;;
esac

case "$CURRENT_OS" in
    darwin) CURRENT_OS="darwin" ;;
    linux) CURRENT_OS="linux" ;;
    mingw*|msys*|cygwin*) CURRENT_OS="win32" ;;
esac

PLATFORM="${CURRENT_OS}-${CURRENT_ARCH}"
echo "🖥️  Platform: ${PLATFORM}"
echo ""

# Build static library first (required by addon)
echo -e "${BLUE}Step 1/3: Building static library...${NC}"
zig build lib-static -Doptimize=ReleaseFast

if [ ! -d "nodejs/prebuilts" ]; then
    echo -e "${YELLOW}⚠️  Static libraries not found. Building them first...${NC}"
    ./build-all.sh --nodejs-only
fi
echo -e "${GREEN}✓ Static library ready${NC}"
echo ""

# Install npm dependencies
echo -e "${BLUE}Step 2/3: Installing npm dependencies...${NC}"
cd nodejs
npm install
echo -e "${GREEN}✓ Dependencies installed${NC}"
echo ""

# Build addon
echo -e "${BLUE}Step 3/3: Building Node.js addon...${NC}"
npm run rebuild

if [ -f "build/Release/zigpug.node" ]; then
    size=$(du -h "build/Release/zigpug.node" | cut -f1)
    echo -e "${GREEN}✓ Addon built successfully (${size})${NC}"

    # Copy to prebuilt-binaries
    mkdir -p "prebuilt-binaries/${PLATFORM}"
    cp "build/Release/zigpug.node" "prebuilt-binaries/${PLATFORM}/"
    echo -e "${GREEN}✓ Copied to prebuilt-binaries/${PLATFORM}/${NC}"
    echo ""

    # Test it
    echo -e "${BLUE}Testing addon...${NC}"
    if npm test; then
        echo -e "${GREEN}✓ Addon tests passed${NC}"
    else
        echo -e "${YELLOW}⚠️  Addon tests failed${NC}"
    fi
else
    echo -e "${RED}✗ Failed to build addon${NC}"
    exit 1
fi

cd ..

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ ADDON BUILD COMPLETED                        ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""
echo -e "${BLUE}📦 Addon available at:${NC}"
echo "   nodejs/build/Release/zigpug.node"
echo "   nodejs/prebuilt-binaries/${PLATFORM}/zigpug.node"
echo ""
echo -e "${YELLOW}💡 Note:${NC} This addon only works on ${PLATFORM}"
echo -e "${YELLOW}   For other platforms, use GitHub Actions or build on each platform${NC}"
echo ""
