# Building Node.js Addon (.node) for Multiple Platforms

## ❓ Por Qué NO Puedes Hacer Cross-Compilation de Addons Node.js

A diferencia de binarios estáticos/dinámicos de Zig, los **addons Node.js** tienen restricciones:

### Limitaciones de node-gyp:

| Aspecto | Cross-Compilation Zig | node-gyp |
|---------|----------------------|----------|
| **Compilador** | Zig (universal) | gcc/clang/MSVC (específico del OS) |
| **Headers** | Incluidos en Zig | Requiere Node.js headers de cada plataforma |
| **Libc** | Puede elegir (musl, glibc, mingw) | Usa libc del sistema |
| **ABI** | Controlada por Zig | Específica de cada plataforma |
| **Cross-compile** | ✅ Sí | ❌ No fácilmente |

### Ejemplo del Problema:

```bash
# ❌ Esto NO funciona:
node-gyp rebuild --target=darwin       # No existe
node-gyp rebuild --target-arch=arm64   # Solo arquitectura, no OS

# ✅ Esto sí funciona (pero solo para tu plataforma):
node-gyp rebuild
```

---

## ✅ Soluciones Profesionales

### **Opción 1: GitHub Actions (Recomendado)** ⭐

Construye automáticamente en cada plataforma cuando haces push:

#### Archivo ya creado: `.github/workflows/build-node-addon.yml`

**Cómo funciona:**
1. Cada plataforma (Linux, macOS Intel, macOS ARM, Windows) corre en su propio runner
2. Cada runner compila el addon nativamente
3. Los addons se suben como artifacts
4. Se combinan en un solo artifact `all-node-addons`

**Uso:**

```bash
# 1. Hacer push o crear tag
git push origin main

# 2. Ver progreso en GitHub Actions
# https://github.com/tu-usuario/zig-pug/actions

# 3. Descargar artifacts:
# - Ir a la acción completada
# - Descargar "all-node-addons"
# - Extraer a nodejs/prebuilt-binaries/
```

**En Releases:**
```bash
# Crear tag para release
git tag v0.4.0
git push origin v0.4.0

# GitHub Actions automáticamente:
# - Construye addons para todas las plataformas
# - Crea release con los binarios
```

---

### **Opción 2: Script Local (Solo Tu Plataforma)**

Para desarrollo local, usa el script creado:

```bash
./build-node-addon.sh
```

**Qué hace:**
1. ✅ Detecta tu plataforma actual (linux-x64, darwin-arm64, etc.)
2. ✅ Construye la librería estática necesaria
3. ✅ Instala dependencias de npm
4. ✅ Compila el addon con node-gyp
5. ✅ Copia a `nodejs/prebuilt-binaries/{plataforma}/`
6. ✅ Ejecuta tests

**Limitación:** Solo genera el `.node` para tu plataforma actual.

---

### **Opción 3: Construcción Manual en Cada Plataforma**

Si tienes acceso a múltiples máquinas:

#### En Linux:
```bash
./build-node-addon.sh
# Genera: nodejs/prebuilt-binaries/linux-x64/zigpug.node
```

#### En macOS Intel:
```bash
./build-node-addon.sh
# Genera: nodejs/prebuilt-binaries/darwin-x64/zigpug.node
```

#### En macOS Apple Silicon:
```bash
./build-node-addon.sh
# Genera: nodejs/prebuilt-binaries/darwin-arm64/zigpug.node
```

#### En Windows:
```bash
./build-node-addon.sh
# Genera: nodejs/prebuilt-binaries/win32-x64/zigpug.node
```

Luego **combina todos** en un commit.

---

### **Opción 4: Docker para Linux (Multi-Arquitectura)**

Para Linux, puedes usar Docker con QEMU:

```bash
# Linux x64
docker run --rm -v $(pwd):/workspace -w /workspace node:20 \
  bash -c "apt-get update && apt-get install -y build-essential && ./build-node-addon.sh"

# Linux ARM64 (con QEMU)
docker run --platform linux/arm64 --rm -v $(pwd):/workspace -w /workspace node:20 \
  bash -c "apt-get update && apt-get install -y build-essential && ./build-node-addon.sh"
```

