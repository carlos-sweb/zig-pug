# Analizador Sintáctico - Análisis Sintáctico

El **Analizador Sintáctico** es la segunda fase del pipeline de compilación de zig-pug. Convierte el flujo de tokens del tokenizador en un Árbol de Sintaxis Abstracta (AST) que representa la estructura de la plantilla.

## Descripción General

El analizador sintáctico consume tokens y construye una estructura de árbol jerárquica que representa la plantilla. Maneja:

- **Análisis sintáctico descendente recursivo** para reglas gramaticales
- **Anidamiento basado en indentación** (estructura de bloques)
- **Análisis de atributos** con expresiones
- **Estructuras de control de flujo** (if/else, bucles, case)
- **Características de plantilla** (mixins, includes, extends)
- **Recuperación de errores** con mensajes útiles

## Arquitectura

### Ubicación: `src/parser/`

```
src/parser/
├── mod.zig           # Estructura Parser principal y punto de entrada
├── helpers.zig       # Utilidades comunes del analizador (advance, expect, match)
├── tag.zig           # Análisis de etiquetas HTML
├── text.zig          # Análisis de texto e interpolación
├── code.zig          # Bloques de código y comentarios
├── attributes.zig    # Análisis de atributos
├── conditionals.zig  # Sentencias if/else/unless
├── loops.zig         # Bucles each/while
├── case.zig          # Sentencias case/when
├── mixins.zig        # Definiciones y llamadas de mixin
├── templates.zig     # Directivas include/extends/block
└── tests.zig         # Suite de pruebas del analizador
```

## Estrategia de Análisis

### Descenso Recursivo

El analizador sintáctico utiliza **descenso recursivo** donde cada regla gramatical tiene su propia función:

```zig
parseStatement()
  ├─> parseTag()
  ├─> parseConditional()
  ├─> parseLoop()
  ├─> parseCode()
  └─> parseMixinCall()
```

### Conciencia de Indentación

El analizador utiliza tokens `INDENT`/`DEDENT` para entender la estructura de bloques:

```pug
if condition
  INDENT
    p Content    # Anidado en bloque 'if'
  DEDENT
p Outside        # No anidado
```

## Componentes del Analizador

### 1. Analizador Principal (`mod.zig`)

**Estructura Parser**:
```zig
pub const Parser = struct {
    tokenizer: tokenizer.Tokenizer,  // Fuente de tokens
    current: tokenizer.Token,        // Token de lookahead
    allocator: std.mem.Allocator,    // Asignador base
    arena: std.heap.ArenaAllocator,  // Arena de nodos AST
}
```

**Funciones Principales**:
- `init()`: Inicializar analizador con código fuente
- `parse()`: Analizar plantilla completa → nodo Document
- `parseStatement()`: Analizar sentencia única
- `deinit()`: Limpiar analizador y todos los nodos AST

### 2. Etiquetas (`tag.zig`)

Analiza etiquetas HTML con atributos e hijos:

```pug
div.container#main(data-value="test")
  p Content
```

**Funciones**:
- `parseTag()`: Analizar etiqueta con nombre
- `parseImplicitDiv()`: Analizar `.class` / `#id` sin etiqueta
- Maneja: nombres de etiqueta, clases, IDs, atributos, hijos

### 3. Atributos (`attributes.zig`)

Analiza listas de atributos dentro de paréntesis:

```pug
a(href="/home" class="link" target="_blank")
input(type="checkbox" checked)
div(class=myVar data-count=items.length)
```

**Tipos de Atributo**:
- **Literal**: `href="/home"` (cadena estática)
- **Expresión**: `class=myVar` (variable JavaScript)
- **Booleano**: `checked` (sin valor)
- **Sin escapar**: `data-html!=content` (HTML sin procesar)

### 4. Texto e Interpolación (`text.zig`)

Analiza contenido de texto y expresiones incrustadas:

```pug
p Hello #{name}, you have #{count} messages
p !{rawHtml}
| Plain text with pipe
```

**Funciones**:
- `parseText()`: Texto simple hasta nueva línea
- `parseInterpolation()`: `#{expr}` o `!{expr}`

### 5. Bloques de Código (`code.zig`)

Analiza la ejecución de código JavaScript:

```pug
= user.name           // Almacenado en búfer (salida escapada)
!= rawHtml            // Sin escapar (salida sin procesar)
- var x = 10          // No almacenado (solo ejecutar)
// HTML comment
//- Code comment (not in output)
```

**Funciones**:
- `parseCode()`: Analizar sentencias `=`, `!=`, `-`
- `parseComment()`: Analizar comentarios `//` y `//-`

### 6. Condicionales (`conditionals.zig`)

Analiza el control de flujo if/else/unless:

```pug
if loggedIn
  p Welcome back!
else if guest
  p Hello guest
else
  p Please login

unless admin
  p Access denied
```

**Funciones**:
- `parseConditional()`: Analizar if/unless con ramas
- Maneja: `if`, `else if`, `else`, `unless`

