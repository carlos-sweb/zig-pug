# zig-pug Development Plan

[Español](PLAN.es.md) | English

## 🎯 Project Vision

zig-pug aims to be the fastest, most complete Pug template engine implementation, leveraging Zig's performance and safety features while maintaining full compatibility with Pug syntax.

---

## ✅ Completed Features (v0.3.x)

### Core Template Engine
- ✅ Complete Pug syntax parser
- ✅ Tag rendering with attributes
- ✅ Classes and IDs shorthand (`.class`, `#id`)
- ✅ Doctype support
- ✅ Text content and interpolation
- ✅ HTML escaping and security

### JavaScript Integration
- ✅ mujs JavaScript engine integration
- ✅ ES5.1 JavaScript support
- ✅ Variable interpolation (`#{variable}`)
- ✅ JavaScript expressions in templates
- ✅ Method calls and operators

### Control Flow
- ✅ Conditionals: `if`, `else if`, `else`, `unless`
- ✅ Loops: `each` with arrays
- ✅ Loop variables (`item`, `index`)
- ✅ While loops

### Advanced Features
- ✅ Mixins with arguments
- ✅ Template inheritance (`extends`, `block`)
- ✅ JSON variables support (strings, numbers, bools, arrays, objects)
- ✅ Dynamic attribute values
- ✅ Documentation comments (`//!`)
- ✅ Buffered/unbuffered code (`=`, `!=`, `-`)

### Platform Support
- ✅ CLI binary (zpug)
- ✅ Node.js N-API addon
- ✅ Bun.js compatibility
- ✅ Cross-platform (Linux, macOS, Windows)
- ✅ Termux/Android support (CLI only)

### Testing & Quality
- ✅ 87 comprehensive unit tests
- ✅ Full UTF-8 support (emoji, accents, all Unicode)
- ✅ Memory safety (Zig guarantees)
- ✅ Performance optimizations

---

## 🚧 In Progress (v0.4.x)

### Documentation
- 🔄 Complete API reference
- 🔄 Extensive examples collection
- 🔄 Migration guide from Pug.js
- 🔄 Performance benchmarks documentation

### Build System
- 🔄 Prebuilt binaries for npm (in progress)
- 🔄 GitHub Actions CI/CD improvements
- 🔄 Automated cross-platform builds

---

## 📋 Planned Features

### Short Term (v0.4.x - v0.5.x)

#### Template Features
- [ ] **Includes** - `include template.pug`
- [ ] **Filters** - `:markdown`, `:coffee`, custom filters
- [ ] **Case statements** - `case`/`when` for cleaner conditionals
- [ ] **Mixin blocks** - Pass content blocks to mixins
- [ ] **Attribute interpolation** - `a(href="/user/#{id}")`

#### JavaScript Enhancements
- [ ] **Object/Array methods** - `.push()`, `.map()`, `.filter()`
- [ ] **JSON.parse/stringify**
- [ ] **Math object** - `Math.random()`, `Math.floor()`, etc.
- [ ] **String methods** - `.split()`, `.join()`, `.replace()`

#### Performance
- [ ] **Template caching** - Compile once, render many times
- [ ] **Partial compilation** - Pre-compile static parts
- [ ] **Memory pooling** - Reduce allocations
- [ ] **SIMD optimizations** - Faster string operations

### Medium Term (v0.6.x - v0.8.x)

#### Advanced Features
- [ ] **Template compilation** - Generate standalone functions
- [ ] **Source maps** - Better error debugging
- [ ] **Watch mode** - Auto-recompile on changes
- [ ] **Plugin system** - Custom tags, filters, functions

#### Ecosystem
- [ ] **Express.js integration** - View engine adapter
- [ ] **Vite plugin** - HMR support for Pug templates
- [ ] **Webpack loader** - Build-time compilation
- [ ] **Deno support** - Native Deno module

#### Developer Experience
- [ ] **VS Code extension** - Syntax highlighting, snippets, IntelliSense
- [ ] **Language server** - Auto-completion, go-to-definition
- [ ] **Formatter** - Automatic code formatting
- [ ] **Linter** - Catch errors before compilation

### Long Term (v1.0.x+)

#### Production Ready
- [ ] **100% Pug.js compatibility** - Pass all official tests
- [ ] **Security audit** - Professional review
- [ ] **Performance benchmarks** - vs Pug.js, vs other engines
- [ ] **Stability guarantees** - Semantic versioning

#### Advanced Optimizations
- [ ] **Static analysis** - Compile-time optimizations
- [ ] **Tree shaking** - Remove unused mixins/variables
- [ ] **Minification** - Smallest possible output
- [ ] **Streaming rendering** - For large documents

#### Enterprise Features
- [ ] **Custom directives** - Framework-specific extensions
- [ ] **Async templates** - Await async data
- [ ] **Parallel rendering** - Multi-threaded compilation
- [ ] **Cloud functions** - Serverless deployment guides

---

## 🎨 Design Principles

1. **Performance First** - Every feature must be fast
2. **Safety** - Leverage Zig's compile-time checks
3. **Simplicity** - Clear, maintainable code
4. **Compatibility** - Work everywhere Node.js works
5. **Zero Dependencies** - Only Zig + embedded mujs
6. **Great DX** - Excellent error messages and tooling

---

## 📊 Benchmarks Goals

Target performance vs Pug.js:

| Metric | Current | Goal |
|--------|---------|------|
| **Compilation** | ~2x faster | 5x faster |
| **Rendering** | ~3x faster | 10x faster |
| **Memory** | ~50% less | 70% less |
| **Binary size** | 2.4 MB | < 2 MB |

---

## 🤝 Contributing

We welcome contributions! Priority areas:

1. **Documentation** - Examples, guides, API docs
2. **Testing** - More test cases, edge cases
3. **Features** - Implement items from the roadmap
4. **Bug fixes** - Report and fix issues
5. **Performance** - Optimize hot paths

See [CONTRIBUTING.md](CONTRIBUTING.md) for guidelines.

---

## 📅 Release Schedule

- **v0.4.x** - Q1 2026 - Documentation, prebuilt binaries
- **v0.5.x** - Q2 2026 - Includes, filters, caching
- **v0.6.x** - Q3 2026 - Plugins, Express integration
- **v0.7.x** - Q4 2026 - Advanced optimizations
- **v1.0.0** - 2027 - Production ready, full compatibility

*Schedule is tentative and subject to change*

---

## 🔗 Related Projects

- [Pug.js](https://pugjs.org/) - Original JavaScript implementation
- [pug-rs](https://github.com/tlack/pug-rs) - Rust implementation
- [pug-php](https://github.com/pug-php/pug) - PHP implementation

---

## 📝 Notes

This is a living document. The roadmap evolves based on:
- User feedback and feature requests
- Performance profiling results
- Ecosystem changes (new Node.js versions, etc.)
- Available development time

Have ideas? Open an issue or discussion on [GitHub](https://github.com/carlos-sweb/zig-pug/discussions)!

---

**Last Updated:** 2025-12-16
**Current Version:** 0.3.7
