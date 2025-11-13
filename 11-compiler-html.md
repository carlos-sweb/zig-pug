# Paso 11: Compilador a HTML

## Objetivo
Compilar AST a HTML utilizando el contexto de datos.

---

## Tareas

### 11.1 Estructura del Compiler

```zig
pub const Compiler = struct {
    allocator: std.mem.Allocator,
    output: std.ArrayList(u8),
    indent_level: usize,
    pretty_print: bool,

    pub fn compile(self: *Compiler, ast: *AstNode, context: *Context) ![]u8 {
        try self.compileNode(ast, context);
        return self.output.toOwnedSlice();
    }
};
```

### 11.2 Compilación de Nodos

#### Tags
```zig
fn compileTag(self: *Compiler, tag: *TagNode, context: *Context) !void {
    try self.writeIndent();
    try self.output.appendSlice("<");
    try self.output.appendSlice(tag.name);

    // Attributes
    for (tag.attributes.items) |attr| {
        try self.compileAttribute(attr, context);
    }

    if (tag.is_self_closing) {
        try self.output.appendSlice(" />");
        return;
    }

    try self.output.appendSlice(">");

    // Children
    for (tag.children.items) |child| {
        try self.compileNode(child, context);
    }

    try self.output.appendSlice("</");
    try self.output.appendSlice(tag.name);
    try self.output.appendSlice(">");
}
```

#### Text
```zig
fn compileText(self: *Compiler, text: *TextNode, context: *Context) !void {
    if (text.is_raw) {
        try self.output.appendSlice(text.content);
    } else {
        try self.writeEscaped(text.content);
    }
}
```

### 11.3 HTML Escaping

```zig
fn writeEscaped(self: *Compiler, text: []const u8) !void {
    for (text) |ch| {
        switch (ch) {
            '<' => try self.output.appendSlice("&lt;"),
            '>' => try self.output.appendSlice("&gt;"),
            '&' => try self.output.appendSlice("&amp;"),
            '"' => try self.output.appendSlice("&quot;"),
            '\'' => try self.output.appendSlice("&#39;"),
            else => try self.output.append(ch),
        }
    }
}
```

### 11.4 Pretty Printing

```zig
fn writeIndent(self: *Compiler) !void {
    if (!self.pretty_print) return;
    var i: usize = 0;
    while (i < self.indent_level) : (i += 1) {
        try self.output.appendSlice("  ");
    }
}
```

---

## Entregables
- Compilador HTML funcional
- HTML escapado correcto
- Pretty printing opcional
- Tests de output

---

## Siguiente Paso
**12-runtime.md** para runtime de ejecución.
