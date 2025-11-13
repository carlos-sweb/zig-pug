# Paso 6: Parser Base

## Objetivo
Implementar parser básico que convierte tokens en AST.

---

## Estructura del Parser

```zig
pub const Parser = struct {
    tokenizer: Tokenizer,
    current: ?Token,
    allocator: std.mem.Allocator,
    arena: std.heap.ArenaAllocator,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Parser {
        var tokenizer = try Tokenizer.init(allocator, source);
        const current = try tokenizer.next();
        return .{
            .tokenizer = tokenizer,
            .current = current,
            .allocator = allocator,
            .arena = std.heap.ArenaAllocator.init(allocator),
        };
    }

    pub fn deinit(self: *Parser) void {
        self.arena.deinit();
        self.tokenizer.deinit();
    }
};
```

---

## Funciones Auxiliares

```zig
fn advance(self: *Parser) !void {
    self.current = try self.tokenizer.next();
}

fn expect(self: *Parser, expected: TokenType) !Token {
    if (self.current) |token| {
        if (token.type == expected) {
            const result = token;
            try self.advance();
            return result;
        }
    }
    return error.UnexpectedToken;
}

fn match(self: *Parser, types: []const TokenType) bool {
    if (self.current) |token| {
        for (types) |t| {
            if (token.type == t) return true;
        }
    }
    return false;
}
```

---

## Parser de Tags Básicos

```zig
pub fn parseTag(self: *Parser) !*AstNode {
    const token = try self.expect(.Ident);
    const allocator = self.arena.allocator();

    var tag_node = try allocator.create(TagNode);
    tag_node.* = .{
        .name = token.value,
        .attributes = std.ArrayList(*AttributeNode).init(allocator),
        .children = std.ArrayList(*AstNode).init(allocator),
        .is_self_closing = false,
    };

    // Parse classes and ids (.class, #id)
    while (self.match(&.{.Dot, .Hash})) {
        try self.parseClassOrId(tag_node);
    }

    // Parse attributes (...)
    if (self.match(&.{.LParen})) {
        try self.parseAttributes(tag_node);
    }

    // Parse inline text
    if (self.current) |token| {
        if (token.type != .Newline and token.type != .Indent) {
            try self.parseInlineText(tag_node);
        }
    }

    // Parse children
    if (self.match(&.{.Newline})) {
        try self.advance();
        if (self.match(&.{.Indent})) {
            try self.advance();
            try self.parseChildren(tag_node);
            try self.expect(.Dedent);
        }
    }

    var node = try allocator.create(AstNode);
    node.* = .{
        .type = .Tag,
        .line = token.line,
        .column = token.column,
        .data = .{ .Tag = tag_node.* },
    };

    return node;
}
```

---

## Parser de Atributos

```zig
fn parseAttributes(self: *Parser, tag: *TagNode) !void {
    try self.expect(.LParen);

    while (!self.match(&.{.RParen, .Eof})) {
        const name_token = try self.expect(.Ident);

        var attr = try self.arena.allocator().create(AttributeNode);
        attr.* = .{
            .name = name_token.value,
            .value = null,
            .is_unescaped = false,
        };

        // Parse attribute value
        if (self.match(&.{.Assign})) {
            try self.advance();
            attr.value = try self.parseExpression();
        }

        try tag.attributes.append(attr);

        // Skip comma if present
        if (self.match(&.{.Comma})) {
            try self.advance();
        }
    }

    try self.expect(.RParen);
}
```

---

## Parser de Texto

```zig
fn parseText(self: *Parser) !*AstNode {
    const allocator = self.arena.allocator();
    var content = std.ArrayList(u8).init(allocator);

    while (self.current) |token| {
        if (token.type == .Newline or token.type == .Indent) break;

        try content.appendSlice(token.value);
        try self.advance();
    }

    var text_node = try allocator.create(TextNode);
    text_node.* = .{
        .content = try content.toOwnedSlice(),
        .is_raw = false,
    };

    var node = try allocator.create(AstNode);
    node.* = .{
        .type = .Text,
        .line = 0,
        .column = 0,
        .data = .{ .Text = text_node.* },
    };

    return node;
}
```

---

## Parser Principal

```zig
pub fn parse(self: *Parser) !*AstNode {
    const allocator = self.arena.allocator();

    var doc = try allocator.create(DocumentNode);
    doc.* = .{
        .children = std.ArrayList(*AstNode).init(allocator),
        .doctype = null,
    };

    while (self.current) |token| {
        if (token.type == .Eof) break;

        const child = try self.parseStatement();
        try doc.children.append(child);
    }

    var node = try allocator.create(AstNode);
    node.* = .{
        .type = .Document,
        .line = 0,
        .column = 0,
        .data = .{ .Document = doc.* },
    };

    return node;
}

fn parseStatement(self: *Parser) !*AstNode {
    if (self.current) |token| {
        return switch (token.type) {
            .Ident => try self.parseTag(),
            .Pipe => try self.parsePipeText(),
            .BufferedComment, .UnbufferedComment => try self.parseComment(),
            .UnbufferedCode, .BufferedCode, .UnescapedCode => try self.parseCode(),
            .If, .Unless => try self.parseConditional(),
            .Each, .While => try self.parseLoop(),
            .Case => try self.parseCase(),
            else => error.UnexpectedToken,
        };
    }
    return error.UnexpectedEndOfInput;
}
```

---

## Tests

```zig
test "parser - simple tag" {
    const allocator = std.testing.allocator;
    var parser = try Parser.init(allocator, "div");
    defer parser.deinit();

    const ast = try parser.parse();
    try std.testing.expectEqual(NodeType.Document, ast.type);
}

test "parser - tag with class" {
    const allocator = std.testing.allocator;
    var parser = try Parser.init(allocator, "div.container");
    defer parser.deinit();

    const ast = try parser.parse();
    // Verificar que tiene clase "container"
}

test "parser - tag with attributes" {
    const allocator = std.testing.allocator;
    var parser = try Parser.init(allocator, "a(href='google.com')");
    defer parser.deinit();

    const ast = try parser.parse();
    // Verificar atributos
}
```

---

## Entregables
1. Parser base funcional
2. Parsing de tags, atributos, texto
3. Tests básicos pasando
4. Mensajes de error con línea/columna

---

## Siguiente Paso
Continuar con **07-parser-core.md** para características core de Pug.
