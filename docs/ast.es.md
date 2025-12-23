# AST - Árbol de Sintaxis Abstracta

El **AST** (Árbol de Sintaxis Abstracta) es la representación intermedia de una plantilla Pug después del análisis. Es una estructura de árbol que representa la naturaleza jerárquica y el significado semántico de la plantilla.

## Descripción General

El AST es creado por el analizador y consumido por el compilador. Proporciona:

- **Estructura jerárquica**: Relaciones padre-hijo
- **Seguridad de tipo**: Cada nodo tiene un tipo específico
- **Ubicación de fuente**: Línea y columna para reportes de error
- **Inmutabilidad**: El árbol no cambia después del análisis
- **Patrón Visitor**: Fácil recorrido de árbol

## Arquitectura

### Ubicación: `src/ast/`

```
src/ast/
├── mod.zig              # API pública y re-exportaciones
├── NodeType.zig         # Enumeración de todos los tipos de nodo
├── AstNode.zig          # Estructura de nodo central y unión NodeData
├── Visitor.zig          # Patrón Visitor para recorrido de árbol
├── printer.zig          # Utilidad de depuración para visualizar árboles
├── tests.zig            # Suite de pruebas de AST
└── nodes/               # Definiciones de tipos de nodo
    ├── DocumentNode.zig      # Nodo raíz de documento
    ├── TagNode.zig           # Etiquetas HTML y atributos
    ├── TextNode.zig          # Texto e interpolación
    ├── CodeNode.zig          # Bloques de código y comentarios
    ├── ControlFlowNode.zig   # Condicionales, bucles, case
    ├── MixinNode.zig         # Definiciones y llamadas de mixin
    └── TemplateNode.zig      # Include, extends, bloques
```

## Estructura de Nodo

### AstNode

Cada nodo AST tiene la misma estructura:

```zig
pub const AstNode = struct {
    type: NodeType,        // Qué tipo de nodo es
    line: usize,           // Línea de fuente (1-indexado)
    column: usize,         // Columna de fuente (1-indexado)
    data: NodeData,        // Datos específicos del tipo (unión)
}
```

### Enumeración NodeType

```zig
pub const NodeType = enum {
    Document,      // Nodo raíz
    Tag,           // Etiqueta HTML
    Text,          // Texto simple
    Interpolation, // #{expr} o !{expr}
    Code,          // =, !=, - código
    Conditional,   // if/else/unless
    Loop,          // each/while
    MixinDef,      // definición de mixin
    MixinCall,     // llamada +mixin()
    Include,       // directiva include
    Block,         // definición de bloque
    Extends,       // directiva extends
    Comment,       // comentario // o //-
    Case,          // sentencia case
    When,          // cláusula when
};
```

### Unión NodeData

Una unión discriminada que contiene datos específicos del tipo:

```zig
pub const NodeData = union(NodeType) {
    Document: DocumentNode,
    Tag: TagNode,
    Text: TextNode,
    Interpolation: InterpolationNode,
    Code: CodeNode,
    Conditional: ConditionalNode,
    Loop: LoopNode,
    MixinDef: MixinDefNode,
    MixinCall: MixinCallNode,
    Include: IncludeNode,
    Block: BlockNode,
    Extends: ExtendsNode,
    Comment: CommentNode,
    Case: CaseNode,
    When: WhenNode,
};
```

## Tipos de Nodo

### 1. DocumentNode

Nodo raíz que contiene todos los nodos de nivel superior:

```zig
pub const DocumentNode = struct {
    children: std.ArrayListUnmanaged(*AstNode),
    doctype: ?[]const u8,  // p.ej., "html", "xml"
};
```

**Ejemplo**:
```pug
doctype html
html
  body
```

### 2. TagNode

Etiqueta HTML con atributos e hijos:

```zig
pub const TagNode = struct {
    name: []const u8,                         // "div", "p", "span"
    attributes: std.ArrayListUnmanaged(Attribute),
    children: std.ArrayListUnmanaged(*AstNode),
    is_self_closing: bool,                    // <img />, <br />
};

pub const Attribute = struct {
    name: []const u8,
    value: ?[]const u8,
    is_unescaped: bool,      // != vs =
    is_expression: bool,     // class=myVar vs class="static"
};
```

**Ejemplo**:
```pug
div.container#main(data-value="test")
  p Content
```

### 3. TextNode e InterpolationNode

Contenido de texto y expresiones incrustadas:

```zig
pub const TextNode = struct {
    content: []const u8,
    is_raw: bool,  // Texto con pipe |
};

pub const InterpolationNode = struct {
    expression: []const u8,  // Código JavaScript
    is_unescaped: bool,      // !{} vs #{}
};
```

**Ejemplo**:
```pug
p Hello #{name}
p !{rawHtml}
| Plain text
```

### 4. CodeNode y CommentNode

Ejecución de código y comentarios:

```zig
pub const CodeNode = struct {
    code: []const u8,
    is_buffered: bool,    // = o != (salida)
    is_unescaped: bool,   // != (HTML sin procesar)
};

pub const CommentNode = struct {
    content: []const u8,
    is_buffered: bool,    // // (en HTML) vs //- (eliminado)
};
```

**Ejemplo**:
```pug
= user.name
!= rawContent
- var x = 10
// HTML comment
//- Code comment
```

### 5. ConditionalNode

Sentencias if/else/unless:

```zig
pub const ConditionalNode = struct {
    condition: []const u8,                    // Expresión JavaScript
    then_branch: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_unless: bool,                          // unless vs if
};
```

**Ejemplo**:
```pug
if loggedIn
  p Welcome
else
  p Login
```