**Limitación:** Solo funciona para Linux. macOS y Windows requieren runners nativos.

---

## 📦 Estructura Final de Addons

Después de construir en todas las plataformas:

```
nodejs/prebuilt-binaries/
├── linux-x64/
│   └── zigpug.node
├── linux-arm64/
│   └── zigpug.node
├── darwin-x64/
│   └── zigpug.node
├── darwin-arm64/
│   └── zigpug.node
└── win32-x64/
    └── zigpug.node
```

---

## 🚀 Flujo de Trabajo Recomendado

### Para Desarrollo Local:
```bash
# Construir addon para tu plataforma
./build-node-addon.sh

# Probar
cd nodejs
npm test
```

### Para Release:
```bash
# 1. Crear tag
git tag v0.4.1
git push origin v0.4.1

# 2. GitHub Actions automáticamente:
#    - Construye addons para todas las plataformas
#    - Crea release en GitHub
#    - Sube los .node como assets

# 3. Descargar artifacts de GitHub Actions
# 4. Commit a nodejs/prebuilt-binaries/
git add nodejs/prebuilt-binaries/
git commit -m "Add prebuilt Node.js addons v0.4.1"
git push
```

---

## 🔍 Comparación de Opciones

| Método | Plataformas | Automático | Requiere Acceso | Recomendado |
|--------|-------------|------------|-----------------|-------------|
| **GitHub Actions** | Todas | ✅ Sí | ❌ No | ⭐⭐⭐⭐⭐ |
| **Script Local** | Solo actual | ❌ No | ✅ Sí | ⭐⭐⭐ |
| **Manual** | Todas | ❌ No | ✅ Sí | ⭐⭐ |
| **Docker** | Solo Linux | Parcial | ❌ No | ⭐⭐ |

---

## 💡 Por Qué GitHub Actions es Mejor

1. **Automatización Total** - Push y listo
2. **Todas las Plataformas** - No necesitas acceso a Mac/Windows
3. **Consistencia** - Mismo entorno cada vez
4. **Gratis** - Para repos públicos
5. **Integración** - Se conecta con Releases automáticamente

---

## 📝 Notas Importantes

### Diferencia con CLI/Librerías:

- **CLI (`zpug`)**: Cross-compilación ✅ (Zig puro)
- **Librerías (`.a`, `.so`, `.dll`)**: Cross-compilación ✅ (Zig puro)
- **Addon Node.js (`.node`)**: Cross-compilación ❌ (requiere compilador nativo)

### Tamaños Esperados:

```
zigpug.node sizes:
- Linux x64:    ~2.8M
- Linux ARM64:  ~3.0M
- macOS x64:    ~1.2M
- macOS ARM64:  ~1.1M
- Windows x64:  ~1.5M
```

---

## 🛠️ Troubleshooting

### Error: "node-gyp not found"
```bash
npm install -g node-gyp
```

### Error: "Python not found"
node-gyp requiere Python 3:
```bash
# Ubuntu/Debian
sudo apt-get install python3

# macOS
brew install python3

# Windows
# Descargar desde python.org
```

### Error: "No compiler found"
```bash
# Ubuntu/Debian
sudo apt-get install build-essential

# macOS
xcode-select --install

# Windows
# Instalar Visual Studio Build Tools
```

---

## 📚 Recursos

- [node-gyp documentation](https://github.com/nodejs/node-gyp)
- [GitHub Actions matrix builds](https://docs.github.com/en/actions/using-jobs/using-a-matrix-for-your-jobs)
- [prebuildify](https://github.com/prebuild/prebuildify) - alternativa automática

---

## 🎯 Resumen TL;DR

**¿Puedo hacer cross-compilation de .node como con Zig?**
❌ No, node-gyp no lo soporta.

**¿Cuál es la mejor solución?**
✅ GitHub Actions - Construye automáticamente en todas las plataformas.

**¿Puedo construir localmente?**
✅ Sí, pero solo para tu plataforma actual con `./build-node-addon.sh`

**¿Qué hago para releases?**
✅ Usa GitHub Actions - automáticamente construye todo cuando creas un tag.
