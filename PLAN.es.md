# Plan de Desarrollo de zig-pug

[English](PLAN.md) | Español

## 🎯 Visión del Proyecto

zig-pug busca ser la implementación de motor de templates Pug más rápida y completa, aprovechando el rendimiento y características de seguridad de Zig mientras mantiene compatibilidad total con la sintaxis de Pug.

---

## ✅ Características Completadas (v0.3.x)

### Motor de Templates Principal
- ✅ Parser completo de sintaxis Pug
- ✅ Renderizado de tags con atributos
- ✅ Shorthand para clases e IDs (`.class`, `#id`)
- ✅ Soporte de doctype
- ✅ Contenido de texto e interpolación
- ✅ Escapado HTML y seguridad

### Integración con JavaScript
- ✅ Integración del motor JavaScript mujs
- ✅ Soporte de JavaScript ES5.1
- ✅ Interpolación de variables (`#{variable}`)
- ✅ Expresiones JavaScript en templates
- ✅ Llamadas a métodos y operadores

### Flujo de Control
- ✅ Condicionales: `if`, `else if`, `else`, `unless`
- ✅ Loops: `each` con arrays
- ✅ Variables de loop (`item`, `index`)
- ✅ Loops while

### Características Avanzadas
- ✅ Mixins con argumentos
- ✅ Herencia de templates (`extends`, `block`)
- ✅ Soporte de variables JSON (strings, números, booleanos, arrays, objetos)
- ✅ Valores dinámicos de atributos
- ✅ Comentarios de documentación (`//!`)
- ✅ Código con/sin buffer (`=`, `!=`, `-`)

### Soporte de Plataformas
- ✅ Binario CLI (zpug)
- ✅ Addon N-API para Node.js
- ✅ Compatibilidad con Bun.js
- ✅ Multi-plataforma (Linux, macOS, Windows)
- ✅ Soporte Termux/Android (solo CLI)

### Testing y Calidad
- ✅ 87 tests unitarios exhaustivos
- ✅ Soporte completo UTF-8 (emoji, acentos, todo Unicode)
- ✅ Seguridad de memoria (garantías de Zig)
- ✅ Optimizaciones de rendimiento

---

## 🚧 En Progreso (v0.4.x)

### Documentación
- 🔄 Referencia completa de API
- 🔄 Colección extensa de ejemplos
- 🔄 Guía de migración desde Pug.js
- 🔄 Documentación de benchmarks de rendimiento

### Sistema de Compilación
- 🔄 Binarios precompilados para npm (en progreso)
- 🔄 Mejoras en GitHub Actions CI/CD
- 🔄 Compilaciones automáticas multi-plataforma

---

## 📋 Características Planificadas

### Corto Plazo (v0.4.x - v0.5.x)

#### Características de Templates
- [ ] **Includes** - `include template.pug`
- [ ] **Filtros** - `:markdown`, `:coffee`, filtros personalizados
- [ ] **Declaraciones Case** - `case`/`when` para condicionales más limpios
- [ ] **Bloques en Mixins** - Pasar bloques de contenido a mixins
- [ ] **Interpolación de atributos** - `a(href="/user/#{id}")`

#### Mejoras JavaScript
- [ ] **Métodos de Objetos/Arrays** - `.push()`, `.map()`, `.filter()`
- [ ] **JSON.parse/stringify**
- [ ] **Objeto Math** - `Math.random()`, `Math.floor()`, etc.
- [ ] **Métodos String** - `.split()`, `.join()`, `.replace()`

#### Rendimiento
- [ ] **Caché de templates** - Compilar una vez, renderizar muchas
- [ ] **Compilación parcial** - Pre-compilar partes estáticas
- [ ] **Memory pooling** - Reducir asignaciones
- [ ] **Optimizaciones SIMD** - Operaciones de string más rápidas

### Mediano Plazo (v0.6.x - v0.8.x)

#### Características Avanzadas
- [ ] **Compilación de templates** - Generar funciones standalone
- [ ] **Source maps** - Mejor debugging de errores
- [ ] **Modo watch** - Auto-recompilar al cambiar
- [ ] **Sistema de plugins** - Tags, filtros, funciones personalizadas

