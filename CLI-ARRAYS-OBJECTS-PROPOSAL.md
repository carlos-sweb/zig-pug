# Propuesta: Arrays y Objetos en CLI

## Problema Actual

Actualmente el CLI de `zpug` soporta:

```bash
# ✅ Valores simples
zpug template.pug --var name=Alice --var age=30 --var active=true

# ✅ Todo desde archivo JSON
zpug template.pug --vars data.json
```

**Limitación:** No se pueden pasar arrays u objetos individuales sin crear un archivo JSON completo.

## Casos de Uso Reales

### Caso 1: Lista rápida de items
```bash
# Quiero renderizar una lista sin crear archivo JSON
zpug list.pug --array items=apple,banana,orange
```

### Caso 2: Configuración con objeto simple
```bash
# Pasar configuración de usuario
zpug profile.pug --object user='{"name":"Alice","age":30,"role":"admin"}'
```

### Caso 3: Mix de tipos
```bash
# Combinar valores simples con arrays
zpug template.pug \
  --var title="Mi Página" \
  --var count=5 \
  --array tags=javascript,zig,performance \
  --object author='{"name":"Carlos","email":"carlos@example.com"}'
```

### Caso 4: Arrays de objetos (JSON inline)
```bash
# Lista de productos
zpug products.pug --json products='[
  {"name":"Laptop","price":999},
  {"name":"Mouse","price":25}
]'
```

### Caso 5: Nested objects
```bash
# Objeto con propiedades anidadas
zpug company.pug --json company='{
  "name":"Tech Corp",
  "location":{"city":"SF","country":"USA"},
  "founded":2010
}'
```

## Propuestas de Sintaxis

### Opción A: Sintaxis Específica por Tipo (RECOMENDADA)

**Ventajas:** Clara, explícita, fácil de entender
**Desventajas:** Más flags

```bash
# Arrays simples (CSV format)
--array <key>=<value1>,<value2>,<value3>

# Objetos/Arrays complejos (JSON format)
--json <key>=<json-string>

# Valores simples (como antes)
--var <key>=<value>
```

**Ejemplos:**
```bash
# Array simple
zpug template.pug --array items=apple,banana,orange

# Array de números
zpug template.pug --array scores=95,87,92,88

# JSON para estructuras complejas
zpug template.pug --json user='{"name":"Alice","age":30}'

# Array de objetos
zpug template.pug --json products='[{"id":1,"name":"Laptop"},{"id":2,"name":"Mouse"}]'

# Mix completo
zpug template.pug \
  --var title="Dashboard" \
  --var version=2.0 \
  --array tags=prod,stable,v2 \
  --json user='{"name":"Alice","role":"admin"}' \
  --json stats='{"views":1500,"users":42}'
```

### Opción B: Auto-detección JSON en --var

**Ventajas:** Un solo flag, simple
**Desventajas:** Puede ser ambiguo, más lógica de parsing

```bash
# Auto-detecta que es JSON array
--var items='["apple","banana","orange"]'

# Auto-detecta que es JSON object
--var user='{"name":"Alice","age":30}'

# String normal
--var title="My Page"
```

**Ejemplos:**
```bash
zpug template.pug \
  --var title="Dashboard" \
  --var items='["a","b","c"]' \
  --var user='{"name":"Alice"}'
```

### Opción C: Híbrido (BALANCE)

**Ventajas:** Flexibilidad + claridad
**Desventajas:** Más opciones para aprender

```bash
# Arrays simples: sintaxis CSV
--array <key>=<val1>,<val2>,...

# JSON explícito (arrays complejos, objetos)
--json <key>=<json-string>

# Auto-detección en --var (backward compatible)
--var <key>=<value>  # Si empieza con { o [, parsea como JSON
```

**Ejemplos:**
```bash
# Simple y rápido
zpug template.pug --array items=a,b,c

# Explícito para estructuras complejas
zpug template.pug --json user='{"name":"Alice","age":30}'

# Auto-detección (backward compatible)
zpug template.pug --var tags='["javascript","zig"]'
```

## Implementación Técnica

### Cambios en CLI (src/cli.zig)

#### 1. Actualizar CliOptions

