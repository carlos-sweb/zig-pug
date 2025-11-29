#!/usr/bin/env node

/**
 * Test suite for zig-pug Node.js addon
 */

const pug = require('../index.js');

console.log('🧪 Testing zig-pug Node.js addon\n');

// Test 1: Version
console.log('📋 Test 1: Version');
try {
    const version = pug.version();
    console.log(`   ✅ Version: ${version}\n`);
} catch (error) {
    console.error(`   ❌ Error: ${error.message}\n`);
    process.exit(1);
}

// Test 2: Simple template
console.log('📋 Test 2: Simple template');
try {
    const template = 'p Hello World';
    const html = pug.compile(template);
    console.log(`   Input:  ${template}`);
    console.log(`   Output: ${html}`);
    if (html === '<p>Hello World</p>') {
        console.log('   ✅ Pass\n');
    } else {
        console.log('   ❌ Unexpected output\n');
        process.exit(1);
    }
} catch (error) {
    console.error(`   ❌ Error: ${error.message}\n`);
    process.exit(1);
}

// Test 3: Template with variables
console.log('📋 Test 3: Template with interpolation');
try {
    const template = 'p Hello #{name}';
    const html = pug.compile(template, { name: 'Alice' });
    console.log(`   Input:  ${template}`);
    console.log(`   Output: ${html}`);
    if (html === '<p>Hello Alice</p>') {
        console.log('   ✅ Pass\n');
    } else {
        console.log('   ❌ Unexpected output\n');
        process.exit(1);
    }
} catch (error) {
    console.error(`   ❌ Error: ${error.message}\n`);
    process.exit(1);
}

// Test 4: Complex template
console.log('📋 Test 4: Complex template with nested tags');
try {
    const template = `div.container
  h1 Welcome
  p This is a test`;
    const html = pug.compile(template);
    console.log(`   Input:`);
    console.log(`     ${template.split('\n').join('\n     ')}`);
    console.log(`   Output: ${html}`);
    // Allow for minor whitespace differences
    const expected = '<div class="container"><h1>Welcome</h1><p>This is a test</p></div>';
    const htmlTrimmed = html.replace(/\s+</g, '<').replace(/>\s+/g, '>');
    const expectedTrimmed = expected.replace(/\s+</g, '<').replace(/>\s+/g, '>');
    if (htmlTrimmed === expectedTrimmed) {
        console.log('   ✅ Pass\n');
    } else {
        console.log('   ❌ Unexpected output');
        console.log(`   Expected: ${expected}\n`);
        process.exit(1);
    }
} catch (error) {
    console.error(`   ❌ Error: ${error.message}\n`);
    process.exit(1);
}

// Test 5: PugCompiler class API
console.log('📋 Test 5: PugCompiler class API');
try {
    const compiler = new pug.PugCompiler();
    compiler.setString('title', 'My Page');
    compiler.setNumber('year', 2024);
    compiler.setBool('active', true);

    const template = 'h1 #{title}';
    const html = compiler.compile(template);
    console.log(`   Input:  ${template}`);
    console.log(`   Output: ${html}`);
    if (html === '<h1>My Page</h1>') {
        console.log('   ✅ Pass\n');
    } else {
        console.log('   ❌ Unexpected output\n');
        process.exit(1);
    }
} catch (error) {
    console.error(`   ❌ Error: ${error.message}\n`);
    process.exit(1);
}

// Test 6: Multiple variables
console.log('📋 Test 6: Multiple variables with setVariables');
try {
    const compiler = new pug.PugCompiler();
    compiler.setVariables({
        name: 'Bob',
        age: 30,
        active: true
    });

    const template = 'p #{name} is #{age} years old';
    const html = compiler.compile(template);
    console.log(`   Input:  ${template}`);
    console.log(`   Output: ${html}`);
    if (html === '<p>Bob is 30 years old</p>') {
        console.log('   ✅ Pass\n');
    } else {
        console.log('   ❌ Unexpected output\n');
        process.exit(1);
    }
} catch (error) {
    console.error(`   ❌ Error: ${error.message}\n`);
    process.exit(1);
}

// Test 7: HTML escaping
console.log('📋 Test 7: HTML escaping');
try {
    const template = 'p #{content}';
    const html = pug.compile(template, { content: '<script>alert("xss")</script>' });
    console.log(`   Input:  ${template}`);
    console.log(`   Output: ${html}`);
    const expected = '<p>&lt;script&gt;alert(&quot;xss&quot;)&lt;/script&gt;</p>';
    if (html === expected) {
        console.log('   ✅ Pass (XSS prevented)\n');
    } else {
        console.log('   ❌ Unexpected output');
        console.log(`   Expected: ${expected}\n`);
        process.exit(1);
    }
} catch (error) {
    console.error(`   ❌ Error: ${error.message}\n`);
    process.exit(1);
}

console.log('✨ All tests passed! zig-pug is working correctly.\n');
