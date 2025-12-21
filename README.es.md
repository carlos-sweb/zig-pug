[English](README.md) | Español

# zig-pug

Un motor de plantillas de alto rendimiento inspirado en [Pug](https://pugjs.org/), implementado en Zig con soporte completo de JavaScript.

```zpug
doctype html
html(lang="en")
  head
    title #{pageTitle.toUpperCase()}
  body
    h1.greeting Hello #{name}!
    p Age next year: #{age + 1}
    if isActive
      p.status Active user
    each item in items
      li= item
```

## 🎯 Características

- ✅ **Sintaxis Pug completa** - Tags, atributos, clases, IDs, doctype
- ✅ **Soporte UTF-8 completo** - Caracteres acentuados (á, é, ñ, ü), emoji 🎉, todo Unicode
- ✅ **JavaScript ES5.1** - Interpolaciones con métodos, operadores y expresiones
- ✅ **Motor JavaScript real** - Powered by [mujs](https://mujs.com/)
- ✅ **Condicionales** - if/else/else if/unless con expresiones JavaScript completas (>, <, >=, <=, ==, &&, ||)
- ✅ **Loops** - each/while con soporte de arrays
- ✅ **Mixins** - Componentes reutilizables con argumentos
- ✅ **Herencia de plantillas** - extends/block
- ✅ **Variables JSON** - Soporte completo para strings, números, bools, arrays y objetos
- ✅ **Expresiones en atributos** - Valores dinámicos de atributos (`class=myVar`)
- **Código buffered/unbuffered** - Operadores `=`, `!=` y `-`
- ✅ **Comentarios de documentación** - `//!` para metadata de archivos (ignorados por el parser)
- **Node.js addon** - Integración nativa vía N-API
- ✅ **Bun.js compatible** - 2-5x más rápido que Node.js
- ✅ **Soporte de editores** - VS Code, Sublime Text, CodeMirror
- ✅ **Sin dependencias** - Solo Zig 0.15.2 y mujs embebido
- ⚡ **Rápido** - Compilación nativa en Zig con optimizaciones
- **Seguro** - Escapado HTML y prevención XSS
- **Funciona en Termux/Android** (binario CLI)
- **87 tests unitarios** - Cobertura de tests completa

> **Notas de Plataforma:**
> - **Termux/Android**: El binario CLI funciona perfectamente. El addon de Node.js compila pero no se puede cargar debido a restricciones de Android. Ver [docs/en/TERMUX.md](docs/en/TERMUX.md).
> - **Windows**: Binarios pre-compilados temporalmente no disponibles debido a incompatibilidad de toolchains MinGW/MSVC. Los usuarios de Windows pueden:
>   - Compilar localmente con [MinGW-w64/MSYS2](https://www.msys2.org/)
>   - Usar [WSL (Windows Subsystem for Linux)](https://learn.microsoft.com/windows/wsl/install)
>   - Estamos trabajando activamente en una solución. Seguir progreso en [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues).

## 📦 Instalación

### Requisitos

- **Zig 0.15.2** ([descargar](https://ziglang.org/download/))

### Clonar y compilar

```bash
git clone https://github.com/carlos-sweb/zig-pug
cd zig-pug
zig build
```

### Instalar (opcional)

```bash
# Instalar en todo el sistema
make install

# Desinstalar
make uninstall
```

### Ejecutar

```bash
# Ejecutar el binario compilado
./zig-out/bin/zpug template.zpug

# O si está instalado
zpug template.zpug
```

## CLI - Interfaz de Línea de Comandos

zig-pug incluye una poderosa interfaz de línea de comandos:

```bash
# Compilar archivo a stdout
zpug template.zpug

# Compilar con archivo de salida
zpug -i template.zpug -o output.html

# Con variables (simple)
zpug template.zpug --var name=Alice --var age=25

# Con arrays (formato CSV)
zpug template.zpug --array items=apple,banana,orange

# Con JSON (objetos y estructuras complejas)
zpug template.zpug --json user='{"name":"Alice","age":30}'

# Con archivo JSON (arrays, objetos, datos anidados)
zpug template.zpug --vars data.json

# Pretty-print con comentarios (modo desarrollo)
zpug -p template.zpug -o dev.html

# Pretty-print sin comentarios (modo legible)
zpug -F template.zpug -o readable.html

# Minificar salida (modo producción)
zpug -m template.zpug -o minified.html

# Por defecto (producción: sin comentarios, minificado)
zpug template.zpug -o output.html

# Desde stdin
cat template.zpug | zpug --stdin > output.html
```

**Ejemplo con arrays y objetos inline:**
```bash
# Arrays CSV (valores simples)
zpug template.zpug --array fruits=apple,banana,orange --array scores=95,87,92

# Objetos JSON
zpug template.zpug --json user='{"name":"Alice","age":30,"email":"alice@example.com"}'

# Arrays JSON (para datos complejos)
zpug template.zpug --json items='["apple","banana","orange"]'

# Mezclar todos los tipos
zpug template.zpug \
  --var title="Dashboard" \
  --array tags=prod,stable \
  --json user='{"name":"Alice","role":"admin"}' \
  --pretty
```

**Ejemplo de archivo JSON de variables:**
```json
{
  "user": {
    "name": "Alice",
    "age": 30,
    "email": "alice@example.com"
  },
  "items": ["apple", "banana", "orange"],
  "active": true
}
```

**[Ver documentación completa del CLI](docs/es/CLI.md)**

## 🚀 Inicio Rápido

### Ejemplo: Página Completa

**template.zpug:**
```zpug
doctype html
html(lang="en")
  head
    meta(charset="UTF-8")
    title #{pageTitle}
  body
    - var greeting = "Hello"
    h1.main-title= greeting + " " + userName

    if isLoggedIn
      p.status Welcome back, #{userName}!
      ul.menu
        each item in menuItems
          li
            a(href=item.url)= item.title
    else
      p Please log in

    mixin button(text, type)
      button(class=type)= text

    +button("Click me", "btn-primary")
```

**Compilar con:**
```bash
zpug template.zpug --vars data.json -o output.html
```

**Salida:**
```html
<!DOCTYPE html><html lang="en"><head><meta charset="UTF-8"><title>My Page</title></head><body><h1 class="main-title">Hello Alice</h1><p class="status">Welcome back, Alice!</p><ul class="menu"><li><a href="/home">Home</a></li><li><a href="/profile">Profile</a></li></ul><button class="btn-primary">Click me</button></body></html>
```

## Sintaxis Pug Soportada

### Doctype

```zpug
doctype html
// Salida: <!DOCTYPE html>

doctype xml
// Salida: <!DOCTYPE xml>
```

### Tags y Atributos

```zpug
// Tags simples
div
p Hello
span World

// Múltiples clases (concatenadas)
div.box.highlight.active
// Salida: <div class="box highlight active">

// Clases e IDs
div.container
p#main-text
button.btn.btn-primary#submit

// Atributos (estáticos)
a(href="https://example.com" target="_blank") Link
input(type="text" name="username" required)

// Atributos (expresiones dinámicas)
- var myClass = "active"
- var myUrl = "/home"
button(class=myClass) Click
a(href=myUrl) Link
// Salida: <button class="active">Click</button>

// Múltiples líneas
div(
  class="card"
  id="user-card"
  data-user-id="123"
)
```

### Código Buffered y Unbuffered

```zpug
// Código unbuffered (ejecuta pero no genera salida)
- var name = "Alice"
- var age = 30
- var doubled = age * 2

// Código buffered inline (sintaxis tag=)
p= name
// Salida: <p>Alice</p>

h1= name.toUpperCase()
// Salida: <h1>ALICE</h1>

// Código buffered sin escapar (tag!=)
- var html = "<strong>Bold</strong>"
div= html
// Salida: <div>&lt;strong&gt;Bold&lt;/strong&gt;</div>

div!= html
// Salida: <div><strong>Bold</strong></div>
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

// Objetos (desde JSON)
p Name: #{user.name}
p Email: #{user.email}
p Age: #{user.age}

// Arrays (desde JSON)
p First: #{items[0]}
p Count: #{items.length}

// Expresiones complejas
p Full: #{firstName + ' ' + lastName}
p Status: #{age >= 18 ? 'Adult' : 'Minor'}

// Math
p Max: #{Math.max(10, 20)}
p Random: #{Math.floor(Math.random() * 100)}
```

### Escapado HTML (Seguridad XSS)

Todas las interpolaciones se escapan automáticamente por seguridad:

```zpug
// Escapado por defecto (seguro)
p #{userInput}
// Input: <script>alert('xss')</script>
// Salida: <p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>

// Sin escapar (solo para HTML confiable)
p !{trustedHtml}
// Input: <strong>Bold</strong>
// Salida: <p><strong>Bold</strong></p>
```

**Caracteres escapados:** `&` `<` `>` `"` `'`

**⚠️ Seguridad:** Solo usa `!{}` con HTML que controles. Nunca con entrada de usuario.

### Condicionales

Soporte completo para `if`, `else`, `else if` y `unless` con expresiones JavaScript completas:

```zpug
// if/else básico
if isLoggedIn
  p Bienvenido de nuevo!
else
  p Por favor inicia sesión

// Múltiples else if (encadenamiento ilimitado)
if score > 90
  p Calificación A
else if score > 80
  p Calificación B
else if score > 70
  p Calificación C
else
  p Calificación F

// unless (negación)
unless isAdmin
  p Acceso denegado

// Acceso a propiedades
if user.isPremium
  p Funciones premium habilitadas
else
  p Mejora a premium

// Operadores de comparación (>, <, >=, <=, ==)
if age >= 18
  p Contenido para adultos
else if age >= 13
  p Contenido adolescente
else
  p Contenido infantil

// Operadores lógicos (&&, ||)
if age >= 18 && hasLicense
  p Puede conducir
else
  p No puede conducir

// Igualdad de strings
if status == "active"
  p Cuenta activa
else if status == "pending"
  p Aprobación pendiente
else
  p Cuenta inactiva

// Expresiones complejas
if (isAdmin || isModerator) && user.isActive
  p Acceso administrativo
else
  p Acceso regular

// Verificación de longitud de arrays
if items.length > 0
  p Carrito tiene #{items.length} artículos
else
  p Carrito vacío

// Condiciones anidadas
if user.isActive
  if user.isPremium
    p Usuario premium activo
  else
    p Usuario regular activo
else
  p Cuenta inactiva
```

**Características soportadas:**
- ✅ Acceso a propiedades: `user.isPremium`, `array.length`
- ✅ Operadores de comparación: `>`, `<`, `>=`, `<=`, `==`
- ✅ Operadores lógicos: `&&` (AND), `||` (OR)
- ✅ Igualdad de strings: `status == "active"`
- ✅ Encadenamiento ilimitado de `else if`
- ✅ Condicionales anidados
- ✅ Expresiones combinadas complejas

### Loops

```zpug
// Each con arrays
each item in items
  li= item

// Each con índice
each item, i in items
  li #{i}: #{item}

// While loops
- var count = 0
while count < 5
  p Count: #{count}
  - count = count + 1
```

### Mixins con Argumentos

```zpug
// Definir mixin
mixin greeting(name)
  p Hello, #{name}!

mixin button(text, type)
  button(class=type)= text

// Usar mixins
+greeting("World")
+greeting("Alice")

+button("Click me", "btn-primary")
+button("Cancel", "btn-secondary")

// Salida:
// <p>Hello, World!</p>
// <p>Hello, Alice!</p>
// <button class="btn-primary">Click me</button>
// <button class="btn-secondary">Cancel</button>
```

### Herencia de Plantillas (Extends/Block)

Construye layouts reutilizables con herencia de plantillas usando `extends` y `block`:

```zpug
// layout.zpug - Layout base
doctype html
html
  head
    title
      block title
        | Default Title
  body
    header
      h1 My Website
    main
      block content
        p Default content
    footer
      block footer
        p © 2024

// page.zpug - Extiende el layout
extends layout.zpug

block title
  | Home Page

block content
  h2 Welcome
  p This replaces the default block content

// Salida:
// <!DOCTYPE html>
// <html>
//   <head><title>Home Page</title></head>
//   <body>
//     <header><h1>My Website</h1></header>
//     <main>
//       <h2>Welcome</h2>
//       <p>This replaces the default block content</p>
//     </main>
//     <footer><p>© 2024</p></footer>
//   </body>
// </html>
```

**Modos de Bloque:**

```zpug
// Replace (por defecto) - Reemplaza completamente el bloque padre
block content
  p New content

// Append - Agrega después del bloque padre
block append content
  p Added after default

// Prepend - Agrega antes del bloque padre
block prepend content
  p Added before default
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

### Comentarios

```zpug
//! Comentario de documentación (completamente ignorado)
//! Puede aparecer antes de declaraciones doctype

// Comentario buffered (visible en HTML con --pretty)
// Este aparece solo en modo desarrollo

//- Comentario unbuffered (nunca en HTML)
//- Esto está solo en el código fuente, nunca compilado

// Seguridad: Los comentarios se escapan
// Comment with --> injection attempt
// Salida: <!-- Comment with - -> injection attempt -->
```

**Tipos de Comentarios:**

| Sintaxis | Nombre | ¿Procesado? | ¿En HTML? | Caso de Uso |
|----------|--------|-------------|-----------|-------------|
| `//!` | Documentación | ❌ No | ❌ No | Metadata de archivo, notas del autor |
| `//` | Buffered | ✅ Sí | ✅ Sí (solo --pretty) | Depuración en desarrollo |
| `//-` | Unbuffered | ✅ Sí | ❌ No | Comentarios de código |

**Comportamiento de Comentarios:**

- **Comentarios de documentación (`//!`)**: Completamente ignorados por el tokenizer (pueden aparecer antes de `doctype`)
- **Modo producción (por defecto)**: Todos los comentarios buffered (`//`) se **eliminan** para tamaño mínimo de archivo
- **Modo desarrollo (`--pretty`)**: Los comentarios buffered (`//`) se **incluyen** para depuración
- **Modo legible (`--format`)**: Pretty-print sin comentarios
- **Comentarios unbuffered (`//-`)**: Siempre eliminados en todos los modos

```bash
# Producción: sin comentarios, minificado
zpug template.zpug -o output.html

# Desarrollo: con comentarios e indentación
zpug --pretty template.zpug -o output.html

# Legible: indentación sin comentarios
zpug --format template.zpug -o output.html
```

Esto coincide con los estándares de la industria (Pug, minificadores HTML) donde la salida de producción está optimizada y la salida de desarrollo es legible.

### Soporte UTF-8

Soporte completo de Unicode para caracteres internacionales en todos los elementos del template:

```zpug
doctype html
html(lang="es")
  head
    title Página en Español
  body
    h1 Bienvenido 🎉

    // Español
    p.información Este es un párrafo con acentos: José, María, Ángel

    // Portugués
    p.português Programação em português com ã, õ, ç

    // Francés
    p.français Génération française avec é, è, ê, ç

    // Alemán
    p#größe Deutsche Größe mit ä, ö, ü, ß

    // Emoji y símbolos
    p Symbols: © ™ € £ ¥ • Emoji: 🚀 ✨ 💻 🌍
```

**Soportado:**
- ✅ Caracteres acentuados en texto: `á é í ó ú ñ ü ç`
- ✅ Caracteres acentuados en nombres de clase: `.información`
- ✅ Caracteres acentuados en IDs: `#descripción`
- ✅ Caracteres acentuados en comentarios: `// útil`
- ✅ Emoji y símbolos Unicode: `🎉 © ™ €`
- ✅ Todas las secuencias UTF-8 (1-4 bytes)

## API de Programación (Zig)

### Ejemplo Completo

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
    try js_runtime.setBool("active", true);

    // Parsear template
    const source =
        \\doctype html
        \\html
        \\  body
        \\    h1= name
        \\    p Age: #{age}
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

### Trabajar con Datos JSON

```zig
// Establecer arrays
const items = [_][]const u8{ "apple", "banana", "orange" };
for (items) |item| {
    // Los arrays se establecen vía código JavaScript
    _ = try js_runtime.eval("var items = ['apple', 'banana', 'orange']");
}

// Establecer objetos
_ = try js_runtime.eval("var user = {name: 'Bob', age: 30}");

// Acceder a propiedades
const name = try js_runtime.eval("user.name");
defer allocator.free(name);
```

## Documentación Completa

### Primeros Pasos
- **[GETTING-STARTED.md](docs/es/GETTING-STARTED.md)** - Guía paso a paso
- **[CLI.md](docs/es/CLI.md)** - Interfaz de línea de comandos
- **[PUG-SYNTAX.md](docs/es/PUG-SYNTAX.md)** - Referencia completa de sintaxis

### Integración
- **[NODEJS-INTEGRATION.md](docs/es/NODEJS-INTEGRATION.md)** - Integración con Node.js (N-API)
- **[ZIG-PACKAGE.md](docs/es/ZIG-PACKAGE.md)** - Uso como dependencia de Zig
- **[TERMUX.md](docs/es/TERMUX.md)** - Compilación en Termux/Android

### Avanzado
- **[LOOPS-INCLUDES-CACHE.md](docs/es/LOOPS-INCLUDES-CACHE.md)** - Loops, includes y cache
- **[API-REFERENCE.md](docs/es/API-REFERENCE.md)** - Documentación de la API
- **[EXAMPLES.md](docs/es/EXAMPLES.md)** - Ejemplos prácticos
- **[TESTS.md](docs/tests/README.md)** - Documentación de tests (87 tests)

## Testing

```bash
# Ejecutar todos los tests
zig build test

# Ver resultados detallados
zig build test --summary all
```

**Estado de tests:** ✅ Todos los 87 tests pasando

Ver [docs/tests/](docs/tests/) para documentación detallada de tests.

## Arquitectura

zig-pug usa una **arquitectura de dos fases** para procesar templates:

```
Source (*.zpug)
      ↓
  Tokenizer (análisis léxico)
      ↓
   Parser (análisis sintáctico)
      ↓
     AST (árbol de sintaxis abstracta)
      ↓
  Compiler ← JS Runtime (mujs)
      ↓
    HTML (salida)
```

### Evaluación de Expresiones Condicionales

zig-pug usa un enfoque de **separación de responsabilidades**:

**Fase 1: Parser (Zig)**
- Reconoce operadores como tokens (`>=`, `&&`, `||`, etc.)
- Reconstruye expresiones JavaScript como strings
- NO evalúa las expresiones

**Fase 2: mujs (C)**
- Evalúa las expresiones JavaScript
- Maneja todos los operadores, acceso a propiedades, métodos
- Retorna resultados al compiler

**Ejemplo:**
```pug
if age >= 18 && hasLicense
  p Puede conducir
```

**Parser produce:** `"age>=18&&hasLicense"` (string)
**mujs evalúa:** `25 >= 18 && true` → `true` (resultado)

Esta arquitectura proporciona:
- ✅ Soporte completo de JavaScript ES5.1 automáticamente
- ✅ Código simple del parser (solo concatenación de strings)
- ✅ Evaluación confiable (mujs está probado en batalla)
- ✅ Mismo enfoque que Pug.js (delega al motor JavaScript)

**Para detalles:** Ver [docs/es/ARCHITECTURE.md](docs/es/ARCHITECTURE.md)

## Optimizaciones de Rendimiento

- **Escapado HTML** - Tamaño de buffer pre-calculado (una sola asignación)
- **Generación de código JS** - Buffers pre-asignados para arrays/objetos
- **mujs** - Compilado con optimización -O2
- **Builds de release** - ReleaseFast forzado para compatibilidad con mujs

## Motor JavaScript

zig-pug usa [**mujs**](https://mujs.com/) como su motor JavaScript:

- **Versión**: mujs 1.3.8
- **Estándar**: Compatible con ES5.1
- **Tamaño**: 590 KB
- **Dependencias**: Ninguna (solo libm)
- **Usado por**: MuPDF, Ghostscript

### JavaScript Soportado (ES5.1)

✅ **Completamente soportado:**
- Métodos de String, Métodos de Number, Métodos de Array
- Acceso a propiedades de objetos, Operadores Aritméticos/Comparación/Lógicos
- Operador ternario, Objeto Math, Objeto JSON

❌ **No soportado (ES6+):**
- Arrow functions, Template literals, let/const, Async/await, Clases

**Para motores de plantillas, ES5.1 es completamente suficiente.**

## Estado del Proyecto

### ✅ Completado (v0.2.0)

**Fase 1: Bugs Críticos**
- [x] Concatenación de múltiples clases
- [x] Parseo de iterador de loops
- [x] Argumentos de mixins
- [x] Escapado de comentarios (seguridad)

**Fase 2: API y Variables**
- [x] Soporte de arrays JSON (`--vars`)
- [x] Soporte de objetos JSON
- [x] Expresiones en atributos (`class=myVar`)
- [x] Código unbuffered (líneas `-`)

**Fase 3: Mejoras de UX**
- [x] Mensajes de error con números de línea y sugerencias
- [x] Sintaxis tag= y tag!=
- [x] Soporte de doctype

**Fase 4: Rendimiento**
- [x] Escapado HTML optimizado
- [x] Generación de código JS optimizada

**Fase 5: Testing**
- [x] 87 tests unitarios completos
- [x] Documentación de tests

**Fase 6: Características de Producción**
- [x] Manejo de comentarios (modos producción vs desarrollo)
- [x] Pretty printing (indentación HTML)

### 🚧 En Progreso

- [ ] Modo watch (`-w`)

### 📋 Roadmap

Ver [PLAN.md](PLAN.md) para el plan completo de desarrollo.

## Contribuir

¡Las contribuciones son bienvenidas! Por favor:

1. Fork el proyecto
2. Crea una rama (`git checkout -b feature/AmazingFeature`)
3. Commit tus cambios (`git commit -m 'Add AmazingFeature'`)
4. Push a la rama (`git push origin feature/AmazingFeature`)
5. Abre un Pull Request

## Licencia

MIT License - ver [LICENSE](LICENSE) para detalles

## Agradecimientos

- [Pug](https://pugjs.org/) - Inspiración original
- [Zig](https://ziglang.org/) - Lenguaje de programación
- [mujs](https://mujs.com/) - Motor JavaScript embebido
- [Artifex Software](https://artifex.com/) - Creadores de mujs

## Soporte

- **Issues**: [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)

---

**Hecho con ❤️ usando Zig 0.15.2 y mujs**

*Last Updated: 2025-12-16*
