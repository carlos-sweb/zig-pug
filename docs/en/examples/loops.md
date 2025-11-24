# Example: Loops and Iteration

**Difficulty:** ⭐⭐ Medium
**Category:** Control
**Time:** 7 minutes

## 📝 What You'll Learn

- Iterating over arrays with `each`
- Loop with index access
- Handling empty arrays with `else`
- Using loop variables in interpolation

## 📄 Source Code

**File:** `examples/loops.zpug`

```zpug
// Example: Loops in zig-pug

doctype html
html(lang="es")
  head
    title Loops Demo
  body
    h1 Lista de Usuarios

    // Simple loop
    ul.users
      each user in users
        li.user #{user}

    // Loop with index
    h2 Frutas Numeradas
    ol
      each fruit, i in fruits
        li #{i}: #{fruit}

    // Empty array with else
    h2 Items Vacíos
    each item in emptyArray
      p #{item}
    else
      p.no-items No hay items disponibles
```

## 🎯 Key Concepts

### 1. Simple Each Loop

```zpug
ul.users
  each user in users
    li.user #{user}
```

**With data:** `users = ['Alice', 'Bob', 'Carol']`

**Generates:**
```html
<ul class="users">
  <li class="user">Alice</li>
  <li class="user">Bob</li>
  <li class="user">Carol</li>
</ul>
```

**Syntax:** `each item in array`

---

### 2. Loop with Index

```zpug
ol
  each fruit, i in fruits
    li #{i}: #{fruit}
```

**With data:** `fruits = ['Apple', 'Banana', 'Orange']`

**Generates:**
```html
<ol>
  <li>0: Apple</li>
  <li>1: Banana</li>
  <li>2: Orange</li>
</ol>
```

**Syntax:** `each item, index in array`

**Note:** Index starts at 0, like JavaScript arrays.

---

### 3. Handling Empty Arrays

```zpug
each item in emptyArray
  p #{item}
else
  p.no-items No hay items disponibles
```

**With data:** `emptyArray = []`

**Generates:**
```html
<p class="no-items">No hay items disponibles</p>
```

**Usage:** The `else` clause executes when the array is empty or undefined.

---

### 4. Looping Over Objects

```zpug
each value, key in userObject
  div
    strong #{key}:
    span #{value}
```

**With data:** `userObject = {name: 'Alice', age: 30}`

**Generates:**
```html
<div><strong>name</strong>: <span>Alice</span></div>
<div><strong>age</strong>: <span>30</span></div>
```

**Syntax:** `each value, key in object`

---

## 🖥️ Run This Example

```bash
# Compile to stdout
zpug examples/loops.zpug

# Pretty print
zpug -p examples/loops.zpug

# Compile to file
zpug examples/loops.zpug -o output.html
```

**Note:** You'll need to pass array data when rendering this template in your application.

## 📤 Expected Output

```html
<!DOCTYPE html><html lang="es"><head><title>Loops Demo</title></head><body><h1>Lista de Usuarios</h1><ul class="users"><li class="user">Alice</li><li class="user">Bob</li><li class="user">Carol</li></ul><h2>Frutas Numeradas</h2><ol><li>0: Apple</li><li>1: Banana</li><li>2: Orange</li></ol><h2>Items Vacíos</h2><p class="no-items">No hay items disponibles</p></body></html>
```

## ✅ Exercise

Create a shopping cart list:

```zpug
div.shopping-cart
  h2 Your Cart

  each product in cart
    div.cart-item
      h3 #{product.name}
      p Quantity: #{product.quantity}
      p Price: $#{product.price * product.quantity}
  else
    p.empty-cart Your cart is empty

  if cart.length > 0
    div.total
      strong Total Items: #{cart.length}
```

## 🔗 What's Next?

**Next Example:** [03-conditionals.md](03-conditionals.md) - Learn conditional rendering

**Previous Example:** [02-interpolation.md](02-interpolation.md) - JavaScript Interpolation

**Learning Path:** [INDEX.md](INDEX.md)
