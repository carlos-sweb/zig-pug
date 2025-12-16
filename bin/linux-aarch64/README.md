# zig-pug v0.4.0 - linux-aarch64

## Contenido

### CLI Tool
- `zpug` - Herramienta de línea de comandos para compilar templates Pug

### Librerías
- `libzig-pug.a` - Librería estática para enlazado estático
- `libzig-pug.so` - Librería dinámica para enlazado dinámico en tiempo de ejecución

## Uso del CLI

```bash
# Compilar un archivo .zpug a .html
./zpug input.zpug -o output.html

# Ver todas las opciones
./zpug --help
```

## Uso de las librerías

### Librería estática (`libzig-pug.a`)
Enlaza esta librería estáticamente en tu proyecto C/C++/Zig.

### Librería dinámica (`libzig-pug.so`)
Carga esta librería dinámicamente en tiempo de ejecución.

## Instalación

### Linux/macOS
```bash
# Copiar el ejecutable a /usr/local/bin
sudo cp zpug /usr/local/bin/zpug

# Copiar librerías (opcional)
sudo cp libzig-pug.a /usr/local/lib/
sudo cp libzig-pug.so /usr/local/lib/
sudo ldconfig  # Solo Linux
```

### Windows
Agrega el directorio que contiene `zpug` a tu PATH.

## Documentación completa
https://github.com/tu-usuario/zig-pug

## Licencia
Ver LICENSE en el repositorio principal.
