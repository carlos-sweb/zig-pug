# Guía de Construcción de zig-pug

Esta guía explica cómo construir zig-pug para diferentes plataformas y entornos.

## Scripts de Construcción

### 🚀 Script Maestro: `build-all.sh` (RECOMENDADO)

Script unificado que construye TODO: binarios CLI, librerías Node.js y addon.

```bash
# Construir todo (CLI + Node.js + Addon + Packages)
./build-all.sh

# Ver opciones disponibles
./build-all.sh --help
```

**Opciones:**

| Opción | Descripción |
|--------|-------------|
| `--cli-only` | Solo construir binarios CLI |
| `--nodejs-only` | Solo construir librerías Node.js |
| `--addon-only` | Solo construir addon .node (plataforma actual) |
| `--skip-cli` | Saltar construcción de CLI |
| `--skip-nodejs` | Saltar construcción de librerías Node.js |
| `--skip-addon` | Saltar construcción de addon .node |
| `--skip-package` | Saltar empaquetado de releases |
| `-h, --help` | Mostrar ayuda |

**Ejemplos:**

```bash
# Solo CLI para todas las plataformas
./build-all.sh --cli-only

# Solo librerías Node.js
./build-all.sh --nodejs-only

# CLI + Node.js (sin addon)
./build-all.sh --skip-addon

# Todo sin empaquetar releases
./build-all.sh --skip-package
```

### 📦 Scripts Individuales (Legacy)

Estos scripts antiguos están disponibles pero se recomienda usar `build-all.sh`:

#### `build-binaries.sh`
Construye solo los binarios CLI para todas las plataformas.

```bash
./build-binaries.sh
```

**Output:**
- `zig-out/bin/linux-x86_64/zpug`
- `zig-out/bin/linux-aarch64/zpug`
- `zig-out/bin/windows-x86_64/zpug.exe`
- `zig-out/bin/macos-x86_64/zpug`
- `zig-out/bin/macos-aarch64/zpug`
- `zig-out/release/*.tar.gz` (releases empaquetados)

#### `nodejs/build-prebuilts.sh`
Construye las librerías estáticas de Zig (.a/.lib) para Node.js.

```bash
cd nodejs
./build-prebuilts.sh
```

**Output:**
- `nodejs/prebuilts/linux-x64/libzig-pug.a`
- `nodejs/prebuilts/linux-arm64/libzig-pug.a`
- `nodejs/prebuilts/darwin-x64/libzig-pug.a`
- `nodejs/prebuilts/darwin-arm64/libzig-pug.a`
- `nodejs/prebuilts/win32-x64/zig-pug.lib`

#### `nodejs/build-node-binaries.sh`
Construye el addon .node para la plataforma actual.

```bash
cd nodejs
./build-node-binaries.sh
```

**Output:**
- `nodejs/prebuilt-binaries/{platform}/zigpug.node`

**Nota:** Solo construye para la plataforma donde se ejecuta. Para otras plataformas, ejecutar en cada una o usar CI/CD.

#### `nodejs/build-termux.sh`
Script específico para compilar en Termux/Android.

```bash
cd nodejs
./build-termux.sh
```

## Flujo de Trabajo Recomendado

### Desarrollo Local

```bash
# Construcción rápida para desarrollo
zig build

# Ejecutar tests
zig build test

# Construir para tu plataforma actual
./build-all.sh --cli-only
```

### Preparación para Release

```bash
# 1. Construir todo
./build-all.sh

# 2. Verificar que todo se construyó
ls -lh zig-out/bin/*/zpug*
ls -lh nodejs/prebuilts/*/*.{a,lib}
ls -lh nodejs/prebuilt-binaries/*/*.node

# 3. Probar binarios
./zig-out/bin/linux-x86_64/zpug --version

# 4. Probar addon Node.js
cd nodejs
npm test
```

### Publicar a npm

```bash
# 1. Construir librerías para todas las plataformas
./build-all.sh --nodejs-only

# 2. Actualizar versión en package.json
cd nodejs
npm version patch  # o minor, o major

# 3. Publicar
npm publish
```

## Requisitos por Plataforma

### Linux

```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# Zig 0.15.2
# Descargar de https://ziglang.org/download/
```

### macOS

```bash
# Xcode Command Line Tools
xcode-select --install

# Zig 0.15.2
brew install zig
```

### Windows

```bash
# Visual Studio Build Tools
# o MinGW-w64

# Zig 0.15.2
# Descargar de https://ziglang.org/download/
```

### Termux/Android

```bash
# Instalar dependencias
pkg install zig nodejs python build-essential

# Usar script específico
cd nodejs
./build-termux.sh
```

