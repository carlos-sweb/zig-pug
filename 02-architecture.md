# Paso 2: Diseño de la Arquitectura

## Objetivo
Diseñar la arquitectura del sistema y sus componentes principales antes de comenzar la implementación.

## Descripción
Una arquitectura bien pensada es crítica para el éxito del proyecto. En este paso definiremos interfaces, flujo de datos, tipos fundamentales y el sistema de manejo de errores.

---

## Flujo de Datos del Sistema

```
┌─────────────┐
│ Template    │
│ (.pug file) │
└──────┬──────┘
       │
       ▼
┌─────────────┐      ┌─────────────┐
│ Tokenizer   │◄─────┤ Source      │
│ (Lexer)     │      │ Reader      │
└──────┬──────┘      └─────────────┘
       │
       │ Tokens
       ▼
┌─────────────┐
│ Parser      │
└──────┬──────┘
       │
       │ AST
       ▼
┌─────────────┐      ┌─────────────┐
│ Compiler    │◄─────┤ TOML Data   │
│             │      │ Parser      │
└──────┬──────┘      └─────────────┘
       │
       │ + Runtime Context
       ▼
┌─────────────┐      ┌─────────────┐
│ Runtime     │◄─────┤ JavaScript  │
│ Executor    │      │ Engine      │
└──────┬──────┘      └─────────────┘
       │
       │ HTML
       ▼
┌─────────────┐
│ HTML Output │
└─────────────┘
```

---

## Componentes Principales

### 1. Tokenizer (Lexer)
**Responsabilidad:** Convertir texto fuente en stream de tokens

**Interfaz:**
```zig
pub const Token = struct {
    type: TokenType,
    value: []const u8,
    line: usize,
    column: usize,
};

pub const Tokenizer = struct {
    source: []const u8,
    pos: usize,
    line: usize,
    column: usize,

    pub fn init(source: []const u8) Tokenizer;
    pub fn next(self: *Tokenizer) !?Token;
    pub fn peek(self: *Tokenizer) !?Token;
    pub fn skipWhitespace(self: *Tokenizer) void;
};
```

### 2. Parser
**Responsabilidad:** Convertir tokens en AST (Abstract Syntax Tree)

**Interfaz:**
```zig
pub const Parser = struct {
    tokenizer: Tokenizer,
    current_token: ?Token,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Parser;
    pub fn parse(self: *Parser) !*AstNode;
    pub fn parseTag(self: *Parser) !*TagNode;
    pub fn parseAttributes(self: *Parser) ![]Attribute;
    pub fn parseExpression(self: *Parser) !*ExprNode;
};
```

### 3. AST (Abstract Syntax Tree)
**Responsabilidad:** Representar la estructura del template

**Interfaz:**
```zig
pub const NodeType = enum {
    Document,
    Tag,
    Text,
    Attribute,
    Interpolation,
    Code,
    Conditional,
    Loop,
    Mixin,
    Include,
    Block,
    Comment,
    Case,
};

pub const AstNode = struct {
    type: NodeType,
    line: usize,
    column: usize,
    // Datos específicos según tipo
};
```

### 4. Compiler
**Responsabilidad:** Compilar AST a HTML

**Interfaz:**
```zig
pub const Compiler = struct {
    allocator: std.mem.Allocator,
    output: std.ArrayList(u8),
    indent_level: usize,

    pub fn init(allocator: std.mem.Allocator) Compiler;
    pub fn compile(self: *Compiler, ast: *AstNode, context: *Context) ![]u8;
    pub fn compileTag(self: *Compiler, node: *TagNode, context: *Context) !void;
    pub fn escape(self: *Compiler, text: []const u8) !void;
};
```

### 5. Runtime Context
**Responsabilidad:** Mantener estado durante ejecución del template

**Interfaz:**
```zig
pub const Context = struct {
    allocator: std.mem.Allocator,
    data: std.StringHashMap(Value),
    parent: ?*Context,

    pub fn init(allocator: std.mem.Allocator) Context;
    pub fn set(self: *Context, key: []const u8, value: Value) !void;
    pub fn get(self: *Context, key: []const u8) ?Value;
    pub fn push(self: *Context) !*Context;
    pub fn pop(self: *Context) void;
};
```

### 6. TOML Parser
**Responsabilidad:** Parsear datos de entrada TOML

**Interfaz:**
```zig
pub const TomlParser = struct {
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) TomlParser;
    pub fn parse(self: *TomlParser, source: []const u8) !Value;
    pub fn toContext(self: *TomlParser, value: Value) !Context;
};
```

### 7. JavaScript Engine (Integración)
**Responsabilidad:** Ejecutar bloques JavaScript

**Interfaz:**
```zig
pub const JsEngine = struct {
    // Detalles de implementación dependen de engine elegido
    pub fn init(allocator: std.mem.Allocator) !JsEngine;
    pub fn eval(self: *JsEngine, code: []const u8, context: *Context) !Value;
    pub fn defineFunction(self: *JsEngine, name: []const u8, func: JsFunction) !void;
};
```

