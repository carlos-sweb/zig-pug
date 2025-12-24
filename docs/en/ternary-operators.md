# Ternary Operators in Attribute Expressions

Zig-Pug supports ternary conditional operators (`? :`) in attribute expressions, allowing you to write dynamic, conditional attribute values inline.

## Table of Contents

- [Basic Syntax](#basic-syntax)
- [Simple Examples](#simple-examples)
- [Comparison Operators](#comparison-operators)
- [Logical Operators](#logical-operators)
- [Complex Expressions](#complex-expressions)
- [Nested Ternary Operators](#nested-ternary-operators)
- [Best Practices](#best-practices)

## Basic Syntax

The ternary operator follows the standard JavaScript syntax:

```pug
element(attribute=condition ? valueIfTrue : valueIfFalse)
```

**Components:**
- `condition`: Any expression that evaluates to a boolean
- `?`: The ternary operator
- `valueIfTrue`: Value used when condition is true
- `:`: Separator
- `valueIfFalse`: Value used when condition is false

## Simple Examples

### Boolean Variable

```pug
- var isActive = true
div(class=isActive ? "active" : "inactive")
```

**Output:**
```html
<div class="active"></div>
```

### With Text Content

```pug
- var loggedIn = false
button(class=loggedIn ? "logout-btn" : "login-btn") Click me
```

**Output:**
```html
<button class="login-btn">Click me</button>
```

### Multiple Attributes

```pug
- var enabled = true
button(
  class=enabled ? "btn-primary" : "btn-disabled",
  type="submit"
) Submit
```

**Output:**
```html
<button class="btn-primary" type="submit">Submit</button>
```

## Comparison Operators

Ternary operators work with all comparison operators:

### Greater Than (`>`)

```pug
- var score = 85
p(class=score > 80 ? "excellent" : "good") Your score
```

**Output:**
```html
<p class="excellent">Your score</p>
```

### Less Than (`<`)

```pug
- var temperature = 15
div(class=temperature < 20 ? "cold" : "warm") Weather
```

**Output:**
```html
<div class="cold">Weather</div>
```

### Greater Than or Equal (`>=`)

```pug
- var age = 18
span(title=age >= 18 ? "adult" : "minor") User status
```

**Output:**
```html
<span title="adult">User status</span>
```

### Less Than or Equal (`<=`)

```pug
- var stock = 5
div(data-status=stock <= 10 ? "low-stock" : "in-stock") Inventory
```

**Output:**
```html
<div data-status="low-stock">Inventory</div>
```

### Equality (`==`)

```pug
- var theme = "dark"
body(class=theme == "dark" ? "dark-mode" : "light-mode")
```

**Output:**
```html
<body class="dark-mode"></body>
```

## Logical Operators

Combine conditions with logical operators for more complex expressions.

### AND Operator (`&&`)

```pug
- var isLoggedIn = true
- var hasPermission = true
div(class=isLoggedIn && hasPermission ? "authorized" : "unauthorized") Content
```

**Output:**
```html
<div class="authorized">Content</div>
```

### OR Operator (`||`)

```pug
- var isAdmin = false
- var isModerator = true
span(data-role=isAdmin || isModerator ? "staff" : "user") Badge
```

**Output:**
```html
<span data-role="staff">Badge</span>
```

### Combined Logical Operators

```pug
- var age = 25
- var hasLicense = true
div(class=age >= 18 && hasLicense ? "can-drive" : "cannot-drive") Driver status
```

**Output:**
```html
<div class="can-drive">Driver status</div>
```

## Complex Expressions

### Property Access

```pug
- var user = { name: "Alice", age: 30, role: "admin" }
span(title=user.age >= 18 ? "adult" : "minor") #{user.name}
a(href=user.role == "admin" ? "/admin" : "/dashboard") Dashboard
```

**Output:**
```html
<span title="adult">Alice</span>
<a href="/admin">Dashboard</a>
```

### Arithmetic Expressions

```pug
- var count = 5
- var threshold = 3
p(data-level=count + 2 > threshold ? "high" : "low") Item count
```

**Output:**
```html
<p data-level="high">Item count</p>
```

### Boolean Literals

```pug
- var items = 0
input(type="checkbox", disabled=items < 1 ? true : false)
```

**Output:**
```html
<input type="checkbox" disabled="true">
```

### String Concatenation in Values

```pug
- var status = "active"
div(class=status == "active" ? "status-" + status : "status-inactive") Status
```

**Output:**
```html
<div class="status-active">Status</div>
```

## Nested Ternary Operators

You can nest ternary operators for multi-level conditions.

### Simple Nested Ternary

```pug
- var score = 75
p(class=score >= 90 ? "A" : score >= 70 ? "B" : "C") Grade
```

**Output:**
```html
<p class="B">Grade</p>
```

### Complex Nested Example

```pug
- var priority = 2
- var urgent = false
div(
  class=priority == 1 ? "critical" : priority == 2 && urgent ? "high" : priority == 2 ? "medium" : "low"
) Task
```

**Output:**
```html
<div class="medium">Task</div>
```

### Multi-level Nested

```pug
- var value = 7
span(
  data-category=value > 10 ? "high" : value > 5 ? "medium" : value > 0 ? "low" : "none"
) Category
```

**Output:**
```html
<span data-category="medium">Category</span>
```

## Best Practices

### 1. Keep It Readable

**Good:**
```pug
- var active = true
div(class=active ? "active" : "inactive")
```

**Avoid (too complex):**
```pug
div(class=a && b || c ? d == e ? f : g && h ? i : j : k)
```

### 2. Use Variables for Complex Conditions

**Good:**
```pug
- var canEdit = user.role == "admin" || user.role == "editor"
button(disabled=canEdit ? false : true) Edit
```

**Less readable:**
```pug
button(disabled=user.role == "admin" || user.role == "editor" ? false : true)
```

### 3. Limit Nesting Depth

For more than 2 levels of nesting, consider using if/else statements instead:

**Good:**
```pug
- var className
- if score >= 90
  - className = "A"
- else if score >= 70
  - className = "B"
- else
  - className = "C"
p(class=className) Grade
```

### 4. Be Explicit with Boolean Values

**Good:**
```pug
input(disabled=count < 1 ? true : false)
```

**Also acceptable:**
```pug
- var isDisabled = count < 1
input(disabled=isDisabled)
```

### 5. Use Meaningful Variable Names

**Good:**
```pug
- var isUserActive = user.status == "active"
div(class=isUserActive ? "online" : "offline")
```

**Avoid:**
```pug
div(class=u.s == "a" ? "on" : "off")
```

## Complete Example

Here's a comprehensive example using various ternary operator features:

```pug
- var user = { name: "Alice", age: 30, role: "admin", active: true }
- var itemCount = 5
- var theme = "dark"

.user-card(class=user.active && itemCount > 0 ? "active-user" : "inactive-user")
  h2(class=theme == "dark" ? "text-light" : "text-dark") #{user.name}

  span.age(title=user.age >= 18 ? "adult" : "minor") Age: #{user.age}

  .badge(class=user.role == "admin" ? "badge-admin" : user.role == "editor" ? "badge-editor" : "badge-user")= user.role

  .items(data-status=itemCount > 10 ? "many" : itemCount > 0 ? "some" : "none")
    | Items: #{itemCount}

  a.dashboard-link(href=user.role == "admin" || user.role == "moderator" ? "/admin" : "/user") Dashboard
```

**Output:**
```html
<div class="user-card active-user">
  <h2 class="text-light">Alice</h2>
  <span class="age" title="adult">Age: 30</span>
  <div class="badge badge-admin">admin</div>
  <div class="items" data-status="some">Items: 5</div>
  <a class="dashboard-link" href="/admin">Dashboard</a>
</div>
```

## See Also

- [Attributes Documentation](attributes.md)
- [Expressions and Interpolation](interpolation.md)
- [Tokenizer Documentation](tokenizer.md)
- [Parser Documentation](parser.md)
