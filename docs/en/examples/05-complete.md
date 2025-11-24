# Example 05: Complete Dashboard Example

**Difficulty:** ⭐⭐⭐ Advanced
**Category:** Composición
**Time:** 20 minutes

## 📝 What You'll Learn

- Combining all zig-pug features
- Building a realistic dashboard
- Using mixins with conditionals
- Nesting loops and conditionals
- Real-world template patterns

## 📄 Source Code

**File:** `examples/05-complete-example.pug`

```zpug
// Ejemplo 5: Ejemplo Completo
// Combina todas las características: tags, interpolación, condicionales, mixins

// Mixins reutilizables
mixin nav-item(text, url)
  li.nav-item
    a(href=url)= text

mixin user-card(user)
  div.user-card
    h3 #{user.name.toUpperCase()}
    p Email: #{user.email.toLowerCase()}
    p Miembro desde: #{user.year}
    if user.isPremium
      span.badge Premium
    else
      span.badge Free

// Estructura de la página
doctype html
html(lang="es")
  head
    meta(charset="UTF-8")
    meta(name="viewport" content="width=device-width, initial-scale=1.0")
    title Dashboard - #{siteName}
    link(rel="stylesheet" href="/styles.css")

  body
    // Navegación
    nav.navbar
      div.container
        h1.logo= siteName
        ul.nav-menu
          +nav-item('Inicio', '/')
          +nav-item('Perfil', '/profile')
          +nav-item('Configuración', '/settings')
          if isAdmin
            +nav-item('Admin', '/admin')

    // Contenido principal
    main.main-content
      div.container
        // Cabecera
        header.page-header
          h1 Bienvenido, #{currentUser.name}!
          p Último acceso: #{lastLogin}

        // Sección de estadísticas
        div.stats-grid
          div.stat-card
            h3 Posts
            p.stat-value #{stats.posts}

          div.stat-card
            h3 Seguidores
            p.stat-value #{stats.followers}

          div.stat-card
            h3 Siguiendo
            p.stat-value #{stats.following}

        // Condicional: mostrar según rol
        if currentUser.role === 'admin'
          div.admin-panel
            h2 Panel de Administración
            p Total de usuarios: #{adminData.totalUsers}
            p Nuevos hoy: #{adminData.newToday}

        // Estado de cuenta
        div.account-status
          if currentUser.isPremium
            div.premium-info
              h2 ⭐ Cuenta Premium
              p Gracias por tu apoyo
              p Válido hasta: #{premiumUntil}
          else
            div.upgrade-prompt
              h2 Actualiza a Premium
              p Desbloquea características exclusivas
              button.btn-primary Mejorar Ahora

        // Lista de usuarios (simulado)
        div.users-section
          h2 Usuarios Activos
          div.users-grid
            +user-card({name: 'Alice', email: 'alice@example.com', year: 2020, isPremium: true})
            +user-card({name: 'Bob', email: 'bob@example.com', year: 2021, isPremium: false})
            +user-card({name: 'Carol', email: 'carol@example.com', year: 2019, isPremium: true})

    // Footer
    footer.footer
      div.container
        p © #{currentYear} #{siteName}. Todos los derechos reservados.
        p Powered by zig-pug
```

## 🎯 Key Concepts

### 1. Reusable Navigation Mixin

```zpug
mixin nav-item(text, url)
  li.nav-item
    a(href=url)= text

// Usage
ul.nav-menu
  +nav-item('Inicio', '/')
  +nav-item('Perfil', '/profile')
  if isAdmin
    +nav-item('Admin', '/admin')
```

**Pattern:** Combine mixins with conditionals for dynamic navigation.

---

### 2. Complex User Card Mixin

```zpug
mixin user-card(user)
  div.user-card
    h3 #{user.name.toUpperCase()}
    p Email: #{user.email.toLowerCase()}
    p Miembro desde: #{user.year}
    if user.isPremium
      span.badge Premium
    else
      span.badge Free
```

**Features Used:**
- Parameter object destructuring
- String interpolation with methods
- Conditional rendering within mixin
- Dynamic styling based on data

---

### 3. Statistics Dashboard

```zpug
div.stats-grid
  div.stat-card
    h3 Posts
    p.stat-value #{stats.posts}

  div.stat-card
    h3 Seguidores
    p.stat-value #{stats.followers}

  div.stat-card
    h3 Siguiendo
    p.stat-value #{stats.following}
```

**Pattern:** Grid layout for dashboard metrics with dynamic values.

---

### 4. Role-Based Content

```zpug
if currentUser.role === 'admin'
  div.admin-panel
    h2 Panel de Administración
    p Total de usuarios: #{adminData.totalUsers}
    p Nuevos hoy: #{adminData.newToday}
```

**Usage:** Show/hide sections based on user roles.

---

### 5. Premium Status Section

```zpug
div.account-status
  if currentUser.isPremium
    div.premium-info
      h2 ⭐ Cuenta Premium
      p Gracias por tu apoyo
      p Válido hasta: #{premiumUntil}
  else
    div.upgrade-prompt
      h2 Actualiza a Premium
      p Desbloquea características exclusivas
      button.btn-primary Mejorar Ahora
```