## Troubleshooting

### Error: "zig: command not found"

Instala Zig 0.15.2 desde https://ziglang.org/download/

```bash
# Verificar versión
zig version
# Output esperado: 0.15.2
```

### Error: "npm: command not found"

Instala Node.js:

```bash
# Ubuntu/Debian
curl -fsSL https://deb.nodesource.com/setup_20.x | sudo -E bash -
sudo apt-get install -y nodejs

# macOS
brew install node

# Windows
# Descargar de https://nodejs.org/
```

### Error al construir addon en Termux

El addon .node no funciona en Termux debido a restricciones de Android. El CLI funciona perfectamente.

```bash
# Usar solo el CLI en Termux
zig build
./zig-out/bin/zpug --version
```

### Error: "libzig-pug.a not found"

Primero construye las librerías antes del addon:

```bash
# Opción 1: Construir todo
./build-all.sh

# Opción 2: Solo librerías primero
./build-all.sh --nodejs-only
# Luego addon
./build-all.sh --addon-only
```

## Compilación Cruzada (Cross-compilation)

Zig soporta compilación cruzada out-of-the-box:

### Binarios CLI

```bash
# Linux desde cualquier plataforma
zig build cross-linux-x86_64

# macOS desde cualquier plataforma
zig build cross-macos-aarch64

# Windows desde cualquier plataforma
zig build cross-windows-x86_64
```

### Librerías Node.js

```bash
# Construir para todas las plataformas desde cualquier sistema
./build-all.sh --nodejs-only
```

### Limitación: Addon .node

El addon .node **NO** puede ser compilado cruzadamente debido a limitaciones de node-gyp. Debes construirlo en cada plataforma objetivo o usar CI/CD.

## CI/CD con GitHub Actions

Ejemplo de workflow para construir en todas las plataformas:

```yaml
name: Build All Platforms

on: [push, pull_request]

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]
        node: [18, 20]

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v3

      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.2

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: ${{ matrix.node }}

      - name: Build All
        run: |
          chmod +x build-all.sh
          ./build-all.sh

      - name: Upload Artifacts
        uses: actions/upload-artifact@v3
        with:
          name: binaries-${{ matrix.os }}-node${{ matrix.node }}
          path: |
            zig-out/release/*.tar.gz
            nodejs/prebuilts/
            nodejs/prebuilt-binaries/
```

## Estructura de Salida

Después de ejecutar `./build-all.sh`, tendrás:

```
zig-pug/
├── zig-out/
│   ├── bin/
│   │   ├── linux-x86_64/zpug
│   │   ├── linux-aarch64/zpug
│   │   ├── windows-x86_64/zpug.exe
│   │   ├── macos-x86_64/zpug
│   │   └── macos-aarch64/zpug
│   └── release/
│       ├── zig-pug-v0.4.0-linux-x86_64.tar.gz
│       ├── zig-pug-v0.4.0-linux-aarch64.tar.gz
│       ├── zig-pug-v0.4.0-windows-x86_64.tar.gz
│       ├── zig-pug-v0.4.0-macos-x86_64.tar.gz
│       └── zig-pug-v0.4.0-macos-aarch64.tar.gz
└── nodejs/
    ├── prebuilts/
    │   ├── linux-x64/libzig-pug.a
    │   ├── linux-arm64/libzig-pug.a
    │   ├── darwin-x64/libzig-pug.a
    │   ├── darwin-arm64/libzig-pug.a
    │   └── win32-x64/zig-pug.lib
    └── prebuilt-binaries/
        └── {platform}/zigpug.node
```

## Comparación de Scripts

| Script | CLI | Librerías | Addon | Packages |
|--------|-----|-----------|-------|----------|
| `build-all.sh` | ✅ | ✅ | ✅ | ✅ |
| `build-binaries.sh` | ✅ | ❌ | ❌ | ✅ |
| `nodejs/build-prebuilts.sh` | ❌ | ✅ | ❌ | ❌ |
| `nodejs/build-node-binaries.sh` | ❌ | ❌ | ✅ | ❌ |
| `nodejs/build-termux.sh` | ❌ | ❌ | ✅* | ❌ |

\* Solo para Termux/Android

## Recomendaciones

1. **Uso diario:** `zig build` - Rápido para desarrollo
2. **Testing completo:** `./build-all.sh` - Construye todo
3. **Solo CLI:** `./build-all.sh --cli-only` - Binarios para distribución
4. **Solo Node.js:** `./build-all.sh --nodejs-only` - Librerías para npm
5. **Publicar npm:** Construir librerías en cada plataforma o CI/CD

---

**Última actualización:** Diciembre 2024
**Versión:** 0.4.0
