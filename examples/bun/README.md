# zig-pug + Bun.js Examples

Ejemplos de uso de zig-pug con [Bun.js](https://bun.sh/), el runtime de JavaScript ultrarrápido.

## ¿Por qué Bun?

Bun es **2-5x más rápido** que Node.js para la mayoría de operaciones:

- ✅ **Compatible con N-API** - El addon de zig-pug funciona sin cambios
- ⚡ **Ultra rápido** - Startup instantáneo, ejecución optimizada
- 🔋 **Baterías incluidas** - Bundler, test runner, package manager
- 🔌 **Drop-in replacement** - Usa `bun` en lugar de `node`

## Requisitos

### Instalación de Bun

```bash
# Linux/macOS
curl -fsSL https://bun.sh/install | bash

# Windows (WSL)
curl -fsSL https://bun.sh/install | bash

# Verificar instalación
bun --version
```

### Compilar el Addon de zig-pug

```bash
cd nodejs
npm install
npm run build
# o con Bun:
bun install
bun run build
```

## Ejemplos

### 01-basic.js - Uso Básico

Introducción a zig-pug con Bun, incluyendo benchmark simple.

```bash
bun run 01-basic.js
```

**Contenido:**
- Importar zig-pug en Bun
- Compilar un template simple
- Benchmark de rendimiento con `Bun.nanoseconds()`

**Output esperado:**
```
=== zig-pug con Bun.js ===

Bun version: 1.x.x
zig-pug version: 0.2.0

HTML generado:
<div class="greeting"><h1>Hello from Bun!</h1>...

=== Performance ===
10000 compilaciones en 45.23ms
0.0045ms por operación
~221000 ops/sec
```

---

### 02-interpolation.js - Expresiones JavaScript

Demuestra interpolaciones JavaScript complejas.

```bash
bun run 02-interpolation.js
```

**Contenido:**
- Métodos de strings: `toUpperCase()`, `toLowerCase()`
- Operadores aritméticos: `age + 1`
- Operador ternario: `age >= 18 ? 'Adulto' : 'Menor'`
- Math functions: `Math.max()`, `Math.random()`
- Objetos anidados: `user.location.city`
- Arrays: `skills[0]`, `skills.length`

**Ejemplo de template:**
```pug
div.user
  h1 #{firstName} #{lastName}
  p Email: #{email.toLowerCase()}
  p Edad: #{age}
  p El próximo año: #{age + 1}
  p Status: #{age >= 18 ? 'Adulto' : 'Menor'}
```

---

### 03-compiler-class.js - API Orientada a Objetos

Usa la clase `PugCompiler` para reutilizar el contexto de compilación.

```bash
bun run 03-compiler-class.js
```

**Contenido:**
- Crear instancia de `PugCompiler`
- Establecer variables con `.set()` y `.setBool()`
- Reutilizar el compilador para múltiples templates
- Benchmark: `PugCompiler` vs `compile()`

**Ventajas de PugCompiler:**
- ✅ Reutilizar variables entre compilaciones
- ✅ Más eficiente para múltiples templates
- ✅ API chainable: `compiler.set('a', 1).set('b', 2)`

**Ejemplo:**
```javascript
const { PugCompiler } = require('../../nodejs');

const compiler = new PugCompiler();
compiler
    .set('title', 'Mi Página')
    .set('version', 1.5)
    .setBool('isProduction', true);

const html = compiler.compile(template);
```

---

### 04-bun-server.js - HTTP Server

Servidor HTTP completo usando `Bun.serve()` y zig-pug.

```bash
bun run 04-bun-server.js
```

Luego visita: http://localhost:3000

**Contenido:**
- Servidor HTTP con `Bun.serve()`
- Múltiples rutas (/, /about, /user/:name)
- Compilación de templates en tiempo real
- API JSON endpoint
- Contador de requests

**Endpoints:**
- `/` - Página principal con stats
- `/about` - Información del proyecto
- `/user/alice` - Perfil de usuario dinámico
- `/api/stats` - JSON con estadísticas

**Ventajas de Bun.serve():**
- ⚡ Más rápido que Express/Fastify
- 🔥 Hot reload incorporado
- 📦 Sin dependencias extras

---

### 05-file-compilation.js - Compilación desde Archivos

Leer templates desde archivos `.pug` y compilarlos.

```bash
bun run 05-file-compilation.js
```

**Contenido:**
- Leer archivos `.pug` con `fs.readFileSync()`
- Compilar múltiples archivos en batch
- Guardar HTML compilado en disco
- Watch mode (detectar cambios y recompilar)

**Casos de uso:**
- Build tool personalizado
- Static site generator
- Pre-compilar templates para producción

**Ejemplo:**
```javascript
function compileFile(templatePath, data = {}) {
    const template = fs.readFileSync(templatePath, 'utf-8');
    return zigpug.compile(template, data);
}

const html = compileFile('./views/index.pug', {
    title: 'Home',
    user: { name: 'Alice' }
});
```

---

## Benchmark: Bun vs Node.js

Ejecutar el mismo código en ambos runtimes:

```bash
# Con Node.js
cd nodejs
node ../examples/bun/01-basic.js

# Con Bun
bun run examples/bun/01-basic.js
```

### Resultados Esperados

**Node.js v20:**
- 10,000 compilaciones: ~80-100ms
- ~100-125k ops/sec

**Bun v1.x:**
- 10,000 compilaciones: ~40-50ms
- ~200-250k ops/sec

**Winner:** Bun es **2x más rápido** 🏆

## Performance Tips

### 1. Reutilizar PugCompiler

```javascript
// ❌ Lento: crear nuevo contexto cada vez
for (let i = 0; i < 1000; i++) {
    zigpug.compile(template, { name: 'Alice' });
}

// ✅ Rápido: reutilizar compilador
const compiler = new PugCompiler();
compiler.set('name', 'Alice');
for (let i = 0; i < 1000; i++) {
    compiler.compile(template);
}
```

### 2. Pre-compilar Templates

```javascript
// ❌ Lento: leer del disco en cada request
app.get('/', (req, res) => {
    const template = fs.readFileSync('./views/home.pug', 'utf-8');
    const html = zigpug.compile(template, data);
    res.send(html);
});

// ✅ Rápido: cargar una vez al inicio
const homeTemplate = fs.readFileSync('./views/home.pug', 'utf-8');
app.get('/', (req, res) => {
    const html = zigpug.compile(homeTemplate, data);
    res.send(html);
});
```

### 3. Usar Bun en Producción

```javascript
// package.json
{
  "scripts": {
    "dev": "bun run server.js",
    "start": "bun run server.js"
  }
}
```

Bun consume menos memoria y arranca más rápido que Node.js.

## Integración con Frameworks

### Bun + Express

```javascript
const express = require('express');
const zigpug = require('./nodejs');
const app = express();

app.get('/', (req, res) => {
    const html = zigpug.compile(template, data);
    res.send(html);
});

// Correr con Bun
app.listen(3000);
```

```bash
bun run server.js
```

### Bun.serve() (Nativo)

```javascript
const zigpug = require('./nodejs');

Bun.serve({
    port: 3000,
    fetch(req) {
        const html = zigpug.compile(template, data);
        return new Response(html, {
            headers: { 'Content-Type': 'text/html' }
        });
    }
});
```

**Recomendación:** Usa `Bun.serve()` para máximo rendimiento.

## API Reference

### compile(template, data)

Compilar un template con datos.

```javascript
const zigpug = require('./nodejs');

const html = zigpug.compile(
    'p Hello #{name}!',
    { name: 'World' }
);
```

### PugCompiler

Compilador reutilizable con estado.

```javascript
const { PugCompiler } = require('./nodejs');

const compiler = new PugCompiler();
compiler.set('key', 'value');     // String/Number
compiler.setBool('flag', true);   // Boolean

const html = compiler.compile(template);
```

**Métodos:**
- `set(key, value)` - Establecer string o number
- `setBool(key, value)` - Establecer boolean
- `compile(template)` - Compilar template

### version()

Obtener la versión de zig-pug.

```javascript
const zigpug = require('./nodejs');
console.log(zigpug.version()); // "0.2.0"
```

## Sintaxis Pug Soportada

Ver documentación completa en [docs/PUG-SYNTAX.md](../../docs/PUG-SYNTAX.md)

**Features principales:**
- ✅ Tags: `div`, `p`, `h1`, etc.
- ✅ Clases e IDs: `div.class#id`
- ✅ Atributos: `a(href="/" target="_blank")`
- ✅ Interpolación: `#{variable}`, `#{obj.prop}`, `#{arr[0]}`
- ✅ Expresiones JS: `#{age + 1}`, `#{name.toUpperCase()}`
- ✅ Condicionales: `if`, `else`, `unless`
- ✅ Mixins: `mixin button(text)`, `+button('Click')`
- ✅ Doctype: `doctype html`

**JavaScript soportado (ES5.1):**
- String methods: `toLowerCase()`, `toUpperCase()`, `split()`, etc.
- Math: `Math.max()`, `Math.random()`, etc.
- Operators: `+`, `-`, `*`, `/`, `%`, `&&`, `||`, `?:`
- Object/Array access: `obj.prop`, `arr[0]`, `arr.length`

## Troubleshooting

### Error: Cannot find module

```
Error: Cannot find module '../../nodejs'
```

**Solución:** Compilar el addon primero:
```bash
cd nodejs
bun install
bun run build
```

### Error: dlopen failed

En Termux/Android, el addon no se puede cargar. Ver [docs/TERMUX.md](../../docs/TERMUX.md).

**Solución:** Usa el CLI binario en Termux:
```bash
zig build
./zig-out/bin/zig-pug template.pug
```

### Bun no está instalado

```bash
# Instalar Bun
curl -fsSL https://bun.sh/install | bash

# Recargar shell
source ~/.bashrc  # o ~/.zshrc
```

## Recursos

- **Documentación zig-pug**: [README.md](../../README.md)
- **Node.js Integration**: [docs/NODEJS-INTEGRATION.md](../../docs/NODEJS-INTEGRATION.md)
- **Pug Syntax**: [docs/PUG-SYNTAX.md](../../docs/PUG-SYNTAX.md)
- **Bun Documentation**: https://bun.sh/docs
- **N-API Reference**: https://nodejs.org/api/n-api.html

## Siguientes Pasos

1. **Probar los ejemplos** - Ejecuta cada ejemplo para ver zig-pug en acción
2. **Crear tu propio servidor** - Usa `04-bun-server.js` como base
3. **Migrar de Pug.js** - zig-pug es compatible con la mayoría de sintaxis Pug
4. **Contribuir** - Reporta bugs o sugiere features en GitHub

---

**¡Disfruta de la velocidad de Bun + zig-pug!** ⚡
