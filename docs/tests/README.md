# Testing Documentation

Comprehensive testing guide for zig-pug.

---

## Overview

zig-pug has **87 unit tests** covering all major features and edge cases.

### Test Coverage

- ✅ **Parser** - Syntax parsing and validation
- ✅ **Compiler** - Template to HTML compilation
- ✅ **Variables** - All variable types (string, number, bool, array, object)
- ✅ **Conditionals** - if/else/unless logic
- ✅ **Loops** - each/while iterations
- ✅ **Mixins** - Reusable components
- ✅ **Inheritance** - extends/block system
- ✅ **UTF-8** - Unicode, emoji, accents
- ✅ **Edge Cases** - Error handling, malformed input

---

## Running Tests

### All Tests

```bash
zig build test
```

### With Verbose Output

```bash
zig build test --summary all
```

### CLI Tests Only

```bash
cd tests/cli
./run-tests.sh
```

---

## Test Structure

### Zig Tests

Located in `src/*.zig` files with `test` blocks:

```zig
test "basic tag rendering" {
    const allocator = testing.allocator;
    const template = "p Hello";
    const result = try compile(allocator, template);
    defer allocator.free(result);

    try testing.expectEqualStrings("<p>Hello</p>", result);
}
```

###  CLI Tests

Located in `tests/cli/*.sh`:

```bash
#!/usr/bin/env bash
# Test: Basic compilation

./zpug template.pug > output.html
expected="<p>Hello</p>"

if [ "$(cat output.html)" = "$expected" ]; then
    echo "✓ Test passed"
    exit 0
else
    echo "✗ Test failed"
    exit 1
fi
```

### Node.js Tests

Located in `nodejs/test/*.js`:

```javascript
const { compile } = require('../index.js');
const assert = require('assert');

describe('PugCompiler', () => {
    it('should compile basic template', () => {
        const html = compile('p Hello');
        assert.strictEqual(html, '<p>Hello</p>');
    });
});
```

---

## Test Categories

### 1. Parser Tests

Test the Pug syntax parser:

- Tag recognition
- Attribute parsing
- Class/ID shortcuts
- Indentation handling
- Comment parsing

### 2. Compiler Tests

Test HTML generation:

- Basic tags
- Nested structures
- Self-closing tags
- Doctype generation
- HTML escaping

### 3. Variable Tests

Test variable interpolation:

```zig
test "string interpolation" {
    // #{name} → actual value
}

test "number operations" {
    // #{count + 1} → calculations
}

test "boolean in conditionals" {
    // if isActive → conditional rendering
}

test "array iteration" {
    // each item in items → loops
}

test "object properties" {
    // #{user.name} → nested access
}
```

### 4. Control Flow Tests

Test conditionals and loops:

```zig
test "if statement" { }
test "if-else" { }
test "if-else if-else" { }
test "unless" { }
test "each with arrays" { }
test "each with index" { }
test "while loop" { }
```

### 5. Advanced Feature Tests

```zig
test "mixins without arguments" { }
test "mixins with arguments" { }
test "template inheritance" { }
test "block overrides" { }
test "extends chain" { }
```

### 6. UTF-8 Tests

```zig
test "accented characters" {
    // á é í ó ú ñ ü
}

test "emoji support" {
    // 🎉 🚀 ✨ 💯
}

test "chinese characters" {
    // 你好世界
}

test "arabic rtl" {
    // مرحبا
}
```

### 7. Edge Case Tests

```zig
test "empty template" { }
test "malformed syntax" { }
test "missing variables" { }
test "circular extends" { }
test "deep nesting" { }
test "large templates" { }
```

---

## Writing New Tests

### Test Template

```zig
const std = @import("std");
const testing = std.testing;
const zig_pug = @import("zig_pug");

test "descriptive test name" {
    // Arrange
    const allocator = testing.allocator;
    const template = "your pug template";
    const expected = "<expected>HTML</expected>";

    // Act
    const result = try zig_pug.compile(allocator, template);
    defer allocator.free(result);

    // Assert
    try testing.expectEqualStrings(expected, result);
}
```

### Best Practices

1. **Clear Names** - Describe what is being tested
2. **One Thing** - Test one feature per test
3. **Independent** - Tests should not depend on each other
4. **Fast** - Keep tests quick
5. **Clean Up** - Always free allocated memory

---

## Test Results Format

```
Test [1/87] test.basic_tag... OK
Test [2/87] test.nested_tags... OK
Test [3/87] test.classes... OK
...
Test [87/87] test.large_template... OK

All 87 tests passed!
```

---

## Continuous Integration

Tests run automatically on:

- Every commit (via git hooks)
- Every push (via GitHub Actions)
- Every pull request

### GitHub Actions

```yaml
name: Tests

on: [push, pull_request]

jobs:
  test:
    runs-on: ubuntu-latest
    steps:
      - uses: actions/checkout@v4
      - uses: goto-bus-stop/setup-zig@v2
        with:
          version: 0.15.2
      - run: zig build test
```

---

## Test Coverage Goals

| Component | Current | Goal |
|-----------|---------|------|
| **Parser** | 95% | 100% |
| **Compiler** | 90% | 100% |
| **Variables** | 100% | 100% |
| **Control Flow** | 95% | 100% |
| **Mixins** | 85% | 95% |
| **Inheritance** | 80% | 95% |
| **Edge Cases** | 70% | 90% |

---

## Benchmarks

Performance benchmarks are separate from unit tests:

```bash
zig build benchmark
```

See [BENCHMARKS.md](BENCHMARKS.md) for performance testing.

---

## Debugging Tests

### Run Single Test

```bash
zig test src/main.zig --test-filter "basic_tag"
```

### With Memory Leak Detection

```bash
zig build test -Doptimize=Debug
```

### With Valgrind

```bash
valgrind --leak-check=full ./zig-out/test/test-runner
```

---

## Contributing Tests

When adding features, always add tests:

1. Write the test first (TDD)
2. Run tests - they should fail
3. Implement the feature
4. Run tests - they should pass
5. Refactor if needed

See [CONTRIBUTING.md](../../CONTRIBUTING.md) for guidelines.

---

## Test Examples

Check `tests/` directory for examples:

- `tests/cli/` - CLI test scripts
- `src/*.zig` - Inline unit tests
- `nodejs/test/` - Node.js integration tests

---

**Last Updated:** 2025-12-16
**Test Count:** 87
**Coverage:** ~90%
