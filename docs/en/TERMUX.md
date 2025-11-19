# Compiling in Termux/Android

This guide explains how to compile the zig-pug Node.js addon in Termux, known limitations, and recommended alternatives.

## TL;DR

- **The addon COMPILES successfully** in Termux with the workaround described
- **The addon CANNOT BE LOADED** due to Android namespace restrictions
- **ALTERNATIVE**: Use the zig-pug CLI binary (`zig-pug`) in Termux

## Technical Context

### Why is compiling in Termux difficult?

Termux is a Linux environment running on Android using PRoot, but:

1. **node-gyp detects Android**: Automatically looks for the Android NDK
2. **No NDK in Termux**: Only clang, cmake, gcc are available
3. **libc conflicts**: Termux uses musl, Android uses Bionic
4. **Namespace restrictions**: Android prevents loading external .so files at runtime

## Compilation Solution (Workaround)

### 1. Configuration Files

#### `nodejs/common.gypi` (Create)

This file provides a dummy variable to prevent node-gyp from searching for the NDK:

```json
{
  'variables': {
    'android_ndk_path%': '/tmp',
  }
}
```

#### `nodejs/binding.gyp` (Simplified)

Minimal configuration without problematic dependencies:

```json
{
  "targets": [
    {
      "target_name": "zigpug",
      "sources": [
        "binding.c"
      ],
      "include_dirs": [
        "../include",
        "../vendor/mujs"
      ],
      "libraries": [
        "<(module_root_dir)/../vendor/mujs/libmujs.a",
        "-lm"
      ],
      "cflags": [
        "-std=c99"
      ],
      "defines": [
        "NAPI_VERSION=8"
      ]
    }
  ]
}
```

**Important changes:**
- Removed `node-addon-api` dependency
- Used `<(module_root_dir)>` for absolute paths
- Minimal configuration with pure N-API only

### 2. Build Script

#### `nodejs/build-termux.sh`

```bash
#!/data/data/com.termux/files/usr/bin/bash
# Script to compile the addon in Termux
# Tricks node-gyp into thinking it's on Linux

export npm_config_arch=arm64
export npm_config_platform=linux
export GYPFLAGS="-DOS=linux"

# Run node-gyp with custom configuration
npx node-gyp configure -- \
  -DOS=linux \
  -Dhost_os=linux \
  -Dtarget_arch=arm64

npx node-gyp build
```

**What does this script do?**
1. Sets environment variables so npm thinks it's on Linux
2. Passes flags to GYP to force OS detection as Linux
3. Runs configure and build with these parameters

### 3. Build Process

```bash
cd nodejs

# Install dependencies
npm install

# Grant execution permissions
chmod +x build-termux.sh

# Compile
./build-termux.sh
```

### Expected Result

```
  CXX(target) Release/obj.target/zigpug/binding.o
  SOLINK_MODULE(target) Release/obj.target/zigpug.node
  COPY Release/zigpug.node
```

The `zigpug.node` addon is successfully created in `build/Release/`.

## Limitation: Cannot Be Loaded

### The Problem

Although compilation is successful, when attempting to load the addon:

```bash
$ node
> require('./build/Release/zigpug.node')
```

### Error Received

```
Error: dlopen failed: library "/root/zig-pug/nodejs/build/Release/zigpug.node"
needed or dlopened by "/data/data/com.termux/files/usr/bin/node"
is not accessible for the namespace "(default)"
```

### Why Does This Happen?

Android implements **namespace restrictions** for security:

1. **Namespace separation**: Android apps have isolated namespaces
2. **PRoot is not real root**: Termux runs in PRoot, doesn't have full root access
3. **dlopen blocked**: Android blocks loading .so files that are not in the app's namespace
4. **Node.js in Termux**: Is in Termux's namespace, the addon is "outside"

### Dependency Analysis (ldd)

```bash
$ ldd build/Release/zigpug.node
```

**Issues found:**
- `liblog.so: No such file or directory` - Android-specific library
- `napi_create_function: symbol not found` - Unresolved N-API symbols
- `zigpug_init: symbol not found` - Unresolved zig-pug symbols
- musl vs Bionic libc conflicts

