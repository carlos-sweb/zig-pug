const std = @import("std");
const Tokenizer = @import("src/tokenizer/mod.zig").Tokenizer;
const print = std.debug.print;
const cases = [_]struct { label: []const u8, source: []const u8 }{
    .{
        .label = "attributos complejos",
        .source = "input(type=#{type},data-name=name.toLowerCase() + \"->teacher\"  data-age= age+1)",
    },
    .{
        .label  = "atributos numericos sin comillas",
        .source = "input(type=\"number\" value=100 min=50 max=150)",
    },
    .{
        .label  = "float sin comillas",
        .source = "input(step=0.5)",
    },
    .{
        .label  = "expresion con punto — acceso a propiedad",
        .source = "div.hi.hello#main(my-value=')',data-value=3.items.length)",
    },
    .{
        .label  = "interpolacion delega a mujs",
        .source = "input(value=#{age + 1})",
    },
    .{
        .label  = "codigo JS inline con numero",
        .source = "- var x = 42",
    },
    .{
        .label  = "loop con array literal",
        .source = "each item in [1,2,3]",
    },
    .{
        .label  = "string con comillas dobles",
        .source = "div(class=\"container\")",
    },
    .{
        .label  = "string con comillas simples",
        .source = "div(class='container')",
    },
    .{
        .label  = "string con comilla opuesta adentro",
        .source = "div(onclick=\"alert('hola')\")",
    },
    .{
        .label  = "string con escape",
        .source = "div(title='it\\'s fine')",
    },
    .{
        .label  = "ternario en atributo",
        .source = "input(data-main= isAdmin ? \"verdadero\" : \"falso\")",
    },
    .{
        .label  = "tag con clase e id",
        .source = "div.container#main",
    },
    .{
        .label  = "tag con texto plano",
        .source = "p Hello world",
    },
    .{
        .label  = "indentacion",
        .source = "div\n  p Hello",
    },
    .{
        .label  = "boolean true como Ident",
        .source = "input(disabled=true)",
    },
    .{
        .label  = "boolean false como Ident",
        .source = "input(disabled=false)",
    },
    .{
        .label  = "boolean True mayuscula",
        .source = "input(disabled=True)",
    },
    .{
        .label  = "expresion con boolean",
        .source = "input(disabled=isAdmin ? true : false)",
    },
    .{
        .label  = "tag con texto plano",
        .source = "p Hello world",
    },
    .{
        .label  = "tag con clase y texto",
        .source = "p.intro Hello world",
    },
    .{
        .label  = "tag con atributos y texto",
        .source = "p(class=\"intro\") Hello world",
    },
    .{
        .label  = "keyword no activa texto",
        .source = "if condition",
    },
    .{
        .label = "Comments",
        .source="//- Esto es un comenatrio",
    },
    .{
        .label = "Comments",
        .source = "//  Esto es un comenatrio",
    },
    .{
        .label = "Comments",
        .source = "//! Custom Commnets",
    },

    // =========================================================================
    // JsStatement
    // =========================================================================
    .{
        .label  = "js — var string",
        .source = "- var name = \"Claude Code\"",
    },
    .{
        .label  = "js — var number",
        .source = "- var age = 42",
    },
    .{
        .label  = "js — var array",
        .source = "- var fruits = [\"banana\", \"apple\", \"mango\"]",
    },
    .{
        .label  = "js — var object",
        .source = "- var user = { name: \"Ana\", role: \"admin\" }",
    },
    .{
        .label  = "js — var con expresion",
        .source = "- var total = price * qty + tax",
    },
    .{
        .label  = "js — multiples declaraciones",
        .source = "- var x = 1\n- var y = 2\n- var z = x + y",
    },
    .{
        .label  = "js — declaracion seguida de tag",
        .source = "- var title = \"Hola\"\nh1 #{title}",
    },

    // =========================================================================
    // if / else / unless
    // =========================================================================
    .{
        .label  = "if simple",
        .source = "if isAdmin",
    },
    .{
        .label  = "if con expresion booleana",
        .source = "if user.age >= 18",
    },
    .{
        .label  = "if — keyword dentro de texto no activa If",
        .source = "p Texto con if aqui",
    },
    .{
        .label  = "if / else multilinea",
        .source = "if isAdmin\n  p Bienvenido admin\nelse\n  p Acceso denegado",
    },
    .{
        .label  = "unless simple",
        .source = "unless isGuest",
    },
    .{
        .label  = "unless multilinea",
        .source = "unless isGuest\n  p Contenido exclusivo",
    },
    .{
        .label  = "unless con expresion booleana",
        .source = "unless user.age < 18",
    },
    .{
        .label  = "unless con else",
        .source = "unless isGuest\n  p Bienvenido\nelse\n  p Acceso denegado",
    },
    .{
        .label  = "unless anidado con if",
        .source = "unless isGuest\n  if isAdmin\n    p Admin\n  else\n    p Usuario",
    },
    .{
        .label  = "unless — keyword en texto no activa Unless",
        .source = "p Texto con unless aqui",
    },

    // =========================================================================
    // each / in / Iterable
    // =========================================================================
    .{
        .label  = "each con variable",
        .source = "each item in items",
    },
    .{
        .label  = "each con array literal",
        .source = "each item in [1,2,3]",
    },
    .{
        .label  = "each con objeto acceso",
        .source = "each val in obj.values()",
    },
    .{
        .label  = "each con string literal array",
        .source = "each fruit in [\"banana\", \"apple\"]",
    },
    .{
        .label  = "each multilinea con tag hijo",
        .source = "each item in items\n  li #{item}",
    },
    .{
        .label  = "each multilinea con clase",
        .source = "each user in users\n  div.user-card\n    p #{user.name}",
    },

    // =========================================================================
    // while
    // =========================================================================
    .{
        .label  = "while simple",
        .source = "while count > 0",
    },
    .{
        .label  = "while con expresion",
        .source = "while i < items.length",
    },
    .{
        .label  = "while multilinea",
        .source = "while n > 0\n  li item\n  - n--",
    },

    // =========================================================================
    // case / when / default
    // =========================================================================
    .{
        .label  = "case simple",
        .source = "case role",
    },
    .{
        .label  = "when simple",
        .source = "when \"admin\"",
    },
    .{
        .label  = "default simple",
        .source = "default",
    },
    .{
        .label  = "case / when / default multilinea",
        .source = "case role\n  when \"admin\"\n    p Admin\n  when \"user\"\n    p Usuario\n  default\n    p Invitado",
    },

    // =========================================================================
    // mixin
    // =========================================================================
    .{
        .label  = "mixin definicion",
        .source = "mixin card(title, body)",
    },
    .{
        .label  = "mixin con cuerpo",
        .source = "mixin btn(label)\n  button.btn #{label}",
    },
    .{
        .label  = "mixin llamada con +",
        .source = "+card(\"Titulo\", \"Cuerpo\")",
    },

    // =========================================================================
    // include / extends / block / append / prepend
    // =========================================================================
    .{
        .label  = "include",
        .source = "include partials/header",
    },
    .{
        .label  = "extends",
        .source = "extends layouts/base",
    },
    .{
        .label  = "block simple",
        .source = "block content",
    },
    .{
        .label  = "append",
        .source = "append scripts",
    },
    .{
        .label  = "prepend",
        .source = "prepend styles",
    },
    .{
        .label  = "block con cuerpo",
        .source = "block content\n  h1 Titulo\n  p Parrafo",
    },

    // =========================================================================
    // doctype
    // =========================================================================
    .{
        .label  = "doctype html",
        .source = "doctype html",
    },
    .{
        .label  = "doctype xml",
        .source = "doctype xml",
    },

    // =========================================================================
    // Interpolacion en texto
    // =========================================================================
    .{
        .label  = "interpolacion escapada en texto",
        .source = "p Hola #{name}",
    },
    .{
        .label  = "interpolacion no escapada en texto",
        .source = "p !{rawHtml}",
    },
    .{
        .label  = "interpolacion con expresion",
        .source = "p Total: #{price * qty}",
    },
    .{
        .label  = "interpolacion multiple en linea",
        .source = "p #{greeting} #{name}!",
    },

    // =========================================================================
    // Indentacion profunda
    // =========================================================================
    .{
        .label  = "indentacion 3 niveles",
        .source = "div\n  section\n    article\n      p Contenido",
    },
    .{
        .label  = "dedent multiple",
        .source = "div\n  section\n    p Hola\np Final",
    },

    // =========================================================================
    // Combinaciones reales
    // =========================================================================
    .{
        .label  = "js + each + if combinados",
        .source = "- var items = [1,2,3]\neach item in items\n  if item > 1\n    p #{item}",
    },
    .{
        .label  = "template completo mini",
        .source = "doctype html\nhtml\n  head\n    title #{pageTitle}\n  body\n    h1 Bienvenido\n    if user\n      p Hola #{user.name}",
    },

    // =========================================================================
    // if — variantes adicionales
    // =========================================================================
    .{
        .label  = "if con expresion logica &&",
        .source = "if isAdmin && isActive",
    },
    .{
        .label  = "if con expresion logica ||",
        .source = "if isGuest || isBlocked",
    },
    .{
        .label  = "if else if encadenado",
        .source = "if role == \"admin\"\n  p Admin\nelse\n  if role == \"user\"\n    p Usuario\n  else\n    p Invitado",
    },
    .{
        .label  = "if con negacion",
        .source = "if !isBlocked",
    },

    // =========================================================================
    // each — variantes adicionales
    // =========================================================================
    .{
        .label  = "each con indice",
        .source = "each item, i in items",
    },
    .{
        .label  = "each con rango js",
        .source = "each n in Array.from({length: 5}, (_, i) => i)",
    },
    .{
        .label  = "each anidado",
        .source = "each section in sections\n  each item in section.items\n    li #{item}",
    },

    // =========================================================================
    // while — variantes adicionales
    // =========================================================================
    .{
        .label  = "while con js statement combinado",
        .source = "- var i = 0\nwhile i < 5\n  p #{i}\n  - i++",
    },
    .{
        .label  = "while con expresion &&",
        .source = "while i < 10 && running",
    },

    // =========================================================================
    // mixin — variantes adicionales
    // =========================================================================
    .{
        .label  = "mixin sin parametros",
        .source = "mixin divider",
    },
    .{
        .label  = "mixin con cuerpo complejo",
        .source = "mixin card(title, body, footer)\n  div.card\n    h2 #{title}\n    p #{body}\n    footer #{footer}",
    },
    .{
        .label  = "mixin llamada sin argumentos",
        .source = "+divider",
    },
    .{
        .label  = "mixin llamada con variable",
        .source = "+card(user.name, user.bio, user.role)",
    },

    // =========================================================================
    // block / append / prepend — variantes adicionales
    // =========================================================================
    .{
        .label  = "block sin nombre — contenido default",
        .source = "block\n  p Contenido default",
    },
    .{
        .label  = "append con cuerpo",
        .source = "append scripts\n  script(src=\"app.js\")",
    },
    .{
        .label  = "prepend con cuerpo",
        .source = "prepend styles\n  link(rel=\"stylesheet\" href=\"main.css\")",
    },

    // =========================================================================
    // include / extends — variantes adicionales
    // =========================================================================
    .{
        .label  = "include ruta simple",
        .source = "include header",
    },
    .{
        .label  = "include ruta profunda",
        .source = "include views/partials/nav/main",
    },
    .{
        .label  = "extends con block override",
        .source = "extends layouts/base\nblock content\n  h1 Pagina",
    },

    // =========================================================================
    // doctype — variantes adicionales
    // =========================================================================
    .{
        .label  = "doctype strict",
        .source = "doctype strict",
    },
    .{
        .label  = "doctype transitional",
        .source = "doctype transitional",
    },
    .{
        .label  = "doctype seguido de html",
        .source = "doctype html\nhtml(lang=\"es\")\n  head\n    meta(charset=\"UTF-8\")\n  body\n    p Hola",
    },

    // =========================================================================
    // case / when — variantes adicionales
    // =========================================================================
    .{
        .label  = "case con variable de js",
        .source = "case user.role",
    },
    .{
        .label  = "when con numero",
        .source = "when 42",
    },
    .{
        .label  = "when con boolean",
        .source = "when true",
    },

    // =========================================================================
    // Combinaciones reales adicionales
    // =========================================================================
    .{
        .label  = "js + unless combinado",
        .source = "- var loggedIn = false\nunless loggedIn\n  p Por favor inicia sesion",
    },
    .{
        .label  = "each + unless anidado",
        .source = "each user in users\n  unless user.banned\n    p #{user.name}",
    },
    .{
        .label  = "template con mixin y each",
        .source = "mixin item(label)\n  li #{label}\nul\n  each fruit in fruits\n    +item(fruit)",
    },
};

pub fn main() !void {
    var gpa: std.heap.DebugAllocator(.{}) = .init;
    defer _ = gpa.deinit();
    const allocator = gpa.allocator();

    for (cases) |case| {
        print("\n", .{});
        print("══════════════════════════════════════════════\n", .{});
        print("  {s}\n", .{case.label});
        print("  source: {s}\n", .{case.source});
        print("══════════════════════════════════════════════\n", .{});
        print("{s:<22} {s:<30} {s}\n", .{ "TOKEN TYPE", "VALUE", "LINE:COL" });
        print("──────────────────────────────────────────────\n", .{});

        var tokenizer = try Tokenizer.init(allocator, case.source);
        defer tokenizer.deinit();

        while (true) {
            const token = tokenizer.next() catch |err| {
                print("[ERROR] {}\n", .{err});
                break;
            };

            print("{s:<22} {s:<30} {}:{}\n", .{
                @tagName(token.type),
                token.value,
                token.line,
                token.column,
            });

            if (token.type == .Eof) break;
        }
    }

    print("\n", .{});
}