**Pattern:** Different UI for premium vs free users.

---

### 6. Inline Object in Mixin Calls

```zpug
+user-card({name: 'Alice', email: 'alice@example.com', year: 2020, isPremium: true})
```

**Note:** Pass object literals directly to mixins for component data.

---

## 🖥️ Run This Example

```bash
# Compile to stdout
zpug examples/05-complete-example.pug

# Pretty print
zpug -p examples/05-complete-example.pug

# Compile to file
zpug examples/05-complete-example.pug -o dashboard.html
```

## 📤 Expected Output

**Sample data:**
- `siteName = "MyApp"`
- `currentUser = {name: "John", role: "admin", isPremium: true}`
- `stats = {posts: 42, followers: 1337, following: 256}`

```html
<!DOCTYPE html><html lang="es"><head><meta charset="UTF-8"><meta name="viewport" content="width=device-width, initial-scale=1.0"><title>Dashboard - MyApp</title><link rel="stylesheet" href="/styles.css"></head><body><nav class="navbar"><div class="container"><h1 class="logo">MyApp</h1><ul class="nav-menu"><li class="nav-item"><a href="/">Inicio</a></li><li class="nav-item"><a href="/profile">Perfil</a></li><li class="nav-item"><a href="/settings">Configuración</a></li><li class="nav-item"><a href="/admin">Admin</a></li></ul></div></nav><main class="main-content"><div class="container"><header class="page-header"><h1>Bienvenido, John!</h1><p>Último acceso: 2024-11-23</p></header><div class="stats-grid"><div class="stat-card"><h3>Posts</h3><p class="stat-value">42</p></div><div class="stat-card"><h3>Seguidores</h3><p class="stat-value">1337</p></div><div class="stat-card"><h3>Siguiendo</h3><p class="stat-value">256</p></div></div><div class="admin-panel"><h2>Panel de Administración</h2><p>Total de usuarios: 1500</p><p>Nuevos hoy: 23</p></div><div class="account-status"><div class="premium-info"><h2>⭐ Cuenta Premium</h2><p>Gracias por tu apoyo</p><p>Válido hasta: 2025-12-31</p></div></div><div class="users-section"><h2>Usuarios Activos</h2><div class="users-grid"><div class="user-card"><h3>ALICE</h3><p>Email: alice@example.com</p><p>Miembro desde: 2020</p><span class="badge">Premium</span></div><div class="user-card"><h3>BOB</h3><p>Email: bob@example.com</p><p>Miembro desde: 2021</p><span class="badge">Free</span></div><div class="user-card"><h3>CAROL</h3><p>Email: carol@example.com</p><p>Miembro desde: 2019</p><span class="badge">Premium</span></div></div></div></div></main><footer class="footer"><div class="container"><p>© 2024 MyApp. Todos los derechos reservados.</p><p>Powered by zig-pug</p></div></footer></body></html>
```

## ✅ Features Demonstrated

| Feature | Lines | Usage |
|---------|-------|-------|
| **Mixins** | 5-17 | Reusable nav-item and user-card components |
| **Doctype** | 20 | HTML5 doctype declaration |
| **Attributes** | 21-26 | Meta tags, links, lang attributes |
| **Interpolation** | 25, 45, 52-60 | Variable insertion with `#{}` |
| **Conditionals** | 37-38, 63-68, 71-80 | if/else for role-based content |
| **String Methods** | 11-12 | toUpperCase(), toLowerCase() |
| **Classes** | Multiple | Class syntax with `.` notation |
| **Nesting** | Entire file | Proper indentation structure |

## ✅ Exercise Challenges

### Challenge 1: Add a Search Feature
Add a search mixin that appears conditionally:

```zpug
mixin search-bar(placeholder)
  div.search
    input(type="search" placeholder=placeholder)
    button Search

// In navbar
if currentUser.isLoggedIn
  +search-bar('Search users...')
```

### Challenge 2: Activity Feed Loop
Create a dynamic activity feed:

```zpug
div.activity-feed
  h2 Recent Activity
  each activity in recentActivities
    div.activity-item
      p.activity-text #{activity.user} #{activity.action}
      p.activity-time #{activity.timeAgo}
  else
    p.no-activity No recent activity
```

### Challenge 3: Notification Badge
Add a notification counter mixin:

```zpug
mixin notification-badge(count)
  if count > 0
    span.badge.notification-badge
      = count > 99 ? '99+' : count

// Usage
+nav-item('Messages', '/messages')
+notification-badge(unreadMessages)
```

## 🔗 What's Next?

**Congratulations!** You've completed all the zig-pug examples.

**Continue Learning:**
- [INDEX.md](INDEX.md) - Review all examples
- [../../README.md](../../README.md) - Full documentation
- Build your own project using these patterns!

**Previous Example:** [inheritance.md](inheritance.md) - Template Inheritance
