# Paso 18: Sistema de Testing y Examples

## Objetivo
Crear suite de tests exhaustiva y galería de ejemplos.

---

## Tareas

### 18.1 Tests Unitarios

Por cada módulo:
- tokenizer_test.zig
- parser_test.zig
- ast_test.zig
- compiler_test.zig
- runtime_test.zig
- toml_test.zig

### 18.2 Tests de Integración

End-to-end tests:
```zig
test "e2e - simple template" {
    const template = "div.container\n  p Hello World";
    const data = "";
    const expected = "<div class=\"container\"><p>Hello World</p></div>";

    var zigpug = ZigPug.init(testing.allocator, .{});
    const result = try zigpug.render(template, data);
    defer testing.allocator.free(result);

    try testing.expectEqualStrings(expected, result);
}
```

### 18.3 Tests de Regresión

Mantener suite de templates que han causado bugs.

### 18.4 Benchmarks

```zig
test "benchmark - render 1000 templates" {
    const start = std.time.nanoTimestamp();
    // Render 1000 times
    const end = std.time.nanoTimestamp();
    std.debug.print("Time: {d}ms\n", .{(end - start) / 1_000_000});
}
```

### 18.5 Galería de Ejemplos

#### Básico
```pug
doctype html
html
  head
    title Mi Sitio
  body
    h1 Bienvenido
```

#### Con TOML
```toml
[site]
title = "Mi Sitio"
```

```pug
h1= site.title
```

#### Loops
```pug
each item in items
  li= item.name
```

#### Mixins
```pug
mixin card(title, body)
  .card
    h2= title
    p= body

+card('Título', 'Contenido')
```

#### Herencia
```pug
// layout.pug
html
  head
    block head
  body
    block content

// page.pug
extends layout.pug

block head
  title Mi Página

block content
  h1 Contenido
```

### 18.6 Cobertura de Código

```bash
zig build test -Dtest-filter=* --summary all
```

Objetivo: >80% de cobertura

---

## Entregables
- Suite de tests completa
- Cobertura alta
- Galería de ejemplos documentados
- Benchmarks

---

## Siguiente Paso
**19-documentation.md** para documentación completa.
