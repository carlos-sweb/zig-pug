# Using zpug with pkg-config

This document explains how to use the zpug library in C/C++ projects using pkg-config.

## Quick Start

### 1. Install the library

Copy the appropriate files for your platform to system directories:

**Linux/macOS:**
```bash
# From the project root
sudo cp libs/linux-x64/libzig-pug.a /usr/local/lib/
sudo cp libs/linux-x64/libzig-pug.so /usr/local/lib/
sudo cp include/zigpug.h /usr/local/include/
sudo cp libs/linux-x64/pkgconfig/zpug.pc /usr/local/lib/pkgconfig/
```

**Adjust the platform directory as needed:**
- `linux-x64` for Linux x86_64
- `linux-arm64` for Linux ARM64
- `darwin-x64` for macOS Intel
- `darwin-arm64` for macOS Apple Silicon
- `win32-x64` for Windows (see Windows section below)

### 2. Verify installation

```bash
pkg-config --modversion zpug
# Output: 0.4.0

pkg-config --cflags zpug
# Output: -I/usr/local/include

pkg-config --libs zpug
# Output: -L/usr/local/lib -lzig-pug
```

### 3. Compile your C/C++ code

```bash
# Using pkg-config
gcc myapp.c -o myapp $(pkg-config --cflags --libs zpug)

# Or with g++
g++ myapp.cpp -o myapp $(pkg-config --cflags --libs zpug)
```

## Example C Program

**hello.c:**
```c
#include <stdio.h>
#include <zigpug.h>

int main() {
    // Initialize zpug context
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "Failed to initialize zpug\n");
        return 1;
    }

    // Set variables
    zigpug_set_string(ctx, "name", "World");
    zigpug_set_int(ctx, "year", 2025);
    zigpug_set_bool(ctx, "isProduction", false);

    // Compile Pug template
    const char* template =
        "doctype html\n"
        "html\n"
        "  head\n"
        "    title Hello #{name}\n"
        "  body\n"
        "    h1 Welcome #{name}!\n"
        "    p Year: #{year}\n"
        "    p Mode: #{isProduction ? 'Production' : 'Development'}";

    char* html = zigpug_compile(ctx, template);
    if (html) {
        printf("%s\n", html);
        zigpug_free_string(html);
    } else {
        fprintf(stderr, "Compilation failed\n");
    }

    // Cleanup
    zigpug_free(ctx);
    return 0;
}
```

**Compile:**
```bash
gcc hello.c -o hello $(pkg-config --cflags --libs zpug)
./hello
```

## CMake Integration

**CMakeLists.txt:**
```cmake
cmake_minimum_required(VERSION 3.10)
project(MyApp)

# Find zpug using pkg-config
find_package(PkgConfig REQUIRED)
pkg_check_modules(ZPUG REQUIRED zpug)

add_executable(myapp main.c)

# Link zpug
target_include_directories(myapp PRIVATE ${ZPUG_INCLUDE_DIRS})
target_link_libraries(myapp ${ZPUG_LIBRARIES})
target_link_directories(myapp PRIVATE ${ZPUG_LIBRARY_DIRS})
```

**Build:**
```bash
mkdir build
cd build
cmake ..
make
```

## Meson Integration

**meson.build:**
```meson
project('myapp', 'c')

zpug_dep = dependency('zpug')

executable('myapp',
  'main.c',
  dependencies: zpug_dep
)
```

**Build:**
```bash
meson setup build
meson compile -C build
```

## Makefile Integration

**Makefile:**
```makefile
CFLAGS = $(shell pkg-config --cflags zpug)
LIBS = $(shell pkg-config --libs zpug)

myapp: main.c
	$(CC) $(CFLAGS) main.c -o myapp $(LIBS)

clean:
	rm -f myapp
```

**Build:**
```bash
make
```

## Windows (MSVC/MinGW)

### MinGW

