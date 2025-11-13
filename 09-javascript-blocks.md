# Paso 9: Bloques de JavaScript Puro

## Objetivo
Implementar soporte para bloques de JavaScript puro y sin restricciones.

---

## Diseño de Sintaxis

Propuestas:
```pug
js.
  function greet(name) {
    return `Hello, ${name}!`;
  }
  const result = greet('World');

script.
  // JavaScript puro aquí
  if (condition) {
    doSomething();
  }
```

---

## Tareas

### 9.1 Extender Tokenizer
- Reconocer marcador de bloque JS (ej: `js.`)
- Tokenizar bloques completos sin parsear contenido

### 9.2 Extender AST
- Crear `JsBlockNode`
- Almacenar código JavaScript como string

### 9.3 Evaluar Engines JavaScript
Opciones:
- **QuickJS** (embeddable, pequeño)
- **Duktape** (embeddable, estable)
- **V8** (potente pero pesado)
- Custom interpreter (mucho trabajo)

### 9.4 Integrar Engine
- Crear bindings Zig
- API de evaluación
- Compartir contexto con template

### 9.5 Sistema de Sandboxing
- Limitar acceso a sistema de archivos
- Timeout para ejecución
- Límites de memoria

### 9.6 Tests de Integración
- Definir funciones en JS, usarlas en template
- Variables compartidas
- Tests de seguridad

---

## Entregables
- Soporte completo para JavaScript puro
- Documentación de sintaxis
- Tests de seguridad

---

## Siguiente Paso
**10-toml-parser.md** para integrar parser TOML.
