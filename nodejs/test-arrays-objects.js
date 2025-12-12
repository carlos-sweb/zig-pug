#!/usr/bin/env node
/**
 * Test suite for arrays and objects support in zig-pug
 * Run with: node test-arrays-objects.js
 */

const zigpug = require('./index.js');

let testsPassed = 0;
let testsFailed = 0;

function test(name, fn) {
    try {
        fn();
        console.log(`✓ ${name}`);
        testsPassed++;
    } catch (err) {
        console.error(`✗ ${name}`);
        console.error(`  Error: ${err.message}`);
        testsFailed++;
    }
}

function assertEqual(actual, expected, message) {
    if (actual !== expected) {
        throw new Error(`${message}\n  Expected: ${expected}\n  Actual: ${actual}`);
    }
}

function assertContains(haystack, needle, message) {
    if (!haystack.includes(needle)) {
        throw new Error(`${message}\n  Expected to contain: ${needle}\n  Actual: ${haystack}`);
    }
}

console.log('Running zig-pug arrays and objects tests...\n');

// Test 1: Simple array with setArray
test('setArray() with simple string array', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setArray('items', ['apple', 'banana', 'orange']);

    const html = compiler.compile('each item in items\n  li= item');
    assertContains(html, '<li>apple</li>', 'Should contain apple');
    assertContains(html, '<li>banana</li>', 'Should contain banana');
    assertContains(html, '<li>orange</li>', 'Should contain orange');
});

// Test 2: Simple object with setObject
test('setObject() with simple object', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setObject('user', { name: 'Alice', age: 30 });

    const html = compiler.compile('p= user.name\np= user.age');
    assertContains(html, '<p>Alice</p>', 'Should contain name');
    assertContains(html, '<p>30</p>', 'Should contain age');
});

// Test 3: Array of objects
test('setArray() with array of objects', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setArray('users', [
        { name: 'Alice', age: 30 },
        { name: 'Bob', age: 25 }
    ]);

    const html = compiler.compile('each user in users\n  p= user.name');
    assertContains(html, '<p>Alice</p>', 'Should contain Alice');
    assertContains(html, '<p>Bob</p>', 'Should contain Bob');
});

// Test 4: Nested objects
test('setObject() with nested objects', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setObject('company', {
        name: 'Tech Corp',
        location: {
            city: 'SF',
            country: 'USA'
        }
    });

    const html = compiler.compile('p= company.location.city');
    assertContains(html, '<p>SF</p>', 'Should access nested property');
});

// Test 5: Auto-detect with setVariables
test('setVariables() auto-detects arrays and objects', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setVariables({
        items: ['a', 'b', 'c'],
        user: { name: 'Test' }
    });

    const html = compiler.compile('each item in items\n  span= item\np= user.name');
    assertContains(html, '<span>a</span>', 'Should contain array item');
    assertContains(html, '<p>Test</p>', 'Should contain object property');
});

// Test 6: Mixed types
test('setVariables() with all types mixed', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setVariables({
        str: 'hello',
        num: 42,
        bool: true,
        arr: [1, 2, 3],
        obj: { key: 'value' }
    });

    const html = compiler.compile(`
p= str
p= num
p= bool
each n in arr
  span= n
p= obj.key
    `);

    assertContains(html, '<p>hello</p>', 'Should contain string');
    assertContains(html, '<p>42</p>', 'Should contain number');
    assertContains(html, '<p>true</p>', 'Should contain boolean');
    assertContains(html, '<span>1</span>', 'Should contain array element');
    assertContains(html, '<p>value</p>', 'Should contain object property');
});

// Test 7: render() convenience method
test('render() with arrays and objects', () => {
    const html = zigpug.compile('each x in list\n  li= x', {
        list: ['one', 'two', 'three']
    });

    assertContains(html, '<li>one</li>', 'Should render array');
});

// Test 8: Chaining methods
test('Method chaining with arrays and objects', () => {
    const compiler = new zigpug.PugCompiler();
    const html = compiler
        .setString('title', 'Test')
        .setArray('items', ['a', 'b'])
        .setObject('user', { name: 'Alice' })
        .compile('p= title\neach item in items\n  span= item\np= user.name');

    assertContains(html, '<p>Test</p>', 'Should contain title');
    assertContains(html, '<span>a</span>', 'Should contain array');
    assertContains(html, '<p>Alice</p>', 'Should contain object');
});

// Test 9: Empty arrays and objects
test('Empty arrays and objects', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setArray('empty_arr', []);
    compiler.setObject('empty_obj', {});

    const html = compiler.compile('each item in empty_arr\n  li= item');
    assertEqual(html, '', 'Empty array should produce no output');
});

// Test 10: Array with numbers
test('setArray() with numbers', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setArray('numbers', [1, 2, 3, 4, 5]);

    const html = compiler.compile('each n in numbers\n  span= n');
    assertContains(html, '<span>1</span>', 'Should contain number 1');
    assertContains(html, '<span>5</span>', 'Should contain number 5');
});

// Test 11: Nested arrays
test('Nested arrays', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setArray('matrix', [[1, 2], [3, 4]]);

    const html = compiler.compile('each row in matrix\n  each cell in row\n    span= cell');
    assertContains(html, '<span>1</span>', 'Should contain nested element 1');
    assertContains(html, '<span>4</span>', 'Should contain nested element 4');
});

// Test 12: Object with array property
test('Object containing arrays', () => {
    const compiler = new zigpug.PugCompiler();
    compiler.setObject('data', {
        title: 'Test',
        items: ['a', 'b', 'c']
    });

    const html = compiler.compile('p= data.title\neach item in data.items\n  li= item');
    assertContains(html, '<p>Test</p>', 'Should contain title');
    assertContains(html, '<li>a</li>', 'Should iterate nested array');
});

// Print summary
console.log('\n' + '='.repeat(50));
console.log(`Tests passed: ${testsPassed}`);
console.log(`Tests failed: ${testsFailed}`);
console.log('='.repeat(50));

if (testsFailed > 0) {
    process.exit(1);
} else {
    console.log('\n✓ All tests passed!');
    process.exit(0);
}
