# C API - Complete Reference

The **C API** provides a complete, C-compatible interface for using zig-pug from C, C++, and other languages that support C FFI (Python ctypes/cffi, Rust, Go, etc.).

## Overview

The C API offers:

- **Simple Interface**: Easy-to-use functions for template compilation
- **Type Safety**: Opaque handles prevent misuse
- **Memory Safety**: Clear ownership and cleanup semantics
- **Full Features**: Access to all zig-pug capabilities
- **Error Handling**: Detailed error reporting with line numbers
- **Cross-Language**: Works with any language supporting C FFI
- **Zero Dependencies**: Only requires standard C library

## Quick Start

### Basic Example

```c
#include <stdio.h>
#include <zigpug.h>

int main(void) {
    // Initialize context
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "Failed to initialize\n");
        return 1;
    }

    // Set variables
    zigpug_set_string(ctx, "name", "World");

    // Compile template
    char* html = zigpug_compile(ctx, "p Hello #{name}!");
    if (html) {
        printf("%s\n", html);
        zigpug_free_string(html);
    }

    // Cleanup
    zigpug_free(ctx);
    return 0;
}
```

### Compilation

```bash
# Using pkg-config (recommended)
gcc myapp.c -o myapp $(pkg-config --cflags --libs zpug)

# Manual
gcc myapp.c -o myapp -I/path/to/include -L/path/to/lib -lzig-pug -lm
```

## API Reference

### Context Management

#### `zigpug_init()`

Initialize a new zig-pug context.

```c
ZigPugContext* zigpug_init(void);
```

**Returns:**
- Context handle on success
- `NULL` on error (memory allocation failed)

**Example:**
```c
ZigPugContext* ctx = zigpug_init();
if (!ctx) {
    fprintf(stderr, "Initialization failed\n");
    return 1;
}
```

**Notes:**
- Each context has its own JavaScript runtime
- Contexts are **not thread-safe**
- Create one context per thread if needed

#### `zigpug_free()`

Free a zig-pug context and release all resources.

```c
void zigpug_free(ZigPugContext* ctx);
```

**Parameters:**
- `ctx` - Context handle (can be `NULL`)

**Example:**
```c
ZigPugContext* ctx = zigpug_init();
// ... use context ...
zigpug_free(ctx);  // Always call this
```

**Notes:**
- Safe to call with `NULL`
- Always call to avoid memory leaks
- Use RAII wrappers in C++ for automatic cleanup

### Template Compilation

#### `zigpug_compile()`

Compile a Pug template string to HTML.

```c
char* zigpug_compile(ZigPugContext* ctx, const char* pug_source);
```

**Parameters:**
- `ctx` - Context handle
- `pug_source` - Null-terminated Pug template string

**Returns:**
- Null-terminated HTML string (must be freed with `zigpug_free_string()`)
- `NULL` on error (use error functions to get details)

**Example:**
```c
const char* template =
    "doctype html\n"
    "html\n"
    "  body\n"
    "    h1 Hello #{name}";

char* html = zigpug_compile(ctx, template);
if (html) {
    printf("%s\n", html);
    zigpug_free_string(html);  // Don't forget!
} else {
    // Handle error (see Error Handling section)
}
```

**Notes:**
- Template is **not** modified
- Result must be freed with `zigpug_free_string()`
- Returns `NULL` on compilation errors

### Variable Management

#### `zigpug_set_string()`

Set a string variable in the context.

```c
bool zigpug_set_string(ZigPugContext* ctx, const char* key, const char* value);
```

**Parameters:**
- `ctx` - Context handle
- `key` - Variable name (null-terminated)
- `value` - String value (null-terminated)

**Returns:**
- `true` on success
- `false` on error

**Example:**
```c
zigpug_set_string(ctx, "name", "Alice");
zigpug_set_string(ctx, "email", "alice@example.com");
zigpug_set_string(ctx, "title", "Welcome Page");
```

**Notes:**
- Strings are copied internally
- UTF-8 strings fully supported
- Empty strings are valid

#### `zigpug_set_int()`

Set an integer variable in the context.

```c
bool zigpug_set_int(ZigPugContext* ctx, const char* key, int64_t value);
```

**Parameters:**
- `ctx` - Context handle
- `key` - Variable name (null-terminated)
- `value` - 64-bit signed integer

**Returns:**
- `true` on success
- `false` on error

**Example:**
```c
zigpug_set_int(ctx, "age", 25);
zigpug_set_int(ctx, "year", 2025);
zigpug_set_int(ctx, "count", 42);
```

**Notes:**
- Internally stored as JavaScript number
- Range: -(2^53-1) to (2^53-1) (JavaScript safe integer range)
- Use for counters, IDs, ages, etc.

#### `zigpug_set_bool()`

Set a boolean variable in the context.

