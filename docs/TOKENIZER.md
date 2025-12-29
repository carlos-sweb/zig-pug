# Tokenizer Documentation

---

## English Version

### Table of Contents
1. [Overview](#overview)
2. [State Machine Architecture](#state-machine-architecture)
3. [Labeled-Switch Pattern](#labeled-switch-pattern)
4. [Scan Functions](#scan-functions)
5. [State Transitions](#state-transitions)
6. [Token Types](#token-types)
7. [Usage Examples](#usage-examples)
8. [Extending the Tokenizer](#extending-the-tokenizer)
9. [Performance Considerations](#performance-considerations)

---

### Overview

The tokenizer is the first phase of the zig-pug compilation pipeline. It converts Pug template source code into a stream of tokens that the parser can process.

**Key Features:**
- **State machine based**: Uses 14 distinct states to handle different parsing contexts
- **Labeled-switch pattern**: Leverages Zig's labeled-switch for efficient state transitions
- **Modular design**: Each scan function in its own file
- **Indentation-aware**: Tracks indentation like Python (INDENT/DEDENT tokens)
- **UTF-8 support**: Handles multi-byte Unicode characters
- **Context-sensitive**: Recognizes `.class` and `#id` only in appropriate contexts

**Pipeline Position:**
```
Source Code → Tokenizer → Token Stream → Parser → AST → Compiler → HTML
```

---

### State Machine Architecture

The tokenizer implements a finite state machine with 14 states defined in `src/tokenizer/TokenizerState.zig`:

| State | Description | Typical Tokens |
|-------|-------------|----------------|
| **Root** | Start of document/line | Tag names, keywords, symbols |
| **Indent** | Processing indentation | N/A (handled internally) |
| **TagStart** | After tag name | `.class`, `#id`, `(`, text |
| **TagClass** | After `.class` | More `.class`, `#id`, `(` |
| **TagId** | After `#id` | `.class`, `(`, text |
| **AttrStart** | Inside `(attributes)` | Attribute names |
| **AttrName** | Processing attribute name | `=`, `,`, `)` |
| **AttrEquals** | After `=` in attribute | String, identifier, number |
| **AttrValue** | Processing attribute value | Next attribute or `)` |
| **AttrString** | String attribute value | Back to AttrName |
| **AttrJS** | JS expression as value | Back to AttrName |
| **Text** | Plain text content | Any text until newline |

**State Flow Example:**
```
div.container#main(class="test")
│   │         │    │     │      │
│   │         │    │     │      └─ AttrString → AttrName → Root
│   │         │    │     └─ AttrEquals
│   │         │    └─ AttrStart → AttrName
│   │         └─ TagId
│   └─ TagClass
└─ Root → TagStart
```

---

### Labeled-Switch Pattern

The tokenizer uses Zig's **labeled-switch** pattern for efficient state transitions. This technique provides:

1. **Direct computed jumps** between states
2. **Better branch prediction** than traditional while loops
3. **Cleaner code** without explicit state variables

**Traditional Approach (verbose):**
```zig
while (true) {
    switch (state) {
        .StateA => { state = .StateB; continue; },
        .StateB => { state = .StateC; continue; },
        .StateC => return,
    }
    break;
}
```

**Labeled-Switch (elegant):**
```zig
state: switch (current_state) {
    .StateA => continue :state .StateB,
    .StateB => continue :state .StateC,
    .StateC => return,
}
```

**In the tokenizer:**
```zig
pub fn next(self: *Tokenizer) !Token {
    // ... preprocessing ...

    return switch (self.state) {
        .Root, .Indent => {
            if (isIdentifier(ch)) return scanIdentifier(self);
            return scanSymbol(self);
        },
        .TagStart, .TagClass, .TagId => {
            if (ch == '.') return scanSymbol(self); // .class
            if (ch == '#') return scanSymbol(self); // #id
            if (ch == '(') return scanSymbol(self); // attributes
            // ...
        },
        .AttrStart, .AttrName, .AttrEquals => {
            // attribute parsing logic
        },
        .Text => scanText(self),
    };
}
```

**Performance Benefits:**
- Reduces branch mispredictions
- Generates more efficient assembly code
- Direct jumps vs. loop overhead

---

### Scan Functions

Each token type has a dedicated scan function in `src/tokenizer/`:

#### 1. `scanIdentifier.zig`
Scans identifiers and keywords (tag names, variable names, keywords).

**Handles:**
- Tag names: `div`, `p`, `span`
- Keywords: `if`, `else`, `each`, `mixin`
- Variable names: `userName`, `item`
- UTF-8 identifiers: `título`, `año`

**State Transitions:**
- `Root` → `TagStart` (if followed by `.`, `#`, or `(`)
- `Root` → `Root` (if plain identifier)
- `AttrStart` → `AttrName` (attribute name)

**Example:**
```pug
div    → Ident("div"), state: Root → TagStart
if     → If (keyword), state: Root (stays)
título → Ident("título"), state: Root (UTF-8 support)
```

#### 2. `scanString.zig`
Scans quoted strings (single or double quotes).

**Handles:**
- Double quotes: `"hello world"`
- Single quotes: `'hello world'`
- Escape sequences: `"line\nbreak"`
- Nested quotes: `"it's ok"`, `'say "hi"'`

**State Transitions:**
- `AttrValue/AttrString` → `AttrName` (after closing quote)

**Example:**
```pug
"hello"  → String("hello")
'world'  → String("world")
```

#### 3. `scanNumber.zig`
Scans numeric literals (integers and decimals).

**Handles:**
- Integers: `42`, `100`
- Decimals: `3.14`, `0.5`

**State Transitions:**
- Maintains current state (numbers don't change context)

**Example:**
```pug
42    → Number("42")
3.14  → Number("3.14")
```

#### 4. `scanComment.zig`
Scans Pug comments.

**Handles:**
- Buffered comments: `// appears in HTML`
- Unbuffered comments: `//- code comment only`
- Doc comments: `//! completely ignored`

**State Transitions:**
- Maintains current state

**Example:**
```pug
// Hello        → BufferedComment("Hello")
//- Internal    → UnbufferedComment("Internal")
//! Documentation → (skipped, recursively calls next())
```

#### 5. `scanInterpolation.zig`
Scans interpolation expressions.

**Handles:**
- Escaped: `#{expression}` (HTML-safe)
- Unescaped: `!{raw_html}` (raw output)
- Nested braces: `#{obj.fn({key: value})}`

**State Transitions:**
- Maintains current state (can appear in text or attributes)

**Example:**
```pug
#{name}      → EscapedInterpol("name")
!{html}      → UnescapedInterpol("html")
#{user.age}  → EscapedInterpol("user.age")
```

#### 6. `scanSymbol.zig`
Scans symbols, operators, and Pug shorthand syntax.

**Handles:**
- Shorthand: `.class`, `#id`
- Parentheses: `(`, `)`
- Brackets: `[`, `]`, `{`, `}`
- Operators: `=`, `!=`, `>=`, `<=`, `==`, `&&`, `||`
- Punctuation: `,`, `:`, `|`

**State Transitions:**
- `.class` → `TagClass` (in tag context)
- `#id` → `TagId` (in tag context)
- `(` → `AttrStart` (when in TagStart/TagClass/TagId)
- `)` → `TagStart` (closing attributes)
- `=` → `AttrEquals` (in AttrName)

**Context-Sensitive Examples:**
```pug
div.container  → Ident("div"), Class("container")
              (state: Root → TagStart → TagClass)

p Text with .period and #hash
              → Ident("p"), Ident("Text"), ...
              (. and # are plain text in Text state)
```

#### 7. `scanText.zig`
Scans plain text content.

**Handles:**
- Any text until newline or EOF
- Stops at interpolation `#{}`
- Prevents `.class` and `#id` from being tokenized in text

**State Transitions:**
- `Text` → `Root` (at newline or EOF)

**Important Fix (v4.0.9+):**
When EOF is reached without a final newline, the state now properly transitions to `Root` instead of remaining in `Text` state. This prevents empty tokens from being generated, which previously caused trailing spaces in text content.

**Example:**
```pug
p This is text with #hashtag and .period
  └─ Text mode: everything after space is text
     Token: Ident("This is text with #hashtag and .period")
```

---

### State Transitions

Visual representation of state flow:

```
┌─────────────────────────────────────────────────────────────┐
│                   TOKENIZER STATE MACHINE                    │
└─────────────────────────────────────────────────────────────┘

START (Root)
    │
    ├─ Identifier + (.|#|() ─────► TagStart
    │                                  │
    │                                  ├─ .class ──► TagClass ─┐
    │                                  ├─ #id ─────► TagId ────┤
    │                                  └─ ( ───────► AttrStart │
    │                                                    │      │
    ├─ Identifier (plain) ─────────► Root (loop)        │      │
    │                                                    │      │
    └─ Newline ────────────────────► Root (reset)       │      │
                                                         │      │
AttrStart ◄──────────────────────────────────────────────┘      │
    │                                                            │
    ├─ Identifier ──────────────────► AttrName                  │
    │                                      │                     │
    │                                      ├─ = ──► AttrEquals  │
    │                                      │           │         │
    │                                      │           ├─ "..." ► AttrString ─┐
    │                                      │           └─ expr ► AttrValue ───┤
    │                                      │                                   │
    │                                      ├─ , ──► AttrName (loop) ◄─────────┤
    │                                      └─ ) ──────────────────────────────┘
    │                                           │
    └───────────────────────────────────────────┴──► TagStart or Text
```

**Newline Behavior:**
- **Always** resets state to `Root`
- Triggers indentation handling
- Emits INDENT/DEDENT tokens as needed

---

### Token Types

Defined in `src/tokenizer/TokenType.zig`:

| Category | Tokens | Example |
|----------|--------|---------|
| **Identifiers** | `Ident` | `div`, `myClass` |
| **Keywords** | `If`, `Else`, `Each`, `Mixin`, `Include`, `Extends`, `Block` | `if`, `each` |
| **Literals** | `String`, `Number`, `Boolean` | `"hello"`, `42`, `true` |
| **Shorthand** | `Class`, `Id` | `.container`, `#main` |
| **Interpolation** | `EscapedInterpol`, `UnescapedInterpol` | `#{x}`, `!{y}` |
| **Comments** | `BufferedComment`, `UnbufferedComment` | `//`, `//-` |
| **Symbols** | `LParen`, `RParen`, `LBracket`, `RBracket`, `LBrace`, `RBrace` | `(`, `)`, `[`, `]` |
| **Operators** | `BufferedCode`, `UnescapedCode`, `Equal`, `Greater`, `Less` | `=`, `!=`, `==` |
| **Structure** | `Newline`, `Indent`, `Dedent`, `Eof` | `\n`, INDENT, DEDENT |
| **Special** | `Doctype`, `Dot`, `Hash`, `Comma`, `Colon`, `Pipe` | `doctype`, `.`, `#` |

---

### Usage Examples

#### Basic Tokenization

```zig
const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source =
        \\div.container
        \\  p Hello #{name}
    ;

    var tokenizer = try Tokenizer.init(allocator, source);
    defer tokenizer.deinit();

    while (true) {
        const token = try tokenizer.next();
        std.debug.print("{s}({s})\n", .{
            @tagName(token.type),
            token.value,
        });
        if (token.type == .Eof) break;
    }
}
```

**Output:**
```
Ident(div)
Class(container)
Newline()
Indent()
Ident(p)
Ident(Hello)
EscapedInterpol(name)
Dedent()
Eof()
```

#### Complex Template

```pug
doctype html
html
  head
    title My Site
  body.main-content#app(data-theme="dark")
    h1 Welcome #{user.name}
    //- This is a comment
    ul
      each item in items
        li= item.title
```

**Token Flow:**
```
Doctype(doctype html)
Newline()
Ident(html)              state: Root → TagStart
Newline()                state: TagStart → Root
Indent()
Ident(head)              state: Root → TagStart
...
Class(main-content)      state: TagClass
Id(app)                  state: TagId
LParen()                 state: AttrStart
Ident(data-theme)        state: AttrName
BufferedCode(=)          state: AttrEquals
String(dark)             state: AttrString → AttrName
RParen()                 state: TagStart
...
```

---

### Extending the Tokenizer

#### Adding a New Token Type

1. **Add to `TokenType.zig`:**
```zig
pub const TokenType = enum {
    // ... existing types ...
    NewTokenType,
};
```

2. **Create scan function** `src/tokenizer/scanNewToken.zig`:
```zig
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;

pub fn scanNewToken(tokenizer: anytype) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    // Scanning logic here
    const value = tokenizer.source[start..tokenizer.pos];

    // State transition if needed
    tokenizer.state = .NewState;

    return Token.init(.NewTokenType, value, start_line, start_col);
}
```

3. **Import in `tokenizer.zig`:**
```zig
const scanNewToken = @import("./tokenizer/scanNewToken.zig").scanNewToken;
```

4. **Add to state machine:**
```zig
return switch (self.state) {
    .SomeState => {
        if (condition) return scanNewToken(self);
        // ...
    },
    // ...
};
```

#### Adding a New State

1. **Add to `TokenizerState.zig`:**
```zig
pub const TokenizerState = enum {
    // ... existing states ...
    NewState,
};
```

2. **Update `next()` switch:**
```zig
return switch (self.state) {
    .NewState => {
        // Handle tokens in this state
        if (ch == 'x') return scanSomething(self);
        // ...
    },
    // ...
};
```

3. **Add transition logic** in relevant scan functions:
```zig
// In scanSomething.zig
tokenizer.state = .NewState; // Transition to new state
```

---

### Performance Considerations

#### Why Labeled-Switch is Faster

**Assembly Comparison:**

Traditional switch in loop:
```asm
.L2:
    mov     eax, DWORD PTR [state]
    cmp     eax, 1
    je      .L3
    cmp     eax, 2
    je      .L4
    jmp     .L2          ; Back to loop start
.L3:
    mov     DWORD PTR [state], 2
    jmp     .L2
```

Labeled-switch:
```asm
    jmp     qword ptr [8*rax + .LJTI0_0]  ; Direct computed jump
.L3:
    // StateA code
.L4:
    // StateB code
```

**Benefits:**
1. **Direct jumps**: No loop condition checking
2. **Better branch prediction**: CPU can predict computed jumps
3. **Fewer instructions**: Less overhead per transition

#### Hot Path Optimization

The tokenizer optimizes common cases:

```zig
// Fast path for common tokens before state machine
if (ch == '\n') {
    // Immediate handling, no state switch
    self.at_line_start = true;
    self.state = .Root;
    return Token.init(.Newline, "\n", line, 1);
}

// Comments (common in templates)
if (ch == '/' and self.peekAhead(1) == '/') {
    return scanComment(self);
}

// Interpolation (very common)
if ((ch == '#' or ch == '!') and self.peekAhead(1) == '{') {
    return scanInterpolation(self);
}
```

#### Memory Efficiency

- **Token reuse**: Tokens contain slices to source, not copies
- **Stack allocation**: Tokens are typically stack-allocated
- **Minimal heap usage**: Only for indent_stack and pending_tokens

---

## Versión en Español

### Tabla de Contenidos
1. [Descripción General](#descripción-general)
2. [Arquitectura de Máquina de Estados](#arquitectura-de-máquina-de-estados)
3. [Patrón Labeled-Switch](#patrón-labeled-switch)
4. [Funciones de Escaneo](#funciones-de-escaneo)
5. [Transiciones de Estado](#transiciones-de-estado)
6. [Tipos de Token](#tipos-de-token)
7. [Ejemplos de Uso](#ejemplos-de-uso)
8. [Extendiendo el Tokenizer](#extendiendo-el-tokenizer)
9. [Consideraciones de Rendimiento](#consideraciones-de-rendimiento)

---

### Descripción General

El tokenizer es la primera fase del pipeline de compilación de zig-pug. Convierte el código fuente de plantillas Pug en un flujo de tokens que el parser puede procesar.

**Características Clave:**
- **Basado en máquina de estados**: Utiliza 14 estados distintos para manejar diferentes contextos de parseo
- **Patrón labeled-switch**: Aprovecha el labeled-switch de Zig para transiciones eficientes
- **Diseño modular**: Cada función de escaneo en su propio archivo
- **Consciente de indentación**: Rastrea indentación como Python (tokens INDENT/DEDENT)
- **Soporte UTF-8**: Maneja caracteres Unicode multi-byte
- **Sensible al contexto**: Reconoce `.class` y `#id` solo en contextos apropiados

**Posición en el Pipeline:**
```
Código Fuente → Tokenizer → Flujo de Tokens → Parser → AST → Compilador → HTML
```

---

### Arquitectura de Máquina de Estados

El tokenizer implementa una máquina de estados finitos con 14 estados definidos en `src/tokenizer/TokenizerState.zig`:

| Estado | Descripción | Tokens Típicos |
|--------|-------------|----------------|
| **Root** | Inicio de documento/línea | Nombres de tag, keywords, símbolos |
| **Indent** | Procesando indentación | N/A (manejado internamente) |
| **TagStart** | Después del nombre de tag | `.class`, `#id`, `(`, texto |
| **TagClass** | Después de `.class` | Más `.class`, `#id`, `(` |
| **TagId** | Después de `#id` | `.class`, `(`, texto |
| **AttrStart** | Dentro de `(atributos)` | Nombres de atributo |
| **AttrName** | Procesando nombre de atributo | `=`, `,`, `)` |
| **AttrEquals** | Después de `=` en atributo | String, identificador, número |
| **AttrValue** | Procesando valor de atributo | Siguiente atributo o `)` |
| **AttrString** | Valor de atributo string | Volver a AttrName |
| **AttrJS** | Expresión JS como valor | Volver a AttrName |
| **Text** | Contenido de texto plano | Cualquier texto hasta newline |

**Ejemplo de Flujo de Estados:**
```
div.container#main(class="test")
│   │         │    │     │      │
│   │         │    │     │      └─ AttrString → AttrName → Root
│   │         │    │     └─ AttrEquals
│   │         │    └─ AttrStart → AttrName
│   │         └─ TagId
│   └─ TagClass
└─ Root → TagStart
```

---

### Patrón Labeled-Switch

El tokenizer usa el patrón **labeled-switch** de Zig para transiciones eficientes de estado. Esta técnica proporciona:

1. **Saltos computados directos** entre estados
2. **Mejor predicción de ramas** que bucles while tradicionales
3. **Código más limpio** sin variables de estado explícitas

**Enfoque Tradicional (verboso):**
```zig
while (true) {
    switch (state) {
        .EstadoA => { state = .EstadoB; continue; },
        .EstadoB => { state = .EstadoC; continue; },
        .EstadoC => return,
    }
    break;
}
```

**Labeled-Switch (elegante):**
```zig
state: switch (estado_actual) {
    .EstadoA => continue :state .EstadoB,
    .EstadoB => continue :state .EstadoC,
    .EstadoC => return,
}
```

**En el tokenizer:**
```zig
pub fn next(self: *Tokenizer) !Token {
    // ... preprocesamiento ...

    return switch (self.state) {
        .Root, .Indent => {
            if (isIdentifier(ch)) return scanIdentifier(self);
            return scanSymbol(self);
        },
        .TagStart, .TagClass, .TagId => {
            if (ch == '.') return scanSymbol(self); // .class
            if (ch == '#') return scanSymbol(self); // #id
            if (ch == '(') return scanSymbol(self); // atributos
            // ...
        },
        .AttrStart, .AttrName, .AttrEquals => {
            // lógica de parseo de atributos
        },
        .Text => scanText(self),
    };
}
```

**Beneficios de Rendimiento:**
- Reduce predicciones erróneas de ramas
- Genera código ensamblador más eficiente
- Saltos directos vs. sobrecarga de bucle

---

### Funciones de Escaneo

Cada tipo de token tiene una función de escaneo dedicada en `src/tokenizer/`:

#### 1. `scanIdentifier.zig`
Escanea identificadores y keywords (nombres de tags, variables, keywords).

**Maneja:**
- Nombres de tags: `div`, `p`, `span`
- Keywords: `if`, `else`, `each`, `mixin`
- Nombres de variables: `userName`, `item`
- Identificadores UTF-8: `título`, `año`

**Transiciones de Estado:**
- `Root` → `TagStart` (si seguido por `.`, `#`, o `(`)
- `Root` → `Root` (si es identificador simple)
- `AttrStart` → `AttrName` (nombre de atributo)

**Ejemplo:**
```pug
div    → Ident("div"), estado: Root → TagStart
if     → If (keyword), estado: Root (permanece)
título → Ident("título"), estado: Root (soporte UTF-8)
```

#### 2. `scanString.zig`
Escanea strings entre comillas (simples o dobles).

**Maneja:**
- Comillas dobles: `"hola mundo"`
- Comillas simples: `'hola mundo'`
- Secuencias de escape: `"línea\nnueva"`
- Comillas anidadas: `"it's ok"`, `'decir "hola"'`

**Transiciones de Estado:**
- `AttrValue/AttrString` → `AttrName` (después de cerrar comilla)

**Ejemplo:**
```pug
"hola"  → String("hola")
'mundo' → String("mundo")
```

#### 3. `scanNumber.zig`
Escanea literales numéricos (enteros y decimales).

**Maneja:**
- Enteros: `42`, `100`
- Decimales: `3.14`, `0.5`

**Transiciones de Estado:**
- Mantiene el estado actual (los números no cambian el contexto)

**Ejemplo:**
```pug
42    → Number("42")
3.14  → Number("3.14")
```

#### 4. `scanComment.zig`
Escanea comentarios Pug.

**Maneja:**
- Comentarios buffered: `// aparece en HTML`
- Comentarios unbuffered: `//- solo comentario de código`
- Comentarios de documentación: `//! completamente ignorado`

**Transiciones de Estado:**
- Mantiene el estado actual

**Ejemplo:**
```pug
// Hola         → BufferedComment("Hola")
//- Interno     → UnbufferedComment("Interno")
//! Documentación → (saltado, llama recursivamente a next())
```

#### 5. `scanInterpolation.zig`
Escanea expresiones de interpolación.

**Maneja:**
- Escapado: `#{expresion}` (seguro para HTML)
- Sin escapar: `!{html_crudo}` (salida cruda)
- Llaves anidadas: `#{obj.fn({key: value})}`

**Transiciones de Estado:**
- Mantiene el estado actual (puede aparecer en texto o atributos)

**Ejemplo:**
```pug
#{nombre}    → EscapedInterpol("nombre")
!{html}      → UnescapedInterpol("html")
#{user.edad} → EscapedInterpol("user.edad")
```

#### 6. `scanSymbol.zig`
Escanea símbolos, operadores y sintaxis abreviada de Pug.

**Maneja:**
- Abreviaciones: `.class`, `#id`
- Paréntesis: `(`, `)`
- Corchetes: `[`, `]`, `{`, `}`
- Operadores: `=`, `!=`, `>=`, `<=`, `==`, `&&`, `||`
- Puntuación: `,`, `:`, `|`

**Transiciones de Estado:**
- `.class` → `TagClass` (en contexto de tag)
- `#id` → `TagId` (en contexto de tag)
- `(` → `AttrStart` (cuando en TagStart/TagClass/TagId)
- `)` → `TagStart` (cerrando atributos)
- `=` → `AttrEquals` (en AttrName)

**Ejemplos Sensibles al Contexto:**
```pug
div.container  → Ident("div"), Class("container")
              (estado: Root → TagStart → TagClass)

p Texto con .punto y #hash
              → Ident("p"), Ident("Texto"), ...
              (. y # son texto plano en estado Text)
```

#### 7. `scanText.zig`
Escanea contenido de texto plano.

**Maneja:**
- Cualquier texto hasta newline
- Se detiene en interpolación `#{}`
- Previene que `.class` y `#id` sean tokenizados en texto

**Transiciones de Estado:**
- `Text` → `Root` (en newline)

**Ejemplo:**
```pug
p Este es texto con #hashtag y .punto
  └─ Modo texto: todo después del espacio es texto
     Token: Ident("Este es texto con #hashtag y .punto")
```

---

### Transiciones de Estado

Representación visual del flujo de estados:

```
┌─────────────────────────────────────────────────────────────┐
│              MÁQUINA DE ESTADOS DEL TOKENIZER                │
└─────────────────────────────────────────────────────────────┘

INICIO (Root)
    │
    ├─ Identificador + (.|#|() ─────► TagStart
    │                                  │
    │                                  ├─ .class ──► TagClass ─┐
    │                                  ├─ #id ─────► TagId ────┤
    │                                  └─ ( ───────► AttrStart │
    │                                                    │      │
    ├─ Identificador (simple) ──────► Root (bucle)      │      │
    │                                                    │      │
    └─ Newline ────────────────────► Root (reinicio)    │      │
                                                         │      │
AttrStart ◄──────────────────────────────────────────────┘      │
    │                                                            │
    ├─ Identificador ──────────────────► AttrName               │
    │                                      │                     │
    │                                      ├─ = ──► AttrEquals  │
    │                                      │           │         │
    │                                      │           ├─ "..." ► AttrString ─┐
    │                                      │           └─ expr ► AttrValue ───┤
    │                                      │                                   │
    │                                      ├─ , ──► AttrName (bucle) ◄────────┤
    │                                      └─ ) ──────────────────────────────┘
    │                                           │
    └───────────────────────────────────────────┴──► TagStart o Text
```

**Comportamiento de Newline:**
- **Siempre** reinicia el estado a `Root`
- Activa el manejo de indentación
- Emite tokens INDENT/DEDENT según sea necesario

---

### Tipos de Token

Definidos en `src/tokenizer/TokenType.zig`:

| Categoría | Tokens | Ejemplo |
|-----------|--------|---------|
| **Identificadores** | `Ident` | `div`, `miClase` |
| **Keywords** | `If`, `Else`, `Each`, `Mixin`, `Include`, `Extends`, `Block` | `if`, `each` |
| **Literales** | `String`, `Number`, `Boolean` | `"hola"`, `42`, `true` |
| **Abreviaciones** | `Class`, `Id` | `.container`, `#main` |
| **Interpolación** | `EscapedInterpol`, `UnescapedInterpol` | `#{x}`, `!{y}` |
| **Comentarios** | `BufferedComment`, `UnbufferedComment` | `//`, `//-` |
| **Símbolos** | `LParen`, `RParen`, `LBracket`, `RBracket`, `LBrace`, `RBrace` | `(`, `)`, `[`, `]` |
| **Operadores** | `BufferedCode`, `UnescapedCode`, `Equal`, `Greater`, `Less` | `=`, `!=`, `==` |
| **Estructura** | `Newline`, `Indent`, `Dedent`, `Eof` | `\n`, INDENT, DEDENT |
| **Especiales** | `Doctype`, `Dot`, `Hash`, `Comma`, `Colon`, `Pipe` | `doctype`, `.`, `#` |

---

### Ejemplos de Uso

#### Tokenización Básica

```zig
const std = @import("std");
const Tokenizer = @import("tokenizer.zig").Tokenizer;

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source =
        \\div.container
        \\  p Hola #{nombre}
    ;

    var tokenizer = try Tokenizer.init(allocator, source);
    defer tokenizer.deinit();

    while (true) {
        const token = try tokenizer.next();
        std.debug.print("{s}({s})\n", .{
            @tagName(token.type),
            token.value,
        });
        if (token.type == .Eof) break;
    }
}
```

**Salida:**
```
Ident(div)
Class(container)
Newline()
Indent()
Ident(p)
Ident(Hola)
EscapedInterpol(nombre)
Dedent()
Eof()
```

#### Plantilla Compleja

```pug
doctype html
html
  head
    title Mi Sitio
  body.main-content#app(data-theme="dark")
    h1 Bienvenido #{user.name}
    //- Este es un comentario
    ul
      each item in items
        li= item.title
```

**Flujo de Tokens:**
```
Doctype(doctype html)
Newline()
Ident(html)              estado: Root → TagStart
Newline()                estado: TagStart → Root
Indent()
Ident(head)              estado: Root → TagStart
...
Class(main-content)      estado: TagClass
Id(app)                  estado: TagId
LParen()                 estado: AttrStart
Ident(data-theme)        estado: AttrName
BufferedCode(=)          estado: AttrEquals
String(dark)             estado: AttrString → AttrName
RParen()                 estado: TagStart
...
```

---

### Extendiendo el Tokenizer

#### Agregando un Nuevo Tipo de Token

1. **Agregar a `TokenType.zig`:**
```zig
pub const TokenType = enum {
    // ... tipos existentes ...
    NuevoTipoToken,
};
```

2. **Crear función de escaneo** `src/tokenizer/scanNuevoToken.zig`:
```zig
const Token = @import("Token.zig").Token;
const TokenType = @import("TokenType.zig").TokenType;

pub fn scanNuevoToken(tokenizer: anytype) !Token {
    const start_line = tokenizer.line;
    const start_col = tokenizer.column;

    // Lógica de escaneo aquí
    const value = tokenizer.source[start..tokenizer.pos];

    // Transición de estado si es necesario
    tokenizer.state = .NuevoEstado;

    return Token.init(.NuevoTipoToken, value, start_line, start_col);
}
```

3. **Importar en `tokenizer.zig`:**
```zig
const scanNuevoToken = @import("./tokenizer/scanNuevoToken.zig").scanNuevoToken;
```

4. **Agregar a máquina de estados:**
```zig
return switch (self.state) {
    .AlgunEstado => {
        if (condicion) return scanNuevoToken(self);
        // ...
    },
    // ...
};
```

#### Agregando un Nuevo Estado

1. **Agregar a `TokenizerState.zig`:**
```zig
pub const TokenizerState = enum {
    // ... estados existentes ...
    NuevoEstado,
};
```

2. **Actualizar switch de `next()`:**
```zig
return switch (self.state) {
    .NuevoEstado => {
        // Manejar tokens en este estado
        if (ch == 'x') return scanAlgo(self);
        // ...
    },
    // ...
};
```

3. **Agregar lógica de transición** en funciones de escaneo relevantes:
```zig
// En scanAlgo.zig
tokenizer.state = .NuevoEstado; // Transición al nuevo estado
```

---

### Consideraciones de Rendimiento

#### Por Qué Labeled-Switch es Más Rápido

**Comparación de Ensamblador:**

Switch tradicional en bucle:
```asm
.L2:
    mov     eax, DWORD PTR [state]
    cmp     eax, 1
    je      .L3
    cmp     eax, 2
    je      .L4
    jmp     .L2          ; Volver al inicio del bucle
.L3:
    mov     DWORD PTR [state], 2
    jmp     .L2
```

Labeled-switch:
```asm
    jmp     qword ptr [8*rax + .LJTI0_0]  ; Salto computado directo
.L3:
    // Código EstadoA
.L4:
    // Código EstadoB
```

**Beneficios:**
1. **Saltos directos**: Sin verificación de condición de bucle
2. **Mejor predicción de ramas**: CPU puede predecir saltos computados
3. **Menos instrucciones**: Menor sobrecarga por transición

#### Optimización de Ruta Caliente

El tokenizer optimiza casos comunes:

```zig
// Ruta rápida para tokens comunes antes de la máquina de estados
if (ch == '\n') {
    // Manejo inmediato, sin switch de estado
    self.at_line_start = true;
    self.state = .Root;
    return Token.init(.Newline, "\n", line, 1);
}

// Comentarios (comunes en plantillas)
if (ch == '/' and self.peekAhead(1) == '/') {
    return scanComment(self);
}

// Interpolación (muy común)
if ((ch == '#' or ch == '!') and self.peekAhead(1) == '{') {
    return scanInterpolation(self);
}
```

#### Eficiencia de Memoria

- **Reutilización de tokens**: Los tokens contienen slices al source, no copias
- **Asignación en stack**: Los tokens típicamente se asignan en stack
- **Uso mínimo de heap**: Solo para indent_stack y pending_tokens

---

## References / Referencias

- [Labeled Switch Article](https://simonklee.dk/labeled-switch) - Original article on labeled-switch pattern
- [Zig Language Reference](https://ziglang.org/documentation/master/) - Zig documentation
- [Pug Syntax](https://pugjs.org/) - Pug template language specification

---

**Last Updated:** December 2025
**Version:** 0.3.8
**Authors:** zig-pug team
