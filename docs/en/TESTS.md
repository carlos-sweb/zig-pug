# Testing Guide

Complete guide to testing zig-pug templates and integrations.

## Table of Contents

- [Test Suites](#test-suites)
- [Running Tests](#running-tests)
- [Writing Tests](#writing-tests)
- [Integration Testing](#integration-testing)
- [Best Practices](#best-practices)

## Test Suites

zig-pug has comprehensive test coverage across multiple layers:

### 1. Zig Unit Tests (87 tests)

**Location:** `src/` (embedded in source files)

**Coverage:**
- Tokenizer (lexical analysis)
- Parser (syntax analysis)
- AST (data structures)
- Compiler (HTML generation)
- Runtime (JavaScript evaluation)
- Formatter (HTML formatting)

**Run:**
```bash
zig build test
```

### 2. Node.js Tests

**Location:** `nodejs/`

**Coverage:**
- Node.js addon (N-API bindings)
- CommonJS/ESM compatibility
- Variable injection
- Output formatting
- Error handling

**Run:**
```bash
cd nodejs
bun test-cjs.js
bun test-pretty.js
bun test-arrays-objects.js
```

### 3. CLI Tests

**Location:** `examples/`

**Coverage:**
- Command-line interface
- File I/O
- Variable flags (`--var`, `--array`, `--vars`)
- Output modes (`--pretty`, `--format`, `--minify`)

**Run:**
```bash
./zig-out/bin/zpug examples/01-basic.zpug
./zig-out/bin/zpug -F examples/loops.zpug
```

### 4. Documentation Tests

**Location:** `check-links.sh`

**Coverage:**
- Markdown documentation
- Internal links
- External references

**Run:**
```bash
./check-links.sh
```

## Running Tests

### All Tests

```bash
# Zig unit tests
zig build test

# Node.js tests
cd nodejs
bun test-cjs.js
bun test-pretty.js
bun test-arrays-objects.js

# CLI manual tests
./zig-out/bin/zpug examples/*.zpug

# Documentation links
./check-links.sh
```

### Specific Test Suites

**Tokenizer only:**
```bash
zig test src/tokenizer/tests.zig
```

**Parser only:**
```bash
zig test src/parser/mod.zig
```

**Compiler only:**
```bash
zig test src/compiler/mod.zig
```

### Verbose Output

```bash
# Show all test names and results
zig build test --summary all

# Show detailed failures
zig build test 2>&1 | less
```

### Watch Mode

```bash
# Using entr (install: apt install entr)
find src -name "*.zig" | entr -c zig build test
```

## Writing Tests

### Zig Unit Tests

**Location:** Embedded in source files

**Pattern:**
```zig
test "description of what is tested" {
    const allocator = std.testing.allocator;

    // Setup
    const input = "test data";

    // Execute
    const result = try functionToTest(allocator, input);
    defer allocator.free(result);

    // Assert
    try std.testing.expectEqual(expected, result);
    try std.testing.expectEqualStrings("expected", result);
}
```

**Example (tokenizer test):**
```zig
test "tokenize simple tag" {
    const allocator = std.testing.allocator;
    const source = "p Hello";

    var tokenizer = try Tokenizer.init(allocator, source);
    defer tokenizer.deinit();

    const t1 = try tokenizer.next();
    try std.testing.expectEqual(.Ident, t1.type);
    try std.testing.expectEqualStrings("p", t1.value);

    const t2 = try tokenizer.next();
    try std.testing.expectEqual(.Ident, t2.type);
    try std.testing.expectEqualStrings("Hello", t2.value);

    const t3 = try tokenizer.next();
    try std.testing.expectEqual(.Eof, t3.type);
}
```

### Node.js Tests

**Location:** `nodejs/test-*.js`

**Pattern:**
```javascript
const assert = require('assert');
const zigpug = require('./index.js');

// Test case
try {
    const html = zigpug.compile('p Hello #{name}', { name: 'World' });
    assert.strictEqual(html, '<p>Hello World</p>');
    console.log('✓ Test passed');
} catch (error) {
    console.error('✗ Test failed:', error.message);
    process.exit(1);
}
```

**Example (arrays test):**
```javascript
// nodejs/test-arrays-objects.js
const zigpug = require('./index.js');
const assert = require('assert');

const template = `
ul
  each item in items
    li= item
`;

const html = zigpug.compile(template, {
    items: ['apple', 'banana', 'orange']
});

const expected = '<ul><li>apple</li><li>banana</li><li>orange</li></ul>';
assert.strictEqual(html, expected);

console.log('✓ Arrays test passed');
```

### Integration Tests

**Pattern:**
```javascript
// test/integration/express.test.js
const express = require('express');
const request = require('supertest');
const zigpug = require('zig-pug');
const fs = require('fs');

const app = express();

const template = fs.readFileSync('./views/home.pug', 'utf-8');

app.get('/', (req, res) => {
    const html = zigpug.compile(template, {
        title: 'Home',
        user: { name: 'Test User' }
    });
    res.send(html);
});

// Test
request(app)
    .get('/')
    .expect(200)
    .expect(/Test User/)
    .end((err) => {
        if (err) throw err;
        console.log('✓ Express integration test passed');
    });
```

## Integration Testing

### Testing with Express

```javascript
// test/server.test.js
const app = require('../server');
const request = require('supertest');

describe('Server Integration', () => {
    it('should render homepage', async () => {
        const res = await request(app).get('/');
        expect(res.status).toBe(200);
        expect(res.text).toContain('<h1>Welcome</h1>');
    });

    it('should render with variables', async () => {
        const res = await request(app)
            .get('/user/123')
            .expect(200);
        expect(res.text).toContain('User #123');
    });
});
```

### Testing Template Rendering

```javascript
// test/templates.test.js
const { PugCompiler } = require('zig-pug');
const fs = require('fs');

describe('Template Rendering', () => {
    let compiler;

    beforeEach(() => {
        compiler = new PugCompiler();
    });

    it('should render user profile', () => {
        const template = fs.readFileSync('./views/profile.pug', 'utf-8');
        compiler.setObject('user', {
            name: 'Alice',
            email: 'alice@example.com'
        });

        const html = compiler.compile(template);
        expect(html).toContain('Alice');
        expect(html).toContain('alice@example.com');
    });

    it('should handle missing data gracefully', () => {
        const template = 'p #{user.name || "Guest"}';
        compiler.setObject('user', {});

        const html = compiler.compile(template);
        expect(html).toContain('Guest');
    });
});
```

### Testing Error Handling

```javascript
// test/errors.test.js
const zigpug = require('zig-pug');

describe('Error Handling', () => {
    it('should throw on invalid syntax', () => {
        expect(() => {
            zigpug.compile('p(invalid attribute)');
        }).toThrow();
    });

    it('should provide error details', () => {
        try {
            zigpug.compile('p #{nonExistent}');
        } catch (error) {
            expect(error.message).toContain('nonExistent');
            expect(error.compilationErrors).toBeDefined();
        }
    });

    it('should handle undefined variables', () => {
        const template = 'p #{user.name}';
        expect(() => {
            zigpug.compile(template, {});
        }).toThrow(/undefined/);
    });
});
```

### Testing Output Formats

```javascript
// test/formats.test.js
const { PugCompiler } = require('zig-pug');

describe('Output Formats', () => {
    const template = 'div\n  h1 Title\n  p Content';

    it('should minify by default', () => {
        const html = new PugCompiler().compile(template);
        expect(html).not.toContain('\n');
        expect(html).toBe('<div><h1>Title</h1><p>Content</p></div>');
    });

    it('should format with indentation', () => {
        const html = new PugCompiler({ format: true }).compile(template);
        expect(html).toContain('\n');
        expect(html).toContain('  ');  // Indentation
    });

    it('should include comments in pretty mode', () => {
        const template = '// Comment\np Text';
        const html = new PugCompiler({ pretty: true }).compile(template);
        expect(html).toContain('<!-- Comment -->');
    });
});
```

## Best Practices

### 1. Test Template Logic

**❌ Bad (no tests):**
```pug
if user.age >= 18
  p Adult
else
  p Minor
```

**✅ Good (tested):**
```javascript
describe('Age check template', () => {
    it('should show Adult for age >= 18', () => {
        const html = compiler.compile(template, { user: { age: 18 } });
        expect(html).toContain('Adult');
    });

    it('should show Minor for age < 18', () => {
        const html = compiler.compile(template, { user: { age: 17 } });
        expect(html).toContain('Minor');
    });
});
```

### 2. Test Edge Cases

```javascript
describe('Edge cases', () => {
    it('should handle empty arrays', () => {
        const template = 'each item in items\n  p= item\nelse\n  p No items';
        const html = compiler.compile(template, { items: [] });
        expect(html).toContain('No items');
    });

    it('should handle null values', () => {
        const template = 'p #{value || "N/A"}';
        const html = compiler.compile(template, { value: null });
        expect(html).toContain('N/A');
    });

    it('should handle special characters', () => {
        const template = 'p #{text}';
        const html = compiler.compile(template, { text: '<script>alert("XSS")</script>' });
        expect(html).toContain('&lt;script&gt;');
    });
});
```

### 3. Test with Real Data

```javascript
// fixtures/users.json
[
    {"name": "Alice", "age": 30, "role": "admin"},
    {"name": "Bob", "age": 25, "role": "user"}
]

// test
const users = require('./fixtures/users.json');

it('should render user list', () => {
    const html = compiler.compile(template, { users });
    expect(html).toContain('Alice');
    expect(html).toContain('Bob');
});
```

### 4. Snapshot Testing

```javascript
const fs = require('fs');

it('should match snapshot', () => {
    const html = compiler.compile(template, data);

    const snapshotPath = './test/snapshots/user-profile.html';

    if (!fs.existsSync(snapshotPath)) {
        fs.writeFileSync(snapshotPath, html);
    }

    const snapshot = fs.readFileSync(snapshotPath, 'utf-8');
    expect(html).toBe(snapshot);
});
```

### 5. Performance Testing

```javascript
describe('Performance', () => {
    it('should compile 1000 templates in under 1 second', () => {
        const start = Date.now();

        for (let i = 0; i < 1000; i++) {
            compiler.compile(template, data);
        }

        const elapsed = Date.now() - start;
        expect(elapsed).toBeLessThan(1000);
    });
});
```

### 6. Security Testing

```javascript
describe('Security', () => {
    it('should escape HTML by default', () => {
        const html = compiler.compile('p #{input}', {
            input: '<script>alert("XSS")</script>'
        });
        expect(html).not.toContain('<script>');
        expect(html).toContain('&lt;script&gt;');
    });

    it('should prevent XSS in attributes', () => {
        const html = compiler.compile('a(href=url) Link', {
            url: 'javascript:alert("XSS")'
        });
        // Should be escaped
        expect(html).not.toContain('javascript:');
    });
});
```

## Test Coverage

### Measuring Coverage

**For Node.js tests:**
```bash
npm install --save-dev nyc

# Run with coverage
nyc node test-all.js

# Generate HTML report
nyc --reporter=html node test-all.js
open coverage/index.html
```

### Coverage Goals

- **Statements:** > 80%
- **Branches:** > 75%
- **Functions:** > 80%
- **Lines:** > 80%

## Continuous Integration

### GitHub Actions

**.github/workflows/test.yml:**
```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest

    steps:
      - uses: actions/checkout@v3

      - name: Install Zig
        uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.2

      - name: Run Zig tests
        run: zig build test

      - name: Setup Node.js
        uses: actions/setup-node@v3
        with:
          node-version: '18'

      - name: Install dependencies
        run: npm install

      - name: Build addon
        run: npm run build

      - name: Run Node.js tests
        run: |
          cd nodejs
          node test-cjs.js
          node test-pretty.js
```

## Debugging Failed Tests

### Verbose Test Output

```bash
# Zig tests with full output
zig build test --summary all 2>&1 | tee test-output.txt

# Node.js tests with stack traces
node --trace-warnings test.js
```

### Isolate Failing Test

```zig
test "specific test only" {
    // Use --test-filter flag
    // zig test src/file.zig --test-filter "specific test only"
}
```

### Add Debug Output

```zig
test "debug test" {
    std.debug.print("Debug: value = {}\n", .{value});
    try std.testing.expectEqual(expected, actual);
}
```

## See Also

- [CONTRIBUTING.md](../../CONTRIBUTING.md) - Contributing guidelines
- [../ARCHITECTURE.md](../ARCHITECTURE.md) - Architecture overview
- [OPTIMIZATION.md](OPTIMIZATION.md) - Performance testing
- [ERROR-MESSAGES.md](ERROR-MESSAGES.md) - Error handling
