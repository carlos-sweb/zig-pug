#!/usr/bin/env bash
# Script maestro de construcción para zig-pug
# Construye binarios CLI, librerías Node.js y addon para todas las plataformas

set -e

# Colores
RED='\033[0;31m'
GREEN='\033[0;32m'
BLUE='\033[0;34m'
YELLOW='\033[1;33m'
NC='\033[0m' # Sin color

# Configuración
VERSION="0.4.0"
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$SCRIPT_DIR"
NODEJS_DIR="$SCRIPT_DIR/nodejs"
PREBUILTS_DIR="$NODEJS_DIR/prebuilts"
NODE_BINARIES_DIR="$NODEJS_DIR/prebuilt-binaries"

# Banner
echo ""
echo "╔═══════════════════════════════════════════════════════════╗"
echo "║         🚀 ZIG-PUG BUILD SYSTEM v${VERSION}                 ║"
echo "║     Construcción completa: CLI + Node.js + Addon          ║"
echo "╚═══════════════════════════════════════════════════════════╝"
echo ""

# Función de ayuda
show_help() {
    echo "Uso: ./build-all.sh [opciones]"
    echo ""
    echo "Opciones:"
    echo "  --cli-only         Solo construir binarios CLI"
    echo "  --nodejs-only      Solo construir librerías Node.js"
    echo "  --addon-only       Solo construir addon .node (plataforma actual)"
    echo "  --skip-cli         Saltar construcción de CLI"
    echo "  --skip-nodejs      Saltar construcción de librerías Node.js"
    echo "  --skip-addon       Saltar construcción de addon .node"
    echo "  --skip-package     Saltar empaquetado de releases"
    echo "  -h, --help         Mostrar esta ayuda"
    echo ""
    echo "Sin opciones: construye TODO (CLI + Node.js + addon + packages)"
    echo ""
    exit 0
}

# Parsear argumentos
BUILD_CLI=true
BUILD_NODEJS=true
BUILD_ADDON=true
BUILD_PACKAGE=true

for arg in "$@"; do
    case $arg in
        --cli-only)
            BUILD_NODEJS=false
            BUILD_ADDON=false
            ;;
        --nodejs-only)
            BUILD_CLI=false
            BUILD_ADDON=false
            ;;
        --addon-only)
            BUILD_CLI=false
            BUILD_NODEJS=false
            ;;
        --skip-cli)
            BUILD_CLI=false
            ;;
        --skip-nodejs)
            BUILD_NODEJS=false
            ;;
        --skip-addon)
            BUILD_ADDON=false
            ;;
        --skip-package)
            BUILD_PACKAGE=false
            ;;
        -h|--help)
            show_help
            ;;
        *)
            echo -e "${RED}Error: Opción desconocida '$arg'${NC}"
            show_help
            ;;
    esac
done

# ============================================================================
# PARTE 1: CONSTRUIR BINARIOS CLI
# ============================================================================

