# Conditionals in Pug

Complete guide to conditional statements and case expressions in zig-pug.

---

## Conditionals

### If Statement

```pug
//- Variable: isLoggedIn = true
if isLoggedIn
  p Welcome back!
```

Output (when true):
```html
<p>Welcome back!</p>
```

### If-Else

```pug
//- Variable: hasPermission = false
if hasPermission
  button Edit
else
  button View Only
```

Output:
```html
<button>View Only</button>
```

### If-Else If-Else

```pug
//- Variable: role = "admin"
if role === "admin"
  p Admin Panel
else if role === "moderator"
  p Moderator Tools
else
  p User Dashboard
```

Output:
```html
<p>Admin Panel</p>
```

### Unless

```pug
//- Variable: isDisabled = false
unless isDisabled
  button Click Me
```

Output:
```html
<button>Click Me</button>
```

---

## Case Statements

Case statements provide a cleaner alternative to multiple if-else conditions when checking a single value against multiple possibilities.

### Basic Case

```pug
//- Variable: status = "success"
case status
  when "success"
    p.success Operation completed successfully
  when "error"
    p.error Something went wrong
  when "pending"
    p.warning Please wait...
  default
    p.info Unknown status
```

Output:
```html
<p class="success">Operation completed successfully</p>
```

### Case with Multiple Values

You can match multiple values in a single `when` clause:

```pug
//- Variable: day = "Saturday"
case day
  when "Monday"
  when "Tuesday"
  when "Wednesday"
  when "Thursday"
  when "Friday"
    p It's a weekday
  when "Saturday"
  when "Sunday"
    p It's the weekend!
  default
    p Invalid day
```

Output:
```html
<p>It's the weekend!</p>
```

### Case with Object Properties

Access object properties in case expressions:

```pug
//- Variable: user = {role: "admin", status: "active"}
case user.role
  when "admin"
    p Administrator Panel
  when "moderator"
    p Moderator Tools
  when "user"
    p User Dashboard
  default
    p Guest View
```

Output:
```html
<p>Administrator Panel</p>
```

### Case with Nested Properties

```pug
//- Variable: response = {data: {status: "ok", code: 200}}
case response.data.status
  when "ok"
    p.success Request successful
  when "error"
    p.error Request failed
  default
    p.warning Unknown response
```

Output:
```html
<p class="success">Request successful</p>
```

### Case with Expressions

```pug
//- Variables: score = 85
case true
  when score >= 90
    p Grade: A
  when score >= 80
    p Grade: B
  when score >= 70
    p Grade: C
  default
    p Grade: F
```

Output:
```html
<p>Grade: B</p>
```

### Case with Complex Blocks

```pug
//- Variable: userType = "premium"
case userType
  when "premium"
    div.premium-box
      h2 Premium Features
      ul
        li No ads
        li Priority support
        li Advanced tools
  when "basic"
    div.basic-box
      h2 Basic Features
      p Standard access
  default
    div.guest-box
      p Please log in
```

Output:
```html
<div class="premium-box">
  <h2>Premium Features</h2>
  <ul>
    <li>No ads</li>
    <li>Priority support</li>
    <li>Advanced tools</li>
  </ul>
</div>
```

### Case with String Values

```pug
//- Variable: color = "blue"
case color
  when "red"
    div.bg-red Red background
  when "blue"
    div.bg-blue Blue background
  when "green"
    div.bg-green Green background
  default
    div.bg-default Default background
```

Output:
```html
<div class="bg-blue">Blue background</div>
```

---

## See Also

- [PUG-SYNTAX.md](../PUG-SYNTAX.md) - Complete Pug syntax reference
- [CONDITIONALS-LOOPS.md](CONDITIONALS-LOOPS.md) - Control flow guide
- [VARIABLES.md](VARIABLES.md) - Working with variables
- [SYNTAX-BASICS.md](SYNTAX-BASICS.md) - Basic syntax guide
