# Propuesta: Loops con JavaScript Runtime

## Estado Actual

### Estructura del LoopNode (ast.zig:210-217)
```zig
pub const LoopNode = struct {
    iterator: []const u8,      // Variable: "item"
    index: ?[]const u8,         // Índice opcional: "i"
    iterable: []const u8,       // Expresión: "items" o "items.filter(...)"
    body: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_while: bool,
};
```

### Sintaxis Pug Tradicional (Ya Soportada)
```pug
// Loop básico
each item in items
  li= item

// Loop con índice
each item, index in items
  li #{index}: #{item}

// While loop
while condition
  p Iteration
```

---

## 🎯 Propuesta 1: Expresiones JavaScript en `iterable`

### Descripción
Permitir que el campo `iterable` contenga **expresiones JavaScript** que se evalúen en runtime.

### Ejemplos

#### 1.1 Filtrado con JavaScript
```pug
// Contexto: { items: [{active: true, name: "A"}, {active: false, name: "B"}] }

each item in items.filter(x => x.active)
  li= item.name
```
**Output:** `<li>A</li>`

#### 1.2 Transformación con map()
```pug
each name in items.map(x => x.name.toUpperCase())
  li= name
```
**Output:** `<li>A</li><li>B</li>`

#### 1.3 Métodos de Array nativos
```pug
// Slice
each item in items.slice(0, 5)
  li= item

// Sort
each item in items.sort((a, b) => a.price - b.price)
  li= item.name

// Reverse
each item in items.reverse()
  li= item
```

#### 1.4 Iteración sobre Object keys/values
```pug
// Contexto: { user: {name: "John", age: 30, city: "NYC"} }

each value in Object.values(user)
  p= value

each key in Object.keys(user)
  p= key

each entry in Object.entries(user)
  p #{entry[0]}: #{entry[1]}
```

#### 1.5 Rangos con JavaScript
```pug
// Rango 0-9
each i in [...Array(10).keys()]
  p= i

// Rango 1-10
each i in Array.from({length: 10}, (_, i) => i + 1)
  p= i
```

### Implementación

#### Parser (parseLoop)
```zig
fn parseLoop(self: *Parser) anyerror!*ast.AstNode {
    const is_while = self.current.type == .While;
    try self.advance();

    // Parse iterator variable(s)
    var iterator: []const u8 = "";
    var index: ?[]const u8 = null;

    if (!is_while) {
        iterator = self.current.value;  // "item"
        try self.advance();

        // Check for index: "item, i"
        if (self.match(&.{.Comma})) {
            try self.advance();
            index = self.current.value;  // "i"
            try self.advance();
        }

        // Expect "in"
        _ = try self.expect(.In);
    }

    // Parse iterable expression (puede ser JS)
    var iterable_expr: std.ArrayList(u8) = .{};
    while (!self.match(&.{ .Newline, .Eof })) {
        if (iterable_expr.items.len > 0) {
            try iterable_expr.append(arena_allocator, ' ');
        }
        try iterable_expr.appendSlice(arena_allocator, self.current.value);
        try self.advance();
    }

    // ... parsear body ...

    return try ast.AstNode.create(
        arena_allocator,
        .Loop,
        start_line,
        1,
        .{ .Loop = .{
            .iterator = iterator,
            .index = index,
            .iterable = try iterable_expr.toOwnedSlice(arena_allocator),
            .body = body,
            .else_branch = null,
            .is_while = is_while,
        } },
    );
}
```

#### Compiler (con QuickJS)
```zig
fn compileLoop(compiler: *Compiler, loop: *ast.LoopNode) !void {
    // Evaluar iterable con JavaScript
    const collection = try compiler.runtime.eval(loop.iterable);
    // collection podría ser: [1, 2, 3] o ["A", "B", "C"]

    // Iterar sobre la colección
    const array = try jsValueToZigArray(collection);

    for (array.items, 0..) |item, idx| {
        // Inyectar variables en contexto JS
        try compiler.runtime.setVariable(loop.iterator, item);

        if (loop.index) |index_name| {
            try compiler.runtime.setVariable(index_name, idx);
        }

        // Compilar body del loop
        for (loop.body.items) |child| {
            try compiler.compileNode(child);
        }
    }
}
```

---

## 🎯 Propuesta 2: Condiciones JavaScript en `while`

### Ejemplos

```pug
// Contexto: { counter: 0, max: 5 }

while counter < max
  p= counter++
```

```pug
// Con expresiones complejas
while items.length > 0 && !done
  p Processing...
```

### Implementación

```zig
fn compileWhileLoop(compiler: *Compiler, loop: *ast.LoopNode) !void {
    while (true) {
        // Evaluar condición con JavaScript
        const condition = try compiler.runtime.eval(loop.iterable);
        const should_continue = try jsValueToBool(condition);

        if (!should_continue) break;

        // Compilar body
        for (loop.body.items) |child| {
            try compiler.compileNode(child);
        }
    }
}
```

---

## 🎯 Propuesta 3: Sintaxis Alternativa - for...of (Opcional)

### Descripción
Agregar soporte para sintaxis JavaScript nativa `for...of`

### Tokenizer
Agregar nuevo token:
```zig
pub const TokenType = enum {
    // ... existentes ...
    For,  // Nuevo token
};
```

