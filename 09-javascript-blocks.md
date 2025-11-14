# Paso 9: Runtime de Evaluación JavaScript

## Objetivo
Implementar un runtime JavaScript para evaluar expresiones dentro de templates durante el renderizado, permitiendo manipulación de datos con APIs nativas de JavaScript y librerías populares.

---

## Visión y Propósito

**NO generamos JavaScript en la salida HTML**. El objetivo es evaluar expresiones JavaScript **durante el renderizado** para manipular datos del contexto.

### Ejemplos de Uso:

```pug
// Contexto: { name: "JOHN DOE", price: 1234.56, items: [...] }

// APIs nativas de JavaScript
p #{name.toLowerCase()}              // → <p>john doe</p>
p #{name.toUpperCase()}              // → <p>JOHN DOE</p>
p #{name.split(' ')[0]}              // → <p>JOHN</p>

// Librería voca.js (manipulación de strings)
p #{v.trim(name)}                    // → <p>JOHN DOE</p>
p #{v.slugify(name)}                 // → <p>john-doe</p>
p #{v.titleCase(name)}               // → <p>John Doe</p>

// Librería numeral.js (formateo de números)
p #{numeral(price).format('$0,0.00')} // → <p>$1,234.56</p>

// Librería day.js (manipulación de fechas)
p #{dayjs(date).format('YYYY-MM-DD')} // → <p>2025-01-14</p>

// Evaluación en condicionales
if items.length > 0
  p Tenemos #{items.length} artículos

// Evaluación en loops
each item in items.filter(x => x.active)
  li= item.name

// Evaluación en case statements
case items.find(x => x.featured).category
  when "electronics"
    p Electrónica
```

---

## Arquitectura

### Componentes Principales:

```
┌─────────────────────────────────────────────────────┐
│                   Template Pug                      │
│   p #{name.toLowerCase()}                           │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓ Parser (ya implementado)
┌─────────────────────────────────────────────────────┐
│                    AST Node                         │
│   Interpolation { expression: "name.toLowerCase()" }│
└────────────────┬────────────────────────────────────┘
                 │
                 ↓ Compiler (Paso 11)
┌─────────────────────────────────────────────────────┐
│              JavaScript Runtime                     │
│   - QuickJS Engine                                  │
│   - Contexto: { name: "JOHN DOE" }                 │
│   - Librerías: voca.js, numeral.js, day.js        │
│   - Evalúa: "JOHN DOE".toLowerCase()               │
└────────────────┬────────────────────────────────────┘
                 │
                 ↓ Resultado: "john doe"
┌─────────────────────────────────────────────────────┐
│                  HTML Output                        │
│   <p>john doe</p>                                   │
└─────────────────────────────────────────────────────┘
```

---

## Tareas

### 9.1 Integrar QuickJS
- Descargar QuickJS (versión 2024.01.13 o superior)
- Compilar como biblioteca estática para Zig
- Crear bindings básicos C ↔ Zig

### 9.2 Crear JavaScript Runtime

```zig
pub const JsRuntime = struct {
    ctx: *quickjs.JSContext,
    allocator: std.mem.Allocator,

    /// Inicializar runtime con librerías opcionales
    pub fn init(allocator: std.mem.Allocator, options: RuntimeOptions) !*JsRuntime;

    /// Evaluar expresión JavaScript
    pub fn eval(self: *Self, expr: []const u8) ![]const u8;

    /// Cargar librería JavaScript
    pub fn loadLibrary(self: *Self, name: []const u8, code: []const u8) !void;

    /// Establecer contexto del template
    pub fn setContext(self: *Self, data: std.json.Value) !void;

    /// Obtener valor del contexto
    pub fn getValue(self: *Self, name: []const u8) !std.json.Value;

    /// Cleanup
    pub fn deinit(self: *Self) void;
};
```

### 9.3 Cargar Librerías Core

#### Librerías a integrar:
1. **voca.js** - Manipulación de strings
   - `v.trim()`, `v.slugify()`, `v.titleCase()`, etc.

2. **numeral.js** - Formateo de números
   - `numeral(1234).format('0,0')` → "1,234"

3. **day.js** - Manipulación de fechas
   - `dayjs().format('YYYY-MM-DD')`

4. **lodash** (opcional) - Utilidades de arrays/objects
   - `_.map()`, `_.filter()`, `_.groupBy()`

### 9.4 Conversión de Tipos Zig ↔ JavaScript

