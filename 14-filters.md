# Paso 14: Sistema de Filtros

## Objetivo
Implementar sistema de filtros para transformación de contenido.

---

## Tareas

### 14.1 API de Filtros

```zig
pub const Filter = struct {
    name: []const u8,
    transformFn: *const fn([]const u8, std.StringHashMap([]const u8)) anyerror![]const u8,
};

pub const FilterRegistry = struct {
    filters: std.StringHashMap(Filter),

    pub fn register(self: *FilterRegistry, filter: Filter) !void {
        try self.filters.put(filter.name, filter);
    }

    pub fn apply(self: *FilterRegistry, name: []const u8, content: []const u8, options: std.StringHashMap([]const u8)) ![]const u8 {
        const filter = self.filters.get(name) orelse return error.UndefinedFilter;
        return try filter.transformFn(content, options);
    }
};
```

### 14.2 Filtros Built-in

#### Markdown
```zig
fn markdownFilter(content: []const u8, options: ...) ![]const u8 {
    // Integrar librería markdown
}
```

#### Escape/Unescape
```zig
fn escapeFilter(content: []const u8, options: ...) ![]const u8 {
    // HTML escape
}
```

#### Upper/Lower
```zig
fn upperFilter(content: []const u8, options: ...) ![]const u8 {
    // To uppercase
}
```

### 14.3 Filtros Personalizados

```zig
var registry = FilterRegistry.init(allocator);
try registry.register(.{
    .name = "custom",
    .transformFn = myCustomFilter,
});
```

### 14.4 Includes con Filtros

```pug
include:markdown article.md
include:escape raw.html
```

---

## Entregables
- Sistema de filtros funcional
- Filtros built-in
- API para filtros custom
- Documentación

---

## Siguiente Paso
**15-includes-modules.md** para sistema robusto de includes.
