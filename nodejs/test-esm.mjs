// Test ES Modules (import)
import { PugCompiler, compile } from './index.mjs';

console.log('=== Testing ES Modules (import) ===');

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

console.log('✅ ES Modules tests passed!');
