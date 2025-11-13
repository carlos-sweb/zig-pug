# Paso 4: Tokenizer Avanzado

## Objetivo
Agregar características avanzadas al tokenizer: manejo de indentación, keywords, comentarios, interpolación, y código.

---

## Tareas

### 4.1 Manejo de Indentación (INDENT/DEDENT)

La indentación en Pug es significativa. Necesitamos rastrear niveles de indentación y emitir tokens INDENT/DEDENT.

```zig
pub const Tokenizer = struct {
    // ... campos existentes ...
    indent_stack: std.ArrayList(usize),
    pending_tokens: std.ArrayList(Token),
    at_line_start: bool,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) !Tokenizer {
        var indent_stack = std.ArrayList(usize).init(allocator);
        try indent_stack.append(0); // Base level

        return .{
            .source = source,
            .pos = 0,
            .line = 1,
            .column = 1,
            .allocator = allocator,
            .indent_stack = indent_stack,
            .pending_tokens = std.ArrayList(Token).init(allocator),
            .at_line_start = true,
        };
    }

    fn handleIndentation(self: *Tokenizer) !void {
        if (!self.at_line_start) return;

        var indent: usize = 0;
        while (self.peek()) |ch| {
            if (ch == ' ') {
                indent += 1;
                _ = self.advance();
            } else if (ch == '\t') {
                return error.InvalidIndentation; // No permitir tabs
            } else {
                break;
            }
        }

        const current_indent = self.indent_stack.items[self.indent_stack.items.len - 1];

        if (indent > current_indent) {
            try self.indent_stack.append(indent);
            try self.pending_tokens.append(Token.init(.Indent, "", self.line, 1));
        } else if (indent < current_indent) {
            while (self.indent_stack.items.len > 0 and
                   self.indent_stack.items[self.indent_stack.items.len - 1] > indent) {
                _ = self.indent_stack.pop();
                try self.pending_tokens.append(Token.init(.Dedent, "", self.line, 1));
            }

            if (self.indent_stack.items.len == 0 or
                self.indent_stack.items[self.indent_stack.items.len - 1] != indent) {
                return error.InvalidIndentation;
            }
        }

        self.at_line_start = false;
    }
};
```

### 4.2 Reconocimiento de Keywords

```zig
const KEYWORDS = std.ComptimeStringMap(TokenType, .{
    .{ "if", .If },
    .{ "else", .Else },
    .{ "unless", .Unless },
    .{ "each", .Each },
    .{ "while", .While },
    .{ "case", .Case },
    .{ "when", .When },
    .{ "default", .Default },
    .{ "mixin", .Mixin },
    .{ "include", .Include },
    .{ "extends", .Extends },
    .{ "block", .Block },
    .{ "append", .Append },
    .{ "prepend", .Prepend },
    .{ "for", .For },
});

fn scanIdentifierOrKeyword(self: *Tokenizer) !Token {
    const start = self.pos;
    const start_line = self.line;
    const start_col = self.column;

    while (self.peek()) |ch| {
        if (std.ascii.isAlphanumeric(ch) or ch == '_' or ch == '-') {
            _ = self.advance();
        } else {
            break;
        }
    }

    const value = self.source[start..self.pos];
    const token_type = KEYWORDS.get(value) orelse .Ident;

    return Token.init(token_type, value, start_line, start_col);
}
```

### 4.3 Tokenización de Comentarios

```zig
fn scanComment(self: *Tokenizer) !Token {
    const start_line = self.line;
    const start_col = self.column;

    // Check for //- (unbuffered) or // (buffered)
    _ = self.advance(); // First /
    _ = self.advance(); // Second /

    const is_unbuffered = if (self.peek()) |ch| ch == '-' else false;
    if (is_unbuffered) {
        _ = self.advance(); // -
    }

    const start = self.pos;
    while (self.peek()) |ch| {
        if (ch == '\n') break;
        _ = self.advance();
    }

    const value = self.source[start..self.pos];
    const token_type = if (is_unbuffered) .UnbufferedComment else .BufferedComment;

    return Token.init(token_type, value, start_line, start_col);
}
```

### 4.4 Tokenización de Interpolación

```zig
fn scanInterpolation(self: *Tokenizer) !Token {
    const start_line = self.line;
    const start_col = self.column;

    _ = self.advance(); // #

    const is_unescaped = if (self.peek()) |ch| ch == '!' else false;
    if (is_unescaped) {
        _ = self.advance(); // !
    }

    if (self.peek() != '{') {
        return error.ExpectedLeftBrace;
    }
    _ = self.advance(); // {

    const start = self.pos;
    var brace_count: usize = 1;

    while (self.peek()) |ch| {
        if (ch == '{') {
            brace_count += 1;
        } else if (ch == '}') {
            brace_count -= 1;
            if (brace_count == 0) {
                const value = self.source[start..self.pos];
                _ = self.advance(); // }
                const token_type = if (is_unescaped) .UnescapedInterpol else .EscapedInterpol;
                return Token.init(token_type, value, start_line, start_col);
            }
        }
        _ = self.advance();
    }

    return error.UnterminatedInterpolation;
}
```

### 4.5 Tokenización de Código (-, =, !=)