```c
bool zigpug_set_bool(ZigPugContext* ctx, const char* key, bool value);
```

**Parameters:**
- `ctx` - Context handle
- `key` - Variable name (null-terminated)
- `value` - Boolean value (`true` or `false`)

**Returns:**
- `true` on success
- `false` on error

**Example:**
```c
zigpug_set_bool(ctx, "loggedIn", true);
zigpug_set_bool(ctx, "admin", false);
zigpug_set_bool(ctx, "verified", true);
```

**Notes:**
- Use C99 `<stdbool.h>` for `true`/`false`
- In C89, use `1` for true, `0` for false

#### `zigpug_set_array_json()`

Set an array variable from a JSON string.

```c
bool zigpug_set_array_json(ZigPugContext* ctx, const char* key, const char* json_str);
```

**Parameters:**
- `ctx` - Context handle
- `key` - Variable name (null-terminated)
- `json_str` - JSON array string

**Returns:**
- `true` on success
- `false` on error (invalid JSON)

**Example:**
```c
// String array
zigpug_set_array_json(ctx, "fruits", "[\"Apple\",\"Banana\",\"Orange\"]");

// Number array
zigpug_set_array_json(ctx, "numbers", "[1,2,3,4,5]");

// Mixed array
zigpug_set_array_json(ctx, "mixed", "[\"text\",42,true,null]");

// Empty array
zigpug_set_array_json(ctx, "empty", "[]");
```

**Template Usage:**
```pug
each fruit in fruits
  li= fruit

each num, i in numbers
  p Item #{i}: #{num}
```

**Notes:**
- JSON must be valid
- Mixed types supported
- Empty arrays are valid
- Nested arrays supported

#### `zigpug_set_object_json()`

Set an object variable from a JSON string.

```c
bool zigpug_set_object_json(ZigPugContext* ctx, const char* key, const char* json_str);
```

**Parameters:**
- `ctx` - Context handle
- `key` - Variable name (null-terminated)
- `json_str` - JSON object string

**Returns:**
- `true` on success
- `false` on error (invalid JSON)

**Example:**
```c
// Simple object
zigpug_set_object_json(ctx, "user",
    "{\"name\":\"Alice\",\"age\":30,\"admin\":true}");

// Nested object
zigpug_set_object_json(ctx, "config",
    "{\"server\":{\"host\":\"localhost\",\"port\":8080}}");

// Empty object
zigpug_set_object_json(ctx, "empty", "{}");
```

**Template Usage:**
```pug
p Name: #{user.name}
p Age: #{user.age}
p Admin: #{user.admin ? 'Yes' : 'No'}
p Host: #{config.server.host}
```

**Notes:**
- JSON must be valid
- Nested objects supported
- Property access with dot notation

### Error Handling

#### `zigpug_get_error_count()`

Get the number of compilation errors from the last compile call.

```c
size_t zigpug_get_error_count(ZigPugContext* ctx);
```

**Parameters:**
- `ctx` - Context handle

**Returns:**
- Number of errors (0 if no errors or no compilation done)

**Example:**
```c
char* html = zigpug_compile(ctx, template);
if (!html) {
    size_t count = zigpug_get_error_count(ctx);
    printf("Compilation failed with %zu error(s)\n", count);
}
```

#### `zigpug_get_error()`

Get detailed information about a specific compilation error.

```c
bool zigpug_get_error(
    ZigPugContext* ctx,
    size_t index,
    size_t* line_out,
    const char** message_out,
    const char** detail_out,
    const char** hint_out
);
```

**Parameters:**
- `ctx` - Context handle
- `index` - Error index (0 to count-1)
- `line_out` - Output: line number (can be `NULL`)
- `message_out` - Output: error message (can be `NULL`)
- `detail_out` - Output: detailed info (can be `NULL`, may be `NULL` even on success)
- `hint_out` - Output: hint for fixing (can be `NULL`, may be `NULL` even on success)

**Returns:**
- `true` if error exists at index
- `false` otherwise

**Example:**
```c
char* html = zigpug_compile(ctx, template);
if (!html) {
    size_t count = zigpug_get_error_count(ctx);

    for (size_t i = 0; i < count; i++) {
        size_t line;
        const char* message;
        const char* detail;
        const char* hint;

        if (zigpug_get_error(ctx, i, &line, &message, &detail, &hint)) {
            fprintf(stderr, "Error #%zu at line %zu: %s\n",
                    i + 1, line, message);

            if (detail) {
                fprintf(stderr, "  Detail: %s\n", detail);
            }

            if (hint) {
                fprintf(stderr, "  Hint: %s\n", hint);
            }
        }
    }
}
```

