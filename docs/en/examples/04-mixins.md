# Example 04: Mixins (Reusable Components)

**Difficulty:** ⭐⭐ Medium
**Category:** Composición
**Time:** 10 minutes

## 📝 What You'll Learn

- Defining mixins with parameters
- Calling mixins with `+`
- Multiple parameter mixins
- Building reusable UI components
- Dynamic class generation in mixins

## 📄 Source Code

**File:** `examples/04-mixins.pug`

```zpug
// Ejemplo 4: Mixins (Componentes Reutilizables)
// Los mixins permiten crear componentes que puedes reusar

// Definir un mixin simple
mixin button(text)
  button.btn= text

// Mixin con múltiples parámetros
mixin card(title, description)
  div.card
    h3.card-title= title
    p.card-description= description

// Mixin para alertas
mixin alert(type, message)
  div(class="alert alert-" + type)
    p= message

// Usar los mixins
div.page
  h1 Ejemplos de Mixins

  div.buttons
    +button('Guardar')
    +button('Cancelar')
    +button('Eliminar')

  div.cards
    +card('Bienvenida', 'Gracias por usar zig-pug')
    +card('Características', 'Soporta toda la sintaxis de Pug')
    +card('Rendimiento', 'Compilación ultra-rápida')

  div.alerts
    +alert('success', 'Operación exitosa')
    +alert('warning', 'Ten cuidado')
    +alert('error', 'Algo salió mal')
```

## 🎯 Key Concepts

### 1. Defining a Simple Mixin

```zpug
mixin button(text)
  button.btn= text
```

**Usage:**
```zpug
+button('Save')
```

**Generates:**
```html
<button class="btn">Save</button>
```

**Syntax:**
- Define: `mixin name(parameters)`
- Call: `+name(arguments)`

---

### 2. Multiple Parameters

```zpug
mixin card(title, description)
  div.card
    h3.card-title= title
    p.card-description= description
```

**Usage:**
```zpug
+card('Welcome', 'Thanks for using zig-pug')
```

**Generates:**
```html
<div class="card">
  <h3 class="card-title">Welcome</h3>
  <p class="card-description">Thanks for using zig-pug</p>
</div>
```

**Note:** Pass arguments in the same order as parameters.

---

### 3. Dynamic Class Names

```zpug
mixin alert(type, message)
  div(class="alert alert-" + type)
    p= message
```

**Usage:**
```zpug
+alert('success', 'Operation successful')
```

**Generates:**
```html
<div class="alert alert-success">
  <p>Operation successful</p>
</div>
```

**Tip:** Concatenate strings to build dynamic attributes.

---

### 4. Mixin with Default Values

```zpug
mixin icon(name, size = 'medium')
  svg(class="icon icon-" + size)
    use(href="#icon-" + name)
```

**Usage:**
```zpug
+icon('home')          // Uses default size
+icon('settings', 'large')
```

**Note:** Default parameters make mixins more flexible.

---

### 5. Nested Content with Blocks

```zpug
mixin panel(title)
  div.panel
    div.panel-header
      h3= title
    div.panel-body
      block
```

**Usage:**
```zpug
+panel('User Settings')
  p Configure your preferences
  button Save Changes
```

**Generates:**
```html
<div class="panel">
  <div class="panel-header">
    <h3>User Settings</h3>
  </div>
  <div class="panel-body">
    <p>Configure your preferences</p>
    <button>Save Changes</button>
  </div>
</div>
```

**Usage:** Use `block` to accept nested content.

---

## 🖥️ Run This Example

```bash
# Compile to stdout
zpug examples/04-mixins.pug

# Pretty print
zpug -p examples/04-mixins.pug

# Compile to file
zpug examples/04-mixins.pug -o output.html
```

## 📤 Expected Output

```html
<div class="page"><h1>Ejemplos de Mixins</h1><div class="buttons"><button class="btn">Guardar</button><button class="btn">Cancelar</button><button class="btn">Eliminar</button></div><div class="cards"><div class="card"><h3 class="card-title">Bienvenida</h3><p class="card-description">Gracias por usar zig-pug</p></div><div class="card"><h3 class="card-title">Características</h3><p class="card-description">Soporta toda la sintaxis de Pug</p></div><div class="card"><h3 class="card-title">Rendimiento</h3><p class="card-description">Compilación ultra-rápida</p></div></div><div class="alerts"><div class="alert alert-success"><p>Operación exitosa</p></div><div class="alert alert-warning"><p>Ten cuidado</p></div><div class="alert alert-error"><p>Algo salió mal</p></div></div></div>
```

## ✅ Exercise

Create a user profile card mixin:

```zpug
mixin userProfile(name, role, avatar, isOnline)
  div.user-profile
    div.avatar
      img(src=avatar alt=name)
      if isOnline
        span.status-badge Online

    div.user-info
      h3= name
      p.role= role

      if role === 'admin'
        span.badge.badge-admin Admin
      else if role === 'moderator'
        span.badge.badge-mod Moderator

// Usage
+userProfile('Alice', 'admin', '/img/alice.jpg', true)
+userProfile('Bob', 'user', '/img/bob.jpg', false)
```

## 🔗 What's Next?

**Next Example:** [includes.md](includes.md) - Learn template composition with includes

**Previous Example:** [03-conditionals.md](03-conditionals.md) - Conditionals

**Learning Path:** [INDEX.md](INDEX.md)
