# C API - Referencia Completa

La **C API** proporciona una interfaz completa y compatible con C para usar zig-pug desde C, C++, y otros lenguajes que soportan C FFI (Python ctypes/cffi, Rust, Go, etc.).

## Descripción General

La C API ofrece:

- **Interfaz Simple**: Funciones fáciles de usar para compilar plantillas
- **Seguridad de Tipos**: Los identificadores opacos previenen el mal uso
- **Seguridad de Memoria**: Semántica clara de propiedad y limpieza
- **Características Completas**: Acceso a todas las capacidades de zig-pug
- **Manejo de Errores**: Informes de error detallados con números de línea
- **Multiplataforma**: Funciona con cualquier lenguaje que soporte C FFI
- **Sin Dependencias**: Solo requiere la biblioteca estándar de C

## Inicio Rápido

### Ejemplo Básico

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

### Compilación

```bash
# Using pkg-config (recommended)
gcc myapp.c -o myapp $(pkg-config --cflags --libs zpug)

# Manual
gcc myapp.c -o myapp -I/path/to/include -L/path/to/lib -lzig-pug -lm
```

## Referencia de API

### Gestión de Contexto

#### `zigpug_init()`

Inicializa un nuevo contexto de zig-pug.

```c
ZigPugContext* zigpug_init(void);
```

**Retorna:**
- Identificador de contexto en caso de éxito
- `NULL` en caso de error (falló la asignación de memoria)

**Ejemplo:**
```c
ZigPugContext* ctx = zigpug_init();
if (!ctx) {
    fprintf(stderr, "Initialization failed\n");
    return 1;
}
```

**Notas:**
- Cada contexto tiene su propio tiempo de ejecución de JavaScript
- Los contextos **no son seguros para hilos**
- Crea un contexto por hilo si es necesario

#### `zigpug_free()`

Libera un contexto de zig-pug y libera todos los recursos.

```c
void zigpug_free(ZigPugContext* ctx);
```

**Parámetros:**
- `ctx` - Identificador de contexto (puede ser `NULL`)

**Ejemplo:**
```c
ZigPugContext* ctx = zigpug_init();
// ... use context ...
zigpug_free(ctx);  // Always call this
```

**Notas:**
- Es seguro llamar con `NULL`
- Siempre llama a esta función para evitar fugas de memoria
- Usa envoltorios RAII en C++ para limpieza automática

### Compilación de Plantillas

#### `zigpug_compile()`

Compila una cadena de plantilla Pug a HTML.

```c
char* zigpug_compile(ZigPugContext* ctx, const char* pug_source);
```

**Parámetros:**
- `ctx` - Identificador de contexto
- `pug_source` - Cadena de plantilla Pug terminada en nulo

**Retorna:**
- Cadena HTML terminada en nulo (debe liberarse con `zigpug_free_string()`)
- `NULL` en caso de error (usa funciones de error para obtener detalles)

**Ejemplo:**
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

**Notas:**
- La plantilla **no** se modifica
- El resultado debe liberarse con `zigpug_free_string()`
- Retorna `NULL` en errores de compilación

### Gestión de Variables

#### `zigpug_set_string()`

Establece una variable de cadena en el contexto.

```c
bool zigpug_set_string(ZigPugContext* ctx, const char* key, const char* value);
```

**Parámetros:**
- `ctx` - Identificador de contexto
- `key` - Nombre de la variable (terminado en nulo)
- `value` - Valor de cadena (terminado en nulo)

**Retorna:**
- `true` en caso de éxito
- `false` en caso de error

**Ejemplo:**
```c
zigpug_set_string(ctx, "name", "Alice");
zigpug_set_string(ctx, "email", "alice@example.com");
zigpug_set_string(ctx, "title", "Welcome Page");
```

**Notas:**
- Las cadenas se copian internamente
- Cadenas UTF-8 completamente soportadas
- Las cadenas vacías son válidas

#### `zigpug_set_int()`

Establece una variable entera en el contexto.

```c
bool zigpug_set_int(ZigPugContext* ctx, const char* key, int64_t value);
```

**Parámetros:**
- `ctx` - Identificador de contexto
- `key` - Nombre de la variable (terminado en nulo)
- `value` - Entero firmado de 64 bits

**Retorna:**
- `true` en caso de éxito
- `false` en caso de error

