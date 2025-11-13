# Paso 17: CLI y API Pública

## Objetivo
Crear herramientas de línea de comandos y API pública del proyecto.

---

## Tareas

### 17.1 API Pública

```zig
pub const ZigPug = struct {
    allocator: std.mem.Allocator,
    options: Options,

    pub const Options = struct {
        basedir: []const u8 = ".",
        pretty: bool = false,
        cache: bool = true,
        filters: ?FilterRegistry = null,
    };

    pub fn init(allocator: std.mem.Allocator, options: Options) ZigPug {
        return .{
            .allocator = allocator,
            .options = options,
        };
    }

    pub fn render(self: *ZigPug, template: []const u8, data_toml: []const u8) ![]const u8 {
        // Parse template
        var parser = try Parser.init(self.allocator, template);
        const ast = try parser.parse();

        // Parse data
        const toml_data = try parseToml(self.allocator, data_toml);
        var context = try tomlToContext(self.allocator, toml_data);

        // Compile
        var compiler = Compiler.init(self.allocator);
        return try compiler.compile(ast, &context);
    }

    pub fn renderFile(self: *ZigPug, template_path: []const u8, data_path: []const u8) ![]const u8 {
        const template = try std.fs.cwd().readFileAlloc(self.allocator, template_path, 1024 * 1024);
        const data = try std.fs.cwd().readFileAlloc(self.allocator, data_path, 1024 * 1024);
        return try self.render(template, data);
    }
};
```

### 17.2 CLI

```zig
pub fn main() !void {
    var gpa = std.heap.GeneralPurposeAllocator(.{}){};
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    const args = try std.process.argsAlloc(allocator);
    defer std.process.argsFree(allocator, args);

    if (args.len < 2) {
        try printUsage();
        return;
    }

    const command = args[1];
    if (std.mem.eql(u8, command, "compile")) {
        try compileCommand(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "watch")) {
        try watchCommand(allocator, args[2..]);
    } else if (std.mem.eql(u8, command, "validate")) {
        try validateCommand(allocator, args[2..]);
    } else {
        std.debug.print("Unknown command: {s}\n", .{command});
    }
}
```

#### Comando compile
```bash
zig-pug compile template.pug --data data.toml --output output.html
```

#### Comando watch
```bash
zig-pug watch templates/ --output dist/
```

#### Comando validate
```bash
zig-pug validate template.pug
```

### 17.3 Sistema de Configuración

`zig-pug.toml`:
```toml
[options]
basedir = "templates"
pretty = true
cache = true

[paths]
templates = "src/templates"
output = "dist"

[filters]
markdown = "enabled"
```

### 17.4 Sistema de Plugins

```zig
pub const Plugin = struct {
    name: []const u8,
    initFn: *const fn(*ZigPug) anyerror!void,
};

pub fn loadPlugin(self: *ZigPug, plugin: Plugin) !void {
    try plugin.initFn(self);
}
```

---

## Entregables
- CLI funcional con comandos principales
- API pública documentada
- Sistema de configuración
- Documentación de uso

---

## Siguiente Paso
**18-testing-examples.md** para testing y ejemplos.
