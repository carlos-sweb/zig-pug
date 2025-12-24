# zig-pug C++ API

Modern C++ wrapper for zig-pug with RAII, exceptions, and STL integration.

## Overview

The C++ API (`zigpug.hpp`) provides a high-level, idiomatic C++ interface over the C API:

- **RAII**: Automatic resource management with destructors
- **Exceptions**: Type-safe error handling with detailed error information
- **STL Integration**: `std::string`, `std::vector`, `std::map` support
- **Fluent Interface**: Method chaining for readable code
- **Move Semantics**: Efficient resource transfer (C++11+)
- **String View**: Zero-copy operations (C++17+, optional)
- **Header-Only**: Just include `zigpug.hpp`

## Quick Start

```cpp
#include <iostream>
#include "zigpug.hpp"

int main() {
    try {
        zigpug::Context ctx;

        ctx.set("name", "Alice")
           .set("age", int64_t(30))
           .set("active", true);

        std::string html = ctx.compile("p Hello #{name}!");
        std::cout << html << std::endl;

    } catch (const zigpug::Exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }

    return 0;
}
```

## Building

### Requirements

- C++11 or later compiler
- zig-pug library (libzig-pug.a or libzig-pug.so)

### Compilation

```bash
# Using static library (recommended)
g++ -std=c++11 -I/path/to/zig-pug/include \
    example.cpp -o example \
    /path/to/libzig-pug.a -lm -ldl -lpthread

# Using shared library
g++ -std=c++11 -I/path/to/zig-pug/include \
    example.cpp -o example \
    -L/path/to/libs -lzig-pug -Wl,-rpath,/path/to/libs
```

### With pkg-config

```bash
g++ -std=c++11 example.cpp -o example \
    $(pkg-config --cflags --libs zig-pug)
```

## API Reference

### Namespace

All C++ API is in the `zigpug` namespace:

```cpp
namespace zigpug {
    class Exception;
    class InitializationError;
    class CompilationError;
    class VariableError;

    class Context;
    class Array;
    class Object;
}
```

### zigpug::Context

Main class for template compilation.

#### Constructor

```cpp
Context();
```

Creates a new context. Throws `InitializationError` if initialization fails.

```cpp
zigpug::Context ctx;  // RAII - automatically cleaned up
```

#### Methods

**compile** - Compile a Pug template to HTML

```cpp
std::string compile(const std::string& pug_source);
std::string compile(const char* pug_source);
std::string compile(std::string_view pug_source);  // C++17
```

Throws `CompilationError` if compilation fails.

```cpp
std::string html = ctx.compile("p Hello #{name}!");
```

**set** - Set variables (fluent interface)

```cpp
Context& set(const std::string& key, const std::string& value);
Context& set(const std::string& key, int64_t value);
Context& set(const std::string& key, bool value);
Context& set(const std::string& key, const Array& arr);
Context& set(const std::string& key, const Object& obj);
```

Returns `*this` for method chaining. Throws `VariableError` if setting fails.

```cpp
ctx.set("name", "Alice")
   .set("age", int64_t(30))
   .set("active", true);
```

**setArrayJson / setObjectJson** - Set from JSON strings

```cpp
Context& setArrayJson(const std::string& key, const std::string& json);
Context& setObjectJson(const std::string& key, const std::string& json);
```

```cpp
ctx.setArrayJson("items", R"(["Apple","Banana","Orange"])");
ctx.setObjectJson("user", R"({"name":"Alice","age":30})");
```

**setAll** - Set multiple variables from a map

```cpp
Context& setAll(const std::map<std::string, std::string>& vars);
```

```cpp
std::map<std::string, std::string> vars = {
    {"title", "Dashboard"},
    {"username", "john"}
};
ctx.setAll(vars);
```

**version** - Get zig-pug version (static)

```cpp
static std::string version();
```

```cpp
std::cout << "Version: " << zigpug::Context::version() << std::endl;
```

### zigpug::Array

Array builder with fluent interface.

#### Constructor

```cpp
explicit Array(Context& ctx);
```

Creates array builder. Throws `InitializationError` on failure.

```cpp
zigpug::Array arr(ctx);
```

#### Methods

**add** - Add elements to the array

```cpp
Array& add(const std::string& value);
Array& add(const char* value);
Array& add(std::string_view value);  // C++17
Array& add(int64_t value);
Array& add(double value);
Array& add(bool value);
Array& addNull();
```

Returns `*this` for chaining. Throws `VariableError` on failure.

```cpp
arr.add("Apple")
   .add("Banana")
   .add(42)
   .add(3.14)
   .add(true)
   .addNull();
```

### zigpug::Object

Object builder with fluent interface.

#### Constructor

```cpp
explicit Object(Context& ctx);
```

Creates object builder. Throws `InitializationError` on failure.

```cpp
zigpug::Object obj(ctx);
```

#### Methods

**set** - Set object properties

```cpp
Object& set(const std::string& key, const std::string& value);
Object& set(const char* key, const char* value);
Object& set(const std::string& key, int64_t value);
Object& set(const std::string& key, double value);
Object& set(const std::string& key, bool value);
Object& setNull(const std::string& key);
```

Returns `*this` for chaining. Throws `VariableError` on failure.

```cpp
obj.set("name", "Alice")
   .set("age", int64_t(30))
   .set("admin", true)
   .set("score", 95.5)
   .setNull("optional");
```

### Exception Classes

All exceptions inherit from `zigpug::Exception` which inherits from `std::runtime_error`.

#### zigpug::Exception

Base class for all zig-pug exceptions.