**Ejemplo:**
```c
zigpug_set_int(ctx, "age", 25);
zigpug_set_int(ctx, "year", 2025);
zigpug_set_int(ctx, "count", 42);
```

**Notas:**
- Se almacena internamente como número de JavaScript
- Rango: -(2^53-1) a (2^53-1) (rango de entero seguro de JavaScript)
- Usa para contadores, IDs, edades, etc.

#### `zigpug_set_bool()`

Establece una variable booleana en el contexto.

```c
bool zigpug_set_bool(ZigPugContext* ctx, const char* key, bool value);
```

**Parámetros:**
- `ctx` - Identificador de contexto
- `key` - Nombre de la variable (terminado en nulo)
- `value` - Valor booleano (`true` o `false`)

**Retorna:**
- `true` en caso de éxito
- `false` en caso de error

**Ejemplo:**
```c
zigpug_set_bool(ctx, "loggedIn", true);
zigpug_set_bool(ctx, "admin", false);
zigpug_set_bool(ctx, "verified", true);
```

**Notas:**
- Usa C99 `<stdbool.h>` para `true`/`false`
- En C89, usa `1` para verdadero, `0` para falso

#### `zigpug_set_array_json()`

Establece una variable de matriz desde una cadena JSON.

```c
bool zigpug_set_array_json(ZigPugContext* ctx, const char* key, const char* json_str);
```

**Parámetros:**
- `ctx` - Identificador de contexto
- `key` - Nombre de la variable (terminado en nulo)
- `json_str` - Cadena de matriz JSON

**Retorna:**
- `true` en caso de éxito
- `false` en caso de error (JSON inválido)

**Ejemplo:**
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

**Uso en Plantilla:**
```pug
each fruit in fruits
  li= fruit

each num, i in numbers
  p Item #{i}: #{num}
```

**Notas:**
- JSON debe ser válido
- Se soportan tipos mixtos
- Las matrices vacías son válidas
- Se soportan matrices anidadas

#### `zigpug_set_object_json()`

Establece una variable de objeto desde una cadena JSON.

```c
bool zigpug_set_object_json(ZigPugContext* ctx, const char* key, const char* json_str);
```

**Parámetros:**
- `ctx` - Identificador de contexto
- `key` - Nombre de la variable (terminado en nulo)
- `json_str` - Cadena de objeto JSON

**Retorna:**
- `true` en caso de éxito
- `false` en caso de error (JSON inválido)

**Ejemplo:**
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

**Uso en Plantilla:**
```pug
p Name: #{user.name}
p Age: #{user.age}
p Admin: #{user.admin ? 'Yes' : 'No'}
p Host: #{config.server.host}
```

**Notas:**
- JSON debe ser válido
- Se soportan objetos anidados
- Acceso a propiedades con notación de punto

### Manejo de Errores

#### `zigpug_get_error_count()`

Obtiene el número de errores de compilación de la última llamada de compilación.

```c
size_t zigpug_get_error_count(ZigPugContext* ctx);
```

**Parámetros:**
- `ctx` - Identificador de contexto

**Retorna:**
- Número de errores (0 si no hay errores o no se realizó compilación)

**Ejemplo:**
```c
char* html = zigpug_compile(ctx, template);
if (!html) {
    size_t count = zigpug_get_error_count(ctx);
    printf("Compilation failed with %zu error(s)\n", count);
}
```

#### `zigpug_get_error()`

Obtiene información detallada sobre un error de compilación específico.

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

**Parámetros:**
- `ctx` - Identificador de contexto
- `index` - Índice de error (0 a count-1)
- `line_out` - Salida: número de línea (puede ser `NULL`)
- `message_out` - Salida: mensaje de error (puede ser `NULL`)
- `detail_out` - Salida: información detallada (puede ser `NULL`, puede ser `NULL` incluso en caso de éxito)
- `hint_out` - Salida: pista para corregir (puede ser `NULL`, puede ser `NULL` incluso en caso de éxito)

**Retorna:**
- `true` si existe error en el índice
- `false` en otro caso

**Ejemplo:**
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

**Notas:**
- Las cadenas de error son propiedad del contexto (no las liberes)
- Los errores se limpian en la siguiente compilación
- `detail` e `hint` pueden ser `NULL`

### Gestión de Memoria

#### `zigpug_free_string()`

Libera una cadena retornada por zig-pug.

```c
void zigpug_free_string(char* str);
```

