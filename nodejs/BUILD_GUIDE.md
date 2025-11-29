# Building zig-pug Node.js Addon

## Quick Start

From the **project root**:

```bash
# Build everything (Zig library + Node.js addon)
zig build node

# Test
cd nodejs && npm test

# Run example
cd nodejs && npm run example
```

## How It Works

The `zig build node` command does three things:

1. **Compiles Zig library** (`libzigpug.so`/`.dylib`/`.dll`)
   - Includes all Zig code + mujs
   - Output: `zig-out/nodejs/libzigpug.{so,dylib,dll}`

2. **Compiles Node.js addon** (`zigpug.node`)
   - Uses `node-gyp` to compile `binding.c`
   - Links against `libzigpug.so` from step 1
   - Output: `nodejs/build/Release/zigpug.node`

3. **Shows success message**

## Architecture

```
┌─────────────────────────────────────────────┐
│  Node.js Application                        │
│  (index.js, your code)                      │
└────────────┬────────────────────────────────┘
             │ require('./build/Release/zigpug.node')
             ↓
┌─────────────────────────────────────────────┐
│  N-API Addon (binding.c)                    │
│  - createContext()                           │
│  - compile()                                 │
│  - setString/Number/Bool()                   │
└────────────┬────────────────────────────────┘
             │ calls FFI functions
             ↓
┌─────────────────────────────────────────────┐
│  libzigpug.so (Zig + mujs)                  │
│  - zigpug_init()                             │
│  - zigpug_compile()                          │
│  - zigpug_set_string/int/bool()              │
│  - tokenizer → parser → compiler → HTML     │
└─────────────────────────────────────────────┘
```

## Development Workflow

### Initial Setup

```bash
# Clone repo
git clone https://github.com/yourusername/zig-pug.git
cd zig-pug

# Build Node.js addon
zig build node
```

### Making Changes

```bash
# After modifying Zig code
zig build node

# After modifying binding.c
cd nodejs && npm run rebuild

# Run tests
cd nodejs && npm test
```

### Clean Build

```bash
# Clean everything
rm -rf zig-out nodejs/build nodejs/node_modules

# Rebuild from scratch
zig build node
```

## File Structure

```
zig-pug/
├── src/                    # Zig source code
│   ├── lib.zig            # C FFI exports
│   ├── compiler.zig       # Template compiler
│   ├── parser.zig         # Pug parser
│   └── ...
├── vendor/mujs/           # mujs JavaScript engine
├── build.zig              # Main build configuration
│   └── "node" step        # ← Builds Node.js addon
├── nodejs/
│   ├── binding.c          # N-API C code
│   ├── binding.gyp        # node-gyp configuration
│   ├── index.js           # JavaScript API
│   └── package.json       # npm configuration
└── zig-out/
    └── nodejs/
        └── libzigpug.so   # ← Compiled by `zig build node`
```

## Cross-Platform Notes

### Linux

- Uses `.so` (shared object)
- rpath: `$ORIGIN/../zig-out/nodejs`
- Works out of the box

### macOS

- Uses `.dylib` (dynamic library)
- rpath: `@loader_path/../zig-out/nodejs`
- May need to sign: `codesign -s - libzigpug.dylib`

### Windows

- Uses `.dll` (dynamic library)
- DLL must be in PATH or same directory as `.node`
- Consider using absolute paths

## Troubleshooting

### `libzigpug.so: cannot open shared object file`

The addon can't find the Zig library. Options:

1. **Set LD_LIBRARY_PATH** (done automatically in npm scripts):
   ```bash
   export LD_LIBRARY_PATH=../zig-out/nodejs:$LD_LIBRARY_PATH
   node your-script.js
   ```

2. **Copy library to addon directory**:
   ```bash
   cp ../zig-out/nodejs/libzigpug.so build/Release/
   ```

3. **Install system-wide** (not recommended for dev):
   ```bash
   sudo cp ../zig-out/nodejs/libzigpug.so /usr/local/lib/
   sudo ldconfig
   ```

### `undefined symbol: js_newstate`

The Zig library wasn't compiled with mujs. Rebuild:

```bash
rm -rf zig-out
zig build node
```

### `node-gyp rebuild fails`

Make sure you have:
- Node.js 14+
- Python 3
- C compiler (gcc/clang)

Install build tools:
```bash
# Ubuntu/Debian
sudo apt install build-essential python3

# Fedora
sudo dnf install @development-tools python3

# macOS
xcode-select --install
```

### Tests fail

Make sure to run from `nodejs/` directory:

```bash
cd nodejs
npm test  # ← npm scripts handle LD_LIBRARY_PATH
```

## Publishing to npm

The current setup requires users to have **Zig installed** to build the addon. For production, consider:

### Option 1: Precompiled Binaries (Recommended)

Use `node-pre-gyp` to distribute precompiled `.node` files:

1. Build for multiple platforms
2. Upload to GitHub Releases
3. Users download the right binary on install

### Option 2: Include Zig in package

Bundle a Zig binary with the npm package (increases size ~50MB).

### Option 3: Document Zig requirement

Current approach - users must have Zig installed:

```json
{
  "engines": {
    "node": ">=14.0.0",
    "zig": ">=0.15.0"
  }
}
```

## Advanced: Building for Multiple Platforms

```bash
# Linux x86_64
zig build node -Dtarget=x86_64-linux

# Linux ARM64
zig build node -Dtarget=aarch64-linux

# macOS x86_64
zig build node -Dtarget=x86_64-macos

# macOS ARM64 (Apple Silicon)
zig build node -Dtarget=aarch64-macos

# Windows x86_64
zig build node -Dtarget=x86_64-windows
```

Note: Cross-compilation may require different rpath configurations.

## Performance Tips

- Always build with `ReleaseFast` (done automatically)
- The Zig library is ~500KB (includes mujs)
- First compile is slower (parsing), subsequent calls are fast
- Consider using `PugCompiler` class for multiple compilations

## Contributing

When modifying the build system:

1. Test on Linux, macOS, and Windows
2. Ensure `zig build node` works from project root
3. Verify npm scripts work from `nodejs/` directory
4. Update this guide if you change the build process

## Resources

- [Zig Build System](https://ziglang.org/documentation/master/#Build-System)
- [Node-GYP](https://github.com/nodejs/node-gyp)
- [N-API Documentation](https://nodejs.org/api/n-api.html)
- [mujs Documentation](https://mujs.com/)
