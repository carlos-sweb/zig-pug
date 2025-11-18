# Índice de Documentación - zig-pug

Guía completa de toda la documentación disponible para zig-pug.

## 🎯 Para Empezar

### 1. [README.md](README.md) - **EMPIEZA AQUÍ**
**Vista general del proyecto**

El README principal es tu punto de partida. Incluye:
- ✨ Características principales
- 📦 Instalación rápida
- 🚀 Ejemplo completo de uso
- 📚 Sintaxis Pug soportada
- 🔧 API de programación
- ⚙️ Motor JavaScript (mujs)
- 📊 Estado del proyecto

**Léelo primero** para entender qué es zig-pug y qué puede hacer.

---

### 2. [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) - **TUTORIAL COMPLETO**
**Guía paso a paso para principiantes**

Tutorial práctico en 8 pasos:
1. ⚙️ Instalación y configuración
2. 📝 Tu primer template
3. 🎨 Agregar variables
4. 🔧 Usar métodos JavaScript
5. ✨ Condicionales
6. 🎯 Trabajar con objetos
7. 🧩 Mixins (componentes)
8. 📦 Ejemplo completo real

Cada paso incluye:
- Código completo funcional
- Explicaciones claras
- Output esperado
- Problemas comunes y soluciones

**Perfecto para**: Aprender desde cero, entender cómo funciona todo.

---

## 📚 Documentación de Referencia

### 3. [PUG.md](PUG.md) - **REFERENCIA DE PUG**
**Especificación completa de Pug.js**

Referencia original de todas las características de Pug:
- Tags y atributos
- Interpolación
- Condicionales e iteración
- Mixins y herencia
- Filtros
- Includes

**Útil para**: Consultar sintaxis específica de Pug.

---

## 🎨 Ejemplos Prácticos

### 4. [examples/](examples/) - **EJEMPLOS LISTOS PARA USAR**

#### [examples/README.md](examples/README.md)
Guía de los ejemplos con instrucciones de uso.

#### Ejemplos incluidos:

**[01-basic.pug](examples/01-basic.pug)** - Tags y Atributos Básicos
```pug
div.container
  h1 Título
  p.texto Párrafo con clase
```
- Tags simples
- Clases e IDs
- Atributos

---

**[02-interpolation.pug](examples/02-interpolation.pug)** - Interpolación JavaScript
```pug
p #{name.toUpperCase()}
p Edad: #{age + 1}
```
- Variables
- Métodos de strings/numbers
- Expresiones aritméticas
- Operador ternario

---

**[03-conditionals.pug](examples/03-conditionals.pug)** - Condicionales
```pug
if isAdmin
  p Panel de Admin
else
  p Acceso denegado
```
- if/else/else if
- unless
- Expresiones en condiciones

---

**[04-mixins.pug](examples/04-mixins.pug)** - Componentes Reutilizables
```pug
mixin card(title, text)
  div.card
    h3= title
    p= text

+card('Hola', 'Mundo')
```
- Definir mixins
- Llamar mixins
- Parámetros

---

**[05-complete-example.pug](examples/05-complete-example.pug)** - Aplicación Completa
```pug
// Dashboard completo con navegación,
// estadísticas, roles de usuario,
// mixins complejos, etc.
```
- Ejemplo real del mundo real
- Combina todas las características
- Best practices

---

## ⚙️ Documentación Técnica

### 5. [MUJS-INTEGRATION.md](MUJS-INTEGRATION.md) - **INTEGRACIÓN JAVASCRIPT**
**Cómo funciona el motor JavaScript**

Detalles completos de la integración de mujs:
- ✅ Qué se completó
- 📁 Estructura de archivos
- 🔧 API de mujs
- 📊 Capacidades soportadas
- 💡 Ejemplos de uso
- ⚠️ Limitaciones conocidas
- 📈 Comparación antes/después

**Útil para**: Entender el motor JavaScript, ver qué funciona.

---

### 6. [MUJS-ANALYSIS.md](MUJS-ANALYSIS.md) - **ANÁLISIS TÉCNICO**
**Por qué mujs en lugar de QuickJS**

Análisis completo de la decisión de usar mujs:
- 📊 Comparación técnica detallada
- ✅ Resultados de compilación
- 🧪 Pruebas funcionales
- 💪 Ventajas y desventajas
- 📝 Plan de migración
- 🎯 Recomendación final

**Útil para**: Decisiones técnicas, entender arquitectura.

---

### 7. [LIBRARY-USAGE.md](LIBRARY-USAGE.md) - **USO COMO LIBRERÍA C**
**Exportar zig-pug para otros lenguajes**

Cómo usar zig-pug como librería desde C, Python, etc.:
- 🔧 Compilar librerías (.a y .so)
- 📖 API Reference completa
- 💻 Ejemplos en C y Python
- 🌍 Uso desde otros lenguajes
- ⚠️ Limitaciones y notas

