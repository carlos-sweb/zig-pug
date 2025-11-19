# Usando zig-pug como Dependencia de Zig

zig-pug está configurado para usarse con el gestor de paquetes de Zig (Zig Package Manager).

## Requisitos

- **Zig 0.13.0** o superior (recomendado: 0.15.2)

## Instalación

### Método 1: Desde URL (Recomendado)

Agrega zig-pug a tu `build.zig.zon`:

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .fingerprint = 0x...,  // Tu fingerprint
    .dependencies = .{
        .zig_pug = .{
            .url = "https://github.com/yourusername/zig-pug/archive/refs/tags/v0.2.0.tar.gz",
            .hash = "...",  // Se obtiene al ejecutar `zig build`
        },
    },
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

### Método 2: Desde Path Local

Para desarrollo local:

```zig
.dependencies = .{
    .zig_pug = .{
        .path = "../zig-pug",
    },
},
```

## Configurar build.zig

En tu `build.zig`, importa el módulo:

```zig
const std = @import("std");

pub fn build(b: *std.Build) void {
    const target = b.standardTargetOptions(.{});
    const optimize = b.standardOptimizeOption(.{});

    // Obtener el módulo zig-pug
    const zig_pug_dep = b.dependency("zig_pug", .{
        .target = target,
        .optimize = optimize,
    });
    const zig_pug_module = zig_pug_dep.module("zig_pug");

    // Crear tu ejecutable
    const exe = b.addExecutable(.{
        .name = "my_app",
        .root_module = b.createModule(.{
            .root_source_file = b.path("src/main.zig"),
            .target = target,
            .optimize = optimize,
        }),
    });

    // Agregar zig-pug como dependencia
    exe.root_module.addImport("zig_pug", zig_pug_module);

    // También necesitas linkear con mujs
    exe.addObjectFile(zig_pug_dep.path("vendor/mujs/libmujs.a"));
    exe.addIncludePath(zig_pug_dep.path("vendor/mujs"));

    b.installArtifact(exe);
}
```

## Uso en tu Código

Una vez configurado, puedes importar y usar zig-pug:

```zig
const std = @import("std");
const zig_pug = @import("zig_pug");

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    // Crear runtime
    var runtime = try zig_pug.Runtime.init(allocator);
    defer runtime.deinit();

    // Establecer variables
    try runtime.setString("name", "Alice");
    try runtime.setNumber("age", 25);
    try runtime.setBool("isActive", true);

    // Compilar template
    const template =
        \\div.greeting
        \\  h1 Hello #{name}!
        \\  p Age: #{age}
        \\  if isActive
        \\    p Status: Active
    ;

    // Tokenizar
    var tokenizer = zig_pug.Tokenizer.init(template);
    const tokens = try tokenizer.tokenize(allocator);
    defer allocator.free(tokens);

    // Parsear
    var parser = try zig_pug.Parser.init(allocator, tokens);
    defer parser.deinit();
    const ast = try parser.parse();

    // Compilar a HTML
    var compiler = zig_pug.Compiler.init(allocator, &runtime);
    const html = try compiler.compile(ast);
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

## API Disponible

### Módulos Públicos

El módulo `zig_pug` exporta:

- **`Tokenizer`** - Tokeniza código Pug
- **`Parser`** - Parsea tokens a AST
- **`Compiler`** - Compila AST a HTML
- **`Runtime`** - Runtime JavaScript (mujs)
- **`ast`** - Definiciones del AST

### Ejemplo Completo

```zig
const std = @import("std");
const zig_pug = @import("zig_pug");

const Tokenizer = zig_pug.Tokenizer;
const Parser = zig_pug.Parser;
const Compiler = zig_pug.Compiler;
const Runtime = zig_pug.Runtime;

