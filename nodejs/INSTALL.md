# Installation Instructions

## Using npm

```bash
npm install zig-pug
```

The package will automatically build the native addon during installation.

## Using Bun

Bun blocks postinstall scripts by default for security. After installing:

```bash
# Install the package
bun install zig-pug

# Trust and run the install script
bun pm trust zig-pug
```

Alternatively, you can manually build the addon:

```bash
cd node_modules/zig-pug
bun install  # or npm install
```

## Manual Build

If the native addon wasn't built automatically:

```bash
cd node_modules/zig-pug
npm install
```

This will:
1. Install node-gyp locally
2. Compile the C binding
3. Link with the prebuilt Zig library
4. Create `build/Release/zigpug.node`

## Troubleshooting

### Error: "Cannot find module './build/Release/zigpug.node'"

The native addon wasn't built. Run:

```bash
cd node_modules/zig-pug && npm install
```

### Error: "node-gyp: command not found"

Install node-gyp globally:

```bash
npm install -g node-gyp
```

Or let npm install it locally by running:

```bash
cd node_modules/zig-pug && npm install
```

### Build Tools Required

node-gyp requires:
- **Windows**: Visual Studio Build Tools or `npm install --global windows-build-tools`
- **macOS**: Xcode Command Line Tools (`xcode-select --install`)
- **Linux**: `build-essential` package (`sudo apt-get install build-essential`)

See [node-gyp installation](https://github.com/nodejs/node-gyp#installation) for details.

## Supported Platforms

- Linux x64 / ARM64
- macOS x64 / ARM64 (Apple Silicon)
- Windows x64

## How It Works

The package includes prebuilt Zig static libraries for all supported platforms. During installation:

1. node-gyp compiles `binding.c` (a thin C wrapper)
2. Links with the appropriate prebuilt library from `prebuilts/`
3. Creates the final native addon `zigpug.node`

This approach means you don't need the Zig compiler installed—only standard C build tools.
