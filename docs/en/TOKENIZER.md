# Tokenizer Documentation

> **Version:** 0.4.0  
> **Last Updated:** April 2026  
> **Status:** Tokenizer complete — Parser next

---

## Table of Contents

1. [Overview](#overview)
2. [Design Philosophy](#design-philosophy)
3. [Architecture](#architecture)
4. [State Machine](#state-machine)
5. [Token Types](#token-types)
6. [Scan Functions](#scan-functions)
7. [Key Design Decisions](#key-design-decisions)
8. [Usage Example](#usage-example)
9. [Pipeline Position](#pipeline-position)

---

## Overview

The tokenizer is the first phase of the zig-pug compilation pipeline. It converts Pug template source code into a flat stream of tokens that the parser consumes.

**Pipeline:**

```
Source Code → Tokenizer → Token Stream → Parser → AST → Compiler → HTML
```

**Key characteristics:**

- Modular — each scan function in its own file
- Indentation-aware — emits `Indent`/`Dedent` tokens like Python
- UTF-8 support — handles multi-byte Unicode characters
- Minimal state — only 3 states, no parser logic

---

## Design Philosophy

> **The tokenizer recognizes surface syntax. The parser assigns meaning.**

This boundary was the central design decision of this version. The tokenizer does NOT:

- Interpret attribute values
- Decide if a `=` is assignment or buffered code
- Classify `true`/`false` as booleans
- Interpret numeric values
- Understand JS expressions

It only answers: **what character is this, in what immediate context?**

### The three token categories that matter

| Token | Meaning | Example |
|---|---|---|
| `String` | Content between quote delimiters | `"hello"`, `'world'` |
| `Text` | Plain content after a tag, until newline | `p Hello world` → `Text("Hello world")` |
| `Ident` | Any word — the parser decides what it means | `div`, `true`, `100`, `myVar` |

Everything else (`Class`, `Id`, symbols, keywords) is surface syntax the tokenizer can recognize visually without needing semantic context.

---

## Architecture

```
src/tokenizer/
  mod.zig              — hub: Tokenizer struct, main dispatch (next())
  Token.zig            — Token struct (type, value, line, column)
  TokenType.zig        — TokenType enum
  TokenizerState.zig   — 3 states only
  TokenizerError.zig   — error types
  utils.zig            — shared helpers: UTF-8, keyword lookup (single source of truth)
  scanIdentifier.zig   — words and keywords
  scanString.zig       — quoted strings with escape support
  scanSymbol.zig       — punctuation, operators, .class/#id shorthands
  scanText.zig         — plain text content
  scanComment.zig      — // and //- comments
  scanInterpolation.zig — #{...} and !{...}
```

**Removed in this version:**

- `scanNumber.zig` — numbers are `Ident`, the parser decides
- `scanAttrValue.zig` — attribute values are not the tokenizer's concern

---

## State Machine

Only 3 states — defined in `TokenizerState.zig`:

```zig
pub const TokenizerState = enum {
    Root,    // start of a line — expects tag, keyword, or comment
    Indent,  // measuring indentation at line start
    Text,    // plain text content after a tag
};
```

### Why only 3 states?

The previous version had 14 states (`TagStart`, `TagClass`, `TagId`, `AttrStart`, `AttrName`, `AttrEquals`, `AttrValue`, `AttrString`, `AttrJS`, `Loop`, `Code`...). Those states encoded parser knowledge — "I am inside an attribute list", "I just saw an equals sign". That belongs to the parser.

The tokenizer only needs to know:
- Am I at the start of a line? (`Root`/`Indent`)
- Am I reading plain text content? (`Text`)

### State transitions

```
Root ──── newline ────────────────────────► Root (reset)
Root ──── space after Ident/Class/Id ────► Text
Text ──── newline ────────────────────────► Root
```

Everything else stays in `Root` — the parser tracks structure.

### Tokenizer struct fields

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
    paren_depth: usize,       // tracks () nesting — when >0, . is Dot not Class
    after_space: bool,        // true when skipWhitespace consumed at least one space
    last_token_type: TokenType, // type of last emitted token — used to activate Text state
};
```

### `paren_depth` — the only structural context

The tokenizer needs to know if it is inside `()` for one specific reason: `.classname` vs `.property`.

- Outside `()`: `div.container` → `Class("container")`
- Inside `()`: `div(data-val=obj.prop)` → `Dot` + `Ident("prop")`

`paren_depth` is incremented on `(` and decremented on `)`. No other structural context is tracked.

### Text activation condition

Plain text after a tag activates when all three are true:

```
after_space == true
AND paren_depth == 0
AND last_token_type ∈ { Ident, Class, Id, RParen }
```

This correctly handles:

```pug
p Hello world         → Text("Hello world")      ✅
p.intro Hello world   → Text("Hello world")      ✅
p(class="x") Hello    → Text("Hello")            ✅
if condition          → Ident("condition")        ✅ (If not in list)
```

### Indentation — `pending_tokens` queue

Pug uses significant indentation. The tokenizer emits `Indent`/`Dedent` tokens using a stack:

- Increase → push level + emit `Indent`
- Decrease → pop until matching level, emit one `Dedent` per pop
- Level not found → `InvalidIndentation` error
- Tabs → always `InvalidIndentation` (Pug requires spaces)

**Performance note:** `pending_tokens` uses `pop()` (O(1)) not `orderedRemove(0)` (O(n)). Tokens are inserted in reverse order so `pop()` returns the correct one.

---

## Token Types

Defined in `TokenType.zig`:

### Identifiers
| Token | Description | Example |
|---|---|---|
| `Ident` | Any word — tag name, variable, `true`, `false`, numbers | `div`, `myVar`, `100`, `true` |
| `Class` | `.classname` shorthand (outside `()` only) | `.container` |
| `Id` | `#idname` shorthand (outside `()` only) | `#main` |

### Literals
| Token | Description | Example |
|---|---|---|
| `String` | Quoted content — double or single quotes | `"hello"`, `'world'` |
| `Text` | Plain text content after a tag | `Hello world` |

> **Note:** `Boolean` and `Number` have been removed. `true`, `false`, `42`, `3.14` are all `Ident`. The parser and mujs interpret their meaning.

### Symbols
| Token | Char | Token | Char |
|---|---|---|---|
| `LParen` | `(` | `RParen` | `)` |
| `LBracket` | `[` | `RBracket` | `]` |
| `LBrace` | `{` | `RBrace` | `}` |
| `Dot` | `.` (inside `()`) | `Hash` | `#` (inside `()`) |
| `Comma` | `,` | `Colon` | `:` |
| `Pipe` | `\|` | `Question` | `?` |

### Operators
| Token | Symbol |
|---|---|
| `BufferedCode` | `=` |
| `UnbufferedCode` | `-` |
| `UnescapedCode` | `!=` |
| `Assign` | `=` (kept for parser compatibility) |
| `Equal` | `==` |
| `NotEqual` | `!=` |
| `And` | `&&` |
| `Or` | `\|\|` |
| `Greater` / `Less` | `>` / `<` |
| `GreaterEqual` / `LessEqual` | `>=` / `<=` |
| `Plus` / `Minus` | `+` / `-` |

### Keywords — Pug directives
`If`, `Else`, `Unless`, `Each`, `While`, `In`, `Case`, `When`, `Default`, `Mixin`, `Include`, `Extends`, `Block`, `Append`, `Prepend`, `Doctype`

> `true` and `false` are NOT keywords. They are plain `Ident`.

### Interpolation
| Token | Syntax |
|---|---|
| `EscapedInterpol` | `#{expression}` — HTML-safe, passed to mujs |
| `UnescapedInterpol` | `!{expression}` — raw output, passed to mujs |

### Comments
| Token | Syntax |
|---|---|
| `BufferedComment` | `//` — rendered as HTML comment |
| `UnbufferedComment` | `//-` — stripped from output |

### Structure
`Indent`, `Dedent`, `Newline`, `Eof`

---

## Scan Functions

### `scanIdentifier`

Reads alphanumeric + `_` + `-` + UTF-8 sequences. Checks against keyword table in `utils.getKeyword()`. Pre-filtered by length (2–7 chars) for performance.

No state transitions. The parser decides what an identifier means.

### `scanString`

Reads between quote delimiters (`"` or `'`). Supports:
- Escape sequences: `\"`, `\'`, `\\`, `\n`, `\t`, any `\x`
- Opposite quote inside: `"alert('hi')"` → `String("alert('hi')")`
- Returns content without the surrounding quotes

### `scanSymbol`

Handles punctuation, operators, and Pug shorthands. Key behaviors:

- `.name` outside `()` → `Class("name")`
- `.name` inside `()` → `Dot` + identifier handled by next call
- `#name` outside `()` → `Id("name")`
- `#name` inside `()` → `Hash`
- Digits → read full sequence as `Ident` (dot only consumed if next char is digit)
- Multi-char operators checked before single-char: `!=`, `>=`, `<=`, `==`, `&&`, `||`
- `(` increments `paren_depth`, `)` decrements it

### `scanText`

Active in `.Text` state. Reads everything until:
- `\n` — end of line
- `#{` — start of escaped interpolation
- `!{` — start of unescaped interpolation

Returns `Text` token. State resets to `Root` at newline.

### `scanComment`

- `//` → `BufferedComment` with content
- `//-` → `UnbufferedComment` with content
- `//!` → doc comment, silently skipped, calls `next()` to continue

### `scanInterpolation`

Reads `#{...}` or `!{...}`. Tracks brace nesting depth — correctly handles:

```pug
#{obj.fn({key: value})}   → EscapedInterpol("obj.fn({key: value})")
```

---

## Key Design Decisions

### 1. Numbers are `Ident`

```pug
input(value=100 min=50 max=150)
```

`100`, `50`, `150` → all `Ident`. In HTML all attribute values are strings. The browser interprets `"100"` as a number when needed. Zig-pug never does arithmetic on these values — the renderer writes them as-is or mujs evaluates them.

### 2. `true`/`false` are `Ident`

JS booleans are not Pug keywords. `true` and `false` emit `Ident` and the parser or mujs decides. `True` also emits `Ident` — mujs will throw `ReferenceError` at runtime, which is correct behavior.

### 3. Unquoted attribute values are token sequences

```pug
div(data-val=myVar.items.length)
```

The tokenizer emits: `Ident("myVar")` `Dot` `Ident("items")` `Dot` `Ident("length")`. The parser sees `BufferedCode` and knows everything until `,` or unbalanced `)` is a JS expression to pass to mujs.

### 4. `.class` vs `.property` — `paren_depth`

`.` means two different things:
- `div.container` — CSS class shorthand
- `obj.property` — JS property access inside `()`

`paren_depth` is the minimal context needed to distinguish them without parser knowledge.

### 5. `pending_tokens` with `pop()` not `orderedRemove(0)`

INDENT/DEDENT tokens are inserted in reverse order so `pop()` (O(1)) can be used instead of `orderedRemove(0)` (O(n)).

---

## Usage Example

```zig
const std = @import("std");
const Tokenizer = @import("src/tokenizer/mod.zig").Tokenizer;

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const source = "div.container#main(class=\"test\") Hello world";

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

**Output:**

```
Ident                div
Class                container
Id                   main
LParen               (
Ident                class
BufferedCode         =
String               test
RParen               )
Text                 Hello world
Eof
```

---

## Token output reference

| Pug source | Tokens |
|---|---|
| `div.container#main` | `Ident("div")` `Class("container")` `Id("main")` |
| `p Hello world` | `Ident("p")` `Text("Hello world")` |
| `input(value=100)` | `Ident("input")` `LParen` `Ident("value")` `BufferedCode` `Ident("100")` `RParen` |
| `input(value="hello")` | `Ident("input")` `LParen` `Ident("value")` `BufferedCode` `String("hello")` `RParen` |
| `input(value=#{age})` | `Ident("input")` `LParen` `Ident("value")` `BufferedCode` `EscapedInterpol("age")` `RParen` |
| `div(data=obj.x.y)` | `Ident("div")` `LParen` `Ident("data")` `BufferedCode` `Ident("obj")` `Dot` `Ident("x")` `Dot` `Ident("y")` `RParen` |
| `if condition` | `If` `Ident("condition")` |
| `each item in items` | `Each` `Ident("item")` `In` `Ident("items")` |
| `- var x = 42` | `UnbufferedCode` `Ident("var")` `Ident("x")` `BufferedCode` `Ident("42")` |
| `// comment` | `BufferedComment("comment")` |
| `//- internal` | `UnbufferedComment("internal")` |

---

## What comes next — the Parser

The parser receives the token stream and assigns semantic meaning:

- `Ident` at line start → tag name
- `Ident` after `BufferedCode` inside `()` → start of JS expression for mujs
- `If` + tokens → conditional node
- `Each` + `Ident` + `In` + `Ident` → loop node
- `Text` → text content node
- `Indent`/`Dedent` → tree nesting

The parser is responsible for balancing `(` `)` in attribute expressions and passing raw JS strings to mujs for evaluation.
