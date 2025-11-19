# Guía de Inicio Rápido - zig-pug

Esta guía te llevará paso a paso desde la instalación hasta la creación de tu primer template con zig-pug.

## 📋 Prerrequisitos

Antes de comenzar, asegúrate de tener:

- **Zig 0.15.2** instalado ([descargar aquí](https://ziglang.org/download/))
- Terminal/línea de comandos
- Editor de texto (VS Code, Vim, etc.)

### Verificar instalación de Zig

```bash
zig version
# Output esperado: 0.15.2
```

## 🚀 Paso 1: Clonar e Instalar

```bash
# Clonar el repositorio
git clone https://github.com/yourusername/zig-pug
cd zig-pug

# Compilar el proyecto
zig build

# Verificar que compiló correctamente
./zig-out/bin/zig-pug
```

**Output esperado:**
```
zig-pug v0.1.0
Template engine inspired by Pug
Built with Zig 0.15.2
...
```

## 📝 Paso 2: Tu Primer Template

Vamos a crear un template simple paso a paso.

### 2.1: Crear el archivo de template

Crea un archivo `hello.pug`:

```pug
div.greeting
  h1 Hello World!
  p This is my first zig-pug template
```

###2.2: Crear el programa Zig

Crea un archivo `example.zig` en el directorio raíz:

```zig
const std = @import("std");
const parser = @import("src/parser.zig");
const compiler = @import("src/compiler.zig");
const runtime = @import("src/runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Tu template Pug
    const template =
        \\div.greeting
        \\  h1 Hello World!
        \\  p This is my first zig-pug template
    ;

    // 1. Crear el runtime JavaScript
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // 2. Parsear el template
    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    // 3. Compilar a HTML
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(ast);
    defer allocator.free(html);

    // 4. Mostrar el resultado
    std.debug.print("HTML Output:\n{s}\n", .{html});
}
```

### 2.3: Compilar y ejecutar

```bash
zig build-exe example.zig -I src

./example
```

**Output:**
```html
<div class="greeting"><h1>Hello World!</h1><p>This is my first zig-pug template</p></div>
```

¡Felicitaciones! Has creado tu primer template con zig-pug.

## 🎨 Paso 3: Agregar Variables

Ahora vamos a hacer el template dinámico usando variables.

### 3.1: Template con interpolación

```pug
div.user-card
  h2 Welcome #{name}!
  p You are #{age} years old
  p Email: #{email}
```

### 3.2: Programa con variables

```zig
const std = @import("std");
const parser = @import("src/parser.zig");
const compiler = @import("src/compiler.zig");
const runtime = @import("src/runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const template =
        \\div.user-card
        \\  h2 Welcome #{name}!
        \\  p You are #{age} years old
        \\  p Email: #{email}
    ;

    // Crear runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // ⭐ Establecer variables
    try js_runtime.setString("name", "Alice");
    try js_runtime.setNumber("age", 25);
    try js_runtime.setString("email", "alice@example.com");

    // Parsear y compilar
    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(ast);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

**Output:**
```html
<div class="user-card"><h2>WelcomeAlice!</h2><p>You are25years old</p><p>Email:alice@example.com</p></div>
```

## 🔧 Paso 4: Usar Métodos JavaScript

zig-pug soporta métodos de JavaScript en las interpolaciones.

### 4.1: Template con métodos

```pug
div.profile
  h1 #{name.toUpperCase()}
  p Email: #{email.toLowerCase()}
  p Age next year: #{age + 1}
  p Double age: #{age * 2}
```

### 4.2: Programa (mismo código anterior)

El código es el mismo, solo cambia el template. Los métodos JavaScript funcionan automáticamente.

**Output:**
```html
<div class="profile"><h1>ALICE</h1><p>Email:alice@example.com</p><p>Age next year:26</p><p>Double age:50</p></div>
```

## ✨ Paso 5: Condicionales

Agregar lógica condicional a tus templates.

### 5.1: Template con if/else

```pug
div.status
  h2 User Status
  if isActive
    p.active ✓ User is active
  else
    p.inactive ✗ User is inactive

  if age >= 18
    p You can vote
  else
    p Too young to vote
```

### 5.2: Programa con booleanos

```zig
// ... (mismo setup anterior) ...

// Establecer variables
try js_runtime.setString("name", "Bob");
try js_runtime.setNumber("age", 16);
try js_runtime.setBool("isActive", true);

// ... (parsear y compilar) ...
```

**Output:**
```html
<div class="status"><h2>User Status</h2><p class="active">✓ User is active</p><p>Too young to vote</p></div>
```

## 🎯 Paso 6: Trabajar con Objetos

### 6.1: Crear objetos en JavaScript

```zig
// ... (setup) ...

var js_runtime = try runtime.JsRuntime.init(allocator);
defer js_runtime.deinit();

// Crear un objeto en JavaScript
_ = try js_runtime.eval(
    \\var user = {
    \\  firstName: 'John',
    \\  lastName: 'Doe',
    \\  email: 'JOHN.DOE@EXAMPLE.COM',
    \\  age: 30
    \\};
);
```

### 6.2: Template con propiedades de objetos

```pug
div.profile
  h1 #{user.firstName} #{user.lastName}
  p Email: #{user.email.toLowerCase()}
  p Age: #{user.age}
  p Next birthday: #{user.age + 1}
```

**Output:**
```html
<div class="profile"><h1>JohnDoe</h1><p>Email:john.doe@example.com</p><p>Age:30</p><p>Next birthday:31</p></div>
```

## 🧩 Paso 7: Mixins (Componentes Reutilizables)

Los mixins te permiten crear componentes que puedes reusar.

### 7.1: Template con mixins

```pug
mixin card(title, text)
  div.card
    h3.card-title= title
    p.card-text= text

div.container
  +card('Welcome', 'This is the first card')
  +card('About', 'This is the second card')
  +card('Contact', 'This is the third card')
```

### 7.2: Programa (código estándar)

Los mixins funcionan automáticamente con el mismo código de siempre.

## 📦 Paso 8: Ejemplo Completo Real

Ahora vamos a crear un ejemplo completo que combine todo lo aprendido.

### 8.1: Template completo

Crea `profile.pug`:

```pug
div.user-profile
  div.header
    h1 #{user.name.toUpperCase()}
    if user.isVerified
      span.badge ✓ Verified

  div.info
    p Email: #{user.email.toLowerCase()}
    p Age: #{user.age}
    p Member since: #{user.year}

  div.stats
    p Posts: #{user.stats.posts}
    p Followers: #{user.stats.followers}
    p Following: #{user.stats.following}

  div.actions
    if user.age >= 18
      button.btn Vote Now

    unless user.isVerified
      button.btn.verify Verify Account
```

### 8.2: Programa completo

Crea `profile_example.zig`:

```zig
const std = @import("std");
const parser = @import("src/parser.zig");
const compiler = @import("src/compiler.zig");
const runtime = @import("src/runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Leer el template desde archivo (o usar string)
    const template = @embedFile("profile.pug");

    // Crear runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Crear un objeto de usuario completo
    _ = try js_runtime.eval(
        \\var user = {
        \\  name: 'Alice Johnson',
        \\  email: 'ALICE.JOHNSON@EXAMPLE.COM',
        \\  age: 25,
        \\  year: 2020,
        \\  isVerified: true,
        \\  stats: {
        \\    posts: 42,
        \\    followers: 156,
        \\    following: 89
        \\  }
        \\};
    );

    // Parsear
    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    // Compilar
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(ast);
    defer allocator.free(html);

    // Guardar a archivo
    const file = try std.fs.cwd().createFile("output.html", .{});
    defer file.close();
    try file.writeAll(html);

    std.debug.print("✓ HTML generado en output.html\n", .{});
}
```

### 8.3: Compilar y ejecutar

```bash
zig build-exe profile_example.zig -I src
./profile_example
```

Se creará `output.html` con todo el HTML generado.

## 🎓 Próximos Pasos

Ahora que dominas lo básico, puedes:

1. **Leer la documentación completa**:
   - [PUG-SYNTAX.md](PUG-SYNTAX.md) - Todas las características de Pug
   - [API-REFERENCE.md](API-REFERENCE.md) - API completa de zig-pug

2. **Ver más ejemplos**:
   - [examples/](../examples/) - Ejemplos prácticos

3. **Explorar características avanzadas**:
   - Loops (cuando estén implementados)
   - Template inheritance
   - Filtros personalizados

## ❓ Problemas Comunes

### Error: "unable to detect native libc"

Este error ocurre si intentas compilar con `-lc`. zig-pug ya incluye todo lo necesario, no necesitas linkear con libc manualmente.

**Solución**: Usa solo `zig build-exe example.zig -I src`

### Los espacios desaparecen en el HTML

Esto es comportamiento normal del parser actual. El HTML generado es funcional aunque no tenga espacios decorativos.

### Variable no encontrada

Asegúrate de establecer la variable ANTES de parsear el template:

```zig
// ✓ Correcto
try js_runtime.setString("name", "Alice");
var pars = try parser.Parser.init(allocator, template);
// ...

// ✗ Incorrecto (variable establecida después de parsear)
var pars = try parser.Parser.init(allocator, template);
try js_runtime.setString("name", "Alice"); // ¡Muy tarde!
```

## 📚 Recursos Adicionales

- **[README.md](../README.md)** - Vista general del proyecto
- **[MUJS-INTEGRATION.md](../MUJS-INTEGRATION.md)** - Detalles del motor JavaScript
- **[Documentación de Pug](https://pugjs.org/)** - Referencia original de Pug
- **[Documentación de Zig](https://ziglang.org/documentation/master/)** - Zig language guide

---

¡Felicitaciones! Ahora estás listo para crear templates potentes con zig-pug. 🎉
