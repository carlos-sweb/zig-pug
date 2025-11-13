# Paso 3: Implementación del Tokenizer Base

## Objetivo
Crear el tokenizer/lexer que convierte texto fuente en un stream de tokens.

## Descripción
El tokenizer es la primera fase del pipeline de compilación. Lee el texto fuente carácter por carácter y lo convierte en tokens que el parser puede entender.

---

## Tareas

### 3.1 Definir TokenType Enum
Crear enumeración completa de tipos de tokens (ver 02-architecture.md)

### 3.2 Implementar Estructura Token
```zig
pub const Token = struct {
    type: TokenType,
    value: []const u8,
    line: usize,
    column: usize,

    pub fn init(token_type: TokenType, value: []const u8, line: usize, column: usize) Token {
        return .{
            .type = token_type,
            .value = value,
            .line = line,
            .column = column,
        };
    }
};
```

### 3.3 Crear Scanner de Caracteres
```zig
pub const Tokenizer = struct {
    source: []const u8,
    pos: usize,
    line: usize,
    column: usize,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator, source: []const u8) Tokenizer {
        return .{
            .source = source,
            .pos = 0,
            .line = 1,
            .column = 1,
            .allocator = allocator,
        };
    }

    fn peek(self: *Tokenizer) ?u8 {
        if (self.pos >= self.source.len) return null;
        return self.source[self.pos];
    }

    fn peekAhead(self: *Tokenizer, offset: usize) ?u8 {
        const pos = self.pos + offset;
        if (pos >= self.source.len) return null;
        return self.source[pos];
    }

    fn advance(self: *Tokenizer) ?u8 {
        if (self.pos >= self.source.len) return null;
        const ch = self.source[self.pos];
        self.pos += 1;
        if (ch == '\n') {
            self.line += 1;
            self.column = 1;
        } else {
            self.column += 1;
        }
        return ch;
    }
};
```

### 3.4 Implementar Reconocimiento de Tokens Básicos

#### Identificadores
```zig
fn scanIdentifier(self: *Tokenizer) !Token {
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
    return Token.init(.Ident, value, start_line, start_col);
}
```

#### Strings
```zig
fn scanString(self: *Tokenizer, quote: u8) !Token {
    const start_line = self.line;
    const start_col = self.column;
    _ = self.advance(); // Skip opening quote

    const start = self.pos;
    while (self.peek()) |ch| {
        if (ch == quote) {
            const value = self.source[start..self.pos];
            _ = self.advance(); // Skip closing quote
            return Token.init(.String, value, start_line, start_col);
        }
        if (ch == '\\') {
            _ = self.advance(); // Skip escape
            _ = self.advance(); // Skip escaped char
        } else {
            _ = self.advance();
        }
    }

    return error.UnterminatedString;
}
```

#### Números
```zig
fn scanNumber(self: *Tokenizer) !Token {
    const start = self.pos;
    const start_line = self.line;
    const start_col = self.column;

    while (self.peek()) |ch| {
        if (std.ascii.isDigit(ch) or ch == '.') {
            _ = self.advance();
        } else {
            break;
        }
    }

    const value = self.source[start..self.pos];
    return Token.init(.Number, value, start_line, start_col);
}
```

#### Símbolos Especiales
```zig
fn scanSymbol(self: *Tokenizer) !Token {
    const start_line = self.line;
    const start_col = self.column;
    const ch = self.advance().?;

    const token_type: TokenType = switch (ch) {
        '(' => .LParen,
        ')' => .RParen,
        '[' => .LBracket,
        ']' => .RBracket,
        '{' => .LBrace,
        '}' => .RBrace,
        ',' => .Comma,
        ':' => .Colon,
        '|' => .Pipe,
        '.' => .Dot,
        '#' => .Hash,
        else => return error.UnexpectedCharacter,
    };

    const value = self.source[self.pos-1..self.pos];
    return Token.init(token_type, value, start_line, start_col);
}
```

### 3.5 Implementar next() - Función Principal
```zig
pub fn next(self: *Tokenizer) !?Token {
    self.skipWhitespaceExceptNewline();

    const ch = self.peek() orelse return Token.init(.Eof, "", self.line, self.column);

    // Newline
    if (ch == '\n') {
        _ = self.advance();
        return Token.init(.Newline, "\n", self.line - 1, 1);
    }

    // Strings
    if (ch == '"' or ch == '\'') {
        return self.scanString(ch);
    }

    // Numbers
    if (std.ascii.isDigit(ch)) {
        return self.scanNumber();
    }

    // Identifiers
    if (std.ascii.isAlphabetic(ch) or ch == '_') {
        return self.scanIdentifier();
    }

    // Symbols
    return self.scanSymbol();
}

fn skipWhitespaceExceptNewline(self: *Tokenizer) void {
    while (self.peek()) |ch| {
        if (ch == ' ' or ch == '\t' or ch == '\r') {
            _ = self.advance();
        } else {
            break;
        }
    }
}
```

### 3.6 Sistema de Errores
```zig
pub const TokenizerError = error {
    UnexpectedCharacter,
    UnterminatedString,
    InvalidNumber,
    OutOfMemory,
};
```

---

## Tests

### Test Suite Básica
```zig
test "tokenizer - identifiers" {
    const allocator = std.testing.allocator;
    var tokenizer = Tokenizer.init(allocator, "div hello world123");

    const token1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, token1.?.type);
    try std.testing.expectEqualStrings("div", token1.?.value);

    const token2 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Ident, token2.?.type);
    try std.testing.expectEqualStrings("hello", token2.?.value);
}

test "tokenizer - strings" {
    const allocator = std.testing.allocator;
    var tokenizer = Tokenizer.init(allocator, "\"hello world\"");

    const token = try tokenizer.next();
    try std.testing.expectEqual(TokenType.String, token.?.type);
    try std.testing.expectEqualStrings("hello world", token.?.value);
}

test "tokenizer - numbers" {
    const allocator = std.testing.allocator;
    var tokenizer = Tokenizer.init(allocator, "123 45.67");

    const token1 = try tokenizer.next();
    try std.testing.expectEqual(TokenType.Number, token1.?.type);
    try std.testing.expectEqualStrings("123", token1.?.value);
}

test "tokenizer - symbols" {
    const allocator = std.testing.allocator;
    var tokenizer = Tokenizer.init(allocator, "()[]{}");

    try std.testing.expectEqual(TokenType.LParen, (try tokenizer.next()).?.type);
    try std.testing.expectEqual(TokenType.RParen, (try tokenizer.next()).?.type);
    try std.testing.expectEqual(TokenType.LBracket, (try tokenizer.next()).?.type);
    try std.testing.expectEqual(TokenType.RBracket, (try tokenizer.next()).?.type);
}
```

---

## Entregables
1. Módulo `tokenizer.zig` con tokenizer base funcional
2. Suite de tests unitarios pasando
3. Documentación inline del código
4. Reconocimiento de tokens básicos funcionando

---

## Siguiente Paso
Continuar con **04-tokenizer-advanced.md** para agregar características avanzadas.
