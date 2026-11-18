# Estructura de Distribución de Binarios

## ⚠️ IMPORTANTE - LEER ANTES DE MODIFICAR BUILD SCRIPTS

### Estructura de Directorios

```
zig-pug/
├── bin/                    ← DISTRIBUIBLE (git tracked)
│   ├── linux-x86_64/
│   ├── linux-aarch64/
│   ├── windows-x86_64/
│   ├── macos-x86_64/
│   └── macos-aarch64/
│
├── libs/                   ← DISTRIBUIBLE (git tracked)
│   ├── linux-x64/         (.so)
│   ├── linux-arm64/       (.so)
│   ├── darwin-x64/        (.dylib)
│   ├── darwin-arm64/      (.dylib)
│   └── win32-x64/         (.dll, .lib)
│
├── nodejs/
│   ├── prebuilts/         ← DISTRIBUIBLE para npm (git tracked)
│   └── prebuilt-binaries/ ← DISTRIBUIBLE para npm (git tracked)
│
└── zig-out/               ← TEMPORAL (gitignored)
    └── (artefactos de compilación)
```

## 🎯 Propósito de Cada Directorio

### `bin/` - Binarios CLI Distribuibles
- **Propósito**: Contiene ejecutables CLI para todas las plataformas
- **Git**: ✅ TRACKED (se distribuye via git)
- **Usuarios**: Pueden descargar y usar directamente desde GitHub
- **Generado por**: `build-all.sh` (copia desde zig-out/bin/)

### `libs/` - Librerías Dinámicas Distribuibles
- **Propósito**: Librerías compartidas (.so, .dll, .dylib)
- **Git**: ✅ TRACKED (se distribuye via git)
- **Usuarios**: Para linking dinámico en proyectos C/C++
- **Generado por**: `build-all.sh` (copia desde zig-out/nodejs/dynamic-libs/)

### `nodejs/prebuilts/` - Librerías Estáticas para npm
- **Propósito**: Archivos .a/.lib para compilar addon Node.js
- **Git**: ✅ TRACKED (necesario para npm)
- **Usuarios npm**: Para compilar desde fuente si no hay .node prebuilt
- **Generado por**: `build-all.sh`

### `nodejs/prebuilt-binaries/` - Addons .node para npm
- **Propósito**: Binarios .node precompilados para Node.js
- **Git**: ✅ TRACKED (necesario para npm)
- **Usuarios npm**: Evita compilación en instalación
- **Generado por**: GitHub Actions

### `zig-out/` - Artefactos Temporales de Build
- **Propósito**: Cache de compilación de Zig
- **Git**: ❌ IGNORED (no se distribuye)
- **Usuarios**: NO acceden a esto
- **Contenido**: Archivos temporales, NO usar para distribución

## 🚨 REGLAS CRÍTICAS

### ❌ NUNCA HACER:
1. NO usar `zig-out/` para distribución
2. NO agregar `bin/` o `libs/` a .gitignore
3. NO referenciar `zig-out/` en documentación de usuario
4. NO copiar manualmente de zig-out/ a bin/ (usar build-all.sh)

### ✅ SIEMPRE HACER:
1. Compilar usando `./build-all.sh`
2. Los binarios finales están en `bin/` y `libs/`
3. Commit y push de `bin/` y `libs/` después de compilar
4. Verificar que archivos estén en git: `git ls-tree -r HEAD | grep "bin/\|libs/"`

## 🔄 Flujo de Compilación

```
1. build-all.sh ejecuta zig build cross-*
   ↓
2. Zig compila a zig-out/bin/ y zig-out/nodejs/
   ↓
3. build-all.sh COPIA a bin/ y libs/
   ↓
4. Usuario hace git add bin/ libs/
   ↓
5. Usuario hace git push
   ↓
6. GitHub distribuye bin/ y libs/ a usuarios
```

## 📝 Comandos Útiles

```bash
# Compilar todo
./build-all.sh

# Verificar qué se distribuye
git ls-tree -r HEAD | grep "^100" | grep -E "bin/|libs/"

# Ver tamaños
du -sh bin/ libs/ zig-out/

# Limpiar temporal (seguro)
rm -rf zig-out/

# ⚠️ NUNCA hacer esto:
# rm -rf bin/  # ❌ Elimina archivos distribuibles
# rm -rf libs/ # ❌ Elimina archivos distribuibles
```

## 🐛 Troubleshooting

**Problema**: "Los binarios no se suben a git"
- Solución: Verificar que .gitignore NO contenga `bin/` o `libs/`

**Problema**: "build-all.sh pone todo en zig-out/"
- Respuesta: ESO ES CORRECTO. El script COPIA de zig-out/ a bin/libs/
- Los archivos finales están en bin/ y libs/, no en zig-out/

**Problema**: "zig-out/ tiene copias de los binarios"
- Respuesta: Normal, son temporales. Puedes borrar zig-out/ sin problema
- Los distribuibles están en bin/ y libs/

---

**Última actualización**: 2025-12-18
**Documentado por**: Claude Code
**Razón**: Evitar confusión sobre zig-out/ vs bin/libs/