```zig
const CliOptions = struct {
    // ... campos existentes ...

    // Nuevos campos
    json_variables: std.StringHashMap([]const u8),  // Para --json
    array_variables: std.StringHashMap([]const u8), // Para --array

    pub fn init(allocator: std.mem.Allocator) CliOptions {
        return .{
            // ... existentes ...
            .json_variables = std.StringHashMap([]const u8).init(allocator),
            .array_variables = std.StringHashMap([]const u8).init(allocator),
        };
    }

    pub fn deinit(self: *CliOptions) void {
        // ... existentes ...
        self.json_variables.deinit();
        self.array_variables.deinit();
    }
};
```

#### 2. Parsear nuevos argumentos

```zig
// En parseArguments()
else if (std.mem.eql(u8, arg, "--json")) {
    const json_str = args.next() orelse {
        std.debug.print("Error: --json requires key=json_value\n", .{});
        std.process.exit(3);
    };

    var it = std.mem.splitScalar(u8, json_str, '=');
    const key = it.next() orelse {
        std.debug.print("Error: --json format is key=json_value\n", .{});
        std.process.exit(3);
    };
    const json_value = it.rest();

    if (json_value.len == 0) {
        std.debug.print("Error: --json requires a JSON value\n", .{});
        std.process.exit(3);
    }

    try options.json_variables.put(key, json_value);
}
else if (std.mem.eql(u8, arg, "--array")) {
    const array_str = args.next() orelse {
        std.debug.print("Error: --array requires key=val1,val2,...\n", .{});
        std.process.exit(3);
    };

    var it = std.mem.splitScalar(u8, array_str, '=');
    const key = it.next() orelse {
        std.debug.print("Error: --array format is key=val1,val2,...\n", .{});
        std.process.exit(3);
    };
    const csv_values = it.rest();

    if (csv_values.len == 0) {
        std.debug.print("Error: --array requires comma-separated values\n", .{});
        std.process.exit(3);
    }

    try options.array_variables.put(key, csv_values);
}
```

#### 3. Procesar variables JSON

```zig
fn setJsonVariable(
    allocator: std.mem.Allocator,
    key: []const u8,
    json_str: []const u8,
    js_runtime: *runtime.JsRuntime,
) !void {
    // Parsear JSON
    const parsed = std.json.parseFromSlice(
        std.json.Value,
        allocator,
        json_str,
        .{}
    ) catch |err| {
        std.debug.print("Error: Invalid JSON for key '{s}': {}\n", .{ key, err });
        std.debug.print("JSON: {s}\n", .{json_str});
        return err;
    };
    defer parsed.deinit();

    const value = parsed.value;

    // Determinar tipo y establecer
    switch (value) {
        .string => |str| try js_runtime.setString(key, str),
        .integer => |num| try js_runtime.setNumber(key, @floatFromInt(num)),
        .float => |num| try js_runtime.setNumber(key, num),
        .bool => |b| try js_runtime.setBool(key, b),
        .array => |arr| try js_runtime.setArrayFromJson(key, arr.items),
        .object => |obj| try js_runtime.setObjectFromJson(key, obj),
        .null => {
            // Opcional: soportar null
            try js_runtime.setString(key, "null");
        },
    }
}
```

#### 4. Procesar arrays CSV

```zig
fn setArrayFromCsv(
    allocator: std.mem.Allocator,
    key: []const u8,
    csv_str: []const u8,
    js_runtime: *runtime.JsRuntime,
) !void {
    var items = std.ArrayList(std.json.Value).init(allocator);
    defer items.deinit();

    // Split por comas
    var it = std.mem.splitScalar(u8, csv_str, ',');
    while (it.next()) |item_str| {
        const trimmed = std.mem.trim(u8, item_str, " \t");

        if (trimmed.len == 0) continue;

        // Intentar parsear como número
        if (std.fmt.parseFloat(f64, trimmed)) |num| {
            try items.append(.{ .float = num });
        } else |_| {
            // Es string
            const str_copy = try allocator.dupe(u8, trimmed);
            try items.append(.{ .string = str_copy });
        }
    }

    // Convertir a slice y establecer
    try js_runtime.setArrayFromJson(key, items.items);
}
```

#### 5. Integrar en main()

