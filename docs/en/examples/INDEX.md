# zig-pug Examples - Learning Path

Learn zig-pug step by step through progressively complex examples.

## 🎯 Learning Path

### 📘 Level 1: Fundamentos (Basics)

Start here to learn the core syntax:

1. **[01-basic.md](01-basic.md)** - Tags, classes, IDs, attributes
   - Learn: Basic HTML structure in Pug syntax
   - Time: 5 minutes

2. **[02-interpolation.md](02-interpolation.md)** - Variables and JavaScript expressions
   - Learn: Dynamic content with `#{}`
   - Time: 10 minutes

3. **[loops.md](loops.md)** - Iteration with `each`
   - Learn: Loop over arrays
   - Time: 10 minutes

### 📗 Level 2: Control y Lógica (Control Flow)

Add logic to your templates:

4. **[03-conditionals.md](03-conditionals.md)** - if/else/unless
   - Learn: Conditional rendering
   - Time: 10 minutes

5. **[04-mixins.md](04-mixins.md)** - Reusable components
   - Learn: Create and use mixins
   - Time: 15 minutes

### 📙 Level 3: Composición Avanzada (Advanced Composition)

Build complex templates:

6. **[includes.md](includes.md)** - Partial templates
   - Learn: Include header, footer, etc.
   - Time: 10 minutes

7. **[inheritance.md](inheritance.md)** - Template inheritance
   - Learn: extends and blocks
   - Time: 15 minutes

### 📕 Level 4: Ejemplo Completo (Complete Example)

8. **[05-complete.md](05-complete.md)** - Full application
   - Learn: Everything combined
   - Time: 20 minutes

---

## 🚀 Quick Start

```bash
# Try any example
zpug examples/01-basic.zpug

# With variables
zpug examples/02-interpolation.zpug --var name=Alice --var age=25

# With JSON data
zpug examples/loops.zpug --vars examples/data.json
```

## 📊 Difficulty Levels

| Example | Difficulty | Features Used | Lines |
|---------|-----------|---------------|-------|
| 01-basic | ⭐ Easy | tags, classes, IDs | ~15 |
| 02-interpolation | ⭐ Easy | interpolation, expressions | ~20 |
| loops | ⭐⭐ Medium | each, arrays | ~15 |
| 03-conditionals | ⭐⭐ Medium | if/else, logic | ~20 |
| 04-mixins | ⭐⭐ Medium | mixins, arguments | ~25 |
| includes | ⭐⭐⭐ Advanced | include, partials | ~30 |
| inheritance | ⭐⭐⭐ Advanced | extends, blocks | ~35 |
| 05-complete | ⭐⭐⭐⭐ Expert | all features | ~50 |

## 🎓 Recommended Learning Order

**Beginner** (Day 1):
1. 01-basic
2. 02-interpolation

**Intermediate** (Day 2):
3. loops
4. 03-conditionals
5. 04-mixins

**Advanced** (Day 3):
6. includes
7. inheritance

**Master** (Day 4):
8. 05-complete

---

**Next:** Start with [01-basic.md](01-basic.md) →
