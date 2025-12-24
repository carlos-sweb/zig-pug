# zig-pug C API Examples

Complete examples demonstrating the zig-pug C API.

## Examples

### 01-basic.c
Basic usage: initialization, variables, compilation, and cleanup.

```c
ZigPugContext* ctx = zigpug_init();
zigpug_set_string(ctx, "name", "World");
char* html = zigpug_compile(ctx, "p Hello #{name}!");
zigpug_free_string(html);
zigpug_free(ctx);
```

### 02-variables.c
All variable types: strings, integers, booleans, and expressions.

```c
zigpug_set_string(ctx, "username", "Carlos");
zigpug_set_int(ctx, "age", 28);
zigpug_set_bool(ctx, "admin", true);
```

### 03-arrays-objects.c
Arrays and objects using JSON strings with loops.

```c
zigpug_set_array_json(ctx, "items", "[\"Apple\",\"Banana\",\"Orange\"]");
zigpug_set_object_json(ctx, "user", "{\"name\":\"Alice\",\"age\":30}");
```

### 04-error-handling.c
Complete error handling with detailed error information.

```c
if (!html) {
    size_t count = zigpug_get_error_count(ctx);
    for (size_t i = 0; i < count; i++) {
        size_t line;
        const char* message;
        zigpug_get_error(ctx, i, &line, &message, NULL, NULL);
        printf("Error at line %zu: %s\n", line, message);
    }
}
```

### 05-file-template.c
Reading and compiling templates from files.

```c
char* template = read_file("template.pug");
char* html = zigpug_compile(ctx, template);
free(template);
```

### 06-builder-api.c
**⭐ BUILDER API - Para Geeks Avanzados**

Demonstrates the powerful Builder API for dynamic array and object construction. Perfect for constructing data structures programmatically from databases, APIs, or any dynamic source.

```c
// Dynamic array construction
ZigPugArray* arr = zigpug_array_create(ctx);
zigpug_array_add_string(arr, "Apple");
zigpug_array_add_int(arr, 42);
zigpug_array_add_bool(arr, true);
zigpug_set_array(ctx, "items", arr);
zigpug_array_free(arr);

// Dynamic object construction
ZigPugObject* obj = zigpug_object_create(ctx);
zigpug_object_set_string(obj, "name", "Alice");
zigpug_object_set_int(obj, "age", 30);
zigpug_object_set_bool(obj, "admin", true);
zigpug_set_object(ctx, "user", obj);
zigpug_object_free(obj);
```

**Why Builder API?**
- Type-safe: No string escaping needed
- Dynamic: Build from loops/databases
- Clean: No JSON string construction
- Powerful: Mixed types supported

## Building with Make

```bash
# Build all examples
make

# Build specific example
make 01-basic

# Run specific example
make run-basic

# Run all examples
make run-all

# Clean
make clean
```

## Building with CMake

```bash
# Create build directory
mkdir build
cd build

# Configure
cmake ..

# Build
make

# Run
./01-basic
./02-variables
./03-arrays-objects
./04-error-handling
echo "p Hello" > template.pug && ./05-file-template template.pug
```

## Manual Compilation

### Linux/macOS

```bash
gcc 01-basic.c -o 01-basic \
    -I../../include \
    -L../../libs/linux-x64 \
    -lzig-pug -lm

./01-basic
```

### Platform-specific library paths

- **Linux x64**: `libs/linux-x64/`
- **Linux ARM64**: `libs/linux-arm64/`
- **macOS Intel**: `libs/darwin-x64/`
- **macOS Apple Silicon**: `libs/darwin-arm64/`
- **Windows**: `libs/win32-x64/`

## Requirements

- C compiler (GCC, Clang, or MSVC)
- zig-pug library (`.a` or `.so`/`.dylib`/`.dll`)
- Header file (`zigpug.h`)

## API Functions

See [../../docs/c-api.md](../../docs/c-api.md) for complete API documentation.

### Core Functions

- `zigpug_init()` - Initialize context
- `zigpug_free()` - Free context
- `zigpug_compile()` - Compile template to HTML
- `zigpug_free_string()` - Free HTML string

### Variable Functions

- `zigpug_set_string()` - Set string variable
- `zigpug_set_int()` - Set integer variable
- `zigpug_set_bool()` - Set boolean variable
- `zigpug_set_array_json()` - Set array from JSON
- `zigpug_set_object_json()` - Set object from JSON

### Error Functions

- `zigpug_get_error_count()` - Get number of errors
- `zigpug_get_error()` - Get specific error details

### Utility Functions

- `zigpug_version()` - Get version string

## See Also

- [C API Documentation](../../docs/c-api.md)
- [pkg-config Usage](../../docs/PKGCONFIG.md)
- [Main Repository](https://github.com/carlos-sweb/zig-pug)
