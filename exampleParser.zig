//! exampleParser.zig — AST output for zig-pug parser
//!
//! Parsea templates de ejemplo e imprime el AST resultante.
//! Usado para verificar que el parser produce el árbol correcto
//! antes de implementar el compiler/renderer.
//!
//! Uso:
//!   zig build exampleParser

const std   = @import("std");
const Parser = @import("src/parser/mod.zig").Parser;
const ast    = @import("src/ast/mod.zig");

const print = std.debug.print;

// ---------------------------------------------------------------------------
// Casos de prueba
// ---------------------------------------------------------------------------

const Case = struct {
    label:  []const u8,
    source: []const u8,
};

const cases = [_]Case{

    // =========================================================================
    // Tags básicos
    // =========================================================================
    .{
        .label  = "tag simple",
        .source = "div",
    },
    .{
        .label  = "tag con clase e id",
        .source = "div.container#main",
    },
    .{
        .label  = "tag con texto",
        .source = "p Hello world",
    },
    .{
        .label  = "tag con clase y texto",
        .source = "p.intro Hello world",
    },
    .{
        .label  = "tag anidado",
        .source = "div\n  p Hello",
    },
    .{
        .label  = "tag 3 niveles",
        .source = "div\n  section\n    p Contenido",
    },

    // =========================================================================
    // Atributos
    // =========================================================================
    .{
        .label  = "atributo string estatico",
        .source = "div(class=\"container\")",
    },
    .{
        .label  = "atributo expresion",
        .source = "div(class=myClass)",
    },
    .{
        .label  = "atributo boolean",
        .source = "input(disabled)",
    },
    .{
        .label  = "multiples atributos",
        .source = "input(type=\"text\" placeholder=\"Nombre\" required)",
    },
    .{
        .label  = "atributo ternario",
        .source = "input(class=isActive ? \"active\" : \"inactive\")",
    },
    .{
        .label  = "atributo metodo",
        .source = "div(class=user.getRole())",
    },
    .{
        .label  = "atributo complejo con operadores",
        .source = "input(data-name=name.toLowerCase() + \"->teacher\")",
    },
    .{
        .label  = "atributos complejos multiples",
        .source = "input(type=#{type},data-age=age+1)",
    },

    // =========================================================================
    // Interpolacion
    // =========================================================================
    .{
        .label  = "interpolacion escapada",
        .source = "p Hola #{name}",
    },
    .{
        .label  = "interpolacion no escapada",
        .source = "p !{rawHtml}",
    },
    .{
        .label  = "interpolacion con expresion",
        .source = "p Total: #{price * qty}",
    },
    .{
        .label  = "interpolacion multiple",
        .source = "p #{greeting} #{name}!",
    },
    .{
        .label  = "interpolacion en atributo",
        .source = "input(value=#{age + 1})",
    },

    // =========================================================================
    // JsStatement / Code
    // =========================================================================
    .{
        .label  = "js var string",
        .source = "- var name = \"Claude\"",
    },
    .{
        .label  = "js var array",
        .source = "- var fruits = [\"banana\", \"apple\"]",
    },
    .{
        .label  = "js var object",
        .source = "- var user = { name: \"Ana\", role: \"admin\" }",
    },
    .{
        .label  = "js multiples declaraciones",
        .source = "- var x = 1\n- var y = 2\n- var z = x + y",
    },
    .{
        .label  = "js seguido de tag con interpol",
        .source = "- var title = \"Hola\"\nh1 #{title}",
    },

    // =========================================================================
    // if / else / unless
    // =========================================================================
    .{
        .label  = "if simple",
        .source = "if isAdmin\n  p Bienvenido",
    },
    .{
        .label  = "if else",
        .source = "if isAdmin\n  p Admin\nelse\n  p Usuario",
    },
    .{
        .label  = "if con expresion logica",
        .source = "if isAdmin && isActive\n  p Activo",
    },
    .{
        .label  = "unless simple",
        .source = "unless isGuest\n  p Contenido exclusivo",
    },
    .{
        .label  = "unless con else",
        .source = "unless isGuest\n  p Bienvenido\nelse\n  p Acceso denegado",
    },
    .{
        .label  = "if else if encadenado",
        .source = "if role == \"admin\"\n  p Admin\nelse\n  if role == \"user\"\n    p Usuario\n  else\n    p Invitado",
    },
    .{
        .label  = "unless anidado con if",
        .source = "unless isGuest\n  if isAdmin\n    p Admin\n  else\n    p Usuario",
    },

    // =========================================================================
    // each / while
    // =========================================================================
    .{
        .label  = "each simple",
        .source = "each item in items\n  li #{item}",
    },
    .{
        .label  = "each con array literal",
        .source = "each item in [1,2,3]\n  li #{item}",
    },
    .{
        .label  = "each con indice",
        .source = "each item, i in items\n  li #{i}: #{item}",
    },
    .{
        .label  = "each anidado",
        .source = "each section in sections\n  each item in section.items\n    li #{item}",
    },
    .{
        .label  = "while simple",
        .source = "while count > 0\n  li item",
    },
    .{
        .label  = "while con js",
        .source = "- var i = 0\nwhile i < 5\n  p #{i}\n  - i++",
    },

    // =========================================================================
    // case / when / default
    // =========================================================================
    .{
        .label  = "case simple",
        .source = "case role\n  when \"admin\"\n    p Admin\n  when \"user\"\n    p Usuario\n  default\n    p Invitado",
    },
    .{
        .label  = "case con variable js",
        .source = "case user.role\n  when \"admin\"\n    p Admin\n  default\n    p Otro",
    },

    // =========================================================================
    // mixin
    // =========================================================================
    .{
        .label  = "mixin definicion sin params",
        .source = "mixin divider\n  hr",
    },
    .{
        .label  = "mixin definicion con params",
        .source = "mixin card(title, body)\n  div.card\n    h2 #{title}\n    p #{body}",
    },
    .{
        .label  = "mixin llamada sin args",
        .source = "+divider",
    },
    .{
        .label  = "mixin llamada con args",
        .source = "+card(\"Titulo\", \"Cuerpo\")",
    },
    .{
        .label  = "mixin completo",
        .source = "mixin item(label)\n  li #{label}\nul\n  each fruit in fruits\n    +item(fruit)",
    },

    // =========================================================================
    // include / extends / block
    // =========================================================================
    .{
        .label  = "include simple",
        .source = "include header",
    },
    .{
        .label  = "include ruta",
        .source = "include partials/nav",
    },
    .{
        .label  = "extends con block",
        .source = "extends layouts/base\nblock content\n  h1 Pagina",
    },
    .{
        .label  = "block con cuerpo",
        .source = "block content\n  h1 Titulo\n  p Parrafo",
    },
    .{
        .label  = "append scripts",
        .source = "append scripts\n  script(src=\"app.js\")",
    },

    // =========================================================================
    // Comentarios
    // =========================================================================
    .{
        .label  = "comentario buffered",
        .source = "// Este es un comentario HTML",
    },
    .{
        .label  = "comentario unbuffered",
        .source = "//- Solo para desarrolladores",
    },

    // =========================================================================
    // doctype
    // =========================================================================
    .{
        .label  = "doctype html",
        .source = "doctype html\nhtml\n  head\n    title Mi Pagina\n  body\n    p Hola",
    },

    // =========================================================================
    // Combinaciones reales
    // =========================================================================
    .{
        .label  = "js + each + if",
        .source = "- var items = [1,2,3]\neach item in items\n  if item > 1\n    p #{item}",
    },
    .{
        .label  = "js + unless",
        .source = "- var loggedIn = false\nunless loggedIn\n  p Por favor inicia sesion",
    },
    .{
        .label  = "template completo mini",
        .source =
            \\doctype html
            \\html(lang="es")
            \\  head
            \\    meta(charset="UTF-8")
            \\    title #{pageTitle}
            \\  body
            \\    if user
            \\      p Hola #{user.name}
            \\    else
            \\      p Bienvenido
        ,
    },
};

