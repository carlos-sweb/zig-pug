# zig-pug v4.0.0 - Builder API & Comprehensive C/C++ Support 🚀

**Major release introducing the powerful Builder API for dynamic data construction and world-class C/C++ integration.**

## 🎯 What's New

### Builder API - For Real Geeks 🤓

Dynamic, type-safe construction of arrays and objects from C/C++. Perfect for building data from databases, APIs, or any dynamic source.

**Array Builder:**
```c
ZigPugArray* products = zigpug_array_create(ctx);
for (int i = 0; i < count; i++) {
    zigpug_array_add_string(products, database[i].name);
    zigpug_array_add_double(products, database[i].price);
}
zigpug_set_array(ctx, "products", products);
zigpug_array_free(products);
```

**Object Builder:**
```c
ZigPugObject* user = zigpug_object_create(ctx);
zigpug_object_set_string(user, "name", "Alice");
zigpug_object_set_int(user, "age", 30);
zigpug_object_set_bool(user, "verified", true);
zigpug_set_object(ctx, "user", user);
zigpug_object_free(user);
```

**Why Builder API?**
- ✅ Type-safe - No manual JSON escaping
- ✅ Dynamic - Build from loops/databases/APIs
- ✅ Clean - No string manipulation
- ✅ Powerful - Mixed types supported

### Comprehensive Documentation 📚

**New User Guides:**
- 📖 [C/C++ Getting Started Guide](docs/c.md) - Complete tutorial with examples
- 📖 [Guía de C/C++ en Español](docs/c.es.md) - Versión completa en español

**Enhanced API Reference:**
- 📘 [C API Reference](docs/c-api.md) - 1,300+ lines with Builder API docs
- 📘 [Referencia API C (Español)](docs/c-api.es.md) - Traducción completa

**Pipeline Documentation (Spanish):**
- 📄 Tokenizer, Parser, AST, Compiler - All fully documented in Spanish

### Complete Examples 💻

6 working C examples in [examples/c/](examples/c/):
1. **01-basic.c** - Basic usage
2. **02-variables.c** - All variable types
3. **03-arrays-objects.c** - JSON approach
4. **04-error-handling.c** - Error handling
5. **05-file-template.c** - File loading
6. **06-builder-api.c** ⭐ - **NEW** 250-line Builder API showcase

## 📦 Installation

### npm (Node.js/Bun)
```bash
npm install zig-pug
```

### From Source
```bash
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
./build-all.sh
```

## 🔧 C/C++ Integration

**With pkg-config:**
```bash
gcc myapp.c -o myapp $(pkg-config --cflags --libs zpug)
```

**Manual:**
```bash
gcc myapp.c -o myapp -I/path/to/include -L/path/to/libs -lzig-pug -lm
```

## 🌟 Key Features

### Hybrid Approach (Recommended)
Combine JSON strings for simple data with Builder API for complex structures:

```c
// Simple: Use JSON
zigpug_set_array_json(ctx, "colors", "[\"red\",\"green\",\"blue\"]");

// Complex: Use Builder
ZigPugArray* items = zigpug_array_create(ctx);
for (int i = 0; i < count; i++) {
    zigpug_array_add_int(items, database_results[i]);
}
zigpug_set_array(ctx, "items", items);
zigpug_array_free(items);
```

### C++ Integration
RAII wrapper included in docs:
```cpp
class ZigPugContext {
    // Automatic cleanup, exception-safe
};
```

## 📊 What's Included

- **16 new C API functions** for Builder API
- **1,500+ lines** of new documentation
- **Bilingual docs** - English & Spanish
- **6 complete examples** with Makefile & CMake
- **Zero breaking changes** - Fully backward compatible

## 🔄 Migration from 0.3.x

**No breaking changes!** All existing code continues to work.

Simply start using the new Builder API when you need dynamic data construction:

```c
// Old way (still works)
zigpug_set_array_json(ctx, "items", "[\"a\",\"b\"]");

// New way (optional, for dynamic data)
ZigPugArray* arr = zigpug_array_create(ctx);
zigpug_array_add_string(arr, "a");
zigpug_array_add_string(arr, "b");
zigpug_set_array(ctx, "items", arr);
zigpug_array_free(arr);
```

## 🛠️ Build Integration

### Makefile
```makefile
LIBS = $(shell pkg-config --libs zpug)
INCLUDES = $(shell pkg-config --cflags zpug)

myapp: myapp.c
	$(CC) $(INCLUDES) myapp.c -o myapp $(LIBS)
```

### CMake
```cmake
find_package(PkgConfig REQUIRED)
pkg_check_modules(ZPUG REQUIRED zpug)

add_executable(myapp myapp.c)
target_link_libraries(myapp ${ZPUG_LIBRARIES})
```

## 🌍 Platform Support

- ✅ Linux (x86_64, ARM64)
- ✅ macOS (Intel, Apple Silicon)
- ✅ Windows (x86_64 with MinGW)
- ✅ Android/Termux (ARM64)

## 📚 Resources

- 📖 [Getting Started with C/C++](docs/c.md)
- 📘 [Complete C API Reference](docs/c-api.md)
- 💻 [Working Examples](examples/c/)
- 🔧 [pkg-config Guide](docs/PKGCONFIG.md)
- 🇪🇸 [Documentación en Español](docs/c.es.md)

## 🎓 Learn More

Check out the comprehensive example `06-builder-api.c` that demonstrates:
- JSON vs Builder API comparison
- Dynamic arrays from loops
- Dynamic objects from structs
- Mixed type arrays
- Realistic use cases (database, API simulation)

## 🙏 Contributors

Thanks to all contributors who made this release possible!

## 📝 Full Changelog

See [CHANGELOG.md](CHANGELOG.md) for complete details.

---

**Ready to stop watching anime and start coding?** 😉

Try the new Builder API today!

```bash
npm install zig-pug@4.0.0
```

Or check out the [examples](examples/c/) to get started with C/C++!
