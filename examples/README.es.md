[English](README.md) | Español

# Ejemplos de zig-pug

Esta carpeta contiene ejemplos prácticos de templates Pug para zig-pug.

## 📁 Archivos de Ejemplo

### 1. `01-basic.zpug`
**Tags y Atributos Básicos**

Muestra la sintaxis básica de Pug:
- Tags simples (`div`, `p`, `h1`)
- Clases (`.clase`)
- IDs (`#id`)
- Atributos `(attr="value")`

**Conceptos**: Tags, anidación, atributos

---

### 2. `02-interpolation.zpug`
**Interpolación de JavaScript**

Demuestra cómo usar variables y expresiones JavaScript:
- Variables simples: `#{name}`
- Métodos: `#{name.toUpperCase()}`
- Aritmética: `#{age + 1}`
- Expresiones complejas: `#{age >= 18 ? 'Yes' : 'No'}`

**Conceptos**: Interpolación, métodos de JavaScript, operadores

---

### 3. `03-conditionals.zpug`
**Condicionales**

Muestra la lógica condicional en templates:
- `if`/`else`
- `else if` (múltiples condiciones)
- `unless` (negación)
- Expresiones en condiciones

**Conceptos**: Control de flujo, lógica condicional

---

### 4. `04-mixins.zpug`
**Mixins (Componentes Reutilizables)**

Demuestra cómo crear y usar mixins:
- Definir mixins: `mixin nombre(params)`
- Llamar mixins: `+nombre(args)`
- Mixins con parámetros
- Reutilización de componentes

**Conceptos**: Componentes, reutilización, DRY

---

### 5. `05-complete-example.zpug`
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

### 6. `loops.zpug`
**Loops y Condicionales**

Demuestra iteración de arrays y renderizado condicional:
- Loops básicos con `each`: `each item in array`
- Múltiples loops en el mismo template
- Manejo de arrays vacíos con `if array.length > 0`

**Conceptos**: Iteración, bucles, renderizado condicional

**Soportado en v0.3.x**:
- ✅ Acceso a propiedades: `if array.length`
- ✅ Comparaciones: `if age >= 18`, `if score > 50`
- ✅ Operadores lógicos: `if a && b`, `if x || y`
- ✅ Igualdad de strings: `if status == "active"`
- ✅ Expresiones combinadas: `if age >= 18 && hasPermission`

**Limitaciones Actuales en v0.3.x**:
- ❌ Loop con índice (`each item, i in array`) - **NO soportado**
- ❌ Sintaxis `each...else` - **NO soportado** (usar `if array.length > 0` en su lugar)

---

### 7. `06-conditionals-advanced.zpug`
**Condicionales Avanzados**

Demostración completa de todas las capacidades del statement `if`:
- Acceso a propiedades: `user.isActive`, `array.length`
- Operadores de comparación: `>=`, `>`, `<`, `<=`, `==`
- Operadores lógicos: `&&` (AND), `||` (OR)
- Verificación de igualdad de strings
- Expresiones complejas combinadas
- Operaciones con arrays y verificación de longitud
- Patrones de uso en aplicaciones reales (dashboards, control de acceso, badges)

**Conceptos**: Condicionales avanzados, acceso a propiedades, expresiones lógicas, patrones del mundo real

**Características Demostradas**:
- ✅ Verificación de propiedades de objetos: `if user.isPremium`
- ✅ Verificación de edad: `if age >= 18`
- ✅ Rangos de puntuación: `if score > 90` ... `else if score > 75`
- ✅ Alertas de inventario: `if stock < 10`
- ✅ Coincidencia de estado: `if status == "approved"`
- ✅ Múltiples condiciones: `if age >= 18 && hasLicense`
- ✅ Condiciones alternativas: `if isAdmin || isModerator`
- ✅ Expresiones complejas: `if (isAdmin || isModerator) && user.isActive`
- ✅ Manejo de arrays vacíos: `if items.length > 0`
- ✅ Condicionales anidados para gestión de estado de UI

Este ejemplo sirve como referencia completa para lógica condicional en templates zig-pug.

---

## 🚀 Cómo Usar los Ejemplos

### Opción 1: Copiar y Pegar

Copia el contenido de cualquier ejemplo a tu código Zig:

```zig
const template = @embedFile("examples/01-basic.zpug");

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
    const template = @embedFile("examples/02-interpolation.zpug");

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

### 01-basic.zpug
No requiere variables (HTML estático).

### 02-interpolation.zpug
```zig
try js_runtime.setString("name", "Alice");
try js_runtime.setString("email", "alice@example.com");
try js_runtime.setNumber("age", 25);
```

### 03-conditionals.zpug
```zig
try js_runtime.setBool("isLoggedIn", true);
try js_runtime.setNumber("age", 20);
try js_runtime.setBool("hasPermission", false);
try js_runtime.setString("role", "admin");
```

### 04-mixins.zpug
No requiere variables externas (los mixins usan parámetros).

### loops.zpug
```zig
// Arrays para los loops
_ = try js_runtime.eval(
    \\var users = ['Alice', 'Bob', 'Charlie'];
);
_ = try js_runtime.eval(
    \\var fruits = ['Apple', 'Banana', 'Orange'];
);
_ = try js_runtime.eval(
    \\var products = []; // Array vacío para demostrar renderizado condicional
);
```

### 06-conditionals-advanced.zpug
```zig
// Objeto user
_ = try js_runtime.eval(
    \\var user = {
    \\  name: 'Alice Johnson',
    \\  isActive: true,
    \\  isPremium: true,
    \\  memberSince: '2023-01-15'
    \\};
);

// Valores numéricos
try js_runtime.setNumber("age", 25);
try js_runtime.setNumber("score", 85);
try js_runtime.setNumber("stock", 7);
try js_runtime.setNumber("bonusPoints", 120);
try js_runtime.setNumber("purchases", 15);

// Valores string
try js_runtime.setString("status", "approved");

// Valores boolean
try js_runtime.setBool("hasLicense", true);
try js_runtime.setBool("isAdmin", false);
try js_runtime.setBool("isModerator", true);

// Arrays
_ = try js_runtime.eval(
    \\var notifications = ['New message', 'Update available', 'System alert'];
);
_ = try js_runtime.eval(
    \\var items = ['Laptop', 'Mouse', 'Keyboard'];
);
_ = try js_runtime.eval(
    \\var products = ['Product A', 'Product B', 'Product C', 'Product D'];
);
```

### 05-complete-example.zpug
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

1. **Comienza simple**: Empieza con `01-basic.zpug` y ve avanzando.

2. **Experimenta**: Modifica los ejemplos y ve qué pasa.

3. **Combina características**: Toma ideas de varios ejemplos y combínalas.

4. **Revisa el output**: Siempre ve el HTML generado para entender cómo funciona.

## 🔗 Recursos Relacionados

- [README.md](../README.md) - Vista general del proyecto
- [docs/GETTING-STARTED.md](../docs/GETTING-STARTED.md) - Guía paso a paso
- [docs/PUG-SYNTAX.md](../docs/PUG-SYNTAX.md) - Referencia completa de sintaxis

---

¿Encontraste un bug o tienes una sugerencia? [Abre un issue](https://github.com/carlos-sweb/zig-pug/issues)
