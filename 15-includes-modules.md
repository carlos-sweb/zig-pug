# Paso 15: Sistema de Includes y Módulos

## Objetivo
Implementar sistema robusto de includes con resolución de rutas y caching.

---

## Tareas

### 15.1 Resolución de Rutas

```zig
pub const PathResolver = struct {
    basedir: []const u8,
    current_file: []const u8,

    pub fn resolve(self: *PathResolver, path: []const u8) ![]const u8 {
        if (std.mem.startsWith(u8, path, "/")) {
            // Absolute path relative to basedir
            return std.fs.path.join(allocator, &.{self.basedir, path});
        } else {
            // Relative to current file
            const dir = std.fs.path.dirname(self.current_file) orelse ".";
            return std.fs.path.join(allocator, &.{dir, path});
        }
    }
};
```

### 15.2 Caching de Includes

```zig
pub const IncludeCache = struct {
    cache: std.StringHashMap([]const u8),

    pub fn get(self: *IncludeCache, path: []const u8) ?[]const u8 {
        return self.cache.get(path);
    }

    pub fn load(self: *IncludeCache, path: []const u8) ![]const u8 {
        if (self.get(path)) |content| return content;

        const content = try std.fs.cwd().readFileAlloc(allocator, path, 1024 * 1024);
        try self.cache.put(path, content);
        return content;
    }
};
```

### 15.3 Prevención de Includes Circulares

```zig
pub const IncludeStack = struct {
    stack: std.ArrayList([]const u8),

    pub fn push(self: *IncludeStack, path: []const u8) !void {
        for (self.stack.items) |item| {
            if (std.mem.eql(u8, item, path)) {
                return error.CircularInclude;
            }
        }
        try self.stack.append(path);
    }

    pub fn pop(self: *IncludeStack) void {
        _ = self.stack.pop();
    }
};
```

### 15.4 Tipos de Includes

- Pug files (compilar y renderizar)
- Text files (insertar como texto)
- Filtered includes (aplicar filtro)

---

## Entregables
- Sistema de includes completo
- Caching eficiente
- Detección de ciclos
- Tests

---

## Siguiente Paso
**16-template-inheritance.md** para herencia de templates.
