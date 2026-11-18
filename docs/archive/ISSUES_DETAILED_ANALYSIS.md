# zig-pug Codebase Issues and Bugs Analysis

## Executive Summary
This analysis identifies critical bugs, missing features, and architectural issues in the zpug template engine codebase. Issues are prioritized by severity: Critical (blocks functionality), High (major feature gaps), and Medium (quality/correctness issues).

---

## CRITICAL ISSUES

### 1. Multiple Classes Create Duplicate Attributes (BUG)
**Location**: `src/parser.zig:136-155` (parseTag function)
**Severity**: CRITICAL
**Description**:
When parsing multiple classes (e.g., `div.box.highlight`), each class is appended as a separate attribute with name="class". This creates duplicate class attributes instead of concatenating them.

**Current Behavior**:
```
Input:  div.box.highlight
Tokens: Class(.box), Class(.highlight)
Result: <div class="box" class="highlight">  ❌ INVALID HTML
```

**Expected Behavior**:
```
<div class="box highlight">  ✓ VALID HTML
```

**Root Cause**:
The parser appends each class as a new attribute:
```zig
try attributes.append(arena_allocator, .{
    .name = "class",
    .value = class_token.value,  // ← Just stores single value
    .is_unescaped = false,
});
```

**Fix Strategy**:
1. Check if a "class" attribute already exists before appending
2. If it exists, concatenate the new class value with a space separator
3. Update the existing attribute instead of creating a new one

**Example Fix**:
```zig
// Check if class attribute already exists
var class_attr_idx: ?usize = null;
for (attributes.items, 0..) |attr, i| {
    if (std.mem.eql(u8, attr.name, "class")) {
        class_attr_idx = i;
        break;
    }
}

if (class_attr_idx) |idx| {
    // Concatenate with existing class
    const existing = attributes.items[idx].value orelse "";
    const new_value = try std.fmt.allocPrint(
        arena_allocator, 
        "{s} {s}", 
        .{existing, class_token.value}
    );
    attributes.items[idx].value = new_value;
} else {
    // Add new class attribute
    try attributes.append(arena_allocator, .{...});
}
```

**Affected Test Case**: `tests/cli/02-classes-ids.zpug` (line 6-7)
- Input: `div.box.highlight`, `p.text#intro.bold`
- Will generate invalid HTML with duplicate class attributes

---

### 2. Loop Iterator Variable Not Parsed (BUG)
**Location**: `src/parser.zig:641`
**Severity**: CRITICAL
**Description**:
The parser collects the entire loop expression as a string but doesn't extract the iterator variable name. This is marked with a TODO comment and causes loops to fail.

**Current Behavior**:
```zig
.iterator = "", // TODO: parse variable names properly
```

The iterator field is always empty string, which means `loop.iterator` is never set to "item" in:
```
each item in items
  li= item
```

**Expected Behavior**:
```zig
.iterator = "item",
.iterable = "items",
```

**Root Cause**:
Parser collects full expression "item in items" as `.iterable` but doesn't parse out the iterator variable.

**Fix Strategy**:
Parse loop expression to extract iterator and optional index:
1. Match pattern: `IDENTIFIER [in|of] EXPRESSION`
2. For "each...in": extract iterator, discard "in", rest is iterable
3. For "each...of": similar pattern
4. Handle index variable: `each item, index in items`

**Example Fix**:
```zig
// Parse loop expression properly
var iterator = std.ArrayList(u8){};
var iterable = std.ArrayList(u8){};
var parsing_iterator = true;
var found_in = false;

while (!self.match(&.{ .Newline, .Eof })) {
    if (!found_in && self.match(&.{.Ident})) {
        const val = self.current.value;
        if (std.mem.eql(u8, val, "in") || std.mem.eql(u8, val, "of")) {
            found_in = true;
            try self.advance();
            continue;
        }
    }
    
    if (parsing_iterator && !found_in) {
        try iterator.appendSlice(arena_allocator, self.current.value);
        if (self.peekAhead(1) and next is not comma) {
            parsing_iterator = false;
        }
    } else {
        try iterable.appendSlice(arena_allocator, self.current.value);
    }
    try self.advance();
}
```

