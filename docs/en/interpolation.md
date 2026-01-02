# Interpolation

Complete guide to text and expression interpolation in zig-pug templates.

## Table of Contents

- [Basic Interpolation](#basic-interpolation)
- [Escaped vs Unescaped](#escaped-vs-unescaped)
- [Expression Types](#expression-types)
- [Common Patterns](#common-patterns)
- [Best Practices](#best-practices)

## Basic Interpolation

### Syntax

Use `#{}` to interpolate JavaScript expressions into text:

```pug
p Hello #{name}!
```

**With variables:**
```javascript
{ name: "Alice" }
```

**Output:**
```html
<p>Hello Alice!</p>
```

### Inline Text

```pug
p This is #{adjective} text
h1 Welcome to #{siteName}
span User: #{user.name}
```

**With variables:**
```javascript
{
  adjective: "awesome",
  siteName: "My Site",
  user: { name: "Bob" }
}
```

**Output:**
```html
<p>This is awesome text</p>
<h1>Welcome to My Site</h1>
<span>User: Bob</span>
```

### Multiple Interpolations

```pug
p #{firstName} #{lastName} (#{age} years old)
```

**With variables:**
```javascript
{
  firstName: "John",
  lastName: "Doe",
  age: 30
}
```

**Output:**
```html
<p>John Doe (30 years old)</p>
```

## Escaped vs Unescaped

### Escaped (Default - Safe)

Use `#{}` for HTML-escaped output:

```pug
- var userInput = "<script>alert('XSS')</script>"
p User said: #{userInput}
```

**Output (safe):**
```html
<p>User said: &lt;script&gt;alert(&#39;XSS&#39;)&lt;/script&gt;</p>
```

**Escaped characters:**
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&#39;`

### Unescaped (Dangerous - Use with Caution)

Use `!{}` for raw HTML output:

```pug
- var html = "<strong>Bold text</strong>"
p Safe: #{html}
p Raw: !{html}
```

**Output:**
```html
<p>Safe: &lt;strong&gt;Bold text&lt;/strong&gt;</p>
<p>Raw: <strong>Bold text</strong></p>
```

**⚠️ Security Warning:**
- **Never** use `!{}` with user input
- Only use with HTML you control
- Risk of XSS attacks

**Safe usage:**
```pug
// ✅ SAFE - You control this HTML
- var safeHtml = "<em>Emphasized</em>"
p !{safeHtml}

// ✅ SAFE - Rendered from trusted markdown
- var trustedMarkdown = renderMarkdown(adminContent)
p !{trustedMarkdown}

// ❌ DANGEROUS - User input
- var userComment = req.body.comment
p !{userComment}  // XSS VULNERABILITY!
```

## Expression Types

### Simple Variables

```pug
- var name = "Alice"
- var age = 30
- var active = true

p Name: #{name}
p Age: #{age}
p Active: #{active}
```

**Output:**
```html
<p>Name: Alice</p>
<p>Age: 30</p>
<p>Active: true</p>
```

### String Methods

```pug
- var text = "hello world"

p #{text.toUpperCase()}
p #{text.toLowerCase()}
p #{text.charAt(0)}
p #{text.substring(0, 5)}
p #{text.replace("world", "universe")}
```

**Output:**
```html
<p>HELLO WORLD</p>
<p>hello world</p>
<p>h</p>
<p>hello</p>
<p>hello universe</p>
```

### Arithmetic

```pug
- var price = 19.99
- var quantity = 3
- var taxRate = 0.1

p Price: $#{price}
p Quantity: #{quantity}
p Subtotal: $#{price * quantity}
p Tax: $#{(price * quantity * taxRate).toFixed(2)}
p Total: $#{(price * quantity * (1 + taxRate)).toFixed(2)}
```

**Output:**
```html
<p>Price: $19.99</p>
<p>Quantity: 3</p>
<p>Subtotal: $59.97</p>
<p>Tax: $5.99</p>
<p>Total: $65.97</p>
```

### Object Access

```pug
- var user = {
-   name: "Alice",
-   age: 30,
-   profile: {
-     email: "alice@example.com",
-     avatar: "/images/alice.jpg"
-   }
- }

p Name: #{user.name}
p Age: #{user.age}
p Email: #{user.profile.email}
```

**Output:**
```html
<p>Name: Alice</p>
<p>Age: 30</p>
<p>Email: alice@example.com</p>
```

### Array Access

```pug
- var items = ["apple", "banana", "orange"]
- var scores = [95, 87, 92]

p First: #{items[0]}
p Last: #{items[items.length - 1]}
p Count: #{items.length}
p Average: #{(scores[0] + scores[1] + scores[2]) / 3}
```

**Output:**
```html
<p>First: apple</p>
<p>Last: orange</p>
<p>Count: 3</p>
<p>Average: 91.33333333333333</p>
```

### Ternary Operators

```pug
- var age = 30
- var score = 85
- var isActive = true

p Status: #{age >= 18 ? "Adult" : "Minor"}
p Grade: #{score >= 90 ? "A" : (score >= 80 ? "B" : "C")}
p Access: #{isActive ? "Granted" : "Denied"}
```

**Output:**
```html
<p>Status: Adult</p>
<p>Grade: B</p>
<p>Access: Granted</p>
```

### Math Functions

```pug
p Max: #{Math.max(10, 20, 30)}
p Min: #{Math.min(10, 20, 30)}
p Random: #{Math.floor(Math.random() * 100)}
p PI: #{Math.PI.toFixed(2)}
p Square root: #{Math.sqrt(16)}
```

**Output (random value varies):**
```html
<p>Max: 30</p>
<p>Min: 10</p>
<p>Random: 42</p>
<p>PI: 3.14</p>
<p>Square root: 4</p>
```

### Array Methods

```pug
- var items = ["apple", "banana", "orange"]

p List: #{items.join(", ")}
p First three: #{items.slice(0, 3).join(", ")}
p Reversed: #{items.reverse().join(", ")}
```

**Output:**
```html
<p>List: apple, banana, orange</p>
<p>First three: apple, banana, orange</p>
<p>Reversed: orange, banana, apple</p>
```

### String Concatenation

```pug
- var firstName = "John"
- var lastName = "Doe"

p Full name: #{firstName + " " + lastName}
p Greeting: #{"Hello, " + firstName + "!"}
```

**Output:**
```html
<p>Full name: John Doe</p>
<p>Greeting: Hello, John!</p>
```

## Common Patterns

### Formatting Currency

```pug
- function formatCurrency(amount) {
-   return "$" + amount.toFixed(2);
- }

- var price = 19.99
p Price: #{formatCurrency(price)}
```

**Output:**
```html
<p>Price: $19.99</p>
```

### Formatting Dates

```pug
- var timestamp = 1609459200000
- var date = new Date(timestamp)

p Date: #{date.toLocaleDateString()}
p Year: #{date.getFullYear()}
```

**Output:**
```html
<p>Date: 1/1/2021</p>
<p>Year: 2021</p>
```

### Truncating Text

```pug
- function truncate(text, max) {
-   if (text.length <= max) return text;
-   return text.substring(0, max) + "...";
- }

- var description = "This is a very long description that needs to be truncated"
p #{truncate(description, 30)}
```

**Output:**
```html
<p>This is a very long descripti...</p>
```

### Pluralization

```pug
- function pluralize(count, singular, plural) {
-   return count + " " + (count == 1 ? singular : plural);
- }

- var itemCount = 5
p You have #{pluralize(itemCount, "item", "items")}
```

**Output:**
```html
<p>You have 5 items</p>
```

### Default Values

```pug
- var userName = userName || "Guest"
- var description = description || "No description"

p Welcome, #{userName}!
p #{description}
```

**With variables:**
```javascript
{} // Empty
```

**Output:**
```html
<p>Welcome, Guest!</p>
<p>No description</p>
```

### Conditional Display

```pug
- var user = {name: "Alice", isPremium: true}

p #{user.name} #{user.isPremium ? "(Premium)" : ""}
```

**Output:**
```html
<p>Alice (Premium)</p>
```

### Number Formatting

```pug
- var count = 1234567

p Count: #{count.toLocaleString()}
```

**Output:**
```html
<p>Count: 1,234,567</p>
```

### Percentage Calculation

```pug
- var completed = 7
- var total = 10
- var percentage = ((completed / total) * 100).toFixed(1)

p Progress: #{percentage}%
```

**Output:**
```html
<p>Progress: 70.0%</p>
```

### String Transformation

```pug
- var email = "ALICE@EXAMPLE.COM"

p Email: #{email.toLowerCase()}
p Domain: #{email.split('@')[1].toLowerCase()}
```

**Output:**
```html
<p>Email: alice@example.com</p>
<p>Domain: example.com</p>
```

## Best Practices

### 1. Keep Expressions Simple

**❌ Bad:**
```pug
p #{items.filter(function(i) { return i.active; }).map(function(i) { return i.name; }).join(", ")}
```

**✅ Good:**
```pug
- var activeNames = items.filter(function(i) { return i.active; }).map(function(i) { return i.name; })
p #{activeNames.join(", ")}
```

### 2. Use Functions for Complex Logic

**❌ Bad:**
```pug
p #{(price * (1 - discount) * quantity * (1 + taxRate)).toFixed(2)}
```

**✅ Good:**
```pug
- function calculateTotal(price, discount, quantity, taxRate) {
-   return (price * (1 - discount) * quantity * (1 + taxRate)).toFixed(2);
- }

p #{calculateTotal(price, discount, quantity, taxRate)}
```

### 3. Provide Defaults

**❌ Bad:**
```pug
p #{user.name}  // Error if user.name is undefined
```

**✅ Good:**
```pug
p #{user && user.name ? user.name : "Unknown"}
```

Or:
```pug
- var userName = user && user.name ? user.name : "Unknown"
p #{userName}
```

### 4. Avoid Nested Ternaries

**❌ Bad:**
```pug
p #{age >= 18 ? (score >= 90 ? "Adult A" : (score >= 80 ? "Adult B" : "Adult C")) : "Minor"}
```

**✅ Good:**
```pug
- var ageStatus = age >= 18 ? "Adult" : "Minor"
- var grade = score >= 90 ? "A" : (score >= 80 ? "B" : "C")
p #{ageStatus} #{grade}
```

### 5. Escape User Input

**❌ DANGEROUS:**
```pug
p !{userComment}  // XSS vulnerability!
```

**✅ SAFE:**
```pug
p #{userComment}  // Automatically escaped
```

### 6. Use Meaningful Variable Names

**❌ Bad:**
```pug
- var x = "John"
- var y = 30
p #{x} is #{y} years old
```

**✅ Good:**
```pug
- var userName = "John"
- var userAge = 30
p #{userName} is #{userAge} years old
```

### 7. Cache Expensive Computations

**❌ Slow:**
```pug
each user in users
  p Total: #{users.reduce(function(sum, u) { return sum + u.score; }, 0)}
```

Recalculates total for every user!

**✅ Fast:**
```pug
- var total = users.reduce(function(sum, u) { return sum + u.score; }, 0)
each user in users
  p Total: #{total}
```

### 8. Validate Data Types

**❌ Bad:**
```pug
p Length: #{items.length}  // Error if items is undefined
```

**✅ Good:**
```pug
- items = items || []
p Length: #{items.length}
```

Or:
```pug
p Length: #{items ? items.length : 0}
```

## Interpolation in Different Contexts

### In Text

```pug
p This is #{adjective} text with #{noun}
```

### In Attributes (See [attributes.md](attributes.md))

```pug
a(href=url title="Visit " + siteName)
```

### In Buffered Code

```pug
p= firstName + " " + lastName
```

Equivalent to:
```pug
p #{firstName + " " + lastName}
```

### Not in Comments

```pug
// This #{variable} won't be interpolated
```

Comments are treated as plain text, not interpolated.

## Performance

### Precompute Where Possible

**❌ Slow:**
```pug
- var users = [/* 1000 users */]
each user in users
  p Sum: #{users.reduce(function(sum, u) { return sum + u.score; }, 0)}
```

**✅ Fast:**
```pug
- var users = [/* 1000 users */]
- var sumScores = users.reduce(function(sum, u) { return sum + u.score; }, 0)
each user in users
  p Sum: #{sumScores}
```

### Avoid Repeated Calculations

**❌ Slow:**
```pug
p Name: #{user.firstName.toUpperCase() + " " + user.lastName.toUpperCase()}
p Email: #{user.firstName.toUpperCase() + "." + user.lastName.toUpperCase() + "@example.com"}
```

**✅ Fast:**
```pug
- var firstUpper = user.firstName.toUpperCase()
- var lastUpper = user.lastName.toUpperCase()
p Name: #{firstUpper + " " + lastUpper}
p Email: #{firstUpper + "." + lastUpper + "@example.com"}
```

## Debugging

### Check Variable Types

```pug
//- Debug output
p Type of user: #{typeof user}
p Type of items: #{typeof items}
p Items is array: #{Array.isArray(items)}
```

### Log Values

```pug
- console.log("userName:", userName)
- console.log("items:", items)

p User: #{userName}
```

### Display Raw Values

```pug
//- For debugging
pre= JSON.stringify({userName, items, config}, null, 2)
```

## See Also

- [attributes.md](attributes.md) - Dynamic attributes
- [JAVASCRIPT.md](JAVASCRIPT.md) - JavaScript in templates
- [SECURITY.md](SECURITY.md) - Security best practices
- [VARIABLES.md](VARIABLES.md) - Working with variables
