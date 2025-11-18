// 03-compiler-class.js - API orientada a objetos con PugCompiler
// Ejecutar: bun run 03-compiler-class.js

const { PugCompiler } = require('../../nodejs');

console.log('=== API PugCompiler con Bun.js ===\n');

// Crear instancia del compilador
const compiler = new PugCompiler();

console.log('Creando compilador y estableciendo variables...\n');

// Establecer variables una por una
compiler
    .set('title', 'Mi Página Web')
    .set('version', 1.5)
    .set('author', 'Alice Johnson')
    .setBool('isDevelopment', false)
    .setBool('isProduction', true);

// Template que usa las variables
const template1 = `
doctype html
html
  head
    title #{title}
  body
    h1 #{title}
    p Versión: #{version}
    p Autor: #{author}
    if isDevelopment
      p.warning ⚠️ Modo desarrollo
    if isProduction
      p.success ✓ Modo producción
`;

console.log('Template 1:');
const html1 = compiler.compile(template1);
console.log(html1);

// Reusar el mismo compilador con nuevos valores
console.log('\n=== Reusando compilador ===\n');

compiler
    .set('productName', 'zig-pug')
    .set('price', 0)
    .setBool('isFree', true);

const template2 = `
div.product
  h2 #{productName}
  if isFree
    p.price ¡Gratis!
  else
    p.price Precio: $#{price}
  p v#{version}
`;

console.log('Template 2:');
const html2 = compiler.compile(template2);
console.log(html2);

// Benchmark: Comparar PugCompiler vs compile()
console.log('\n=== Benchmark: PugCompiler vs compile() ===\n');

const benchTemplate = `div.test
  p Hello #{name}
  p Age: #{age}`;

const iterations = 10000;

// Método 1: PugCompiler (reutilizar instancia)
const compilerInstance = new PugCompiler();
compilerInstance.set('name', 'Bob').set('age', 30);

const start1 = Bun.nanoseconds();
for (let i = 0; i < iterations; i++) {
    compilerInstance.compile(benchTemplate);
}
const elapsed1 = (Bun.nanoseconds() - start1) / 1000000;

// Método 2: compile() (crear contexto cada vez)
const zigpug = require('../../nodejs');
const start2 = Bun.nanoseconds();
for (let i = 0; i < iterations; i++) {
    zigpug.compile(benchTemplate, { name: 'Bob', age: 30 });
}
const elapsed2 = (Bun.nanoseconds() - start2) / 1000000;

console.log(`PugCompiler (reusar):     ${elapsed1.toFixed(2)}ms (${(elapsed1/iterations).toFixed(4)}ms/op)`);
console.log(`compile() (nuevo ctx):    ${elapsed2.toFixed(2)}ms (${(elapsed2/iterations).toFixed(4)}ms/op)`);
console.log(`Diferencia:               ${((elapsed2/elapsed1) * 100 - 100).toFixed(1)}% más lento con compile()`);

console.log('\n💡 Tip: Reusar PugCompiler es más eficiente si compilas múltiples templates con las mismas variables');
