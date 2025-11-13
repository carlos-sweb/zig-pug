# Paso 13: Compilación en Tiempo de Compilación

## Objetivo
Aprovechar capacidades comptime de Zig para máximo rendimiento.

---

## Tareas

### 13.1 API Comptime

```zig
pub fn compileTemplate(comptime template: []const u8) type {
    return struct {
        pub fn render(context: Context) ![]const u8 {
            // Template compilado en comptime
            // Genera código Zig optimizado
        }
    };
}
```

### 13.2 Parsing en Comptime

```zig
pub fn parseComptime(comptime source: []const u8) *AstNode {
    @setEvalBranchQuota(10000);
    // Parse en comptime
    // AST generado en comptime
}
```

### 13.3 Generación de Código Zig

Convertir template en funciones Zig generadas:

```pug
div.container
  p= message
```

Genera:

```zig
pub fn render(context: Context) ![]const u8 {
    var output = std.ArrayList(u8).init(allocator);
    try output.appendSlice("<div class=\"container\">");
    try output.appendSlice("<p>");
    const message = context.get("message");
    try output.appendSlice(message.String);
    try output.appendSlice("</p>");
    try output.appendSlice("</div>");
    return output.toOwnedSlice();
}
```

### 13.4 Benchmarks

Comparar:
- Runtime parsing + compilation
- Comptime compilation
- Pure string concatenation

### 13.5 Limitaciones

Documentar qué funciona en comptime y qué no:
- ✓ Templates estáticos
- ✓ Estructura conocida
- ✗ Includes dinámicos
- ✗ Datos no conocidos en comptime

---

## Entregables
- Soporte comptime funcional
- API documentada
- Benchmarks comparativos

---

## Siguiente Paso
**14-filters.md** para sistema de filtros.