#### Ecosistema
- [ ] **Integración Express.js** - Adaptador de view engine
- [ ] **Plugin Vite** - Soporte HMR para templates Pug
- [ ] **Webpack loader** - Compilación en tiempo de build
- [ ] **Soporte Deno** - Módulo nativo de Deno

#### Experiencia de Desarrollador
- [ ] **Extensión VS Code** - Resaltado de sintaxis, snippets, IntelliSense
- [ ] **Language server** - Auto-completado, ir a definición
- [ ] **Formateador** - Formateo automático de código
- [ ] **Linter** - Detectar errores antes de compilar

### Largo Plazo (v1.0.x+)

#### Producción Lista
- [ ] **100% compatibilidad con Pug.js** - Pasar todos los tests oficiales
- [ ] **Auditoría de seguridad** - Revisión profesional
- [ ] **Benchmarks de rendimiento** - vs Pug.js, vs otros motores
- [ ] **Garantías de estabilidad** - Versionado semántico

#### Optimizaciones Avanzadas
- [ ] **Análisis estático** - Optimizaciones en tiempo de compilación
- [ ] **Tree shaking** - Eliminar mixins/variables no usados
- [ ] **Minificación** - Output lo más pequeño posible
- [ ] **Renderizado en streaming** - Para documentos grandes

#### Características Empresariales
- [ ] **Directivas personalizadas** - Extensiones específicas de frameworks
- [ ] **Templates asíncronos** - Esperar datos asíncronos
- [ ] **Renderizado paralelo** - Compilación multi-hilo
- [ ] **Funciones cloud** - Guías de despliegue serverless

---

## 🎨 Principios de Diseño

1. **Rendimiento Primero** - Cada característica debe ser rápida
2. **Seguridad** - Aprovechar verificaciones en tiempo de compilación de Zig
3. **Simplicidad** - Código claro y mantenible
4. **Compatibilidad** - Funcionar donde funcione Node.js
5. **Cero Dependencias** - Solo Zig + mujs embebido
6. **Gran DX** - Excelentes mensajes de error y herramientas

---

## 📊 Metas de Benchmarks

Rendimiento objetivo vs Pug.js:

| Métrica | Actual | Meta |
|---------|--------|------|
| **Compilación** | ~2x más rápido | 5x más rápido |
| **Renderizado** | ~3x más rápido | 10x más rápido |
| **Memoria** | ~50% menos | 70% menos |
| **Tamaño binario** | 2.4 MB | < 2 MB |

---

## 🤝 Contribuir

¡Aceptamos contribuciones! Áreas prioritarias:

1. **Documentación** - Ejemplos, guías, docs de API
2. **Testing** - Más casos de prueba, casos extremos
3. **Características** - Implementar items del roadmap
4. **Bug fixes** - Reportar y corregir issues
5. **Rendimiento** - Optimizar rutas críticas

Ver [CONTRIBUTING.md](CONTRIBUTING.md) para lineamientos.

---

## 📅 Cronograma de Lanzamientos

- **v0.4.x** - Q1 2026 - Documentación, binarios precompilados
- **v0.5.x** - Q2 2026 - Includes, filtros, caché
- **v0.6.x** - Q3 2026 - Plugins, integración Express
- **v0.7.x** - Q4 2026 - Optimizaciones avanzadas
- **v1.0.0** - 2027 - Listo para producción, compatibilidad completa

*El cronograma es tentativo y sujeto a cambios*

---

## 🔗 Proyectos Relacionados

- [Pug.js](https://pugjs.org/) - Implementación original en JavaScript
- [pug-rs](https://github.com/tlack/pug-rs) - Implementación en Rust
- [pug-php](https://github.com/pug-php/pug) - Implementación en PHP

---

## 📝 Notas

Este es un documento vivo. El roadmap evoluciona basándose en:
- Feedback de usuarios y solicitudes de características
- Resultados de profiling de rendimiento
- Cambios en el ecosistema (nuevas versiones de Node.js, etc.)
- Tiempo de desarrollo disponible

¿Tienes ideas? ¡Abre un issue o discusión en [GitHub](https://github.com/carlos-sweb/zig-pug/discussions)!

---

**Última Actualización:** 2025-12-16
**Versión Actual:** 0.3.7