**Útil para**: Integrar zig-pug en otros proyectos.

---

## 📋 Planificación y Desarrollo

### 8. [PLAN.md](PLAN.md) - **ROADMAP DEL PROYECTO**
**Plan completo de desarrollo en 23 pasos**

Roadmap detallado del proyecto:
- Fases de desarrollo
- Pasos completados ✅
- Pasos pendientes ⬜
- Timeline estimado

**Útil para**: Contribuir, ver qué falta, planificar.

---

### 9. Documentos de Pasos (00-23-*.md)
**Documentación de cada fase de desarrollo**

Cada paso del plan tiene su documento:
- `00-prerequisites.md` - Requisitos
- `01-setup.md` - Configuración
- `02-architecture.md` - Arquitectura
- ... hasta `23-ecosystem.md`

**Útil para**: Desarrollo, contribuciones, entender implementación.

---

## 🔍 Guía de Lectura por Objetivo

### Si quieres: **Usar zig-pug rápidamente**
1. Lee: [README.md](README.md) - Vista general
2. Sigue: [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md) - Tutorial
3. Copia: [examples/02-interpolation.pug](examples/02-interpolation.pug) - Ejemplo básico
4. Consulta: [README.md - Sintaxis](README.md#-sintaxis-pug-soportada) - Referencia rápida

### Si quieres: **Entender cómo funciona**
1. Lee: [README.md - Arquitectura](README.md#️-arquitectura)
2. Estudia: [MUJS-INTEGRATION.md](MUJS-INTEGRATION.md)
3. Revisa: [02-architecture.md](02-architecture.md)
4. Explora: Código fuente en `src/`

### Si quieres: **Ver ejemplos**
1. Abre: [examples/](examples/)
2. Lee: [examples/README.md](examples/README.md)
3. Prueba: Cada ejemplo de 01 a 05
4. Modifica: Experimenta con los ejemplos

### Si quieres: **Contribuir al proyecto**
1. Lee: [PLAN.md](PLAN.md) - Ver qué falta
2. Revisa: Documentos de pasos (00-23)
3. Entiende: [02-architecture.md](02-architecture.md)
4. Consulta: Código en `src/`

### Si quieres: **Usar como librería en C/Python**
1. Lee: [LIBRARY-USAGE.md](LIBRARY-USAGE.md)
2. Compila: `zig build lib`
3. Copia: [examples/example.c](examples/example.c)
4. Adapta: Para tu lenguaje

### Si quieres: **Entender las decisiones técnicas**
1. Lee: [MUJS-ANALYSIS.md](MUJS-ANALYSIS.md) - Por qué mujs
2. Revisa: [MUJS-INTEGRATION.md](MUJS-INTEGRATION.md) - Qué se hizo
3. Consulta: [ALTERNATIVAS-QUICKJS.md](ALTERNATIVAS-QUICKJS.md) - Qué se consideró

---

## 📊 Mapa Conceptual

```
┌─────────────────────────────────────────────────────────────┐
│                      DOCUMENTACIÓN                          │
└─────────────────────────────────────────────────────────────┘
                           │
        ┌──────────────────┼──────────────────┐
        │                  │                  │
    ┌───▼───┐         ┌────▼────┐       ┌────▼────┐
    │ INICIO│         │  TUTORIALES  │       │ REFERENCIA  │
    └───┬───┘         └────┬────┘       └────┬────┘
        │                  │                  │
        │           ┌──────┴──────┐          │
        │           │             │          │
    README.md   GETTING-     examples/   PUG.md
                STARTED.md                 │
                                     API docs

┌─────────────────────────────────────────────────────────────┐
│                    DOCUMENTACIÓN TÉCNICA                    │
└─────────────────────────────────────────────────────────────┘
        │
        ├─ MUJS-INTEGRATION.md (Cómo funciona JS)
        ├─ MUJS-ANALYSIS.md (Por qué mujs)
        ├─ LIBRARY-USAGE.md (Uso como librería)
        └─ PLAN.md + pasos (Desarrollo)
```

---

## 🆕 ¿Qué Leer Ahora?

**Si eres nuevo**: Empieza con [README.md](README.md) y luego [docs/GETTING-STARTED.md](docs/GETTING-STARTED.md)

**Si tienes prisa**: Ve directo a [examples/](examples/) y copia un ejemplo

**Si quieres profundizar**: Lee [MUJS-INTEGRATION.md](MUJS-INTEGRATION.md)

**Si quieres contribuir**: Revisa [PLAN.md](PLAN.md)

---

## 📞 ¿Necesitas Ayuda?

- **GitHub Issues**: Para bugs y preguntas técnicas
- **GitHub Discussions**: Para preguntas generales
- **Esta documentación**: Para la mayoría de las respuestas

---

**Última actualización**: Noviembre 18, 2025
**Versión**: zig-pug 0.2.0 con mujs
