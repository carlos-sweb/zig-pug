#!/usr/bin/env bash
# Script para organizar binarios en carpeta bin/ para distribución GitHub
# Organiza CLI + librerías estáticas + librerías dinámicas por plataforma

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m'

# Configuración
VERSION="0.4.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
BIN_DIR="$PROJECT_ROOT/bin"
NODEJS_DIR="$PROJECT_ROOT/nodejs"

echo ""
echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${BLUE}║  📦 ZIG-PUG DISTRIBUTION ORGANIZER v${VERSION}            ║${NC}"
echo -e "${BLUE}║  Organizando binarios para distribución en GitHub        ║${NC}"
echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

# Verificar que existan los builds
if [ ! -d "zig-out/bin" ]; then
    echo -e "${RED}Error: No se encontró zig-out/bin/${NC}"
    echo -e "${YELLOW}Ejecuta primero: ./build-all.sh${NC}"
    exit 1
fi

# Limpiar y crear directorio bin
echo "🧹 Limpiando directorio bin/ anterior..."
rm -rf "$BIN_DIR"
mkdir -p "$BIN_DIR"
echo ""

# Definir mapeo de plataformas
# Formato: "nombre-plataforma:cli-binary:static-lib-ext:dynamic-lib-ext:node-platform"
declare -A PLATFORMS=(
    ["linux-x86_64"]="zpug:libzig-pug.a:libzig-pug.so:linux-x64"
    ["linux-aarch64"]="zpug:libzig-pug.a:libzig-pug.so:linux-arm64"
    ["windows-x86_64"]="zpug.exe:zig-pug.lib:zig-pug.dll:win32-x64"
    ["macos-x86_64"]="zpug:libzig-pug.a:libzig-pug.dylib:darwin-x64"
    ["macos-aarch64"]="zpug:libzig-pug.a:libzig-pug.dylib:darwin-arm64"
)

echo -e "${BLUE}📦 Organizando binarios por plataforma...${NC}"
echo ""

for platform in "${!PLATFORMS[@]}"; do
    IFS=: read -r cli_binary static_lib dynamic_lib node_platform <<< "${PLATFORMS[$platform]}"

    platform_dir="$BIN_DIR/$platform"
    mkdir -p "$platform_dir"

    echo -e "${BLUE}Procesando ${platform}...${NC}"

    # 1. Copiar CLI ejecutable
    cli_src="zig-out/bin/$platform/$cli_binary"
    if [ -f "$cli_src" ]; then
        cp "$cli_src" "$platform_dir/"
        echo -e "${GREEN}  ✓ CLI: $cli_binary${NC}"
    else
        echo -e "${YELLOW}  ⚠ CLI no encontrado: $cli_binary${NC}"
    fi

    # 2. Copiar librería estática
    static_src="$NODEJS_DIR/prebuilts/$node_platform/$static_lib"
    if [ -f "$static_src" ]; then
        cp "$static_src" "$platform_dir/"
        echo -e "${GREEN}  ✓ Static: $static_lib${NC}"
    else
        echo -e "${YELLOW}  ⚠ Librería estática no encontrada: $static_lib${NC}"
    fi

    # 3. Copiar librería dinámica
    dynamic_src="$PROJECT_ROOT/zig-out/nodejs/dynamic-libs/$node_platform/$dynamic_lib"
    if [ -f "$dynamic_src" ]; then
        cp "$dynamic_src" "$platform_dir/"
        echo -e "${GREEN}  ✓ Dynamic: $dynamic_lib${NC}"
    else
        echo -e "${YELLOW}  ⚠ Librería dinámica no encontrada: $dynamic_lib${NC}"
    fi

    # 4. Crear README para la plataforma
    readme="$platform_dir/README.md"
    cat > "$readme" << EOF
# zig-pug v${VERSION} - ${platform}

## Contenido

### CLI Tool
- \`$cli_binary\` - Herramienta de línea de comandos para compilar templates Pug

### Librerías
- \`$static_lib\` - Librería estática para enlazado estático
- \`$dynamic_lib\` - Librería dinámica para enlazado dinámico en tiempo de ejecución

## Uso del CLI

\`\`\`bash
# Compilar un archivo .zpug a .html
./$cli_binary input.zpug -o output.html

# Ver todas las opciones
./$cli_binary --help
\`\`\`

## Uso de las librerías

### Librería estática (\`$static_lib\`)
Enlaza esta librería estáticamente en tu proyecto C/C++/Zig.

### Librería dinámica (\`$dynamic_lib\`)
Carga esta librería dinámicamente en tiempo de ejecución.

## Instalación

### Linux/macOS
\`\`\`bash
# Copiar el ejecutable a /usr/local/bin
sudo cp $cli_binary /usr/local/bin/zpug

# Copiar librerías (opcional)
sudo cp $static_lib /usr/local/lib/
sudo cp $dynamic_lib /usr/local/lib/
sudo ldconfig  # Solo Linux
\`\`\`

### Windows
Agrega el directorio que contiene \`$cli_binary\` a tu PATH.

## Documentación completa
https://github.com/tu-usuario/zig-pug

## Licencia
Ver LICENSE en el repositorio principal.
EOF

    echo -e "${GREEN}  ✓ README.md${NC}"
    echo ""
done

# Crear README principal en bin/
echo -e "${BLUE}📝 Creando README principal...${NC}"
cat > "$BIN_DIR/README.md" << 'EOF'
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
EOF

echo -e "${GREEN}✓ README.md principal creado${NC}"
echo ""

# Mostrar resumen
echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           ✅ ORGANIZACIÓN COMPLETADA                      ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

echo -e "${BLUE}📦 Estructura creada en bin/:${NC}"
echo ""
tree -L 2 "$BIN_DIR" 2>/dev/null || find "$BIN_DIR" -maxdepth 2 -type f | sed 's|^|  |'
echo ""

echo -e "${BLUE}📊 Tamaños totales por plataforma:${NC}"
du -sh "$BIN_DIR"/*/ 2>/dev/null | sed 's|^|  |' || true
echo ""

echo -e "${GREEN}✨ Los binarios están listos para distribuir en GitHub!${NC}"
echo ""
echo -e "${YELLOW}Próximos pasos:${NC}"
echo "  1. git add bin/"
echo "  2. git commit -m 'Add prebuilt binaries for v${VERSION}'"
echo "  3. git push"
echo "  4. Crear release en GitHub y subir archivos de bin/"
echo ""
