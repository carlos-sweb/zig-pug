# Runtime Stub vs QuickJS Real

## Estado Actual (Termux/Android)

### ✅ Runtime Stub Implementado

Hemos creado un **runtime stub** funcional en `src/runtime.zig` que funciona en Termux/Android sin necesidad de QuickJS.

**Capacidades del Stub:**
- ✅ Acceso a variables simples: `#{name}`
- ✅ Acceso a propiedades de objetos: `#{user.name}`
- ✅ Acceso a elementos de arrays: `#{items.0}`
- ✅ Contexto con tipos básicos: strings, números, booleans, objects, arrays
- ✅ Memory management correcto (sin leaks)
- ✅ Tests funcionando (2/2 passing)

**Limitaciones del Stub:**
- ❌ Métodos JavaScript: `#{name.toLowerCase()}` → NO funciona
- ❌ Operadores: `#{price + tax}` → NO funciona
- ❌ Expresiones complejas: `#{items.filter(x => x.active)}` → NO funciona
- ❌ Librerías externas: voca.js, numeral.js, day.js, lodash → NO disponibles
- ❌ Funciones: `#{Math.max(a, b)}` → NO funciona

---

## 🎯 QuickJS Real (Próxima Implementación)

### QuickJS ya está preparado

- ✅ Descargado: `vendor/quickjs/` (versión 2024-01-13)
- ✅ Compilado: `libquickjs.a` (6.9MB) listo
- ✅ Bindings Zig creados: `src/quickjs_bindings.zig`
- ⏸️ Deshabilitado temporalmente por problemas con Bionic libc en Termux

### Cuando se integre QuickJS, tendremos:

#### ✅ Expresiones JavaScript Completas

```pug
// Métodos nativos
p #{name.toLowerCase()}
p #{name.toUpperCase()}
p #{items.length}

// Operadores
p #{price + tax}
p #{quantity * price}
p #{isActive && isVisible}

// Expresiones complejas
p #{items.filter(x => x.active).length}
p #{users.map(u => u.name).join(', ')}
```

#### ✅ Librerías JavaScript Precargadas

**1. voca.js - Manipulación de strings**
```pug
p #{v.trim(name)}
p #{v.slugify(title)}
p #{v.titleCase(sentence)}
p #{v.truncate(text, 50)}
```

**2. numeral.js - Formateo de números**
```pug
p #{numeral(1234.56).format('$0,0.00')}
p #{numeral(0.75).format('0.00%')}
p #{numeral(1000000).format('0.0a')}
```

**3. day.js - Manipulación de fechas**
```pug
p #{dayjs(date).format('YYYY-MM-DD')}
p #{dayjs().add(7, 'day').format('MMM DD')}
p #{dayjs(date).fromNow()}
```

**4. lodash - Utilidades**
```pug
each item in _.sortBy(items, 'name')
  li= item

each chunk in _.chunk(items, 3)
  .row
    each item in chunk
      .col= item
```

#### ✅ Loops con Expresiones JavaScript

```pug
// Filtrado
each item in items.filter(x => x.active)
  li= item.name

// Map
each name in users.map(u => u.name)
  p= name

// Métodos nativos
each item in items.slice(0, 5)
  li= item

// Con lodash
each group in _.groupBy(items, 'category')
  h3= group[0].category
  each item in group
    p= item.name
```

#### ✅ Condicionales con JavaScript

```pug
if items.length > 0
  p Hay #{items.length} elementos

if user.role === 'admin' && user.active
  button Delete User

unless items.filter(x => !x.processed).length === 0
  p Hay tareas pendientes
```

---

## 🔄 Migración: Stub → QuickJS

### Paso 1: Habilitar QuickJS en build.zig

En un sistema Linux/Mac estándar (NO Termux), descomentar:

```zig
// build.zig
exe.linkSystemLibrary("c");
exe.addIncludePath(b.path("vendor/quickjs"));
exe.addObjectFile(b.path("vendor/quickjs/libquickjs.a"));
exe.linkSystemLibrary("m");
exe.linkSystemLibrary("dl");
exe.linkSystemLibrary("pthread");
```

### Paso 2: Reemplazar runtime.zig

Crear nuevo `src/runtime_quickjs.zig`:

