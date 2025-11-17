# Alternativas a QuickJS para zig-pug

## 🔍 Búsqueda Realizada

He investigado exhaustivamente alternativas a QuickJS escritas en Zig puro para evitar los problemas de libc en Termux/Android.

---

## 📋 Opciones Encontradas

### 1. **Kiesel** ⚠️ (Motor JS en Zig - En Desarrollo)
- **Repo**: https://codeberg.org/kiesel-js/kiesel
- **Lenguaje**: Zig (con deps C)
- **Zig Version**: 0.15 ✅
- **Estado**: Temprano (25% test262 compliance)

**✅ Ventajas:**
- Escrito principalmente en Zig
- Objetivo: soporte completo ECMAScript
- Compatible con Zig 0.15.2

**❌ Desventajas:**
- Usa dependencias C: bdwgc (GC), libregexp, ICU4X
- Solo 25% test262 (no production-ready)
- Requiere Cargo para algunas features
- **Mismo problema de libc que QuickJS**

**Veredicto**: ❌ No resuelve nuestro problema de Termux/Android

---

### 2. **Bun Parser** (Parser JS en Zig)
- **Repo**: https://github.com/oven-sh/bun
- **Archivo**: `src/js_parser.zig`
- **Lenguaje**: Zig 100%

**✅ Ventajas:**
- Parser JS/JSX/TS completo en Zig puro
- Production-ready (usado en Bun)
- Muy rápido

**❌ Desventajas:**
- Solo PARSER (no evaluador)
- Muy acoplado a Bun (js_lexer, js_ast, core modules)
- No ejecuta código, solo lo parsea
- Difícil de extraer como standalone

**Veredicto**: ❌ No sirve (necesitamos ejecutar, no solo parsear)

---

### 3. **Lenguajes de Scripting en Zig** 🤔

Encontrados en awesome-zig:

#### **Cyber** - Fast and concurrent scripting
- **Repo**: https://github.com/fubark/cyber
- **Lenguaje**: Zig 100%
- **Sintaxis**: Similar a Python/JavaScript

#### **Buzz** - Small/lightweight scripting
- **Repo**: https://github.com/buzz-language/buzz
- **Lenguaje**: Zig 100%
- **Sintaxis**: Propia (estáticamente tipado)

#### **Zua** - Lua implementation in Zig
- **Repo**: https://github.com/squeek502/zua
- **Lenguaje**: Zig 100%
- **Sintaxis**: Lua

**✅ Ventajas:**
- 100% Zig puro (no deps C)
- Compilarían en Termux sin problemas
- Production-ready algunos

**❌ Desventajas:**
- NO son JavaScript (sintaxis diferente)
- Usuarios tendrían que aprender nueva sintaxis
- No hay librerías JS (voca, numeral, etc.)

**Veredicto**: 🤔 Posible pero cambiaría la propuesta del proyecto

---

### 4. **Otras Herramientas**

- **zig-javascript-bridge**: Para llamar JS desde Zig WASM (no aplica)
- **napigen**: Bindings N-API para Zig (requiere Node.js)
- **jam**: Parser/formatter/linter JS (solo análisis estático)

**Veredicto**: ❌ No aplican para nuestro caso de uso

---

## 🎯 Comparación de Opciones

| Opción | Lenguaje | Funciona en Termux | JavaScript Real | Production Ready |
|--------|----------|-------------------|-----------------|------------------|
| **QuickJS** (actual) | C | ❌ No | ✅ Sí | ✅ Sí |
| **Kiesel** | Zig + C deps | ❌ No | ✅ Sí (parcial) | ❌ No |
| **Bun Parser** | Zig | ✅ Sí | ❌ Solo parse | ✅ Sí |
| **Cyber** | Zig puro | ✅ Sí | ❌ No (propio lenguaje) | ✅ Sí |
| **Runtime Stub** (actual) | Zig puro | ✅ Sí | 🟡 Limitado | 🟡 Para desarrollo |

---

## 💡 Recomendación Final

