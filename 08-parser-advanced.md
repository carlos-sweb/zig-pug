# Paso 8: Parser de Características Avanzadas

## Objetivo
Implementar mixins, includes, template inheritance.

---

## Tareas

### 8.1 Parser de Mixins
- Definición: `mixin name(params)`
- Llamada: `+name(args)`
- Parámetros con valores por defecto
- Rest arguments `...items`
- Bloques de mixin
- Atributos implícitos

### 8.2 Parser de Includes
- Includes de archivos Pug
- Includes de texto plano
- Includes con filtros
- Resolución de rutas

### 8.3 Parser de Template Inheritance
- `extends parent.pug`
- `block blockname`
- `block append blockname`
- `block prepend blockname`
- Validación de reglas de herencia

### 8.4 Optimización del Parser
- Reducir allocaciones
- Mejorar mensajes de error
- Profiling

---

## Entregables
- Parser completo con todas las características
- Tests exhaustivos
- Benchmarks de rendimiento

---

## Siguiente Paso
**09-javascript-blocks.md** para soporte de JavaScript puro.
