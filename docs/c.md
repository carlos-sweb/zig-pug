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

**Using TCC (Tiny C Compiler) - Fast compilation:**
```bash
# Install TCC (if not installed)
# Ubuntu/Debian: sudo apt-get install tcc
# Arch: sudo pacman -S tcc
# macOS: brew install tcc

# Compile with TCC (very fast!)
tcc -run hello.c -I/path/to/include -L/path/to/libs/linux-x64 -lzig-pug -lm

# Or compile to executable
tcc hello.c -o hello -I/path/to/include -L/path/to/libs/linux-x64 -lzig-pug -lm
./hello
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

## Using TCC (Tiny C Compiler)

[TCC](https://bellard.org/tcc/) is an incredibly fast C compiler, perfect for rapid prototyping and scripting with C. It can compile and run code in a single step!

### Why TCC?

- ⚡ **Extremely fast**: 9x faster compilation than GCC
- 🚀 **Instant execution**: `-run` flag compiles and runs in one step
- 📦 **Lightweight**: ~100KB binary, minimal dependencies
- 🎯 **Perfect for scripting**: Use C like Python or JavaScript
- ✅ **C99 compatible**: Full ANSI C and most C99 features

### Installation

```bash
# Ubuntu/Debian
sudo apt-get install tcc

# Arch Linux
sudo pacman -S tcc

# Fedora
sudo dnf install tcc

# macOS (Homebrew)
brew install tcc

# Build from source
git clone https://repo.or.cz/tinycc.git
cd tinycc
./configure && make && sudo make install
```

### Quick Start with TCC

**1. Script-style execution (no compilation step):**

```bash
# Run directly - compile and execute instantly!
tcc -run hello.c -I./include -L./libs/linux-x64 -lzig-pug -lm
```

**2. Template processor script:**

Create `process-template.c`:
```c
#!/usr/bin/tcc -run -I./include -L./libs/linux-x64 -lzig-pug -lm

#include <stdio.h>
#include <zigpug.h>

int main(int argc, char** argv) {
    if (argc < 3) {
        fprintf(stderr, "Usage: %s <template> <name>\n", argv[0]);
        return 1;
    }

    ZigPugContext* ctx = zigpug_init();
    zigpug_set_string(ctx, "name", argv[2]);

    char* html = zigpug_compile(ctx, argv[1]);
    if (html) {
        printf("%s\n", html);
        zigpug_free_string(html);
    }

    zigpug_free(ctx);
    return 0;
}
```

Make it executable and run:
```bash
chmod +x process-template.c
./process-template.c "p Hello #{name}!" "Alice"
# Output: <p>Hello Alice!</p>
```

**3. Interactive template REPL:**

Create `pug-repl.c`:
```c
#!/usr/bin/tcc -run -I./include -L./libs/linux-x64 -lzig-pug -lm

#include <stdio.h>
#include <string.h>
#include <zigpug.h>

