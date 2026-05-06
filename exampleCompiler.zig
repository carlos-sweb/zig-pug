//! exampleCompiler.zig — HTML output for zig-pug compiler
//!
//! Compila templates de ejemplo y muestra el HTML generado.
//! Usado para verificar que el compiler produce el HTML correcto
//! antes de integrarlo en la CLI.
//!
//! Uso:
//!   zig build exampleCompiler

const std = @import("std");
const Parser = @import("src/parser/mod.zig").Parser;
const Compiler = @import("src/compiler/mod.zig").Compiler;
const runtime = @import("src/runtime.zig");

const print = std.debug.print;

// ---------------------------------------------------------------------------
// Caso de prueba
// ---------------------------------------------------------------------------

const Case = struct {
    label: []const u8,
    source: []const u8,
    context: []const Var = &.{},
    expected: ?[]const u8 = null, // null = solo mostrar salida, no validar
};

const Var = struct {
    name: []const u8,
    value: Value,
};

const Value = union(enum) {
    string: []const u8,
    boolean: bool,
    number: f64,
};

// ---------------------------------------------------------------------------
// Casos
// ---------------------------------------------------------------------------

const cases = [_]Case{

    // =========================================================================
    // Tags básicos
    // =========================================================================
    .{
        .label = "tag simple",
        .source = "div",
        .expected = "<div></div>",
    },
    .{
        .label = "tag con texto",
        .source = "p Hello world",
        .expected = "<p>Hello world</p>",
    },
    .{
        .label = "tag anidado",
        .source = "div\n  p Hello",
        .expected = "<div><p>Hello</p></div>",
    },
    .{
        .label = "tag 3 niveles",
        .source = "div\n  section\n    p Contenido",
        .expected = "<div><section><p>Contenido</p></section></div>",
    },

    // =========================================================================
    // Clases e IDs
    // =========================================================================
    .{
        .label = "clase simple",
        .source = "div.container",
        .expected = "<div class=\"container\"></div>",
    },
    .{
        .label = "multiples clases fusionadas",
        .source = "div.box.highlight Content",
        .expected = "<div class=\"box highlight\">Content</div>",
    },
    .{
        .label = "clase e id",
        .source = "div.container#main",
        .expected = "<div class=\"container\" id=\"main\"></div>",
    },

    // =========================================================================
    // Atributos
    // =========================================================================
    .{
        .label = "atributo string estatico",
        .source = "a(href=\"/home\") Inicio",
        .expected = "<a href=\"/home\">Inicio</a>",
    },
    .{
        .label = "multiples atributos",
        .source = "input(type=\"text\" placeholder=\"Nombre\" required)",
        .expected = "<input type=\"text\" placeholder=\"Nombre\" required>",
    },
    .{
        .label = "atributo boolean",
        .source = "input(disabled)",
        .expected = "<input disabled>",
    },
    .{
        .label = "atributo expresion",
        .source = "- var cls = \"primary\"\nbutton(class=cls) Click",
        .expected = "<button class=\"primary\">Click</button>",
    },
    .{
        .label = "atributo ternario",
        .source = "- var active = true\ndiv(class=active ? \"active\" : \"inactive\")",
        .expected = "<div class=\"active\"></div>",
    },

    // =========================================================================
    // Void elements
    // =========================================================================
    .{
        .label = "br void",
        .source = "br",
        .expected = "<br>",
    },
    .{
        .label = "input void",
        .source = "input(type=\"text\")",
        .expected = "<input type=\"text\">",
    },
    .{
        .label = "meta void",
        .source = "meta(charset=\"UTF-8\")",
        .expected = "<meta charset=\"UTF-8\">",
    },
    .{
        .label = "img void",
        .source = "img(src=\"logo.png\" alt=\"Logo\")",
        .expected = "<img src=\"logo.png\" alt=\"Logo\">",
    },

    // =========================================================================
    // Doctype
    // =========================================================================
    .{
        .label = "doctype html",
        .source = "doctype html\nhtml\n  head\n    title Test\n  body\n    p Hola",
        .expected = "<!DOCTYPE html><html><head><title>Test</title></head><body><p>Hola</p></body></html>",
    },

    // =========================================================================
    // JsStatement / Code
    // =========================================================================
    .{
        .label = "var y uso",
        .source = "- var name = \"Carlos\"\np Hola #{name}",
        .expected = "<p>Hola Carlos</p>",
    },
    .{
        .label = "var numero",
        .source = "- var x = 10\n- var y = 20\np #{x + y}",
        .expected = "<p>30</p>",
    },
    .{
        .label = "var array",
        .source = "- var fruits = [\"banana\", \"apple\"]\np #{fruits[0]}",
        .expected = "<p>banana</p>",
    },
    .{
        .label = "var objeto",
        .source = "- var user = { name: \"Ana\" }\np #{user.name}",
        .expected = "<p>Ana</p>",
    },

    // =========================================================================
    // Interpolacion
    // =========================================================================
    .{
        .label = "interpolacion escapada",
        .source = "p Hola #{name}",
        .context = &.{.{ .name = "name", .value = .{ .string = "Carlos" } }},
        .expected = "<p>Hola Carlos</p>",
    },
    .{
        .label = "interpolacion escapa XSS",
        .source = "p #{content}",
        .context = &.{.{ .name = "content", .value = .{ .string = "<script>alert('xss')</script>" } }},
        .expected = "<p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>",
    },
    .{
        .label = "interpolacion no escapada",
        .source = "p !{html}",
        .context = &.{.{ .name = "html", .value = .{ .string = "<strong>Bold</strong>" } }},
        .expected = "<p><strong>Bold</strong></p>",
    },
    .{
        .label = "interpolacion con expresion",
        .source = "- var price = 10\n- var qty = 3\np Total: #{price * qty}",
        .expected = "<p>Total: 30</p>",
    },
    .{
        .label = "interpolacion multiple",
        .source = "- var a = \"Hola\"\n- var b = \"mundo\"\np #{a} #{b}!",
        .expected = "<p>Hola mundo!</p>",
    },

    // =========================================================================
    // if / else / unless
    // =========================================================================
    .{
        .label = "if true",
        .source = "if isAdmin\n  p Admin",
        .context = &.{.{ .name = "isAdmin", .value = .{ .boolean = true } }},
        .expected = "<p>Admin</p>",
    },
    .{
        .label = "if false",
        .source = "if isAdmin\n  p Admin",
        .context = &.{.{ .name = "isAdmin", .value = .{ .boolean = false } }},
        .expected = "",
    },
    .{
        .label = "if else",
        .source = "if isAdmin\n  p Admin\nelse\n  p Usuario",
        .context = &.{.{ .name = "isAdmin", .value = .{ .boolean = false } }},
        .expected = "<p>Usuario</p>",
    },
    .{
        .label = "unless false renderiza",
        .source = "unless isGuest\n  p Bienvenido",
        .context = &.{.{ .name = "isGuest", .value = .{ .boolean = false } }},
        .expected = "<p>Bienvenido</p>",
    },
    .{
        .label = "unless true no renderiza",
        .source = "unless isGuest\n  p Bienvenido",
        .context = &.{.{ .name = "isGuest", .value = .{ .boolean = true } }},
        .expected = "",
    },
    .{
        .label = "if else if encadenado",
        .source = "- var role = \"user\"\nif role == \"admin\"\n  p Admin\nelse\n  if role == \"user\"\n    p Usuario\n  else\n    p Invitado",
        .expected = "<p>Usuario</p>",
    },

    // =========================================================================
    // each
    // =========================================================================
    .{
        .label = "each simple",
        .source = "- var items = [\"a\",\"b\",\"c\"]\nul\n  each item in items\n    li #{item}",
        .expected = "<ul><li>a</li><li>b</li><li>c</li></ul>",
    },
    .{
        .label = "each array literal",
        .source = "each n in [1,2,3]\n  p #{n}",
        .expected = "<p>1</p><p>2</p><p>3</p>",
    },
    .{
        .label = "each con indice",
        .source = "- var items = [\"x\",\"y\"]\neach item, i in items\n  p #{i}:#{item}",
        .expected = "<p>0:x</p><p>1:y</p>",
    },
    .{
        .label = "each anidado",
        .source = "- var rows = [[1,2],[3,4]]\neach row in rows\n  each cell in row\n    span #{cell}",
        .expected = "<span>1</span><span>2</span><span>3</span><span>4</span>",
    },

    // =========================================================================
    // while
    // =========================================================================
    .{
        .label = "while simple",
        .source = "- var i = 0\nwhile i < 3\n  p #{i}\n  - i++",
        .expected = "<p>0</p><p>1</p><p>2</p>",
    },

    // =========================================================================
    // case / when / default
    // =========================================================================
    .{
        .label = "case match",
        .source = "- var role = \"admin\"\ncase role\n  when \"admin\"\n    p Admin\n  when \"user\"\n    p Usuario\n  default\n    p Invitado",
        .expected = "<p>Admin</p>",
    },
    .{
        .label = "case default",
        .source = "- var role = \"guest\"\ncase role\n  when \"admin\"\n    p Admin\n  default\n    p Invitado",
        .expected = "<p>Invitado</p>",
    },

    // =========================================================================
    // mixin
    // =========================================================================
    .{
        .label = "mixin sin params",
        .source = "mixin divider\n  hr\n+divider",
        .expected = "<hr>",
    },
    .{
        .label = "mixin con params",
        .source = "mixin greet(name)\n  p Hola #{name}\n+greet(\"Carlos\")",
        .expected = "<p>Hola Carlos</p>",
    },
    .{
        .label = "mixin multiple llamadas",
        .source = "mixin btn(label)\n  button #{label}\n+btn(\"Guardar\")\n+btn(\"Cancelar\")",
        .expected = "<button>Guardar</button><button>Cancelar</button>",
    },

    // =========================================================================
    // Comentarios
    // =========================================================================
    .{
        .label = "comentario unbuffered no emite",
        .source = "//- Solo para devs\np Visible",
        .expected = "<p>Visible</p>",
    },

    // =========================================================================
    // Combinaciones reales
    // =========================================================================
    .{
        .label = "js + each + if",
        .source = "- var items = [1,2,3]\nul\n  each item in items\n    if item > 1\n      li #{item}",
        .expected = "<ul><li>2</li><li>3</li></ul>",
    },
    .{
        .label = "js + unless",
        .source = "- var loggedIn = false\nunless loggedIn\n  p Por favor inicia sesion",
        .expected = "<p>Por favor inicia sesion</p>",
    },
    .{
        .label = "template mini completo",
        .source =
        \\doctype html
        \\html(lang="es")
        \\  head
        \\    meta(charset="UTF-8")
        \\    title Mi Pagina
        \\  body
        \\    h1 Bienvenido
        \\    p Hola mundo
        ,
        .expected = "<!DOCTYPE html><html lang=\"es\"><head><meta charset=\"UTF-8\"><title>Mi Pagina</title></head><body><h1>Bienvenido</h1><p>Hola mundo</p></body></html>",
    },
    .{
        .label = "mixin + each complejo",
        .source = "mixin item(label)\n  li.item #{label}\nul\n  each fruit in [\"banana\",\"apple\"]\n    +item(fruit)",
        .expected = "<ul><li class=\"item\">banana</li><li class=\"item\">apple</li></ul>",
    },
};

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;
    const io = init.io;

    var passed: usize = 0;
    var failed: usize = 0;

    for (cases) |case| {
        const sep = "═" ** 50;
        print("\n{s}\n  {s}\n", .{ sep, case.label });

        // Print source
        var lines = std.mem.splitScalar(u8, case.source, '\n');
        var ln: usize = 1;
        while (lines.next()) |line| {
            print("  {d:>2}: {s}\n", .{ ln, line });
            ln += 1;
        }
        print("{s}\n", .{"─" ** 50});

        // Parse
        var parser = Parser.init(allocator, case.source) catch |err| {
            print("[PARSE ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };
        defer parser.deinit();

        const root = parser.parse() catch |err| {
            print("[PARSE ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };

        // Runtime
        var js_runtime = runtime.JsRuntime.init(allocator) catch |err| {
            print("[RUNTIME ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };
        defer js_runtime.deinit();

        // Set context variables
        for (case.context) |v| {
            const js_val = switch (v.value) {
                .string => |s| runtime.jsValueFromString(allocator, s) catch continue,
                .boolean => |b| runtime.jsValueFromBool(allocator, b) catch continue,
                .number => |n| runtime.jsValueFromNumber(allocator, n) catch continue,
            };
            js_runtime.setContext(v.name, js_val) catch {};
            var val_copy = js_val;
            val_copy.deinit(allocator);
        }

        // Compile
        var compiler = Compiler.init(io, allocator, js_runtime) catch |err| {
            print("[COMPILER INIT ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };
        defer compiler.deinit();

        const html = compiler.compile(root) catch |err| {
            print("[COMPILE ERROR] {}\n", .{err});
            // Print accumulated errors if any
            for (compiler.errors.items) |e| {
                print("  → [{s}] line {d}: {s}", .{ @tagName(e.type), e.line, e.message });
                if (e.detail) |d| print(" ({s})", .{d});
                print("\n", .{});
            }
            failed += 1;
            continue;
        };
        defer allocator.free(html);

        print("HTML: {s}\n", .{html});

        // Validate if expected is set
        if (case.expected) |expected| {
            if (std.mem.eql(u8, html, expected)) {
                print("✓ OK\n", .{});
                passed += 1;
            } else {
                print("✗ FAIL\n", .{});
                print("  expected: {s}\n", .{expected});
                print("  got:      {s}\n", .{html});
                failed += 1;
            }
        } else {
            passed += 1;
        }
    }

    print("\n{s}\n", .{"═" ** 50});
    print("  {d}/{d} casos exitosos", .{ passed, passed + failed });
    if (failed > 0) {
        print("  ({d} errores)\n", .{failed});
    } else {
        print("  ✓\n", .{});
    }
    print("{s}\n", .{"═" ** 50});
}
