#!/bin/bash
# Build prebuilt Zig static libraries for multiple platforms
# This script should be run before publishing to npm

set -e

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
PREBUILTS_DIR="$SCRIPT_DIR/prebuilts"

echo "Building prebuilt Zig libraries..."
echo "Project root: $PROJECT_ROOT"
echo "Prebuilts directory: $PREBUILTS_DIR"

# Clean previous builds
rm -rf "$PREBUILTS_DIR"
mkdir -p "$PREBUILTS_DIR"

cd "$PROJECT_ROOT"

# Define target platforms
# Format: "zig-target:output-folder"
TARGETS=(
    "x86_64-linux:linux-x64"
    "aarch64-linux:linux-arm64"
    "x86_64-macos:darwin-x64"
    "aarch64-macos:darwin-arm64"
    "x86_64-windows:win32-x64"
)

for target in "${TARGETS[@]}"; do
    IFS=: read -r zig_target output_dir <<< "$target"

    echo ""
    echo "Building for $zig_target -> $output_dir"
    echo "----------------------------------------"

    # Build static library for target
    zig build lib-static \
        -Dtarget="$zig_target" \
        -Doptimize=ReleaseFast \
        --prefix-lib-dir "$PREBUILTS_DIR/$output_dir"

    # Verify the library was created (Windows uses .lib, others use .a)
    if [ -f "$PREBUILTS_DIR/$output_dir/libzig-pug.a" ]; then
        size=$(du -h "$PREBUILTS_DIR/$output_dir/libzig-pug.a" | cut -f1)
        echo "✓ Created $output_dir/libzig-pug.a ($size)"
    elif [ -f "$PREBUILTS_DIR/$output_dir/zig-pug.lib" ]; then
        size=$(du -h "$PREBUILTS_DIR/$output_dir/zig-pug.lib" | cut -f1)
        echo "✓ Created $output_dir/zig-pug.lib ($size)"
    else
        echo "✗ Failed to create library for $output_dir"
        exit 1
    fi
done

echo ""
echo "========================================="
echo "All prebuilt libraries created successfully!"
echo "========================================="
echo ""
ls -lh "$PREBUILTS_DIR"/*/*.a "$PREBUILTS_DIR"/*/*.lib 2>/dev/null || true
