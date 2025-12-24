# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.0.0/),
and this project adheres to [Semantic Versioning](https://semver.org/spec/v2.0.0.html).

## [4.0.0] - 2024-12-24

### 🎉 Major Release - Builder API & Comprehensive C/C++ Support

This is a major release introducing the powerful Builder API for dynamic data construction and comprehensive C/C++ integration, making zig-pug a first-class citizen for C/C++ applications.

### Added

#### Builder API for C/C++
- **Array Builder Functions** - 8 new functions for dynamic array construction
  - `zigpug_array_create()` - Create new array builder
  - `zigpug_array_add_string()` - Add string values
  - `zigpug_array_add_int()` - Add integer values
  - `zigpug_array_add_double()` - Add floating-point values
  - `zigpug_array_add_bool()` - Add boolean values
  - `zigpug_array_add_null()` - Add null values
  - `zigpug_set_array()` - Set array variable in context
  - `zigpug_array_free()` - Free array builder

- **Object Builder Functions** - 8 new functions for dynamic object construction
  - `zigpug_object_create()` - Create new object builder
  - `zigpug_object_set_string()` - Set string properties
  - `zigpug_object_set_int()` - Set integer properties
  - `zigpug_object_set_double()` - Set floating-point properties
  - `zigpug_object_set_bool()` - Set boolean properties
  - `zigpug_object_set_null()` - Set null properties
  - `zigpug_set_object()` - Set object variable in context
  - `zigpug_object_free()` - Free object builder

#### Documentation
- **C/C++ User Guide** (`docs/c.md`) - Comprehensive getting started guide
  - Quick start with installation options
  - Complete examples for all common use cases
  - Build integration (Makefile, CMake)
  - C++ integration with RAII wrapper
  - Best practices and thread safety patterns
  - Platform support and troubleshooting

- **Spanish Translation** (`docs/c.es.md`) - Complete Spanish version of C guide

- **Enhanced C API Reference** (`docs/c-api.md`)
  - Builder API section with 510+ lines of documentation
  - Three detailed examples (database, API response, mixed types)
  - Hybrid approach guidance (JSON vs Builder)
  - Complete function reference with parameters and return values

- **Spanish C API Reference** (`docs/c-api.es.md`) - Full Spanish translation

- **Pipeline Documentation** (Spanish)
  - `docs/tokenizer.es.md` - Tokenizer/lexical analysis (243 lines)
  - `docs/parser.es.md` - Parser/syntax analysis (373 lines)
  - `docs/ast.es.md` - Abstract Syntax Tree (491 lines)
  - `docs/compiler.es.md` - Compiler/HTML generation (494 lines)

#### Examples
- **Builder API Example** (`examples/c/06-builder-api.c`)
  - 250+ line comprehensive demonstration
  - 5 parts showcasing JSON vs Builder approaches
  - Realistic use cases (database simulation, API responses)
  - Mixed types example

- Updated `examples/c/Makefile` and `examples/c/CMakeLists.txt` for new example

- Updated `examples/c/README.md` with Builder API documentation

### Changed

#### C API
- Enhanced header file (`include/zigpug.h`) with:
  - Complete Builder API declarations
  - Extensive inline documentation
  - Usage examples for all new functions

#### Package
- Updated `package.json` version to 4.0.0
- Enhanced description to mention Builder API
- Added new keywords: `c-api`, `c++`, `cpp`, `ffi`, `builder-api`, `dynamic-data`, `type-safe`

#### README
- Reorganized documentation section
- Added C/C++ Guide links in both English and Spanish
- Renamed "C API" to "C API Reference" for clarity
- Better separation between tutorial and reference content

#### Build System
- Rebuilt all binaries with Builder API support
  - CLI binaries for 5 platforms
  - Static libraries (.a/.lib)
  - Shared libraries (.so/.dll/.dylib)
  - Node.js addons

### Implementation Details

#### Core (src/lib.zig)
- `ArrayBuilderImpl` struct for dynamic array construction
- `ObjectBuilderImpl` struct for dynamic object construction
- Proper memory management with create/free pattern
- Support for mixed types in arrays
- Type-safe property setting in objects

#### Memory Safety
- Explicit ownership semantics
- Safe to free builders after `set_array()`/`set_object()`
- Proper cleanup of string values in builders
- No memory leaks or double-free issues

### Benefits

- ✅ **Type Safety** - No manual JSON escaping required
- ✅ **Dynamic Construction** - Build from loops, databases, APIs
- ✅ **Clean API** - Programmatic construction without string manipulation
- ✅ **Powerful** - Mixed types, nested structures supported
- ✅ **Flexible** - Combine with JSON strings for optimal workflow
- ✅ **Well Documented** - Comprehensive guides in English and Spanish
- ✅ **Production Ready** - Complete examples and best practices

### Migration Guide

#### From 0.3.x to 4.0.0

**No Breaking Changes** - All existing code continues to work.

**New Capabilities:**

Instead of building JSON strings manually:
```c
// Old way (still works)
zigpug_set_array_json(ctx, "items", "[\"Apple\",\"Banana\"]");
```

You can now use the Builder API:
```c
// New way (4.0.0+)
ZigPugArray* arr = zigpug_array_create(ctx);
zigpug_array_add_string(arr, "Apple");
zigpug_array_add_string(arr, "Banana");
zigpug_set_array(ctx, "items", arr);
zigpug_array_free(arr);
```

**When to Use Each:**
- JSON strings: Simple, static data
- Builder API: Dynamic data from loops, databases, complex structures

### Statistics

- **16 new C API functions** added
- **1,500+ lines** of new documentation
- **6 complete examples** in C
- **Bilingual support** - Full English and Spanish documentation
- **Zero breaking changes** - Fully backward compatible

---

## [0.3.8] - 2024-12-22

### Previous Release
See [ARRAYS-OBJECTS-CHANGELOG.md](ARRAYS-OBJECTS-CHANGELOG.md) for details on 0.3.x releases.

---

## Links

- [GitHub Repository](https://github.com/carlos-sweb/zig-pug)
- [npm Package](https://www.npmjs.com/package/zig-pug)
- [C API Documentation](docs/c-api.md)
- [C/C++ Guide](docs/c.md)
- [Examples](examples/c/)
