# Tokenizer - Lexical Analysis

The **Tokenizer** is the first phase of the zig-pug compilation pipeline. It converts Pug template source code into a stream of tokens that the parser can process.

## Overview

The tokenizer reads source code character by character and groups them into meaningful tokens. It handles:

- **Whitespace-significant indentation** (like Python)
- **Keywords and identifiers** (tag names, variable names)
- **Literals** (strings, numbers, booleans)
- **Special syntax** (`.class`, `#id`, `#{interpolation}`)
- **Comments** (`//` buffered, `//-` unbuffered, `//!` documentation)
- **Code markers** (`=`, `!=`, `-`, `|`)

## Architecture

### Location: `src/tokenizer/`

```
src/tokenizer/
├── mod.zig              # Main entry point with Tokenizer struct
├── TokenType.zig        # Enum of all token types
├── Token.zig            # Token data structure
├── TokenizerState.zig   # State machine states
├── TokenizerError.zig   # Error types
├── scanComment.zig      # Comment scanning
├── scanIdentifier.zig   # Identifier/keyword scanning
├── scanInterpolation.zig # Interpolation scanning
├── scanNumber.zig       # Number literal scanning
├── scanString.zig       # String literal scanning
├── scanSymbol.zig       # Symbol/operator scanning
├── scanText.zig         # Plain text scanning
└── tests.zig           # Tokenizer test suite
```

## State Machine

The tokenizer uses a **labeled-switch state machine** for efficient token recognition:

### States

1. **Root**: Start of a line, expecting tag/keyword
2. **Indent**: After indentation, expecting content
3. **TagStart**: After tag name, can accept `.class`, `#id`, `(attrs)`
4. **TagClass**: After class shorthand
5. **TagId**: After id shorthand
6. **AttrStart**: Inside attribute parentheses `(`
7. **AttrName**: Attribute name
8. **AttrEquals**: After `=` in attribute
9. **AttrValue**: Attribute value
10. **AttrString**: String attribute value
11. **AttrJS**: JavaScript expression in attribute
12. **Text**: Plain text content
13. **Code**: JavaScript expression context (after `=`, `!=`, `-`)

### State Transitions

```
Root/Indent
  ├─> TagStart (on tag name)
  ├─> Code (on =, !=, -)
  └─> Text (on text content)

TagStart
  ├─> TagClass (on .class)
  ├─> TagId (on #id)
  ├─> AttrStart (on '(')
  └─> Text (on space)

AttrStart
  ├─> AttrName (on identifier)
  ├─> AttrEquals (on '=')
  └─> TagStart (on ')')

Code
  └─> Root (on newline)
```

## Token Types

### Structural Tokens
- `Indent` / `Dedent`: Indentation changes
- `Newline`: Line break
- `Eof`: End of file

### Identifier Tokens
- `Ident`: Variable/tag names
- `Class`: `.classname` shorthand
- `Id`: `#idname` shorthand

### Literal Tokens
- `String`: `"text"` or `'text'`
- `Number`: `123`, `45.67`
- `Boolean`: `true`, `false`

### Keyword Tokens
- Control flow: `If`, `Else`, `Unless`, `Each`, `While`, `Case`, `When`, `Default`
- Templates: `Mixin`, `Include`, `Extends`, `Block`, `Append`, `Prepend`
- Special: `Doctype`

### Symbol Tokens
- Parentheses: `LParen` `(`, `RParen` `)`
- Brackets: `LBracket` `[`, `RBracket` `]`
- Braces: `LBrace` `{`, `RBrace` `}`
- Operators: `Dot` `.`, `Comma` `,`, `Colon` `:`, `Pipe` `|`
- Comparison: `Equal` `==`, `Greater` `>`, `Less` `<`, `GreaterEqual` `>=`, `LessEqual` `<=`
- Logical: `And` `&&`, `Or` `||`

### Code Markers
- `BufferedCode`: `=` (evaluate and output escaped)
- `UnescapedCode`: `!=` (evaluate and output raw)
- `UnbufferedCode`: `-` (execute without output)

### Comments
- `BufferedComment`: `//` (emitted to HTML)
- `UnbufferedComment`: `//-` (not included in output)
- Doc comments `//!` are skipped entirely

### Interpolation
- `EscapedInterpol`: `#{expr}` (HTML-escaped output)
- `UnescapedInterpol`: `!{expr}` (raw HTML output)

## Indentation Handling

The tokenizer tracks indentation levels and generates `INDENT`/`DEDENT` tokens similar to Python:

```pug
div
  p Hello    # INDENT emitted
  p World
span          # DEDENT emitted
```

### Rules
- Only **spaces** allowed (tabs cause `InvalidIndentation` error)
- Increased indent → emit `INDENT` token
- Decreased indent → emit one or more `DEDENT` tokens
- Empty lines are skipped

## UTF-8 Support

The tokenizer fully supports UTF-8:

- **Multi-byte sequences**: Emojis, accented characters, Chinese/Japanese/etc.
- **Identifiers**: `div.clase-española`, `p #{名前}`
- **Text content**: Any valid UTF-8 string

### UTF-8 Functions
- `isUtf8Start(byte)`: Check if byte starts a UTF-8 sequence
- `utf8SequenceLength(first_byte)`: Get sequence length (1-4 bytes)
- `isValidTextByte(byte)`: Check if byte is valid in text

## Example Tokenization

### Input
```pug
div.container#main
  p Hello #{name}
  // This is a comment
```

### Token Stream
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

## API Usage

### Initialization

```zig
const std = @import("std");
const Tokenizer = @import("tokenizer/mod.zig").Tokenizer;

var tokenizer = try Tokenizer.init(allocator, source);
defer tokenizer.deinit();
```

### Token Iteration

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

## Error Handling

### Error Types
- `InvalidIndentation`: Tabs used or inconsistent dedentation
- `UnterminatedString`: String not closed
- `UnexpectedCharacter`: Invalid character in context

### Error Recovery
Errors include line and column information for precise error reporting to users.

## Performance

- **Single-pass**: Source is scanned once
- **Zero-copy**: Tokens reference source slices (no allocation)
- **Lookahead**: Maximum 2 characters (`//`, `#{`, etc.)
- **Efficient**: Uses labeled-switch for better branch prediction

## Testing

Run tokenizer tests:
```bash
zig test src/tokenizer/tests.zig
```

Tests cover:
- All token types
- Indentation tracking
- UTF-8 handling
- Error cases
- Edge cases (empty files, etc.)

## See Also

- [Parser](parser.md) - Syntax analysis (next phase)
- [AST](ast.md) - Abstract Syntax Tree structure
- [Compiler](compiler.md) - HTML generation
