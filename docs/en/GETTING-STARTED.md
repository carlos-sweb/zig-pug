# Quick Start Guide - zig-pug

This guide will take you step by step from installation to creating your first template with zig-pug.

## Prerequisites

Before you begin, make sure you have:

- **Zig 0.15.2** installed ([download here](https://ziglang.org/download/))
- Terminal/command line
- Text editor (VS Code, Vim, etc.)

### Verify Zig Installation

```bash
zig version
# Expected output: 0.15.2
```

## Step 1: Clone and Install

```bash
# Clone the repository
git clone https://github.com/yourusername/zig-pug
cd zig-pug

# Build the project
zig build

# Verify it compiled correctly
./zig-out/bin/zig-pug
```

**Expected output:**
```
zig-pug v0.1.0
Template engine inspired by Pug
Built with Zig 0.15.2
...
```

## Step 2: Your First Template

Let's create a simple template step by step.

### 2.1: Create the Template File

Create a file `hello.pug`:

```pug
div.greeting
  h1 Hello World!
  p This is my first zig-pug template
```

### 2.2: Create the Zig Program

Create a file `example.zig` in the root directory:

```zig
const std = @import("std");
const parser = @import("src/parser.zig");
const compiler = @import("src/compiler.zig");
const runtime = @import("src/runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Your Pug template
    const template =
        \\div.greeting
        \\  h1 Hello World!
        \\  p This is my first zig-pug template
    ;

    // 1. Create the JavaScript runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // 2. Parse the template
    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    // 3. Compile to HTML
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(ast);
    defer allocator.free(html);

    // 4. Display the result
    std.debug.print("HTML Output:\n{s}\n", .{html});
}
```

### 2.3: Compile and Run

```bash
zig build-exe example.zig -I src

./example
```

**Output:**
```html
<div class="greeting"><h1>Hello World!</h1><p>This is my first zig-pug template</p></div>
```

Congratulations! You've created your first template with zig-pug.

## Step 3: Adding Variables

Now let's make the template dynamic using variables.

### 3.1: Template with Interpolation

```pug
div.user-card
  h2 Welcome #{name}!
  p You are #{age} years old
  p Email: #{email}
```

### 3.2: Program with Variables

```zig
const std = @import("std");
const parser = @import("src/parser.zig");
const compiler = @import("src/compiler.zig");
const runtime = @import("src/runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const template =
        \\div.user-card
        \\  h2 Welcome #{name}!
        \\  p You are #{age} years old
        \\  p Email: #{email}
    ;

    // Create runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Set variables
    try js_runtime.setString("name", "Alice");
    try js_runtime.setNumber("age", 25);
    try js_runtime.setString("email", "alice@example.com");

    // Parse and compile
    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(ast);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

**Output:**
```html
<div class="user-card"><h2>WelcomeAlice!</h2><p>You are25years old</p><p>Email:alice@example.com</p></div>
```

## Step 4: Using JavaScript Methods

zig-pug supports JavaScript methods in interpolations.

### 4.1: Template with Methods

```pug
div.profile
  h1 #{name.toUpperCase()}
  p Email: #{email.toLowerCase()}
  p Age next year: #{age + 1}
  p Double age: #{age * 2}
```

### 4.2: Program (Same Code as Before)

The code is the same, only the template changes. JavaScript methods work automatically.

**Output:**
```html
<div class="profile"><h1>ALICE</h1><p>Email:alice@example.com</p><p>Age next year:26</p><p>Double age:50</p></div>
```

## Step 5: Conditionals

Add conditional logic to your templates.

### 5.1: Template with if/else

```pug
div.status
  h2 User Status
  if isActive
    p.active User is active
  else
    p.inactive User is inactive

  if age >= 18
    p You can vote
  else
    p Too young to vote
```

### 5.2: Program with Booleans

```zig
// ... (same setup as before) ...

// Set variables
try js_runtime.setString("name", "Bob");
try js_runtime.setNumber("age", 16);
try js_runtime.setBool("isActive", true);

// ... (parse and compile) ...
```

**Output:**
```html
<div class="status"><h2>User Status</h2><p class="active">User is active</p><p>Too young to vote</p></div>
```

## Step 6: Working with Objects

### 6.1: Creating Objects in JavaScript

```zig
// ... (setup) ...

var js_runtime = try runtime.JsRuntime.init(allocator);
defer js_runtime.deinit();

// Create an object in JavaScript
_ = try js_runtime.eval(
    \\var user = {
    \\  firstName: 'John',
    \\  lastName: 'Doe',
    \\  email: 'JOHN.DOE@EXAMPLE.COM',
    \\  age: 30
    \\};
);
```

### 6.2: Template with Object Properties

```pug
div.profile
  h1 #{user.firstName} #{user.lastName}
  p Email: #{user.email.toLowerCase()}
  p Age: #{user.age}
  p Next birthday: #{user.age + 1}
```

**Output:**
```html
<div class="profile"><h1>JohnDoe</h1><p>Email:john.doe@example.com</p><p>Age:30</p><p>Next birthday:31</p></div>
```

## Step 7: Mixins (Reusable Components)

Mixins allow you to create components that you can reuse.

### 7.1: Template with Mixins

```pug
mixin card(title, text)
  div.card
    h3.card-title= title
    p.card-text= text

div.container
  +card('Welcome', 'This is the first card')
  +card('About', 'This is the second card')
  +card('Contact', 'This is the third card')
```

### 7.2: Program (Standard Code)

Mixins work automatically with the same code as always.

## Step 8: Complete Real Example

Now let's create a complete example that combines everything we've learned.

### 8.1: Complete Template

Create `profile.pug`:

```pug
div.user-profile
  div.header
    h1 #{user.name.toUpperCase()}
    if user.isVerified
      span.badge Verified

  div.info
    p Email: #{user.email.toLowerCase()}
    p Age: #{user.age}
    p Member since: #{user.year}

  div.stats
    p Posts: #{user.stats.posts}
    p Followers: #{user.stats.followers}
    p Following: #{user.stats.following}

  div.actions
    if user.age >= 18
      button.btn Vote Now

    unless user.isVerified
      button.btn.verify Verify Account
```

### 8.2: Complete Program

Create `profile_example.zig`:

```zig
const std = @import("std");
const parser = @import("src/parser.zig");
const compiler = @import("src/compiler.zig");
const runtime = @import("src/runtime.zig");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Read the template from file (or use string)
    const template = @embedFile("profile.pug");

    // Create runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Create a complete user object
    _ = try js_runtime.eval(
        \\var user = {
        \\  name: 'Alice Johnson',
        \\  email: 'ALICE.JOHNSON@EXAMPLE.COM',
        \\  age: 25,
        \\  year: 2020,
        \\  isVerified: true,
        \\  stats: {
        \\    posts: 42,
        \\    followers: 156,
        \\    following: 89
        \\  }
        \\};
    );

    // Parse
    var pars = try parser.Parser.init(allocator, template);
    defer pars.deinit();
    const ast = try pars.parse();

    // Compile
    var comp = try compiler.Compiler.init(allocator, js_runtime);
    defer comp.deinit();
    const html = try comp.compile(ast);
    defer allocator.free(html);

    // Save to file
    const file = try std.fs.cwd().createFile("output.html", .{});
    defer file.close();
    try file.writeAll(html);

    std.debug.print("HTML generated in output.html\n", .{});
}
```

### 8.3: Compile and Run

```bash
zig build-exe profile_example.zig -I src
./profile_example
```

This will create `output.html` with all the generated HTML.

## Next Steps

Now that you've mastered the basics, you can:

1. **Read the complete documentation**:
   - [PUG-SYNTAX.md](PUG-SYNTAX.md) - All Pug features
   - [API-REFERENCE.md](API-REFERENCE.md) - Complete zig-pug API

2. **See more examples**:
   - [examples/](../examples/) - Practical examples

3. **Explore advanced features**:
   - Loops (when implemented)
   - Template inheritance
   - Custom filters

## Common Issues

### Error: "unable to detect native libc"

This error occurs if you try to compile with `-lc`. zig-pug already includes everything needed, you don't need to link with libc manually.

**Solution**: Just use `zig build-exe example.zig -I src`

### Spaces Disappear in HTML

This is normal behavior of the current parser. The generated HTML is functional even though it doesn't have decorative spaces.

### Variable Not Found

Make sure to set the variable BEFORE parsing the template:

```zig
// Correct
try js_runtime.setString("name", "Alice");
var pars = try parser.Parser.init(allocator, template);
// ...

// Incorrect (variable set after parsing)
var pars = try parser.Parser.init(allocator, template);
try js_runtime.setString("name", "Alice"); // Too late!
```

## Additional Resources

- **[README.md](../README.md)** - Project overview
- **[MUJS-INTEGRATION.md](../MUJS-INTEGRATION.md)** - JavaScript engine details
- **[Pug Documentation](https://pugjs.org/)** - Original Pug reference
- **[Zig Documentation](https://ziglang.org/documentation/master/)** - Zig language guide

---

Congratulations! You're now ready to create powerful templates with zig-pug.