**Impact**: Loops completely broken - can't access loop variables

---

### 3. Mixin Arguments Not Substituted in Body (BUG)
**Location**: `src/compiler.zig:579-595` (compileMixinCall function)
**Severity**: CRITICAL
**Description**:
Mixin calls ignore their arguments. The TODO comment says parameters aren't set in runtime context.

**Current Code**:
```zig
fn compileMixinCall(self: *Self, node: *ast.AstNode) !void {
    const call = &node.data.MixinCall;
    // Find mixin...
    const mixin_def = &mixin_node.data.MixinDef;
    
    // TODO: Set mixin parameters in runtime context
    // For now, just compile the body
    for (mixin_def.body.items) |child| {
        try self.compileNode(child);
    }
}
```

**Example**:
```
mixin greeting(name)
  p Hello #{name}
  
+greeting("Alice")
```

Renders as `<p>Hello undefined</p>` because `name` is never set to "Alice".

**Fix Strategy**:
1. Evaluate each argument expression from runtime
2. Create JavaScript variable assignments for each parameter
3. Execute assignments before compiling mixin body
4. Handle rest parameters (...args)

**Example Fix**:
```zig
fn compileMixinCall(self: *Self, node: *ast.AstNode) !void {
    const call = &node.data.MixinCall;
    const mixin_node = self.mixins.get(call.name) orelse {...};
    const mixin_def = &mixin_node.data.MixinDef;
    
    // Set mixin parameters in runtime context
    for (mixin_def.params.items, 0..) |param, i| {
        if (i < call.args.items.len) {
            // Evaluate argument and set as parameter
            const arg_value = try self.runtime.eval(call.args.items[i]);
            defer self.allocator.free(arg_value);
            
            const param_var = try std.fmt.allocPrint(
                self.allocator,
                "var {s} = \"{s}\"",
                .{param, arg_value}
            );
            defer self.allocator.free(param_var);
            
            _ = try self.runtime.eval(param_var);
        }
    }
    
    // Compile mixin body
    for (mixin_def.body.items) |child| {
        try self.compileNode(child);
    }
}
```

**Test Impact**: `tests/cli/07-mixins.zpug` expects mixin args to work

---

### 4. Comment Content Not Escaped (SECURITY BUG)
**Location**: `src/compiler.zig:333-341` (compileComment function)
**Severity**: CRITICAL (Security)
**Description**:
Comment content is inserted directly without HTML escaping. If user input contains `-->`, it breaks the HTML comment structure.

**Current Code**:
```zig
fn compileComment(self: *Self, node: *ast.AstNode) !void {
    const comment = &node.data.Comment;
    if (comment.is_buffered) {
        try self.output.appendSlice(self.allocator, "<!--");
        try self.output.appendSlice(self.allocator, comment.content);  // ← No escaping!
        try self.output.appendSlice(self.allocator, "-->");
    }
}
```

**Attack Vector**:
```
// This is a comment --> <script>alert('xss')</script> <!--
```

Renders as:
```html
<!-- This is a comment --> <script>alert('xss')</script> <!---->
```

The script tag is now outside the comment!

**Fix Strategy**:
HTML comments have strict content rules:
1. Cannot contain `--` (double dash)
2. Cannot end with `-` before `>`
3. Must escape or sanitize `-->` sequences

**Example Fix**:
```zig
fn compileComment(self: *Self, node: *ast.AstNode) !void {
    const comment = &node.data.Comment;
    if (comment.is_buffered) {
        try self.output.appendSlice(self.allocator, "<!--");
        
        // Sanitize comment content
        for (comment.content) |c| {
            if (c == '-' and index + 1 < len and content[index+1] == '-') {
                // Escape double dash
                try self.output.append(self.allocator, ' ');
            }
            try self.output.append(self.allocator, c);
        }
        
        try self.output.appendSlice(self.allocator, "-->");
    }
}
```

