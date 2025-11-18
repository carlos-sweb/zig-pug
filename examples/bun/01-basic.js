// 01-basic.js - Uso básico con Bun.js
// Ejecutar: bun run 01-basic.js

const zigpug = require('../../nodejs');

console.log('=== zig-pug con Bun.js ===\n');
console.log('Bun version:', Bun.version);
console.log('zig-pug version:', zigpug.version());
console.log('');

// Template simple
const template = `
div.greeting
  h1 Hello from Bun!
  p Version: #{version}
  p Runtime: #{runtime}
`;

const html = zigpug.compile(template, {
    version: '0.2.0',
    runtime: 'Bun.js ' + Bun.version
});

console.log('Template:');
console.log(template);
console.log('\nHTML generado:');
console.log(html);

// Benchmark simple
console.log('\n=== Performance ===');
const iterations = 10000;
const start = Bun.nanoseconds();

for (let i = 0; i < iterations; i++) {
    zigpug.compile(template, {
        version: '0.2.0',
        runtime: 'Bun.js'
    });
}

const end = Bun.nanoseconds();
const elapsed = (end - start) / 1000000; // Convert to ms
const perOp = elapsed / iterations;

console.log(`${iterations} compilaciones en ${elapsed.toFixed(2)}ms`);
console.log(`${perOp.toFixed(4)}ms por operación`);
console.log(`~${Math.floor(iterations / (elapsed / 1000))} ops/sec`);
