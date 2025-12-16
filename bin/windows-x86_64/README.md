# zig-pug v0.4.0 - windows-x86_64

## Contenido

### CLI Tool
- `zpug.exe` - Herramienta de línea de comandos para compilar templates Pug

### Librerías
- `zig-pug.lib` - Librería estática para enlazado estático
- `zig-pug.dll` - Librería dinámica para enlazado dinámico en tiempo de ejecución

## Uso del CLI

```bash
# Compilar un archivo .zpug a .html
./zpug.exe input.zpug -o output.html

# Ver todas las opciones
./zpug.exe --help
```

## Uso de las librerías

### Librería estática (`zig-pug.lib`)
Enlaza esta librería estáticamente en tu proyecto C/C++/Zig.

### Librería dinámica (`zig-pug.dll`)
Carga esta librería dinámicamente en tiempo de ejecución.

## Instalación

### Linux/macOS
```bash
# Copiar el ejecutable a /usr/local/bin
sudo cp zpug.exe /usr/local/bin/zpug

# Copiar librerías (opcional)
sudo cp zig-pug.lib /usr/local/lib/
sudo cp zig-pug.dll /usr/local/lib/
sudo ldconfig  # Solo Linux
```

### Windows
Agrega el directorio que contiene `zpug.exe` a tu PATH.

## Documentación completa
https://github.com/tu-usuario/zig-pug

## Licencia
Ver LICENSE en el repositorio principal.
