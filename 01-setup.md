# Paso 1: Configuración del Proyecto

## Prerequisito
**IMPORTANTE:** Antes de comenzar este paso, debes tener Zig 0.15.2 instalado y verificado. Ver **00-prerequisites.md**

Verificar:
```bash
zig version
# Debe mostrar: 0.15.2
```

## Objetivo
Establecer la estructura base del proyecto y configuración de Zig 0.15.2

## Descripción
Este es el primer paso fundamental para comenzar el proyecto zig-pug. Crearemos la estructura de directorios, inicializaremos el proyecto Zig y configuraremos el sistema de testing básico usando Zig 0.15.2.

---

## Tareas Detalladas

### 1.1 Estructura de Directorios
Crear la siguiente estructura:

```
zig-pug/
├── src/
│   ├── main.zig              # Punto de entrada
│   ├── tokenizer.zig         # Tokenizer/Lexer
│   ├── parser.zig            # Parser
│   ├── ast.zig               # Abstract Syntax Tree
│   ├── compiler.zig          # Compilador a HTML
│   ├── runtime.zig           # Runtime de ejecución
│   ├── toml.zig              # Parser TOML (o integración)
│   └── utils.zig             # Utilidades
├── tests/
│   ├── tokenizer_test.zig
│   ├── parser_test.zig
│   ├── compiler_test.zig
│   └── integration_test.zig
├── examples/
│   ├── basic/
│   ├── advanced/
│   └── toml-integration/
├── docs/
│   ├── api/
│   ├── tutorials/
│   └── reference/
├── build.zig                 # Build system
├── build.zig.zon            # Dependencias (opcional)
├── README.md
├── LICENSE
├── .gitignore
├── PUG.md                    # Ya creado
└── PLAN.md                   # Ya creado
```

### 1.2 Inicializar Proyecto Zig
```bash
zig init-exe
```

Modificar `build.zig` para:
- Configurar el ejecutable principal
- Agregar sistema de tests
- Configurar opciones de optimización
- Agregar targets de build

### 1.3 Configurar Sistema de Testing
- Agregar test runner en `build.zig`
- Crear template básico para tests
- Configurar coverage (opcional)
- Documentar cómo ejecutar tests

### 1.4 Establecer Convenciones de Código
- Estilo de código (camelCase, snake_case, etc.)
- Comentarios y documentación inline
- Naming conventions
- Organización de imports
- Manejo de errores

### 1.5 Crear README Básico
Incluir:
- Descripción del proyecto
- Características principales
- Diferencias con Pug original
- Instalación (placeholder)
- Uso básico (placeholder)
- Estado del proyecto
- Contribuciones
- Licencia

### 1.6 Configurar Git (Opcional)
```bash
git init
git add .
git commit -m "Initial commit: Project setup"
```

Crear `.gitignore`:
```
zig-cache/
zig-out/
*.o
*.so
*.dylib
*.dll
*.exe
.vscode/
.idea/
*.swp
*.swo
*~
```

---

## Código Inicial

### build.zig Básico
```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Ejecutable principal
    const exe = b.addExecutable(.{
        .name = "zig-pug",
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    b.installArtifact(exe);

    // Run command
    const run_cmd = b.addRunArtifact(exe);
    run_cmd.step.dependOn(b.getInstallStep());
    if (b.args) |args| {
        run_cmd.addArgs(args);
    }
    const run_step = b.step("run", "Run the app");
    run_step.dependOn(&run_cmd.step);

    // Tests
    const tests = b.addTest(.{
        .root_source_file = .{ .path = "src/main.zig" },
        .target = target,
        .optimize = optimize,
    });
    const run_tests = b.addRunArtifact(tests);
    const test_step = b.step("test", "Run unit tests");
    test_step.dependOn(&run_tests.step);
}
```

### src/main.zig Básico (Zig 0.15.2)
```zig
const std = @import("std");

pub fn main() !void {
    // Zig 0.15.x usa buffered I/O por defecto
    const stdout = std.io.getStdOut().writer();
    var buffered = std.io.bufferedWriter(stdout);
    const writer = buffered.writer();

    try writer.print("zig-pug v0.1.0\n", .{});
    try writer.print("Template engine inspired by Pug\n", .{});
    try writer.print("Built with Zig 0.15.2\n", .{});

    // IMPORTANTE en 0.15.x: siempre flush el buffer
    try buffered.flush();
}

test "basic test" {
    try std.testing.expectEqual(@as(i32, 42), 42);
}
```

---

## Validación

### Checklist
- [ ] Estructura de directorios creada
- [ ] `build.zig` configurado correctamente
- [ ] Proyecto compila: `zig build`
- [ ] Tests ejecutan: `zig build test`
- [ ] `zig build run` funciona
- [ ] README.md creado
- [ ] .gitignore configurado
- [ ] Licencia agregada

### Comandos de Validación
```bash
# Compilar
zig build

# Ejecutar
zig build run

# Tests
zig build test

# Limpiar
rm -rf zig-cache zig-out
```

---

## Entregables
1. Proyecto Zig compilable
2. Sistema de tests funcional
3. Estructura de directorios clara
4. README básico
5. Build system configurado

---

## Siguiente Paso
Una vez completado este paso, continuar con **02-architecture.md** para diseñar la arquitectura del sistema.

---

## Notas
- **CRÍTICO:** Usar Zig 0.15.2 específicamente (ver 00-prerequisites.md)
- Versiones anteriores a 0.15 NO son compatibles
- Zig 0.15.x tiene cambios importantes en I/O y build system
- Considerar configurar CI/CD desde el inicio (GitHub Actions)
- Mantener documentación actualizada desde el día 1
- Este setup es la base de todo el proyecto - hacerlo bien