pub fn compile(allocator: std.mem.Allocator, template: []const u8, vars: anytype) ![]u8 {
    // Runtime
    var runtime = try Runtime.init(allocator);
    defer runtime.deinit();

    // Establecer variables desde struct
    inline for (std.meta.fields(@TypeOf(vars))) |field| {
        const value = @field(vars, field.name);
        switch (@TypeOf(value)) {
            []const u8, [:0]const u8 => try runtime.setString(field.name, value),
            i32, i64, f32, f64 => try runtime.setNumber(field.name, @as(f64, @floatFromInt(value))),
            bool => try runtime.setBool(field.name, value),
            else => {},
        }
    }

    // Pipeline: Tokenize -> Parse -> Compile
    var tokenizer = Tokenizer.init(template);
    const tokens = try tokenizer.tokenize(allocator);
    defer allocator.free(tokens);

    var parser = try Parser.init(allocator, tokens);
    defer parser.deinit();
    const ast = try parser.parse();

    var compiler = Compiler.init(allocator, &runtime);
    return try compiler.compile(ast);
}

pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const template =
        \\doctype html
        \\html(lang="es")
        \\  head
        \\    title #{title}
        \\  body
        \\    h1 #{greeting}
        \\    p Welcome, #{name}!
    ;

    const html = try compile(allocator, template, .{
        .title = "Mi Página",
        .greeting = "Hola Mundo",
        .name = "Usuario",
    });
    defer allocator.free(html);

    std.debug.print("{s}\n", .{html});
}
```

## Estructura del Proyecto de Ejemplo

```
my-project/
├── build.zig
├── build.zig.zon
└── src/
    └── main.zig
```

### build.zig.zon

```zig
.{
    .name = .my_project,
    .version = "0.1.0",
    .fingerprint = 0xabc123...,
    .dependencies = .{
        .zig_pug = .{
            .url = "https://github.com/yourusername/zig-pug/archive/v0.2.0.tar.gz",
            .hash = "122...",
        },
    },
    .paths = .{
        "build.zig",
        "build.zig.zon",
        "src",
    },
}
```

### build.zig

Ver ejemplo completo arriba.

## Obtener el Hash

La primera vez que ejecutes `zig build`, Zig te dará un error con el hash correcto:

```bash
$ zig build
error: hash mismatch
note: expected: 122...
```

Copia el hash y agrégalo a tu `build.zig.zon`.

## Actualizar Versión

Para actualizar a una nueva versión:

1. Cambia la URL al nuevo tag
2. Elimina el hash actual
3. Ejecuta `zig build` para obtener el nuevo hash
4. Agrega el nuevo hash

## Limitaciones

### mujs (JavaScript Engine)

zig-pug incluye mujs como librería C precompilada. Actualmente:

- ✅ Funciona en Linux x86_64, aarch64
- ✅ Funciona en macOS
- ⚠️ Windows puede requerir recompilar mujs
- ⚠️ Otras arquitecturas pueden necesitar compilar mujs manualmente

### Cross-compilation

Para cross-compile, necesitas el `libmujs.a` compilado para la arquitectura objetivo.

## Troubleshooting

### "hash mismatch"

Esto es normal la primera vez. Usa el hash que Zig sugiere.

### "unable to find libmujs.a"

Asegúrate de agregar las líneas:

```zig
exe.addObjectFile(zig_pug_dep.path("vendor/mujs/libmujs.a"));
exe.addIncludePath(zig_pug_dep.path("vendor/mujs"));
```

### Error de linking

Si ves errores de símbolos no encontrados relacionados con math (`sin`, `cos`, etc.), agrega:

```zig
exe.linkLibC();
```

## Recursos

- **Zig Package Manager Docs:** https://ziglang.org/documentation/master/#Package-Management
- **zig-pug GitHub:** https://github.com/yourusername/zig-pug
- **zig-pug API Reference:** [docs/API-REFERENCE.md](API-REFERENCE.md)

## Soporte

Si tienes problemas usando zig-pug como dependencia:

1. Verifica que estés usando Zig 0.13.0+
2. Revisa que el hash sea correcto
3. Abre un issue en GitHub con el error completo

---

**¡Disfruta usando zig-pug en tu proyecto Zig!** 🚀