```bash
# Install files
cp libs/win32-x64/zig-pug.lib C:/mingw64/lib/
cp libs/win32-x64/zig-pug.dll C:/mingw64/bin/
cp include/zigpug.h C:/mingw64/include/
cp libs/win32-x64/pkgconfig/zpug.pc C:/mingw64/lib/pkgconfig/

# Compile
gcc myapp.c -o myapp.exe $(pkg-config --cflags --libs zpug)
```

### MSVC

For Visual Studio, you typically don't use pkg-config. Instead:

1. Copy `zig-pug.lib` and `zig-pug.dll` to your project
2. Copy `zigpug.h` to your include directory
3. Add to your project properties:
   - **C/C++ → General → Additional Include Directories**: Path to zigpug.h
   - **Linker → Input → Additional Dependencies**: zig-pug.lib
   - **Linker → General → Additional Library Directories**: Path to zig-pug.lib

## API Reference

See `include/zigpug.h` for the complete C API:

### Core Functions

```c
// Initialize/cleanup
ZigPugContext* zigpug_init(void);
void zigpug_free(ZigPugContext* ctx);

// Compile templates
char* zigpug_compile(ZigPugContext* ctx, const char* pug_source);

// Set variables
bool zigpug_set_string(ZigPugContext* ctx, const char* key, const char* value);
bool zigpug_set_int(ZigPugContext* ctx, const char* key, int64_t value);
bool zigpug_set_bool(ZigPugContext* ctx, const char* key, bool value);

// Free strings
void zigpug_free_string(char* str);

// Version info
const char* zigpug_version(void);
```

## Error Handling

zpug returns `NULL` on errors. Always check return values:

```c
char* html = zigpug_compile(ctx, template);
if (!html) {
    fprintf(stderr, "Error: Compilation failed\n");
    // Handle error...
} else {
    // Use html...
    zigpug_free_string(html);
}
```

## Thread Safety

Each `ZigPugContext` is **not thread-safe**. If you need concurrent compilation:

1. Create one context per thread
2. Use mutex locks around context operations
3. Consider using a context pool

## Performance Tips

1. **Reuse contexts**: Creating contexts is expensive, reuse them when possible
2. **Static linking**: Use `.a` files for better performance in production
3. **Dynamic linking**: Use `.so/.dylib/.dll` for development and shared libraries

## Troubleshooting

### pkg-config: zpug not found

```bash
# Check PKG_CONFIG_PATH
echo $PKG_CONFIG_PATH

# Add custom path if needed
export PKG_CONFIG_PATH=/usr/local/lib/pkgconfig:$PKG_CONFIG_PATH

# Or specify path directly
pkg-config --cflags --libs /path/to/zpug.pc
```

### Linker errors

```bash
# Verify library is installed
ls -l /usr/local/lib/libzig-pug.*

# Check if library is in ld cache (Linux)
sudo ldconfig
ldconfig -p | grep zig-pug

# Add library path (Linux)
export LD_LIBRARY_PATH=/usr/local/lib:$LD_LIBRARY_PATH

# Add library path (macOS)
export DYLD_LIBRARY_PATH=/usr/local/lib:$DYLD_LIBRARY_PATH
```

### Runtime errors: library not found

**Linux:**
```bash
# Add to /etc/ld.so.conf.d/zpug.conf
echo "/usr/local/lib" | sudo tee /etc/ld.so.conf.d/zpug.conf
sudo ldconfig
```

**macOS:**
```bash
# Install library with install_name
sudo install_name_tool -id /usr/local/lib/libzig-pug.dylib /usr/local/lib/libzig-pug.dylib
```

## Alternative: Manual Compilation

If you prefer not to use pkg-config:

```bash
# Include header and link library directly
gcc myapp.c -o myapp -I/usr/local/include -L/usr/local/lib -lzig-pug -lm
```

## Examples

See the `examples/c/` directory for complete working examples:
- Basic usage
- Error handling
- CMake integration
- Makefile integration

## Support

- **Header**: `include/zigpug.h`
- **Documentation**: [GitHub](https://github.com/carlos-sweb/zig-pug)
- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)

## License

MIT License - see [LICENSE](../LICENSE) for details.
