# Ejemplos de zig-pug

Esta carpeta contiene ejemplos prácticos de templates Pug para zig-pug.

## 📁 Archivos de Ejemplo

### 1. `01-basic.pug`
**Tags y Atributos Básicos**

Muestra la sintaxis básica de Pug:
- Tags simples (`div`, `p`, `h1`)
- Clases (`.clase`)
- IDs (`#id`)
- Atributos `(attr="value")`

**Conceptos**: Tags, anidación, atributos

---

### 2. `02-interpolation.pug`
**Interpolación de JavaScript**

Demuestra cómo usar variables y expresiones JavaScript:
- Variables simples: `#{name}`
- Métodos: `#{name.toUpperCase()}`
- Aritmética: `#{age + 1}`
- Expresiones complejas: `#{age >= 18 ? 'Yes' : 'No'}`

**Conceptos**: Interpolación, métodos de JavaScript, operadores

---

### 3. `03-conditionals.pug`
**Condicionales**

Muestra la lógica condicional en templates:
- `if`/`else`
- `else if` (múltiples condiciones)
- `unless` (negación)
- Expresiones en condiciones

**Conceptos**: Control de flujo, lógica condicional

---

### 4. `04-mixins.pug`
**Mixins (Componentes Reutilizables)**

Demuestra cómo crear y usar mixins:
- Definir mixins: `mixin nombre(params)`
- Llamar mixins: `+nombre(args)`
- Mixins con parámetros
- Reutilización de componentes

**Conceptos**: Componentes, reutilización, DRY

---

### 5. `05-complete-example.pug`
**Ejemplo Completo**

Combina todas las características en un ejemplo real:
- Estructura HTML completa
- Navegación dinámica
- Dashboard con estadísticas
- Roles de usuario
- Mixins complejos
- Todo integrado

**Conceptos**: Aplicación real, best practices

---

## 🚀 Cómo Usar los Ejemplos

### Opción 1: Copiar y Pegar

Copia el contenido de cualquier ejemplo a tu código Zig:

```zig
const template = @embedFile("examples/01-basic.pug");

// ... parsear y compilar ...
```

### Opción 2: Crear un Programa de Prueba

Crea `test_example.zig`:

```zig
const std = @import("std");
const parser = @import("src/parser.zig");
const compiler = @import("src/compiler.zig");
const runtime = @import("src/runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Leer el ejemplo
    const template = @embedFile("examples/02-interpolation.pug");

    // Crear runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Establecer variables necesarias
    try js_runtime.setString("name", "Alice");
    try js_runtime.setString("email", "ALICE@EXAMPLE.COM");
    try js_runtime.setNumber("age", 25);

    // Parsear
    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    // Compilar
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(ast);
    defer allocator.free(html);

    // Mostrar resultado
    std.debug.print("{s}\n", .{html});
}
```

Compilar y ejecutar:

```bash
zig build-exe test_example.zig -I src
./test_example
```

## 📚 Variables Necesarias por Ejemplo

### 01-basic.pug
No requiere variables (HTML estático).

### 02-interpolation.pug
```zig
try js_runtime.setString("name", "Alice");
try js_runtime.setString("email", "alice@example.com");
try js_runtime.setNumber("age", 25);
```

### 03-conditionals.pug
```zig
try js_runtime.setBool("isLoggedIn", true);
try js_runtime.setNumber("age", 20);
try js_runtime.setBool("hasPermission", false);
try js_runtime.setString("role", "admin");
```

### 04-mixins.pug
No requiere variables externas (los mixins usan parámetros).

### 05-complete-example.pug
```zig
// Sitio
try js_runtime.setString("siteName", "MiApp");
try js_runtime.setNumber("currentYear", 2024);

// Usuario actual
_ = try js_runtime.eval(
    \\var currentUser = {
    \\  name: 'John Doe',
    \\  role: 'admin',
    \\  isPremium: true
    \\};
);

try js_runtime.setString("lastLogin", "2024-11-18");
try js_runtime.setString("premiumUntil", "2025-12-31");
try js_runtime.setBool("isAdmin", true);

// Estadísticas
_ = try js_runtime.eval(
    \\var stats = {
    \\  posts: 42,
    \\  followers: 156,
    \\  following: 89
    \\};
);

// Datos de admin
_ = try js_runtime.eval(
    \\var adminData = {
    \\  totalUsers: 1250,
    \\  newToday: 15
    \\};
);
```

## 💡 Tips

1. **Comienza simple**: Empieza con `01-basic.pug` y ve avanzando.

2. **Experimenta**: Modifica los ejemplos y ve qué pasa.

3. **Combina características**: Toma ideas de varios ejemplos y combínalas.

4. **Revisa el output**: Siempre ve el HTML generado para entender cómo funciona.

## 🔗 Recursos Relacionados

- [README.md](../README.md) - Vista general del proyecto
- [docs/GETTING-STARTED.md](../docs/GETTING-STARTED.md) - Guía paso a paso
- [docs/PUG-SYNTAX.md](../docs/PUG-SYNTAX.md) - Referencia completa de sintaxis

---

¿Encontraste un bug o tienes una sugerencia? [Abre un issue](https://github.com/yourusername/zig-pug/issues)
