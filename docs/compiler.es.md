# Compilador - Generación de HTML

El **Compilador** es la fase final del pipeline de compilación de zig-pug. Recorre el AST y genera salida HTML, manejando evaluación de JavaScript, composición de plantillas y características de seguridad.

## Descripción General

El compilador transforma un AST en HTML por:

- **Recorrido del árbol**: Recorrido en profundidad de nodos AST
- **Evaluación de expresiones**: Ejecución de código JavaScript via runtime mujs
- **Generación de HTML**: Conversión de nodos a cadenas HTML
- **Escapado de contenido**: Prevención de ataques XSS
- **Características de plantilla**: Mixins, includes, herencia
- **Manejo de errores**: Errores de compilación estructurados

## Arquitectura

### Ubicación: `src/compiler/`

```
src/compiler/
├── mod.zig        # Estructura Compiler principal y lógica de compilación
├── errors.zig     # Definiciones de tipos de error
├── escaping.zig   # Utilidades de escapado HTML/comentario
├── tests.zig      # Suite de pruebas del compilador
└── compile/       # Futuro: funciones de compilación por tipo de nodo
```

## Estructura del Compilador

### Estructura Compiler

```zig
pub const Compiler = struct {
    allocator: std.mem.Allocator,
    runtime: *JsRuntime,                     // Motor JavaScript
    output: std.ArrayList(u8),                // Buffer de salida HTML
    indent_level: usize,                      // Indentación actual
    pretty: bool,                             // Modo pretty-print
    mixins: std.StringHashMap(*AstNode),      // Definiciones de mixin
    base_path: ?[]const u8,                   // Ruta base para includes
    template_cache: ?*TemplateCache,          // Almacenamiento en caché opcional
    child_blocks: std.StringHashMap(ChildBlockInfo),  // Herencia de plantilla
    include_comments: bool,                   // Incluir comentarios HTML
    has_errors: bool,                         // Errores de compilación ocurrieron
    errors: std.ArrayList(CompilationError),  // Lista de errores
};
```

## Proceso de Compilación

### Flujo Principal

1. **Inicializar**: Crear compilador con runtime JavaScript
2. **Establecer contexto**: Agregar variables al alcance JS
3. **Compilar**: Recorrer AST y generar HTML
4. **Devolver**: Cadena HTML o error

### Compilación de Nodo

Cada tipo de nodo AST tiene una función de compilación:

```zig
compileNode(node)
  ├─> compileDocument()
  ├─> compileTag()
  ├─> compileText()
  ├─> compileInterpolation()
  ├─> compileCode()
  ├─> compileComment()
  ├─> compileConditional()
  ├─> compileLoop()
  ├─> compileCase()
  ├─> compileMixinCall()
  ├─> compileInclude()
  ├─> compileExtends()
  └─> compileBlock()
```

## Características de Compilación

### 1. Compilación de Etiqueta

Convierte nodos de etiqueta a elementos HTML:

**Entrada**:
```pug
div.container#main(data-value="test")
  p Hello
```

**Salida**:
```html
<div class="container" id="main" data-value="test"><p>Hello</p></div>
```

**Proceso**:
1. Emitir etiqueta de apertura: `<div`
2. Compilar atributos: ` class="container" id="main" data-value="test"`
3. Cerrar etiqueta de apertura: `>`
4. Compilar recursivamente hijos
5. Emitir etiqueta de cierre: `</div>`

### 2. Compilación de Atributo

Maneja diferentes tipos de atributo:

```pug
a(href="/home")              // Estático: href="/home"
a(href=link)                 // Expresión: evaluar 'link'
a(class="btn" disabled)      // Booleano: disabled (sin valor)
a(data-html!=content)        // Sin escapar: HTML sin procesar
```

**Seguridad**:
- Valores estáticos: Escapados en HTML
- Expresiones: Evaluadas, luego escapadas
- Sin escapar (`!=`): No escapado (¡úsalo con cuidado!)
- Booleano: Solo nombre de atributo

### 3. Texto e Interpolación

Texto simple y expresiones incrustadas:

```pug
p Hello #{name}              // Interpolación escapada
p !{rawHtml}                 // Sin escapar (HTML sin procesar)
| Plain text content
```