int main(void) {
    ZigPugContext* ctx = zigpug_init();
    char line[1024];

    printf("zig-pug REPL (TCC mode)\n");
    printf("Enter Pug templates (Ctrl+D to exit):\n\n");

    while (1) {
        printf("> ");
        if (!fgets(line, sizeof(line), stdin)) break;

        // Remove newline
        line[strcspn(line, "\n")] = 0;
        if (strlen(line) == 0) continue;

        // Compile and print
        char* html = zigpug_compile(ctx, line);
        if (html) {
            printf("%s\n", html);
            zigpug_free_string(html);
        } else {
            printf("Error: Compilation failed\n");
        }
    }

    zigpug_free(ctx);
    printf("\nGoodbye!\n");
    return 0;
}
```

Run it:
```bash
chmod +x pug-repl.c
./pug-repl.c
> p Hello World
<p>Hello World</p>
> div.container
<div class="container"></div>
```

**4. File processor with TCC:**

Create `compile-pug-file.c`:
```c
#!/usr/bin/tcc -run -I./include -L./libs/linux-x64 -lzig-pug -lm

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

    char* template = read_file(argv[1]);
    if (!template) {
        fprintf(stderr, "Error: Cannot read file '%s'\n", argv[1]);
        return 1;
    }

    ZigPugContext* ctx = zigpug_init();
    char* html = zigpug_compile(ctx, template);

    if (html) {
        printf("%s\n", html);
        zigpug_free_string(html);
    } else {
        fprintf(stderr, "Compilation failed\n");
    }

    free(template);
    zigpug_free(ctx);
    return 0;
}
```

Use it:
```bash
chmod +x compile-pug-file.c
./compile-pug-file.c template.pug > output.html
```

### TCC Compilation Modes

**1. Run directly (script mode):**
```bash
tcc -run myprogram.c -I./include -L./libs/linux-x64 -lzig-pug -lm
```

**2. Compile to executable:**
```bash
tcc myprogram.c -o myprogram -I./include -L./libs/linux-x64 -lzig-pug -lm
./myprogram
```

**3. Compile to object file:**
```bash
tcc -c myprogram.c -I./include
```

**4. Use as shebang (script-style):**
```c
#!/usr/bin/tcc -run -I./include -L./libs/linux-x64 -lzig-pug -lm
#include <stdio.h>
// ... your code ...
```

### TCC with Builder API

```c
#!/usr/bin/tcc -run -I./include -L./libs/linux-x64 -lzig-pug -lm

#include <stdio.h>
#include <zigpug.h>

int main(void) {
    ZigPugContext* ctx = zigpug_init();

    // Build array dynamically
    ZigPugArray* fruits = zigpug_array_create(ctx);
    zigpug_array_add_string(fruits, "Apple");
    zigpug_array_add_string(fruits, "Banana");
    zigpug_array_add_string(fruits, "Orange");
    zigpug_set_array(ctx, "fruits", fruits);
    zigpug_array_free(fruits);

    // Build object
    ZigPugObject* user = zigpug_object_create(ctx);
    zigpug_object_set_string(user, "name", "Alice");
    zigpug_object_set_int(user, "age", 30);
    zigpug_set_object(ctx, "user", user);
    zigpug_object_free(user);

    // Compile
    char* html = zigpug_compile(ctx,
        "div.profile\n"
        "  h2= user.name\n"
        "  p Age: #{user.age}\n"
        "  h3 Favorite Fruits\n"
        "  ul\n"
        "    each fruit in fruits\n"
        "      li= fruit");

    if (html) {
        printf("%s\n", html);
        zigpug_free_string(html);
    }

    zigpug_free(ctx);
    return 0;
}
```

Run instantly:
```bash
chmod +x build-example.c
./build-example.c
```

### TCC Performance Comparison

| Compiler | Compile Time | Run Time | Total | Use Case |
|----------|--------------|----------|-------|----------|
| **TCC** | 0.01s | 0.001s | **0.011s** | Development, scripting |
| GCC -O0 | 0.09s | 0.001s | 0.091s | Debug builds |
| GCC -O2 | 0.15s | 0.0008s | 0.151s | Production |

TCC is **~9x faster** for compilation, perfect for rapid iteration!

### When to Use TCC vs GCC

**Use TCC for:**
- ✅ Rapid prototyping and development
- ✅ C scripting (replacing shell scripts)
- ✅ Quick testing and experimentation
- ✅ Interactive development (REPL-style)
- ✅ Build tools and generators
- ✅ Teaching and learning C

**Use GCC/Clang for:**
- ✅ Production builds
- ✅ Performance-critical code
- ✅ Advanced optimizations
- ✅ Cross-platform compatibility
- ✅ Modern C standards (C11, C17, C23)

### TCC Limitations

- No optimization flags (similar to GCC -O0)
- Limited C11 support (mostly C99)
- Smaller standard library
- Platform-specific features may not work

For zig-pug usage, TCC works perfectly for development and scripting!

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
