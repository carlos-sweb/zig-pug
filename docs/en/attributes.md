# Attributes

Complete guide to HTML attribute handling in zig-pug.

## Table of Contents

- [Basic Attributes](#basic-attributes)
- [Dynamic Attributes](#dynamic-attributes)
- [Boolean Attributes](#boolean-attributes)
- [Data Attributes](#data-attributes)
- [Attribute Expressions](#attribute-expressions)
- [Special Cases](#special-cases)

## Basic Attributes

### Syntax

Attributes are specified in parentheses after the tag name:

```pug
tag(attribute="value")
```

### Simple Attributes

```pug
a(href="/home") Link
img(src="logo.png" alt="Logo")
input(type="email" name="email")
```

**Output:**
```html
<a href="/home">Link</a>
<img src="logo.png" alt="Logo">
<input type="email" name="email">
```

### Multiple Attributes

Separate attributes with spaces:

```pug
a(href="/" class="link" target="_blank" rel="noopener") External
```

**Output:**
```html
<a href="/" class="link" target="_blank" rel="noopener">External</a>
```

### Multi-line Attributes

For better readability:

```pug
div(
  class="container"
  id="main"
  data-role="primary"
  data-status="active"
)
```

**Output:**
```html
<div class="container" id="main" data-role="primary" data-status="active"></div>
```

## Dynamic Attributes

### Expression Values

Use `=` to evaluate expressions:

```pug
- var myUrl = "/home"
- var myClass = "active"
- var isDisabled = false

a(href=myUrl class=myClass disabled=isDisabled) Link
```

**Output:**
```html
<a href="/home" class="active">Link</a>
```

### String Concatenation

```pug
- var userId = 123
- var alertType = "success"

div(id="user-" + userId)
div(class="alert alert-" + alertType)
```

**Output:**
```html
<div id="user-123"></div>
<div class="alert alert-success"></div>
```

### Object Access

```pug
- var user = {name: "Alice", role: "admin"}
- var config = {theme: "dark", lang: "en"}

div(data-name=user.name data-role=user.role)
html(lang=config.lang data-theme=config.theme)
```

**Output:**
```html
<div data-name="Alice" data-role="admin"></div>
<html lang="en" data-theme="dark"></html>
```

### Array Access

```pug
- var urls = ["/home", "/about", "/contact"]
- var images = ["banner.jpg", "logo.png"]

a(href=urls[0]) Home
img(src=images[0])
```

**Output:**
```html
<a href="/home">Home</a>
<img src="banner.jpg">
```

### Ternary Operators

```pug
- var isActive = true
- var isPremium = false

div(class=isActive ? "active" : "inactive")
div(data-tier=isPremium ? "premium" : "free")
```

**Output:**
```html
<div class="active"></div>
<div data-tier="free"></div>
```

## Boolean Attributes

### True Values

When an attribute evaluates to `true`, the attribute name is output without a value:

```pug
input(type="checkbox" checked)
input(type="text" required)
button(disabled) Click
```

**Output:**
```html
<input type="checkbox" checked>
<input type="text" required>
<button disabled>Click</button>
```

### Dynamic Boolean Attributes

```pug
- var isChecked = true
- var isRequired = false
- var isDisabled = true

input(type="checkbox" checked=isChecked)
input(type="text" required=isRequired)
button(disabled=isDisabled) Click
```

**Output:**
```html
<input type="checkbox" checked>
<input type="text">
<button disabled>Click</button>
```

**Note:** When `false`, the attribute is omitted entirely.

### Conditional Attributes

```pug
- var openInNewTab = true
- var isExternal = true

a(
  href="https://example.com"
  target=openInNewTab ? "_blank" : null
  rel=isExternal ? "noopener noreferrer" : null
) Link
```

**Output:**
```html
<a href="https://example.com" target="_blank" rel="noopener noreferrer">Link</a>
```

## Data Attributes

### Static Data Attributes

```pug
div(data-id="123" data-role="admin" data-status="active")
```

**Output:**
```html
<div data-id="123" data-role="admin" data-status="active"></div>
```

### Dynamic Data Attributes

```pug
- var userId = 456
- var userRole = "moderator"

div(data-user-id=userId data-user-role=userRole)
```

**Output:**
```html
<div data-user-id="456" data-user-role="moderator"></div>
```

### JSON in Data Attributes

```pug
- var config = {theme: "dark", lang: "en"}

div(data-config=JSON.stringify(config))
```

**Output:**
```html
<div data-config='{"theme":"dark","lang":"en"}'></div>
```

**Client-side access:**
```javascript
const div = document.querySelector('div');
const config = JSON.parse(div.dataset.config);
console.log(config.theme); // "dark"
```

## Attribute Expressions

### Complex Expressions

```pug
- var price = 99.99
- var discount = 0.1
- var quantity = 3

div(data-total=(price * (1 - discount) * quantity).toFixed(2))
```

**Output:**
```html
<div data-total="269.97"></div>
```

### Method Calls

```pug
- var text = "Hello World"

div(data-upper=text.toUpperCase())
div(data-lower=text.toLowerCase())
div(data-length=text.length)
```

**Output:**
```html
<div data-upper="HELLO WORLD"></div>
<div data-lower="hello world"></div>
<div data-length="11"></div>
```

### Logical Operations

```pug
- var age = 30
- var hasLicense = true

div(data-can-drive=age >= 18 && hasLicense)
```

**Output:**
```html
<div data-can-drive="true"></div>
```

## Special Cases

### Class Attribute

Multiple ways to set classes:

**Shorthand:**
```pug
div.container.fluid
```

**Attribute:**
```pug
div(class="container fluid")
```

**Dynamic:**
```pug
- var classes = "container fluid"
div(class=classes)
```

**Combined:**
```pug
div.box(class="active")
```

**Output:**
```html
<div class="box active"></div>
```

**Array of classes:**
```pug
- var classList = ["btn", "btn-primary", "btn-lg"]
button(class=classList.join(' ')) Click
```

**Output:**
```html
<button class="btn btn-primary btn-lg">Click</button>
```

### ID Attribute

**Shorthand:**
```pug
div#main
```

**Attribute:**
```pug
div(id="main")
```

**Dynamic:**
```pug
- var containerId = "main"
div(id=containerId)
```

**Combined:**
```pug
div#header(class="container")
```

**Output:**
```html
<div id="header" class="container"></div>
```

### ARIA Attributes

```pug
button(
  aria-label="Close"
  aria-pressed="false"
  role="button"
) ×
```

**Output:**
```html
<button aria-label="Close" aria-pressed="false" role="button">×</button>
```

**Dynamic:**
```pug
- var isExpanded = false
button(aria-expanded=isExpanded) Toggle
```

**Output:**
```html
<button aria-expanded="false">Toggle</button>
```

### Style Attribute

**Static:**
```pug
div(style="color: red; font-size: 16px")
```

**Dynamic:**
```pug
- var color = "blue"
- var fontSize = 18
div(style="color: " + color + "; font-size: " + fontSize + "px")
```

**Output:**
```html
<div style="color: blue; font-size: 18px"></div>
```

**Better approach (CSS classes):**
```pug
- var theme = "dark"
div(class="theme-" + theme)
```

### Event Handlers (Avoid)

**❌ Not recommended:**
```pug
button(onclick="alert('Clicked')") Click
```

**✅ Better (external JavaScript):**
```pug
button#myButton Click

script.
  document.getElementById('myButton').addEventListener('click', function() {
    alert('Clicked');
  });
```

## HTML Escaping

All attribute values are HTML-escaped automatically:

```pug
- var userInput = '"><script>alert("XSS")</script><a href="'
a(href=userInput) Link
```

**Output (safe):**
```html
<a href="&quot;&gt;&lt;script&gt;alert(&quot;XSS&quot;)&lt;/script&gt;&lt;a href=&quot;">Link</a>
```

**Escaped characters:**
- `&` → `&amp;`
- `<` → `&lt;`
- `>` → `&gt;`
- `"` → `&quot;`
- `'` → `&#39;`

## Best Practices

### 1. Use Semantic HTML

```pug
// ✅ Good
nav
  a(href="/") Home

// ❌ Bad
div(role="navigation")
  span(onclick="location.href='/'") Home
```

### 2. Prefer CSS Classes over Inline Styles

```pug
// ✅ Good
div.highlight

// ❌ Bad
div(style="background: yellow; padding: 10px")
```

### 3. Validate Inputs

```pug
- function isSafeUrl(url) {
-   return url && (url.startsWith('http://') || url.startsWith('https://') || url.startsWith('/'));
- }
- var userUrl = userProvidedUrl
- var safeUrl = isSafeUrl(userUrl) ? userUrl : '#'

a(href=safeUrl) Link
```

### 4. Use Data Attributes for JavaScript

```pug
button.submit(data-form-id="contact") Submit

script.
  document.querySelector('.submit').addEventListener('click', function(e) {
    const formId = e.target.dataset.formId;
    submitForm(formId);
  });
```

### 5. Keep Attribute Logic Simple

**❌ Bad:**
```pug
div(
  class=isActive ? (isPremium ? "active premium" : "active") : (isPremium ? "premium" : "")
  data-status=user.status == "active" ? "online" : (user.status == "away" ? "away" : "offline")
)
```

**✅ Good:**
```pug
- var classList = []
- if (isActive) classList.push("active")
- if (isPremium) classList.push("premium")

- var status = user.status == "active" ? "online" : (user.status == "away" ? "away" : "offline")

div(class=classList.join(' ') data-status=status)
```

### 6. Use Meaningful Attribute Names

```pug
// ✅ Good
div(data-user-id=userId data-user-role=userRole)

// ❌ Bad
div(data-id=userId data-r=userRole)
```

## Common Patterns

### Conditional CSS Classes

```pug
- var status = "success"
- var baseClass = "alert"
- var statusClass = "alert-" + status

div(class=baseClass + " " + statusClass) Message
```

**Output:**
```html
<div class="alert alert-success">Message</div>
```

### Links with Multiple Conditions

```pug
- var isExternal = true
- var openInNewTab = true

a(
  href="https://example.com"
  class=isExternal ? "external-link" : "internal-link"
  target=openInNewTab ? "_blank" : "_self"
  rel=isExternal ? "noopener noreferrer" : null
) Link
```

### Form Inputs with Validation

```pug
- var email = user.email || ""
- var isRequired = true
- var hasError = emailError != null

input(
  type="email"
  name="email"
  value=email
  required=isRequired
  class=hasError ? "form-control is-invalid" : "form-control"
  aria-invalid=hasError
  aria-describedby=hasError ? "email-error" : null
)
```

### Image with Fallback

```pug
- var avatarUrl = user.avatar || "/images/default-avatar.png"
- var userName = user.name || "User"

img(
  src=avatarUrl
  alt="Avatar of " + userName
  loading="lazy"
)
```

## See Also

- [interpolation.md](interpolation.md) - Text interpolation
- [SYNTAX-BASICS.md](SYNTAX-BASICS.md) - Basic syntax
- [SYNTAX-ADVANCED.md](SYNTAX-ADVANCED.md) - Advanced features
- [SECURITY.md](SECURITY.md) - Security best practices
