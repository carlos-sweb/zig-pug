[English](README.md) | Español

# zig-pug

Un motor de templates inspirado en [Pug](https://pugjs.org/), implementado en Zig con soporte completo de JavaScript.

```zpug
doctype html
html(lang="es")
  head
    title #{pageTitle.toUpperCase()}
  body
    h1.greeting Hello #{name}!
    p Age next year: #{age + 1}
    if isActive
      p.status ✓ Usuario activo
```

## 🎯 Características

- ✅ **Sintaxis Pug completa** - Tags, atributos, clases, IDs
- ✅ **JavaScript ES5.1** - Interpolaciones con métodos, operadores y expresiones
- ✅ **Motor JavaScript real** - Powered by [mujs](https://mujs.com/)
- ✅ **Condicionales** - if/else/unless
- ✅ **Mixins** - Componentes reutilizables
- ✅ **Node.js addon** - Integración nativa via N-API
- ✅ **Bun.js compatible** - 2-5x más rápido que Node.js
- ✅ **Editor support** - VS Code, Sublime Text, CodeMirror
- ✅ **Sin dependencias** - Solo Zig 0.15.2 y mujs embebido
- ⚡ **Rápido** - Compilación nativa en Zig
- 🔧 **Funciona en Termux/Android** (CLI binario)

> **Nota para Termux**: El CLI binario funciona perfectamente. El addon de Node.js compila pero no se puede cargar debido a restricciones de Android. Ver [docs/TERMUX.md](docs/es/TERMUX.md) para detalles.

## 📦 Instalación

### Requisitos

- **Zig 0.15.2** ([descargar](https://ziglang.org/download/))

### Clonar y compilar

```bash
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
zig build
```

### Ejecutar

```bash
# Ejecutar el binario compilado
./zig-out/bin/zpug
```

### CLI - Línea de Comandos

zig-pug incluye una interfaz de línea de comandos para compilar templates:

```bash
# Compilar archivo a stdout
zpug template.zpug

# Compilar con archivo de salida
zpug -i template.zpug -o output.html

# Con variables
zpug template.zpug --var name=Alice --var age=25

# Modo desarrollo (con comentarios e indentación)
zpug -p template.zpug -o dev.html

# Modo legible (indentación sin comentarios)
zpug -F template.zpug -o readable.html

# Modo producción (minificado)
zpug -m template.zpug -o minified.html

# Por defecto (producción: sin comentarios, minificado)
zpug template.zpug -o output.html
```

**Nota**: Existen dos versiones del CLI:
- **Simple** (`src/main.zig`) - Funciona en Termux/Android, menos opciones
- **Completo** (`src/cli.zig`) - Requiere libc, todas las opciones (--var, --pretty, --format, --minify, etc.)

📖 **[Ver documentación completa del CLI](docs/es/CLI.md)**

### Editor Support

zig-pug usa la extensión **`.zpug`** para sus archivos de template, con soporte completo en los principales editores:

**Visual Studio Code:**
```bash
cd editor-support/vscode
code --install-extension zig-pug-0.2.0.vsix
```

**Sublime Text 3/4:**
- Copia los archivos de `editor-support/sublime-text/` a tu carpeta de Packages
- Reinicia Sublime Text

**CodeMirror (para editores web):**
```javascript
var editor = CodeMirror.fromTextArea(textarea, {
  mode: 'zpug',
  theme: 'monokai'
});
```

Todas las extensiones incluyen:
- ✅ Syntax highlighting completo
- ✅ Snippets para patrones comunes
- ✅ Auto-completado
- ✅ Indentación inteligente

📖 **[Ver documentación completa de editores](editor-support/README.md)**

### Uso en Node.js

zig-pug también está disponible como addon nativo para Node.js:

```bash
cd nodejs
npm install
npm run build
```

**Ejemplo de uso:**
```javascript
const zigpug = require('./nodejs');

const html = zigpug.compile('p Hello #{name}!', { name: 'World' });
console.log(html);
// <p>Hello World!</p>
```

**API orientada a objetos:**
```javascript
const { PugCompiler } = require('./nodejs');

const compiler = new PugCompiler();
compiler
    .set('title', 'My Page')
    .set('version', 1.5)
    .setBool('isDev', false);

const html = compiler.compile('title #{title}');
```

**Integración con Express.js:**
```javascript
const express = require('express');
const zigpug = require('./nodejs');

app.engine('zpug', createZigPugEngine());
app.set('view engine', 'zpug');

app.get('/', (req, res) => {
    res.render('index', { title: 'Home' });
});
```

📖 **[Ver documentación completa de Node.js](docs/es/NODEJS-INTEGRATION.md)**

## 🚀 Inicio Rápido

### Ejemplo 1: Template Básico

**template.zpug:**
```zpug
div.container
  h1 Hello #{name}!
  p You are #{age} years old
```

**Uso en Zig:**
```zig
const std = @import("std");
const parser = @import("parser.zig");
const compiler = @import("compiler.zig");
const runtime = @import("runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Crear runtime JavaScript
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Establecer variables
    try js_runtime.setString("name", "Alice");
    try js_runtime.setNumber("age", 25);

    // Parsear template
    const source =
        \\div.container
        \\  h1 Hello #{name}!
        \\  p You are #{age} years old
    ;

    var pars = try parser.Parser.init(allocator, source);
    defer pars.deinit();
    const tree = try pars.parse();

    // Compilar a HTML
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(tree);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

**Output:**
```html
<div class="container"><h1>HelloAlice!</h1><p>You are25years old</p></div>
```

## 📚 Sintaxis Pug Soportada

### Tags y Atributos

```zpug
// Tags simples
div
p Hello
span World

// Clases e IDs
div.container
p#main-text
button.btn.btn-primary#submit

// Atributos
a(href="https://example.com" target="_blank") Link
input(type="text" name="username" required)
img(src="photo.jpg" alt="Foto")

// Múltiples líneas
div(
  class="card"
  id="user-card"
  data-user-id="123"
)
```

### Interpolación JavaScript

```zpug
// Variables simples
p Hello #{name}

// Métodos de strings
p #{name.toUpperCase()}
p #{email.toLowerCase()}

// Aritmética
p Age: #{age}
p Next year: #{age + 1}
p Double: #{age * 2}

// Objetos
p Name: #{user.firstName} #{user.lastName}
p Email: #{user.email.toLowerCase()}

// Arrays
p First item: #{items[0]}
p Count: #{items.length}

// Expresiones complejas
p Full name: #{firstName + ' ' + lastName}
p Status: #{age >= 18 ? 'Adult' : 'Minor'}

// Math
p Max: #{Math.max(10, 20)}
p Random: #{Math.floor(Math.random() * 100)}

// JSON
p Data: #{JSON.stringify(obj)}
```

### Escapado HTML (Seguridad XSS)

Por defecto, todas las interpolaciones `#{}` escapan caracteres HTML para prevenir ataques XSS:

```zpug
// Escapado automático (seguro)
p #{userInput}
// Input: <script>alert('xss')</script>
// Output: <p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>

// Sin escapar (para HTML confiable)
p !{trustedHtml}
// Input: <strong>Bold</strong>
// Output: <p><strong>Bold</strong></p>
```

**Caracteres escapados:**
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&#39;`

**Importante:** Solo usa `!{}` con contenido HTML que controlas. Nunca uses `!{}` con input de usuarios.

### Condicionales

```zpug
// if/else
if isLoggedIn
  p Welcome back!
else
  p Please log in

// unless (negación)
unless isAdmin
  p Access denied

// Expresiones
if age >= 18
  p You can vote
else if age >= 16
  p Almost there
else
  p Too young
```

### Mixins

```zpug
// Definir mixin
mixin button(text)
  button.btn= text

// Usar mixin
+button('Click me')
+button('Submit')

// Mixin con atributos
mixin card(title, content)
  div.card
    h3= title
    p= content

+card('Hello', 'This is a card')
```

### Herencia de Plantillas (Extends/Block)

Crea layouts reutilizables con herencia de plantillas usando `extends` y `block`:

```zpug
// layout.zpug - Layout base
doctype html
html
  head
    title
      block title
        | Título por Defecto
  body
    header
      h1 Mi Sitio Web
    main
      block content
        p Contenido por defecto
    footer
      block footer
        p © 2024

// page.zpug - Extiende el layout
extends layout.zpug

block title
  | Página de Inicio

block content
  h2 Bienvenido
  p Este contenido reemplaza el bloque por defecto

// Salida:
// <!DOCTYPE html>
// <html>
//   <head><title>Página de Inicio</title></head>
//   <body>
//     <header><h1>Mi Sitio Web</h1></header>
//     <main>
//       <h2>Bienvenido</h2>
//       <p>Este contenido reemplaza el bloque por defecto</p>
//     </main>
//     <footer><p>© 2024</p></footer>
//   </body>
// </html>
```

**Modos de Bloque:**

```zpug
// Replace (por defecto) - Reemplaza completamente el bloque padre
block content
  p Nuevo contenido

// Append - Agrega después del bloque padre
block append content
  p Agregado después del contenido por defecto

// Prepend - Agrega antes del bloque padre
block prepend content
  p Agregado antes del contenido por defecto
```

**Sintaxis de Rutas:**

```zpug
// Rutas sin comillas (recomendado)
extends layout.zpug
extends ../layouts/base.zpug

// Rutas con comillas
extends "layout.zpug"
extends "../layouts/base.zpug"
```

**Ver [examples/extends/](examples/extends/) para ejemplos completos y funcionales.**

## 🔧 API de Programación

### Runtime JavaScript

```zig
const runtime = @import("runtime.zig");

// Inicializar
var js_runtime = try runtime.JsRuntime.init(allocator);
defer js_runtime.deinit();

// Establecer variables
try js_runtime.setString("name", "Alice");
try js_runtime.setNumber("age", 25);
try js_runtime.setBool("active", true);
try js_runtime.setInt("count", 42);

// Evaluar expresiones
const result = try js_runtime.eval("name.toUpperCase()");
defer allocator.free(result);
// result = "ALICE"

// Crear objetos en JavaScript
_ = try js_runtime.eval("var user = {name: 'Bob', age: 30}");
const name = try js_runtime.eval("user.name");
defer allocator.free(name);
// name = "Bob"
```

### Parser

```zig
const parser = @import("parser.zig");

// Crear parser
var pars = try parser.Parser.init(allocator, source_code);
defer pars.deinit();

// Parsear
const ast_tree = try pars.parse();
// ast_tree es el árbol AST
```

### Compiler

```zig
const compiler = @import("compiler.zig");

// Crear compiler
var comp = try compiler.Compiler.init(allocator, js_runtime);
defer comp.deinit();

// Compilar AST a HTML
const html = try comp.compile(ast_tree);
defer allocator.free(html);
```

## 📖 Documentación Completa

- **[GETTING-STARTED.md](docs/es/GETTING-STARTED.md)** - Guía de inicio paso a paso
- **[CLI.md](docs/es/CLI.md)** - Interfaz de línea de comandos
- **[LOOPS-INCLUDES-CACHE.md](docs/es/LOOPS-INCLUDES-CACHE.md)** - Loops, includes y cache
- **[ZIG-PACKAGE.md](docs/es/ZIG-PACKAGE.md)** - Uso como dependencia de Zig
- **[NODEJS-INTEGRATION.md](docs/es/NODEJS-INTEGRATION.md)** - Integración con Node.js (N-API)
- **[TERMUX.md](docs/es/TERMUX.md)** - Compilación en Termux/Android
- **[PUG-SYNTAX.md](docs/es/PUG-SYNTAX.md)** - Referencia completa de sintaxis Pug
- **[API-REFERENCE.md](docs/es/API-REFERENCE.md)** - Documentación de la API
- **[EXAMPLES.md](docs/es/EXAMPLES.md)** - Ejemplos prácticos

## 🎨 Ejemplos

### Templates Pug

Ver carpeta [examples/](examples/) para ejemplos de templates:

- `examples/basic.zpug` - Tags y atributos básicos
- `examples/interpolation.zpug` - Interpolación de JavaScript
- `examples/conditionals.zpug` - Condicionales y lógica
- `examples/mixins.zpug` - Componentes reutilizables
- `examples/loops.zpug` - Iteración con each/for
- `examples/includes.zpug` - Includes con partials

### Ejemplos Node.js

Ver carpeta [examples/nodejs/](examples/nodejs/) para ejemplos de uso en Node.js:

- `01-basic.js` - Uso básico con `compile()`
- `02-interpolation.js` - Expresiones JavaScript
- `03-compiler-class.js` - API orientada a objetos
- `04-file-compilation.js` - Compilación desde archivos
- `05-express-integration.js` - Integración con Express.js

## 🧪 Testing

```bash
# Ejecutar todos los tests
zig build test

# Ver resultados detallados
zig build test --summary all
```

**Estado de tests**: ✅ Todos pasando (13 tests)

## 🏗️ Arquitectura

```
┌─────────────┐
│   Source    │  Template zpug
│  (*.zpug)   │
└──────┬──────┘
       │
       ▼
┌─────────────┐
│  Tokenizer  │  Análisis léxico
└──────┬──────┘
       │
       ▼
┌─────────────┐
│   Parser    │  Análisis sintáctico
└──────┬──────┘
       │
       ▼
┌─────────────┐
│     AST     │  Árbol de sintaxis abstracta
└──────┬──────┘
       │
       ▼
┌─────────────┐       ┌─────────────┐
│  Compiler   │◄──────┤  JS Runtime │
└──────┬──────┘       │    (mujs)   │
       │              └─────────────┘
       ▼
┌─────────────┐
│    HTML     │  Output final
└─────────────┘
```

## ⚙️ Motor JavaScript

zig-pug usa [**mujs**](https://mujs.com/) como motor JavaScript:

- **Versión**: mujs 1.3.8
- **Estándar**: ES5.1 compliant
- **Tamaño**: 590 KB
- **Dependencias**: Ninguna (solo libm)
- **Usado por**: MuPDF, Ghostscript

### JavaScript Soportado (ES5.1)

✅ **Soportado:**
- String methods: `toLowerCase()`, `toUpperCase()`, `substr()`, `split()`, etc.
- Number methods: `toFixed()`, `toPrecision()`
- Array methods: `map()`, `filter()`, `reduce()`, `forEach()`, etc.
- Object property access
- Operadores aritméticos: `+`, `-`, `*`, `/`, `%`
- Operadores de comparación: `>`, `<`, `>=`, `<=`, `==`, `===`
- Operadores lógicos: `&&`, `||`, `!`
- Operador ternario: `condition ? true : false`
- Math: `Math.max()`, `Math.min()`, `Math.round()`, etc.
- JSON: `JSON.parse()`, `JSON.stringify()`

❌ **No soportado** (ES6+):
- Arrow functions: `() => {}`
- Template literals: `` `text ${var}` ``
- let/const (usar `var`)
- Async/await
- Clases (class keyword)
- Módulos ES6

**Para templates Pug, ES5.1 es completamente suficiente.**

## 📊 Estado del Proyecto

### ✅ Completado

- [x] Tokenizer (análisis léxico)
- [x] Parser (análisis sintáctico)
- [x] AST (árbol de sintaxis)
- [x] Compiler (generación HTML)
- [x] Runtime JavaScript (mujs)
- [x] Tags y atributos
- [x] Clases e IDs
- [x] Interpolación JavaScript
- [x] Condicionales (if/else/unless)
- [x] Mixins
- [x] Tests

### 🚧 En Desarrollo

- [x] Loops (each/for)
- [x] Includes
- [x] Cache de templates
- [x] Template inheritance (extends/block)
- [x] Escapado HTML (XSS prevention)
- [x] Pretty printing (indentación HTML)
- [x] Manejo de comentarios (producción vs desarrollo)
- [ ] CLI completo
- [ ] Modo watch (`-w`)

### 📋 Roadmap

Ver [PLAN.md](PLAN.md) para el plan completo de desarrollo.

## 💬 Propuestas (RFC)

Las siguientes características están en evaluación. Tu feedback es bienvenido en [GitHub Discussions](https://github.com/carlos-sweb/zig-pug/discussions).

### RFC-001: Filtros de Valor

**Estado:** En evaluación

**Propuesta:** Agregar filtros para transformar valores en interpolaciones usando sintaxis pipe.

```zpug
p #{name | uppercase}
p #{price | default(0)}
p #{bio | truncate(50)}
p #{tags | join(', ')}
```

**Filtros propuestos:**
- `uppercase`, `lowercase`, `capitalize` - Transformación de texto
- `truncate(n)` - Cortar texto a n caracteres
- `default(val)` - Valor por defecto si undefined/null
- `escape` - Escapar HTML
- `json` - Convertir a JSON string
- `length`, `first`, `last` - Operaciones de arrays
- `join(sep)`, `reverse`, `sort` - Manipulación de arrays

**A favor:**
- Mejora expresividad de templates
- Se implementa con mujs (sin dependencias nuevas)
- Común en otros motores (Jinja2, Twig, Liquid)

**En contra:**
- JavaScript ya tiene métodos: `name.toUpperCase()`, `arr.join(',')`
- Agrega complejidad al parser
- Sintaxis adicional que aprender
- Filosofía minimalista de zig-pug

**Alternativa actual:**
```zpug
// En lugar de filtros, usar métodos JavaScript directamente
p #{name.toUpperCase()}
p #{price || 0}
p #{bio.substr(0, 50)}
p #{tags.join(', ')}
```

**¿Qué opinas?** Abre un issue o discussion con tu caso de uso.

---

## 🤝 Contribuir

¡Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea una rama para tu feature (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add some AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## 📄 Licencia

MIT License - ver [LICENSE](LICENSE) para detalles

## 🙏 Agradecimientos

- [Pug](https://pugjs.org/) - Inspiración original
- [Zig](https://ziglang.org/) - Lenguaje de programación
- [mujs](https://mujs.com/) - Motor JavaScript embebido
- [Artifex Software](https://artifex.com/) - Creadores de mujs

## 📞 Soporte

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)
- **Discussions**: [GitHub Discussions](https://github.com/carlos-sweb/zig-pug/discussions)

---

**Hecho con ❤️ usando Zig 0.15.2 y mujs**
