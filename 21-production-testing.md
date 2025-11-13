# Paso 21: Testing en Producción

## Objetivo
Validar el proyecto en casos de uso reales y prepararlo para producción.

---

## Tareas

### 21.1 Proyectos de Prueba Reales

Crear proyectos completos:
- Blog estático
- Landing page
- Dashboard admin
- Documentación site

### 21.2 Testing de Carga

```zig
test "load test - 10000 concurrent renders" {
    var threads: [10]std.Thread = undefined;

    for (&threads) |*thread| {
        thread.* = try std.Thread.spawn(.{}, renderWorker, .{});
    }

    for (threads) |thread| {
        thread.join();
    }
}
```

### 21.3 Testing de Stress

- Memoria limitada
- CPU limitado
- Templates muy grandes
- Datos masivos

### 21.4 Testing de Edge Cases

- Templates vacíos
- UTF-8 complejo
- Comentarios malformados
- Nesting extremo
- Nombres de variables raros

### 21.5 Validación de Seguridad

#### XSS Prevention
```zig
test "security - XSS prevention" {
    const template = "p= user_input";
    const data = "[user]\nuser_input = \"<script>alert('xss')</script>\"";

    const result = try render(template, data);
    try testing.expect(!std.mem.containsAtLeast(u8, result, 1, "<script>"));
    try testing.expect(std.mem.containsAtLeast(u8, result, 1, "&lt;script&gt;"));
}
```

#### JavaScript Sandbox
- Timeout en ejecución
- Sin acceso a filesystem
- Sin acceso a network

#### TOML Injection
- Validar que TOML malicioso no cause crashes
- Límites de recursión

### 21.6 Code Review Exhaustivo

- Revisar TODO comments
- Verificar error handling
- Confirmar memory safety
- Validar edge cases

### 21.7 Fuzzing

```zig
test "fuzz - random templates" {
    var prng = std.rand.DefaultPrng.init(0);
    const random = prng.random();

    var i: usize = 0;
    while (i < 1000) : (i += 1) {
        const template = try generateRandomTemplate(random);
        _ = render(template, "") catch |err| {
            // Should never crash, only return errors
            try testing.expect(@errorReturnTrace() != null);
        };
    }
}
```

### 21.8 Fixing de Bugs

Mantener tracking de:
- Bugs encontrados
- Fixes aplicados
- Tests de regresión agregados

---

## Entregables
- Proyecto validado en producción
- Lista de bugs corregidos
- Reporte de testing
- Validación de seguridad

---

## Siguiente Paso
**22-packaging.md** para empaquetado y distribución.