**Notes:**
- Error strings are owned by context (don't free them)
- Errors are cleared on next compilation
- `detail` and `hint` may be `NULL`

### Memory Management

#### `zigpug_free_string()`

Free a string returned by zig-pug.

```c
void zigpug_free_string(char* str);
```

**Parameters:**
- `str` - String to free (can be `NULL`)

**Example:**
```c
char* html = zigpug_compile(ctx, template);
if (html) {
    printf("%s\n", html);
    zigpug_free_string(html);  // Must call this
}
```

**Notes:**
- Safe to call with `NULL`
- Only free strings from `zigpug_compile()`
- Don't free error strings (they're owned by context)

### Utility Functions

#### `zigpug_version()`

Get the zig-pug version string.

```c
const char* zigpug_version(void);
```

**Returns:**
- Version string (do not free)

**Example:**
```c
printf("zig-pug version: %s\n", zigpug_version());
// Output: zig-pug version: 0.1.0
```

## Complete Examples

### Example 1: Basic Usage

```c
#include <stdio.h>
#include <zigpug.h>

int main(void) {
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) return 1;

    zigpug_set_string(ctx, "title", "My Page");
    zigpug_set_int(ctx, "year", 2025);

    char* html = zigpug_compile(ctx,
        "doctype html\n"
        "html\n"
        "  head\n"
        "    title= title\n"
        "  body\n"
        "    p Copyright #{year}");

    if (html) {
        printf("%s\n", html);
        zigpug_free_string(html);
    }

    zigpug_free(ctx);
    return 0;
}
```

### Example 2: With Arrays and Loops

```c
#include <stdio.h>
#include <zigpug.h>

int main(void) {
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) return 1;

    // Set array
    zigpug_set_array_json(ctx, "items",
        "[\"Apple\",\"Banana\",\"Orange\"]");

    // Compile template with loop
    char* html = zigpug_compile(ctx,
        "ul\n"
        "  each item in items\n"
        "    li= item");

    if (html) {
        printf("%s\n", html);
        zigpug_free_string(html);
    }

    zigpug_free(ctx);
    return 0;
}
```

### Example 3: Complete Error Handling

```c
#include <stdio.h>
#include <zigpug.h>

void compile_with_errors(ZigPugContext* ctx, const char* template) {
    char* html = zigpug_compile(ctx, template);

    if (html) {
        printf("Success:\n%s\n", html);
        zigpug_free_string(html);
    } else {
        fprintf(stderr, "Compilation failed!\n");

        size_t count = zigpug_get_error_count(ctx);
        for (size_t i = 0; i < count; i++) {
            size_t line;
            const char* message;
            const char* detail;
            const char* hint;

            if (zigpug_get_error(ctx, i, &line, &message, &detail, &hint)) {
                fprintf(stderr, "\nError #%zu:\n", i + 1);
                fprintf(stderr, "  Line: %zu\n", line);
                fprintf(stderr, "  Message: %s\n", message);

                if (detail) fprintf(stderr, "  Detail: %s\n", detail);
                if (hint) fprintf(stderr, "  Hint: %s\n", hint);
            }
        }
    }
}

int main(void) {
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) return 1;

    // This will fail (undefined variable)
    compile_with_errors(ctx, "p Hello #{undefinedVar}");

    zigpug_free(ctx);
    return 0;
}
```

### Example 4: File Templates

```c
#include <stdio.h>
#include <stdlib.h>
#include <zigpug.h>

char* read_file(const char* path) {
    FILE* f = fopen(path, "rb");
    if (!f) return NULL;

    fseek(f, 0, SEEK_END);
    long size = ftell(f);
    fseek(f, 0, SEEK_SET);

    char* buf = malloc(size + 1);
    fread(buf, 1, size, f);
    buf[size] = '\0';

    fclose(f);
    return buf;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <template.pug>\n", argv[0]);
        return 1;
    }

    char* template = read_file(argv[1]);
    if (!template) {
        fprintf(stderr, "Failed to read file\n");
        return 1;
    }

    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        free(template);
        return 1;
    }

    zigpug_set_string(ctx, "name", "User");

    char* html = zigpug_compile(ctx, template);
    if (html) {
        printf("%s\n", html);
        zigpug_free_string(html);
    }

    free(template);
    zigpug_free(ctx);
    return 0;
}
```

## Building Applications

### Using pkg-config

Create `myapp.c`:

```c
#include <stdio.h>
#include <zigpug.h>

int main(void) {
    ZigPugContext* ctx = zigpug_init();
    zigpug_set_string(ctx, "msg", "Hello");
    char* html = zigpug_compile(ctx, "p= msg");
    printf("%s\n", html);
    zigpug_free_string(html);
    zigpug_free(ctx);
    return 0;
}
```

Compile:

```bash
gcc myapp.c -o myapp $(pkg-config --cflags --libs zpug)
./myapp
```

### Using Makefile

