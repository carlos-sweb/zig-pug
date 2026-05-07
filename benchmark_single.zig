//! benchmark_single.zig — un solo render completo
//! hyperfine lo llama N veces desde afuera.
//!
//! Mide todo: init runtime, parse, compile, output.
//!
//! Agregar a build.zig:
//!   const bench = b.addExecutable(.{
//!       .name = "benchmark_single",
//!       .root_source_file = b.path("benchmark_single.zig"),
//!       .target = target,
//!       .optimize = .ReleaseFast,
//!   });
//!   // mismo linkado que el CLI (mujs, libc, etc.)

const std = @import("std");
const Parser = @import("src/parser/mod.zig").Parser;
const Compiler = @import("src/compiler/mod.zig").Compiler;
const runtime = @import("src/runtime.zig");

const TEMPLATE =
    \\doctype html
    \\html(lang="es")
    \\  head
    \\    meta(charset="UTF-8")
    \\    meta(name="viewport" content="width=device-width, initial-scale=1.0")
    \\    title #{pageTitle} — #{siteName}
    \\    link(rel="stylesheet" href="/css/main.css")
    \\  body
    \\    header.site-header
    \\      nav.navbar
    \\        a.brand(href="/") #{siteName}
    \\        ul.nav-links
    \\          each link in navLinks
    \\            li
    \\              a(href=link.href) #{link.label}
    \\        if user
    \\          div.user-menu
    \\            span Hola, #{user}
    \\        else
    \\          a(href="/login") Iniciar sesion
    \\    main.container
    \\      section.stats-grid
    \\        each stat in stats
    \\          div.stat-card
    \\            span.stat-value #{stat.value}
    \\            span.stat-label #{stat.label}
    \\      section.products
    \\        h2 #{productsTitle}
    \\        div.product-grid
    \\          each product in products
    \\            div.product-card
    \\              h3 #{product.name}
    \\              p #{product.description}
    \\              span.price $#{product.price}
    \\              div.product-stock
    \\                case product.stock
    \\                  when "in_stock"
    \\                    span.stock-ok En stock
    \\                  when "low_stock"
    \\                    span.stock-low Pocas unidades
    \\                  default
    \\                    span.stock-out Agotado
    \\              unless product.discontinued
    \\                button.btn-cart Agregar
    \\      section.blog
    \\        h2 Ultimas entradas
    \\        div.blog-grid
    \\          each post in blogPosts
    \\            article.post-card
    \\              h3
    \\                a(href=post.url) #{post.title}
    \\              p #{post.excerpt}
    \\              div.post-tags
    \\                each tag in post.tags
    \\                  span.tag #{tag}
    \\      section.faq
    \\        h2 Preguntas frecuentes
    \\        div.faq-list
    \\          each item in faq
    \\            div.faq-item
    \\              h4 #{item.question}
    \\              if item.open
    \\                p #{item.answer}
    \\      unless user
    \\        section.newsletter
    \\          h2 Suscribete
    \\    footer.site-footer
    \\      p &copy; #{year} #{siteName}
;

const CONTEXT_JS =
    \\var pageTitle = "Tienda Online";
    \\var siteName = "ZigShop";
    \\var year = 2025;
    \\var user = "Carlos";
    \\var navLinks = [
    \\  {href:"/",label:"Inicio"},
    \\  {href:"/shop",label:"Tienda"},
    \\  {href:"/blog",label:"Blog"},
    \\  {href:"/contact",label:"Contacto"}
    \\];
    \\var stats = [
    \\  {value:"1,240",label:"Clientes"},
    \\  {value:"98%",label:"Satisfaccion"},
    \\  {value:"3,500",label:"Productos"},
    \\  {value:"24/7",label:"Soporte"}
    \\];
    \\var productsTitle = "Productos destacados";
    \\var products = (function(){
    \\  var a=[];
    \\  for(var i=0;i<20;i++){
    \\    a.push({
    \\      name:"Producto "+(i+1),
    \\      description:"Descripcion "+(i+1),
    \\      price:((i+1)*49.99).toFixed(2),
    \\      stock:["in_stock","low_stock","out_of_stock"][i%3],
    \\      discontinued:i%10===0
    \\    });
    \\  }
    \\  return a;
    \\})();
    \\var blogPosts = (function(){
    \\  var a=[];
    \\  for(var i=0;i<6;i++){
    \\    a.push({
    \\      title:"Entrada "+(i+1),
    \\      excerpt:"Resumen "+(i+1),
    \\      url:"/blog/post-"+(i+1),
    \\      tags:["tag"+(i+1),"blog"]
    \\    });
    \\  }
    \\  return a;
    \\})();
    \\var faq = (function(){
    \\  var a=[];
    \\  for(var i=0;i<8;i++){
    \\    a.push({
    \\      question:"Pregunta "+(i+1)+"?",
    \\      answer:"Respuesta "+(i+1),
    \\      open:i===0
    \\    });
    \\  }
    \\  return a;
    \\})();
;

pub fn main(init: std.process.Init) !void {
    const allocator = init.gpa;

    // 1. Init runtime
    var js_rt = try runtime.JsRuntime.init(allocator);
    defer js_rt.deinit();

    // 2. Set context
    _ = try js_rt.eval(CONTEXT_JS);

    // 3. Parse
    var parser = try Parser.init(allocator, TEMPLATE);
    defer parser.deinit();
    const root = try parser.parse();

    // 4. Compile
    var compiler = try Compiler.init(init.io, allocator, js_rt);
    defer compiler.deinit();
    const html = try compiler.compile(root);
    defer allocator.free(html);

    // 5. Output
    try std.Io.File.stdout().writeStreamingAll(init.io, html);
}
