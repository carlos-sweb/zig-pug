# Tokenizador - Análisis Léxico

El **Tokenizador** es la primera fase del pipeline de compilación de zig-pug. Convierte el código fuente de plantilla Pug en un flujo de tokens que el analizador sintáctico puede procesar.

## Descripción General

El tokenizador lee el código fuente carácter por carácter y los agrupa en tokens significativos. Maneja:

- **Indentación significativa para espacios en blanco** (como Python)
- **Palabras clave e identificadores** (nombres de etiquetas, nombres de variables)
- **Literales** (cadenas, números, booleanos)
- **Sintaxis especial** (`.class`, `#id`, `#{interpolación}`)
- **Comentarios** (`//` almacenados en búfer, `//-` no almacenados, `//!` documentación)
- **Marcadores de código** (`=`, `!=`, `-`, `|`)

## Arquitectura

### Ubicación: `src/tokenizer/`

```
src/tokenizer/
├── mod.zig              # Punto de entrada principal con estructura Tokenizer
├── TokenType.zig        # Enumeración de todos los tipos de token
├── Token.zig            # Estructura de datos Token
├── TokenizerState.zig   # Estados de la máquina de estados
├── TokenizerError.zig   # Tipos de error
├── scanComment.zig      # Escaneo de comentarios
├── scanIdentifier.zig   # Escaneo de identificadores/palabras clave
├── scanInterpolation.zig # Escaneo de interpolación
├── scanNumber.zig       # Escaneo de literales numéricos
├── scanString.zig       # Escaneo de literales de cadena
├── scanSymbol.zig       # Escaneo de símbolos/operadores
├── scanText.zig         # Escaneo de texto simple
└── tests.zig           # Suite de pruebas del tokenizador
```

## Máquina de Estados

El tokenizador utiliza una **máquina de estados con switch etiquetado** para el reconocimiento eficiente de tokens:

### Estados

1. **Root**: Inicio de una línea, esperando etiqueta/palabra clave
2. **Indent**: Después de indentación, esperando contenido
3. **TagStart**: Después del nombre de etiqueta, puede aceptar `.class`, `#id`, `(attrs)`
4. **TagClass**: Después de la abreviatura de clase
5. **TagId**: Después de la abreviatura de id
6. **AttrStart**: Dentro de paréntesis de atributo `(`
7. **AttrName**: Nombre de atributo
8. **AttrEquals**: Después de `=` en atributo
9. **AttrValue**: Valor de atributo
10. **AttrString**: Valor de atributo de cadena
11. **AttrJS**: Expresión JavaScript en atributo
12. **Text**: Contenido de texto simple
13. **Code**: Contexto de expresión JavaScript (después de `=`, `!=`, `-`)

### Transiciones de Estado

```
Root/Indent
  ├─> TagStart (en nombre de etiqueta)
  ├─> Code (en =, !=, -)
  └─> Text (en contenido de texto)

TagStart
  ├─> TagClass (en .class)
  ├─> TagId (en #id)
  ├─> AttrStart (en '(')
  └─> Text (en espacio)

AttrStart
  ├─> AttrName (en identificador)
  ├─> AttrEquals (en '=')
  └─> TagStart (en ')')

Code
  └─> Root (en nueva línea)
```

## Tipos de Token

### Tokens Estructurales
- `Indent` / `Dedent`: Cambios de indentación
- `Newline`: Salto de línea
- `Eof`: Fin de archivo

### Tokens de Identificador
- `Ident`: Nombres de variable/etiqueta
- `Class`: Abreviatura `.classname`
- `Id`: Abreviatura `#idname`

### Tokens de Literal
- `String`: `"texto"` o `'texto'`
- `Number`: `123`, `45.67`
- `Boolean`: `true`, `false`

### Tokens de Palabra Clave
- Control de flujo: `If`, `Else`, `Unless`, `Each`, `While`, `Case`, `When`, `Default`
- Plantillas: `Mixin`, `Include`, `Extends`, `Block`, `Append`, `Prepend`
- Especiales: `Doctype`

