# Prebuilt Native Binaries

zig-pug uses **prebuilt native binaries** (`.node` files) to provide zero-build installation for supported platforms.

## How It Works

The package includes precompiled `.node` binaries for all major platforms in the `prebuilt-binaries/` directory:

```
prebuilt-binaries/
├── linux-x64/zigpug.node
├── linux-arm64/zigpug.node
├── darwin-x64/zigpug.node
├── darwin-arm64/zigpug.node
└── win32-x64/zigpug.node
```

When you `require('zig-pug')` or `import` it, the code automatically:

1. Detects your platform and architecture
2. Loads the appropriate prebuilt `.node` binary
3. Falls back to building from source if no prebuilt exists

## Benefits

✓ **Zero build time** - No compilation needed during installation
✓ **No build tools required** - Works without node-gyp, Python, or C++ compiler
✓ **Works with Bun** - Even when postinstall scripts are blocked
✓ **Instant npm install** - Just downloads and extracts
✓ **Small binaries** - Each binary is ~2-3MB

## Supported Platforms

| Platform | Architecture | Binary Size | Status |
|----------|-------------|-------------|--------|
| Linux | x64 | ~2.4MB | ✓ |
| Linux | ARM64 | ~2.4MB | ✓ |
| macOS | x64 (Intel) | ~2.4MB | ✓ |
| macOS | ARM64 (M1/M2) | ~2.4MB | ✓ |
| Windows | x64 | ~2.4MB | ✓ |

## Installation Flow

### With Prebuilt Binary (Default)

```bash
npm install zig-pug
# ✓ Downloads package with prebuilt binaries
# ✓ Installs instantly
# ✓ Ready to use immediately
```

No build process runs because the binary already exists!

### Without Prebuilt Binary (Fallback)

If your platform is not supported with a prebuilt binary:

```bash
npm install zig-pug
# → Detects no prebuilt binary for your platform
# → Automatically runs node-gyp rebuild
# → Compiles from Zig static libraries
# → Creates build/Release/zigpug.node
```

## Building Prebuilt Binaries (Maintainers)

### Current Platform Only

To build the `.node` binary for your current platform:

```bash
cd nodejs
npm run build-binaries
```

This creates `prebuilt-binaries/<platform>-<arch>/zigpug.node`.

### All Platforms (CI/CD)

Cross-compiling `.node` binaries is challenging because it requires:
- Platform-specific Node.js headers
- Platform-specific system libraries
- Platform-specific toolchains

**Recommended approach:** Use GitHub Actions or CI/CD to build on each platform:

```yaml
# .github/workflows/build-binaries.yml
strategy:
  matrix:
    os: [ubuntu-latest, macos-latest, windows-latest]
    arch: [x64, arm64]
```

Each runner builds the binary for its platform and uploads it as an artifact.

### Manual Multi-Platform Build

If you have access to multiple platforms:

1. **Linux x64**:
   ```bash
   # On Linux x64 machine
   cd nodejs && npm run build-binaries
   ```

2. **macOS ARM64** (M1/M2):
   ```bash
   # On macOS ARM64 machine
   cd nodejs && npm run build-binaries
   ```

3. **Windows x64**:
   ```cmd
   REM On Windows x64 machine
   cd nodejs
   npm run build-binaries
   ```

4. Collect all `prebuilt-binaries/*/zigpug.node` files into one directory.

## Why Prebuilt .node Instead of Static Libraries?

We include both approaches:

1. **Prebuilt `.node` binaries** (recommended):
   - Zero installation time
   - No build tools needed
   - Larger package size (~12MB total)

2. **Static libraries** (`.a`/`.lib` in `prebuilts/`):
   - Fallback for unsupported platforms
   - Smaller package size
   - Requires node-gyp and C++ compiler

The `.node` approach is superior when available because it requires absolutely no build process.

## Package Size Comparison

| Approach | Download Size | Installed Size | Build Time |
|----------|--------------|----------------|------------|
| Prebuilt .node | ~5MB | ~12MB | 0s |
| Static libs only | ~4MB | ~16MB | 30-60s |
| Source only | ~1MB | ~20MB | 2-5min |

We include prebuilt `.node` files because the extra 1MB download is worth zero build time.

## Troubleshooting

### "Platform not supported"

If you see this error, your platform doesn't have a prebuilt binary. The package will automatically try to build from source. Ensure you have:

- Node.js 14+
- Python 3
- C++ build tools (see [node-gyp requirements](https://github.com/nodejs/node-gyp#installation))

### Binary Not Loading

If the binary exists but won't load:

```javascript
Error: Cannot find module './prebuilt-binaries/linux-x64/zigpug.node'
```

Try:
1. Delete `node_modules/zig-pug`
2. Clear npm cache: `npm cache clean --force`
3. Reinstall: `npm install zig-pug`

### ABI Compatibility

The `.node` binaries are built against Node.js N-API, which is ABI-stable across Node.js versions. They work with:

- Node.js 14.x, 16.x, 18.x, 20.x, 22.x
- Bun 1.x
- Deno (with npm: specifier)

No rebuilding needed when updating Node.js!

## Development Workflow

When working on zig-pug:

1. Make changes to Zig code in `src/`
2. Rebuild Zig static libraries: `npm run build-prebuilts`
3. Rebuild `.node` binary: `npm run build-binaries`
4. Test locally: `npm test`
5. Before publishing: `npm run prepublishOnly` (builds everything)

The `prepublishOnly` script ensures both static libraries and `.node` binaries are fresh.

## Future Improvements

Potential enhancements:

1. **Download on demand**: Download binaries from GitHub releases instead of bundling in package
2. **Electron support**: Add Electron-specific binaries
3. **More platforms**: Add support for more architectures (RISC-V, etc.)
4. **Binary signing**: Sign binaries for additional security verification
