# Condicionales en Pug

Guía completa sobre sentencias condicionales y expresiones case en zig-pug.

---

## Condicionales

### Sentencia If

```pug
//- Variable: isLoggedIn = true
if isLoggedIn
  p Welcome back!
```

Salida (cuando es verdadero):
```html
<p>Welcome back!</p>
```

### If-Else

```pug
//- Variable: hasPermission = false
if hasPermission
  button Edit
else
  button View Only
```

Salida:
```html
<button>View Only</button>
```

### If-Else If-Else

```pug
//- Variable: role = "admin"
if role === "admin"
  p Admin Panel
else if role === "moderator"
  p Moderator Tools
else
  p User Dashboard
```

Salida:
```html
<p>Admin Panel</p>
```

### Unless

```pug
//- Variable: isDisabled = false
unless isDisabled
  button Click Me
```

Salida:
```html
<button>Click Me</button>
```

---

## Sentencias Case

Las sentencias case proporcionan una alternativa más limpia a múltiples condiciones if-else cuando se verifica un solo valor contra múltiples posibilidades.

### Case Básico

```pug
//- Variable: status = "success"
case status
  when "success"
    p.success Operación completada exitosamente
  when "error"
    p.error Algo salió mal
  when "pending"
    p.warning Por favor espere...
  default
    p.info Estado desconocido
```

Salida:
```html
<p class="success">Operación completada exitosamente</p>
```

### Case con Múltiples Valores

Puedes comparar múltiples valores en una sola cláusula `when`:

```pug
//- Variable: day = "Saturday"
case day
  when "Monday"
  when "Tuesday"
  when "Wednesday"
  when "Thursday"
  when "Friday"
    p Es un día de semana
  when "Saturday"
  when "Sunday"
    p ¡Es fin de semana!
  default
    p Día inválido
```

Salida:
```html
<p>¡Es fin de semana!</p>
```

### Case con Propiedades de Objetos

Accede a propiedades de objetos en expresiones case:

```pug
//- Variable: user = {role: "admin", status: "active"}
case user.role
  when "admin"
    p Panel de Administrador
  when "moderator"
    p Herramientas de Moderador
  when "user"
    p Panel de Usuario
  default
    p Vista de Invitado
```

Salida:
```html
<p>Panel de Administrador</p>
```

### Case con Propiedades Anidadas

```pug
//- Variable: response = {data: {status: "ok", code: 200}}
case response.data.status
  when "ok"
    p.success Solicitud exitosa
  when "error"
    p.error Solicitud fallida
  default
    p.warning Respuesta desconocida
```

Salida:
```html
<p class="success">Solicitud exitosa</p>
```

### Case con Expresiones

```pug
//- Variables: score = 85
case true
  when score >= 90
    p Calificación: A
  when score >= 80
    p Calificación: B
  when score >= 70
    p Calificación: C
  default
    p Calificación: F
```

Salida:
```html
<p>Calificación: B</p>
```

### Case con Bloques Complejos

```pug
//- Variable: userType = "premium"
case userType
  when "premium"
    div.premium-box
      h2 Características Premium
      ul
        li Sin anuncios
        li Soporte prioritario
        li Herramientas avanzadas
  when "basic"
    div.basic-box
      h2 Características Básicas
      p Acceso estándar
  default
    div.guest-box
      p Por favor inicie sesión
```

Salida:
```html
<div class="premium-box">
  <h2>Características Premium</h2>
  <ul>
    <li>Sin anuncios</li>
    <li>Soporte prioritario</li>
    <li>Herramientas avanzadas</li>
  </ul>
</div>
```

### Case con Valores de Cadena

```pug
//- Variable: color = "blue"
case color
  when "red"
    div.bg-red Fondo rojo
  when "blue"
    div.bg-blue Fondo azul
  when "green"
    div.bg-green Fondo verde
  default
    div.bg-default Fondo predeterminado
```

Salida:
```html
<div class="bg-blue">Fondo azul</div>
```

---

## Ver También

- [PUG-SYNTAX.md](../PUG-SYNTAX.md) - Referencia completa de sintaxis Pug
- [CONDITIONALS-LOOPS.md](../en/CONDITIONALS-LOOPS.md) - Guía de control de flujo
- [VARIABLES.md](../en/VARIABLES.md) - Trabajando con variables
- [SYNTAX-BASICS.md](../en/SYNTAX-BASICS.md) - Guía de sintaxis básica
