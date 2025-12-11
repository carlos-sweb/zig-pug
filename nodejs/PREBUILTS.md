# Prebuilt Native Libraries

This document explains how zig-pug uses prebuilt native libraries for cross-platform Node.js addon distribution.

## Overview

The zig-pug package includes prebuilt static libraries (`.a` files for Unix/Linux/macOS, `.lib` for Windows) that are compiled from Zig source code and include the mujs JavaScript engine. During `npm install`, these prebuilt libraries are linked with a thin C binding layer to create the final native Node.js addon.

## Why Prebuilts?

1. **No Zig Compiler Required**: Users don't need to install Zig to use zig-pug
2. **Faster Installation**: Only the C binding needs to be compiled (via node-gyp)
3. **Cross-Platform**: Prebuilt libraries for all major platforms are included
4. **Reliable**: Same binary artifacts used across all installations

## Supported Platforms

The following prebuilt libraries are included:

- **Linux x64**: `prebuilts/linux-x64/libzig-pug.a`
- **Linux ARM64**: `prebuilts/linux-arm64/libzig-pug.a`
- **macOS x64**: `prebuilts/darwin-x64/libzig-pug.a`
- **macOS ARM64** (Apple Silicon): `prebuilts/darwin-arm64/libzig-pug.a`
- **Windows x64**: `prebuilts/win32-x64/zig-pug.lib`

## Building Prebuilts (for Maintainers)

To rebuild the prebuilt libraries (required before publishing):

```bash
cd nodejs
./build-prebuilts.sh
```

This script:
1. Builds the Zig static library for each target platform
2. Includes mujs JavaScript engine
3. Compiles with Position Independent Code (-fPIC) for shared library compatibility
4. Places output in `prebuilts/` directory

### Requirements for Building

- Zig compiler (0.13.0 or later)
- Cross-compilation support (Zig handles this automatically)

## How It Works

### Installation Flow

1. User runs `npm install zig-pug`
2. npm extracts package including `prebuilts/` directory
3. The `install` script runs: `node-gyp rebuild`
4. node-gyp:
   - Compiles `binding.c` (thin C wrapper for Node.js N-API)
   - Links with appropriate prebuilt library from `prebuilts/<platform>/`
   - Creates `build/Release/zigpug.node`
5. Node.js can now `require()` or `import` the addon

### Build Configuration

The `binding.gyp` file is configured to:
- Select the correct prebuilt library based on OS and architecture
- Link with math library (`-lm`) on Unix-like systems
- Handle Windows `.lib` vs Unix `.a` differences

```gyp
{
  "conditions": [
    ["OS=='win'", {
      "libraries": ["<(module_root_dir)/prebuilts/win32-<(target_arch)/zig-pug.lib"]
    }, {
      "libraries": [
        "-lm",
        "<(module_root_dir)/prebuilts/<(OS)-<(target_arch)/libzig-pug.a"
      ]
    }]
  ]
}
```

## Publishing Workflow

Before publishing to npm:

```bash
# 1. Build prebuilts for all platforms
npm run build-prebuilts

# 2. Verify prebuilts exist
ls -lh prebuilts/*/

# 3. Publish (prebuilts are included via package.json "files")
npm publish
```

The `prepublishOnly` script automatically runs `build-prebuilts` to ensure fresh binaries.

## Package Size

Prebuilt libraries add ~15MB to the package (compressed):
- Each platform library: ~2-4MB
- 5 platforms total: ~10-20MB uncompressed
- npm package compression reduces this significantly

This is acceptable because:
- Users only download once
- Eliminates need for Zig compiler
- Faster installation than compiling from source

## Troubleshooting

### Missing Prebuilt for Platform

If a platform is not supported, node-gyp will fail during `npm install`. To add support:

1. Add target to `build-prebuilts.sh`:
   ```bash
   TARGETS+=(
       "new-arch-new-os:output-folder-name"
   )
   ```

2. Update `binding.gyp` if needed for platform-specific flags

3. Rebuild and test

### Symbol Errors

If you see "undefined symbol" errors:
- Ensure mujs is compiled into the static library
- Check that `-fPIC` is enabled in `build.zig`
- Verify library was built with correct optimization level

### Windows Build Issues

Windows uses different library format (`.lib` instead of `.a`):
- Zig automatically generates `.lib` for Windows targets
- `binding.gyp` handles this via OS conditions
- Ensure both Unix and Windows paths are tested

## Technical Details

### Why Static Library?

We use static libraries (`.a`/`.lib`) instead of shared libraries (`.so`/`.dll`) because:
1. **Self-contained**: No runtime dependencies
2. **Node.js addons**: Typically use static linking
3. **Cross-platform**: Easier to distribute
4. **Version independence**: No system library conflicts

### Position Independent Code (PIC)

The libraries are compiled with `-fPIC` because:
- Node.js addons are loaded as shared objects
- PIC allows code to be loaded at any memory address
- Required for shared library linking on most platforms

### Optimization

Libraries are built with `ReleaseFast` optimization:
- mujs requires optimization to function correctly
- Smaller binary size
- Better runtime performance
- Still includes debug symbols for better error messages

## Future Improvements

Potential enhancements:
1. **Optional download**: Download prebuilts from GitHub releases if not in package
2. **Platform detection**: Only include relevant platform in final installation
3. **Fallback compilation**: Compile from source if prebuilt unavailable
4. **Binary hosting**: Use external CDN to reduce package size
