# Example 03: Conditionals

**Difficulty:** ⭐⭐ Medium
**Category:** Control
**Time:** 7 minutes

## 📝 What You'll Learn

- Simple if/else statements
- else if chains
- unless (negation)
- Combining conditionals with expressions
- Role-based rendering

## 📄 Source Code

**File:** `examples/03-conditionals.zpug`

```zpug
// Ejemplo 3: Condicionales
// Muestra if/else/unless para lógica condicional

div.status
  h2 Estado del Usuario

  // Condicional simple
  if isLoggedIn
    p.success ✓ Sesión iniciada
  else
    p.warning Debe iniciar sesión

  // Condicional con expresión
  if age >= 18
    p.info Puede votar
  else if age >= 16
    p.info Casi puede votar
  else
    p.info Muy joven para votar

  // Unless (negación)
  unless hasPermission
    p.error ⚠ Acceso denegado

  // Combinando con variables
  if role === 'admin'
    button.btn-danger Panel de Administración
  else if role === 'user'
    button.btn-primary Panel de Usuario
  else
    button.btn-secondary Ver Perfil
```

## 🎯 Key Concepts

### 1. Simple If/Else

```zpug
if isLoggedIn
  p.success ✓ Sesión iniciada
else
  p.warning Debe iniciar sesión
```

**When `isLoggedIn = true`:**
```html
<p class="success">✓ Sesión iniciada</p>
```

**When `isLoggedIn = false`:**
```html
<p class="warning">Debe iniciar sesión</p>
```

**Syntax:** Standard if/else block structure.

---

### 2. Else If Chains

```zpug
if age >= 18
  p.info Puede votar
else if age >= 16
  p.info Casi puede votar
else
  p.info Muy joven para votar
```

**With `age = 17`:**
```html
<p class="info">Casi puede votar</p>
```

**Usage:** Chain multiple conditions to handle different cases.

---

### 3. Unless (Negation)

```zpug
unless hasPermission
  p.error ⚠ Acceso denegado
```

**Equivalent to:**
```zpug
if !hasPermission
  p.error ⚠ Acceso denegado
```

**When `hasPermission = false`:**
```html
<p class="error">⚠ Acceso denegado</p>
```

**Note:** `unless` is syntactic sugar for `if not`. Use it when negation reads more naturally.

---

### 4. String Comparison

```zpug
if role === 'admin'
  button.btn-danger Panel de Administración
else if role === 'user'
  button.btn-primary Panel de Usuario
else
  button.btn-secondary Ver Perfil
```

**With `role = 'admin'`:**
```html
<button class="btn-danger">Panel de Administración</button>
```

**Tip:** You can use any JavaScript comparison operators: `===`, `!==`, `>`, `<`, `>=`, `<=`

---

### 5. Complex Expressions

```zpug
if user.isPremium && user.age >= 18
  div.premium-content
    p Contenido exclusivo premium
else if user.isLoggedIn
  div.standard-content
    p Contenido estándar
else
  div.public-content
    p Contenido público
```

**Usage:** Combine conditions with `&&` (and) and `||` (or).

---

## 🖥️ Run This Example

```bash
# Compile to stdout
zpug examples/03-conditionals.zpug

# Pretty print
zpug -p examples/03-conditionals.zpug

# Compile to file
zpug examples/03-conditionals.zpug -o output.html
```

**Note:** Pass different variable values to see different conditional branches render.

## 📤 Expected Output

**With:** `isLoggedIn = true`, `age = 20`, `hasPermission = true`, `role = 'admin'`

```html
<div class="status"><h2>Estado del Usuario</h2><p class="success">✓ Sesión iniciada</p><p class="info">Puede votar</p><button class="btn-danger">Panel de Administración</button></div>
```

## ✅ Exercise

Create a status dashboard with conditionals:

```zpug
div.dashboard
  if user.isOnline
    span.status.online ● Online
  else
    span.status.offline ● Offline

  if user.notifications > 0
    div.notification-badge #{user.notifications}

  unless user.hasCompletedProfile
    div.alert
      p Please complete your profile

  if user.accountType === 'premium'
    div.premium-features
      p Access to all features
  else if user.accountType === 'basic'
    div.basic-features
      p Limited features
      a(href="/upgrade") Upgrade Now
```

## 🔗 What's Next?

**Next Example:** [04-mixins.md](04-mixins.md) - Learn reusable components

**Previous Example:** [loops.md](loops.md) - Loops and Iteration

**Learning Path:** [INDEX.md](INDEX.md)