**Impact**: XSS vulnerability in comments

---

## HIGH PRIORITY ISSUES

### 5. Attribute String Concatenation Not Supported (FEATURE GAP)
**Location**: `src/parser.zig:226-268` (parseAttributes function)
**Severity**: HIGH
**Description**:
Attributes don't support expression concatenation. Pug allows:
```pug
a(href="/user/" + userId) User Profile
```

This should evaluate and concatenate at compile time, but currently not supported.

**Current Behavior**:
- Only supports literal strings, numbers, identifiers, or single expressions
- No operator support (`, +, ||, etc.)

**Expected**:
```html
<a href="/user/123">User Profile</a>
```

**Fix**: Enhance attribute parsing to collect full JavaScript expression until comma or rparen

---

### 6. Test Configuration Points to Wrong File (BUILD ISSUE)
**Location**: `build.zig:180-186`
**Severity**: HIGH
**Description**:
Test root is set to `src/main.zig` which is a demo/CLI entry point, not a test file. All actual tests are in individual source modules (.zig files) but aren't being run by the test harness.

**Current Code**:
```zig
const tests = b.addTest(.{
    .root_module = b.createModule(.{
        .root_source_file = b.path("src/main.zig"),  // ← WRONG FILE
        .target = exe_target,
        .optimize = optimize,
    }),
});
```

**Problem**:
- `src/main.zig` contains only one test: `test "basic test" { ... }`
- All other modules (compiler.zig, parser.zig, etc.) have test blocks but aren't included
- Running `zig build test` only runs the basic test, missing 50+ tests

**Fix**:
Create a test runner file that imports all modules:

**Example Fix** (create `src/test.zig`):
```zig
const _ = @import("compiler.zig");
const _ = @import("parser.zig");
const _ = @import("ast.zig");
const _ = @import("tokenizer.zig");
```

Then update `build.zig`:
```zig
.root_source_file = b.path("src/test.zig"),
```

---

### 7. Block Modes (append/prepend) Not Implemented (FEATURE GAP)
**Location**: `src/compiler.zig:170-185` (compileBlock function)
**Severity**: HIGH
**Description**:
The parser supports `block append` and `block prepend` modes, but the compiler ignores them and always replaces content.

**Current Code**:
```zig
fn compileBlock(self: *Self, node: *ast.AstNode) !void {
    const block = &node.data.Block;
    
    if (self.child_blocks.get(block.name)) |child_body| {
        // Render child block content
        for (child_body.items) |child| {
            try self.compileNode(child);
        }
    } else {
        // Render default block content
        for (block.body.items) |child| {
            try self.compileNode(child);
        }
    }
    // ← No handling of block.mode (Append/Prepend)
}
```

**Modes Not Implemented**:
- `block append NAME`: Child content should be appended to parent
- `block prepend NAME`: Child content should be prepended to parent
- `block NAME` (default): Replace entire block

**Impact**: Template inheritance doesn't work correctly with append/prepend blocks

---

### 8. Include Filter Not Implemented (FEATURE GAP)
**Location**: `src/compiler.zig:468-526` (compileInclude function)
**Severity**: HIGH
**Description**:
The parser supports include filters (`include:markdown file.md`), but compiler ignores them.

**Current Code**:
```zig
fn compileInclude(self: *Self, node: *ast.AstNode) !void {
    const include = &node.data.Include;
    // ... reads file ...
    const included_ast = parser.parse() catch {...};
    // ← No filter processing, always parses as .zpug
}
```

Filters like `markdown`, `html`, `stylus` should preprocess file content before inclusion.

---

## MEDIUM PRIORITY ISSUES

### 9. Loop else_branch Always Null (BUG)
**Location**: `src/parser.zig:608-649` (parseLoop function)
**Severity**: MEDIUM
**Description**:
Loop parser doesn't support `else` clause for empty arrays. Always sets `else_branch = null`.

**Fix**: Add else clause parsing after loop body, similar to conditional parsing.

---

### 10. Case Comparison Always String-Based (LIMITATION)
**Location**: `src/compiler.zig:532-568` (compileCase function)
**Severity**: MEDIUM
**Description**:
Case statement compares string representations:
```zig
if (std.mem.eql(u8, case_value, value)) {
```

This means `case 1` will never match `when 1` (number vs string). Should do type-aware comparison.

---

### 11. Attribute Value Escaping Missing for Dynamic Values (BUG)
**Location**: `src/compiler.zig:232-242` (compileAttributes function)
**Severity**: MEDIUM
**Description**:
Attribute values aren't HTML-escaped. Dynamic attributes can inject attributes/quotes.

**Example**:
```pug
a(title=userInput)
```

If `userInput = 'foo" onclick="alert(1)'`, renders as:
```html
<a title="foo" onclick="alert(1)">
```

---

### 12. Unreachable Code in Parser (CODE QUALITY)
**Location**: `src/parser.zig:748`
**Severity**: LOW
**Description**:
In parseCase, there's a `break` statement that becomes unreachable after default block processing due to loop structure.

---

### 13. Index Variable Name Never Set in Loops (BUG)
**Location**: `src/compiler.zig:383-462` (compileLoop)
**Severity**: MEDIUM
**Description**:
Even if parser provides `loop.index`, the variable is set but `loop.iterator` is empty string, making loop variable access impossible anyway.

---

## ARCHITECTURAL ISSUES

### 14. No Type System for Runtime Values (DESIGN)
**Severity**: MEDIUM
**Description**:
JavaScript values are evaluated as strings. Case statements and conditionals don't properly handle type coercion. Number `1`, string `"1"`, and boolean `true` all stringify to different values.

---

### 15. Mixin Scope Isolation Missing (DESIGN)
**Severity**: MEDIUM
**Description**:
No local scope for mixin parameters. Setting parameters pollutes global runtime context. Multiple mixin calls could have variable conflicts.

---

## SUMMARY TABLE

| Issue | File:Line | Type | Severity | Impact |
|-------|-----------|------|----------|--------|
| Multiple classes → duplicate attributes | parser.zig:136-155 | Bug | CRITICAL | Invalid HTML |
| Loop iterator not extracted | parser.zig:641 | Bug | CRITICAL | Loops broken |
| Mixin args not substituted | compiler.zig:579-595 | Bug | CRITICAL | Mixins don't work |
| Comment content not escaped | compiler.zig:333-341 | Security | CRITICAL | XSS vulnerability |
| Attribute concatenation missing | parser.zig:226-268 | Feature | HIGH | Dynamic attrs fail |
| Test file wrong | build.zig:180-186 | Build | HIGH | Tests not run |
| Block modes not implemented | compiler.zig:170-185 | Feature | HIGH | Template inheritance broken |
| Include filters not implemented | compiler.zig:468-526 | Feature | HIGH | Filters don't work |
| Loop else missing | parser.zig:608-649 | Feature | MEDIUM | No fallback rendering |
| Case comparison type issue | compiler.zig:532-568 | Bug | MEDIUM | Type mismatches fail |
| Attribute escaping missing | compiler.zig:232-242 | Security | MEDIUM | XSS in attributes |

---

## RECOMMENDED FIX ORDER

1. **Multiple Classes** (parser.zig) - Blocks basic functionality
2. **Loop Iterator Parsing** (parser.zig) - Core feature broken
3. **Mixin Arguments** (compiler.zig) - Core feature broken  
4. **Comment Escaping** (compiler.zig) - Security issue
5. **Test Configuration** (build.zig) - Infrastructure
6. **Block Modes** (compiler.zig) - Template inheritance
7. **Attribute Escaping** (compiler.zig) - Security issue
8. **Case Type Comparison** (compiler.zig) - Logic correctness
9. **Loop else** (parser.zig) - Feature completeness
10. **Include Filters** (compiler.zig) - Feature completeness