## Recommended Alternatives

### Option 1: Use the CLI Binary (RECOMMENDED)

The zig-pug CLI works perfectly in Termux:

```bash
# Compile the CLI
zig build

# Use directly
./zig-out/bin/zig-pug template.pug

# With variables
./zig-out/bin/zig-pug template.pug --var name=World --var age=25

# Save to file
./zig-out/bin/zig-pug -i template.pug -o output.html
```

**Advantages:**
- Works perfectly in Termux
- No Node.js dependencies
- Faster than the addon
- Full access to all zig-pug features

### Option 2: Remote Development

Use Termux for editing, but compile/run on a Linux VM:

```bash
# In Termux: edit code
vim template.pug

# In Linux/macOS: compile and test addon
cd nodejs
npm install
npm run build
node examples/01-basic.js
```

### Option 3: Bun.js on Linux/macOS

The addon is compatible with Bun.js, which is much faster:

```bash
# On Linux/macOS
bun install
bun run examples/bun/01-basic.js
```

**Performance with Bun:**
- 2-5x faster than Node.js
- Same API, same code
- See `examples/bun/` for examples

### Option 4: Attempt to Load the Addon (NOT RECOMMENDED)

Technically you could try:
- Modifying the linker path
- Using LD_PRELOAD
- Compiling Node.js with special configuration

**But:**
- Very complex and fragile
- Requires advanced knowledge of Android internals
- Probably won't work due to security restrictions
- Not worth the effort

## Options Comparison

| Option | Works in Termux | Performance | Complexity | Feature Access |
|--------|----------------|-------------|------------|----------------|
| CLI Binary | Yes | Very fast | Easy | 100% |
| Node.js Addon | No | Fast | Doesn't work | 0% |
| Bun.js Addon | No* | Very fast | Doesn't work | 0% |
| Remote Dev | Editing only | Depends | Medium | 100% |

*Bun is not available for Android/Termux

## Technical Details

### Configuration That Works

**Environment variables:**
```bash
npm_config_arch=arm64
npm_config_platform=linux
GYPFLAGS="-DOS=linux"
```

**GYP flags:**
```bash
-DOS=linux
-Dhost_os=linux
-Dtarget_arch=arm64
```

**Correct shebang for Termux:**
```bash
#!/data/data/com.termux/files/usr/bin/bash
```

### What Does NOT Work

**Attempting to use node-addon-api:**
```json
// DOES NOT WORK in Termux
"include_dirs": [
  "<!@(node -p \"require('node-addon-api').include\")"
]
```

**Relative paths for libraries:**
```json
// DOES NOT WORK
"libraries": [
  "../vendor/mujs/libmujs.a"
]

// WORKS
"libraries": [
  "<(module_root_dir)/../vendor/mujs/libmujs.a"
]
```

## Conclusion

### For Termux Users

**If you're in Termux:**
1. Use the CLI binary (`zig-pug`)
2. Compile with `zig build`
3. Enjoy maximum performance without complications

**DO NOT attempt to use the Node.js addon in Termux** - it's a waste of time due to fundamental Android restrictions.

### For Development on Linux/macOS

**If you're on Linux or macOS:**
1. The addon works perfectly
2. Use Bun.js for better performance
3. Integrate with Express, Fastify, etc.
4. See `docs/NODEJS-INTEGRATION.md`

## Resources

- **CLI Documentation**: [docs/CLI.md](CLI.md)
- **Node.js Integration**: [docs/NODEJS-INTEGRATION.md](NODEJS-INTEGRATION.md)
- **Bun Examples**: [examples/bun/](../examples/bun/)
- **Building Guide**: [docs/BUILDING-ADDON.md](BUILDING-ADDON.md)

## Support

If you have problems compiling in Termux:
1. Verify that you have Zig 0.15.2 installed
2. Use the CLI binary instead of the addon
3. Open an issue on GitHub if you find bugs in the CLI

---

**Summary**: The addon compiles in Termux with the workaround, but cannot be loaded. **Use the CLI binary** which works perfectly.