```makefile
CC = gcc
CFLAGS = $(shell pkg-config --cflags zpug)
LIBS = $(shell pkg-config --libs zpug)

myapp: myapp.c
	$(CC) $(CFLAGS) myapp.c -o myapp $(LIBS)

clean:
	rm -f myapp
```

### Using CMake

```cmake
cmake_minimum_required(VERSION 3.10)
project(MyApp C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(ZPUG REQUIRED zpug)

add_executable(myapp myapp.c)
target_include_directories(myapp PRIVATE ${ZPUG_INCLUDE_DIRS})
target_link_libraries(myapp ${ZPUG_LIBRARIES})
```

## Thread Safety

### Not Thread-Safe

Each `ZigPugContext` is **not thread-safe**. Don't share contexts between threads.

**Wrong:**
```c
// DON'T DO THIS
ZigPugContext* ctx = zigpug_init();

void* thread1(void* arg) {
    zigpug_compile(ctx, template1);  // ❌ Race condition
}

void* thread2(void* arg) {
    zigpug_compile(ctx, template2);  // ❌ Race condition
}
```

### Thread-Safe Approach 1: Context Per Thread

```c
void* worker_thread(void* template_ptr) {
    const char* template = (const char*)template_ptr;

    // Each thread has its own context
    ZigPugContext* ctx = zigpug_init();

    char* html = zigpug_compile(ctx, template);
    printf("%s\n", html);
    zigpug_free_string(html);

    zigpug_free(ctx);
    return NULL;
}
```

### Thread-Safe Approach 2: Mutex

```c
#include <pthread.h>

ZigPugContext* shared_ctx;
pthread_mutex_t ctx_mutex = PTHREAD_MUTEX_INITIALIZER;

void* worker_thread(void* template_ptr) {
    const char* template = (const char*)template_ptr;

    pthread_mutex_lock(&ctx_mutex);
    char* html = zigpug_compile(shared_ctx, template);
    pthread_mutex_unlock(&ctx_mutex);

    printf("%s\n", html);
    zigpug_free_string(html);
    return NULL;
}
```

## Platform Support

### Supported Platforms

- ✅ **Linux** (x86_64, ARM64)
- ✅ **macOS** (Intel, Apple Silicon)
- ✅ **Windows** (x86_64)

### Library Files

- **Static**: `libzig-pug.a` (Linux/macOS), `zig-pug.lib` (Windows)
- **Shared**: `libzig-pug.so` (Linux), `libzig-pug.dylib` (macOS), `zig-pug.dll` (Windows)

### Platform Paths

- Linux x64: `libs/linux-x64/`
- Linux ARM64: `libs/linux-arm64/`
- macOS Intel: `libs/darwin-x64/`
- macOS Apple Silicon: `libs/darwin-arm64/`
- Windows: `libs/win32-x64/`

## Performance Tips

1. **Reuse Contexts**: Creating contexts is expensive
   ```c
   // Good: Reuse context
   ZigPugContext* ctx = zigpug_init();
   for (int i = 0; i < 1000; i++) {
       char* html = zigpug_compile(ctx, templates[i]);
       // ... use html ...
       zigpug_free_string(html);
   }
   zigpug_free(ctx);
   ```

2. **Pre-load Templates**: Read files once at startup
   ```c
   char* template = read_file("template.pug");
   for (int i = 0; i < 1000; i++) {
       char* html = zigpug_compile(ctx, template);
       // ...
   }
   free(template);
   ```

3. **Static Linking**: Use `.a` files for better performance

## Common Patterns

### RAII Wrapper (C++)

```cpp
class ZigPugContext {
    ::ZigPugContext* ctx;
public:
    ZigPugContext() : ctx(zigpug_init()) {
        if (!ctx) throw std::runtime_error("Init failed");
    }
    ~ZigPugContext() { zigpug_free(ctx); }

    // Prevent copying
    ZigPugContext(const ZigPugContext&) = delete;
    ZigPugContext& operator=(const ZigPugContext&) = delete;

    operator ::ZigPugContext*() { return ctx; }
};

// Usage
ZigPugContext ctx;  // Automatic cleanup
char* html = zigpug_compile(ctx, template);
```

### Error Handling Helper

```c
void print_errors(ZigPugContext* ctx) {
    size_t count = zigpug_get_error_count(ctx);
    for (size_t i = 0; i < count; i++) {
        size_t line;
        const char* msg;
        if (zigpug_get_error(ctx, i, &line, &msg, NULL, NULL)) {
            fprintf(stderr, "Line %zu: %s\n", line, msg);
        }
    }
}
```

## See Also

- **[Examples](../examples/c/)** - Complete working examples
- **[pkg-config Guide](PKGCONFIG.md)** - Installation and usage
- **[Pug Syntax](../README.md#pug-syntax)** - Template syntax reference
- **[Node.js API](../nodejs/README.md)** - JavaScript API comparison

## License

MIT License - see [LICENSE](../LICENSE) for details.
