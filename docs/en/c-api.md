# C API Reference

The complete C API reference documentation is available at:

**[../c-api.md](../c-api.md)**

## Quick Links

### Getting Started

- [C/C++ Guide](../c.md) - Getting started guide for using zig-pug from C/C++
- [C API Reference](../c-api.md) - Complete C API reference with examples

### Main API Functions

From [../c-api.md](../c-api.md):

- `zigpug_compile()` - Compile Pug template to HTML
- `zigpug_compile_file()` - Compile Pug file to HTML
- `zigpug_set_variable()` - Set template variables
- `zigpug_free()` - Free allocated memory
- `zigpug_get_error()` - Get last error message
- `zigpug_version()` - Get zig-pug version

### Examples

```c
#include <zigpug.h>

int main() {
    const char *template = "p Hello #{name}!";
    const char *variables = "{\"name\": \"World\"}";

    char *html = zigpug_compile(template, variables);
    if (html) {
        printf("%s\n", html);
        zigpug_free(html);
    } else {
        fprintf(stderr, "Error: %s\n", zigpug_get_error());
    }

    return 0;
}
```

### Building with C API

**Using pkg-config:**
```bash
gcc myapp.c -o myapp $(pkg-config --cflags --libs zigpug)
```

**Manual linking:**
```bash
gcc myapp.c -o myapp -I/usr/local/include -L/usr/local/lib -lzigpug -lmujs -lm
```

### See Also

- [C/C++ Guide](../c.md) - Getting started
- [C API Reference](../c-api.md) - Complete API documentation
- [C Examples](../../examples/c/) - Working examples
- [pkg-config Usage](../PKGCONFIG.md) - Using zig-pug with pkg-config

---

**Note:** This is a stub file. The complete documentation is in [../c-api.md](../c-api.md).
