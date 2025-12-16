[Español](README.es.md) | English

# zig-pug Examples

This folder contains practical examples of Pug templates for zig-pug.

## 📁 Example Files

### 1. `01-basic.zpug`
**Basic Tags and Attributes**

Demonstrates basic Pug syntax:
- Simple tags (`div`, `p`, `h1`)
- Classes (`.class`)
- IDs (`#id`)
- Attributes `(attr="value")`

**Concepts**: Tags, nesting, attributes

---

### 2. `02-interpolation.zpug`
**JavaScript Interpolation**

Shows how to use variables and JavaScript expressions:
- Simple variables: `#{name}`
- Methods: `#{name.toUpperCase()}`
- Arithmetic: `#{age + 1}`
- Complex expressions: `#{age >= 18 ? 'Yes' : 'No'}`

**Concepts**: Interpolation, JavaScript methods, operators

---

### 3. `03-conditionals.zpug`
**Conditionals**

Demonstrates conditional logic in templates:
- `if`/`else`
- `else if` (multiple conditions)
- `unless` (negation)
- Expressions in conditions

**Concepts**: Control flow, conditional logic

---

### 4. `04-mixins.zpug`
**Mixins (Reusable Components)**

Shows how to create and use mixins:
- Define mixins: `mixin name(params)`
- Call mixins: `+name(args)`
- Mixins with parameters
- Component reusability

**Concepts**: Components, reusability, DRY

---

### 5. `05-complete-example.zpug`
**Complete Example**

Combines all features in a real-world example:
- Complete HTML structure
- Dynamic navigation
- Dashboard with statistics
- User roles
- Complex mixins
- Everything integrated

**Concepts**: Real application, best practices

---

## 🚀 How to Use the Examples

### Option 1: Copy and Paste

Copy the content from any example into your Zig code:

```zig
const template = @embedFile("examples/01-basic.zpug");

// ... parse and compile ...
```

### Option 2: Create a Test Program

Create `test_example.zig`:

```zig
const std = @import("std");
const parser = @import("src/parser.zig");
const compiler = @import("src/compiler.zig");
const runtime = @import("src/runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Read the example
    const template = @embedFile("examples/02-interpolation.zpug");

    // Create runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Set required variables
    try js_runtime.setString("name", "Alice");
    try js_runtime.setString("email", "ALICE@EXAMPLE.COM");
    try js_runtime.setNumber("age", 25);

    // Parse
    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    // Compile
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(ast);
    defer allocator.free(html);

    // Display result
    std.debug.print("{s}\n", .{html});
}
```

Compile and run:

```bash
zig build-exe test_example.zig -I src
./test_example
```

## 📚 Required Variables per Example

### 01-basic.zpug
No variables required (static HTML).

### 02-interpolation.zpug
```zig
try js_runtime.setString("name", "Alice");
try js_runtime.setString("email", "alice@example.com");
try js_runtime.setNumber("age", 25);
```

### 03-conditionals.zpug
```zig
try js_runtime.setBool("isLoggedIn", true);
try js_runtime.setNumber("age", 20);
try js_runtime.setBool("hasPermission", false);
try js_runtime.setString("role", "admin");
```

### 04-mixins.zpug
No external variables required (mixins use parameters).

### 05-complete-example.zpug
```zig
// Site
try js_runtime.setString("siteName", "MiApp");
try js_runtime.setNumber("currentYear", 2024);

// Current user
_ = try js_runtime.eval(
    \\var currentUser = {
    \\  name: 'John Doe',
    \\  role: 'admin',
    \\  isPremium: true
    \\};
);

try js_runtime.setString("lastLogin", "2024-11-18");
try js_runtime.setString("premiumUntil", "2025-12-31");
try js_runtime.setBool("isAdmin", true);

// Statistics
_ = try js_runtime.eval(
    \\var stats = {
    \\  posts: 42,
    \\  followers: 156,
    \\  following: 89
    \\};
);

// Admin data
_ = try js_runtime.eval(
    \\var adminData = {
    \\  totalUsers: 1250,
    \\  newToday: 15
    \\};
);
```

## 💡 Tips

1. **Start simple**: Begin with `01-basic.zpug` and progress from there.

2. **Experiment**: Modify the examples and see what happens.

3. **Combine features**: Take ideas from multiple examples and combine them.

4. **Review the output**: Always check the generated HTML to understand how it works.

## 🔗 Related Resources

- [README.md](../README.md) - Project overview
- [docs/GETTING-STARTED.md](../docs/GETTING-STARTED.md) - Step-by-step guide
- [docs/PUG-SYNTAX.md](../docs/PUG-SYNTAX.md) - Complete syntax reference

---

Found a bug or have a suggestion? [Open an issue](https://github.com/carlos-sweb/zig-pug/issues)
