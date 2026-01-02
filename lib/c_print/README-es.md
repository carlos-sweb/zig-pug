# c_print

**Biblioteca C para imprimir texto coloreado y formateado en la consola usando códigos de escape ANSI**

[![Version](https://img.shields.io/badge/version-1.0.0-blue.svg)](https://github.com/carlos-sweb/c_print)
[![C Standard](https://img.shields.io/badge/C-C99%20%7C%20C11-orange.svg)](https://en.wikipedia.org/wiki/C11_%28C_standard_revision%29)
[![License](https://img.shields.io/badge/license-MIT-green.svg)](../../LICENSE)

[English](README.md) | Español

## Descripción

`c_print` es una biblioteca C completa que proporciona tres enfoques distintos para imprimir texto formateado y coloreado en la terminal. Con soporte para colores ANSI, estilos de texto, alineación avanzada y formateo de números, la biblioteca ofrece flexibilidad para diferentes casos de uso y preferencias de programación.

## Características Principales

- 🎨 **16 colores ANSI** (8 estándar + 8 brillantes)
- 🖌️ **8 estilos de texto** (negrita, cursiva, subrayado, etc.)
- 📏 **Alineación de texto** (izquierda, derecha, centro con caracteres de relleno personalizables)
- 🔢 **Formateo avanzado de números** (separadores de miles, relleno, bases numéricas)
- 🎯 **Tres APIs distintas** para diferentes necesidades
- 🔒 **Seguridad de tipos** (dependiendo del enfoque elegido)
- 🔧 **Modular y extensible**
- 🔗 **Compatible con C++ y C99/C11**
- 📦 **Biblioteca compartida y estática**

---

## Los 3 Enfoques de Impresión

### 1. API Basada en Patrones (Recomendada)

**Archivo:** `c_print.h`

Este es el enfoque principal y más flexible, utilizando patrones de formato con sintaxis `{type:specifier1:specifier2:...}`.

#### Sintaxis Básica

```c
c_print("Text with {type:specifiers}", value);
```

#### Tipos Soportados

- `{s:...}` - Cadena
- `{d:...}` o `{i:...}` - Entero (int)
- `{f:...}` - Decimal (float/double)
- `{c:...}` - Carácter (char)
- `{b:...}` - Binario
- `{x:...}` - Hexadecimal
- `{o:...}` - Octal
- `{u:...}` - Entero sin signo
- `{l:...}` - Entero largo

#### Especificadores Disponibles

**Colores:**
- Básicos: `red`, `green`, `blue`, `cyan`, `magenta`, `yellow`, `white`, `black`
- Brillantes: `bright_red`, `bright_green`, `bright_blue`, etc.
- Fondos: `bg_red`, `bg_green`, `bg_blue`, etc.

**Estilos:**
- `bold` - Negrita
- `italic` - Cursiva
- `underline` - Subrayado
- `dim` - Atenuado
- `blink` - Parpadeo
- `reverse` - Invertido
- `strikethrough` - Tachado

**Alineación:**
- `<N` - Alinear a la izquierda (ancho N)
- `>N` - Alinear a la derecha (ancho N)
- `^N` - Centrar (ancho N)
- `*^N` - Centrar con carácter de relleno personalizado

**Formateo de Números:**
- `.N` - Precisión decimal (e.g., `.2` para 2 decimales)
- `0N` - Relleno con ceros (e.g., `05` para 00042)
- `,` - Separador de miles con coma
- `_` - Separador de miles con guion bajo
- `#` - Mostrar prefijo (0b, 0x, 0o)
- `+` - Siempre mostrar signo
- `%` - Formatear como porcentaje

#### Ejemplos

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

**Ventajas:**
- Sintaxis compacta y legible
- Muy flexible y poderosa
- Similar a printf pero con colores y formateo avanzado
- Ideal para la mayoría de los casos de uso

**Limitaciones:**
- Verificación de tipos solo en tiempo de ejecución
- Requiere cuidado con el orden de los argumentos

---

### 2. API de Patrón Builder

**Archivo:** `c_print_builder.h`

Este enfoque elimina las funciones variádicas, proporcionando seguridad de tipos completa en tiempo de compilación a través de funciones explícitas para cada tipo de dato.

#### Funciones Principales

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

#### Ejemplos

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

**Ventajas:**
- **Seguridad de tipos en tiempo de compilación**: Imposible mezclar tipos
- Sin funciones variádicas
- API limpia y encadenable
- Reutilizable (con `cp_reset`)
- Gestión automática de memoria interna

**Limitaciones:**
- Sintaxis más verbosa
- Requiere crear y liberar el builder
- Menos flexible que la API de patrones

---

### 3. API Genérica (C11 _Generic)

**Archivo:** `c_print_generic.h`

Este enfoque utiliza `_Generic` de C11 para detectar automáticamente los tipos de argumentos, combinando la conveniencia de las funciones variádicas con la seguridad de tipos en tiempo de compilación.

#### Macro Principal

```c
#define C_PRINT(pattern, ...)
```

#### Configuración

```c
#define C_PRINT_USE_GENERIC          // Enable generic API
#include "c_print.h"
#include "c_print_generic.h"
```

#### Características

- Detección automática de tipos usando `_Generic`
- Advertencias en tiempo de compilación
- Detección de desajustes de tipos en tiempo de ejecución
- Modo estricto con aborto en errores
- Modo de depuración para inspeccionar tipos

#### Ejemplos

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

#### Modo Estricto

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

#### Tipos Soportados

- `const char*`, `char*` → string
- `int`, `signed char`, `unsigned char` → int
- `unsigned int` → unsigned
- `long`, `long long` → long
- `unsigned long`, `unsigned long long` → unsigned long
- `float`, `double` → double
- `char` → char
- `_Bool` → bool
- `void*` → pointer

**Ventajas:**
- Combinación perfecta de conveniencia y seguridad
- Sintaxis simple como la API de patrones
- Verificación de tipos en tiempo de compilación y ejecución
- Mensajes de error informativos

**Limitaciones:**
- Requiere C11 o posterior
- No compatible con C99
- Sobrecarga mínima para verificación de tipos

---

## Comparación de las 3 APIs

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

### ¿Cuál API Elegir?

- **API de Patrones**: Para la mayoría de los proyectos. Simple, flexible y poderosa.
- **API de Builder**: Para código que requiere máxima seguridad de tipos y validación en tiempo de compilación.
- **API Genérica**: Para proyectos modernos en C11+ que quieran lo mejor de ambos mundos.

---

## Instalación

### Requisitos

- **CMake** 3.15 o superior
- **Compilador C** con soporte para C99 (C11 para API Genérica)
- **Compilador C++** (opcional, para compatibilidad con C++)

### Construcción e Instalación

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

### Opciones de Construcción

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

### Uso con pkg-config

Después de la instalación, puedes usar `pkg-config` para enlazar la biblioteca:

```bash
# View compilation flags
pkg-config --cflags c_print

# View linking flags
pkg-config --libs c_print

# Compile a program
gcc my_program.c $(pkg-config --cflags --libs c_print) -o my_program
```

---

## Uso en Proyectos

### Opción 1: Usando CMake (Recomendada)

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

### Opción 2: Compilación Manual

```bash
# With shared library (installed)
gcc my_program.c -lc_print -o my_program

# With static library (installed)
gcc my_program.c -lc_print -static -o my_program

# With source files directly
gcc my_program.c src/*.c -Iinclude -o my_program
```

### Opción 3: Incluir como Submódulo

```bash
# Add as git submodule
git submodule add https://github.com/carlos-sweb/c_print.git libs/c_print

# In your CMakeLists.txt
add_subdirectory(libs/c_print)
target_link_libraries(my_program c_print)
```

---

## Ejemplos Detallados

### Ejemplo 1: Panel de Sistema

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

### Ejemplo 2: Sistema de Registro

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

### Ejemplo 3: Tabla de Datos

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

## Estructura del Proyecto

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

## Arquitectura Modular

La biblioteca está diseñada con una arquitectura modular donde cada componente es independiente:

### Módulos Principales

1. **ansi_codes** - Generación de códigos ANSI
2. **color_parser** - Análisis de nombres de colores/estilos
3. **pattern_parser** - Análisis de patrones `{type:specs}`
4. **number_formatter** - Formateo de números (separadores, bases, relleno)
5. **text_alignment** - Alineación de texto con relleno
6. **string_utils** - Utilidades de cadenas

### APIs de Alto Nivel

1. **c_print** - API de Patrones (usa todos los módulos)
2. **c_print_builder** - API de Builder (usa módulos seleccionados)
3. **c_print_generic** - API Genérica (envoltura sobre c_print con _Generic)

---

## Compatibilidad

### Estándares C

- **C99**: ✅ API de Patrones, API de Builder
- **C11**: ✅ Todas las APIs (incluye _Generic)
- **C++**: ✅ Todas las APIs (con `extern "C"`)

### Plataformas

- ✅ Linux
- ✅ macOS
- ✅ Windows (con soporte ANSI en Windows 10+)
- ✅ BSD

### Compiladores

- ✅ GCC 4.9+
- ✅ Clang 3.5+
- ✅ MSVC 2019+ (con C11)
- ✅ MinGW

---

## Ejecución de Ejemplos

Después de construir:

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

## Solución de Problemas

### Colores no se muestran

**Problema**: El texto aparece con códigos extraños o sin colores.

**Solución**:
- En Linux/macOS: Asegúrate de usar una terminal compatible con ANSI
- En Windows 10+: Habilita el soporte ANSI en la consola
- Verifica que `TERM` esté configurado correctamente: `echo $TERM`

### Error de compilación con API Genérica

**Problema**: Errores relacionados con `_Generic`.

**Solución**:
- Asegúrate de compilar con C11: `gcc -std=c11 ...`
- Verifica que tu compilador soporte C11
- Usa GCC 4.9+ o Clang 3.5+

### Símbolos indefinidos al enlazar

**Problema**: `undefined reference to 'c_print'`

**Solución**:
```bash
# Make sure to link the library
gcc program.c -lc_print -o program

# Or use pkg-config
gcc program.c $(pkg-config --cflags --libs c_print) -o program
```

---

## Contribuciones

Las contribuciones son bienvenidas. Por favor:

1. Haz un fork del repositorio
2. Crea una rama para tu característica (`git checkout -b feature/nueva-caracteristica`)
3. Confirma tus cambios (`git commit -am 'Añade nueva característica'`)
4. Empuja a la rama (`git push origin feature/nueva-caracteristica`)
5. Crea un Pull Request

### Guías de Contribución

- Mantén la compatibilidad con C99 en las APIs principales
- Añade pruebas para nuevas características
- Documenta en inglés en el código
- Sigue el estilo de código existente

---

## Licencia

Este proyecto está licenciado bajo la Licencia MIT. Consulta el archivo `LICENSE` para más detalles.

---

## Autor

**Carlos Illesca** - [GitHub](https://github.com/carlos-sweb)

---

## Agradecimientos

- Inspirado en bibliotecas modernas de formateo como fmt, Rich y Chalk
- Comunidad C por retroalimentación y contribuciones
- Documentación de códigos de escape ANSI

---

## Hoja de Ruta

### v1.1 (Planeada)

- [ ] Soporte para True Color (RGB de 24 bits)
- [ ] Temas personalizables
- [ ] Detección automática de capacidades de terminal
- [ ] Tablas automáticas con bordes
- [ ] Barras de progreso
- [ ] Spinners animados

### v1.2 (Futura)

- [ ] Soporte para Windows sin ANSI usando WinAPI
- [ ] Registro estructurado integrado
- [ ] Perfilamiento de rendimiento
- [ ] Enlaces para otros lenguajes (Python, Rust)

---

## Preguntas Frecuentes (FAQ)

### ¿Puedo usar esta biblioteca en proyectos comerciales?

Sí, la licencia MIT permite el uso comercial sin restricciones.

### ¿Funciona en Windows?

Sí, en Windows 10+ que tiene soporte nativo para códigos ANSI. En versiones anteriores, necesitarías habilitar ANSI o usar una alternativa como ConEmu.

### ¿Cuál es la sobrecarga de rendimiento?

La sobrecarga es mínima. El análisis de patrones ocurre una vez por llamada y la API de Builder tiene un costo casi cero.

### ¿Puedo mezclar las tres APIs en el mismo proyecto?

Sí, las tres APIs son compatibles y se pueden usar simultáneamente en el mismo programa.

### ¿Hay alternativas a esta biblioteca?

Sí, algunas alternativas incluyen:
- **termcolor** (solo colores básicos)
- **rang** (C++)
- **colorama** (Python)
- Esta biblioteca ofrece más características y flexibilidad que la mayoría de las alternativas en C.

---

## Ejemplos Adicionales

### Barra de Progreso

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

### Sistema de Menú

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

## Contacto

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/c_print/issues)
- **Email**: c4rl0sill3sc4@protonmail.com

---

<p align="center">
  Made with {s:red:bold} in C
</p>