**Parámetros:**
- `str` - Cadena a liberar (puede ser `NULL`)

**Ejemplo:**
```c
char* html = zigpug_compile(ctx, template);
if (html) {
    printf("%s\n", html);
    zigpug_free_string(html);  // Must call this
}
```

**Notas:**
- Es seguro llamar con `NULL`
- Solo libera cadenas de `zigpug_compile()`
- No liberes cadenas de error (son propiedad del contexto)

### Funciones de Utilidad

#### `zigpug_version()`

Obtiene la cadena de versión de zig-pug.

```c
const char* zigpug_version(void);
```

**Retorna:**
- Cadena de versión (no liberes)

**Ejemplo:**
```c
printf("zig-pug version: %s\n", zigpug_version());
// Output: zig-pug version: 0.1.0
```

## Ejemplos Completos

### Ejemplo 1: Uso Básico

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

### Ejemplo 2: Con Matrices e Iteraciones

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

### Ejemplo 3: Manejo Completo de Errores

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

### Ejemplo 4: Plantillas de Archivo

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

## Construcción de Aplicaciones

### Usando pkg-config

Crea `myapp.c`:

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

Compilar:

```bash
gcc myapp.c -o myapp $(pkg-config --cflags --libs zpug)
./myapp
```

### Usando Makefile

```makefile
CC = gcc
CFLAGS = $(shell pkg-config --cflags zpug)
LIBS = $(shell pkg-config --libs zpug)

myapp: myapp.c
	$(CC) $(CFLAGS) myapp.c -o myapp $(LIBS)

clean:
	rm -f myapp
```

### Usando CMake

```cmake
cmake_minimum_required(VERSION 3.10)
project(MyApp C)

find_package(PkgConfig REQUIRED)
pkg_check_modules(ZPUG REQUIRED zpug)

add_executable(myapp myapp.c)
target_include_directories(myapp PRIVATE ${ZPUG_INCLUDE_DIRS})
target_link_libraries(myapp ${ZPUG_LIBRARIES})
```

## Seguridad para Hilos

### No es Seguro para Hilos

Cada `ZigPugContext` **no es seguro para hilos**. No compartas contextos entre hilos.

**Incorrecto:**
```c
// DON'T DO THIS
ZigPugContext* ctx = zigpug_init();

void* thread1(void* arg) {
    zigpug_compile(ctx, template1);  // Race condition
}

void* thread2(void* arg) {
    zigpug_compile(ctx, template2);  // Race condition
}
```

### Enfoque Seguro para Hilos 1: Contexto por Hilo

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

### Enfoque Seguro para Hilos 2: Mutex

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

## Soporte de Plataformas

### Plataformas Soportadas

- Linux (x86_64, ARM64)
- macOS (Intel, Apple Silicon)
- Windows (x86_64)

### Archivos de Biblioteca

- **Estática**: `libzig-pug.a` (Linux/macOS), `zig-pug.lib` (Windows)
- **Compartida**: `libzig-pug.so` (Linux), `libzig-pug.dylib` (macOS), `zig-pug.dll` (Windows)

### Rutas de Plataforma

- Linux x64: `libs/linux-x64/`
- Linux ARM64: `libs/linux-arm64/`
- macOS Intel: `libs/darwin-x64/`
- macOS Apple Silicon: `libs/darwin-arm64/`
- Windows: `libs/win32-x64/`

## Consejos de Rendimiento

1. **Reutiliza Contextos**: Crear contextos es costoso
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

2. **Precarga Plantillas**: Lee archivos una vez al iniciar
   ```c
   char* template = read_file("template.pug");
   for (int i = 0; i < 1000; i++) {
       char* html = zigpug_compile(ctx, template);
       // ...
   }
   free(template);
   ```

3. **Enlazamiento Estático**: Usa archivos `.a` para mejor rendimiento

## Patrones Comunes

### Envoltorio RAII (C++)

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

### Ayuda para Manejo de Errores

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

## Ver También

- **[Ejemplos](../examples/c/)** - Ejemplos completos de trabajo
- **[Guía pkg-config](PKGCONFIG.md)** - Instalación y uso
- **[Sintaxis Pug](../README.md#pug-syntax)** - Referencia de sintaxis de plantilla
- **[Node.js API](../nodejs/README.md)** - Comparación de API de JavaScript

## Licencia

Licencia MIT - ver [LICENSE](../LICENSE) para detalles.
