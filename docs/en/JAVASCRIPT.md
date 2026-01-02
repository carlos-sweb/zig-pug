# JavaScript in Templates

Complete guide to using JavaScript expressions in zig-pug templates.

## Table of Contents

- [Overview](#overview)
- [ES5.1 Standard](#es51-standard)
- [Interpolation](#interpolation)
- [Variables](#variables)
- [Operators](#operators)
- [Built-in Objects](#built-in-objects)
- [Functions](#functions)
- [Common Patterns](#common-patterns)
- [Limitations](#limitations)

## Overview

zig-pug uses **mujs**, a lightweight ES5.1-compliant JavaScript engine, to evaluate expressions in templates.

**Key Points:**
- ✅ ES5.1 standard (complete support)
- ✅ All standard built-ins (Math, String, Array, Object, JSON, Date)
- ✅ Synchronous execution only
- ❌ No ES6+ features (arrow functions, template literals, classes)
- ❌ No async/await, Promises
- ❌ No DOM APIs (document, window, etc.)

## ES5.1 Standard

### What's Supported

**Primitives:**
```pug
- var str = "hello"
- var num = 42
- var bool = true
- var nothing = null
- var undef = undefined
```

**Variables:**
```pug
- var x = 10
- var name = "Alice"
- var active = true
```

**Objects:**
```pug
- var user = {name: "Alice", age: 30}
- var nested = {profile: {email: "alice@example.com"}}
```

**Arrays:**
```pug
- var items = [1, 2, 3]
- var mixed = ["text", 42, true, {key: "value"}]
```

**Functions:**
```pug
- function greet(name) { return "Hello, " + name; }
- var double = function(x) { return x * 2; }
```

### What's Not Supported (ES6+)

**Arrow functions:**
```pug
// ❌ Not supported
- var double = x => x * 2

// ✅ Use this instead
- var double = function(x) { return x * 2; }
```

**Template literals:**
```pug
// ❌ Not supported
- var msg = `Hello ${name}`

// ✅ Use this instead
- var msg = "Hello " + name
```

**let/const:**
```pug
// ❌ Not supported
- const PI = 3.14
- let count = 0

// ✅ Use this instead
- var PI = 3.14
- var count = 0
```

**Classes:**
```pug
// ❌ Not supported
- class User { constructor(name) { this.name = name; } }

// ✅ Use prototypes instead
- function User(name) { this.name = name; }
```

## Interpolation

### Escaped (Safe)

Use `#{}` for HTML-escaped output:

```pug
- var name = "Alice"
- var userInput = "<script>alert('xss')</script>"

p Hello #{name}!
p User said: #{userInput}
```

**Output:**
```html
<p>Hello Alice!</p>
<p>User said: &lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>
```

### Unescaped (Dangerous)

Use `!{}` for raw HTML:

```pug
- var html = "<strong>Bold</strong>"
p Safe: #{html}
p Raw: !{html}
```

**Output:**
```html
<p>Safe: &lt;strong&gt;Bold&lt;/strong&gt;</p>
<p>Raw: <strong>Bold</strong></p>
```

**⚠️ Warning:** Never use `!{}` with user input!

## Variables

### Setting Variables

```pug
- var name = "Alice"
- var age = 30
- var active = true
```

### Using Variables

```pug
p #{name}
p #{age}
p #{active}
```

### Modifying Variables

```pug
- var count = 0
- count = count + 1
- count++
p Count: #{count}
```

### Scope

```pug
- var global = "accessible everywhere"

div
  - var local = "local to this block"
  p #{global}  // ✅ Works
  p #{local}   // ✅ Works

p #{global}  // ✅ Works
p #{local}   // ❌ Error: local not defined
```

## Operators

### Arithmetic

```pug
- var a = 10
- var b = 3

p #{a + b}   // 13
p #{a - b}   // 7
p #{a * b}   // 30
p #{a / b}   // 3.333...
p #{a % b}   // 1
```

### Comparison

```pug
- var age = 30

p #{age > 18}    // true
p #{age < 18}    // false
p #{age >= 30}   // true
p #{age <= 25}   // false
p #{age == 30}   // true
p #{age != 25}   // true
```

### Logical

```pug
- var isAdmin = true
- var isActive = true

p #{isAdmin && isActive}   // true (AND)
p #{isAdmin || false}      // true (OR)
p #{!isAdmin}              // false (NOT)
```

### Ternary

```pug
- var age = 30
p Status: #{age >= 18 ? "Adult" : "Minor"}
```

### String Concatenation

```pug
- var first = "John"
- var last = "Doe"
p Full name: #{first + " " + last}
```

## Built-in Objects

### String Methods

```pug
- var text = "hello world"

p #{text.toUpperCase()}           // HELLO WORLD
p #{text.toLowerCase()}           // hello world
p #{text.charAt(0)}               // h
p #{text.substring(0, 5)}         // hello
p #{text.replace("world", "JavaScript")}  // hello JavaScript
p #{text.split(" ").join("-")}    // hello-world
```

### Number Methods

```pug
- var num = 19.99

p #{num.toFixed(2)}       // 19.99
p #{num.toFixed(0)}       // 20
p #{parseInt("42")}       // 42
p #{parseFloat("3.14")}   // 3.14
```

### Array Methods

```pug
- var items = [1, 2, 3, 4, 5]

p #{items.length}                                      // 5
p #{items.join(", ")}                                  // 1, 2, 3, 4, 5
p #{items.slice(0, 3).join(", ")}                     // 1, 2, 3
p #{items.reverse().join(", ")}                       // 5, 4, 3, 2, 1
p #{items.map(function(x) { return x * 2; }).join(", ")}  // 2, 4, 6, 8, 10
```

### Math Object

```pug
p #{Math.PI}                      // 3.141592653589793
p #{Math.round(3.7)}              // 4
p #{Math.floor(3.7)}              // 3
p #{Math.ceil(3.2)}               // 4
p #{Math.max(10, 20, 30)}         // 30
p #{Math.min(10, 20, 30)}         // 10
p #{Math.random()}                // 0.123456... (random)
p #{Math.floor(Math.random() * 100)}  // Random 0-99
```

### JSON Object

```pug
- var obj = {name: "Alice", age: 30}
- var json = JSON.stringify(obj)
p #{json}  // {"name":"Alice","age":30}

- var parsed = JSON.parse('{"name":"Bob","age":25}')
p #{parsed.name}  // Bob
```

### Date Object

```pug
- var now = new Date()
- var timestamp = now.getTime()

p #{now.getFullYear()}         // 2025
p #{now.getMonth()}            // 0-11
p #{now.getDate()}             // 1-31
p #{now.getDay()}              // 0-6 (Sunday-Saturday)
p #{now.toLocaleDateString()}  // 1/1/2025
```

## Functions

### Function Declarations

```pug
- function greet(name) {
-   return "Hello, " + name + "!";
- }

p #{greet("Alice")}  // Hello, Alice!
```

### Function Expressions

```pug
- var double = function(x) {
-   return x * 2;
- }

p #{double(21)}  // 42
```

### Closures

```pug
- function makeCounter() {
-   var count = 0;
-   return function() {
-     count++;
-     return count;
-   };
- }
- var counter = makeCounter()

p #{counter()}  // 1
p #{counter()}  // 2
p #{counter()}  // 3
```

### Higher-Order Functions

```pug
- var numbers = [1, 2, 3, 4, 5]

// map
- var doubled = numbers.map(function(x) { return x * 2; })
p #{doubled.join(", ")}  // 2, 4, 6, 8, 10

// filter
- var evens = numbers.filter(function(x) { return x % 2 == 0; })
p #{evens.join(", ")}  // 2, 4

// reduce
- var sum = numbers.reduce(function(a, b) { return a + b; }, 0)
p Sum: #{sum}  // Sum: 15
```

## Common Patterns

### Formatting Currency

```pug
- function formatCurrency(amount) {
-   return "$" + amount.toFixed(2);
- }

- var price = 19.99
p Price: #{formatCurrency(price)}  // Price: $19.99
```

### Formatting Dates

```pug
- function formatDate(timestamp) {
-   var d = new Date(timestamp);
-   return d.toLocaleDateString();
- }

- var timestamp = 1609459200000
p Date: #{formatDate(timestamp)}
```

### Truncating Text

```pug
- function truncate(text, max) {
-   if (text.length <= max) return text;
-   return text.substring(0, max) + "...";
- }

- var description = "This is a very long description that needs truncating"
p #{truncate(description, 20)}  // This is a very long...
```

### Pluralization

```pug
- function pluralize(count, singular, plural) {
-   return count + " " + (count == 1 ? singular : plural);
- }

- var itemCount = 5
p You have #{pluralize(itemCount, "item", "items")}  // You have 5 items
```

### Array Utilities

```pug
- function first(arr) { return arr[0]; }
- function last(arr) { return arr[arr.length - 1]; }
- function isEmpty(arr) { return arr.length == 0; }

- var items = ["apple", "banana", "orange"]
p First: #{first(items)}    // First: apple
p Last: #{last(items)}      // Last: orange
p Empty: #{isEmpty(items)}  // Empty: false
```

### Object Utilities

```pug
- function pick(obj, keys) {
-   var result = {};
-   for (var i = 0; i < keys.length; i++) {
-     if (obj.hasOwnProperty(keys[i])) {
-       result[keys[i]] = obj[keys[i]];
-     }
-   }
-   return result;
- }

- var user = {name: "Alice", age: 30, email: "alice@example.com", role: "admin"}
- var publicInfo = pick(user, ["name", "age"])
```

## Limitations

### No Asynchronous Operations

```pug
// ❌ Not available
- await fetch(url)
- Promise.resolve()
- setTimeout(fn, 100)
```

**Why:** Templates are compiled synchronously. Prepare all data before compilation.

### No DOM APIs

```pug
// ❌ Not available
- document.getElementById()
- window.location
- localStorage.getItem()
```

**Why:** Templates generate static HTML. Client-side JavaScript is separate.

### No ES6+ Features

See [ES5.1 Standard](#es51-standard) section for details.

### No require/import

```pug
// ❌ Not available
- var lib = require('library')
- import { func } from 'module'
```

**Why:** mujs doesn't support modules. Define functions inline or via unbuffered code.

## Performance Tips

### 1. Cache Expensive Computations

**❌ Bad:**
```pug
each user in users
  p Total: #{users.reduce(function(sum, u) { return sum + u.score; }, 0)}
```

**✅ Good:**
```pug
- var total = users.reduce(function(sum, u) { return sum + u.score; }, 0)
each user in users
  p Total: #{total}
```

### 2. Avoid Complex Expressions

**❌ Bad:**
```pug
p #{items.filter(function(x) { return x.active; }).map(function(x) { return x.name; }).join(", ")}
```

**✅ Good:**
```pug
- var activeNames = items.filter(function(x) { return x.active; }).map(function(x) { return x.name; })
p #{activeNames.join(", ")}
```

### 3. Use Simple Property Access

**❌ Bad:**
```pug
p #{user["profile"]["settings"]["theme"]["color"]}
```

**✅ Good:**
```pug
p #{user.profile.settings.theme.color}
```

## See Also

- [VARIABLES.md](VARIABLES.md) - Working with variables
- [../MUJS-INTEGRATION.md](../MUJS-INTEGRATION.md) - JavaScript runtime details
- [SECURITY.md](SECURITY.md) - Security best practices
- [OPTIMIZATION.md](OPTIMIZATION.md) - Performance optimization
