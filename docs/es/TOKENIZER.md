# Documentación del Tokenizer

> **Versión:** 0.4.0  
> **Última actualización:** Abril 2026  
> **Estado:** Tokenizer completo — Parser es lo siguiente

---

## Tabla de Contenidos

1. [Descripción General](#descripción-general)
2. [Filosofía de Diseño](#filosofía-de-diseño)
3. [Arquitectura](#arquitectura)
4. [Máquina de Estados](#máquina-de-estados)
5. [Tipos de Token](#tipos-de-token)
6. [Funciones de Escaneo](#funciones-de-escaneo)
7. [Decisiones Clave de Diseño](#decisiones-clave-de-diseño)
8. [Ejemplo de Uso](#ejemplo-de-uso)
9. [Referencia de Salida de Tokens](#referencia-de-salida-de-tokens)
10. [Lo que viene — el Parser](#lo-que-viene--el-parser)

---

## Descripción General

El tokenizer es la primera fase del pipeline de compilación de zig-pug. Convierte el código fuente de plantillas Pug en un flujo plano de tokens que el parser consume.

**Pipeline:**

```
Código Fuente → Tokenizer → Flujo de Tokens → Parser → AST → Compilador → HTML
```

**Características principales:**

- Modular — cada función de escaneo en su propio archivo
- Consciente de indentación — emite tokens `Indent`/`Dedent` como Python
- Soporte UTF-8 — maneja caracteres Unicode multi-byte
- Estado mínimo — solo 3 estados, sin lógica del parser

---

## Filosofía de Diseño

> **El tokenizer reconoce sintaxis superficial. El parser asigna significado.**

Esta frontera fue la decisión de diseño central de esta versión. El tokenizer NO:

- Interpreta valores de atributos
- Decide si un `=` es asignación o código buffered
- Clasifica `true`/`false` como booleanos
- Interpreta valores numéricos
- Entiende expresiones JS

Solo responde a: **¿qué carácter es este, en qué contexto inmediato?**

### Las tres categorías de token que importan

| Token | Significado | Ejemplo |
|---|---|---|
| `String` | Contenido entre delimitadores de comillas | `"hola"`, `'mundo'` |
| `Text` | Contenido plano después de un tag, hasta newline | `p Hola mundo` → `Text("Hola mundo")` |
| `Ident` | Cualquier palabra — el parser decide qué significa | `div`, `true`, `100`, `miVar` |

Todo lo demás (`Class`, `Id`, símbolos, keywords) es sintaxis superficial que el tokenizer puede reconocer visualmente sin necesitar contexto semántico.

---

## Arquitectura

```
src/tokenizer/
  mod.zig              — hub: struct Tokenizer, dispatch principal (next())
  Token.zig            — struct Token (type, value, line, column)
  TokenType.zig        — enum TokenType
  TokenizerState.zig   — solo 3 estados
  TokenizerError.zig   — tipos de error
  utils.zig            — helpers compartidos: UTF-8, tabla de keywords (fuente única de verdad)
  scanIdentifier.zig   — palabras y keywords
  scanString.zig       — strings entre comillas con soporte de escape
  scanSymbol.zig       — puntuación, operadores, atajos .class/#id
  scanText.zig         — contenido de texto plano
  scanComment.zig      — comentarios // y //-
  scanInterpolation.zig — #{...} y !{...}
```

**Eliminados en esta versión:**

- `scanNumber.zig` — los números son `Ident`, el parser decide
- `scanAttrValue.zig` — los valores de atributos no son responsabilidad del tokenizer

---

## Máquina de Estados

Solo 3 estados — definidos en `TokenizerState.zig`:

```zig
pub const TokenizerState = enum {
    Root,    // inicio de línea — espera tag, keyword, o comentario
    Indent,  // midiendo indentación al inicio de línea
    Text,    // contenido de texto plano después de un tag
};
```

### ¿Por qué solo 3 estados?

La versión anterior tenía 14 estados (`TagStart`, `TagClass`, `TagId`, `AttrStart`, `AttrName`, `AttrEquals`, `AttrValue`, `AttrString`, `AttrJS`, `Loop`, `Code`...). Esos estados codificaban conocimiento del parser — "estoy dentro de una lista de atributos", "acabo de ver un signo igual". Eso le pertenece al parser.

El tokenizer solo necesita saber:
- ¿Estoy al inicio de una línea? (`Root`/`Indent`)
- ¿Estoy leyendo contenido de texto plano? (`Text`)

### Transiciones de estado

```
Root ──── newline ─────────────────────── ► Root (reset)
Root ──── espacio después de Ident/Class/Id ► Text
Text ──── newline ─────────────────────── ► Root
```

Todo lo demás permanece en `Root` — el parser rastrea la estructura.

### Campos del struct Tokenizer

```zig
pub const Tokenizer = struct {
    source: []const u8,
    pos: usize,
    line: usize,
    column: usize,
    allocator: std.mem.Allocator,
    indent_stack: std.ArrayListUnmanaged(usize),
    pending_tokens: std.ArrayListUnmanaged(Token),
    at_line_start: bool,
    state: TokenizerState,
    paren_depth: usize,         // rastrea anidamiento de () — cuando >0, . es Dot no Class
    after_space: bool,          // true cuando skipWhitespace consumió al menos un espacio
    last_token_type: TokenType, // tipo del último token emitido — usado para activar estado Text
};
```

### `paren_depth` — el único contexto estructural

El tokenizer necesita saber si está dentro de `()` por una sola razón: `.classname` vs `.propiedad`.

- Fuera de `()`: `div.container` → `Class("container")`
- Dentro de `()`: `div(data-val=obj.prop)` → `Dot` + `Ident("prop")`

`paren_depth` se incrementa con `(` y se decrementa con `)`. No se rastrea ningún otro contexto estructural.

### Condición de activación del estado Text

El texto plano después de un tag se activa cuando los tres son verdaderos:

```
after_space == true
AND paren_depth == 0
AND last_token_type ∈ { Ident, Class, Id, RParen }
```

Esto maneja correctamente:

```pug
p Hola mundo          → Text("Hola mundo")       ✅
p.intro Hola mundo    → Text("Hola mundo")       ✅
p(class="x") Hola     → Text("Hola")             ✅
if condicion          → Ident("condicion")        ✅ (If no está en la lista)
```

### Indentación — cola `pending_tokens`

Pug usa indentación significativa. El tokenizer emite tokens `Indent`/`Dedent` usando un stack:

- Aumenta → push del nivel + emitir `Indent`
- Disminuye → pop hasta el nivel correspondiente, emitir un `Dedent` por cada pop
- Nivel no encontrado → error `InvalidIndentation`
- Tabs → siempre `InvalidIndentation` (Pug requiere espacios)

**Nota de rendimiento:** `pending_tokens` usa `pop()` (O(1)) en lugar de `orderedRemove(0)` (O(n)). Los tokens se insertan en orden inverso para que `pop()` devuelva el correcto.

---

## Tipos de Token

Definidos en `TokenType.zig`:

### Identificadores
| Token | Descripción | Ejemplo |
|---|---|---|
| `Ident` | Cualquier palabra — nombre de tag, variable, `true`, `false`, números | `div`, `miVar`, `100`, `true` |
| `Class` | Atajo `.classname` (solo fuera de `()`) | `.container` |
| `Id` | Atajo `#idname` (solo fuera de `()`) | `#main` |

### Literales
| Token | Descripción | Ejemplo |
|---|---|---|
| `String` | Contenido entre comillas — dobles o simples | `"hola"`, `'mundo'` |
| `Text` | Contenido de texto plano después de un tag | `Hola mundo` |

> **Nota:** `Boolean` y `Number` han sido eliminados. `true`, `false`, `42`, `3.14` son todos `Ident`. El parser y mujs interpretan su significado.

### Símbolos
| Token | Char | Token | Char |
|---|---|---|---|
| `LParen` | `(` | `RParen` | `)` |
| `LBracket` | `[` | `RBracket` | `]` |
| `LBrace` | `{` | `RBrace` | `}` |
| `Dot` | `.` (dentro de `()`) | `Hash` | `#` (dentro de `()`) |
| `Comma` | `,` | `Colon` | `:` |
| `Pipe` | `\|` | `Question` | `?` |

### Operadores
| Token | Símbolo |
|---|---|
| `BufferedCode` | `=` |
| `UnbufferedCode` | `-` |
| `UnescapedCode` | `!=` |
| `Assign` | `=` (mantenido por compatibilidad con el parser) |
| `Equal` | `==` |
| `NotEqual` | `!=` |
| `And` | `&&` |
| `Or` | `\|\|` |
| `Greater` / `Less` | `>` / `<` |
| `GreaterEqual` / `LessEqual` | `>=` / `<=` |
| `Plus` / `Minus` | `+` / `-` |

### Keywords — directivas Pug
`If`, `Else`, `Unless`, `Each`, `While`, `In`, `Case`, `When`, `Default`, `Mixin`, `Include`, `Extends`, `Block`, `Append`, `Prepend`, `Doctype`

> `true` y `false` NO son keywords. Son `Ident` simples.

### Interpolación
| Token | Sintaxis |
|---|---|
| `EscapedInterpol` | `#{expresion}` — seguro para HTML, enviado a mujs |
| `UnescapedInterpol` | `!{expresion}` — salida cruda, enviado a mujs |

### Comentarios
| Token | Sintaxis |
|---|---|
| `BufferedComment` | `//` — se renderiza como comentario HTML |
| `UnbufferedComment` | `//-` — eliminado de la salida |

### Estructura
`Indent`, `Dedent`, `Newline`, `Eof`

---

## Funciones de Escaneo

### `scanIdentifier`

Lee caracteres alfanuméricos + `_` + `-` + secuencias UTF-8. Verifica contra la tabla de keywords en `utils.getKeyword()`. Pre-filtrado por longitud (2–7 chars) para rendimiento.

Sin transiciones de estado. El parser decide qué significa un identificador.

### `scanString`

Lee entre delimitadores de comillas (`"` o `'`). Soporta:
- Secuencias de escape: `\"`, `\'`, `\\`, `\n`, `\t`, cualquier `\x`
- Comilla opuesta adentro: `"alert('hola')"` → `String("alert('hola')")`
- Devuelve el contenido sin las comillas circundantes

### `scanSymbol`

Maneja puntuación, operadores y atajos Pug. Comportamientos clave:

- `.nombre` fuera de `()` → `Class("nombre")`
- `.nombre` dentro de `()` → `Dot` + identificador manejado por la siguiente llamada
- `#nombre` fuera de `()` → `Id("nombre")`
- `#nombre` dentro de `()` → `Hash`
- Dígitos → lee la secuencia completa como `Ident` (el punto solo se consume si el siguiente char es dígito)
- Operadores multi-char verificados antes de single-char: `!=`, `>=`, `<=`, `==`, `&&`, `||`
- `(` incrementa `paren_depth`, `)` lo decrementa

### `scanText`

Activo en estado `.Text`. Lee todo hasta:
- `\n` — fin de línea
- `#{` — inicio de interpolación escapada
- `!{` — inicio de interpolación sin escapar

Devuelve token `Text`. El estado se resetea a `Root` en newline.

### `scanComment`

- `//` → `BufferedComment` con contenido
- `//-` → `UnbufferedComment` con contenido
- `//!` → comentario de documentación, ignorado silenciosamente, llama a `next()` para continuar

### `scanInterpolation`

Lee `#{...}` o `!{...}`. Rastrea profundidad de anidamiento de llaves — maneja correctamente:

```pug
#{obj.fn({key: value})}   → EscapedInterpol("obj.fn({key: value})")
```

---

## Decisiones Clave de Diseño

### 1. Los números son `Ident`

```pug
input(value=100 min=50 max=150)
```

`100`, `50`, `150` → todos `Ident`. En HTML todos los valores de atributos son strings. El navegador interpreta `"100"` como número cuando lo necesita. Zig-pug nunca hace aritmética con estos valores — el renderer los escribe tal cual o mujs los evalúa.

### 2. `true`/`false` son `Ident`

Los booleanos de JS no son keywords de Pug. `true` y `false` emiten `Ident` y el parser o mujs decide. `True` también emite `Ident` — mujs lanzará `ReferenceError` en runtime, lo cual es el comportamiento correcto.

### 3. Los valores de atributos sin comillas son secuencias de tokens

```pug
div(data-val=miVar.items.length)
```

El tokenizer emite: `Ident("miVar")` `Dot` `Ident("items")` `Dot` `Ident("length")`. El parser ve `BufferedCode` y sabe que todo hasta `,` o `)` no balanceado es una expresión JS para pasar a mujs.

### 4. `.class` vs `.propiedad` — `paren_depth`

`.` significa dos cosas distintas:
- `div.container` — atajo de clase CSS
- `obj.propiedad` — acceso a propiedad JS dentro de `()`

`paren_depth` es el contexto mínimo necesario para distinguirlos sin conocimiento del parser.

### 5. `pending_tokens` con `pop()` en lugar de `orderedRemove(0)`

Los tokens INDENT/DEDENT se insertan en orden inverso para que `pop()` (O(1)) pueda usarse en lugar de `orderedRemove(0)` (O(n)).

---

## Ejemplo de Uso

```zig
const std = @import("std");
const Tokenizer = @import("src/tokenizer/mod.zig").Tokenizer;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source = "div.container#main(class=\"test\") Hola mundo";

    var tokenizer = try Tokenizer.init(allocator, source);
    defer tokenizer.deinit();

    while (true) {
        const token = tokenizer.next() catch |err| {
            std.debug.print("[ERROR] {}\n", .{err});
            break;
        };
        std.debug.print("{s:<20} {s}\n", .{ @tagName(token.type), token.value });
        if (token.type == .Eof) break;
    }
}
```

**Salida:**

```
Ident                div
Class                container
Id                   main
LParen               (
Ident                class
BufferedCode         =
String               test
RParen               )
Text                 Hola mundo
Eof
```

---

## Referencia de Salida de Tokens

| Fuente Pug | Tokens |
|---|---|
| `div.container#main` | `Ident("div")` `Class("container")` `Id("main")` |
| `p Hola mundo` | `Ident("p")` `Text("Hola mundo")` |
| `input(value=100)` | `Ident("input")` `LParen` `Ident("value")` `BufferedCode` `Ident("100")` `RParen` |
| `input(value="hola")` | `Ident("input")` `LParen` `Ident("value")` `BufferedCode` `String("hola")` `RParen` |
| `input(value=#{edad})` | `Ident("input")` `LParen` `Ident("value")` `BufferedCode` `EscapedInterpol("edad")` `RParen` |
| `div(data=obj.x.y)` | `Ident("div")` `LParen` `Ident("data")` `BufferedCode` `Ident("obj")` `Dot` `Ident("x")` `Dot` `Ident("y")` `RParen` |
| `if condicion` | `If` `Ident("condicion")` |
| `each item in items` | `Each` `Ident("item")` `In` `Ident("items")` |
| `- var x = 42` | `UnbufferedCode` `Ident("var")` `Ident("x")` `BufferedCode` `Ident("42")` |
| `// comentario` | `BufferedComment("comentario")` |
| `//- interno` | `UnbufferedComment("interno")` |

---

## Lo que viene — el Parser

El parser recibe el flujo de tokens y asigna significado semántico:

- `Ident` al inicio de línea → nombre de tag
- `Ident` después de `BufferedCode` dentro de `()` → inicio de expresión JS para mujs
- `If` + tokens → nodo condicional
- `Each` + `Ident` + `In` + `Ident` → nodo de loop
- `Text` → nodo de contenido de texto
- `Indent`/`Dedent` → anidamiento del árbol

El parser es responsable de balancear `(` `)` en expresiones de atributos y pasar strings JS crudos a mujs para evaluación.
