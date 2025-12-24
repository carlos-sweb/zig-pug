# Using zig-pug from C/C++

This guide shows you how to use zig-pug from C and C++ applications. For complete API reference, see [C API Documentation](c-api.md).

## Quick Start

### 1. Installation

**Option A: Using pre-built libraries**

Download the latest release from [GitHub Releases](https://github.com/carlos-sweb/zig-pug/releases) or build from source:

```bash
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
./build-all.sh
```

After building, you'll have:
- **Headers**: `include/zigpug.h`
- **Static libraries**: `libs/<platform>/libzig-pug.a` (or `.lib` on Windows)
- **Shared libraries**: `libs/<platform>/libzig-pug.so` (or `.dll`/`.dylib`)

**Option B: Using pkg-config (recommended)**

After building, install the pkg-config file:

```bash
sudo make install-pkgconfig
```

### 2. Your First Program

Create `hello.c`:

```c
#include <stdio.h>
#include <zigpug.h>

int main(void) {
    // Initialize context
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "Failed to initialize zig-pug\n");
        return 1;
    }

    // Set variables
    zigpug_set_string(ctx, "name", "World");

    // Compile template
    char* html = zigpug_compile(ctx, "p Hello #{name}!");

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

### 3. Compile

**With pkg-config:**
```bash
gcc hello.c -o hello $(pkg-config --cflags --libs zpug)
./hello
```

**Without pkg-config:**
```bash
# Linux
gcc hello.c -o hello -I/path/to/include -L/path/to/libs/linux-x64 -lzig-pug -lm

# macOS
gcc hello.c -o hello -I/path/to/include -L/path/to/libs/darwin-x64 -lzig-pug

# Windows (MinGW)
gcc hello.c -o hello.exe -I/path/to/include -L/path/to/libs/win32-x64 -lzig-pug
```

**Output:**
```html
<p>Hello World!</p>
```

## Common Use Cases

### Working with Variables

```c
ZigPugContext* ctx = zigpug_init();

// Strings
zigpug_set_string(ctx, "title", "My Page");
zigpug_set_string(ctx, "author", "Alice");

// Numbers
zigpug_set_int(ctx, "year", 2025);
zigpug_set_int(ctx, "count", 42);

// Booleans
zigpug_set_bool(ctx, "isAdmin", true);
zigpug_set_bool(ctx, "isActive", false);

// Use in template
char* html = zigpug_compile(ctx,
    "doctype html\n"
    "html\n"
    "  head\n"
    "    title= title\n"
    "  body\n"
    "    h1 Welcome\n"
    "    p Author: #{author}\n"
    "    p Year: #{year}\n"
    "    if isAdmin\n"
    "      p.admin Admin Panel");

zigpug_free_string(html);
zigpug_free(ctx);
```

### Working with Arrays

**Simple approach (JSON strings):**

```c
ZigPugContext* ctx = zigpug_init();

// Set array from JSON
zigpug_set_array_json(ctx, "fruits",
    "[\"Apple\",\"Banana\",\"Orange\"]");

// Template with loop
char* html = zigpug_compile(ctx,
    "ul\n"
    "  each fruit in fruits\n"
    "    li= fruit");

printf("%s\n", html);
// Output: <ul><li>Apple</li><li>Banana</li><li>Orange</li></ul>

zigpug_free_string(html);
zigpug_free(ctx);
```

**Dynamic approach (Builder API):**

```c
ZigPugContext* ctx = zigpug_init();

// Build array dynamically
ZigPugArray* items = zigpug_array_create(ctx);

// Add items from a loop
const char* products[] = {"Laptop", "Mouse", "Keyboard"};
for (int i = 0; i < 3; i++) {
    zigpug_array_add_string(items, products[i]);
}

// Set the array
zigpug_set_array(ctx, "products", items);
zigpug_array_free(items);  // Safe to free after set

// Compile template
char* html = zigpug_compile(ctx,
    "h2 Products\n"
    "ul\n"
    "  each product in products\n"
    "    li= product");

printf("%s\n", html);
zigpug_free_string(html);
zigpug_free(ctx);
```

### Working with Objects

**Simple approach (JSON strings):**

```c
ZigPugContext* ctx = zigpug_init();

// Set object from JSON
zigpug_set_object_json(ctx, "user",
    "{\"name\":\"Alice\",\"age\":30,\"admin\":true}");

// Template
char* html = zigpug_compile(ctx,
    "div.user\n"
    "  h2= user.name\n"
    "  p Age: #{user.age}\n"
    "  if user.admin\n"
    "    span.badge Admin");

printf("%s\n", html);
zigpug_free_string(html);
zigpug_free(ctx);
```

**Dynamic approach (Builder API):**

```c
ZigPugContext* ctx = zigpug_init();

// Build object dynamically
ZigPugObject* user = zigpug_object_create(ctx);
zigpug_object_set_string(user, "name", "Bob");
zigpug_object_set_int(user, "age", 25);
zigpug_object_set_double(user, "score", 98.5);
zigpug_object_set_bool(user, "verified", true);

// Set the object
zigpug_set_object(ctx, "user", user);
zigpug_object_free(user);  // Safe to free after set

// Compile template
char* html = zigpug_compile(ctx,
    "div.profile\n"
    "  h2= user.name\n"
    "  p Age: #{user.age}\n"
    "  p Score: #{user.score}%\n"
    "  if user.verified\n"
    "    span ✓ Verified");

printf("%s\n", html);
zigpug_free_string(html);
zigpug_free(ctx);
```

### Loading Templates from Files

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

    char* buffer = malloc(size + 1);
    fread(buffer, 1, size, f);
    buffer[size] = '\0';

    fclose(f);
    return buffer;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <template.pug>\n", argv[0]);
        return 1;
    }

    // Read template from file
    char* template = read_file(argv[1]);
    if (!template) {
        fprintf(stderr, "Failed to read file\n");
        return 1;
    }

    // Compile
    ZigPugContext* ctx = zigpug_init();
    zigpug_set_string(ctx, "title", "My Page");

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

### Error Handling

```c
ZigPugContext* ctx = zigpug_init();
zigpug_set_string(ctx, "name", "Alice");

const char* template =
    "if undefinedVar\n"  // This will cause an error
    "  p Hello";

char* html = zigpug_compile(ctx, template);

if (!html) {
    // Get error count
    size_t count = zigpug_get_error_count(ctx);
    fprintf(stderr, "Compilation failed with %zu error(s):\n", count);

    // Print all errors
    for (size_t i = 0; i < count; i++) {
        size_t line;
        const char* message;
        const char* detail;
        const char* hint;

        if (zigpug_get_error(ctx, i, &line, &message, &detail, &hint)) {
            fprintf(stderr, "\nError #%zu:\n", i + 1);
            fprintf(stderr, "  Line: %zu\n", line);
            fprintf(stderr, "  Message: %s\n", message);

            if (detail) {
                fprintf(stderr, "  Detail: %s\n", detail);
            }
            if (hint) {
                fprintf(stderr, "  Hint: %s\n", hint);
            }
        }
    }
} else {
    printf("%s\n", html);
    zigpug_free_string(html);
}

zigpug_free(ctx);
```

## Build Integration

### Using Makefile

```makefile
CC = gcc
CFLAGS = -Wall -Wextra -std=c99
LIBS = $(shell pkg-config --libs zpug)
INCLUDES = $(shell pkg-config --cflags zpug)

myapp: myapp.c
	$(CC) $(CFLAGS) $(INCLUDES) myapp.c -o myapp $(LIBS)

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

## C++ Integration

zig-pug works seamlessly with C++:

```cpp
#include <iostream>
#include <string>
#include <memory>
#include <zigpug.h>

// RAII wrapper
class ZigPugContext {
    ::ZigPugContext* ctx;
public:
    ZigPugContext() : ctx(zigpug_init()) {
        if (!ctx) throw std::runtime_error("Failed to initialize zig-pug");
    }

    ~ZigPugContext() {
        zigpug_free(ctx);
    }

    // Delete copy constructor/assignment
    ZigPugContext(const ZigPugContext&) = delete;
    ZigPugContext& operator=(const ZigPugContext&) = delete;

    // Conversion operator
    operator ::ZigPugContext*() { return ctx; }

    // Helper methods
    void setString(const std::string& key, const std::string& value) {
        zigpug_set_string(ctx, key.c_str(), value.c_str());
    }

    void setInt(const std::string& key, int64_t value) {
        zigpug_set_int(ctx, key.c_str(), value);
    }

    std::string compile(const std::string& template_str) {
        char* html = zigpug_compile(ctx, template_str.c_str());
        if (!html) {
            throw std::runtime_error("Compilation failed");
        }
        std::string result(html);
        zigpug_free_string(html);
        return result;
    }
};

int main() {
    try {
        ZigPugContext ctx;  // Automatic cleanup

        ctx.setString("name", "Alice");
        ctx.setInt("age", 30);

        std::string html = ctx.compile("p Hello #{name}, age #{age}");
        std::cout << html << std::endl;

    } catch (const std::exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
```

## Best Practices

### 1. Reuse Contexts

Creating contexts is expensive. Reuse them:

```c
ZigPugContext* ctx = zigpug_init();

// Compile many templates with same context
for (int i = 0; i < 1000; i++) {
    char* html = zigpug_compile(ctx, templates[i]);
    // ... use html ...
    zigpug_free_string(html);
}

zigpug_free(ctx);  // Cleanup once at the end
```

### 2. Choose the Right API

**Use JSON strings when:**
- Data is static or simple
- Data is already in JSON format
- Quick prototyping

**Use Builder API when:**
- Building data from loops
- Data from databases or APIs
- Need type safety
- Complex nested structures

### 3. Handle Errors Properly

Always check return values and handle errors:

```c
ZigPugContext* ctx = zigpug_init();
if (!ctx) {
    // Handle initialization error
}

char* html = zigpug_compile(ctx, template);
if (!html) {
    // Handle compilation error
    // Use zigpug_get_error_count() and zigpug_get_error()
}

zigpug_free_string(html);
zigpug_free(ctx);
```

### 4. Memory Management

Follow the ownership rules:

```c
// You own and must free:
char* html = zigpug_compile(ctx, template);
zigpug_free_string(html);  // YOU must call this

// Library owns, don't free:
const char* error_msg;
zigpug_get_error(ctx, 0, NULL, &error_msg, NULL, NULL);
// Don't call free(error_msg)!

// Builders are safe to free after set:
ZigPugArray* arr = zigpug_array_create(ctx);
zigpug_array_add_string(arr, "value");
zigpug_set_array(ctx, "key", arr);
zigpug_array_free(arr);  // Safe - data is copied
```

## Platform Support

zig-pug works on all major platforms:

- ✅ **Linux** (x86_64, ARM64)
- ✅ **macOS** (Intel, Apple Silicon)
- ✅ **Windows** (x86_64 with MinGW)
- ✅ **Android/Termux** (ARM64)

### Thread Safety

Each `ZigPugContext` is **not thread-safe**. For multi-threaded applications:

**Option 1: Context per thread**
```c
void* worker_thread(void* arg) {
    ZigPugContext* ctx = zigpug_init();  // Each thread has its own

    char* html = zigpug_compile(ctx, template);
    // ... use html ...

    zigpug_free_string(html);
    zigpug_free(ctx);
    return NULL;
}
```

**Option 2: Mutex protection**
```c
pthread_mutex_t ctx_mutex = PTHREAD_MUTEX_INITIALIZER;
ZigPugContext* shared_ctx;

void* worker_thread(void* arg) {
    pthread_mutex_lock(&ctx_mutex);
    char* html = zigpug_compile(shared_ctx, template);
    pthread_mutex_unlock(&ctx_mutex);

    // ... use html (outside critical section) ...

    zigpug_free_string(html);
    return NULL;
}
```

## Examples

Complete working examples are available in [examples/c/](../examples/c/):

- **01-basic.c** - Basic usage with variables
- **02-variables.c** - All variable types
- **03-arrays-objects.c** - Arrays and objects with JSON
- **04-error-handling.c** - Complete error handling
- **05-file-template.c** - Loading templates from files
- **06-builder-api.c** - Advanced Builder API usage

## Additional Resources

- **[C API Reference](c-api.md)** - Complete API documentation
- **[C Examples](../examples/c/)** - Working code examples
- **[pkg-config Guide](PKGCONFIG.md)** - Integration with build systems
- **[GitHub Repository](https://github.com/carlos-sweb/zig-pug)** - Source code and issues

## Support

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)
- **Discussions**: [GitHub Discussions](https://github.com/carlos-sweb/zig-pug/discussions)

## License

MIT License - see [LICENSE](../LICENSE) for details.
