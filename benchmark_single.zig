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
    const content_pug_template = try std.Io.Dir.cwd().readFileAlloc(init.io,"benchmark.pug", allocator, .limited(10 * 1024 * 1024));

    // 1. Init runtime
    var js_rt = try runtime.JsRuntime.init(allocator);
    defer js_rt.deinit();

    // 2. Set context
    _ = try js_rt.eval(CONTEXT_JS);

    // 3. Parse
    var parser = try Parser.init(allocator, content_pug_template );
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
