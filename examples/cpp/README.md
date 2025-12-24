# zig-pug C++ Examples

Modern C++ examples demonstrating the zig-pug C++ API with RAII, exceptions, and STL integration.

## Features

The C++ API (`zigpug.hpp`) provides:

- **RAII**: Automatic resource management - no manual cleanup needed
- **Exceptions**: Type-safe error handling with detailed error information
- **STL Integration**: `std::string`, `std::vector`, `std::map` support
- **Fluent Interface**: Method chaining for readable code
- **Move Semantics**: Efficient resource transfer (C++11+)
- **String View**: Zero-copy operations (C++17+, optional)
- **Type Safety**: Compile-time type checking

## Requirements

- C++11 or later compiler (g++, clang++)
- zig-pug library compiled and available in `../../libs/`

## Building

```bash
# Build all examples
make

# Build and run all examples
make run-all

# Build and run a specific example
make run-01-basic

# Clean build artifacts
make clean
```

## Examples

### 01-basic.cpp - Getting Started

Basic usage demonstrating:
- Context initialization with RAII
- Setting variables with method chaining
- Template compilation
- Exception handling

```cpp
zigpug::Context ctx;
ctx.set("name", "Alice")
   .set("age", 30)
   .set("active", true);

std::string html = ctx.compile("p Hello #{name}!");
```

### 02-arrays.cpp - Working with Arrays

Array Builder API with fluent interface:

```cpp
zigpug::Array fruits(ctx);
fruits.add("Apple")
      .add("Banana")
      .add("Orange");

ctx.set("fruits", fruits);
```

### 03-objects.cpp - Working with Objects

Object Builder API for complex data:

```cpp
zigpug::Object user(ctx);
user.set("name", "Alice")
    .set("age", 30)
    .set("admin", true)
    .set("score", 95.5);

ctx.set("user", user);
```

### 04-move-semantics.cpp - Efficient Resource Transfer

Move semantics for zero-copy operations:

```cpp
zigpug::Context createContext() {
    zigpug::Context ctx;
    // configure...
    return ctx;  // Move semantics automatically applied
}

zigpug::Context ctx = createContext();  // Efficient transfer
```

### 05-complex-data.cpp - Real-World Scenarios

Building complex data structures dynamically:

```cpp
// Build from database results
for (const auto& product : products) {
    zigpug::Object obj(ctx);
    obj.set("name", product.name)
       .set("price", product.price);
    // ...
}
```

### 06-stl-integration.cpp - STL Containers

Integration with standard library containers:

```cpp
std::map<std::string, std::string> vars = {
    {"title", "Dashboard"},
    {"username", "john_doe"}
};

ctx.setAll(vars);  // Set multiple variables at once
```

## Exception Handling

The C++ API uses exceptions for error handling:

```cpp
try {
    zigpug::Context ctx;
    std::string html = ctx.compile(pug_source);
    // ... use html ...

} catch (const zigpug::CompilationError& e) {
    // Compilation failed
    std::cerr << e.what() << std::endl;

    // Get detailed error information
    for (const auto& err : e.errors()) {
        std::cerr << "Line " << err.line << ": " << err.message << std::endl;
        if (!err.detail.empty()) {
            std::cerr << "  Detail: " << err.detail << std::endl;
        }
        if (!err.hint.empty()) {
            std::cerr << "  Hint: " << err.hint << std::endl;
        }
    }

} catch (const zigpug::VariableError& e) {
    // Variable setting failed
    std::cerr << "Variable error: " << e.what() << std::endl;

} catch (const zigpug::InitializationError& e) {
    // Context/builder initialization failed
    std::cerr << "Init error: " << e.what() << std::endl;

} catch (const zigpug::Exception& e) {
    // Catch-all for any zig-pug exception
    std::cerr << "Error: " << e.what() << std::endl;
}
```

## API Reference

### zigpug::Context

Main class for template compilation.

**Methods:**
- `Context()` - Initialize context (throws InitializationError on failure)
- `std::string compile(const std::string& pug_source)` - Compile template (throws CompilationError)
- `Context& set(const std::string& key, const std::string& value)` - Set string variable
- `Context& set(const std::string& key, int64_t value)` - Set integer variable
- `Context& set(const std::string& key, bool value)` - Set boolean variable
- `Context& set(const std::string& key, const Array& arr)` - Set array variable
- `Context& set(const std::string& key, const Object& obj)` - Set object variable
- `Context& setAll(const std::map<std::string, std::string>& vars)` - Set multiple variables
- `static std::string version()` - Get zig-pug version

### zigpug::Array

Array builder with fluent interface.

**Methods:**
- `Array(Context& ctx)` - Create array builder
- `Array& add(const std::string& value)` - Add string
- `Array& add(int64_t value)` - Add integer
- `Array& add(double value)` - Add double
- `Array& add(bool value)` - Add boolean
- `Array& addNull()` - Add null value

### zigpug::Object

Object builder with fluent interface.

**Methods:**
- `Object(Context& ctx)` - Create object builder
- `Object& set(const std::string& key, const std::string& value)` - Set string property
- `Object& set(const std::string& key, int64_t value)` - Set integer property
- `Object& set(const std::string& key, double value)` - Set double property
- `Object& set(const std::string& key, bool value)` - Set boolean property
- `Object& setNull(const std::string& key)` - Set null property

### Exception Types

- `zigpug::Exception` - Base exception class
- `zigpug::InitializationError` - Context/builder init failed
- `zigpug::CompilationError` - Template compilation failed
- `zigpug::VariableError` - Variable operation failed

## C++ Standards

### C++11 (Default)
All examples work with C++11 and later.

### C++17 (Optional)
When using C++17, additional features are available:
- `std::string_view` overloads for zero-copy operations
- `std::optional` for error handling (future)

Build with C++17:
```bash
g++ -std=c++17 example.cpp -o example -lzig-pug
```

## Advanced Usage

### Custom Error Handling

```cpp
try {
    ctx.compile(pug_source);
} catch (const zigpug::CompilationError& e) {
    // Log errors to file
    std::ofstream log("errors.log");
    for (const auto& err : e.errors()) {
        log << "Line " << err.line << ": " << err.message << "\n";
    }
}
```

### Building Arrays from STL Containers

```cpp
std::vector<std::string> names = {"Alice", "Bob", "Charlie"};

zigpug::Array arr(ctx);
for (const auto& name : names) {
    arr.add(name);
}
ctx.set("names", arr);
```

### Factory Pattern

```cpp
class TemplateEngine {
    zigpug::Context ctx_;

public:
    TemplateEngine() {
        // Configure default variables
        ctx_.set("appName", "MyApp")
            .set("version", "1.0.0");
    }

    std::string render(const std::string& tmpl) {
        return ctx_.compile(tmpl);
    }

    void setVar(const std::string& key, const std::string& value) {
        ctx_.set(key, value);
    }
};
```

## See Also

- [C API Documentation](../../docs/en/c-api.md)
- [Main Documentation](../../README.md)
- [C Examples](../c/)
