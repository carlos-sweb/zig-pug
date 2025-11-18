# Loops, Includes y Cache en zig-pug

Esta guía explica las características avanzadas de zig-pug para loops, includes y caché de templates.

## Loops (each/for)

### Sintaxis Básica

```zpug
each item in items
  li #{item}
```

**HTML generado:**
```html
<li>Item 1</li>
<li>Item 2</li>
<li>Item 3</li>
```

### Loop con Índice

```zpug
each fruit, index in fruits
  li #{index}: #{fruit}
```

**HTML generado:**
```html
<li>0: Apple</li>
<li>1: Banana</li>
<li>2: Orange</li>
```

### Else para Arrays Vacíos

```zpug
each item in emptyArray
  li #{item}
else
  p No hay items disponibles
```

**HTML (si el array está vacío):**
```html
<p>No hay items disponibles</p>
```

### Configurar Arrays en el Runtime

**En Zig:**
```zig
// Establecer array en JavaScript
_ = try runtime.eval("var items = ['Apple', 'Banana', 'Orange']");
```

**En Node.js:**
```javascript
const zigpug = require('zig-pug');

const html = zigpug.compile(template, {
    items: ['Apple', 'Banana', 'Orange']
});
```

### Ejemplo Completo

```zpug
doctype html
html
  body
    h1 Lista de Usuarios
    ul
      each user in users
        li.user
          strong #{user.name}
          span  - #{user.email}

    h2 Productos
    each product, i in products
      div.product
        span.number #{i + 1}.
        span.name #{product}
    else
      p No hay productos
```

---

## Includes

### Sintaxis

```zpug
include path/to/file.zpug
```

### Estructura de Archivos

```
project/
├── views/
│   ├── index.zpug        # Template principal
│   └── partials/
│       ├── header.zpug   # Parcial del header
│       └── footer.zpug   # Parcial del footer
```

### Template Principal

```zpug
// views/index.zpug
doctype html
html
  head
    title #{title}
  body
    include partials/header.zpug

    main.content
      h1 #{title}
      p #{content}

    include partials/footer.zpug
```

### Parcial Header

```zpug
// views/partials/header.zpug
header.main-header
  nav
    a.logo(href="/") Mi Sitio
    ul.menu
      li: a(href="/") Home
      li: a(href="/about") About
```

### Parcial Footer

```zpug
// views/partials/footer.zpug
footer
  p &copy; 2024 Mi Sitio
```

### Configurar Base Path

Para que los includes funcionen correctamente, configura el base path:

**En Zig:**
```zig
var compiler = try Compiler.init(allocator, runtime);
compiler.setBasePath("views/index.zpug");
```

**En CLI:**
```bash
zig-pug views/index.zpug -o output.html
```

El CLI automáticamente usa el directorio del archivo como base path.

### Includes Anidados

Los includes pueden contener otros includes:

```zpug
// layout.zpug
doctype html
html
  head
    include partials/meta.zpug
  body
    include partials/header.zpug
    block content
    include partials/footer.zpug
```

---

## Cache de Templates

El cache almacena templates compilados para evitar re-parsear y re-compilar.

### Beneficios

- ⚡ **Performance**: Evita re-parsear templates sin cambios
- 🔄 **Invalidación automática**: Detecta cambios por hash del source
- 📊 **Estadísticas**: Hit rate, misses, número de entradas

### Uso en Zig

```zig
const cache = @import("cache.zig");

// Crear cache (0 = sin límite, o especificar máximo de entradas)
var template_cache = cache.TemplateCache.init(allocator, 100);
defer template_cache.deinit();

// Crear compiler con cache
var compiler = try Compiler.init(allocator, runtime);
compiler.setCache(&template_cache);

// Compilar - se cachea automáticamente
const html = try compiler.compile(ast);

// Ver estadísticas
const stats = template_cache.stats();
std.debug.print("Hits: {}, Misses: {}, Hit Rate: {d:.2}%\n",
    .{ stats.hits, stats.misses, stats.hit_rate * 100 });
```

### Invalidación Manual

```zig
// Invalidar un template específico
template_cache.invalidate("views/index.zpug");

// Limpiar todo el cache
template_cache.clear();
```

### Uso con Includes

Cuando usas includes, el cache almacena cada parcial por separado:

```zig
var compiler = try Compiler.init(allocator, runtime);
compiler.setBasePath("views/index.zpug");
compiler.setCache(&template_cache);

// Los includes se cachean individualmente
const html = try compiler.compile(ast);

// Cada include tiene su propia entrada en cache:
// - "views/partials/header.zpug"
// - "views/partials/footer.zpug"
```

### Cache en Node.js

En Node.js, el cache es manejado internamente. Puedes habilitarlo con opciones:

```javascript
const zigpug = require('zig-pug');
const { PugCompiler } = zigpug;

const compiler = new PugCompiler();
compiler.enableCache(100); // Máximo 100 entradas

// Compilar múltiples veces - usa cache
for (let i = 0; i < 1000; i++) {
    compiler.compile(template);
}

// Ver estadísticas
const stats = compiler.cacheStats();
console.log(`Hit rate: ${stats.hitRate * 100}%`);
```

### Configuración del Cache

| Parámetro | Descripción | Default |
|-----------|-------------|---------|
| `max_size` | Número máximo de entradas (0 = ilimitado) | 0 |
| Eviction | LRU (Least Recently Used) por timestamp | - |
| Validación | Hash del source code | - |

### Ejemplo de Performance

```zig
const iterations = 10000;

// Sin cache
var start = std.time.nanoTimestamp();
for (0..iterations) |_| {
    // Parse + compile cada vez
}
var no_cache_time = std.time.nanoTimestamp() - start;

// Con cache
var template_cache = cache.TemplateCache.init(allocator, 0);
start = std.time.nanoTimestamp();
for (0..iterations) |_| {
    // Solo compila la primera vez
}
var with_cache_time = std.time.nanoTimestamp() - start;

// Resultado típico: 10-50x más rápido con cache
```

---

## Ejemplos Completos

### Ejemplo 1: Blog con Loops e Includes

```zpug
// views/blog.zpug
doctype html
html
  head
    title #{blogTitle}
  body
    include partials/header.zpug

    main.blog
      h1 #{blogTitle}

      each post in posts
        article.post
          h2 #{post.title}
          p.meta Por #{post.author} - #{post.date}
          p #{post.excerpt}
          a(href="/post/#{post.id}") Leer más
      else
        p No hay posts disponibles

    include partials/footer.zpug
```

### Ejemplo 2: E-commerce con Cache

```zig
// Servidor con cache de templates
var template_cache = cache.TemplateCache.init(allocator, 1000);
defer template_cache.deinit();

fn handleRequest(path: []const u8) ![]const u8 {
    var compiler = try Compiler.init(allocator, runtime);
    defer compiler.deinit();

    compiler.setBasePath(path);
    compiler.setCache(&template_cache);

    const ast = try parseTemplate(path);
    return try compiler.compile(ast);
}

// Primera request: parse + compile (10ms)
// Siguientes requests: desde cache (0.1ms)
```

### Ejemplo 3: Lista Dinámica

```zpug
div.shopping-cart
  h2 Tu Carrito (#{items.length} items)

  if items.length > 0
    ul.cart-items
      each item, i in items
        li.cart-item
          span.number #{i + 1}.
          span.name #{item.name}
          span.price $#{item.price}
          span.qty x#{item.quantity}

    div.total
      strong Total: $#{total}
  else
    p.empty Tu carrito está vacío
    a(href="/products") Ver productos
```

---

## Limitaciones Conocidas

### Loops

- Solo itera sobre arrays JavaScript
- No soporta objetos directamente (usar `Object.keys()`)
- El iterable debe tener propiedad `.length`

### Includes

- Paths relativos al archivo actual
- No soporta includes dinámicos (path debe ser literal)
- Máximo 1MB por archivo incluido

### Cache

- Cache en memoria (se pierde al reiniciar)
- No soporta cache distribuido
- Eviction simple (oldest first)

---

## Mejores Prácticas

### 1. Organizar Parciales

```
views/
├── layouts/
│   └── base.zpug
├── partials/
│   ├── header.zpug
│   ├── footer.zpug
│   └── sidebar.zpug
└── pages/
    ├── home.zpug
    └── about.zpug
```

### 2. Usar Cache en Producción

```zig
// Desarrollo: sin cache (recargar cambios)
if (is_development) {
    compiler.setCache(null);
} else {
    compiler.setCache(&production_cache);
}
```

### 3. Evitar Loops Anidados Profundos

```zpug
// ✅ Bueno
each category in categories
  h2 #{category.name}
  each product in category.products
    p #{product.name}

// ❌ Evitar (3+ niveles)
each a in items
  each b in a.children
    each c in b.children
      each d in c.children  // Muy profundo
```

### 4. Parciales Pequeños y Reutilizables

```zpug
// partials/button.zpug
button.btn(class=type)= text

// Uso
include partials/button.zpug
```

---

## Recursos

- **Ejemplos**: `examples/loops.zpug`, `examples/includes.zpug`
- **Tests**: `src/compiler.zig` (tests de loops y cache)
- **API Reference**: [docs/API-REFERENCE.md](API-REFERENCE.md)

---

**¡Disfruta de los loops, includes y cache en zig-pug!** 🚀