**Proceso**:
- Texto: Escapado en HTML por defecto
- `#{expr}`: Evaluar → escapar → salida
- `!{expr}`: Evaluar → salida (sin escapado)

### 4. Ejecución de Código

Evaluación de código JavaScript:

```pug
= user.name                  // Salida escapada
!= rawHtml                   // Salida sin escapar
- var x = 10                 // Ejecutar solo (sin salida)
```

**Runtime JavaScript**:
- Usa **mujs** (motor JavaScript ES5.1)
- Variables establecidas via `runtime.setVariable()`
- Expresiones evaluadas con `runtime.eval()`

### 5. Condicionales

Control de flujo if/else/unless:

```pug
if admin
  button Edit
else
  p View only
```

**Proceso**:
1. Evaluar condición: `runtime.eval("admin")`
2. Verificar si es verdadero
3. Compilar rama apropiada
4. `unless` invierte la lógica

### 6. Bucles

Iteración sobre arrays:

```pug
each item in items
  li= item

each item, index in items
  li #{index}: #{item}
```

**Proceso**:
1. Evaluar iterable: `runtime.eval("items")`
2. Verificar si es array
3. Para cada elemento:
   - Establecer variable iteradora: `runtime.setVariable("item", value)`
   - Establecer variable de índice (si se especifica)
   - Compilar cuerpo del bucle
4. Compilar rama else si array está vacío

### 7. Sentencias Case

Concordancia de estilo switch:

```pug
case color
  when 'red'
    p Red
  when 'blue', 'cyan'
    p Blue-ish
  default
    p Unknown
```

**Proceso**:
1. Evaluar expresión: `runtime.eval("color")`
2. Para cada cláusula when:
   - Verificar si valor coincide con cualquier valor when
   - Si coincide, compilar cuerpo y salir
3. Si no hay coincidencia, compilar cláusula default

### 8. Mixins

Bloques de plantilla reutilizables:

```pug
mixin article(title)
  article
    h1= title

+article("Hello World")
```

**Proceso**:
1. **Definición**: Almacenar mixin en mapa `mixins`
2. **Llamada**:
   - Buscar mixin por nombre
   - Establecer variables de parámetro
   - Compilar cuerpo de mixin
   - Restaurar alcance anterior

### 9. Includes

Incluir otras plantillas:

```pug
include header.pug
```

**Proceso**:
1. Resolver ruta relativa a `base_path`
2. Leer archivo incluido
3. Analizar plantilla incluida
4. Compilar AST incluido
5. Insertar resultado en salida

**Almacenamiento en caché**:
- Usa `template_cache` si se proporciona
- Evita re-analizar el mismo archivo

### 10. Herencia de Plantilla

Patrón extends/block:

**layout.pug**:
```pug
html
  body
    block content
      p Default
```

**page.pug**:
```pug
extends layout.pug

block content
  p Custom content
```

**Proceso**:
1. Analizar plantilla hijo
2. Recopilar definiciones de bloque
3. Analizar plantilla padre
4. Reemplazar/agregar/anteponer bloques
5. Compilar árbol final

## Características de Seguridad

### Escapado HTML

Previene ataques XSS escapando caracteres especiales:

```
&  →  &amp;
<  →  &lt;
>  →  &gt;
"  →  &quot;
'  →  &#39;
```

**Implementación**: `escaping.escapeHtml()`

**Cuándo se aplica**:
- Contenido de texto (siempre)
- Valores de atributo (siempre)
- Interpolaciones `#{expr}` (siempre)
- NO en `!{expr}` o `!=` (¡responsabilidad del usuario!)

### Escapado de Comentario

Previene inyección de comentario:

```
--  →  - -
```

Previene cierre prematuro de comentario: `<!-- comment --> <script>`

**Implementación**: `escaping.escapeComment()`

### Evaluación de Expresión

El código JavaScript se ejecuta en contexto mujs aislado:

- Sin acceso al sistema de archivos
- Sin acceso a la red
- Solo variables proporcionadas disponibles
- Puro cálculo

## Modos de Salida

### Modo Estándar (Minificado)

HTML mínimo, sin espacios en blanco:

```html
<div><p>Hello</p></div>
```