// ---------------------------------------------------------------------------
// Runner
// ---------------------------------------------------------------------------

pub fn main() !void {
    var gpa : std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    var passed:  usize = 0;
    var failed:  usize = 0;

    for (cases) |case| {
        const sep = "═" ** 46;
        print("\n{s}\n", .{sep});
        print("  {s}\n", .{case.label});
        print("  source:\n", .{});

        // Print source with line numbers
        var lines = std.mem.splitScalar(u8, case.source, '\n');
        var ln: usize = 1;
        while (lines.next()) |line| {
            print("    {d:>2}: {s}\n", .{ ln, line });
            ln += 1;
        }
        print("{s}\n", .{"─" ** 46});

        var parser = Parser.init(allocator, case.source) catch |err| {
            print("[INIT ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };
        defer parser.deinit();

        const root = parser.parse() catch |err| {
            print("[PARSE ERROR] {}\n", .{err});
            failed += 1;
            continue;
        };

        ast.printAstDebug(root, 0);
        passed += 1;
    }

    const total = passed + failed;
    print("\n{s}\n", .{"═" ** 46});
    print("  {d}/{d} casos exitosos", .{ passed, total });
    if (failed > 0) {
        print("  ({d} errores)\n", .{failed});
    } else {
        print("  ✓\n", .{});
    }
    print("{s}\n", .{"═" ** 46});
}
