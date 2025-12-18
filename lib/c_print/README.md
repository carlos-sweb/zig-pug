# c_print

**C library for printing colored and formatted text to the console using ANSI escape codes**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/carlos-sweb/c_print)
[![C Standard](https://img.shields.io/badge/C-C99%20%7C%20C11-orange.svg)](https://en.wikipedia.org/wiki/C11_(C_standard_revision))
[![License](https://img.shields.io/badge/license-MIT-green.svg)](LICENSE)

[Español](README-es.md) | English

## Description

`c_print` is a comprehensive C library that provides three distinct approaches for printing formatted and colored text to the terminal. With support for ANSI colors, text styles, advanced alignment, and number formatting, the library offers flexibility for different use cases and programming preferences.

## Key Features

- 🎨 **16 ANSI colors** (8 standard + 8 bright)
- 🖌️ **8 text styles** (bold, italic, underline, etc.)
- 📏 **Text alignment** (left, right, center with customizable fill characters)
- 🔢 **Advanced number formatting** (thousands separators, padding, numeric bases)
- 🎯 **Three distinct APIs** for different needs
- 🔒 **Type safety** (depending on chosen approach)
- 🔧 **Modular and extensible**
- 🔗 **Compatible with C++ and C99/C11**
- 📦 **Shared and static library**

---

## The 3 Printing Approaches

### 1. Pattern-Based API (Recommended)

**File:** `c_print.h`

This is the main and most flexible approach, using format patterns with `{type:specifier1:specifier2:...}` syntax.

#### Basic Syntax

```c
c_print("Text with {type:specifiers}", value);
```

#### Supported Types

- `{s:...}` - String
- `{d:...}` or `{i:...}` - Integer (int)
- `{f:...}` - Decimal (float/double)
- `{c:...}` - Character (char)
- `{b:...}` - Binary
- `{x:...}` - Hexadecimal
- `{o:...}` - Octal
- `{u:...}` - Unsigned integer
- `{l:...}` - Long integer

#### Available Specifiers

**Colors:**
- Basic: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`
- Bright: `bright_red`, `bright_green`, `bright_blue`, etc.
- Backgrounds: `bg_red`, `bg_green`, `bg_blue`, etc.

**Styles:**
- `bold` - Bold
- `italic` - Italic
- `underline` - Underline
- `dim` - Dim
- `blink` - Blink
- `reverse` - Reverse
- `strikethrough` - Strikethrough

**Alignment:**
- `<N` - Left align (width N)
- `>N` - Right align (width N)
- `^N` - Center (width N)
- `*^N` - Center with custom fill character

**Number Formatting:**
- `.N` - Decimal precision (e.g., `.2` for 2 decimals)
- `0N` - Zero padding (e.g., `05` for 00042)
- `,` - Thousands separator with comma
- `_` - Thousands separator with underscore
- `#` - Show prefix (0b, 0x, 0o)
- `+` - Always show sign
- `%` - Format as percentage

#### Examples

```c
#include "c_print.h"

int main() {
    // Simple colored text
    c_print("Hello {s:green}!\n", "World");

    // Multiple specifiers
    c_print("{s:cyan:bg_black:bold}\n", "IMPORTANT");

    // Multiple values
    c_print("User: {s:yellow}, Age: {d:blue}, Score: {f:.2:green}\n",
            "Alice", 25, 95.5);

    // Number formatting
    c_print("Population: {d:,}\n", 1234567);               // 1,234,567
    c_print("Progress: {f:.1%:cyan}\n", 0.85);            // 85.0%
    c_print("Hex: 0x{x:bold}\n", 255);                    // 0xFF
    c_print("Price: ${f:.2:,}\n", 1234.56);               // $1,234.56

    // Alignment
    c_print("|{s:<20}|\n", "Left");
    c_print("|{s:>20}|\n", "Right");
    c_print("|{s:^20}|\n", "Center");
    c_print("|{s:*^20}|\n", "Fill");                      // |*******Fill*******|

    // Complex example
    c_print("[{s:bright_green:bold}] {s:white} - {f:.2:green} ms\n",
            "SUCCESS", "Request completed", 45.32);

    return 0;
}
```

**Advantages:**
- Compact and readable syntax
- Very flexible and powerful
- Similar to printf but with colors and advanced formatting
- Ideal for most use cases

**Limitations:**
- Type checking at runtime only
- Requires care with argument order

---

### 2. Builder Pattern API

**File:** `c_print_builder.h`

This approach eliminates variadic functions, providing complete compile-time type safety through explicit functions for each data type.

#### Main Functions

```c
// Create and free
CPrintBuilder* cp_new(void);              // Create builder
void cp_free(CPrintBuilder* b);           // Free memory
void cp_reset(CPrintBuilder* b);          // Reset for reuse

// Add content (type-safe)
cp_text(b, "text");                       // Literal text without formatting
cp_str(b, variable_string);               // Formatted string
cp_int(b, 42);                            // Integer
cp_float(b, 3.14);                        // Decimal
cp_char(b, 'A');                          // Character
cp_bool(b, true);                         // Boolean
cp_binary(b, 255);                        // Binary
cp_hex(b, 255);                           // Hexadecimal

// Apply formatting (chainable)
cp_color_str(b, "red");                   // Text color
cp_bg_str(b, "bg_blue");                  // Background color
cp_style_str(b, "bold");                  // Style
cp_precision(b, 2);                       // Decimal precision
cp_zero_pad(b, 5);                        // Zero padding
cp_separator(b, ',');                     // Thousands separator
cp_show_prefix(b, true);                  // Show 0x, 0b, etc.
cp_show_sign(b, true);                    // Show +/- sign
cp_as_percentage(b, true);                // Format as %
cp_align_left(b, 20);                     // Left align
cp_align_right(b, 20);                    // Right align
cp_align_center(b, 20);                   // Center
cp_fill_char(b, '*');                     // Fill character

// Print
cp_print(b);                              // Print
cp_println(b);                            // Print with newline
char* str = cp_to_string(b);              // Get string (must free)
```

#### Examples

```c
#include "c_print_builder.h"

int main() {
    CPrintBuilder* b = cp_new();

    // Type-safe construction
    cp_text(b, "Employee: ");
    cp_str(cp_color_str(b, "cyan"), "Carlos");
    cp_text(b, " | Salary: $");
    cp_float(cp_precision(cp_color_str(b, "green"), 2), 75000.50);
    cp_println(b);
    // Output: Employee: Carlos | Salary: $75000.50

    // Reuse builder
    cp_reset(b);
    cp_text(b, "ID: ");
    cp_int(cp_zero_pad(b, 5), 42);
    cp_println(b);
    // Output: ID: 00042

    // Number with separators
    cp_reset(b);
    cp_text(b, "Population: ");
    cp_int(cp_separator(b, ','), 1234567);
    cp_println(b);
    // Output: Population: 1,234,567

    // Complex chaining
    cp_reset(b);
    cp_text(b, "Price: $");
    cp_float(
        cp_separator(
            cp_precision(
                cp_color_str(b, "green"),
                2
            ),
            ','
        ),
        9999.99
    );
    cp_println(b);
    // Output: Price: $9,999.99 (in green)

    cp_free(b);
    return 0;
}
```

**Advantages:**
- **Compile-time type safety**: Impossible to mix types
- No variadic functions
- Clean, chainable API
- Reusable (with `cp_reset`)
- Automatic internal memory management

**Limitations:**
- More verbose syntax
- Requires creating and freeing the builder
- Less flexible than pattern API

---

### 3. Generic API (C11 _Generic)

**File:** `c_print_generic.h`

This approach uses C11's `_Generic` to automatically detect argument types, combining the convenience of variadic functions with compile-time type safety.

#### Main Macro

```c
#define C_PRINT(pattern, ...)
```

#### Configuration

```c
#define C_PRINT_USE_GENERIC          // Enable generic API
#include "c_print.h"
#include "c_print_generic.h"
```

#### Features

- Automatic type detection using `_Generic`
- Compile-time warnings
- Runtime type mismatch detection
- Strict mode with abort on errors
- Debug mode to inspect types

#### Examples

```c
#define C_PRINT_USE_GENERIC
#include "c_print.h"
#include "c_print_generic.h"

int main() {
    const char* name = "Maria";
    int age = 30;
    double salary = 85000.75;

    // Automatic type detection
    C_PRINT("Name: {s:blue}\n", name);               // ✓ OK
    C_PRINT("Age: {d:yellow}\n", age);               // ✓ OK
    C_PRINT("Salary: ${f:.2:green:,}\n", salary);    // ✓ OK

    // Type mismatch detection
    C_PRINT("Error: {s:red}\n", 500);                // ⚠️ Warning: int passed for string

    // Debug types
    C_PRINT_DEBUG_TYPES("{s} {d} {f}", name, age, salary);
    // Output: Argument 0: type=string
    //         Argument 1: type=int
    //         Argument 2: type=double

    return 0;
}
```

#### Strict Mode

```c
#define C_PRINT_STRICT
#define C_PRINT_USE_GENERIC
#include "c_print.h"
#include "c_print_generic.h"

int main() {
    C_PRINT("{d}", "wrong");  // ❌ Aborts program with error message
    return 0;
}
```

#### Supported Types

- `const char*`, `char*` → string
- `int`, `signed char`, `unsigned char` → int
- `unsigned int` → unsigned
- `long`, `long long` → long
- `unsigned long`, `unsigned long long` → unsigned long
- `float`, `double` → double
- `char` → char
- `_Bool` → bool
- `void*` → pointer

**Advantages:**
- Perfect combination of convenience and safety
- Simple syntax like pattern API
- Compile-time and runtime type checking
- Informative error messages

**Limitations:**
- Requires C11 or later
- Not compatible with C99
- Minimal overhead for type checking

---

## Comparison of the 3 APIs

| Feature | Pattern | Builder | Generic |
|---------|---------|---------|---------|
| **Type Safety** | Runtime only | Compile-time | Compile-time + Runtime |
| **Variadic Functions** | Yes | No | Yes (with _Generic) |
| **Memory Overhead** | Low | Internal buffer | Low |
| **Flexibility** | High | Limited | High |
| **Ease of Use** | Very easy | Moderate | Easy |
| **Required C Standard** | C99 | C99 | C11 |
| **Error Messages** | Runtime | Compile-time | Both |
| **Syntax** | Compact | Verbose | Compact |
| **Ideal Use Case** | General use | Critical code | Modern C11+ projects |

### Which API to Choose?

- **Pattern API**: For most projects. Simple, flexible, and powerful.
- **Builder API**: For code requiring maximum type safety and compile-time validation.
- **Generic API**: For modern C11+ projects wanting the best of both worlds.

---

## Installation

### Requirements

- **CMake** 3.15 or higher
- **C Compiler** with C99 support (C11 for Generic API)
- **C++ Compiler** (optional, for C++ compatibility)

### Build and Installation

```bash
# Clone the repository
git clone https://github.com/carlos-sweb/c_print.git
cd c_print

# Create build directory
mkdir build && cd build

# Configure with CMake
cmake ..

# Compile
make

# Install (may require sudo)
sudo make install
```

### Build Options

```bash
# Build examples (default: ON)
cmake -DBUILD_EXAMPLES=ON ..

# Build tests (default: OFF)
cmake -DBUILD_TESTS=ON ..

# Specify installation prefix
cmake -DCMAKE_INSTALL_PREFIX=/usr/local ..

# Build everything
cmake -DBUILD_EXAMPLES=ON -DBUILD_TESTS=ON ..
make
```

### Using with pkg-config

After installation, you can use `pkg-config` to link the library:

```bash
# View compilation flags
pkg-config --cflags c_print

# View linking flags
pkg-config --libs c_print

# Compile a program
gcc my_program.c $(pkg-config --cflags --libs c_print) -o my_program
```

---

## Usage in Projects

### Option 1: Using CMake (Recommended)

```cmake
cmake_minimum_required(VERSION 3.15)
project(my_project C)

# Find c_print
find_package(PkgConfig REQUIRED)
pkg_check_modules(CPRINT REQUIRED c_print)

add_executable(my_program main.c)

# Link c_print
target_link_libraries(my_program ${CPRINT_LIBRARIES})
target_include_directories(my_program PUBLIC ${CPRINT_INCLUDE_DIRS})
```

### Option 2: Manual Compilation

```bash
# With shared library (installed)
gcc my_program.c -lc_print -o my_program

# With static library (installed)
gcc my_program.c -lc_print -static -o my_program

# With source files directly
gcc my_program.c src/*.c -Iinclude -o my_program
```

### Option 3: Include as Submodule

```bash
# Add as git submodule
git submodule add https://github.com/carlos-sweb/c_print.git libs/c_print

# In your CMakeLists.txt
add_subdirectory(libs/c_print)
target_link_libraries(my_program c_print)
```

---

## Detailed Examples

### Example 1: System Dashboard

```c
#include "c_print.h"

int main() {
    c_print("\n{s:*^60:cyan:bold}\n", " SYSTEM STATUS ");

    c_print("{s:<20} [{s:bright_green:bold}]\n", "CPU", "OK");
    c_print("{s:<20} {d:,} MB ({f:.1%:yellow})\n",
            "Memory", 8192, 0.65);
    c_print("{s:<20} {d:,} / {d:,} GB\n",
            "Disk", 450, 1000);
    c_print("{s:<20} {f:.2:green} ms\n",
            "Latency", 12.45);

    c_print("{s:*^60:cyan}\n", "");

    return 0;
}
```

### Example 2: Logging System

```c
#include "c_print_builder.h"

typedef enum {
    LOG_INFO,
    LOG_WARNING,
    LOG_ERROR,
    LOG_SUCCESS
} LogLevel;

void log_message(LogLevel level, const char* message) {
    CPrintBuilder* b = cp_new();

    cp_text(b, "[");

    switch(level) {
        case LOG_INFO:
            cp_str(cp_color_str(b, "cyan"), "INFO");
            break;
        case LOG_WARNING:
            cp_str(cp_color_str(b, "yellow"), "WARN");
            break;
        case LOG_ERROR:
            cp_str(cp_color_str(cp_style_str(b, "bold"), "red"), "ERROR");
            break;
        case LOG_SUCCESS:
            cp_str(cp_color_str(b, "green"), "OK");
            break;
    }

    cp_text(b, "] ");
    cp_str(b, message);
    cp_println(b);

    cp_free(b);
}

int main() {
    log_message(LOG_INFO, "Starting application...");
    log_message(LOG_SUCCESS, "Connection established");
    log_message(LOG_WARNING, "Cache nearly full");
    log_message(LOG_ERROR, "Authentication failed");
    return 0;
}
```

### Example 3: Data Table

```c
#define C_PRINT_USE_GENERIC
#include "c_print.h"
#include "c_print_generic.h"

void print_table_row(const char* name, int id, double value) {
    C_PRINT("| {s:<20} | {d:>8:05} | {f:>12:.2:,} |\n",
            name, id, value);
}

int main() {
    C_PRINT("{s:=^60:bold}\n", " SALES REPORT ");
    C_PRINT("| {s:<20} | {s:>8} | {s:>12} |\n",
            "Product", "ID", "Price");
    C_PRINT("{s:-^60}\n", "");

    print_table_row("Laptop", 1001, 899.99);
    print_table_row("Mouse", 2034, 29.99);
    print_table_row("Keyboard", 3102, 79.50);

    C_PRINT("{s:=^60}\n", "");
    C_PRINT("Total: {s:$}{f:.2:bright_green:bold:,}\n", "", 1009.48);

    return 0;
}
```

---

## Project Structure

```
c_print/
├── include/                      # Public header files
│   ├── c_print.h                # Main pattern API
│   ├── c_print_builder.h        # Builder pattern API
│   ├── c_print_generic.h        # Generic C11 API
│   ├── ansi_codes.h             # ANSI codes
│   ├── color_parser.h           # Color parser
│   ├── pattern_parser.h         # Pattern parser
│   ├── number_formatter.h       # Number formatting
│   ├── text_alignment.h         # Text alignment
│   └── string_utils.h           # String utilities
├── src/                         # Implementations
│   ├── c_print.c               # Pattern API implementation
│   ├── c_print_builder.c       # Builder implementation
│   ├── c_print_generic.c       # Generic implementation
│   ├── c_print_safe.c          # Safe versions
│   ├── pattern_parser.c
│   ├── number_formatter.c
│   ├── color_parser.c
│   ├── text_alignment.c
│   ├── ansi_codes.c
│   └── string_utils.c
├── test/                        # Examples and tests
│   ├── example.c               # Pattern API example
│   ├── example_builder.c       # Builder example
│   ├── example_generic.c       # Generic example
│   ├── test_color_parser.c
│   ├── test_number_formatter.c
│   ├── test_text_alignment.c
│   ├── test_builder.c
│   └── test_string_utils.c
├── CMakeLists.txt              # CMake configuration
├── c_print.pc.in               # pkg-config template
├── compile_and_test.sh         # Compilation script
├── check_headers.sh            # Header verification
├── README.md                   # This file (English)
└── README-es.md                # Spanish version
```

---

## Modular Architecture

The library is designed with a modular architecture where each component is independent:

### Core Modules

1. **ansi_codes** - ANSI code generation
2. **color_parser** - Parse color/style names
3. **pattern_parser** - Parse `{type:specs}` patterns
4. **number_formatter** - Number formatting (separators, bases, padding)
5. **text_alignment** - Text alignment with fill
6. **string_utils** - String utilities

### High-Level APIs

1. **c_print** - Pattern API (uses all modules)
2. **c_print_builder** - Builder API (uses selected modules)
3. **c_print_generic** - Generic API (wrapper over c_print with _Generic)

---

## Compatibility

### C Standards

- **C99**: ✅ Pattern API, Builder API
- **C11**: ✅ All APIs (includes _Generic)
- **C++**: ✅ All APIs (with `extern "C"`)

### Platforms

- ✅ Linux
- ✅ macOS
- ✅ Windows (with ANSI support in Windows 10+)
- ✅ BSD

### Compilers

- ✅ GCC 4.9+
- ✅ Clang 3.5+
- ✅ MSVC 2019+ (with C11)
- ✅ MinGW

---

## Running Examples

After building:

```bash
cd build

# Pattern API
./example_shared

# Builder API
./example_builder

# Generic API (requires C11)
./example_generic

# Tests
./test_color_parser
./test_number_formatter
./test_text_alignment
./test_builder
```

---

## Troubleshooting

### Colors not showing

**Problem**: Text appears with strange codes or without colors.

**Solution**:
- On Linux/macOS: Make sure you're using an ANSI-compatible terminal
- On Windows 10+: Enable ANSI support in console
- Verify `TERM` is configured correctly: `echo $TERM`

### Compilation error with Generic API

**Problem**: Errors related to `_Generic`.

**Solution**:
- Make sure to compile with C11: `gcc -std=c11 ...`
- Verify your compiler supports C11
- Use GCC 4.9+ or Clang 3.5+

### Undefined symbols when linking

**Problem**: `undefined reference to 'c_print'`

**Solution**:
```bash
# Make sure to link the library
gcc program.c -lc_print -o program

# Or use pkg-config
gcc program.c $(pkg-config --cflags --libs c_print) -o program
```

---

## Contributing

Contributions are welcome. Please:

1. Fork the repository
2. Create a branch for your feature (`git checkout -b feature/new-feature`)
3. Commit your changes (`git commit -am 'Add new feature'`)
4. Push to the branch (`git push origin feature/new-feature`)
5. Create a Pull Request

### Contribution Guidelines

- Maintain C99 compatibility in main APIs
- Add tests for new features
- Document in English in code
- Follow existing code style

---

## License

This project is licensed under the MIT License. See the `LICENSE` file for details.

---

## Author

**Carlos Illesca** - [GitHub](https://github.com/carlos-sweb)

---

## Acknowledgments

- Inspired by modern formatting libraries like fmt, Rich, and Chalk
- C community for feedback and contributions
- ANSI escape codes documentation

---

## Roadmap

### v1.1 (Planned)

- [ ] True Color support (24-bit RGB)
- [ ] Customizable themes
- [ ] Automatic terminal capability detection
- [ ] Automatic tables with borders
- [ ] Progress bars
- [ ] Animated spinners

### v1.2 (Future)

- [ ] Windows support without ANSI using WinAPI
- [ ] Integrated structured logging
- [ ] Performance profiling
- [ ] Bindings for other languages (Python, Rust)

---

## Frequently Asked Questions (FAQ)

### Can I use this library in commercial projects?

Yes, the MIT license allows commercial use without restrictions.

### Does it work on Windows?

Yes, on Windows 10+ which has native support for ANSI codes. On earlier versions, you would need to enable ANSI or use an alternative like ConEmu.

### What is the performance overhead?

The overhead is minimal. Pattern parsing occurs once per call and the Builder API has near-zero cost.

### Can I mix the three APIs in the same project?

Yes, all three APIs are compatible and can be used simultaneously in the same program.

### Are there alternatives to this library?

Yes, some alternatives include:
- **termcolor** (basic colors only)
- **rang** (C++)
- **colorama** (Python)
- This library offers more features and flexibility than most C alternatives.

---

## Additional Examples

### Progress Bar

```c
#include "c_print.h"

void show_progress(double percent) {
    int filled = (int)(percent * 40);
    c_print("[{s:green}", "");
    for(int i = 0; i < filled; i++) c_print("█", "");
    c_print("{s:dim}", "");
    for(int i = filled; i < 40; i++) c_print("░", "");
    c_print("{s}] {f:.1%}\r", "", percent);
    fflush(stdout);
}

int main() {
    for(int i = 0; i <= 100; i++) {
        show_progress(i / 100.0);
        usleep(50000);  // 50ms
    }
    printf("\n");
    return 0;
}
```

### Menu System

```c
#include "c_print.h"

void print_menu() {
    c_print("\n{s:=^50:cyan:bold}\n", " MAIN MENU ");
    c_print("{s:bright_white:bold} {d}. {s}\n", "", 1, "New Game");
    c_print("{s:bright_white:bold} {d}. {s}\n", "", 2, "Load Game");
    c_print("{s:bright_white:bold} {d}. {s}\n", "", 3, "Options");
    c_print("{s:bright_white:bold} {d}. {s}\n", "", 4, "Exit");
    c_print("{s:=^50:cyan}\n", "");
    c_print("Select an option: ", "");
}

int main() {
    print_menu();
    // ... menu logic
    return 0;
}
```

---

## Contact

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/c_print/issues)
- **Email**: c4rl0sill3sc4@protonmail.com

---

<p align="center">
  Made with {s:red:bold} in C
</p>
