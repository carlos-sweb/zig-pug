# Conditionals and Loops

Complete guide to control flow in zig-pug templates.

## Table of Contents

- [Conditionals](#conditionals)
- [Loops](#loops)
- [Case Statements](#case-statements)
- [Common Patterns](#common-patterns)
- [Best Practices](#best-practices)

## Conditionals

### Basic If/Else

**Syntax:**
```pug
if condition
  // content when true
else
  // content when false
```

**Example:**
```pug
- var isLoggedIn = true

if isLoggedIn
  p Welcome back!
  a(href="/logout") Logout
else
  p Please log in
  a(href="/login") Login
```

**Output (when isLoggedIn = true):**
```html
<p>Welcome back!</p>
<a href="/logout">Logout</a>
```

### Else If

**Syntax:**
```pug
if condition1
  // content for condition1
else if condition2
  // content for condition2
else if condition3
  // content for condition3
else
  // default content
```

**Example:**
```pug
- var score = 85

if score > 90
  p Grade: A
  p.badge.badge-success Excellent!
else if score > 80
  p Grade: B
  p.badge.badge-info Good job!
else if score > 70
  p Grade: C
  p.badge.badge-warning Passing
else
  p Grade: F
  p.badge.badge-danger Failed
```

**Unlimited Chaining:**
```pug
if role == "admin"
  p Full access
else if role == "moderator"
  p Moderate access
else if role == "editor"
  p Edit access
else if role == "viewer"
  p View only
else
  p No access
```

### Unless (Negation)

`unless` is the opposite of `if`:

```pug
- var isAdmin = false

unless isAdmin
  p Access denied
```

Equivalent to:
```pug
if !isAdmin
  p Access denied
```

### Comparison Operators

**Supported:** `>`, `<`, `>=`, `<=`, `==`

```pug
- var age = 30

if age > 18
  p Adult

if age >= 18
  p Adult or exactly 18

if age < 18
  p Minor

if age <= 18
  p Minor or exactly 18

if age == 30
  p Exactly 30
```

### Logical Operators

**AND (`&&`):**
```pug
- var age = 30
- var hasLicense = true

if age >= 18 && hasLicense
  p Can drive
else
  p Cannot drive
```

**OR (`||`):**
```pug
- var isAdmin = false
- var isModerator = true

if isAdmin || isModerator
  p Has moderator privileges
else
  p Regular user
```

**Complex Expressions:**
```pug
- var age = 30
- var hasLicense = true
- var hasInsurance = true

if age >= 18 && hasLicense && hasInsurance
  p Fully qualified to drive
else if age >= 18 && hasLicense
  p Can drive but needs insurance
else
  p Cannot drive
```

### Property Access

```pug
- var user = {isPremium: true, isActive: true}

if user.isPremium
  p Premium features enabled
  .premium-badge Premium

if user.isActive
  p Account is active
```

### Nested Conditionals

```pug
- var user = {role: "admin", isActive: true}

if user.role == "admin"
  if user.isActive
    p Active admin - full access
  else
    p Inactive admin - limited access
else
  if user.isActive
    p Active user
  else
    p Inactive user
```

## Loops

### Each (Arrays)

**Basic Syntax:**
```pug
each item in array
  // process item
```

**Example:**
```pug
- var fruits = ["apple", "banana", "orange"]

ul
  each fruit in fruits
    li= fruit
```

**Output:**
```html
<ul>
  <li>apple</li>
  <li>banana</li>
  <li>orange</li>
</ul>
```

### Each with Index

**Syntax:**
```pug
each item, index in array
  // process item and index
```

**Example:**
```pug
- var items = ["First", "Second", "Third"]

ol
  each item, i in items
    li #{i + 1}. #{item}
```

**Output:**
```html
<ol>
  <li>1. First</li>
  <li>2. Second</li>
  <li>3. Third</li>
</ol>
```

### Each with Objects

```pug
- var users = [
-   {name: "Alice", age: 30, role: "admin"},
-   {name: "Bob", age: 25, role: "user"},
-   {name: "Charlie", age: 35, role: "moderator"}
- ]

table
  tr
    th Name
    th Age
    th Role
  each user in users
    tr
      td= user.name
      td= user.age
      td= user.role
```

**Output:**
```html
<table>
  <tr>
    <th>Name</th>
    <th>Age</th>
    <th>Role</th>
  </tr>
  <tr>
    <td>Alice</td>
    <td>30</td>
    <td>admin</td>
  </tr>
  <tr>
    <td>Bob</td>
    <td>25</td>
    <td>user</td>
  </tr>
  <tr>
    <td>Charlie</td>
    <td>35</td>
    <td>moderator</td>
  </tr>
</table>
```

### Empty Array Handling

```pug
- var items = []

ul
  each item in items
    li= item
  else
    li No items found
```

**Output (when empty):**
```html
<ul>
  <li>No items found</li>
</ul>
```

### While Loops

**Syntax:**
```pug
while condition
  // loop body
  // update condition
```

**Example:**
```pug
- var count = 0

ul
  while count < 5
    li Count: #{count}
    - count++
```

**Output:**
```html
<ul>
  <li>Count: 0</li>
  <li>Count: 1</li>
  <li>Count: 2</li>
  <li>Count: 3</li>
  <li>Count: 4</li>
</ul>
```

**⚠️ Warning:** Ensure while loops terminate to avoid infinite loops!

### Nested Loops

```pug
- var categories = [
-   {name: "Fruits", items: ["Apple", "Banana"]},
-   {name: "Vegetables", items: ["Carrot", "Lettuce"]}
- ]

each category in categories
  .category
    h3= category.name
    ul
      each item in category.items
        li= item
```

**Output:**
```html
<div class="category">
  <h3>Fruits</h3>
  <ul>
    <li>Apple</li>
    <li>Banana</li>
  </ul>
</div>
<div class="category">
  <h3>Vegetables</h3>
  <ul>
    <li>Carrot</li>
    <li>Lettuce</li>
  </ul>
</div>
```

## Case Statements

Pattern matching for multiple conditions.

### Basic Case

**Syntax:**
```pug
case expression
  when value1
    // content
  when value2
    // content
  default
    // default content
```

**Example:**
```pug
- var day = "Monday"

case day
  when "Monday"
    p Start of the week
  when "Friday"
    p End of the week
  when "Saturday"
  when "Sunday"
    p Weekend!
  default
    p Midweek
```

### Case with Expressions

```pug
- var status = "active"

case status
  when "active"
    .badge.badge-success Active
  when "pending"
    .badge.badge-warning Pending
  when "inactive"
    .badge.badge-danger Inactive
  default
    .badge.badge-secondary Unknown
```

### Case with true (Complex Conditions)

```pug
- var score = 85

case true
  when score > 90
    p Grade A
  when score > 80
    p Grade B
  when score > 70
    p Grade C
  when score > 60
    p Grade D
  default
    p Grade F
```

## Common Patterns

### Authentication State

```pug
if user && user.isLoggedIn
  nav.user-nav
    span Welcome, #{user.name}!
    a(href="/profile") Profile
    a(href="/settings") Settings
    a(href="/logout") Logout
else
  nav.guest-nav
    a(href="/login") Login
    a(href="/signup") Sign Up
```

### Permissions

```pug
- var permissions = {canEdit: true, canDelete: false, canPublish: true}

.actions
  if permissions.canEdit
    button.btn.btn-primary Edit

  if permissions.canDelete
    button.btn.btn-danger Delete

  if permissions.canPublish
    button.btn.btn-success Publish
```

### Feature Flags

```pug
- var features = {darkMode: true, notifications: false, beta: true}

.settings
  if features.darkMode
    .setting
      label Dark Mode
      input(type="checkbox" checked)

  if features.notifications
    .setting
      label Notifications
      input(type="checkbox" checked)

  if features.beta
    .setting
      .badge.badge-warning Beta
```

### Pagination

```pug
- var currentPage = 3
- var totalPages = 10

.pagination
  if currentPage > 1
    a.page-link(href=`/page/${currentPage - 1}`) Previous

  - var page = 1
  while page <= totalPages
    if page == currentPage
      span.page-link.active= page
    else
      a.page-link(href=`/page/${page}`)= page
    - page++

  if currentPage < totalPages
    a.page-link(href=`/page/${currentPage + 1}`) Next
```

### Dynamic Classes

```pug
- var items = [
-   {name: "Item 1", active: true, featured: false},
-   {name: "Item 2", active: false, featured: true},
-   {name: "Item 3", active: true, featured: true}
- ]

each item in items
  - var classes = []
  - if (item.active) classes.push('active')
  - if (item.featured) classes.push('featured')
  div(class=classes.join(' '))= item.name
```

### Conditional Attributes

```pug
- var isExternal = true
- var openInNewTab = true

a(
  href="https://example.com"
  target=openInNewTab ? "_blank" : null
  rel=isExternal ? "noopener noreferrer" : null
) Link
```

### Status Indicators

```pug
- var orders = [
-   {id: 1, status: "pending"},
-   {id: 2, status: "shipped"},
-   {id: 3, status: "delivered"}
- ]

each order in orders
  .order
    p Order ##{order.id}
    case order.status
      when "pending"
        .status.status-pending ⏳ Pending
      when "shipped"
        .status.status-shipped 🚚 Shipped
      when "delivered"
        .status.status-delivered ✅ Delivered
      default
        .status.status-unknown ❓ Unknown
```

## Best Practices

### 1. Keep Conditionals Simple

**❌ Bad:**
```pug
if (user && user.profile && user.profile.settings && user.profile.settings.theme == "dark" && user.isPremium && user.isActive)
  p Dark mode premium user
```

**✅ Good:**
```pug
- var isDarkModePremium = user && user.profile && user.profile.settings && user.profile.settings.theme == "dark" && user.isPremium && user.isActive

if isDarkModePremium
  p Dark mode premium user
```

### 2. Use else if Instead of Nested ifs

**❌ Bad:**
```pug
if role == "admin"
  p Admin
else
  if role == "moderator"
    p Moderator
  else
    if role == "user"
      p User
```

**✅ Good:**
```pug
if role == "admin"
  p Admin
else if role == "moderator"
  p Moderator
else if role == "user"
  p User
else
  p Guest
```

### 3. Provide else Clauses

**❌ Bad:**
```pug
if items.length > 0
  each item in items
    p= item
// Nothing shown when empty!
```

**✅ Good:**
```pug
if items.length > 0
  each item in items
    p= item
else
  p No items found
```

### 4. Validate Arrays Before Looping

**❌ Bad:**
```pug
each item in items  // Error if items is undefined!
  p= item
```

**✅ Good:**
```pug
- items = items || []
each item in items
  p= item
else
  p No items
```

### 5. Use case for Multiple Conditions

**❌ Bad:**
```pug
if status == "draft"
  p Draft
else if status == "review"
  p Review
else if status == "published"
  p Published
else if status == "archived"
  p Archived
```

**✅ Good:**
```pug
case status
  when "draft"
    p Draft
  when "review"
    p Review
  when "published"
    p Published
  when "archived"
    p Archived
  default
    p Unknown
```

### 6. Extract Complex Conditions

**❌ Bad:**
```pug
if age >= 18 && hasLicense && hasInsurance && violations < 3 && experience > 1
  p Can rent car
```

**✅ Good:**
```pug
- var meetsAgeRequirement = age >= 18
- var hasProperDocuments = hasLicense && hasInsurance
- var hasGoodRecord = violations < 3
- var hasExperience = experience > 1
- var canRentCar = meetsAgeRequirement && hasProperDocuments && hasGoodRecord && hasExperience

if canRentCar
  p Can rent car
```

### 7. Avoid Deep Nesting

**❌ Bad:**
```pug
if user
  if user.profile
    if user.profile.settings
      if user.profile.settings.notifications
        if user.profile.settings.notifications.email
          p Email notifications enabled
```

**✅ Good:**
```pug
- var emailNotifications = user && user.profile && user.profile.settings && user.profile.settings.notifications && user.profile.settings.notifications.email

if emailNotifications
  p Email notifications enabled
```

### 8. Document Complex Logic

```pug
//! Pricing logic:
//! - Premium users get 20% discount
//! - Orders over $100 get free shipping
//! - First-time buyers get $10 off

- var discount = user.isPremium ? 0.20 : 0
- var freeShipping = total > 100
- var firstTimeBonus = user.isFirstTime ? 10 : 0
```

## Troubleshooting

### Infinite While Loop

**Problem:**
```pug
- var count = 0
while count < 10
  p #{count}
  // Forgot to increment count!
```

**Solution:**
```pug
- var count = 0
while count < 10
  p #{count}
  - count++  // Always update condition variable!
```

### Undefined in Conditionals

**Problem:**
```pug
if user.profile.email  // Error if user.profile is undefined
  p= user.profile.email
```

**Solution:**
```pug
if user && user.profile && user.profile.email
  p= user.profile.email
```

### Loop Variable Conflicts

**Problem:**
```pug
- var item = "global"

each item in items  // Shadows global 'item'
  p= item

p= item  // Still shadowed!
```

**Solution:**
Use unique loop variable names:
```pug
each listItem in items
  p= listItem
```

## See Also

- [VARIABLES.md](VARIABLES.md) - Working with variables
- [JAVASCRIPT.md](JAVASCRIPT.md) - JavaScript expressions
- [SYNTAX-ADVANCED.md](SYNTAX-ADVANCED.md) - Advanced syntax
- [../PUG-SYNTAX.md](../PUG-SYNTAX.md) - Complete syntax reference
