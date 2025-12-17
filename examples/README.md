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

### 6. `loops.zpug`
**Loops and Conditionals**

Demonstrates array iteration and conditional rendering:
- Basic `each` loops: `each item in array`
- Multiple loops in the same template
- Handling empty arrays with `if array.length > 0`

**Concepts**: Iteration, loops, conditional rendering

**Supported in v0.3.x**:
- ✅ Property access: `if array.length`
- ✅ Comparisons: `if age >= 18`, `if score > 50`
- ✅ Logical operators: `if a && b`, `if x || y`
- ✅ String equality: `if status == "active"`
- ✅ Combined expressions: `if age >= 18 && hasPermission`

**Current Limitations in v0.3.x**:
- ❌ Loop with index (`each item, i in array`) - **NOT supported**
- ❌ `each...else` syntax - **NOT supported** (use `if array.length > 0` instead)

---

### 7. `06-conditionals-advanced.zpug`
**Advanced Conditionals**

Comprehensive demonstration of all `if` statement capabilities:
- Property access: `user.isActive`, `array.length`
- Comparison operators: `>=`, `>`, `<`, `<=`, `==`
- Logical operators: `&&` (AND), `||` (OR)
- String equality checks
- Combined complex expressions
- Array operations and length checks
- Real-world usage patterns (dashboards, access control, badges)

**Concepts**: Advanced conditionals, property access, logical expressions, real-world patterns

**Features Demonstrated**:
- ✅ Object property checks: `if user.isPremium`
- ✅ Age verification: `if age >= 18`
- ✅ Score ranges: `if score > 90` ... `else if score > 75`
- ✅ Stock alerts: `if stock < 10`
- ✅ Status matching: `if status == "approved"`
- ✅ Multiple conditions: `if age >= 18 && hasLicense`
- ✅ Alternative conditions: `if isAdmin || isModerator`
- ✅ Complex expressions: `if (isAdmin || isModerator) && user.isActive`
- ✅ Empty array handling: `if items.length > 0`
- ✅ Nested conditionals for UI state management

This example serves as a complete reference for conditional logic in zig-pug templates.

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

### loops.zpug
```zig
// Arrays for loops
_ = try js_runtime.eval(
    \\var users = ['Alice', 'Bob', 'Charlie'];
);
_ = try js_runtime.eval(
    \\var fruits = ['Apple', 'Banana', 'Orange'];
);
_ = try js_runtime.eval(
    \\var products = []; // Empty array to demonstrate conditional rendering
);
```

### 06-conditionals-advanced.zpug
```zig
// User object
_ = try js_runtime.eval(
    \\var user = {
    \\  name: 'Alice Johnson',
    \\  isActive: true,
    \\  isPremium: true,
    \\  memberSince: '2023-01-15'
    \\};
);

// Numeric values
try js_runtime.setNumber("age", 25);
try js_runtime.setNumber("score", 85);
try js_runtime.setNumber("stock", 7);
try js_runtime.setNumber("bonusPoints", 120);
try js_runtime.setNumber("purchases", 15);

// String values
try js_runtime.setString("status", "approved");

// Boolean values
try js_runtime.setBool("hasLicense", true);
try js_runtime.setBool("isAdmin", false);
try js_runtime.setBool("isModerator", true);

// Arrays
_ = try js_runtime.eval(
    \\var notifications = ['New message', 'Update available', 'System alert'];
);
_ = try js_runtime.eval(
    \\var items = ['Laptop', 'Mouse', 'Keyboard'];
);
_ = try js_runtime.eval(
    \\var products = ['Product A', 'Product B', 'Product C', 'Product D'];
);
```

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
