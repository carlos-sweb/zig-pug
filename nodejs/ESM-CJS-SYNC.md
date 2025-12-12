# Sincronización ESM y CommonJS

## Problema Detectado

El proyecto tenía **inconsistencias** entre los módulos ESM y CommonJS:

### `index.js` (CommonJS) ✅ COMPLETO
```javascript
// Métodos disponibles:
- setString(key, value)
- setNumber(key, value)  
- setBool(key, value)
- setArray(key, value)     // ✅ PRESENTE
- setObject(key, value)    // ✅ PRESENTE
- set(key, value)          // ✅ Auto-detecta arrays y objects
- setVariables(obj)
- compile(template)
- render(template, vars)
```

### `index.mjs` (ES Modules) ❌ INCOMPLETO (antes)
```javascript
// Métodos disponibles:
- setString(key, value)
- setNumber(key, value)
- setBool(key, value)
- setArray(key, value)     // ❌ FALTABA
- setObject(key, value)    // ❌ FALTABA
- set(key, value)          // ❌ NO detectaba arrays/objects
- setVariables(obj)
- compile(template)
- render(template, vars)
```

## Impacto

Los usuarios que usaban ES Modules (`import`) **NO podían usar arrays ni objects**:

```javascript
// ❌ ESTO NO FUNCIONABA con import
import { PugCompiler } from 'zig-pug';

const compiler = new PugCompiler();
compiler.set('items', ['a', 'b', 'c']); // ❌ Error!
compiler.set('user', { name: 'Alice' }); // ❌ Error!
```

```javascript
// ✅ PERO ESTO SÍ FUNCIONABA con require
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler();
compiler.set('items', ['a', 'b', 'c']); // ✅ OK
compiler.set('user', { name: 'Alice' }); // ✅ OK
```

## Solución

Se sincronizó `index.mjs` con `index.js` agregando:

1. **Método `setArray()`**:
```javascript
setArray(key, value) {
    if (!Array.isArray(value)) {
        throw new TypeError('Value must be an array');
    }
    const success = binding.setArray(this.context, key, value);
    if (!success) {
        throw new Error(`Failed to set array variable: ${key}`);
    }
    return this;
}
```

2. **Método `setObject()`**:
```javascript
setObject(key, value) {
    if (typeof value !== 'object' || value === null || Array.isArray(value)) {
        throw new TypeError('Value must be a plain object');
    }
    const success = binding.setObject(this.context, key, value);
    if (!success) {
        throw new Error(`Failed to set object variable: ${key}`);
    }
    return this;
}
```

3. **Actualización de `set()` con auto-detección**:
```javascript
set(key, value) {
    if (Array.isArray(value)) {
        return this.setArray(key, value);
    } else if (typeof value === 'object' && value !== null) {
        return this.setObject(key, value);
    } else if (typeof value === 'string') {
        return this.setString(key, value);
    } else if (typeof value === 'number') {
        return this.setNumber(key, value);
    } else if (typeof value === 'boolean') {
        return this.setBool(key, value);
    } else {
        throw new TypeError(`Unsupported value type for key "${key}": ${typeof value}`);
    }
}
```

## Resultado

### ✅ Ahora AMBOS módulos tienen la MISMA API completa:

| Característica | CommonJS | ES Modules |
|----------------|----------|------------|
| `setString()` | ✅ | ✅ |
| `setNumber()` | ✅ | ✅ |
| `setBool()` | ✅ | ✅ |
| `setArray()` | ✅ | ✅ |
| `setObject()` | ✅ | ✅ |
| `set()` auto-detect | ✅ | ✅ |
| Arrays support | ✅ | ✅ |
| Objects support | ✅ | ✅ |

## Tests

### CommonJS
```bash
node nodejs/test-cjs.js
```

### ES Modules
```bash
node nodejs/test-esm.mjs
```

Ambos tests ahora prueban:
- ✅ Variables simples (string, number, boolean)
- ✅ Arrays con `setArray()`
- ✅ Objects con `setObject()`
- ✅ Auto-detección con `set()`
- ✅ Función `compile()` con todos los tipos

## Uso

Ahora funciona igual en ambos:

```javascript
// ES Modules
import { PugCompiler } from 'zig-pug';

const compiler = new PugCompiler();
compiler
    .set('title', 'Dashboard')
    .set('count', 42)
    .set('active', true)
    .set('items', ['a', 'b', 'c'])        // ✅ Ahora funciona!
    .set('user', { name: 'Alice' });      // ✅ Ahora funciona!
```

```javascript
// CommonJS
const { PugCompiler } = require('zig-pug');

const compiler = new PugCompiler();
compiler
    .set('title', 'Dashboard')
    .set('count', 42)
    .set('active', true)
    .set('items', ['a', 'b', 'c'])        // ✅ Funcionaba antes
    .set('user', { name: 'Alice' });      // ✅ Funcionaba antes
```

## Verificación

Para verificar que todo funciona:

```bash
# Test CommonJS
cd nodejs
node test-cjs.js

# Test ES Modules
node test-esm.mjs

# Test arrays y objects específicamente
node test-arrays-objects.js
```

Todos los tests deben pasar sin errores.

---

**Fecha de corrección:** Diciembre 2024
**Versión:** 0.4.0