---

## Tipos de Datos Fundamentales

### TokenType
```zig
pub const TokenType = enum {
    // Identificadores
    Ident,
    Class,           // .classname
    Id,              // #idname

    // Literales
    String,
    Number,
    Boolean,

    // Símbolos
    LParen,          // (
    RParen,          // )
    LBracket,        // [
    RBracket,        // ]
    LBrace,          // {
    RBrace,          // }
    Dot,             // .
    Hash,            // #
    Comma,           // ,
    Colon,           // :
    Pipe,            // |

    // Operadores
    Assign,          // =
    NotEqual,        // !=
    Plus,            // +
    Minus,           // -

    // Keywords
    If,
    Else,
    Unless,
    Each,
    While,
    Case,
    When,
    Default,
    Mixin,
    Include,
    Extends,
    Block,
    Append,
    Prepend,

    // Especiales
    Indent,
    Dedent,
    Newline,
    Comment,
    BufferedCode,    // =
    UnbufferedCode,  // -
    UnescapedCode,   // !=
    InterpolStart,   // #{
    InterpolEnd,     // }

    Eof,
};
```

### Value (Sistema de tipos runtime)
```zig
pub const ValueType = enum {
    Null,
    Boolean,
    Integer,
    Float,
    String,
    Array,
    Object,
    Function,
};

pub const Value = union(ValueType) {
    Null: void,
    Boolean: bool,
    Integer: i64,
    Float: f64,
    String: []const u8,
    Array: std.ArrayList(Value),
    Object: std.StringHashMap(Value),
    Function: *const fn(*Context, []Value) anyerror!Value,
};
```

---

## Sistema de Manejo de Errores

### Error Types
```zig
pub const ZigPugError = error {
    // Tokenizer errors
    UnexpectedCharacter,
    InvalidIndentation,
    UnterminatedString,

    // Parser errors
    UnexpectedToken,
    ExpectedToken,
    InvalidSyntax,
    InvalidNesting,

    // Compiler errors
    UndefinedVariable,
    TypeError,

    // Runtime errors
    DivisionByZero,
    NullPointerAccess,

    // IO errors
    FileNotFound,
    AccessDenied,

    // Memory errors
    OutOfMemory,
};

pub const ErrorInfo = struct {
    err: ZigPugError,
    message: []const u8,
    line: usize,
    column: usize,
    source_line: ?[]const u8,
};
```

### Error Reporting
```zig
pub fn reportError(info: ErrorInfo) void {
    std.debug.print("Error at line {d}, column {d}: {s}\n",
        .{info.line, info.column, info.message});

    if (info.source_line) |line| {
        std.debug.print("  {s}\n", .{line});
        // Print caret pointing to error position
        var i: usize = 0;
        while (i < info.column - 1) : (i += 1) {
            std.debug.print(" ", .{});
        }
        std.debug.print("^\n", .{});
    }
}
```

---

## Estructura de Módulos

```
src/
├── main.zig              # Entry point, CLI
├── tokenizer.zig         # Tokenizer implementation
├── parser.zig            # Parser implementation
├── ast.zig               # AST types and utilities
├── compiler.zig          # Compiler implementation
├── runtime.zig           # Runtime context and execution
├── toml.zig              # TOML parser integration
├── js_engine.zig         # JavaScript engine integration
├── errors.zig            # Error types and reporting
├── utils.zig             # Utility functions
└── builtins.zig          # Built-in functions
```

---

## Decisiones Arquitectónicas

### 1. Memoria y Allocación
- Usar `ArenaAllocator` para AST (lifetime del árbol)
- Usar `GeneralPurposeAllocator` para runtime context
- Pool de strings para tokens comunes
- Ownership claro: quien crea, libera

### 2. Manejo de Strings
- Strings inmutables donde sea posible
- String interning para identificadores comunes
- UTF-8 nativo (Zig default)

### 3. Concurrencia
- Fase 1: Single-threaded
- Fase 2: Thread-safe compilation (opcional)
- Compilación paralela de múltiples templates (futuro)

### 4. Extensibilidad
- Sistema de plugins para filtros
- API pública estable
- Hooks para customización

### 5. Performance
- Zero-copy parsing donde sea posible
- Lazy evaluation cuando posible
- Cache de templates compilados
- Comptime evaluation para templates estáticos

---

## Entregables

1. Diagrama de arquitectura (este documento)
2. Definición de interfaces principales (código stub)
3. Documentación de tipos de datos fundamentales
4. Documentación de flujo de datos
5. Decisiones arquitectónicas documentadas

---

## Siguiente Paso
Una vez completado este paso y validado el diseño, continuar con **03-tokenizer-base.md** para implementar el tokenizer básico.

---

## Notas
- Esta arquitectura es flexible y puede evolucionar
- Priorizar simplicidad sobre optimización prematura
- Mantener separación clara de responsabilidades
- Documentar todas las decisiones importantes