### Opción A: **Mantener Runtime Stub** (RECOMENDADO)

**Continuar como está:**
1. ✅ Usar runtime stub para desarrollo en Termux
2. ✅ Completar el compiler (Paso 11)
3. ✅ Tener proyecto funcional con limitaciones documentadas
4. ⏭️ Integrar QuickJS real cuando tengamos acceso a Linux/Mac estándar

**Razones:**
- No bloqueamos el desarrollo
- Runtime stub ya está funcionando (2 tests passing)
- Interfaz preparada para migración futura
- QuickJS es industry-standard (usado en producción)

---

### Opción B: **Usar Cyber como lenguaje de templates**

**Cambio de dirección:**
```pug
// En lugar de JavaScript:
p #{name.toLowerCase()}

// Usaríamos sintaxis Cyber:
p #{name.lower()}
```

**Pros:**
- ✅ Compilaría en Termux sin problemas
- ✅ 100% Zig (performance nativo)
- ✅ Lenguaje completo con funciones

**Cons:**
- ❌ NO es JavaScript (sintaxis diferente)
- ❌ Usuarios deben aprender Cyber
- ❌ Sin librerías JS populares (voca, numeral, lodash)
- ❌ Cambia la propuesta del proyecto completamente

---

### Opción C: **Implementar evaluador de expresiones simple en Zig**

**Crear nuestro propio evaluador:**
- Solo expresiones simples: operadores, métodos básicos
- Sin funciones complejas ni librerías
- Suficiente para templates

**Pros:**
- ✅ Control total
- ✅ Sin dependencias
- ✅ Funcionaría en Termux

**Cons:**
- ⏰ Tiempo significativo de desarrollo
- 🐛 Muchos edge cases
- 📚 Difícil soportar todas las features de JS
- 🔧 Reinventar la rueda

---

## 🏆 Decisión Sugerida

### **OPCIÓN A - Mantener Runtime Stub**

**Justificación:**

1. **No bloquea desarrollo**: Ya tenemos un stub funcional
2. **Path to production**: QuickJS es battle-tested y production-ready
3. **Migración clara**: Cuando tengamos Linux/Mac, solo activamos QuickJS
4. **Expectativas del usuario**: JavaScript es JavaScript, no un lenguaje nuevo
5. **Ecosystem**: Acceso futuro a todo el ecosistema JS (voca, numeral, lodash)

**Timeline:**

```
📍 AHORA (Termux):
- ✅ Runtime stub funcionando
- ✅ Soporta: variables, propiedades, arrays
- ⏭️ Continuar con Paso 11 (Compiler)
- ⏭️ Generar HTML con capacidades limitadas

📍 FUTURO (Linux/Mac):
- 🚀 Activar QuickJS en build.zig
- 🚀 Integrar librerías JS
- 🚀 Tests completos con expresiones JS reales
- 🚀 Production-ready con todas las features
```

---

## ❓ Otras Consideraciones

### ¿Y si realmente necesitamos JS ahora en Termux?

**Opción experimental**: Intentar compilar QuickJS con Zig en Termux creando un `libc.txt` manual:

```bash
# Crear libc.txt para Termux
zig libc > /tmp/libc.txt
# Editar paths manualmente para Termux
# Intentar build con -Dtarget=aarch64-linux-musl
```

**Riesgo**: Alto - puede no funcionar y perder tiempo

---

## 📝 Conclusión

**No existe un motor JavaScript puro en Zig production-ready.**

Las opciones son:
1. ✅ **Runtime stub ahora, QuickJS después** (RECOMENDADO)
2. 🤔 Cambiar a Cyber/Buzz (cambia la propuesta)
3. ⏰ Implementar evaluador propio (mucho trabajo)
4. 🎲 Forzar QuickJS en Termux (experimental)

**Mi recomendación fuerte: Opción 1**
- Continúa el desarrollo sin bloqueos
- Mantiene la visión original (JavaScript real)
- Path claro hacia producción
- Ya tenemos código funcionando

¿Qué te parece?