```zig
fn scanCodeMarker(self: *Tokenizer) !Token {
    const start_line = self.line;
    const start_col = self.column;
    const ch = self.peek().?;

    if (ch == '-') {
        _ = self.advance();
        return Token.init(.UnbufferedCode, "-", start_line, start_col);
    }

    if (ch == '=') {
        _ = self.advance();
        return Token.init(.BufferedCode, "=", start_line, start_col);
    }

    if (ch == '!') {
        _ = self.advance();
        if (self.peek() == '=') {
            _ = self.advance();
            return Token.init(.UnescapedCode, "!=", start_line, start_col);
        }
        // Put back the !
        self.pos -= 1;
        self.column -= 1;
    }

    return error.UnexpectedCharacter;
}
```

### 4.6 Tokenización de Atributos Multilínea

```zig
fn scanAttributes(self: *Tokenizer) ![]Token {
    var tokens = std.ArrayList(Token).init(self.allocator);

    if (self.peek() != '(') return error.ExpectedLeftParen;
    try tokens.append(try self.scanSymbol()); // (

    var paren_count: usize = 1;
    while (paren_count > 0 and self.peek() != null) {
        self.skipWhitespace(); // Skip all whitespace including newlines

        const ch = self.peek().?;
        if (ch == '(') {
            paren_count += 1;
            try tokens.append(try self.scanSymbol());
        } else if (ch == ')') {
            paren_count -= 1;
            try tokens.append(try self.scanSymbol());
        } else {
            try tokens.append(try self.next());
        }
    }

    return tokens.toOwnedSlice();
}
```

### 4.7 Actualizar next() con Todas las Características

```zig
pub fn next(self: *Tokenizer) !?Token {
    // Check for pending tokens first
    if (self.pending_tokens.items.len > 0) {
        return self.pending_tokens.orderedRemove(0);
    }

    // Handle indentation at line start
    try self.handleIndentation();

    // Skip whitespace (except newlines which are significant)
    self.skipWhitespaceExceptNewline();

    const ch = self.peek() orelse {
        // Emit remaining DEDENT tokens at EOF
        if (self.indent_stack.items.len > 1) {
            _ = self.indent_stack.pop();
            return Token.init(.Dedent, "", self.line, self.column);
        }
        return Token.init(.Eof, "", self.line, self.column);
    };

    // Newline
    if (ch == '\n') {
        self.at_line_start = true;
        _ = self.advance();
        return Token.init(.Newline, "\n", self.line - 1, 1);
    }

    // Comments //
    if (ch == '/' and self.peekAhead(1) == '/') {
        return self.scanComment();
    }

    // Interpolation #{...} or !{...}
    if (ch == '#' and self.peekAhead(1) == '{') {
        return self.scanInterpolation();
    }
    if (ch == '!' and self.peekAhead(1) == '{') {
        return self.scanInterpolation();
    }

    // Code markers -, =, !=
    if (ch == '-' or ch == '=' or ch == '!') {
        return self.scanCodeMarker();
    }

    // ... resto de la lógica existente ...
}
```

---

## Tests Avanzados

```zig
test "tokenizer - indentation" {
    const allocator = std.testing.allocator;
    const source =
        \\div
        \\  p hello
        \\  p world
        \\span
    ;

    var tokenizer = try Tokenizer.init(allocator, source);
    defer tokenizer.deinit();

    // div
    _ = try tokenizer.next(); // div
    _ = try tokenizer.next(); // newline
    // INDENT
    const indent = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Indent, indent.?.type);
}

test "tokenizer - keywords" {
    const allocator = std.testing.allocator;
    var tokenizer = try Tokenizer.init(allocator, "if else each while");
    defer tokenizer.deinit();

    try std.testing.expectEqual(TokenType.If, (try tokenizer.next()).?.type);
    try std.testing.expectEqual(TokenType.Else, (try tokenizer.next()).?.type);
    try std.testing.expectEqual(TokenType.Each, (try tokenizer.next()).?.type);
    try std.testing.expectEqual(TokenType.While, (try tokenizer.next()).?.type);
}

test "tokenizer - comments" {
    const allocator = std.testing.allocator;
    var tokenizer = try Tokenizer.init(allocator, "// comment\n//- unbuffered");
    defer tokenizer.deinit();

    const comment1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.BufferedComment, comment1.?.type);

    const comment2 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.UnbufferedComment, comment2.?.type);
}

test "tokenizer - interpolation" {
    const allocator = std.testing.allocator;
    var tokenizer = try Tokenizer.init(allocator, "p Hello #{name}");
    defer tokenizer.deinit();

    _ = try tokenizer.next(); // p
    _ = try tokenizer.next(); // Hello
    const interpol = try tokenizer.next();
    try std.testing.expectEqual(TokenType.EscapedInterpol, interpol.?.type);
    try std.testing.expectEqualStrings("name", interpol.?.value);
}
```

---

## Benchmarks

Agregar benchmarks básicos:

```zig
test "benchmark - tokenize large file" {
    const allocator = std.testing.allocator;
    const source = // ... large pug file ...

    const start = std.time.milliTimestamp();
    var tokenizer = try Tokenizer.init(allocator, source);
    defer tokenizer.deinit();

    var count: usize = 0;
    while (try tokenizer.next()) |token| {
        if (token.type == .Eof) break;
        count += 1;
    }

    const end = std.time.milliTimestamp();
    std.debug.print("Tokenized {d} tokens in {d}ms\n", .{count, end - start});
}
```

---

## Entregables
1. Tokenizer completo con todas las características
2. Tests exhaustivos pasando
3. Benchmarks de rendimiento
4. Documentación actualizada

---

## Siguiente Paso
Continuar con **05-ast-definition.md** para definir el Abstract Syntax Tree.