### 7. Bucles (`loops.zig`)

Analiza construcciones de iteración:

```pug
each item in items
  li= item

each item, index in items
  li #{index}: #{item}

while hasMore
  p Loading...
```

**Funciones**:
- `parseLoop()`: Analizar bucles each/while
- Soporta: iteradores, variables de índice, ramas else

### 8. Sentencias Case (`case.zig`)

Analiza la concordancia de estilo switch:

```pug
case color
  when 'red'
    p Red color
  when 'blue', 'cyan'
    p Blue-ish
  default
    p Unknown
```

**Funciones**:
- `parseCase()`: Analizar sentencia case
- `parseWhen()`: Analizar cláusulas when

### 9. Mixins (`mixins.zig`)

Analiza bloques de plantilla reutilizables:

```pug
mixin article(title, author)
  article
    h1= title
    p by #{author}

+article("Hello", "John")
```

**Funciones**:
- `parseMixinDefinition()`: Analizar mixin con parámetros
- `parseMixinCall()`: Analizar `+mixinName(args)`

### 10. Herencia de Plantilla (`templates.zig`)

Analiza directivas include/extends/block:

```pug
extends layout.pug

block content
  p Child content

include header.pug
```

**Funciones**:
- `parseInclude()`: Analizar directiva include
- `parseExtends()`: Analizar directiva extends
- `parseBlock()`: Analizar definición de bloque

### 11. Funciones Auxiliares (`helpers.zig`)

Utilidades comunes de análisis:

```zig
advance(parser)              // Moverse al siguiente token
expect(parser, TokenType)    // Consumir token esperado o error
match(parser, []TokenType)   // Verificar si actual coincide con algún tipo
```

## Flujo de Análisis

### Ejemplo: Análisis de Etiqueta

**Entrada**:
```pug
div.container#main(data-value="test")
  p Hello
```

**Pasos de Análisis**:

1. **parseStatement()** ve `Ident("div")`
2. Llama a **parseTag()**
3. Consume nombre de etiqueta: `"div"`
4. Ve `.Class` → añade atributo class
5. Ve `#Id` → añade atributo id
6. Ve `(` → llama a **parseAttributes()**
7. Analiza `data-value="test"`
8. Ve `Newline` luego `Indent`
9. Analiza recursivamente hijos
10. Devuelve **TagNode** con todos los datos

### Ejemplo: Análisis de Condicional

**Entrada**:
```pug
if user
  p Welcome
else
  p Login
```

**Pasos de Análisis**:

1. **parseStatement()** ve palabra clave `If`
2. Llama a **parseConditional()**
3. Analiza condición: `"user"`
4. Ve `Newline` luego `Indent`
5. Analiza hijos de rama then
6. Ve `Dedent` luego `Else`
7. Analiza hijos de rama else
8. Devuelve **ConditionalNode**

## Manejo de Errores

El analizador proporciona mensajes de error detallados:

```
Error at line 5, column 10:
Expected ')' but found ','
  div(class="box",
                  ^
```

**Tipos de Error**:
- `UnexpectedToken`: Token incorrecto en contexto
- `InvalidIndentation`: Indentación inconsistente
- `OutOfMemory`: Asignación fallida

## Gestión de Memoria

El analizador utiliza un **ArenaAllocator** para nodos AST:

```zig
var parser = try Parser.init(allocator, source);
defer parser.deinit();  // Libera TODOS los nodos AST de una vez
```

Beneficios:
- **Rápido**: Sin limpieza de nodo individual
- **Simple**: Llamada única deinit()
- **Seguro**: Sin fugas de memoria

## Espaciado Inteligente

El analizador maneja inteligentemente los espacios en blanco en expresiones de código:

```pug
= item.title       // → "item.title" (sin espacios alrededor de '.')
= arr[0]          // → "arr[0]" (sin espacios alrededor de '[')
= x + y           // → "x + y" (espacios alrededor de '+')
```

Utiliza `needsSpaceBefore()` y `needsSpaceAfter()` para determinar espaciado.

## Uso de API

### Análisis Básico

```zig
const Parser = @import("parser/mod.zig").Parser;

var parser = try Parser.init(allocator, source);
defer parser.deinit();

const document = try parser.parse();
// document es nodo AST raíz
```

### Manejo de Errores

```zig
const document = parser.parse() catch |err| {
    std.debug.print("Parse error: {}\n", .{err});
    return err;
};
```

## Pruebas

Ejecutar pruebas del analizador:
```bash
zig test src/parser/tests.zig
```

Las pruebas cubren:
- Todos los tipos de sentencia
- Anidamiento e indentación
- Atributos y expresiones
- Casos extremos
- Recuperación de errores

## Ver También

- [Tokenizador](tokenizer.md) - Análisis léxico (fase anterior)
- [AST](ast.md) - Estructura del Árbol de Sintaxis Abstracta
- [Compilador](compiler.md) - Generación de HTML (siguiente fase)