### Parser
```zig
fn parseForLoop(self: *Parser) anyerror!*ast.AstNode {
    try self.advance(); // consume 'for'

    const iterator = self.current.value;
    try self.advance();

    _ = try self.expect(.Of); // 'of' keyword

    // Parse iterable expression
    var iterable = collectExpression();

    // ... similar a parseLoop ...
}
```

### Ejemplos
```pug
for item of items.filter(x => x.active)
  li= item.name

for key in Object.keys(user)
  p= key

for [key, value] of Object.entries(user)
  p #{key}: #{value}
```

---

## 🎯 Propuesta 4: Helpers de Loop (lodash style)

### Descripción
Si cargamos lodash en el runtime, podemos usar sus utilidades:

### Ejemplos

```pug
// Contexto: lodash pre-cargado como '_'

// GroupBy
each group in _.groupBy(items, 'category')
  h3= group.category
  each item in group.items
    li= item.name

// Chunk (dividir en grupos)
each chunk in _.chunk(items, 3)
  .row
    each item in chunk
      .col= item

// SortBy múltiple
each item in _.sortBy(items, ['priority', 'name'])
  li= item.name

// Unique
each tag in _.uniq(tags)
  span.tag= tag
```

---

## 📊 Comparación de Propuestas

| Propuesta | Complejidad | Potencia | Retrocompat | Recomendación |
|-----------|-------------|----------|-------------|---------------|
| 1. Expresiones JS en iterable | 🟢 Baja | 🟢 Alta | ✅ 100% | **⭐ Implementar primero** |
| 2. Condiciones JS en while | 🟢 Baja | 🟢 Alta | ✅ 100% | **⭐ Implementar primero** |
| 3. Sintaxis for...of | 🟡 Media | 🟡 Media | ⚠️ Nueva sintaxis | Opcional (Paso futuro) |
| 4. Helpers lodash | 🟢 Baja | 🟢 Alta | ✅ 100% | Si cargamos lodash |

---

## 🚀 Plan de Implementación Recomendado

### Fase 1: Runtime Evaluation (Paso 9)
1. ✅ Integrar QuickJS
2. ✅ Crear JsRuntime con eval()
3. ✅ Cargar librerías (voca, numeral, day, **lodash**)
4. ✅ Conversión de tipos Zig ↔ JS

### Fase 2: Loop Enhancement (Parte del Paso 11 - Compiler)
1. Mejorar parseLoop() para parsear correctamente iterator/index
2. Compilar loops evaluando `iterable` con runtime.eval()
3. Inyectar variables (iterator, index) en contexto JS para cada iteración
4. Soportar expresiones JS complejas

### Fase 3: Tests
```zig
test "loop - filter with JavaScript" {
    const source =
        \\each item in items.filter(x => x.active)
        \\  li= item.name
    ;
    const context = .{
        .items = .{
            .{ .active = true, .name = "A" },
            .{ .active = false, .name = "B" },
        },
    };

    const html = try render(source, context);
    try std.testing.expectEqualStrings("<li>A</li>", html);
}
```

---

## 💡 Ventajas de este Enfoque

1. **Retrocompatibilidad 100%**:
   - `each item in items` sigue funcionando
   - `items` se evalúa como JavaScript → accede al contexto

2. **Potencia incremental**:
   - Nivel 1: `each item in items` (simple)
   - Nivel 2: `each item in items.slice(0, 5)` (métodos nativos)
   - Nivel 3: `each item in _.sortBy(items, 'name')` (lodash)
   - Nivel 4: `each item in items.filter(x => x.price > 100)` (arrow functions)

3. **Consistencia**:
   - Misma sintaxis para interpolaciones: `#{name.toLowerCase()}`
   - Misma sintaxis para loops: `each item in items.map(...)`
   - Misma sintaxis para condicionales: `if items.length > 0`

4. **Sin nuevos tokens**:
   - No necesita cambios en tokenizer
   - Solo mejora en parser (parsear iterator/index correctamente)
   - Toda la magia sucede en el compiler con runtime.eval()

---

## 🎓 Ejemplo Completo

```pug
//- Contexto: {
//-   products: [
//-     {name: "Laptop", price: 1200, category: "electronics", active: true},
//-     {name: "Mouse", price: 25, category: "electronics", active: true},
//-     {name: "Desk", price: 300, category: "furniture", active: false}
//-   ]
//- }

h1 Active Electronics

//- Filtro + Sort en una expresión
each product in products.filter(p => p.active && p.category === 'electronics').sort((a,b) => a.price - b.price)
  .product
    h3= product.name
    p Price: #{numeral(product.price).format('$0,0')}

//- Con índice
each product, i in products.slice(0, 3)
  p #{i + 1}. #{product.name}

//- Lodash groupBy
each group in _.groupBy(products, 'category')
  section
    h2= group[0].category
    each product in group
      p= product.name
```

---

## ✅ Decisión Recomendada

**Implementar Propuestas 1 y 2** en el Paso 11 (Compiler):
- ✅ Expresiones JavaScript en `iterable`
- ✅ Condiciones JavaScript en `while`
- ✅ Cargar lodash en runtime (opcional pero recomendado)
- ⏸️ Posponer sintaxis `for...of` para versión futura

¿Estás de acuerdo con este enfoque?
