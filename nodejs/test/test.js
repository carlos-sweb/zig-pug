#!/usr/bin/env node
/**
 * Basic test for zig-pug Node.js addon
 */

const assert = require('assert');
const path = require('path');

console.log('🧪 Testing zig-pug addon...\n');

let zigpug;

try {
    // Try to load the addon
    zigpug = require('../index.js');
    console.log('✓ Addon loaded successfully');
} catch (err) {
    console.error('✗ Failed to load addon:', err.message);
    process.exit(1);
}

// Test 1: Basic compilation
try {
    const template = 'div Hello World';
    const result = zigpug.compile(template);

    assert(typeof result === 'string', 'Result should be a string');
    assert(result.includes('Hello World'), 'Result should contain "Hello World"');
    assert(result.includes('<div>'), 'Result should contain <div>');

    console.log('✓ Test 1: Basic compilation passed');
} catch (err) {
    console.error('✗ Test 1 failed:', err.message);
    process.exit(1);
}

// Test 2: With class
try {
    const template = 'div.container Content';
    const result = zigpug.compile(template);

    assert(result.includes('class="container"'), 'Result should have class attribute');

    console.log('✓ Test 2: Class attribute passed');
} catch (err) {
    console.error('✗ Test 2 failed:', err.message);
    process.exit(1);
}

// Test 3: Nested elements
try {
    const template = 'div\n  p Nested';
    const result = zigpug.compile(template);

    assert(result.includes('<div>'), 'Should have div tag');
    assert(result.includes('<p>'), 'Should have p tag');
    assert(result.includes('Nested'), 'Should have content');

    console.log('✓ Test 3: Nested elements passed');
} catch (err) {
    console.error('✗ Test 3 failed:', err.message);
    process.exit(1);
}

// Test 4: Error handling
try {
    const template = ''; // Empty template
    const result = zigpug.compile(template);

    console.log('✓ Test 4: Empty template handled');
} catch (err) {
    // It's okay if it throws, we just want to make sure it doesn't crash
    console.log('✓ Test 4: Error handling works');
}

console.log('\n✅ All tests passed!');
process.exit(0);
