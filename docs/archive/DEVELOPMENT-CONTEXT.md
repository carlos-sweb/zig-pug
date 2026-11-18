# zig-pug Development Context

## Project Overview
High-performance Pug template engine written in Zig with mujs (ES5.1) runtime.

## Current Version
**v0.3.0** (Ready for production)

## Development Timeline

### Initial Development
- Created tokenizer, parser, compiler, runtime
- Integrated mujs for JavaScript expressions
- Basic Pug syntax support

### Phase 1-5 (Features)
- Phase 1: Multiple classes, loop iterators, mixin arguments
- Phase 2: Unbuffered code, attribute expressions, JSON variables
- Phase 3: Buffered code (=, !=), HTML escaping, error messages
- Phase 4: Performance optimizations (HTML escape, JS code gen)
- Phase 5: 87 comprehensive tests

### Phase 6 (Production vs Development)
- Production mode: strips comments by default
- Development mode: --pretty includes comments
- Industry standard behavior matching Pug.js

### Recent Session (Latest improvements)
1. **Comment handling** - Production vs development modes
2. **Strict error mode** - No output on compilation errors
3. **Pretty-print fixes:**
   - HTML comment indentation
   - Text-only tags on single line
   - Leading empty line removal
   - Void elements indentation
   - Nested tag closing indentation
4. **--format flag** - Pretty-print without comments

## Architecture

### Core Components
```
src/
├── tokenizer.zig    # Lexical analysis
├── parser.zig       # AST generation
├── compiler.zig     # HTML generation
├── runtime.zig      # mujs wrapper
└── cli.zig         # Command-line interface
```

### Runtime Integration
- Uses mujs (590KB) for ES5.1 JavaScript
- ~12 calls to runtime.eval() for expressions
- Future: Consider zig-expr (Zig-native expression evaluator)

## CLI Modes

| Flag | Indentation | Comments | Use Case |
|------|-------------|----------|----------|
| `--pretty` (`-p`) | ✅ | ✅ | Development/debugging |
| `--format` (`-F`) | ✅ | ❌ | Readable production |
| `--minify` (`-m`) | ❌ | ❌ | Optimized production |
| (none) | ❌ | ❌ | Default production |

## Testing
- **87 unit tests** - All passing ✅
- Test files in `tests/cli/*.zpug`
- Test output in `tests/cli/output/` (gitignored)

## Known Limitations
- JavaScript runtime: Only ES5.1 (via mujs)
- Uses ~5-7% of mujs capabilities
- No built-in date/array helpers (future: zig-expr)

## Future Roadmap

### v0.4.0 (Planned)
- `zig-expr` - Zig-native expression evaluator
- Date helpers (format_date, add_days, etc.)
- Array helpers (map, filter, sort_by, etc.)
- String helpers (capitalize, truncate, etc.)
- ~200KB binary reduction

### v0.5.0
- Watch mode implementation
- Source maps generation

## Build System

### Dependencies
- Zig 0.15.2
- mujs (embedded, built from source)
- No external runtime dependencies

### Build Commands
```bash
zig build              # Build zpug
zig build test         # Run tests
zig build install      # Install to /usr/local/bin
```

### Cross-compilation
Works on: Linux (x86_64, aarch64), macOS, Windows, Termux/Android

## Documentation
- README.md (English)
- README.es.md (Spanish)
- docs/en/CLI.md - Full CLI reference
- docs/en/FEATURES.md - Complete feature list
- docs/en/GETTING-STARTED.md - Tutorial

## Git Workflow
- Main branch: `main`
- Commit style: Conventional Commits
- All commits co-authored with Claude

## Key Design Decisions

1. **mujs over quickjs**: Smaller, simpler, sufficient for templates
2. **Strict error mode**: No output on errors (fail fast)
3. **Production by default**: Optimized output unless --pretty
4. **Pretty-print algorithm**: Context-aware indentation
5. **Comment stripping**: Industry standard (Pug, minifiers)

## Development Environment

### Termux/Android
- Alpine Linux in proot-distro
- Zig 0.15.2 compiled from source
- mujs built with custom Makefile

### Recommended Fedora Setup
```bash
# Install Zig
sudo dnf install zig

# Clone and build
git clone <repo> zig-pug
cd zig-pug
zig build

# Run tests
zig build test
```

## Performance
- Small templates (<1KB): ~0.1-0.5ms
- Medium templates (1-10KB): ~1-3ms
- Large templates (>10KB): ~5-10ms
- Binary size: ~5.4MB (mujs = 11%)

## Contact & Contributions
Project maintained with Claude Code assistance.

---
Generated: 2025-11-24
Version: 0.3.0