```zig
const std = @import("std");
const qjs = @import("quickjs_bindings.zig");

pub const JsRuntime = struct {
    rt: *qjs.JSRuntime,
    ctx: *qjs.JSContext,
    allocator: std.mem.Allocator,

    pub fn init(allocator: std.mem.Allocator) !*JsRuntime {
        const rt = try qjs.newRuntime();
        qjs.setMemoryLimit(rt, 50 * 1024 * 1024); // 50MB

        const ctx = try qjs.newContext(rt);

        const runtime = try allocator.create(JsRuntime);
        runtime.* = .{
            .rt = rt,
            .ctx = ctx,
            .allocator = allocator,
        };

        // Cargar librerías
        try runtime.loadLibrary("voca", voca_js);
        try runtime.loadLibrary("numeral", numeral_js);
        try runtime.loadLibrary("dayjs", dayjs_js);
        try runtime.loadLibrary("lodash", lodash_js);

        return runtime;
    }

    pub fn eval(self: *Self, expr: []const u8) ![]const u8 {
        const result = try qjs.eval(self.ctx, expr, "<eval>");
        defer qjs.freeValue(self.ctx, result);

        if (qjs.isException(result)) {
            const exception = qjs.getException(self.ctx);
            defer qjs.freeValue(self.ctx, exception);

            const err_str = try qjs.toString(self.ctx, exception, self.allocator);
            defer self.allocator.free(err_str);

            std.debug.print("JS Error: {s}\n", .{err_str});
            return error.EvalFailed;
        }

        return try qjs.toString(self.ctx, result, self.allocator);
    }

    pub fn setContext(self: *Self, key: []const u8, value: JsValue) !void {
        const global = qjs.getGlobalObject(self.ctx);
        defer qjs.freeValue(self.ctx, global);

        const js_val = try self.valueToQuickJS(value);
        try qjs.setPropertyStr(self.ctx, global, key, js_val);
    }

    fn valueToQuickJS(self: *Self, value: JsValue) !qjs.JSValue {
        return switch (value) {
            .null_value => qjs.JS_NULL,
            .undefined => qjs.JS_UNDEFINED,
            .bool_value => |b| qjs.newBool(self.ctx, b),
            .int_value => |i| qjs.newInt32(self.ctx, @intCast(i)),
            .float_value => |f| qjs.newFloat64(self.ctx, f),
            .string_value => |s| try qjs.newString(self.ctx, s),
            // ... handle objects and arrays
        };
    }
};
```

### Paso 3: Actualizar imports

```zig
// En compiler.zig o donde se use:
const runtime = @import("runtime.zig");  // Stub actual
// Cambiar a:
const runtime = @import("runtime_quickjs.zig");  // QuickJS real
```

---

## 📊 Comparación de Rendimiento

| Característica | Stub | QuickJS |
|----------------|------|---------|
| Variables simples | ✅ Rápido | ✅ Rápido |
| Propiedades | ✅ Rápido | ✅ Rápido |
| Métodos JS | ❌ No | ✅ Rápido |
| Expresiones | ❌ No | ✅ Medio |
| Librerías | ❌ No | ✅ Depende |
| Memory | 🟢 Bajo | 🟡 Medio (50MB límite) |
| Startup | 🟢 Instantáneo | 🟡 ~10ms (cargar libs) |

---

## 🎓 Ejemplos de Migración

### Antes (Stub - Funciona Ahora)

```pug
//- Contexto: { user: { name: "John", age: 30 }, items: [...] }

p #{user.name}              // ✅ Funciona
p Items: #{items.length}    // ❌ .length no funciona en stub

//- Workaround con stub: pasar length pre-calculado
//- Contexto: { user: { name: "John" }, itemCount: 5 }
p Items: #{itemCount}       // ✅ Funciona
```

### Después (QuickJS - Futuro)

```pug
//- Contexto: { user: { name: "JOHN" }, items: [...] }

p #{user.name.toLowerCase()}     // ✅ Funciona
p Items: #{items.length}         // ✅ Funciona
p #{items.filter(x => x.active).length}  // ✅ Funciona

//- Con librerías
p #{v.titleCase(user.name)}      // ✅ "John"
p #{numeral(items.length).format('0o')}  // ✅ "5th"
```

---

## ✅ Plan de Acción

**Ahora (Termux/Android con Stub):**
1. ✅ Continuar desarrollo del compiler (Paso 11)
2. ✅ Implementar rendering HTML básico
3. ✅ Tests con datos simples (variables, propiedades)

**Cuando tengas acceso a Linux/Mac estándar:**
1. Habilitar QuickJS en build.zig
2. Descargar librerías JS (voca, numeral, day, lodash)
3. Crear runtime_quickjs.zig
4. Migrar tests para usar expresiones completas

**Beneficio de este enfoque:**
- ✅ No bloqueamos el desarrollo por problemas de entorno
- ✅ El código del compiler ya está preparado para QuickJS
- ✅ Interfaz del runtime es la misma (fácil migración)
- ✅ Tests actuales seguirán funcionando

---

## 🚀 Conclusión

El **Runtime Stub** nos permite:
- ✅ Continuar desarrollando el compiler
- ✅ Probar la arquitectura completa
- ✅ Tener un proyecto funcional en Termux

**QuickJS** nos dará:
- 🚀 Expresiones JavaScript completas
- 📚 Librerías populares integradas
- 💪 Poder real de un template engine moderno

**Próximo paso:** Continuar con el **Paso 11: Compiler HTML** usando el runtime stub actual.