- Sin indentación
- Sin comentarios (`include_comments = false`)
- Tamaño de archivo más pequeño

### Modo Pretty

HTML legible con indentación:

```html
<div>
  <p>Hello</p>
</div>
```

- Seguimiento de indentación
- Comentarios incluidos (`include_comments = true`)
- Más fácil de depurar

Habilitar con:
```zig
compiler.pretty = true;
compiler.include_comments = true;
```

## Manejo de Errores

### Errores Estructurados

El compilador proporciona información de error detallada:

```zig
pub const CompilationError = struct {
    type: ErrorType,
    line: usize,
    message: [:0]const u8,
    detail: ?[:0]const u8,
    hint: ?[:0]const u8,
};
```

### Tipos de Error

- `LoopIterableEvalFailed`: No se puede evaluar iterable de bucle
- `ConditionalEvalFailed`: No se puede evaluar condición
- `InterpolationEvalFailed`: No se puede evaluar interpolación
- `AttributeEvalFailed`: No se puede evaluar valor de atributo
- `CodeExecutionFailed`: Error de JavaScript
- `CaseEvalFailed`: No se puede evaluar expresión case
- `MixinNotFound`: Mixin indefinido llamado
- `IncludeFileNotFound`: Archivo de include faltante
- `ExtendsFileNotFound`: Plantilla padre faltante

### Recolección de Errores

El compilador puede continuar en errores y recopilar todos los problemas:

```zig
const html = compiler.compile(ast) catch {
    for (compiler.errors.items) |err| {
        std.debug.print("Error at line {}: {s}\n", .{
            err.line,
            err.message
        });
        if (err.detail) |detail| {
            std.debug.print("  Detail: {s}\n", .{detail});
        }
        if (err.hint) |hint| {
            std.debug.print("  Hint: {s}\n", .{hint});
        }
    }
    return error.CompilationFailed;
};
```

## Uso de API

### Compilación Básica

```zig
const Compiler = @import("compiler/mod.zig").Compiler;
const JsRuntime = @import("runtime.zig").JsRuntime;

// Inicializar runtime JavaScript
var js_runtime = try JsRuntime.init(allocator);
defer js_runtime.deinit();

// Establecer variables
try js_runtime.setVariable("name", "John");
try js_runtime.setVariable("admin", true);

// Inicializar compilador
var compiler = try Compiler.init(allocator, js_runtime);
defer compiler.deinit();

// Compilar AST a HTML
const html = try compiler.compile(ast);
defer allocator.free(html);
```

### Con Pretty Printing

```zig
var compiler = try Compiler.init(allocator, js_runtime);
defer compiler.deinit();

compiler.pretty = true;
compiler.include_comments = true;

const html = try compiler.compile(ast);
defer allocator.free(html);
```

### Con Template Cache

```zig
var cache = TemplateCache.init(allocator);
defer cache.deinit();

var compiler = try Compiler.init(allocator, js_runtime);
defer compiler.deinit();

compiler.template_cache = &cache;
compiler.base_path = "/path/to/templates";

const html = try compiler.compile(ast);
defer allocator.free(html);
```

## Rendimiento

### Optimizaciones

- **Paso único**: AST recorrido una vez
- **Reutilización de buffer**: Buffer de salida crece, no se reasigna
- **Almacenamiento en caché de plantilla**: Plantillas analizadas en caché
- **Sin copia**: Nodos de texto hacen referencia a fuente
- **Escapado**: Pre-calcula tamaño, asignación única

### Benchmarks

Rendimiento típico (varía según complejidad de plantilla):

- Etiqueta simple: ~100ns
- Bucle (10 elementos): ~5µs
- Plantilla de página completa: ~50-500µs

## Pruebas

Ejecutar pruebas del compilador:
```bash
zig test src/compiler/tests.zig
```

Las pruebas cubren:
- Todos los tipos de nodo
- Evaluación de JavaScript
- Casos de error
- Casos extremos
- Seguridad (prevención de XSS)

## Ver También

- [Tokenizador](tokenizer.md) - Análisis léxico
- [Analizador Sintáctico](parser.md) - Análisis sintáctico
- [AST](ast.md) - Árbol de Sintaxis Abstracta (entrada del compilador)