```zig
// Después de setVariablesFromMap()

// Procesar arrays CSV
var array_it = options.array_variables.iterator();
while (array_it.next()) |entry| {
    setArrayFromCsv(
        allocator,
        entry.key_ptr.*,
        entry.value_ptr.*,
        js_runtime
    ) catch |err| {
        std.debug.print("Error setting array '{s}': {}\n", .{ entry.key_ptr.*, err });
        std.process.exit(1);
    };
}

// Procesar JSON
var json_it = options.json_variables.iterator();
while (json_it.next()) |entry| {
    setJsonVariable(
        allocator,
        entry.key_ptr.*,
        entry.value_ptr.*,
        js_runtime
    ) catch |err| {
        std.debug.print("Error setting JSON '{s}': {}\n", .{ entry.key_ptr.*, err });
        std.process.exit(1);
    };
}
```

#### 6. Actualizar help text

```zig
const help_text =
    \\...
    \\VARIABLES:
    \\  --var <key>=<value>       Set simple variable (string/number/boolean)
    \\  --array <key>=<val1>,<val2>,...   Set array from CSV values
    \\  --json <key>=<json>       Set variable from JSON string
    \\  --vars <file.json>        Load all variables from JSON file
    \\
    \\EXAMPLES:
    \\  # Simple variables
    \\  zpug template.pug --var name=Alice --var age=30
    \\
    \\  # Arrays (CSV format)
    \\  zpug template.pug --array items=apple,banana,orange
    \\  zpug template.pug --array scores=95,87,92
    \\
    \\  # JSON objects
    \\  zpug template.pug --json user='{"name":"Alice","age":30}'
    \\
    \\  # JSON arrays
    \\  zpug template.pug --json items='["apple","banana","orange"]'
    \\
    \\  # Mixed types
    \\  zpug template.pug \
    \\    --var title="My Page" \
    \\    --array tags=prod,stable \
    \\    --json user='{"name":"Alice","role":"admin"}'
    \\
    \\  # Complex structures
    \\  zpug template.pug --json products='[
    \\    {"id":1,"name":"Laptop","price":999},
    \\    {"id":2,"name":"Mouse","price":25}
    \\  ]'
    \\
;
```

## Ejemplos de Uso Completos

### Ejemplo 1: Blog post con tags

**Template (blog-post.pug):**
```pug
doctype html
html
  head
    title= title
  body
    article
      h1= title
      p.author Author: #{author}

      ul.tags
        each tag in tags
          li.tag= tag

      div.content= content
```

**Comando:**
```bash
zpug blog-post.pug \
  --var title="Introduction to Zig" \
  --var author="Carlos" \
  --array tags=programming,zig,performance,systems \
  --var content="Zig is a general-purpose programming language..." \
  -o blog-post.html
```

### Ejemplo 2: Lista de productos

**Template (products.pug):**
```pug
doctype html
html
  body
    h1 Product Catalog

    div.products
      each product in products
        div.product
          h2= product.name
          p Price: $#{product.price}
          p Stock: #{product.stock}
          if product.discount
            p.discount Discount: #{product.discount}%
```

**Comando:**
```bash
zpug products.pug --json products='[
  {"name":"Laptop","price":999,"stock":5,"discount":10},
  {"name":"Mouse","price":25,"stock":50},
  {"name":"Keyboard","price":75,"stock":20,"discount":5}
]' -o products.html
```

### Ejemplo 3: Página de equipo

**Template (team.pug):**
```pug
doctype html
html
  body
    h1= company.name
    p Location: #{company.location}

    h2 Team Members
    each member in members
      div.member
        h3= member.name
        p Role: #{member.role}
        p Email: #{member.email}
```

**Comando:**
```bash
zpug team.pug \
  --json company='{"name":"Tech Corp","location":"San Francisco"}' \
  --json members='[
    {"name":"Alice","role":"CEO","email":"alice@tech.com"},
    {"name":"Bob","role":"CTO","email":"bob@tech.com"},
    {"name":"Carol","role":"CFO","email":"carol@tech.com"}
  ]' \
  -o team.html
```

### Ejemplo 4: Dashboard con estadísticas

**Template (dashboard.pug):**
```pug
doctype html
html
  body
    h1 Dashboard

    div.stats
      div.stat
        h3 Users
        p= stats.users
      div.stat
        h3 Revenue
        p $#{stats.revenue}
      div.stat
        h3 Growth
        p #{stats.growth}%

    h2 Recent Activity
    ul
      each activity in recentActivity
        li #{activity}
```

