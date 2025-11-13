# Paso 10: Parser de TOML

## Objetivo
Implementar o integrar parser TOML para datos de entrada.

---

## Tareas

### 10.1 Evaluar Librerías TOML
- `zig-toml` (buscar en GitHub)
- `toml.zig`
- Implementación propia (si necesario)

### 10.2 Integración
- Agregar dependencia en `build.zig.zon`
- Crear wrapper si necesario

### 10.3 Estructura de Datos TOML

```zig
pub const TomlValue = union(enum) {
    String: []const u8,
    Integer: i64,
    Float: f64,
    Boolean: bool,
    Datetime: i64,
    Array: std.ArrayList(TomlValue),
    Table: std.StringHashMap(TomlValue),
};
```

### 10.4 Conversión TOML → Context
```zig
pub fn tomlToContext(allocator: std.mem.Allocator, toml: TomlValue) !Context {
    var ctx = Context.init(allocator);
    // Convertir TomlValue a Values del runtime
    return ctx;
}
```

### 10.5 API de Uso

```zig
const template = "div= user.name";
const data_toml =
    \\[user]
    \\name = "Juan"
    \\age = 30
;

const toml = try parseToml(allocator, data_toml);
const context = try tomlToContext(allocator, toml);
const html = try render(template, context);
```

### 10.6 Tests
- Parsear todos los tipos TOML
- Acceso a datos desde templates
- Arrays y tablas anidadas
- Manejo de errores

---

## Entregables
- Parser/integración TOML funcional
- Sistema de acceso a datos
- Documentación con ejemplos

---

## Siguiente Paso
**11-compiler-html.md** para compilar AST a HTML.
