# zig-pug Binarios de Distribución

Este directorio contiene binarios precompilados de zig-pug para diferentes plataformas.

## Plataformas Disponibles

- `linux-x86_64/` - Linux 64-bit (x86_64)
- `linux-aarch64/` - Linux 64-bit (ARM64)
- `windows-x86_64/` - Windows 64-bit
- `macos-x86_64/` - macOS 64-bit (Intel)
- `macos-aarch64/` - macOS 64-bit (Apple Silicon)

## Contenido por Plataforma

Cada carpeta contiene:
- **CLI ejecutable** (`zpug` o `zpug.exe`) - Herramienta de línea de comandos
- **Librería estática** (`.a` o `.lib`) - Para enlazado estático
- **Librería dinámica** (`.so`, `.dll`, `.dylib`) - Para enlazado dinámico
- **README.md** - Instrucciones específicas de la plataforma

## Descarga Rápida

1. Navega a la carpeta de tu plataforma
2. Descarga los archivos que necesites
3. Sigue las instrucciones en el README de tu plataforma

## Uso del CLI

```bash
# Ver ayuda
zpug --help

# Compilar un template
zpug input.zpug -o output.html

# Con variables
zpug template.zpug -o out.html -v title="Mi Página" -v author="Tu Nombre"

# Pretty print
zpug input.zpug -o output.html --pretty
```

## Uso de Librerías

### Desde C/C++
```c
#include <zig-pug.h>

// Compilar template
char* html = zigpug_compile("div Hello World", NULL);
printf("%s\n", html);
free(html);
```

### Desde Zig
```zig
const zigpug = @import("zig-pug");

const html = try zigpug.compile(allocator, "div Hello World");
defer allocator.free(html);
```

## Construir desde Fuente

Si prefieres compilar desde el código fuente:

```bash
git clone https://github.com/tu-usuario/zig-pug
cd zig-pug
./build-all.sh
```

## Documentación

- [Documentación completa](https://github.com/tu-usuario/zig-pug)
- [Ejemplos](https://github.com/tu-usuario/zig-pug/tree/main/examples)
- [API Reference](https://github.com/tu-usuario/zig-pug/wiki)

## Licencia

Ver LICENSE en el repositorio principal.