### 6. LoopNode

Iteración each/while:

```zig
pub const LoopNode = struct {
    iterator: []const u8,     // "item"
    index: ?[]const u8,       // "i" (opcional)
    iterable: []const u8,     // "items" o condición
    body: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_while: bool,
};
```

**Ejemplo**:
```pug
each item, i in items
  li #{i}: #{item}

while hasMore
  p Loading...
```

### 7. CaseNode y WhenNode

Concordancia de estilo switch:

```zig
pub const CaseNode = struct {
    expression: []const u8,
    cases: std.ArrayListUnmanaged(*AstNode),  // WhenNodes
    default: ?std.ArrayListUnmanaged(*AstNode),
};

pub const WhenNode = struct {
    values: std.ArrayListUnmanaged([]const u8),
    body: std.ArrayListUnmanaged(*AstNode),
};
```

**Ejemplo**:
```pug
case color
  when 'red', 'crimson'
    p Red
  default
    p Unknown
```

### 8. MixinDefNode y MixinCallNode

Bloques de plantilla reutilizables:

```zig
pub const MixinDefNode = struct {
    name: []const u8,
    params: std.ArrayListUnmanaged([]const u8),
    rest_param: ?[]const u8,   // ...args
    body: std.ArrayListUnmanaged(*AstNode),
};

pub const MixinCallNode = struct {
    name: []const u8,
    args: std.ArrayListUnmanaged([]const u8),
    attributes: std.ArrayListUnmanaged(Attribute),
    body: ?std.ArrayListUnmanaged(*AstNode),
};
```

**Ejemplo**:
```pug
mixin article(title, author)
  article
    h1= title
    p= author

+article("Hello", "John")
```

### 9. IncludeNode, BlockNode, ExtendsNode

Composición de plantilla:

```zig
pub const IncludeNode = struct {
    path: []const u8,
    filter: ?[]const u8,  // :markdown, etc.
};

pub const BlockMode = enum {
    Replace,   // Predeterminado
    Append,    // block append
    Prepend,   // block prepend
};

pub const BlockNode = struct {
    name: []const u8,
    mode: BlockMode,
    body: std.ArrayListUnmanaged(*AstNode),
};

pub const ExtendsNode = struct {
    path: []const u8,
};
```

**Ejemplo**:
```pug
extends layout.pug

block content
  p Child content

include header.pug
```

## Gestión de Memoria

Los nodos AST se asignan en un **ArenaAllocator**:

```zig
// El analizador es propietario de la arena
var parser = try Parser.init(allocator, source);
defer parser.deinit();  // Libera todos los nodos

const document = try parser.parse();
// Todos los nodos se liberan cuando se llama a parser.deinit()
```

Beneficios:
- **Asignación rápida**: Sin sobrecarga por nodo
- **Liberación rápida**: Una única liberación para todo el árbol
- **Sin fugas**: Imposible olvidar nodos individuales

## Patrón Visitor

Recorrer el árbol AST con lógica personalizada:

```zig
const MyContext = struct {
    count: usize,

    fn visitNode(ctx: *anyopaque, node: *AstNode) !void {
        const self: *MyContext = @ptrCast(@alignCast(ctx));
        self.count += 1;
    }
};

var ctx = MyContext{ .count = 0 };
var visitor = Visitor{
    .context = &ctx,
    .visitFn = MyContext.visitNode,
};

try visitor.visit(document);
// ctx.count ahora tiene el conteo total de nodos
```

## Impresión de Depuración

Imprimir estructura de árbol AST:

```zig
const printAst = @import("ast/mod.zig").printAst;

printAst(document, 0);
```

**Salida**:
```
Document (line 1)
  Tag (line 1)
    name: div
    attributes:
      class="container"
      id="main"
    Tag (line 2)
      name: p
      Text (line 2)
        content: "Hello"
```

## Ejemplo AST

### Entrada
```pug
div.container
  p Hello #{name}
  if admin
    button Edit
```

### Estructura AST
```
Document {
  children: [
    Tag {
      name: "div",
      attributes: [Attribute{name: "class", value: "container"}],
      children: [
        Tag {
          name: "p",
          children: [
            Text{content: "Hello "},
            Interpolation{expression: "name"}
          ]
        },
        Conditional {
          condition: "admin",
          then_branch: [
            Tag {
              name: "button",
              children: [Text{content: "Edit"}]
            }
          ]
        }
      ]
    }
  ]
}
```

## Uso de API

### Creación de Nodos

```zig
const ast = @import("ast/mod.zig");

const text_node = try ast.AstNode.create(
    allocator,
    .Text,
    5,    // línea
    10,   // columna
    .{ .Text = .{
        .content = "Hello",
        .is_raw = false,
    }}
);
```

### Acceso a Datos de Nodo

```zig
switch (node.type) {
    .Tag => |tag| {
        std.debug.print("Tag: {s}\n", .{tag.name});
        for (tag.children.items) |child| {
            // Procesar hijos
        }
    },
    .Text => |text| {
        std.debug.print("Text: {s}\n", .{text.content});
    },
    else => {},
}
```

## Pruebas

Ejecutar pruebas de AST:
```bash
zig test src/ast/tests.zig
```

Las pruebas cubren:
- Creación de nodos
- Gestión de memoria
- Patrón Visitor
- Todos los tipos de nodo

## Ver También

- [Tokenizador](tokenizer.md) - Análisis léxico
- [Analizador Sintáctico](parser.md) - Análisis sintáctico (crea AST)
- [Compilador](compiler.md) - Generación de HTML (consume AST)