if [ "$BUILD_CLI" = true ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  PASO 1/3: Construyendo binarios CLI (zpug)              ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Limpiar builds anteriores
    echo "🧹 Limpiando builds anteriores de CLI..."
    rm -rf zig-out/bin/*
    echo ""

    # Definir plataformas CLI
    CLI_TARGETS=(
        "linux-x86_64:zpug"
        "linux-aarch64:zpug"
        "windows-x86_64:zpug.exe"
        "macos-x86_64:zpug"
        "macos-aarch64:zpug"
    )

    for target in "${CLI_TARGETS[@]}"; do
        IFS=: read -r platform binary <<< "$target"

        echo -e "${BLUE}Construyendo CLI para ${platform}...${NC}"
        zig build cross-${platform}

        if [ -f "zig-out/bin/${platform}/${binary}" ]; then
            size=$(du -h "zig-out/bin/${platform}/${binary}" | cut -f1)
            echo -e "${GREEN}✓ ${platform}/${binary} (${size})${NC}"
        else
            echo -e "${RED}✗ Error construyendo ${platform}${NC}"
            exit 1
        fi
        echo ""
    done

    echo -e "${GREEN}✅ Binarios CLI completados${NC}"
    echo ""
fi

# ============================================================================
# PARTE 2: CONSTRUIR LIBRERÍAS NODE.JS (ESTÁTICAS Y DINÁMICAS)
# ============================================================================

if [ "$BUILD_NODEJS" = true ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  PASO 2/3: Construyendo librerías (.a/.lib/.so/.dll)     ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Limpiar builds anteriores
    echo "🧹 Limpiando prebuilts anteriores..."
    rm -rf "$PREBUILTS_DIR"
    mkdir -p "$PREBUILTS_DIR"
    echo ""

    # Definir plataformas Node.js
    # Formato: "zig-target:output-folder:library-name"
    NODEJS_TARGETS=(
        "x86_64-linux:linux-x64:libzig-pug.a"
        "aarch64-linux:linux-arm64:libzig-pug.a"
        "x86_64-macos:darwin-x64:libzig-pug.a"
        "aarch64-macos:darwin-arm64:libzig-pug.a"
        "x86_64-windows:win32-x64:zig-pug.lib"
    )

    for target in "${NODEJS_TARGETS[@]}"; do
        IFS=: read -r zig_target output_dir lib_name <<< "$target"

        echo -e "${BLUE}Construyendo librería para ${output_dir}...${NC}"

        # Construir librería estática
        zig build lib-static \
            -Dtarget="$zig_target" \
            -Doptimize=ReleaseFast \
            --prefix-lib-dir "$PREBUILTS_DIR/$output_dir"

        # Verificar que se creó
        if [ -f "$PREBUILTS_DIR/$output_dir/$lib_name" ]; then
            size=$(du -h "$PREBUILTS_DIR/$output_dir/$lib_name" | cut -f1)
            echo -e "${GREEN}✓ ${output_dir}/${lib_name} (${size})${NC}"
        else
            echo -e "${RED}✗ Error construyendo librería para ${output_dir}${NC}"
            exit 1
        fi
        echo ""
    done

    echo -e "${GREEN}✅ Librerías estáticas Node.js completadas${NC}"
    echo ""

    # Construir librerías dinámicas (.so / .dll / .dylib)
    echo -e "${BLUE}Construyendo librerías dinámicas...${NC}"
    echo ""

    # Directorio para librerías dinámicas (usa zig-out como base)
    DYNAMIC_LIBS_DIR="$PROJECT_ROOT/zig-out/nodejs/dynamic-libs"
    rm -rf "$DYNAMIC_LIBS_DIR"
    mkdir -p "$DYNAMIC_LIBS_DIR"

    # Mapeo de plataforma a extensión de librería dinámica
    # Formato: "zig-target:output-folder:shared-lib-name"
    DYNAMIC_TARGETS=(
        "x86_64-linux:linux-x64:libzig-pug.so"
        "aarch64-linux:linux-arm64:libzig-pug.so"
        "x86_64-macos:darwin-x64:libzig-pug.dylib"
        "aarch64-macos:darwin-arm64:libzig-pug.dylib"
        "x86_64-windows:win32-x64:zig-pug.dll"
    )

    for target in "${DYNAMIC_TARGETS[@]}"; do
        IFS=: read -r zig_target output_dir lib_name <<< "$target"

        echo -e "${BLUE}Construyendo librería dinámica para ${output_dir}...${NC}"

        # Construir librería dinámica
        zig build lib-shared \
            -Dtarget="$zig_target" \
            -Doptimize=ReleaseFast \
            --prefix-lib-dir "$DYNAMIC_LIBS_DIR/$output_dir"

        # Para Windows, el .dll va a zig-out/bin/ y el .lib a lib-dir
        # Necesitamos mover el .dll al lugar correcto
        if [ "$zig_target" = "x86_64-windows" ]; then
            # Copiar DLL desde zig-out/bin/
            if [ -f "zig-out/bin/zig-pug.dll" ]; then
                mv "zig-out/bin/zig-pug.dll" "$DYNAMIC_LIBS_DIR/$output_dir/"
            fi
        fi

        # Verificar que se creó
        if [ -f "$DYNAMIC_LIBS_DIR/$output_dir/$lib_name" ]; then
            size=$(du -h "$DYNAMIC_LIBS_DIR/$output_dir/$lib_name" | cut -f1)
            echo -e "${GREEN}✓ ${output_dir}/${lib_name} (${size})${NC}"
        else
            echo -e "${RED}✗ Error construyendo librería dinámica para ${output_dir}${NC}"
            exit 1
        fi
        echo ""
    done

    echo -e "${GREEN}✅ Librerías dinámicas completadas${NC}"
    echo ""
fi

# ============================================================================
# PARTE 3: CONSTRUIR ADDON NODE.JS (.node)
# ============================================================================

if [ "$BUILD_ADDON" = true ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  PASO 3/3: Construyendo addon Node.js (.node)            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    # Verificar que existan las librerías precompiladas
    if [ ! -d "$PREBUILTS_DIR" ]; then
        echo -e "${YELLOW}⚠️  No se encontró el directorio prebuilts/${NC}"
        echo -e "${YELLOW}   Ejecutando construcción de librerías primero...${NC}"
        echo ""
        # Reconstruir librerías
        BUILD_NODEJS=true
        # Ejecutar la parte 2 recursivamente (simplificado aquí)
        echo -e "${RED}Error: Ejecuta primero con --nodejs-only o sin --skip-nodejs${NC}"
        exit 1
    fi

    # Detectar plataforma actual
    CURRENT_OS=$(uname -s | tr '[:upper:]' '[:lower:]')
    CURRENT_ARCH=$(uname -m)

    # Normalizar nombres
    case "$CURRENT_ARCH" in
        x86_64) CURRENT_ARCH="x64" ;;
        aarch64|arm64) CURRENT_ARCH="arm64" ;;
    esac

    case "$CURRENT_OS" in
        darwin) CURRENT_OS="darwin" ;;
        linux) CURRENT_OS="linux" ;;
        mingw*|msys*|cygwin*) CURRENT_OS="win32" ;;
    esac

    CURRENT_PLATFORM="${CURRENT_OS}-${CURRENT_ARCH}"

    echo "📍 Plataforma detectada: ${CURRENT_PLATFORM}"
    echo ""

    # Limpiar y reconstruir addon
    echo "🧹 Limpiando build anterior del addon..."
    cd "$NODEJS_DIR"
    rm -rf build/
    echo ""

    echo -e "${BLUE}Construyendo addon para ${CURRENT_PLATFORM}...${NC}"
    npm run rebuild

    # Verificar que se construyó
    if [ -f "build/Release/zigpug.node" ]; then
        size=$(du -h "build/Release/zigpug.node" | cut -f1)
        echo ""
        echo -e "${GREEN}✓ zigpug.node construido exitosamente (${size})${NC}"

        # Copiar a directorio de binarios precompilados
        mkdir -p "$NODE_BINARIES_DIR/$CURRENT_PLATFORM"
        cp "build/Release/zigpug.node" "$NODE_BINARIES_DIR/$CURRENT_PLATFORM/"
        echo -e "${GREEN}✓ Copiado a prebuilt-binaries/${CURRENT_PLATFORM}/${NC}"
    else
        echo -e "${RED}✗ Error construyendo addon .node${NC}"
        exit 1
    fi

    cd "$PROJECT_ROOT"
    echo ""
    echo -e "${GREEN}✅ Addon Node.js completado${NC}"
    echo ""
    echo -e "${YELLOW}Nota: El addon .node solo se construye para la plataforma actual.${NC}"
    echo -e "${YELLOW}Para otras plataformas, ejecuta este script en cada una o usa CI/CD.${NC}"
    echo ""
fi

# ============================================================================
# PARTE 4: EMPAQUETAR RELEASES
# ============================================================================

if [ "$BUILD_PACKAGE" = true ] && [ "$BUILD_CLI" = true ]; then
    echo -e "${BLUE}╔═══════════════════════════════════════════════════════════╗${NC}"
    echo -e "${BLUE}║  EXTRA: Empaquetando releases                            ║${NC}"
    echo -e "${BLUE}╚═══════════════════════════════════════════════════════════╝${NC}"
    echo ""

    RELEASE_DIR="zig-out/release"
    mkdir -p "$RELEASE_DIR"

    # Función para crear archivo comprimido
    create_archive() {
        local platform=$1
        local binary_name=$2
        local archive_name="zig-pug-v${VERSION}-${platform}"

        echo "📦 Creando ${archive_name}..."

        mkdir -p "$RELEASE_DIR/$archive_name"

        # Copiar binario
        cp "zig-out/bin/${platform}/${binary_name}" "$RELEASE_DIR/$archive_name/"

        # Copiar documentación
        cp README.md "$RELEASE_DIR/$archive_name/"
        cp LICENSE "$RELEASE_DIR/$archive_name/" 2>/dev/null || echo "  (Sin LICENSE)"

        # Crear archivo comprimido
        cd "$RELEASE_DIR"
        tar czf "${archive_name}.tar.gz" "$archive_name"
        cd - > /dev/null

        # Limpiar directorio temporal
        rm -rf "$RELEASE_DIR/$archive_name"

        size=$(du -h "$RELEASE_DIR/${archive_name}.tar.gz" | cut -f1)
        echo -e "${GREEN}✓ ${archive_name}.tar.gz (${size})${NC}"
    }

    # Crear archivos para cada plataforma
    create_archive "linux-x86_64" "zpug"
    create_archive "linux-aarch64" "zpug"
    create_archive "windows-x86_64" "zpug.exe"
    create_archive "macos-x86_64" "zpug"
    create_archive "macos-aarch64" "zpug"

    echo ""
    echo -e "${GREEN}✅ Releases empaquetados${NC}"
    echo ""
fi

# ============================================================================
# RESUMEN FINAL
# ============================================================================

echo ""
echo -e "${GREEN}╔═══════════════════════════════════════════════════════════╗${NC}"
echo -e "${GREEN}║           🎉 CONSTRUCCIÓN COMPLETADA EXITOSAMENTE         ║${NC}"
echo -e "${GREEN}╚═══════════════════════════════════════════════════════════╝${NC}"
echo ""

if [ "$BUILD_CLI" = true ]; then
    echo -e "${BLUE}📦 Binarios CLI disponibles en:${NC}"
    echo "   zig-out/bin/linux-x86_64/zpug"
    echo "   zig-out/bin/linux-aarch64/zpug"
    echo "   zig-out/bin/windows-x86_64/zpug.exe"
    echo "   zig-out/bin/macos-x86_64/zpug"
    echo "   zig-out/bin/macos-aarch64/zpug"
    echo ""
fi

if [ "$BUILD_NODEJS" = true ]; then
    echo -e "${BLUE}📦 Librerías estáticas disponibles en:${NC}"
    ls -1 "$PREBUILTS_DIR"/*/*.a "$PREBUILTS_DIR"/*/*.lib 2>/dev/null | sed 's|.*/prebuilts/|   nodejs/prebuilts/|' || true
    echo ""
    echo -e "${BLUE}📦 Librerías dinámicas disponibles en:${NC}"
    ls -1 "$DYNAMIC_LIBS_DIR"/*/*.{so,dll,dylib} 2>/dev/null | sed 's|.*/dynamic-libs/|   nodejs/dynamic-libs/|' || true
    echo ""
fi

if [ "$BUILD_ADDON" = true ]; then
    echo -e "${BLUE}📦 Addon Node.js disponible en:${NC}"
    ls -1 "$NODE_BINARIES_DIR"/*/*.node 2>/dev/null | sed 's|.*/prebuilt-binaries/|   nodejs/prebuilt-binaries/|' || true
    echo ""
fi

if [ "$BUILD_PACKAGE" = true ] && [ "$BUILD_CLI" = true ]; then
    echo -e "${BLUE}📦 Releases empaquetados en:${NC}"
    ls -1 "$RELEASE_DIR"/*.tar.gz 2>/dev/null | sed 's|^|   |' || true
    echo ""
fi

echo -e "${BLUE}📊 Tamaños:${NC}"
if [ "$BUILD_CLI" = true ]; then
    echo -e "${YELLOW}  CLI:${NC}"
    du -h zig-out/bin/*/zpug* 2>/dev/null | sed 's/^/    /' || true
fi
if [ "$BUILD_NODEJS" = true ]; then
    echo -e "${YELLOW}  Librerías estáticas:${NC}"
    du -h "$PREBUILTS_DIR"/*/*.{a,lib} 2>/dev/null | sed 's/^/    /' || true
    echo -e "${YELLOW}  Librerías dinámicas:${NC}"
    du -h "$DYNAMIC_LIBS_DIR"/*/*.{so,dll,dylib} 2>/dev/null | sed 's/^/    /' || true
fi
if [ "$BUILD_ADDON" = true ]; then
    echo -e "${YELLOW}  Addon:${NC}"
    du -h "$NODE_BINARIES_DIR"/*/*.node 2>/dev/null | sed 's/^/    /' || true
fi

echo ""
echo -e "${GREEN}✨ Todo listo para usar o publicar!${NC}"
echo ""