**Comando:**
```bash
zpug dashboard.pug \
  --json stats='{"users":1250,"revenue":45000,"growth":23.5}' \
  --array recentActivity="New user registered","Product purchased","Support ticket resolved" \
  -o dashboard.html
```

### Ejemplo 5: Configuración multi-idioma

**Template (i18n.pug):**
```pug
doctype html
html(lang=lang)
  head
    title= translations.title
  body
    h1= translations.welcome
    p= translations.description

    ul.menu
      each item in translations.menu
        li= item
```

**Comando (Español):**
```bash
zpug i18n.pug \
  --var lang=es \
  --json translations='{
    "title":"Mi Aplicación",
    "welcome":"Bienvenido",
    "description":"Esta es una aplicación multiidioma",
    "menu":["Inicio","Productos","Contacto"]
  }' \
  -o index-es.html
```

**Comando (English):**
```bash
zpug i18n.pug \
  --var lang=en \
  --json translations='{
    "title":"My Application",
    "welcome":"Welcome",
    "description":"This is a multilingual application",
    "menu":["Home","Products","Contact"]
  }' \
  -o index-en.html
```

## Prioridad de Variables

Si se especifica la misma variable con diferentes flags:

```bash
zpug template.pug \
  --var name=John \
  --json name='"Alice"' \
  --vars data.json
```

**Orden de precedencia (último gana):**
1. `--vars file.json` (carga primero)
2. `--var` (sobrescribe)
3. `--array` (sobrescribe)
4. `--json` (sobrescribe, último)

## Manejo de Errores

### JSON inválido
```bash
zpug template.pug --json user='not valid json'
# Error: Invalid JSON for key 'user': error.UnexpectedToken
# JSON: not valid json
```

### Array vacío
```bash
zpug template.pug --array items=
# Error: --array requires comma-separated values
```

### Comillas mal escapadas
```bash
# Problema: comillas dentro del JSON
zpug template.pug --json user='{"name":"O'Brien"}'
#                                        ^ error

# Solución 1: Escapar comillas
zpug template.pug --json user='{"name":"O'\''Brien"}'

# Solución 2: Usar archivo
echo '{"name":"O'\''Brien"}' > user.json
zpug template.pug --vars user.json
```

## Ventajas de esta Propuesta

1. **✅ Simplicidad**: Arrays simples son fáciles con CSV
2. **✅ Potencia**: JSON para estructuras complejas
3. **✅ Backward compatible**: `--var` sigue funcionando igual
4. **✅ Flexibilidad**: Puedes combinar todos los métodos
5. **✅ Sin archivos temporales**: Todo inline
6. **✅ Shell scripting friendly**: Fácil de usar en scripts
7. **✅ Claro y explícito**: Cada flag indica qué tipo de dato

## Comparación con Alternativas

### Otras herramientas

**Handlebars CLI:**
```bash
# Solo soporta archivos JSON
handlebars template.hbs -d data.json
```

**Mustache:**
```bash
# Solo archivos JSON
mustache data.json template.mustache
```

**Pug (oficial):**
```bash
# No tiene variables desde CLI, requiere JS
pug --obj '{"name":"Alice"}' template.pug
```

**zig-pug (propuesto):**
```bash
# Múltiples opciones flexibles
zpug template.pug \
  --var name=Alice \
  --array items=a,b,c \
  --json user='{"name":"Alice"}' \
  --vars data.json
```

## Próximos Pasos

1. **Implementar en src/cli.zig**:
   - Añadir parsing de `--array` y `--json`
   - Funciones de procesamiento
   - Tests

2. **Actualizar documentación**:
   - README.md
   - docs/en/CLI.md
   - Ejemplos

3. **Tests**:
   - Arrays CSV
   - JSON válido/inválido
   - Precedencia de variables
   - Edge cases

4. **Release**:
   - Bump version a 0.4.0
   - Changelog
   - Documentación de migración

## Recomendación Final

**Implementar Opción A (Sintaxis Específica)** con:

- `--array key=val1,val2,...` para arrays simples (CSV)
- `--json key=json_string` para estructuras complejas
- `--var key=value` para valores simples (sin cambios)
- `--vars file.json` para archivos (sin cambios)

**Razones:**
1. Clara y explícita (no ambigua)
2. Fácil de documentar y aprender
3. Cubre todos los casos de uso
4. Buen balance simplicidad/potencia
5. Shell-friendly

¿Quieres que implemente esta propuesta?
