# Using zig-pug as a Library

zig-pug can be built as a static or shared library for use from other programming languages via C FFI (Foreign Function Interface).

## Building the Libraries

### Prerequisites

- Zig 0.15.2 or later
- **libc must be available** (glibc or musl on Linux, native libc on macOS/Windows)
- **Note:** Cannot be built in Termux/Android due to libc detection issues

### Build Commands

```bash
# Build both static (.a) and shared (.so/.dll/.dylib) libraries
zig build lib

# Build only static library
zig build lib-static

# Build only shared library
zig build lib-shared
```

The libraries will be output to:
- Static: `zig-out/lib/libzig-pug.a`
- Shared: `zig-out/lib/libzig-pug.so` (Linux), `libzig-pug.dylib` (macOS), or `zig-pug.dll` (Windows)

## C API Reference

The C API is defined in `include/zigpug.h`. All functions use C-compatible types and calling conventions.

### Types

```c
typedef struct ZigPugContext ZigPugContext;
```

Opaque context handle representing a zig-pug compilation environment with runtime state.

### Functions

#### `zigpug_init()`

```c
ZigPugContext* zigpug_init(void);
```

Initialize a new zig-pug context.

**Returns:** Context handle, or `NULL` on error

**Example:**
```c
ZigPugContext* ctx = zigpug_init();
if (!ctx) {
    fprintf(stderr, "Failed to initialize zig-pug\n");
    return 1;
}
```

#### `zigpug_free()`

```c
void zigpug_free(ZigPugContext* ctx);
```

Free a zig-pug context and release all associated resources.

**Parameters:**
- `ctx`: Context handle (can be `NULL`)

#### `zigpug_compile()`

```c
char* zigpug_compile(ZigPugContext* ctx, const char* pug_source);
```

Compile a Pug template string to HTML.

**Parameters:**
- `ctx`: Context handle
- `pug_source`: Null-terminated Pug template string

**Returns:** Null-terminated HTML string (must be freed with `zigpug_free_string()`), or `NULL` on error

**Example:**
```c
const char* template = "div.container\n  p Hello #{name}!";
char* html = zigpug_compile(ctx, template);
if (html) {
    printf("%s\n", html);
    zigpug_free_string(html);
}
```

#### `zigpug_set_string()`

```c
bool zigpug_set_string(ZigPugContext* ctx, const char* key, const char* value);
```

Set a string variable in the context for use in template interpolation.

**Parameters:**
- `ctx`: Context handle
- `key`: Variable name (null-terminated)
- `value`: String value (null-terminated)

**Returns:** `true` on success, `false` on error

#### `zigpug_set_int()`

```c
bool zigpug_set_int(ZigPugContext* ctx, const char* key, int64_t value);
```

Set an integer variable in the context.

**Parameters:**
- `ctx`: Context handle
- `key`: Variable name (null-terminated)
- `value`: Integer value

**Returns:** `true` on success, `false` on error

#### `zigpug_set_bool()`

```c
bool zigpug_set_bool(ZigPugContext* ctx, const char* key, bool value);
```

Set a boolean variable in the context.

**Parameters:**
- `ctx`: Context handle
- `key`: Variable name (null-terminated)
- `value`: Boolean value

**Returns:** `true` on success, `false` on error

#### `zigpug_free_string()`

```c
void zigpug_free_string(char* str);
```

Free a string returned by zig-pug functions (like `zigpug_compile()`).

**Parameters:**
- `str`: String to free (can be `NULL`)

#### `zigpug_version()`

```c
const char* zigpug_version(void);
```

Get the zig-pug version string.

**Returns:** Version string (do not free)

## Usage Examples

### C

See `examples/example.c` for a complete working example.

**Compilation:**
```bash
gcc example.c -I../include -L../zig-out/lib -lzig-pug -o example
LD_LIBRARY_PATH=../zig-out/lib ./example
```

**Basic usage:**
```c
#include <stdio.h>
#include "zigpug.h"

int main(void) {
    ZigPugContext* ctx = zigpug_init();

    zigpug_set_string(ctx, "name", "World");
    char* html = zigpug_compile(ctx, "p Hello #{name}!");

    printf("%s\n", html);  // <p>HelloWorld</p>

    zigpug_free_string(html);
    zigpug_free(ctx);
    return 0;
}
```

### Python (ctypes)

See `examples/example.py` for a complete working example with a Python wrapper class.

**Basic usage:**
```python
import ctypes

# Load library
zigpug = ctypes.CDLL("./zig-out/lib/libzig-pug.so")

# Define function signatures
zigpug.zigpug_init.restype = ctypes.c_void_p
zigpug.zigpug_compile.restype = ctypes.c_char_p
zigpug.zigpug_compile.argtypes = [ctypes.c_void_p, ctypes.c_char_p]

# Use library
ctx = zigpug.zigpug_init()
html = zigpug.zigpug_compile(ctx, b"p Hello World!")
print(html.decode('utf-8'))  # <p>Hello World !</p>
zigpug.zigpug_free(ctx)
```

### Other Languages

The C API can be used from any language that supports C FFI:

- **Node.js**: Use `ffi-napi` or `node-ffi`
- **Ruby**: Use `fiddle` or `ffi` gem
- **Rust**: Use `bindgen` or manual `extern "C"` declarations
- **Go**: Use `cgo`
- **Java**: Use JNI or JNA
- **C#/.NET**: Use P/Invoke

## Limitations in Termux/Android

The library build **cannot be compiled in Termux/Android** due to libc requirements. The C FFI API uses `std.heap.c_allocator` which requires linking with libc, and Zig cannot detect the Bionic libc installation in Termux.

**Workarounds:**
1. Build the library on a standard Linux/macOS system and copy the compiled library to Termux
2. Use the command-line tool (`zig-pug` executable) instead, which doesn't require libc
3. Wait for better Termux libc support in future Zig versions

## Thread Safety

The current implementation is **not thread-safe**. Each thread should have its own `ZigPugContext` instance.

## Memory Management

- All strings returned by zig-pug (e.g., from `zigpug_compile()`) must be freed with `zigpug_free_string()`
- Context objects must be freed with `zigpug_free()`
- The library uses the C allocator internally, so all memory is compatible with standard C memory management
- Do not mix allocation/deallocation between the library and your code (always use the provided free functions)

## Performance Considerations

- Creating a context (`zigpug_init()`) is relatively expensive. Reuse contexts when compiling multiple templates
- Setting variables (`zigpug_set_*()`) allocates memory. Clear or reset the context if you need to compile many different templates
- Compilation is currently not optimized. For production use, consider caching compiled templates

## Future Enhancements

The following features are planned but not yet implemented:

- Template caching
- Pretty-printed HTML output (with indentation)
- Thread-safe contexts
- Support for arrays and objects in context variables
- Support for JavaScript expressions beyond simple variable access
- Asynchronous compilation API
