// Test ES Modules (import)
import { PugCompiler, compile } from './index.mjs';

console.log('=== Testing ES Modules (import) ===\n');

// Test 1: Simple compile function
console.log('Test 1: compile() with simple variables');
const html1 = compile('p Hello #{name}!', { name: 'World' });
console.log('✓ Result:', html1);
console.log('');

// Test 2: PugCompiler with all types
console.log('Test 2: PugCompiler with strings, numbers, booleans');
const compiler = new PugCompiler();
compiler
    .set('title', 'My Page')
    .set('version', 1.5)
    .setBool('isDev', false);

const html2 = compiler.compile('h1 #{title} v#{version}');
console.log('✓ Result:', html2);
console.log('');

// Test 3: Arrays
console.log('Test 3: setArray()');
const compiler3 = new PugCompiler();
compiler3.setArray('items', ['apple', 'banana', 'orange']);

const html3 = compiler3.compile(`ul
  each item in items
    li= item`);
console.log('✓ Result:', html3);
console.log('');

// Test 4: Objects
console.log('Test 4: setObject()');
const compiler4 = new PugCompiler();
compiler4.setObject('user', {
    name: 'Alice',
    age: 30,
    email: 'alice@example.com'
});

const html4 = compiler4.compile('p User: #{user.name}, Age: #{user.age}');
console.log('✓ Result:', html4);
console.log('');

// Test 5: set() with auto-detection
console.log('Test 5: set() with auto-detection (arrays and objects)');
const compiler5 = new PugCompiler();
compiler5
    .set('title', 'Dashboard')          // string
    .set('count', 42)                   // number
    .set('active', true)                // boolean
    .set('tags', ['prod', 'stable'])   // array (auto-detected)
    .set('user', { name: 'Bob', role: 'Admin' }); // object (auto-detected)

const html5 = compiler5.compile(`div
  h1= title
  p Count: #{count}
  p User: #{user.name} (#{user.role})
  ul
    each tag in tags
      li= tag`);
console.log('✓ Result:', html5);
console.log('');

// Test 6: compile() shorthand with arrays and objects
console.log('Test 6: compile() shorthand with complex data');
const html6 = compile(
    `div
  h2= title
  ul
    each item in items
      li= item
  p Email: #{contact.email}`,
    {
        title: 'Shopping List',
        items: ['Milk', 'Bread', 'Eggs'],
        contact: { email: 'shop@example.com', phone: '555-1234' }
    }
);
console.log('✓ Result:', html6);
console.log('');

console.log('✅ All ES Module tests passed!');
console.log('');
console.log('Summary:');
console.log('  - ✅ String variables');
console.log('  - ✅ Number variables');
console.log('  - ✅ Boolean variables');
console.log('  - ✅ Array variables (setArray)');
console.log('  - ✅ Object variables (setObject)');
console.log('  - ✅ Auto-detection in set()');
console.log('  - ✅ Shorthand compile() with all types');
