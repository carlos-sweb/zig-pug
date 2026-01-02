# Contributing to zig-pug

Thank you for your interest in contributing to zig-pug! This document provides guidelines and instructions for contributing to the project.

## 📋 Table of Contents

- [Code of Conduct](#code-of-conduct)
- [Getting Started](#getting-started)
- [Development Setup](#development-setup)
- [How to Contribute](#how-to-contribute)
- [Coding Guidelines](#coding-guidelines)
- [Testing](#testing)
- [Documentation](#documentation)
- [Pull Request Process](#pull-request-process)

## 🤝 Code of Conduct

This project follows a simple code of conduct:

- **Be respectful** and considerate in all interactions
- **Be patient** with newcomers to the project
- **Be constructive** when providing feedback
- **Focus on what is best** for the community and the project

## 🚀 Getting Started

### Prerequisites

- **Zig 0.15.2** ([download](https://ziglang.org/download/))
- Git
- Basic knowledge of:
  - Zig programming language
  - Template engines (Pug/Jade)
  - JavaScript (for runtime integration)

### Development Setup

1. **Fork and clone the repository:**
   ```bash
   git clone https://github.com/YOUR-USERNAME/zig-pug
   cd zig-pug
   ```

2. **Build the project:**
   ```bash
   zig build
   ```

3. **Run tests:**
   ```bash
   zig build test
   ```

4. **Test the CLI:**
   ```bash
   ./zig-out/bin/zig-pug examples/01-basic.zpug
   ```

## 💡 How to Contribute

### Reporting Bugs

Found a bug? Please help us fix it!

1. **Check existing issues** to avoid duplicates
2. **Create a new issue** with:
   - Clear, descriptive title
   - Steps to reproduce the bug
   - Expected vs actual behavior
   - Zig version and OS
   - Code sample (minimal reproducible example)

### Suggesting Enhancements

Have an idea for improvement?

1. **Check discussions** for similar ideas
2. **Open an issue** describing:
   - The problem your enhancement solves
   - How it would work
   - Potential implementation approach
   - Examples of usage

### Contributing Code

1. **Pick an issue** or create one
2. **Comment on the issue** to let others know you're working on it
3. **Fork the repository**
4. **Create a feature branch:** `git checkout -b feature/my-feature`
5. **Make your changes** (see Coding Guidelines below)
6. **Test your changes** thoroughly
7. **Commit with clear messages** (see commit guidelines)
8. **Push to your fork**
9. **Create a Pull Request**

## 📝 Coding Guidelines

### Zig Code Style

Follow the official Zig style guide and project conventions:

```zig
// Good: Clear naming, proper indentation
pub fn prettyPrintHtml(allocator: std.mem.Allocator, html: []const u8) ![]const u8 {
    var result = std.ArrayList(u8){};
    // ... implementation
    return result.toOwnedSlice(allocator);
}

// Avoid: Unclear names, inconsistent style
pub fn pp(a: anytype, h: []u8) ![]u8 {
    // ...
}
```

**Key points:**
- Use meaningful variable and function names
- Keep functions focused and small
- Document public APIs with doc comments
- Handle errors properly (don't ignore them)
- Use `const` when possible
- Follow 4-space indentation

### Project Structure

```
src/
├── tokenizer/    # Lexical analysis
├── parser/       # Syntax analysis
├── compiler/     # HTML generation
├── formatter.zig # HTML formatting (pretty/minify)
├── runtime.zig   # JavaScript runtime (mujs)
├── cli.zig       # Command-line interface
└── lib.zig       # C API / Library interface
```

**Guidelines:**
- **New features:** Consider which phase they belong to
- **Bug fixes:** Identify the correct module
- **Formatting:** Use shared `formatter.zig` module
- **Cross-cutting:** Discuss architecture first

### Commit Messages

Write clear, descriptive commit messages:

```
Good commit message format:

<type>: <short summary> (50 chars or less)

<Detailed explanation if needed>
- What changed
- Why it changed
- Any breaking changes

Example:
fix: Prevent trailing space in text content at EOF

Fixed tokenizer EOF handling to properly transition state
to Root instead of remaining in Text state, which was
causing empty tokens and trailing spaces.

- Updated src/tokenizer/scanText.zig
- Updated src/parser/text.zig to skip empty tokens
- Added tests for EOF without final newline
```

**Commit types:**
- `feat`: New feature
- `fix`: Bug fix
- `docs`: Documentation changes
- `refactor`: Code refactoring
- `test`: Adding or updating tests
- `perf`: Performance improvements
- `chore`: Maintenance tasks

## ✅ Testing

### Running Tests

```bash
# Run all Zig unit tests
zig build test

# Run Node.js tests
cd nodejs
bun test-cjs.js
bun test-pretty.js
bun test-arrays-objects.js

# Run CLI tests
./check-links.sh  # Check documentation links
```

### Writing Tests

Add tests for:
- **New features:** Test happy path and edge cases
- **Bug fixes:** Add regression test
- **API changes:** Update existing tests

Example test structure:

```zig
test "tokenizer handles EOF without newline" {
    const allocator = std.testing.allocator;
    const source = "p World";  // No final newline

    var tokenizer = try Tokenizer.init(allocator, source);
    defer tokenizer.deinit();

    // Test implementation...
    try std.testing.expectEqual(expected, actual);
}
```

## 📚 Documentation

Good documentation is as important as good code!

### Documentation Requirements

- **Code comments:** Explain *why*, not *what*
- **Doc comments:** For all public APIs
- **README updates:** For new features
- **Architecture docs:** For significant changes

### Documentation Files

When adding features, update:
- `README.md` - User-facing features
- `docs/ARCHITECTURE.md` - Internal architecture
- `docs/tokenizer.md`, `parser.md`, `compiler.md` - Component docs
- `CHANGELOG.md` - Version history

### Writing Style

- Use clear, concise language
- Include code examples
- Explain edge cases
- Link to related documentation

## 🔄 Pull Request Process

### Before Submitting

- [ ] Code follows project style
- [ ] All tests pass
- [ ] New tests added for new features/fixes
- [ ] Documentation updated
- [ ] Commits are clean and descriptive
- [ ] Branch is up to date with main

### PR Description Template

```markdown
## Description
Brief description of what this PR does

## Type of Change
- [ ] Bug fix
- [ ] New feature
- [ ] Documentation update
- [ ] Refactoring
- [ ] Performance improvement

## Changes Made
- Detailed list of changes
- Why each change was necessary

## Testing
- How was this tested?
- What test cases were added?

## Related Issues
Closes #123
Related to #456

## Checklist
- [ ] Tests pass
- [ ] Documentation updated
- [ ] No breaking changes (or documented if unavoidable)
```

### Review Process

1. **Automated checks** must pass (tests, linting)
2. **Code review** by maintainers
3. **Feedback incorporated** if needed
4. **Approval** from at least one maintainer
5. **Merge** to main branch

### After Merge

Your contribution will be:
- Included in the next release
- Credited in CHANGELOG.md
- Appreciated by the community! 🎉

## 🎯 Development Tips

### Quick Development Cycle

```bash
# Fast rebuild and test
zig build && ./zig-out/bin/zig-pug test.zpug

# Watch mode (using entr or similar)
find src -name "*.zig" | entr -c zig build test
```

### Debugging

```zig
// Use std.debug.print for debugging
std.debug.print("Debug: value = {}\n", .{value});

// Use zig build with debug info
zig build -Doptimize=Debug
```

### Common Tasks

- **Add a new keyword:** Update `src/tokenizer/TokenType.zig` and `scanIdentifier.zig`
- **Add a new tag feature:** Modify `src/parser/tag.zig` and `src/compiler/mod.zig`
- **Fix formatting:** Update `src/formatter.zig` (shared by CLI and API)

## 🤔 Questions?

- **General questions:** [GitHub Discussions](https://github.com/carlos-sweb/zig-pug/discussions)
- **Bug reports:** [GitHub Issues](https://github.com/carlos-sweb/zig-pug/issues)
- **Real-time chat:** Check README for community links

## 📄 License

By contributing to zig-pug, you agree that your contributions will be licensed under the [MIT License](LICENSE).

---

Thank you for contributing to zig-pug! Every contribution, no matter how small, makes a difference. 🙏