```cpp
class Exception : public std::runtime_error {
public:
    explicit Exception(const std::string& message);
};
```

#### zigpug::InitializationError

Thrown when context/builder initialization fails.

```cpp
class InitializationError : public Exception {
    // Automatically provides message
};
```

#### zigpug::CompilationError

Thrown when template compilation fails. Provides detailed error information.

```cpp
class CompilationError : public Exception {
public:
    struct Error {
        size_t line;
        std::string message;
        std::string detail;
        std::string hint;
    };

    const std::vector<Error>& errors() const;
};
```

Example:

```cpp
try {
    ctx.compile(invalid_template);
} catch (const zigpug::CompilationError& e) {
    std::cerr << "Compilation failed: " << e.what() << std::endl;

    for (const auto& err : e.errors()) {
        std::cerr << "  Line " << err.line << ": " << err.message << std::endl;
        if (!err.detail.empty()) {
            std::cerr << "    Detail: " << err.detail << std::endl;
        }
        if (!err.hint.empty()) {
            std::cerr << "    Hint: " << err.hint << std::endl;
        }
    }
}
```

#### zigpug::VariableError

Thrown when variable operations fail.

```cpp
class VariableError : public Exception {
public:
    explicit VariableError(const std::string& message);
};
```

## Examples

### Basic Usage

```cpp
#include "zigpug.hpp"
#include <iostream>

int main() {
    try {
        zigpug::Context ctx;

        ctx.set("name", "Alice")
           .set("age", int64_t(30))
           .set("active", true);

        std::string html = ctx.compile(R"(
doctype html
html
  head
    title Welcome
  body
    h1 Hello #{name}!
    p Age: #{age}
    if active
      p.status Active user
)");

        std::cout << html << std::endl;
        return 0;

    } catch (const zigpug::Exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
```

### Arrays

```cpp
zigpug::Context ctx;

zigpug::Array fruits(ctx);
fruits.add("Apple")
      .add("Banana")
      .add("Orange");

ctx.set("fruits", fruits);

std::string html = ctx.compile(R"(
ul
  each fruit in fruits
    li= fruit
)");
```

### Objects

```cpp
zigpug::Context ctx;

zigpug::Object user(ctx);
user.set("name", "Alice")
    .set("email", "alice@example.com")
    .set("age", int64_t(30))
    .set("admin", true);

ctx.set("user", user);

std::string html = ctx.compile(R"(
dl
  dt Name
  dd= user.name
  dt Email
  dd= user.email
  dt Admin
  dd= user.admin
)");
```

### Move Semantics

```cpp
zigpug::Context createContext() {
    zigpug::Context ctx;
    ctx.set("app", "MyApp");
    return ctx;  // Move semantics - efficient
}

int main() {
    zigpug::Context ctx = createContext();  // No copy, just move
    std::string html = ctx.compile("p #{app}");
}
```

### STL Integration

```cpp
std::map<std::string, std::string> config = {
    {"title", "Dashboard"},
    {"user", "john_doe"}
};

zigpug::Context ctx;
ctx.setAll(config);

std::string html = ctx.compile("h1 #{title}");
```

### Dynamic Arrays from Data

```cpp
std::vector<std::string> names = {"Alice", "Bob", "Charlie"};

zigpug::Context ctx;
zigpug::Array arr(ctx);

for (const auto& name : names) {
    arr.add(name);
}

ctx.set("names", arr);
```

## C++ Standards

### C++11 (Default)

All features work with C++11:
- RAII
- Move semantics
- Exceptions
- STL containers

### C++17 (Optional)

Additional features with C++17:
- `std::string_view` overloads for zero-copy
- More efficient string handling

Compile with C++17:
```bash
g++ -std=c++17 example.cpp -o example $(pkg-config --cflags --libs zig-pug)
```

## RAII Benefits

Resources are automatically managed:

```cpp
void processTemplate() {
    zigpug::Context ctx;  // Allocated
    ctx.set("x", "value");
    // ... use ctx ...
}  // ctx automatically destroyed, resources freed
```

No need to manually call `free()` or cleanup functions.

## Error Handling Best Practices

### Catching Specific Exceptions

```cpp
try {
    // ... zig-pug code ...
} catch (const zigpug::CompilationError& e) {
    // Handle compilation errors
    for (const auto& err : e.errors()) {
        logError(err);
    }
} catch (const zigpug::VariableError& e) {
    // Handle variable errors
    logError(e.what());
} catch (const zigpug::InitializationError& e) {
    // Handle init errors
    logError(e.what());
} catch (const zigpug::Exception& e) {
    // Catch-all for zig-pug errors
    logError(e.what());
}
```

### Integration with std::exception

```cpp
try {
    // ... zig-pug code ...
} catch (const std::exception& e) {
    // Catches all C++ exceptions including zig-pug
    std::cerr << "Error: " << e.what() << std::endl;
}
```

## Performance Considerations

- **Move semantics**: Use `std::move()` when transferring contexts
- **String views**: Use C++17 `std::string_view` to avoid copies
- **Reuse contexts**: Create once, compile multiple templates
- **Static library**: Link against `libzig-pug.a` for better optimization

## Thread Safety

Each `Context` instance is not thread-safe. Use one context per thread or synchronize access:

```cpp
// Per-thread contexts
thread_local zigpug::Context ctx;

// Or use mutexes
std::mutex ctx_mutex;
{
    std::lock_guard<std::mutex> lock(ctx_mutex);
    ctx.compile(template);
}
```

## See Also

- [C API Documentation](c-api.md)
- [Examples](../../examples/cpp/)
- [Main README](../../README.md)
