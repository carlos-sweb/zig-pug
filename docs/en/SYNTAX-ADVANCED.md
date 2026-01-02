# Advanced Pug Syntax

Advanced features and patterns for power users.

## Table of Contents

- [Mixins](#mixins)
- [Template Inheritance](#template-inheritance)
- [Includes](#includes)
- [Case Statements](#case-statements)
- [Advanced Interpolation](#advanced-interpolation)
- [Complex Attributes](#complex-attributes)
- [Inline Conditionals](#inline-conditionals)
- [Best Practices](#best-practices)

## Mixins

Mixins are reusable template components.

### Basic Mixins

**Definition:**
```pug
mixin greeting(name)
  p Hello, #{name}!
```

**Usage:**
```pug
+greeting("World")
+greeting("Alice")
```

**Output:**
```html
<p>Hello, World!</p>
<p>Hello, Alice!</p>
```

### Multiple Parameters

```pug
mixin button(text, type, size)
  button(class="btn btn-" + type + " btn-" + size)= text

+button("Submit", "primary", "lg")
+button("Cancel", "secondary", "sm")
```

**Output:**
```html
<button class="btn btn-primary btn-lg">Submit</button>
<button class="btn btn-secondary btn-sm">Cancel</button>
```

### Default Parameters

```pug
mixin link(text, url)
  - url = url || "#"
  a(href=url)= text

+link("Home", "/")
+link("Placeholder")
```

**Output:**
```html
<a href="/">Home</a>
<a href="#">Placeholder</a>
```

### Nested Content

```pug
mixin card(title)
  .card
    .card-header
      h3= title
    .card-body
      block

+card("User Info")
  p Name: Alice
  p Age: 30
```

**Output:**
```html
<div class="card">
  <div class="card-header">
    <h3>User Info</h3>
  </div>
  <div class="card-body">
    <p>Name: Alice</p>
    <p>Age: 30</p>
  </div>
</div>
```

### Mixin Library Pattern

```pug
//- components.zpug
mixin icon(name)
  i(class="icon icon-" + name)

mixin badge(text, type)
  span(class="badge badge-" + type)= text

mixin alert(message, level)
  .alert(class="alert-" + level)
    +icon(level)
    span= message

//- main.zpug
include components.zpug

+icon("home")
+badge("New", "success")
+alert("Warning!", "warning")
```

## Template Inheritance

Build layouts with `extends` and `block`.

### Base Layout

**layouts/base.zpug:**
```pug
doctype html
html
  head
    meta(charset="UTF-8")
    title
      block title
        | Default Title
    block styles
      link(rel="stylesheet" href="/css/main.css")
  body
    header
      block header
        h1 My Website

    nav
      block navigation
        ul
          li
            a(href="/") Home

    main
      block content
        p Default content

    footer
      block footer
        p © 2025
```

### Page Extending Layout

**pages/home.zpug:**
```pug
extends ../layouts/base.zpug

block title
  | Home Page

block content
  section.hero
    h2 Welcome!
    p This is the home page

block append styles
  link(rel="stylesheet" href="/css/home.css")
```

**Output:**
```html
<!DOCTYPE html>
<html>
  <head>
    <meta charset="UTF-8">
    <title>Home Page</title>
    <link rel="stylesheet" href="/css/main.css">
    <link rel="stylesheet" href="/css/home.css">
  </head>
  <body>
    <header>
      <h1>My Website</h1>
    </header>
    <nav>
      <ul>
        <li><a href="/">Home</a></li>
      </ul>
    </nav>
    <main>
      <section class="hero">
        <h2>Welcome!</h2>
        <p>This is the home page</p>
      </section>
    </main>
    <footer>
      <p>© 2025</p>
    </footer>
  </body>
</html>
```

### Block Modes

**Replace (default):**
```pug
block content
  p New content
```

**Append:**
```pug
block append scripts
  script(src="/js/page-specific.js")
```

**Prepend:**
```pug
block prepend styles
  link(rel="stylesheet" href="/css/urgent.css")
```

### Multi-level Inheritance

**layouts/base.zpug:**
```pug
doctype html
html
  body
    block content
```

**layouts/with-sidebar.zpug:**
```pug
extends base.zpug

block content
  .container
    aside
      block sidebar
        p Default sidebar
    main
      block main-content
```

**pages/article.zpug:**
```pug
extends ../layouts/with-sidebar.zpug

block sidebar
  ul
    li Recent Posts

block main-content
  article
    h1 Article Title
    p Article content
```

## Includes

### Basic Includes

**partials/header.zpug:**
```pug
header
  h1 Site Title
  nav
    a(href="/") Home
    a(href="/about") About
```

**index.zpug:**
```pug
doctype html
html
  body
    include partials/header.zpug
    main
      p Content
```

### Including Plain Text

**footer.txt:**
```
Copyright 2025. All rights reserved.
```

**index.zpug:**
```pug
footer
  p
    include footer.txt
```

### Dynamic Includes

```pug
- var section = "hero"
include components/#{section}.zpug
```

## Case Statements

Pattern matching for multiple conditions.

### Basic Case

```pug
- var status = "active"
case status
  when "active"
    p.status-active Active
  when "pending"
    p.status-pending Pending
  when "inactive"
    p.status-inactive Inactive
  default
    p.status-unknown Unknown
```

### Multiple Values

```pug
- var role = "moderator"
case role
  when "admin"
  when "moderator"
    p Has administrative access
  when "user"
    p Standard user
  default
    p Guest
```

### Complex Expressions

```pug
- var score = 85
case true
  when score > 90
    p Grade A
  when score > 80
    p Grade B
  when score > 70
    p Grade C
  default
    p Grade F
```

## Advanced Interpolation

### Expression Chaining

```pug
- var user = {profile: {name: "Alice", email: "alice@example.com"}}
p #{user.profile.name.toUpperCase()}
p #{user.profile.email.split('@')[0]}
```

### Array Methods

```pug
- var numbers = [1, 2, 3, 4, 5]
p Sum: #{numbers.reduce(function(a, b) { return a + b; }, 0)}
p Double: #{numbers.map(function(x) { return x * 2; }).join(', ')}
```

### Ternary Nesting

```pug
- var age = 30
- var status = "active"
p #{age >= 18 ? (status == "active" ? "Adult Active" : "Adult Inactive") : "Minor"}
```

### Function Calls

```pug
- function formatPrice(price) { return "$" + price.toFixed(2); }
p Price: #{formatPrice(19.99)}
```

## Complex Attributes

### Computed Attribute Names

```pug
- var attr = "data-role"
div(#{attr}="admin")
```

**Output:**
```html
<div data-role="admin"></div>
```

### Conditional Attributes

```pug
- var isActive = true
- var role = "admin"
div(
  class=isActive ? "active" : "inactive"
  data-role=role
  data-special=isActive ? "yes" : null
)
```

### Object Spread Pattern

```pug
- var attrs = {id: "main", class: "container", "data-role": "primary"}
div&attributes(attrs)
```

### Dynamic Classes

```pug
- var classes = ["box", "highlight", "active"]
div(class=classes.join(' '))
```

**Output:**
```html
<div class="box highlight active"></div>
```

## Inline Conditionals

### Ternary in Text

```pug
p Status: #{isActive ? "Active" : "Inactive"}
```

### Conditional Classes

```pug
div(class=isPremium ? "premium-user" : "regular-user")
```

### Conditional Attributes

```pug
a(
  href="/"
  target=external ? "_blank" : null
  rel=external ? "noopener" : null
) Link
```

## Best Practices

### 1. Organize Mixins

**Good:**
```
templates/
├── mixins/
│   ├── buttons.zpug
│   ├── forms.zpug
│   └── cards.zpug
├── layouts/
│   ├── base.zpug
│   └── admin.zpug
└── pages/
    ├── home.zpug
    └── about.zpug
```

### 2. Reusable Layouts

**Good:**
```pug
// layouts/base.zpug
doctype html
html
  head
    block head
      title
        block title
      block styles
  body
    block body
      block content
```

### 3. Component Pattern

**components/card.zpug:**
```pug
mixin card(title, variant)
  - variant = variant || "default"
  .card(class="card-" + variant)
    if title
      .card-header
        h3= title
    .card-body
      block
```

**Usage:**
```pug
include components/card.zpug

+card("User Profile", "primary")
  p Name: Alice
  p Role: Admin
```

### 4. Data-Driven Templates

**Good:**
```pug
- var menuItems = [{text: "Home", url: "/"}, {text: "About", url: "/about"}]
nav
  ul
    each item in menuItems
      li
        a(href=item.url)= item.text
```

### 5. Conditional Rendering

**Good:**
```pug
- var sections = {hero: true, features: true, pricing: false}

if sections.hero
  include sections/hero.zpug

if sections.features
  include sections/features.zpug

if sections.pricing
  include sections/pricing.zpug
```

### 6. Documentation

**Good:**
```pug
//! Component: User Card
//! Author: John Doe
//! Description: Displays user information with avatar and stats
//! Params:
//!   - user: {name, avatar, stats}
//!   - variant: "compact" | "expanded"

mixin userCard(user, variant)
  .user-card(class="user-card-" + variant)
    img.avatar(src=user.avatar)
    .info
      h4= user.name
      .stats
        each stat in user.stats
          span= stat
```

### 7. Error Prevention

**Good:**
```pug
mixin link(text, url)
  - if (!text) throw new Error("Link text is required")
  - url = url || "#"
  a(href=url)= text
```

### 8. Performance

**Good (cache expensive operations):**
```pug
- var sortedUsers = users.sort(function(a, b) { return a.name.localeCompare(b.name); })
each user in sortedUsers
  p= user.name
```

**Bad (sorts on every iteration):**
```pug
each user in users.sort(...)
  p= user.name
```

## Advanced Patterns

### Factory Pattern

```pug
mixin icon(name, size)
  - size = size || "md"
  case size
    when "sm"
      i.icon.icon-sm(class="icon-" + name)
    when "md"
      i.icon.icon-md(class="icon-" + name)
    when "lg"
      i.icon.icon-lg(class="icon-" + name)
```

### Builder Pattern

```pug
mixin form
  form(class=formClass)
    block

mixin formInput(name, type, label)
  .form-group
    if label
      label(for=name)= label
    input(type=type name=name id=name)

mixin formSubmit(text)
  button(type="submit")= text

- var formClass = "contact-form"
+form
  +formInput("email", "email", "Email")
  +formInput("message", "textarea", "Message")
  +formSubmit("Send")
```

### Composition Pattern

```pug
mixin page
  block

mixin section(title)
  section
    if title
      h2= title
    block

mixin container
  .container
    block

+page
  +container
    +section("Welcome")
      p Content here
```

## See Also

- [SYNTAX-BASICS.md](SYNTAX-BASICS.md) - Basic syntax
- [VARIABLES.md](VARIABLES.md) - Working with variables
- [CONDITIONALS-LOOPS.md](CONDITIONALS-LOOPS.md) - Logic in templates
- [../PUG-SYNTAX.md](../PUG-SYNTAX.md) - Complete syntax reference
