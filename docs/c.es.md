# Usando zig-pug desde C/C++

Esta guía te muestra cómo usar zig-pug desde aplicaciones C y C++. Para la referencia completa de la API, consulta [Documentación de la API C](c-api.es.md).

## Inicio Rápido

### 1. Instalación

**Opción A: Usando bibliotecas pre-compiladas**

Descarga la última versión desde [GitHub Releases](https://github.com/carlos-sweb/zig-pug/releases) o compila desde el código fuente:

```bash
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
./build-all.sh
```

Después de compilar, tendrás:
- **Headers**: `include/zigpug.h`
- **Bibliotecas estáticas**: `libs/<platform>/libzig-pug.a` (o `.lib` en Windows)
- **Bibliotecas compartidas**: `libs/<platform>/libzig-pug.so` (o `.dll`/`.dylib`)

**Opción B: Usando pkg-config (recomendado)**

Después de compilar, instala el archivo pkg-config:

```bash
sudo make install-pkgconfig
```

### 2. Tu Primer Programa

Crea `hello.c`:

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

### 3. Compilar

**Con pkg-config:**
```bash
gcc hello.c -o hello $(pkg-config --cflags --libs zpug)
./hello
```

**Sin pkg-config:**
```bash
# Linux
gcc hello.c -o hello -I/path/to/include -L/path/to/libs/linux-x64 -lzig-pug -lm

# macOS
gcc hello.c -o hello -I/path/to/include -L/path/to/libs/darwin-x64 -lzig-pug

# Windows (MinGW)
gcc hello.c -o hello.exe -I/path/to/include -L/path/to/libs/win32-x64 -lzig-pug
```

**Usando TCC (Tiny C Compiler) - Compilación rápida:**
```bash
# Instalar TCC (si no está instalado)
# Ubuntu/Debian: sudo apt-get install tcc
# Arch: sudo pacman -S tcc
# macOS: brew install tcc

# Compilar con TCC (¡muy rápido!)
tcc -run hello.c -I/path/to/include -L/path/to/libs/linux-x64 -lzig-pug -lm

# O compilar a ejecutable
tcc hello.c -o hello -I/path/to/include -L/path/to/libs/linux-x64 -lzig-pug -lm
./hello
```

**Salida:**
```html
<p>Hello World!</p>
```

## Casos de Uso Comunes

### Trabajando con Variables

```c
ZigPugContext* ctx = zigpug_init();

// Cadenas
zigpug_set_string(ctx, "title", "My Page");
zigpug_set_string(ctx, "author", "Alice");

// Números
zigpug_set_int(ctx, "year", 2025);
zigpug_set_int(ctx, "count", 42);

// Booleanos
zigpug_set_bool(ctx, "isAdmin", true);
zigpug_set_bool(ctx, "isActive", false);

// Usar en plantilla
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

### Trabajando con Arrays

**Enfoque simple (cadenas JSON):**

```c
ZigPugContext* ctx = zigpug_init();

// Establecer array desde JSON
zigpug_set_array_json(ctx, "fruits",
    "[\"Apple\",\"Banana\",\"Orange\"]");

// Plantilla con bucle
char* html = zigpug_compile(ctx,
    "ul\n"
    "  each fruit in fruits\n"
    "    li= fruit");

printf("%s\n", html);
// Output: <ul><li>Apple</li><li>Banana</li><li>Orange</li></ul>

zigpug_free_string(html);
zigpug_free(ctx);
```

**Enfoque dinámico (Builder API):**

```c
ZigPugContext* ctx = zigpug_init();

// Construir array dinámicamente
ZigPugArray* items = zigpug_array_create(ctx);

// Agregar items desde un bucle
const char* products[] = {"Laptop", "Mouse", "Keyboard"};
for (int i = 0; i < 3; i++) {
    zigpug_array_add_string(items, products[i]);
}

// Establecer el array
zigpug_set_array(ctx, "products", items);
zigpug_array_free(items);  // Safe to free after set

// Compilar plantilla
char* html = zigpug_compile(ctx,
    "h2 Products\n"
    "ul\n"
    "  each product in products\n"
    "    li= product");

printf("%s\n", html);
zigpug_free_string(html);
zigpug_free(ctx);
```

### Trabajando con Objetos

**Enfoque simple (cadenas JSON):**

```c
ZigPugContext* ctx = zigpug_init();

// Establecer objeto desde JSON
zigpug_set_object_json(ctx, "user",
    "{\"name\":\"Alice\",\"age\":30,\"admin\":true}");

// Plantilla
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

**Enfoque dinámico (Builder API):**

```c
ZigPugContext* ctx = zigpug_init();

// Construir objeto dinámicamente
ZigPugObject* user = zigpug_object_create(ctx);
zigpug_object_set_string(user, "name", "Bob");
zigpug_object_set_int(user, "age", 25);
zigpug_object_set_double(user, "score", 98.5);
zigpug_object_set_bool(user, "verified", true);

// Establecer el objeto
zigpug_set_object(ctx, "user", user);
zigpug_object_free(user);  // Safe to free after set

// Compilar plantilla
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

### Cargando Plantillas desde Archivos

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

    // Leer plantilla desde archivo
    char* template = read_file(argv[1]);
    if (!template) {
        fprintf(stderr, "Failed to read file\n");
        return 1;
    }

    // Compilar
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

### Manejo de Errores

```c
ZigPugContext* ctx = zigpug_init();
zigpug_set_string(ctx, "name", "Alice");

const char* template =
    "if undefinedVar\n"  // Esto causará un error
    "  p Hello";

char* html = zigpug_compile(ctx, template);

if (!html) {
    // Obtener cantidad de errores
    size_t count = zigpug_get_error_count(ctx);
    fprintf(stderr, "Compilation failed with %zu error(s):\n", count);

    // Imprimir todos los errores
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

## Integración de Build

### Usando Makefile

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

## Integración con C++

zig-pug funciona perfectamente con C++:

```cpp
#include <iostream>
#include <string>
#include <memory>
#include <zigpug.h>

// Envoltorio RAII
class ZigPugContext {
    ::ZigPugContext* ctx;
public:
    ZigPugContext() : ctx(zigpug_init()) {
        if (!ctx) throw std::runtime_error("Failed to initialize zig-pug");
    }

    ~ZigPugContext() {
        zigpug_free(ctx);
    }

    // Eliminar constructor de copia/asignación
    ZigPugContext(const ZigPugContext&) = delete;
    ZigPugContext& operator=(const ZigPugContext&) = delete;

    // Operador de conversión
    operator ::ZigPugContext*() { return ctx; }

    // Métodos auxiliares
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
        ZigPugContext ctx;  // Limpieza automática

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

## Mejores Prácticas

### 1. Reutiliza Contextos

Crear contextos es costoso. Reutilízalos:

```c
ZigPugContext* ctx = zigpug_init();

// Compilar muchas plantillas con el mismo contexto
for (int i = 0; i < 1000; i++) {
    char* html = zigpug_compile(ctx, templates[i]);
    // ... usar html ...
    zigpug_free_string(html);
}

zigpug_free(ctx);  // Limpiar una vez al final
```

### 2. Elige la API Correcta

**Usa cadenas JSON cuando:**
- Los datos son estáticos o simples
- Los datos ya están en formato JSON
- Prototipado rápido

**Usa Builder API cuando:**
- Construyes datos desde bucles
- Datos de bases de datos o APIs
- Necesitas seguridad de tipos
- Estructuras anidadas complejas

### 3. Maneja los Errores Correctamente

Siempre verifica los valores de retorno y maneja errores:

```c
ZigPugContext* ctx = zigpug_init();
if (!ctx) {
    // Manejar error de inicialización
}

char* html = zigpug_compile(ctx, template);
if (!html) {
    // Manejar error de compilación
    // Usa zigpug_get_error_count() y zigpug_get_error()
}

zigpug_free_string(html);
zigpug_free(ctx);
```

### 4. Gestión de Memoria

Sigue las reglas de propiedad:

```c
// Tú posees y debes liberar:
char* html = zigpug_compile(ctx, template);
zigpug_free_string(html);  // TÚ debes llamar esto

// La biblioteca posee, no liberes:
const char* error_msg;
zigpug_get_error(ctx, 0, NULL, &error_msg, NULL, NULL);
// ¡No llames free(error_msg)!

// Los builders son seguros de liberar después de set:
ZigPugArray* arr = zigpug_array_create(ctx);
zigpug_array_add_string(arr, "value");
zigpug_set_array(ctx, "key", arr);
zigpug_array_free(arr);  // Seguro - los datos se copian
```

## Soporte de Plataformas

zig-pug funciona en todas las plataformas principales:

- ✅ **Linux** (x86_64, ARM64)
- ✅ **macOS** (Intel, Apple Silicon)
- ✅ **Windows** (x86_64 con MinGW)
- ✅ **Android/Termux** (ARM64)

### Seguridad en Hilos

Cada `ZigPugContext` **no es seguro para hilos**. Para aplicaciones multi-hilo:

**Opción 1: Contexto por hilo**
```c
void* worker_thread(void* arg) {
    ZigPugContext* ctx = zigpug_init();  // Cada hilo tiene el suyo

    char* html = zigpug_compile(ctx, template);
    // ... usar html ...

    zigpug_free_string(html);
    zigpug_free(ctx);
    return NULL;
}
```

**Opción 2: Protección con mutex**
```c
pthread_mutex_t ctx_mutex = PTHREAD_MUTEX_INITIALIZER;
ZigPugContext* shared_ctx;

void* worker_thread(void* arg) {
    pthread_mutex_lock(&ctx_mutex);
    char* html = zigpug_compile(shared_ctx, template);
    pthread_mutex_unlock(&ctx_mutex);

    // ... usar html (fuera de la sección crítica) ...

    zigpug_free_string(html);
    return NULL;
}
```

## Ejemplos

Ejemplos completos y funcionales están disponibles en [examples/c/](../examples/c/):

- **01-basic.c** - Uso básico con variables
- **02-variables.c** - Todos los tipos de variables
- **03-arrays-objects.c** - Arrays y objetos con JSON
- **04-error-handling.c** - Manejo completo de errores
- **05-file-template.c** - Cargando plantillas desde archivos
- **06-builder-api.c** - Uso avanzado de Builder API

## Recursos Adicionales

- **[Referencia de API C](c-api.es.md)** - Documentación completa de la API
- **[Ejemplos en C](../examples/c/)** - Ejemplos de código funcionales
- **[Guía de pkg-config](PKGCONFIG.md)** - Integración con sistemas de build
- **[Repositorio GitHub](https://github.com/carlos-sweb/zig-pug)** - Código fuente e issues

## Soporte

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)
- **Discusiones**: [GitHub Discussions](https://github.com/carlos-sweb/zig-pug/discussions)

## Licencia

Licencia MIT - ver [LICENSE](../LICENSE) para detalles.
