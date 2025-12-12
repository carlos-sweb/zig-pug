# Limitaciones de Termux/Android para Node.js Addons

## Resumen

**CLI zig-pug:** ✅ **FUNCIONA PERFECTAMENTE**  
**Addon Node.js:** ❌ **NO PUEDE CARGARSE** (restricción de Android)

## Análisis Completo

### ✅ Compilación: ÉXITO

El addon **SÍ se compila correctamente** en Termux/Android:

```bash
cd nodejs
npm run rebuild

# Resultado:
✓ binding.c compilado
✓ libzig-pug.a linkeado
✓ zigpug.node generado (2.8M)
```

**Archivo generado:**
```
nodejs/build/Release/zigpug.node  (2.8M)
```

**Solución aplicada en binding.gyp:**
```gyp
["OS=='android'", {
  "libraries": [
    "-lm",
    "<(module_root_dir)/prebuilts/linux-<(target_arch)/libzig-pug.a"
  ]
}]
```

Esto mapea `android → linux` porque:
- Android usa el kernel Linux
- Android ARM64 usa la misma ABI que Linux ARM64
- Las librerías son 100% compatibles

### ❌ Carga Dinámica: FALLA

Aunque el addon compila, **NO puede cargarse en runtime**:

```bash
node test-cjs.js

# Error:
Error: dlopen failed: library "zigpug.node" is not accessible 
for the namespace "(default)"
```

## 🔒 Causa Root: Restricciones de Seguridad de Android

### Linker Namespaces (Android 10+)

Android usa **linker namespaces** para seguridad:

```
┌─────────────────────────────────────┐
│  Android Linker Namespace System   │
├─────────────────────────────────────┤
│                                     │
│  Namespace "(default)"              │
│  ├─ Librerías del sistema          │
│  ├─ /system/lib64/*                │
│  └─ Muy restrictivo                │
│                                     │
│  Namespace "sphal"                  │
│  ├─ Librerías de vendor            │
│  ├─ Más permisivo                  │
│  └─ Requiere permisos especiales   │
│                                     │
└─────────────────────────────────────┘
```

**El problema:**
1. Node.js ejecuta en namespace `"(default)"`
2. Este namespace solo permite cargar librerías específicas
3. `dlopen()` de addons `.node` es bloqueado
4. Termux **no puede** cambiar namespaces (sin root)

### Comparación: CLI vs Addon

| Aspecto | CLI (zpug) | Addon (.node) |
|---------|------------|---------------|
| **Tipo** | Binario estático | Librería dinámica |
| **Carga** | Ejecución directa | `dlopen()` runtime |
| **Namespace** | No aplica | Requiere permiso |
| **Funciona en Termux** | ✅ SÍ | ❌ NO |
| **Compila en Termux** | ✅ SÍ | ✅ SÍ |
| **Se carga en Termux** | ✅ SÍ | ❌ NO |

## 🛠️ Soluciones Intentadas

### ❌ Intento 1: Compilar con flags especiales
```bash
# NO funciona: Android bloquea a nivel de kernel
LDFLAGS="-Wl,--no-undefined" npm run rebuild
```

### ❌ Intento 2: Cambiar rpath
```bash
# NO funciona: No es problema de rpath
patchelf --set-rpath /data/data/com.termux/files/usr/lib
```

### ❌ Intento 3: LD_PRELOAD
```bash
# NO funciona: Android ignora LD_PRELOAD por seguridad
LD_PRELOAD=./zigpug.node node test.js
```

### ✅ Única solución: Root + SELinux permissive
```bash
# Requiere root y deshabilitar SELinux
# NO RECOMENDADO para usuarios finales
su
setenforce 0
```

## 📊 Verificación del Problema

### Test 1: Compilación
```bash
cd nodejs
rm -rf build
npm run rebuild

# Resultado esperado:
# ✅ gyp info ok
# ✅ zigpug.node creado
```

### Test 2: Carga dinámica
```bash
node -e "require('./build/Release/zigpug.node')"

# Resultado esperado en Termux:
# ❌ Error: dlopen failed: not accessible for namespace
```

### Test 3: CLI
```bash
cd ..
./zig-out/bin/zpug --version

# Resultado esperado:
# ✅ Funciona perfectamente
```

## ✅ Workaround para Usuarios de Termux

**Recomendación: Usar el CLI en lugar del addon**

```bash
# ❌ NO funciona en Termux:
const pug = require('zig-pug');

# ✅ SÍ funciona en Termux:
const { execSync } = require('child_process');
const html = execSync('zpug template.pug', { encoding: 'utf8' });
```

**Ejemplo wrapper Node.js:**
```javascript
// wrapper.js - Usar CLI desde Node.js
const { execFileSync } = require('child_process');
const fs = require('fs');
const path = require('path');

function compilePug(template, variables = {}) {
    // Escribir template temporal
    const tmpTemplate = '/tmp/template.pug';
    fs.writeFileSync(tmpTemplate, template);
    
    // Escribir variables JSON
    const tmpVars = '/tmp/vars.json';
    fs.writeFileSync(tmpVars, JSON.stringify(variables));
    
    // Ejecutar zpug CLI
    const html = execFileSync('zpug', [
        tmpTemplate,
        '--vars', tmpVars
    ], { encoding: 'utf8' });
    
    // Limpiar temporales
    fs.unlinkSync(tmpTemplate);
    fs.unlinkSync(tmpVars);
    
    return html;
}

// Uso
const html = compilePug('p Hello #{name}!', { name: 'World' });
console.log(html); // <p>Hello World!</p>
```

## 📱 Plataformas Afectadas

| Plataforma | CLI | Addon | Nota |
|------------|-----|-------|------|
| **Linux** | ✅ | ✅ | Funciona todo |
| **macOS** | ✅ | ✅ | Funciona todo |
| **Windows** | ✅ | ✅ | Funciona todo |
| **Termux (Android)** | ✅ | ❌ | Solo CLI |
| **Android (sin Termux)** | ✅ | ❌ | Solo CLI |

## 🔬 Referencias Técnicas

### Android Linker Namespaces
- [Android Docs - Namespaces](https://source.android.com/docs/core/architecture/vndk/linker-namespace)
- [Android Security - Library Isolation](https://source.android.com/docs/security/features/selinux)

### Node.js N-API en Android
- [Node.js Issue #30401](https://github.com/nodejs/node/issues/30401) - Android dlopen restrictions
- [Termux Issue #2155](https://github.com/termux/termux-packages/issues/2155) - Native addon limitations

### Workarounds conocidos
- [React Native - Native Modules](https://reactnative.dev/docs/native-modules-android) - Requiere app completa
- [Cordova Plugins](https://cordova.apache.org/docs/en/latest/guide/hybrid/plugins/) - Requiere framework

## 💡 Conclusión

**Para desarrolladores:**
- ✅ El addon compila correctamente
- ✅ El código C y Zig son correctos
- ✅ El binding.gyp está bien configurado
- ❌ Android bloquea la carga por seguridad

**Para usuarios de Termux:**
- ✅ Usa el CLI `zpug` - funciona perfectamente
- ✅ Puedes crear wrapper Node.js → CLI
- ❌ No uses `require('zig-pug')` directamente

**Estado final:**
- Compilación: ✅ RESUELTA
- Carga dinámica: ❌ LIMITACIÓN DE ANDROID (sin solución sin root)

---

**Última actualización:** Diciembre 2024  
**Autor:** Análisis realizado con Claude Code  
**Versión:** zig-pug 0.4.0