### Tokens de Símbolo
- Paréntesis: `LParen` `(`, `RParen` `)`
- Corchetes: `LBracket` `[`, `RBracket` `]`
- Llaves: `LBrace` `{`, `RBrace` `}`
- Operadores: `Dot` `.`, `Comma` `,`, `Colon` `:`, `Pipe` `|`
- Comparación: `Equal` `==`, `Greater` `>`, `Less` `<`, `GreaterEqual` `>=`, `LessEqual` `<=`
- Lógicos: `And` `&&`, `Or` `||`

### Marcadores de Código
- `BufferedCode`: `=` (evaluar y salida escapada)
- `UnescapedCode`: `!=` (evaluar y salida sin procesar)
- `UnbufferedCode`: `-` (ejecutar sin salida)

### Comentarios
- `BufferedComment`: `//` (emitido a HTML)
- `UnbufferedComment`: `//-` (no incluido en salida)
- Los comentarios de documentación `//!` se ignoran completamente

### Interpolación
- `EscapedInterpol`: `#{expr}` (salida escapada en HTML)
- `UnescapedInterpol`: `!{expr}` (salida HTML sin procesar)

## Manejo de Indentación

El tokenizador rastrea los niveles de indentación y genera tokens `INDENT`/`DEDENT` similares a Python:

```pug
div
  p Hello    # INDENT emitido
  p World
span          # DEDENT emitido
```

### Reglas
- Solo se permiten **espacios** (las tabulaciones causan error `InvalidIndentation`)
- Indentación aumentada → emite token `INDENT`
- Indentación disminuida → emite uno o más tokens `DEDENT`
- Las líneas vacías se omiten

## Soporte UTF-8

El tokenizador soporta completamente UTF-8:

- **Secuencias multibyte**: Emojis, caracteres acentuados, chino/japonés/etc.
- **Identificadores**: `div.clase-española`, `p #{名前}`
- **Contenido de texto**: Cualquier cadena UTF-8 válida

### Funciones UTF-8
- `isUtf8Start(byte)`: Verificar si byte inicia una secuencia UTF-8
- `utf8SequenceLength(first_byte)`: Obtener longitud de secuencia (1-4 bytes)
- `isValidTextByte(byte)`: Verificar si byte es válido en texto

## Ejemplo de Tokenización

### Entrada
```pug
div.container#main
  p Hello #{name}
  // This is a comment
```

### Flujo de Tokens
```
Ident("div")
Class("container")
Id("main")
Newline
Indent
Ident("p")
Ident("Hello")
EscapedInterpol("name")
Newline
BufferedComment("This is a comment")
Newline
Dedent
Eof
```

## Uso de API

### Inicialización

```zig
const std = @import("std");
const Tokenizer = @import("tokenizer/mod.zig").Tokenizer;

var tokenizer = try Tokenizer.init(allocator, source);
defer tokenizer.deinit();
```

### Iteración de Token

```zig
while (true) {
    const token = try tokenizer.next();
    if (token.type == .Eof) break;

    std.debug.print("{s} at {}:{}\n", .{
        @tagName(token.type),
        token.line,
        token.column
    });
}
```

## Manejo de Errores

### Tipos de Error
- `InvalidIndentation`: Se usaron tabulaciones o dedentación inconsistente
- `UnterminatedString`: Cadena no cerrada
- `UnexpectedCharacter`: Carácter inválido en contexto

### Recuperación de Errores
Los errores incluyen información de línea y columna para reportes de error precisos a los usuarios.

## Rendimiento

- **Paso único**: Se escanea la fuente una vez
- **Sin copia**: Los tokens hacen referencia a fragmentos de fuente (sin asignación)
- **Lookahead**: Máximo 2 caracteres (`//`, `#{`, etc.)
- **Eficiente**: Usa switch etiquetado para mejor predicción de rama

## Pruebas

Ejecutar pruebas del tokenizador:
```bash
zig test src/tokenizer/tests.zig
```

Las pruebas cubren:
- Todos los tipos de token
- Seguimiento de indentación
- Manejo UTF-8
- Casos de error
- Casos extremos (archivos vacíos, etc.)

## Ver También

- [Analizador Sintáctico](parser.md) - Análisis sintáctico (siguiente fase)
- [AST](ast.md) - Estructura del Árbol de Sintaxis Abstracta
- [Compilador](compiler.md) - Generación de HTML
