# Galería de Ejemplos

[English](../en/EXAMPLES.md) | Español

Ejemplos prácticos de plantillas zig-pug para casos de uso comunes.

---

## Tabla de Contenidos

1. [Página Básica](#página-básica)
2. [Artículo de Blog](#artículo-de-blog)
3. [Menú de Navegación](#menú-de-navegación)
4. [Formularios](#formularios)
5. [Cuadrícula de Tarjetas](#cuadrícula-de-tarjetas)
6. [Panel de Control](#panel-de-control)
7. [Plantilla de Correo Electrónico](#plantilla-de-correo-electrónico)
8. [Página 404](#página-404)

---

## Página Básica

Una página HTML simple con metadatos.

**Plantilla:**

```pug
doctype html
html(lang="en")
  head
    meta(charset="UTF-8")
    meta(name="viewport" content="width=device-width, initial-scale=1.0")
    title #{pageTitle}
    link(rel="stylesheet" href="/styles.css")
  body
    header
      h1 #{siteTitle}
      nav
        a(href="/") Home
        a(href="/about") About
        a(href="/contact") Contact
    main
      h2 #{pageTitle}
      p #{description}
    footer
      p © #{year} #{siteName}
```

**Variables:**

```javascript
{
  pageTitle: "Welcome",
  siteTitle: "My Website",
  description: "Welcome to our amazing site!",
  year: 2025,
  siteName: "Example Inc."
}
```

---

## Artículo de Blog

Página de artículo con metadatos y contenido.

**Plantilla:**

```pug
doctype html
html(lang="en")
  head
    title #{article.title} - #{siteName}
    meta(name="author" content=article.author)
    meta(name="description" content=article.excerpt)
  body
    article
      header
        h1= article.title
        .meta
          span.author By #{article.author}
          span.date #{article.date}
          if article.featured
            span.badge Featured
      .content
        p= article.excerpt
        .body!= article.content
      if article.tags
        .tags
          each tag in article.tags
            span.tag= tag
      .actions
        if canEdit
          a.btn(href="/edit/#{article.id}") Edit
        a.btn(href="/share") Share
```

**Variables:**

```javascript
{
  siteName: "Tech Blog",
  canEdit: true,
  article: {
    id: 123,
    title: "Getting Started with Zig",
    author: "Alice Developer",
    date: "2025-12-16",
    featured: true,
    excerpt: "Learn the basics of Zig programming language",
    content: "<p>Zig is amazing...</p>",
    tags: ["zig", "programming", "tutorial"]
  }
}
```

---

## Menú de Navegación

Navegación responsiva con estados activos.

**Plantilla:**

```pug
nav.navbar
  .container
    a.brand(href="/") #{siteName}
    button.toggle(type="button") ☰
    ul.nav-menu
      each item in menuItems
        li(class=item.active ? "active" : "")
          a(href=item.url)= item.label
          if item.badge
            span.badge= item.badge
```

**Variables:**

```javascript
{
  siteName: "Dashboard",
  menuItems: [
    { label: "Home", url: "/", active: true },
    { label: "Products", url: "/products", active: false },
    { label: "Cart", url: "/cart", active: false, badge: "3" },
    { label: "Profile", url: "/profile", active: false }
  ]
}
```

---

## Formularios

Formulario de contacto con estados de validación.

**Plantilla:**

```pug
form.contact-form(action="/submit" method="POST")
  h2 #{formTitle}

  .form-group(class=nameError ? "error" : "")
    label(for="name") Name *
    input#name(type="text" name="name" required)
    if nameError
      span.error-msg= nameError

  .form-group(class=emailError ? "error" : "")
    label(for="email") Email *
    input#email(type="email" name="email" required)
    if emailError
      span.error-msg= emailError

  .form-group
    label(for="subject") Subject
    select#subject(name="subject")
      each option in subjects
        option(value=option)= option

  .form-group
    label(for="message") Message *
    textarea#message(name="message" rows="5" required)

  .form-group
    label
      input(type="checkbox" name="subscribe")
      |  Subscribe to newsletter

  button.btn-submit(type="submit") #{submitText}
```

**Variables:**

```javascript
{
  formTitle: "Contact Us",
  nameError: null,
  emailError: "Please enter a valid email",
  subjects: ["General", "Support", "Sales", "Other"],
  submitText: "Send Message"
}
```

---

## Cuadrícula de Tarjetas

Tarjetas de productos o contenido en un diseño de cuadrícula.

**Plantilla:**

```pug
.cards-grid
  each product in products
    .card(class=product.featured ? "featured" : "")
      if product.image
        img.card-img(src=product.image alt=product.name)
      .card-body
        h3.card-title= product.name
        p.card-price $#{product.price}
        p.card-desc= product.description

        if product.inStock
          span.badge.success In Stock
        else
          span.badge.danger Out of Stock

        .card-footer
          button.btn(disabled=!product.inStock) Add to Cart
          a.btn-link(href="/product/#{product.id}") Details
```

**Variables:**

```javascript
{
  products: [
    {
      id: 1,
      name: "Laptop Pro",
      price: 999,
      description: "Powerful laptop for professionals",
      image: "/images/laptop.jpg",
      inStock: true,
      featured: true
    },
    {
      id: 2,
      name: "Wireless Mouse",
      price: 29,
      description: "Ergonomic wireless mouse",
      image: "/images/mouse.jpg",
      inStock: false,
      featured: false
    }
  ]
}
```

---

## Panel de Control

Panel de administración con estadísticas.

**Plantilla:**

```pug
.dashboard
  header.dashboard-header
    h1 #{user.name}'s Dashboard
    .user-info
      span Welcome back!
      if user.isAdmin
        span.badge Admin

  .stats-grid
    each stat in stats
      .stat-card(class="stat-" + stat.type)
        .stat-icon= stat.icon
        .stat-value= stat.value
        .stat-label= stat.label
        if stat.change
          .stat-change(class=stat.change > 0 ? "positive" : "negative")
            | #{stat.change > 0 ? "+" : ""}#{stat.change}%

  .content-grid
    .section
      h2 Recent Activity
      ul.activity-list
        each activity in recentActivity
          li
            span.time= activity.time
            span.message= activity.message

    .section
      h2 Quick Actions
      .actions
        each action in quickActions
          button.action-btn(class="btn-" + action.type)= action.label
```

**Variables:**

```javascript
{
  user: {
    name: "Alice",
    isAdmin: true
  },
  stats: [
    { icon: "📊", value: "1,234", label: "Total Sales", type: "primary", change: 12.5 },
    { icon: "👥", value: "567", label: "Users", type: "info", change: 5.3 },
    { icon: "📦", value: "89", label: "Orders", type: "success", change: -2.1 },
    { icon: "💰", value: "$12,345", label: "Revenue", type: "warning", change: 8.7 }
  ],
  recentActivity: [
    { time: "2m ago", message: "New order received" },
    { time: "15m ago", message: "User registered" },
    { time: "1h ago", message: "Payment processed" }
  ],
  quickActions: [
    { label: "New Product", type: "primary" },
    { label: "Export Data", type: "secondary" },
    { label: "Settings", type: "tertiary" }
  ]
}
```

---

## Plantilla de Correo Electrónico

Correo electrónico HTML con diseño responsivo.

**Plantilla:**

```pug
doctype html
html
  head
    meta(charset="UTF-8")
    meta(name="viewport" content="width=device-width, initial-scale=1.0")
    title= emailSubject
    style.
      body { font-family: Arial, sans-serif; }
      .container { max-width: 600px; margin: 0 auto; }
      .header { background: #007bff; color: white; padding: 20px; }
      .content { padding: 20px; }
      .button { background: #28a745; color: white; padding: 10px 20px; text-decoration: none; }
  body
    .container
      .header
        h1= companyName
      .content
        p Hi #{recipientName},
        p= message
        if actionUrl
          p
            a.button(href=actionUrl)= actionText
        p Thank you,
        p= companyName
      .footer
        p
          small © #{year} #{companyName}. All rights reserved.
        if unsubscribeUrl
          p
            small
              a(href=unsubscribeUrl) Unsubscribe
```

**Variables:**

```javascript
{
  emailSubject: "Welcome to Our Service",
  companyName: "Example Corp",
  recipientName: "Alice",
  message: "Thank you for signing up! We're excited to have you on board.",
  actionUrl: "https://example.com/verify",
  actionText: "Verify Email",
  year: 2025,
  unsubscribeUrl: "https://example.com/unsubscribe"
}
```

---

## Página 404

Página de error personalizada con enlaces útiles.

**Plantilla:**

```pug
doctype html
html(lang="en")
  head
    title #{errorCode} - #{errorMessage}
    style.
      body {
        font-family: Arial, sans-serif;
        text-align: center;
        padding: 50px;
      }
      h1 { font-size: 72px; color: #e74c3c; }
      .suggestions { list-style: none; padding: 0; }
      .suggestions li { margin: 10px 0; }
  body
    h1= errorCode
    h2= errorMessage
    p= errorDescription

    if suggestions.length > 0
      h3 Try these instead:
      ul.suggestions
        each link in suggestions
          li
            a(href=link.url)= link.text

    hr

    if showContactSupport
      p
        | Need help?
        a(href="/contact") Contact Support

    p
      a(href="/") ← Back to Home
```

**Variables:**

```javascript
{
  errorCode: "404",
  errorMessage: "Page Not Found",
  errorDescription: "The page you're looking for doesn't exist or has been moved.",
  showContactSupport: true,
  suggestions: [
    { text: "Go to Homepage", url: "/" },
    { text: "View Products", url: "/products" },
    { text: "Read Blog", url: "/blog" },
    { text: "Contact Us", url: "/contact" }
  ]
}
```

---

## Más Ejemplos

Consulta el directorio `examples/` en el repositorio para más plantillas:

- **Diseños de Blog** - `examples/blog/`
- **Comercio Electrónico** - `examples/ecommerce/`
- **Portafolio** - `examples/portfolio/`
- **Páginas de Aterrizaje** - `examples/landing/`
- **Paneles de Administración** - `examples/admin/`

---

## Ver También

- [Guía de Sintaxis Pug](PUG-SYNTAX.md)
- [Referencia de API](API-REFERENCE.md)
- [Primeros Pasos](GETTING-STARTED.md)

---

**Última Actualización:** 2025-12-16
