# Compilación en Termux/Android

Esta guía explica cómo compilar el addon de Node.js de zig-pug en Termux, las limitaciones conocidas, y alternativas recomendadas.

## TL;DR

- ✅ **El addon COMPILA exitosamente** en Termux con el workaround descrito
- ❌ **El addon NO SE PUEDE CARGAR** debido a restricciones de namespace de Android
- ✅ **ALTERNATIVA**: Usa el CLI binario de zig-pug (`zig-pug`) en Termux

## Contexto Técnico

### ¿Por qué es difícil compilar en Termux?

Termux es un entorno Linux que corre en Android usando PRoot, pero:

1. **node-gyp detecta Android**: Automáticamente busca el Android NDK
2. **No hay NDK en Termux**: Solo están disponibles clang, cmake, gcc
3. **Conflictos de libc**: Termux usa musl, Android usa Bionic
4. **Restricciones de namespace**: Android impide cargar .so externos en runtime

## Solución de Compilación (Workaround)

### 1. Archivos de Configuración

#### `nodejs/common.gypi` (Crear)

Este archivo proporciona una variable dummy para evitar que node-gyp busque el NDK:

```json
{
  'variables': {
    'android_ndk_path%': '/tmp',
  }
}
```

#### `nodejs/binding.gyp` (Simplificado)

Configuración mínima sin dependencias problemáticas:

```json
{
  "targets": [
    {
      "target_name": "zigpug",
      "sources": [
        "binding.c"
      ],
      "include_dirs": [
        "../include",
        "../vendor/mujs"
      ],
      "libraries": [
        "<(module_root_dir)/../vendor/mujs/libmujs.a",
        "-lm"
      ],
      "cflags": [
        "-std=c99"
      ],
      "defines": [
        "NAPI_VERSION=8"
      ]
    }
  ]
}
```

**Cambios importantes:**
- Removida la dependencia de `node-addon-api`
- Usado `<(module_root_dir)>` para paths absolutos
- Configuración mínima solo con N-API puro

### 2. Script de Compilación

#### `nodejs/build-termux.sh`

```bash
#!/data/data/com.termux/files/usr/bin/bash
# Script para compilar el addon en Termux
# Engaña a node-gyp para que piense que está en Linux

export npm_config_arch=arm64
export npm_config_platform=linux
export GYPFLAGS="-DOS=linux"

# Ejecutar node-gyp con configuración custom
npx node-gyp configure -- \
  -DOS=linux \
  -Dhost_os=linux \
  -Dtarget_arch=arm64

npx node-gyp build
```

**¿Qué hace este script?**
1. Configura variables de entorno para que npm piense que está en Linux
2. Pasa flags a GYP para forzar detección de OS como Linux
3. Ejecuta configure y build con estos parámetros

### 3. Proceso de Compilación

```bash
cd nodejs

# Instalar dependencias
npm install

# Dar permisos de ejecución
chmod +x build-termux.sh

# Compilar
./build-termux.sh
```

### Resultado Esperado

```
  CXX(target) Release/obj.target/zigpug/binding.o
  SOLINK_MODULE(target) Release/obj.target/zigpug.node
  COPY Release/zigpug.node
```

El addon `zigpug.node` se crea exitosamente en `build/Release/`.

## Limitación: No se Puede Cargar

### El Problema

Aunque la compilación es exitosa, al intentar cargar el addon:

```bash
$ node
> require('./build/Release/zigpug.node')
```

### Error Obtenido

```
Error: dlopen failed: library "/root/zig-pug/nodejs/build/Release/zigpug.node"
needed or dlopened by "/data/data/com.termux/files/usr/bin/node"
is not accessible for the namespace "(default)"
```

### ¿Por Qué Ocurre?

Android implementa **namespace restrictions** por seguridad:

1. **Separación de namespaces**: Las apps de Android tienen namespaces aislados
2. **PRoot no es root real**: Termux corre en PRoot, no tiene acceso root completo
3. **dlopen bloqueado**: Android bloquea cargar .so que no están en el namespace de la app
4. **Node.js en Termux**: Está en el namespace de Termux, el addon está "fuera"

### Análisis de Dependencias (ldd)

```bash
$ ldd build/Release/zigpug.node
```

**Problemas encontrados:**
- `liblog.so: No such file or directory` - Librería específica de Android
- `napi_create_function: symbol not found` - Símbolos N-API no resueltos
- `zigpug_init: symbol not found` - Símbolos de zig-pug no resueltos
- Conflictos musl vs Bionic libc

## Alternativas Recomendadas

### ✅ Opción 1: Usar el CLI Binario (RECOMENDADO)

El CLI de zig-pug funciona perfectamente en Termux:

```bash
# Compilar el CLI
zig build

# Usar directamente
./zig-out/bin/zig-pug template.zpug

# Con variables
./zig-out/bin/zig-pug template.zpug --var name=World --var age=25

# Guardar en archivo
./zig-out/bin/zig-pug -i template.zpug -o output.html
```

**Ventajas:**
- ✅ Funciona perfectamente en Termux
- ✅ Sin dependencias de Node.js
- ✅ Más rápido que el addon
- ✅ Acceso completo a todas las features de zig-pug

### ✅ Opción 2: Desarrollo Remoto

Usa Termux para editar, pero compila/ejecuta en una VM Linux:

```bash
# En Termux: editar código
vim template.zpug

# En Linux/macOS: compilar y probar addon
cd nodejs
npm install
npm run build
node examples/01-basic.js
```

### ✅ Opción 3: Bun.js en Linux/macOS

El addon es compatible con Bun.js, que es mucho más rápido:

```bash
# En Linux/macOS
bun install
bun run examples/bun/01-basic.js
```

**Performance con Bun:**
- 2-5x más rápido que Node.js
- Igual API, mismo código
- Ver `examples/bun/` para ejemplos

### ❌ Opción 4: Intentar Cargar el Addon (NO RECOMENDADO)

Técnicamente podrías intentar:
- Modificar el linker path
- Usar LD_PRELOAD
- Compilar Node.js con configuración especial

**Pero:**
- Muy complejo y frágil
- Requiere conocimientos avanzados de Android internals
- Probablemente no funcione debido a las restricciones de seguridad
- No vale la pena el esfuerzo

## Comparación de Opciones

| Opción | Funciona en Termux | Rendimiento | Complejidad | Acceso a Features |
|--------|-------------------|-------------|-------------|-------------------|
| CLI Binario | ✅ Sí | ⚡⚡⚡ Muy rápido | 🟢 Fácil | ✅ 100% |
| Addon Node.js | ❌ No | ⚡⚡ Rápido | 🔴 No funciona | ❌ 0% |
| Addon Bun.js | ❌ No* | ⚡⚡⚡ Muy rápido | 🔴 No funciona | ❌ 0% |
| Dev Remoto | ✅ Edición | ⚡⚡ Depende | 🟡 Medio | ✅ 100% |

*Bun no está disponible para Android/Termux

## Detalles Técnicos

### Configuración que Funciona

**Variables de entorno:**
```bash
npm_config_arch=arm64
npm_config_platform=linux
GYPFLAGS="-DOS=linux"
```

**Flags de GYP:**
```bash
-DOS=linux
-Dhost_os=linux
-Dtarget_arch=arm64
```

**Shebang correcto para Termux:**
```bash
#!/data/data/com.termux/files/usr/bin/bash
```

### Lo que NO Funciona

**Intentar usar node-addon-api:**
```json
// ❌ NO FUNCIONA en Termux
"include_dirs": [
  "<!@(node -p \"require('node-addon-api').include\")"
]
```

**Paths relativos para librerías:**
```json
// ❌ NO FUNCIONA
"libraries": [
  "../vendor/mujs/libmujs.a"
]

// ✅ SÍ FUNCIONA
"libraries": [
  "<(module_root_dir)/../vendor/mujs/libmujs.a"
]
```

## Conclusión

### Para Usuarios de Termux

**Si estás en Termux:**
1. ✅ Usa el CLI binario (`zig-pug`)
2. ✅ Compila con `zig build`
3. ✅ Disfruta del máximo rendimiento sin complicaciones

**NO intentes usar el addon de Node.js en Termux** - es una pérdida de tiempo debido a las restricciones fundamentales de Android.

### Para Desarrollo en Linux/macOS

**Si estás en Linux o macOS:**
1. ✅ El addon funciona perfectamente
2. ✅ Usa Bun.js para mejor rendimiento
3. ✅ Integra con Express, Fastify, etc.
4. ✅ Ver `docs/NODEJS-INTEGRATION.md`

## Recursos

- **CLI Documentation**: [docs/CLI.md](CLI.md)
- **Node.js Integration**: [docs/NODEJS-INTEGRATION.md](NODEJS-INTEGRATION.md)
- **Bun Examples**: [examples/bun/](../../examples/bun/)
- **Building Guide**: [docs/BUILDING-ADDON.md](../en/BUILDING-ADDON.md)

## Soporte

Si tienes problemas compilando en Termux:
1. Verifica que tienes Zig 0.15.2 instalado
2. Usa el CLI binario en lugar del addon
3. Abre un issue en GitHub si encuentras bugs en el CLI

---

**Resumen**: El addon compila en Termux con el workaround, pero no se puede cargar. **Usa el CLI binario** que funciona perfectamente.
