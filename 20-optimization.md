# Paso 20: Optimización y Performance

## Objetivo
Optimizar rendimiento del proyecto mediante profiling y optimizaciones específicas.

---

## Tareas

### 20.1 Profiling de Rendimiento

```zig
const std = @import("std");

pub fn profile(comptime name: []const u8, func: anytype, args: anytype) !@TypeOf(@call(.auto, func, args)) {
    const start = std.time.nanoTimestamp();
    const result = try @call(.auto, func, args);
    const end = std.time.nanoTimestamp();

    std.debug.print("{s}: {d}ms\n", .{name, (end - start) / 1_000_000});
    return result;
}
```

Identificar hotpaths:
- Tokenization
- Parsing
- Compilation
- String operations

### 20.2 Optimización de Allocaciones

- Usar ArenaAllocator para operaciones batch
- Pool de objetos frecuentes (tokens, nodos AST)
- Reducir allocaciones en hot paths
- Zero-copy parsing donde sea posible

```zig
pub const TokenPool = struct {
    pool: std.ArrayList(Token),

    pub fn acquire(self: *TokenPool) !*Token {
        if (self.pool.items.len > 0) {
            return self.pool.pop();
        }
        return try self.allocator.create(Token);
    }

    pub fn release(self: *TokenPool, token: *Token) !void {
        try self.pool.append(token);
    }
};
```

### 20.3 Optimización de Strings

- String interning para identificadores comunes
- StringBuilder para construcción de HTML
- Evitar copias innecesarias

```zig
pub const StringInterner = struct {
    strings: std.StringHashMap([]const u8),

    pub fn intern(self: *StringInterner, str: []const u8) ![]const u8 {
        if (self.strings.get(str)) |interned| {
            return interned;
        }
        const copy = try self.allocator.dupe(u8, str);
        try self.strings.put(copy, copy);
        return copy;
    }
};
```

### 20.4 Optimización de Parser

- Predictive parsing
- Memoization para expresiones complejas
- Lazy evaluation

### 20.5 Benchmarks Comparativos

Comparar con:
- Pug (Node.js)
- Mustache
- Handlebars
- EJS

Métricas:
- Tiempo de parsing
- Tiempo de compilación
- Memoria utilizada
- Throughput (templates/segundo)

### 20.6 Optimizaciones Específicas

#### Cache de Templates
```zig
var cache = std.StringHashMap(*AstNode).init(allocator);
```

#### Inline de Mixins Simples
Detectar mixins que se usan una sola vez e inline

#### Eliminación de Código Muerto
Detectar bloques que nunca se ejecutan

### 20.7 Documentación de Best Practices

```markdown
# Performance Best Practices

## Template Design
- Evitar nesting profundo
- Usar mixins para reutilización
- Cachear templates compilados

## Data Preparation
- Preparar datos antes de render
- Evitar cálculos en templates
- Usar tipos TOML apropiados

## Production
- Habilitar cache
- Precompilar templates
- Usar comptime cuando posible
```

---

## Entregables
- Código optimizado
- Benchmarks comparativos
- Documentación de performance
- Best practices guide

---

## Siguiente Paso
**21-production-testing.md** para testing en producción.
