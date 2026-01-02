# Building the Node.js Addon

Complete guide to building and debugging the zig-pug Node.js addon.

## Table of Contents

- [Prerequisites](#prerequisites)
- [Building from Source](#building-from-source)
- [Development Setup](#development-setup)
- [Debugging](#debugging)
- [Platform-Specific Notes](#platform-specific-notes)
- [Troubleshooting](#troubleshooting)

## Prerequisites

### Required Tools

**All Platforms:**
- Node.js >= 14.0.0
- Python 3 (for node-gyp)
- Zig 0.15.2

**Linux/macOS:**
- GCC or Clang
- make

**Windows:**
- Visual Studio 2017 or later (with C++ tools)
- OR MinGW-w64

### Install Prerequisites

**Ubuntu/Debian:**
```bash
sudo apt-get update
sudo apt-get install build-essential python3 git
```

**macOS:**
```bash
xcode-select --install
```

**Windows:**
```powershell
# Install Visual Studio Build Tools
# Download from: https://visualstudio.microsoft.com/downloads/

# Or install via chocolatey
choco install visualstudio2022buildtools
choco install visualstudio2022-workload-vctools
```

**Install Zig:**
```bash
# Download from: https://ziglang.org/download/
# Extract and add to PATH

# Verify
zig version
# Should show: 0.15.2
```

## Building from Source

### Quick Build

```bash
# Clone repository
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug

# Build addon
npm install
```

This runs `node-gyp rebuild` automatically during `npm install`.

### Manual Build

```bash
# Install dependencies
npm install --ignore-scripts

# Build manually
npm run build
```

### Verify Build

```bash
# Check addon exists
ls -l build/Release/zigpug.node

# Test addon
node -e "const z = require('./nodejs'); console.log(z.version())"
```

## Development Setup

### Project Structure

```
zig-pug/
├── src/               # Zig source code
├── vendor/mujs/       # Embedded mujs
├── nodejs/
│   ├── binding.c      # N-API wrapper (C)
│   ├── binding.gyp    # Build configuration
│   ├── index.js       # JavaScript API
│   └── index.d.ts     # TypeScript definitions
└── build/
    └── Release/
        └── zigpug.node  # Compiled addon
```

### Build Configuration

**binding.gyp:**
```python
{
  'targets': [{
    'target_name': 'zigpug',
    'sources': [
      'nodejs/binding.c'
    ],
    'libraries': [
      '../zig-out/lib/libzigpug.a',  # Zig library
      '../vendor/mujs/build/release/libmujs.a'  # mujs library
    ],
    'include_dirs': [
      '<!(node -p "require(\'node-addon-api\').include_dir")',
      './src',
      './vendor/mujs'
    ]
  }]
}
```

### Development Build

```bash
# Clean previous build
rm -rf build/ zig-out/

# Build Zig library
zig build

# Build mujs
cd vendor/mujs
make clean
make release
cd ../..

# Build Node.js addon
npm run build

# Test
node nodejs/test-cjs.js
```

### Watch Mode

```bash
# Install nodemon
npm install -g nodemon

# Watch for changes
nodemon --watch src --watch nodejs --exec "npm run build && node nodejs/test-cjs.js"
```

## Debugging

### Debug Build

**Enable debug symbols:**

```bash
# Zig debug build
zig build -Doptimize=Debug

# Node.js debug build
node-gyp rebuild --debug
```

**Debug symbols location:**
- Linux: `build/Debug/zigpug.node`
- macOS: `build/Debug/zigpug.node.dSYM/`
- Windows: `build/Debug/zigpug.pdb`

### Debugging with GDB (Linux)

```bash
# Build with debug symbols
zig build -Doptimize=Debug
node-gyp rebuild --debug

# Run under GDB
gdb --args node nodejs/test-cjs.js

# GDB commands
(gdb) break zigpug_compile
(gdb) run
(gdb) backtrace
(gdb) print variable
```

### Debugging with LLDB (macOS)

```bash
# Build with debug symbols
zig build -Doptimize=Debug
node-gyp rebuild --debug

# Run under LLDB
lldb -- node nodejs/test-cjs.js

# LLDB commands
(lldb) breakpoint set --name zigpug_compile
(lldb) run
(lldb) bt
(lldb) frame variable
```

### Debugging with Visual Studio (Windows)

1. Build with debug symbols:
   ```powershell
   zig build -Doptimize=Debug
   node-gyp rebuild --debug
   ```

2. Open Visual Studio
3. Debug → Attach to Process
4. Select Node.js process
5. Set breakpoints in C code
6. Run tests

### Memory Debugging

**Valgrind (Linux):**
```bash
# Check for memory leaks
valgrind --leak-check=full \
         --show-leak-kinds=all \
         node nodejs/test-cjs.js
```

**AddressSanitizer:**
```bash
# Build with ASan
export CFLAGS="-fsanitize=address -g"
export LDFLAGS="-fsanitize=address"
node-gyp rebuild --debug

# Run
node nodejs/test-cjs.js
```

### Logging

**Add logging to binding.c:**

```c
#include <stdio.h>

napi_value zigpug_compile(napi_env env, napi_callback_info info) {
    fprintf(stderr, "[DEBUG] zigpug_compile called\n");

    // ... existing code

    fprintf(stderr, "[DEBUG] template length: %zu\n", template_len);

    // ... rest of function
}
```

**Rebuild and test:**
```bash
npm run build
node nodejs/test-cjs.js 2>&1 | grep DEBUG
```

## Platform-Specific Notes

### Linux

**ARM64 (Raspberry Pi, etc.):**
```bash
# Ensure correct architecture
uname -m
# Should show: aarch64 or arm64

# Build
zig build -Dtarget=aarch64-linux
npm run build
```

**x64:**
```bash
zig build -Dtarget=x86_64-linux
npm run build
```

### macOS

**Apple Silicon (M1/M2):**
```bash
# Native build
zig build -Dtarget=aarch64-macos
npm run build
```

**Intel:**
```bash
zig build -Dtarget=x86_64-macos
npm run build
```

**Universal Binary:**
```bash
# Build both architectures
zig build -Dtarget=x86_64-macos
cp zig-out/lib/libzigpug.a zig-out/lib/libzigpug-x64.a

zig build -Dtarget=aarch64-macos
cp zig-out/lib/libzigpug.a zig-out/lib/libzigpug-arm64.a

# Combine with lipo
lipo -create \
  zig-out/lib/libzigpug-x64.a \
  zig-out/lib/libzigpug-arm64.a \
  -output zig-out/lib/libzigpug.a

# Build addon
npm run build
```

### Windows

**MinGW:**
```bash
# Use MinGW toolchain
zig build -Dtarget=x86_64-windows-gnu
npm run build
```

**MSVC:**
```powershell
# Use MSVC toolchain
zig build -Dtarget=x86_64-windows-msvc
npm run build
```

### Termux/Android

**CLI works, addon cannot load:**
```bash
# Build CLI (works)
zig build
./zig-out/bin/zpug template.zpug

# Addon compiles but cannot load (Android limitation)
npm install  # Builds successfully
node -e "require('./nodejs')"  # Fails with dlopen error
```

**Workaround:** Use CLI instead of Node.js API.

See [../TERMUX.md](../TERMUX.md) for details.

## Troubleshooting

### Build Failures

**Error: "node-gyp not found"**

```bash
# Install globally
npm install -g node-gyp

# Or use npx
npx node-gyp rebuild
```

**Error: "Cannot find Zig"**

```bash
# Add Zig to PATH
export PATH="/path/to/zig:$PATH"

# Verify
zig version
```

**Error: "mujs build failed"**

```bash
# Build mujs manually
cd vendor/mujs
make clean
make release

# Check output
ls -l build/release/libmujs.a
```

**Error: "Python not found"**

```bash
# Install Python 3
# Ubuntu
sudo apt-get install python3

# macOS
brew install python3

# Windows
# Download from: https://www.python.org/downloads/
```

### Runtime Errors

**Error: "Cannot load addon"**

**Check addon exists:**
```bash
ls -l build/Release/zigpug.node
```

**Check dependencies:**
```bash
# Linux
ldd build/Release/zigpug.node

# macOS
otool -L build/Release/zigpug.node

# Windows
dumpbin /dependents build\Release\zigpug.node
```

**Rebuild:**
```bash
rm -rf build/ node_modules/
npm install
```

**Error: "Symbol not found"**

**Cause:** Zig library not up to date.

**Solution:**
```bash
# Rebuild Zig library
rm -rf zig-out/
zig build

# Rebuild addon
npm run build
```

**Error: "Segmentation fault"**

**Debug:**
```bash
# Run under GDB
gdb --args node test.js

# Run test
(gdb) run

# Check backtrace when crashes
(gdb) bt
```

### Performance Issues

**Addon slower than expected:**

1. **Check build optimization:**
   ```bash
   # Should be ReleaseFast
   zig build -Doptimize=ReleaseFast
   npm run build
   ```

2. **Profile:**
   ```bash
   node --prof test.js
   node --prof-process isolate-*.log
   ```

3. **Use Bun:**
   ```bash
   bun run test.js  # 2-5x faster
   ```

## Build Scripts

### Automated Build Script

**build.sh:**
```bash
#!/bin/bash
set -e

echo "Building zig-pug addon..."

# Clean
echo "Cleaning..."
rm -rf build/ zig-out/ vendor/mujs/build/

# Build mujs
echo "Building mujs..."
cd vendor/mujs
make release
cd ../..

# Build Zig library
echo "Building Zig library..."
zig build -Doptimize=ReleaseFast

# Build Node.js addon
echo "Building Node.js addon..."
npm run build

# Test
echo "Testing..."
node nodejs/test-cjs.js

echo "Build complete!"
```

**Usage:**
```bash
chmod +x build.sh
./build.sh
```

### Cross-Compilation Script

**build-all-platforms.sh:**
```bash
#!/bin/bash

platforms="x86_64-linux aarch64-linux x86_64-macos aarch64-macos x86_64-windows"

for platform in $platforms; do
    echo "Building for $platform..."
    zig build -Dtarget=$platform -Doptimize=ReleaseFast
    cp zig-out/lib/libzigpug.a "prebuilt/libzigpug-$platform.a"
done

echo "All platforms built!"
```

## See Also

- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contributing guidelines
- [../NODEJS-INTEGRATION.md](../NODEJS-INTEGRATION.md) - Node.js integration
- [../TERMUX.md](../TERMUX.md) - Android/Termux notes
- [TESTS.md](TESTS.md) - Testing guide
