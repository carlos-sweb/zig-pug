# zig-pug

Un motor de templates inspirado en [Pug](https://pugjs.org/), implementado en Zig con soporte completo de JavaScript.

```pug
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
- ✅ **Sin dependencias** - Solo Zig 0.15.2 y mujs embebido
- ⚡ **Rápido** - Compilación nativa en Zig
- 🔧 **Funciona en Termux/Android**

## 📦 Instalación

### Requisitos

- **Zig 0.15.2** ([descargar](https://ziglang.org/download/))

### Clonar y compilar

```bash
git clone https://github.com/yourusername/zig-pug
cd zig-pug
zig build
```

### Ejecutar

```bash
./zig-out/bin/zig-pug
```

## 🚀 Inicio Rápido

### Ejemplo 1: Template Básico

**template.pug:**
```pug
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

```pug
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

```pug
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

### Condicionales

```pug
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

```pug
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

- **[GETTING-STARTED.md](docs/GETTING-STARTED.md)** - Guía de inicio paso a paso
- **[PUG-SYNTAX.md](docs/PUG-SYNTAX.md)** - Referencia completa de sintaxis Pug
- **[API-REFERENCE.md](docs/API-REFERENCE.md)** - Documentación de la API
- **[EXAMPLES.md](docs/EXAMPLES.md)** - Ejemplos prácticos

### Documentación Técnica

- **[MUJS-INTEGRATION.md](MUJS-INTEGRATION.md)** - Integración del motor JavaScript
- **[MUJS-ANALYSIS.md](MUJS-ANALYSIS.md)** - Análisis mujs vs QuickJS
- **[LIBRARY-USAGE.md](LIBRARY-USAGE.md)** - Usar zig-pug como librería C

## 🎨 Ejemplos

Ver carpeta [examples/](examples/) para más ejemplos:

- `examples/basic.pug` - Tags y atributos básicos
- `examples/interpolation.pug` - Interpolación de JavaScript
- `examples/conditionals.pug` - Condicionales y lógica
- `examples/mixins.pug` - Componentes reutilizables

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
│   Source    │  Template Pug
│  (*.pug)    │
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

- [ ] Loops (each/for)
- [ ] Template inheritance (extends/block)
- [ ] Includes
- [ ] Filtros
- [ ] Pretty printing (indentación HTML)
- [ ] Escapado HTML
- [ ] CLI completo

### 📋 Roadmap

Ver [PLAN.md](PLAN.md) para el plan completo de desarrollo.

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

- **Issues**: [GitHub Issues](https://github.com/yourusername/zig-pug/issues)
- **Discussions**: [GitHub Discussions](https://github.com/yourusername/zig-pug/discussions)

---

**Hecho con ❤️ usando Zig 0.15.2 y mujs**
