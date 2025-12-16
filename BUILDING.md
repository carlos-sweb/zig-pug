# Guía de Construcción y Distribución

Esta guía explica cómo construir zig-pug y preparar los binarios para distribución en GitHub.

## 📋 Tabla de Contenidos

- [Requisitos](#requisitos)
- [Scripts Disponibles](#scripts-disponibles)
- [Construcción Completa](#construcción-completa)
- [Construcción Parcial](#construcción-parcial)
- [Distribución](#distribución)
- [Estructura de Salida](#estructura-de-salida)

## Requisitos

- **Zig 0.15.2** o superior
- **Bash** (Linux/macOS) o WSL (Windows)
- **Node.js y npm** (opcional, solo para addons .node)
- **Git** (para control de versiones)

## Scripts Disponibles

### 1. `build-and-distribute.sh` ⭐ (Recomendado)
**Script maestro que ejecuta TODO el proceso:**
- Construye binarios CLI para todas las plataformas
- Construye librerías estáticas (.a, .lib)
- Construye librerías dinámicas (.so, .dll, .dylib)
- Construye addon Node.js (.node) para plataforma actual
- Organiza todo en la carpeta `bin/` para distribución

```bash
# Construcción completa + organización
./build-and-distribute.sh

# Solo CLI + organización
./build-and-distribute.sh --cli-only

# Sin addon Node.js + organización
./build-and-distribute.sh --skip-addon
```

### 2. `build-all.sh`
**Construye todos los binarios sin organizar:**

```bash
# Construir TODO
./build-all.sh

# Solo binarios CLI
./build-all.sh --cli-only

# Solo librerías (estáticas + dinámicas)
./build-all.sh --nodejs-only

# Solo addon .node
./build-all.sh --addon-only

# Saltar empaquetado de releases
./build-all.sh --skip-package
```

### 3. `organize-distribution.sh`
**Organiza binarios ya construidos en `bin/`:**

```bash
./organize-distribution.sh
```

Este script toma los binarios de `zig-out/bin/` y `nodejs/` y los organiza en la estructura de distribución.

## Construcción Completa

### Opción 1: Un solo comando (Recomendado)

```bash
./build-and-distribute.sh
```

### Opción 2: Paso a paso

```bash
# 1. Construir binarios
./build-all.sh

# 2. Organizar para distribución
./organize-distribution.sh
```

## Construcción Parcial

### Solo CLI para todas las plataformas

```bash
./build-all.sh --cli-only
./organize-distribution.sh
```

### Solo librerías (sin CLI)

```bash
./build-all.sh --nodejs-only
./organize-distribution.sh
```

### Para desarrollo local (plataforma actual)

```bash
# Solo CLI nativo
zig build

# CLI + ejecutar
zig build run -- input.zpug -o output.html

# Con tests
zig build test
```

## Distribución

### Estructura de `bin/`

Después de ejecutar `build-and-distribute.sh` o `organize-distribution.sh`, tendrás:

```
bin/
├── README.md                      # Documentación principal
├── linux-x86_64/
│   ├── zpug                       # CLI ejecutable
│   ├── libzig-pug.a              # Librería estática
│   ├── libzig-pug.so             # Librería dinámica
│   └── README.md                  # Instrucciones específicas
├── linux-aarch64/
│   ├── zpug
│   ├── libzig-pug.a
│   ├── libzig-pug.so
│   └── README.md
├── windows-x86_64/
│   ├── zpug.exe
│   ├── zig-pug.lib               # Librería estática
│   ├── zig-pug.dll               # Librería dinámica
│   └── README.md
├── macos-x86_64/
│   ├── zpug
│   ├── libzig-pug.a
│   ├── libzig-pug.dylib          # Librería dinámica
│   └── README.md
└── macos-aarch64/
    ├── zpug
    ├── libzig-pug.a
    ├── libzig-pug.dylib
    └── README.md
```

### Publicar en GitHub

#### Opción 1: Git LFS (Recomendado para binarios grandes)

```bash
# Instalar Git LFS
git lfs install

# Trackear binarios
git lfs track "bin/**/zpug*"
git lfs track "bin/**/*.a"
git lfs track "bin/**/*.so"
git lfs track "bin/**/*.lib"
git lfs track "bin/**/*.dll"
git lfs track "bin/**/*.dylib"

# Commit
git add .gitattributes bin/
git commit -m "Add prebuilt binaries v0.4.0"
git push
```

#### Opción 2: GitHub Releases (Recomendado)

1. Crear un release en GitHub:
   ```bash
   git tag v0.4.0
   git push origin v0.4.0
   ```

2. Ir a GitHub → Releases → Create new release

3. Subir los archivos de cada plataforma desde `bin/`

#### Opción 3: Commit directo (solo binarios pequeños)

```bash
git add bin/
git commit -m "Add prebuilt binaries v0.4.0"
git push
```

### Automatización con GitHub Actions

Puedes automatizar la construcción con CI/CD:

```yaml
# .github/workflows/build.yml
name: Build Binaries

on:
  push:
    tags:
      - 'v*'

jobs:
  build:
    strategy:
      matrix:
        os: [ubuntu-latest, macos-latest, windows-latest]

    runs-on: ${{ matrix.os }}

    steps:
      - uses: actions/checkout@v3

      - name: Setup Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.2

      - name: Build
        run: ./build-all.sh --cli-only

      - name: Upload artifacts
        uses: actions/upload-artifact@v3
        with:
          name: binaries-${{ matrix.os }}
          path: zig-out/bin/
```

## Estructura de Salida

### Durante la construcción

```
zig-out/
├── bin/
│   ├── linux-x86_64/zpug
│   ├── linux-aarch64/zpug
│   ├── windows-x86_64/zpug.exe
│   ├── macos-x86_64/zpug
│   └── macos-aarch64/zpug
└── release/
    ├── zig-pug-v0.4.0-linux-x86_64.tar.gz
    ├── zig-pug-v0.4.0-linux-aarch64.tar.gz
    ├── zig-pug-v0.4.0-windows-x86_64.tar.gz
    ├── zig-pug-v0.4.0-macos-x86_64.tar.gz
    └── zig-pug-v0.4.0-macos-aarch64.tar.gz

nodejs/
├── prebuilts/                     # Librerías estáticas
│   ├── linux-x64/libzig-pug.a
│   ├── linux-arm64/libzig-pug.a
│   ├── darwin-x64/libzig-pug.a
│   ├── darwin-arm64/libzig-pug.a
│   └── win32-x64/zig-pug.lib
├── dynamic-libs/                  # Librerías dinámicas
│   ├── linux-x64/libzig-pug.so
│   ├── linux-arm64/libzig-pug.so
│   ├── darwin-x64/libzig-pug.dylib
│   ├── darwin-arm64/libzig-pug.dylib
│   └── win32-x64/zig-pug.dll
└── prebuilt-binaries/            # Addons Node.js
    └── {platform}/zigpug.node
```

### Después de organizar

```
bin/                              # ← Listo para distribuir
├── README.md
├── linux-x86_64/
│   ├── zpug
│   ├── libzig-pug.a
│   ├── libzig-pug.so
│   └── README.md
├── linux-aarch64/
│   └── ...
├── windows-x86_64/
│   ├── zpug.exe
│   ├── zig-pug.lib
│   ├── zig-pug.dll
│   └── README.md
├── macos-x86_64/
│   └── ...
└── macos-aarch64/
    └── ...
```

## Limpieza

```bash
# Limpiar builds
rm -rf zig-out/ zig-cache/

# Limpiar distribución
rm -rf bin/

# Limpiar Node.js builds
rm -rf nodejs/prebuilts/ nodejs/dynamic-libs/ nodejs/build/

# Limpieza completa
rm -rf zig-out/ zig-cache/ bin/ nodejs/prebuilts/ nodejs/dynamic-libs/ nodejs/build/
```

## Troubleshooting

### Error: "zig: command not found"
Instala Zig desde https://ziglang.org/download/

### Error en construcción de librerías dinámicas
Las librerías dinámicas requieren libc. Si estás en un entorno sin libc (como Termux), usa `--skip-nodejs`.

### Binarios muy grandes
Los binarios de debug son grandes. Usa `ReleaseFast` o `ReleaseSmall`:
```bash
zig build -Doptimize=ReleaseSmall
```

### Error de permisos al ejecutar scripts
```bash
chmod +x build-all.sh organize-distribution.sh build-and-distribute.sh
```

## Soporte

- Issues: https://github.com/tu-usuario/zig-pug/issues
- Documentación: https://github.com/tu-usuario/zig-pug
- Ejemplos: https://github.com/tu-usuario/zig-pug/tree/main/examples