```zig
pub const TypeConverter = struct {
    /// Convertir valor Zig a JavaScript
    pub fn zigToJs(runtime: *JsRuntime, value: anytype) !quickjs.JSValue;

    /// Convertir valor JavaScript a Zig
    pub fn jsToZig(runtime: *JsRuntime, value: quickjs.JSValue, comptime T: type) !T;

    /// Convertir JSON a contexto JS
    pub fn jsonToContext(runtime: *JsRuntime, json: std.json.Value) !void;
};
```

### 9.5 Integración con Compiler

El compiler (Paso 11) usará el runtime así:

```zig
// Al encontrar interpolación
const interp_node = ast_node.data.Interpolation;

// Evaluar con runtime
const result = try runtime.eval(interp_node.expression);

// Insertar en output HTML
try output.appendSlice(result);
```

### 9.6 Sistema de Sandboxing

#### Medidas de seguridad:
- **Sin acceso a filesystem**: Deshabilitar `require()`, `import`, `fs`
- **Timeout de ejecución**: Matar evaluación después de 5 segundos
- **Límite de memoria**: Máximo 50MB por runtime
- **APIs restringidas**: Solo acceso a librerías pre-cargadas
- **No eval dinámico**: Deshabilitar `eval()` y `Function()`

```zig
pub const RuntimeOptions = struct {
    max_memory: usize = 50 * 1024 * 1024,  // 50MB
    timeout_ms: u64 = 5000,                 // 5 segundos
    allow_filesystem: bool = false,
    allow_network: bool = false,
    allow_eval: bool = false,
};
```

### 9.7 Tests

```zig
test "runtime - eval simple expression" {
    var runtime = try JsRuntime.init(allocator, .{});
    defer runtime.deinit();

    try runtime.setContext(.{ .name = "John" });

    const result = try runtime.eval("name.toLowerCase()");
    try std.testing.expectEqualStrings("john", result);
}

test "runtime - voca.js integration" {
    var runtime = try JsRuntime.init(allocator, .{});
    defer runtime.deinit();

    try runtime.loadLibrary("voca", voca_js_code);
    try runtime.setContext(.{ .text = "  hello world  " });

    const result = try runtime.eval("v.trim(text)");
    try std.testing.expectEqualStrings("hello world", result);
}

test "runtime - numeral.js integration" {
    var runtime = try JsRuntime.init(allocator, .{});
    defer runtime.deinit();

    try runtime.loadLibrary("numeral", numeral_js_code);
    try runtime.setContext(.{ .price = 1234.56 });

    const result = try runtime.eval("numeral(price).format('$0,0.00')");
    try std.testing.expectEqualStrings("$1,234.56", result);
}

test "runtime - security timeout" {
    var runtime = try JsRuntime.init(allocator, .{ .timeout_ms = 100 });
    defer runtime.deinit();

    // Debe timeout
    const result = runtime.eval("while(true) {}");
    try std.testing.expectError(error.Timeout, result);
}
```

---

## Flujo Completo de Renderizado

```
1. Usuario: render("template.pug", { name: "JOHN", items: [...] })
                              ↓
2. Inicializar JsRuntime
   - Cargar voca.js, numeral.js, day.js
   - Inyectar contexto { name: "JOHN", items: [...] }
                              ↓
3. Parser → AST (ya implementado)
                              ↓
4. Compiler recorre AST:
   - Encuentra Interpolation { expression: "name.toLowerCase()" }
   - Llama: runtime.eval("name.toLowerCase()")
   - Recibe: "john"
   - Inserta en HTML: <p>john</p>
                              ↓
5. HTML final sin JavaScript embebido
```

---

## Entregables

- ✅ QuickJS integrado con bindings Zig
- ✅ JsRuntime funcional con eval()
- ✅ Voca.js, numeral.js, day.js cargados
- ✅ Conversión de tipos Zig ↔ JS
- ✅ Sandboxing con límites de memoria y timeout
- ✅ Tests de integración y seguridad
- ✅ Documentación de APIs disponibles

---

## Notas de Implementación

### QuickJS vs Duktape:
- **QuickJS**: ES2020, más rápido, mejor para este proyecto ✅
- **Duktape**: ES5.1, más estable pero antiguo

### Orden de implementación recomendado:
1. Integrar QuickJS básico (eval simple)
2. Conversión de tipos (context injection)
3. Cargar voca.js
4. Cargar numeral.js y day.js
5. Sandboxing
6. Integración con compiler

### Alternativa ligera (para MVP):
Si QuickJS es demasiado complejo inicialmente:
- Implementar solo string methods nativos
- Agregar helpers personalizados en Zig
- Diferir librerías externas

---

## Siguiente Paso
**10-toml-parser.md** para integrar parser TOML (datos de entrada).
**11-compiler-html.md** donde se integra este runtime.
