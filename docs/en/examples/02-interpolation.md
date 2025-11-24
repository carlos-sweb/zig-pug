# Example 02: JavaScript Interpolation

**Difficulty:** ⭐ Easy
**Category:** Fundamentos
**Time:** 5 minutes

## 📝 What You'll Learn

- Variable interpolation with `#{}`
- Using JavaScript expressions
- String methods in templates
- Arithmetic operations
- Ternary operators

## 📄 Source Code

**File:** `examples/02-interpolation.pug`

```zpug
// Ejemplo 2: Interpolación de JavaScript
// Muestra cómo usar variables y expresiones JavaScript

div.user-profile
  h1 Perfil de #{name}

  div.info
    p Nombre: #{name.toUpperCase()}
    p Email: #{email.toLowerCase()}
    p Edad: #{age}
    p Edad el próximo año: #{age + 1}

  div.calculated
    p Doble de edad: #{age * 2}
    p Es adulto: #{age >= 18 ? 'Sí' : 'No'}

  div.methods
    p Primera letra: #{name[0]}
    p Longitud del nombre: #{name.length}
```

## 🎯 Key Concepts

### 1. Basic Variable Interpolation

```zpug
h1 Perfil de #{name}
p Edad: #{age}
```

**Generates:**
```html
<h1>Perfil de Juan</h1>
<p>Edad: 25</p>
```

**Syntax:** Use `#{}` to insert JavaScript variables or expressions into text.

---

### 2. JavaScript Methods

```zpug
p Nombre: #{name.toUpperCase()}
p Email: #{email.toLowerCase()}
```

**Generates:**
```html
<p>Nombre: JUAN</p>
<p>Email: juan@example.com</p>
```

**Note:** You can call any JavaScript string method inside `#{}`.

---

### 3. Arithmetic Operations

```zpug
p Edad el próximo año: #{age + 1}
p Doble de edad: #{age * 2}
```

**Generates:**
```html
<p>Edad el próximo año: 26</p>
<p>Doble de edad: 50</p>
```

**Tip:** All JavaScript arithmetic operators work inside interpolation.

---

### 4. Ternary Operators

```zpug
p Es adulto: #{age >= 18 ? 'Sí' : 'No'}
```

**Generates:**
```html
<p>Es adulto: Sí</p>
```

**Usage:** Perfect for inline conditional text.

---

### 5. Array/Object Access

```zpug
p Primera letra: #{name[0]}
p Longitud del nombre: #{name.length}
```

**Generates:**
```html
<p>Primera letra: J</p>
<p>Longitud del nombre: 4</p>
```

**Note:** Access object properties and array elements normally.

---

## 🖥️ Run This Example

```bash
# Compile with sample data
zpug examples/02-interpolation.pug

# Pretty print
zpug -p examples/02-interpolation.pug

# Compile to file
zpug examples/02-interpolation.pug -o output.html
```

**Note:** Variables like `name`, `email`, and `age` would normally be passed from your application code.

## 📤 Expected Output

```html
<div class="user-profile"><h1>Perfil de Juan</h1><div class="info"><p>Nombre: JUAN</p><p>Email: juan@example.com</p><p>Edad: 25</p><p>Edad el próximo año: 26</p></div><div class="calculated"><p>Doble de edad: 50</p><p>Es adulto: Sí</p></div><div class="methods"><p>Primera letra: J</p><p>Longitud del nombre: 4</p></div></div>
```

## ✅ Exercise

Create a product card with interpolation:

```zpug
div.product-card
  h2 #{productName}
  p.price $#{price.toFixed(2)}
  p.discount #{discount}% OFF
  p.final-price Final: $#{(price * (1 - discount/100)).toFixed(2)}
  p.stock #{stock > 0 ? 'In Stock' : 'Out of Stock'}
```

## 🔗 What's Next?

**Next Example:** [loops.md](loops.md) - Learn how to iterate over arrays and objects

**Previous Example:** [01-basic.md](01-basic.md) - Basic Tags and Attributes

**Learning Path:** [INDEX.md](INDEX.md)
