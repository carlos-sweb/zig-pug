/**
 * Test for pretty-print and formatting options
 */

const { PugCompiler, compile } = require('./index.js');

console.log('Testing zig-pug pretty-print functionality...\n');

// Test 1: Default (minified)
console.log('=== Test 1: Default (minified) ===');
const compiler1 = new PugCompiler();
compiler1.set('title', 'Hello');
const html1 = compiler1.compile('div\n  h1= title\n  p World');
console.log(html1);
console.log('Length:', html1.length, 'bytes\n');

// Test 2: Pretty mode (with comments)
console.log('=== Test 2: Pretty mode (with comments) ===');
const compiler2 = new PugCompiler({ pretty: true });
compiler2.set('title', 'Hello');
const html2 = compiler2.compile('div\n  h1= title\n  p World');
console.log(html2);
console.log('Length:', html2.length, 'bytes\n');

// Test 3: Format mode (without comments)
console.log('=== Test 3: Format mode (without comments) ===');
const compiler3 = new PugCompiler({ format: true });
compiler3.set('title', 'Hello');
const html3 = compiler3.compile('div\n  h1= title\n  p World');
console.log(html3);
console.log('Length:', html3.length, 'bytes\n');

// Test 4: Minify mode
console.log('=== Test 4: Minify mode ===');
const compiler4 = new PugCompiler({ minify: true });
compiler4.set('title', 'Hello');
const html4 = compiler4.compile('div\n  h1= title\n  p World');
console.log(html4);
console.log('Length:', html4.length, 'bytes\n');

// Test 5: Override at compile time
console.log('=== Test 5: Override options at compile time ===');
const compiler5 = new PugCompiler({ minify: true });
compiler5.set('title', 'Hello');
const minified = compiler5.compile('div\n  h1= title\n  p World');
const pretty = compiler5.compile('div\n  h1= title\n  p World', { pretty: true });
console.log('Minified:', minified);
console.log('Pretty:', pretty);
console.log('');

// Test 6: Using convenience function
console.log('=== Test 6: Convenience function with options ===');
const html6 = compile('div\n  h1= title', { title: 'World' }, { pretty: true });
console.log(html6);
console.log('');

// Test 7: Render method with options
console.log('=== Test 7: Render method with options ===');
const compiler7 = new PugCompiler();
const html7 = compiler7.render('div\n  h1= title', { title: 'Test' }, { format: true });
console.log(html7);
console.log('');

// Test 8: Complex template
console.log('=== Test 8: Complex template with pretty ===');
const template = `doctype html
html
  head
    title= pageTitle
  body
    h1= heading
    ul
      each item in items
        li= item`;

const compiler8 = new PugCompiler({ pretty: true });
compiler8.set('pageTitle', 'My Page');
compiler8.set('heading', 'Welcome');
compiler8.setArray('items', ['Apple', 'Banana', 'Cherry']);
const html8 = compiler8.compile(template);
console.log(html8);
console.log('');

console.log('✅ All tests completed!');
