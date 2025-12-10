// Test CommonJS (require)
const { PugCompiler, compile } = require('./index.js');

console.log('=== Testing CommonJS (require) ===');

// Test 1: Simple compile function
const html1 = compile('p Hello #{name}!', { name: 'World' });
console.log('✓ compile():', html1);

// Test 2: PugCompiler class
const compiler = new PugCompiler();
compiler
    .set('title', 'My Page')
    .set('version', 1.5)
    .setBool('isDev', false);

const html2 = compiler.compile('h1 #{title}');
console.log('✓ PugCompiler:', html2);

console.log('✅ CommonJS tests passed!');
