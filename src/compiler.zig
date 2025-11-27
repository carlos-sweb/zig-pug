//! Compiler module - Code Generation
//!
//! This module converts an Abstract Syntax Tree (AST) into HTML output.
//! It's the final phase of the compilation pipeline.
//!
//! Flow:
//! 1. Compiler.init() creates compiler with JavaScript runtime
//! 2. compile() walks AST and generates HTML
//! 3. Each node type has its own compile function
//! 4. Returns complete HTML string
//!
//! Example:
//! ```zig
//! var parser = try Parser.init(allocator, source);
//! defer parser.deinit();
//!
//! const document = try parser.parse();
//!
//! var js_runtime = try runtime.JsRuntime.init(allocator);
//! defer js_runtime.deinit();
//!
//! var compiler = try Compiler.init(allocator, js_runtime);
//! defer compiler.deinit();
//!
//! const html = try compiler.compile(document);
//! defer allocator.free(html);
//! ```
//!
//! Compiler features:
//! - HTML generation from AST nodes
//! - JavaScript expression evaluation via runtime
//! - Template inheritance (extends/block)
//! - Mixin definitions and calls
//! - Include directive support
//! - Pretty-print mode with indentation
//! - Comment inclusion control
//! - Template caching
//!
//! Output modes:
//! - Standard: Minified HTML (no indentation, no comments)
//! - Pretty: Indented HTML with comments (--pretty flag)
//! - Format: Indented HTML without comments (--format flag)

const std = @import("std");
const ast = @import("ast.zig");
const runtime = @import("runtime.zig");
const cache = @import("cache.zig");
const Parser = @import("parser.zig").Parser;

/// Errors that can occur during compilation
///
/// - OutOfMemory: Allocation failed
/// - RuntimeError: JavaScript evaluation error
/// - InvalidNode: Malformed AST node
/// - MixinNotFound: Called undefined mixin
/// - IncludeFileNotFound: Include file doesn't exist
/// - IncludeParseError: Include file has syntax errors
/// - LoopIterableNotArray: Loop target isn't an array
/// - ExtendsFileNotFound: Parent template doesn't exist
/// - ExtendsParseError: Parent template has syntax errors
pub const CompilerError = error{
    OutOfMemory,
    RuntimeError,
    InvalidNode,
    MixinNotFound,
    IncludeFileNotFound,
    IncludeParseError,
    LoopIterableNotArray,
    ExtendsFileNotFound,
    ExtendsParseError,
};

/// Compiler - Generates HTML from AST
///
/// Stateful code generator that walks AST and outputs HTML.
/// Maintains context for template features like mixins, blocks, includes.
///
/// Fields:
/// - allocator: Memory allocator
/// - runtime: JavaScript runtime for expression evaluation
/// - output: HTML output buffer
/// - indent_level: Current indentation depth (for pretty mode)
/// - pretty: Enable indentation and formatting
/// - mixins: Map of mixin name → definition node
/// - base_path: Directory path for resolving relative includes
/// - template_cache: Optional cache for compiled includes
/// - child_blocks: Blocks defined in child template (for extends)
/// - include_comments: Whether to emit HTML comments
/// - has_errors: Whether any errors occurred (strict mode)
///
/// Usage:
/// ```zig
/// var compiler = try Compiler.init(allocator, js_runtime);
/// defer compiler.deinit();
///
/// compiler.pretty = true;  // Enable pretty-print
/// const html = try compiler.compile(ast_document);
/// defer allocator.free(html);
/// ```
pub const Compiler = struct {
    allocator: std.mem.Allocator,
    runtime: *runtime.JsRuntime,
    output: std.ArrayList(u8),
    indent_level: usize,
    pretty: bool, // Enable pretty printing with indentation
    mixins: std.StringHashMap(*ast.AstNode), // Store mixin definitions
    base_path: ?[]const u8, // Base path for resolving includes
    template_cache: ?*cache.TemplateCache, // Optional template cache
    child_blocks: std.StringHashMap(std.ArrayListUnmanaged(*ast.AstNode)), // Blocks from child template
    include_comments: bool, // Include HTML comments in output (true for --pretty, false for production)
    has_errors: bool, // Track if any compilation errors occurred (for strict mode)

    const Self = @This();

    /// Initialize compiler with JavaScript runtime
    ///
    /// Parameters:
    /// - allocator: Memory allocator
    /// - js_runtime: JavaScript runtime for evaluating expressions
    ///
    /// Returns: Initialized compiler
    ///
    /// Example:
    /// ```zig
    /// var js_runtime = try runtime.JsRuntime.init(allocator);
    /// defer js_runtime.deinit();
    ///
    /// var compiler = try Compiler.init(allocator, js_runtime);
    /// defer compiler.deinit();
    /// ```
    pub fn init(allocator: std.mem.Allocator, js_runtime: *runtime.JsRuntime) !*Self {
        const compiler = try allocator.create(Self);
        compiler.* = .{
            .allocator = allocator,
            .runtime = js_runtime,
            .output = .{},
            .indent_level = 0,
            .pretty = false,
            .include_comments = false, // Production default: no comments
            .has_errors = false, // Start with no errors
            .mixins = std.StringHashMap(*ast.AstNode).init(allocator),
            .base_path = null,
            .template_cache = null,
            .child_blocks = std.StringHashMap(std.ArrayListUnmanaged(*ast.AstNode)).init(allocator),
        };
        return compiler;
    }

    /// Set base directory path for resolving relative includes
    ///
    /// When template uses 'include header.pug', this path is used
    /// to locate the included file.
    ///
    /// Parameters:
    /// - path: Absolute or relative path to template directory
    pub fn setBasePath(self: *Self, path: []const u8) void {
        self.base_path = path;
    }

    /// Set template cache for faster compilation
    ///
    /// Cache stores parsed and compiled templates to avoid
    /// re-parsing includes on every compilation.
    ///
    /// Parameters:
    /// - template_cache: Cache instance to use
    pub fn setCache(self: *Self, template_cache: *cache.TemplateCache) void {
        self.template_cache = template_cache;
    }

    /// Free compiler resources
    ///
    /// Cleans up output buffer, mixin map, and block map.
    pub fn deinit(self: *Self) void {
        self.output.deinit(self.allocator);
        self.mixins.deinit();
        self.child_blocks.deinit();
        self.allocator.destroy(self);
    }

    /// Compile AST document to HTML string
    ///
    /// Main entry point for compilation. Walks the AST and
    /// generates HTML output based on compiler settings.
    ///
    /// Parameters:
    /// - node: Root AST node (usually Document)
    ///
    /// Returns: HTML string (caller owns memory)
    ///
    /// Example:
    /// ```zig
    /// const html = try compiler.compile(document);
    /// defer allocator.free(html);
    /// ```
    pub fn compile(self: *Self, node: *ast.AstNode) ![]const u8 {
        try self.compileNode(node);
        return try self.output.toOwnedSlice(self.allocator);
    }

    /// Dispatch compilation to appropriate function based on node type
    ///
    /// Central dispatcher that routes each AST node type to its
    /// corresponding compile function.
    fn compileNode(self: *Self, node: *ast.AstNode) anyerror!void {
        switch (node.data) {
            .Document => try self.compileDocument(node),
            .Tag => try self.compileTag(node),
            .Text => try self.compileText(node),
            .Interpolation => try self.compileInterpolation(node),
            .Code => try self.compileCode(node),
            .Comment => try self.compileComment(node),
            .Conditional => try self.compileConditional(node),
            .Loop => try self.compileLoop(node),
            .MixinDef => try self.registerMixin(node),
            .MixinCall => try self.compileMixinCall(node),
            .Include => try self.compileInclude(node),
            .Block => try self.compileBlock(node),
            .Extends => {}, // Handled by compileDocument
            .Case => try self.compileCase(node),
            .When => {}, // Handled by Case
        }
    }

    // ========================================================================
    // Document Compilation
    // ========================================================================

    /// Compile root Document node
    ///
    /// Handles:
    /// 1. Doctype declaration output
    /// 2. Mixin registration
    /// 3. Template inheritance (extends)
    /// 4. Block collection for child templates
    /// 5. Normal content compilation
    fn compileDocument(self: *Self, node: *ast.AstNode) !void {
        const doc = &node.data.Document;

        // Output doctype if present
        if (doc.doctype) |doctype_value| {
            try self.output.appendSlice(self.allocator, "<!DOCTYPE ");
            try self.output.appendSlice(self.allocator, doctype_value);
            try self.output.appendSlice(self.allocator, ">");
        }

        // First pass: register all mixins and check for extends
        var extends_path: ?[]const u8 = null;
        for (doc.children.items) |child| {
            if (child.type == .MixinDef) {
                try self.registerMixin(child);
            } else if (child.type == .Extends) {
                extends_path = child.data.Extends.path;
            } else if (child.type == .Block) {
                // Collect blocks from child template
                const block_data = &child.data.Block;
                try self.child_blocks.put(block_data.name, block_data.body);
            }
        }

        // If extends, load and compile parent template
        if (extends_path) |parent_path| {
            try self.compileExtends(parent_path);
            return;
        }

        // No extends: compile everything else normally
        for (doc.children.items) |child| {
            if (child.type != .MixinDef and child.type != .Extends and child.type != .Block) {
                try self.compileNode(child);
            }
        }
    }

    // ========================================================================
    // Template Inheritance (Extends/Block)
    // ========================================================================

    /// Compile extends directive - load and compile parent template
    ///
    /// Resolves parent template path, loads and parses it,
    /// then compiles with child blocks available for override.
    fn compileExtends(self: *Self, parent_path: []const u8) !void {
        // Resolve path relative to base_path
        const full_path = if (self.base_path) |base| blk: {
            const dir = std.fs.path.dirname(base) orelse ".";
            break :blk try std.fs.path.join(self.allocator, &.{ dir, parent_path });
        } else blk: {
            break :blk try self.allocator.dupe(u8, parent_path);
        };
        defer self.allocator.free(full_path);

        // Read parent file
        const file_content = std.fs.cwd().readFileAlloc(
            self.allocator,
            full_path,
            1024 * 1024, // 1MB max
        ) catch |err| {
            std.debug.print("Error reading extends file '{s}': {}\n", .{ full_path, err });
            return error.ExtendsFileNotFound;
        };
        defer self.allocator.free(file_content);

        // Parse parent template
        var parser = Parser.init(self.allocator, file_content) catch |err| {
            std.debug.print("Error parsing extends file '{s}': {}\n", .{ full_path, err });
            return error.ExtendsParseError;
        };
        defer parser.deinit();

        const parent_ast = parser.parse() catch |err| {
            std.debug.print("Error parsing extends file '{s}': {}\n", .{ full_path, err });
            return error.ExtendsParseError;
        };

        // Compile parent template (blocks will be substituted via child_blocks)
        try self.compileNode(parent_ast);
    }

    /// Compile block directive
    ///
    /// If child template overrode this block (in child_blocks map),
    /// use child content. Otherwise use default content.
    fn compileBlock(self: *Self, node: *ast.AstNode) !void {
        const block = &node.data.Block;

        // Check if child template has overridden this block
        if (self.child_blocks.get(block.name)) |child_body| {
            // Render child block content
            for (child_body.items) |child| {
                try self.compileNode(child);
            }
        } else {
            // Render default block content
            for (block.body.items) |child| {
                try self.compileNode(child);
            }
        }
    }

    // ========================================================================
    // Tag Compilation
    // ========================================================================

    /// Compile HTML tag element
    ///
    /// Generates opening tag, attributes, content, and closing tag.
    /// Handles void elements (img, input, br, etc.) correctly.
    /// Applies pretty-print indentation if enabled.
    fn compileTag(self: *Self, node: *ast.AstNode) !void {
        const tag = &node.data.Tag;

        // Don't render empty tag names (fragment containers from parsePipeText)
        if (tag.name.len == 0) {
            // Just render children
            for (tag.children.items) |child| {
                try self.compileNode(child);
            }
            return;
        }

        // Opening tag
        try self.output.appendSlice(self.allocator, "<");
        try self.output.appendSlice(self.allocator, tag.name);

        // Attributes
        if (tag.attributes.items.len > 0) {
            try self.compileAttributes(&tag.attributes);
        }

        // Self-closing tags
        const is_void_element = isVoidElement(tag.name);
        if (is_void_element or tag.is_self_closing) {
            try self.output.appendSlice(self.allocator, ">");
            return;
        }

        try self.output.appendSlice(self.allocator, ">");

        // Children
        for (tag.children.items) |child| {
            try self.compileNode(child);
        }

        // Closing tag
        try self.output.appendSlice(self.allocator, "</");
        try self.output.appendSlice(self.allocator, tag.name);
        try self.output.appendSlice(self.allocator, ">");
    }

    fn compileAttributes(self: *Self, attributes: *const std.ArrayListUnmanaged(ast.Attribute)) !void {
        for (attributes.items) |attr| {
            try self.output.appendSlice(self.allocator, " ");
            try self.output.appendSlice(self.allocator, attr.name);

            if (attr.value) |value| {
                try self.output.appendSlice(self.allocator, "=\"");

                // Evaluate expression if needed
                if (attr.is_expression) {
                    const result = self.runtime.eval(value) catch |err| {
                        self.has_errors = true;
                        std.debug.print("Error: Failed to evaluate attribute expression\n", .{});
                        std.debug.print("  Attribute: {s}={s}\n", .{ attr.name, value });
                        std.debug.print("  Error: {}\n", .{err});
                        std.debug.print("  Hint: Make sure the variable '{s}' is defined\n", .{value});
                        // Skip attribute on error (strict mode)
                        try self.output.appendSlice(self.allocator, "\"");
                        continue;
                    };
                    defer self.allocator.free(result);

                    // Escape the result if not unescaped
                    if (attr.is_unescaped) {
                        try self.output.appendSlice(self.allocator, result);
                    } else {
                        const escaped = try self.escapeHtml(result);
                        defer self.allocator.free(escaped);
                        try self.output.appendSlice(self.allocator, escaped);
                    }
                } else {
                    try self.output.appendSlice(self.allocator, value);
                }

                try self.output.appendSlice(self.allocator, "\"");
            }
        }
    }

    fn isVoidElement(tag_name: []const u8) bool {
        const void_elements = [_][]const u8{
            "area", "base", "br", "col", "embed", "hr", "img", "input",
            "link", "meta", "param", "source", "track", "wbr",
        };

        for (void_elements) |void_elem| {
            if (std.mem.eql(u8, tag_name, void_elem)) {
                return true;
            }
        }
        return false;
    }

    // ========================================================================
    // Text & Interpolation Compilation
    // ========================================================================

    /// Compile text node - outputs literal text content
    fn compileText(self: *Self, node: *ast.AstNode) !void {
        const text = &node.data.Text;
        try self.output.appendSlice(self.allocator, text.content);
    }

    /// Compile interpolation - evaluates JavaScript expression
    ///
    /// Handles #{expr} (escaped) and !{expr} (unescaped).
    /// Evaluates expression using JavaScript runtime.
    fn compileInterpolation(self: *Self, node: *ast.AstNode) !void {
        const interp = &node.data.Interpolation;

        // Evaluate the JavaScript expression using runtime
        const result = self.runtime.eval(interp.expression) catch |err| {
            self.has_errors = true;
            std.debug.print("Error: Failed to evaluate interpolation at line {d}\n", .{node.line});
            std.debug.print("  Expression: #{{{s}}}\n", .{interp.expression});
            std.debug.print("  Error: {}\n", .{err});
            std.debug.print("  Hint: Check that all variables used in the expression are defined\n", .{});
            // Don't generate output on error (strict mode)
            return;
        };
        defer self.allocator.free(result);

        // Apply HTML escaping unless explicitly unescaped
        if (interp.is_unescaped) {
            try self.output.appendSlice(self.allocator, result);
        } else {
            const escaped = try self.escapeHtml(result);
            defer self.allocator.free(escaped);
            try self.output.appendSlice(self.allocator, escaped);
        }
    }

    /// Compile code node (=, !=, -)
    ///
    /// Evaluates JavaScript code and optionally outputs result.
    /// - Buffered (=): Output escaped result
    /// - Unescaped (!=): Output raw result
    /// - Unbuffered (-): Execute only, no output
    fn compileCode(self: *Self, node: *ast.AstNode) !void {
        const code = &node.data.Code;

        // Evaluate the code
        const result = self.runtime.eval(code.code) catch |err| {
            self.has_errors = true;
            std.debug.print("Error: Failed to execute code at line {d}\n", .{node.line});
            std.debug.print("  Code: {s}\n", .{code.code});
            std.debug.print("  Error: {}\n", .{err});
            return;
        };
        defer self.allocator.free(result);

        // If buffered, output the result
        if (code.is_buffered) {
            // Apply HTML escaping unless explicitly unescaped
            if (code.is_unescaped) {
                try self.output.appendSlice(self.allocator, result);
            } else {
                const escaped = try self.escapeHtml(result);
                defer self.allocator.free(escaped);
                try self.output.appendSlice(self.allocator, escaped);
            }
        }
        // If unbuffered, we just executed it but don't output
    }

    /// Escape HTML special characters to prevent XSS attacks
    /// Optimized version that pre-calculates size to avoid reallocations
    fn escapeHtml(self: *Self, input: []const u8) ![]const u8 {
        // First pass: check if escaping is needed and calculate exact size
        var needs_escaping = false;
        var final_size: usize = 0;

        for (input) |c| {
            switch (c) {
                '&' => {
                    needs_escaping = true;
                    final_size += 5; // &amp;
                },
                '<', '>' => {
                    needs_escaping = true;
                    final_size += 4; // &lt; or &gt;
                },
                '"' => {
                    needs_escaping = true;
                    final_size += 6; // &quot;
                },
                '\'' => {
                    needs_escaping = true;
                    final_size += 5; // &#39;
                },
                else => {
                    final_size += 1;
                },
            }
        }

        // If no escaping needed, return a copy of the input
        if (!needs_escaping) {
            return try self.allocator.dupe(u8, input);
        }

        // Allocate exact size needed (no reallocations)
        var result = std.ArrayList(u8){};
        errdefer result.deinit(self.allocator);
        try result.ensureTotalCapacity(self.allocator, final_size);

        // Second pass: build escaped string
        for (input) |c| {
            switch (c) {
                '&' => result.appendSliceAssumeCapacity("&amp;"),
                '<' => result.appendSliceAssumeCapacity("&lt;"),
                '>' => result.appendSliceAssumeCapacity("&gt;"),
                '"' => result.appendSliceAssumeCapacity("&quot;"),
                '\'' => result.appendSliceAssumeCapacity("&#39;"),
                else => result.appendAssumeCapacity(c),
            }
        }

        return try result.toOwnedSlice(self.allocator);
    }

    // ========================================================================
    // Comment Compilation
    // ========================================================================

    fn compileComment(self: *Self, node: *ast.AstNode) !void {
        const comment = &node.data.Comment;

        // Only include buffered comments if include_comments is true
        // Unbuffered comments (//-) are never included
        if (comment.is_buffered and self.include_comments) {
            try self.output.appendSlice(self.allocator, "<!--");
            // Escape comment content to prevent injection attacks
            // Replace "--" with "- -" to prevent premature comment closing
            const escaped = try self.escapeComment(comment.content);
            defer self.allocator.free(escaped);
            try self.output.appendSlice(self.allocator, escaped);
            try self.output.appendSlice(self.allocator, "-->");
        }
        // Production mode (include_comments=false): comments are stripped
        // Development mode (include_comments=true): comments are included
    }

    /// Escape HTML comment content to prevent XSS/injection attacks
    /// Replaces "--" with "- -" to prevent premature comment closing
    fn escapeComment(self: *Self, input: []const u8) ![]const u8 {
        // Check if escaping is needed
        var needs_escaping = false;
        var i: usize = 0;
        while (i < input.len) : (i += 1) {
            if (i + 1 < input.len and input[i] == '-' and input[i + 1] == '-') {
                needs_escaping = true;
                break;
            }
        }

        if (!needs_escaping) {
            return try self.allocator.dupe(u8, input);
        }

        // Escape "--" sequences
        var result = std.ArrayList(u8){};
        errdefer result.deinit(self.allocator);

        i = 0;
        while (i < input.len) {
            if (i + 1 < input.len and input[i] == '-' and input[i + 1] == '-') {
                try result.appendSlice(self.allocator, "- -");
                i += 2;
            } else {
                try result.append(self.allocator, input[i]);
                i += 1;
            }
        }

        return try result.toOwnedSlice(self.allocator);
    }

    // ========================================================================
    // Conditional Compilation
    // ========================================================================

    fn compileConditional(self: *Self, node: *ast.AstNode) !void {
        const cond = &node.data.Conditional;

        // Evaluate condition using runtime
        const result = self.runtime.eval(cond.condition) catch |err| {
            self.has_errors = true;
            std.debug.print("Error: Failed to evaluate conditional at line {d}\n", .{node.line});
            std.debug.print("  Condition: {s}\n", .{cond.condition});
            std.debug.print("  Error: {}\n", .{err});
            return;
        };
        defer self.allocator.free(result);

        // Check if result is truthy
        const is_true = !std.mem.eql(u8, result, "false") and
            !std.mem.eql(u8, result, "null") and
            !std.mem.eql(u8, result, "undefined") and
            !std.mem.eql(u8, result, "0") and
            result.len > 0;

        const should_execute = if (cond.is_unless) !is_true else is_true;

        if (should_execute) {
            // Execute then branch
            for (cond.then_branch.items) |child| {
                try self.compileNode(child);
            }
        } else if (cond.else_branch) |*else_branch| {
            // Execute else branch
            for (else_branch.items) |child| {
                try self.compileNode(child);
            }
        }
    }

    // ========================================================================
    // Loop Compilation
    // ========================================================================

    fn compileLoop(self: *Self, node: *ast.AstNode) !void {
        const loop = &node.data.Loop;

        // Get the iterable value from runtime
        const iterable_result = self.runtime.eval(loop.iterable) catch |err| {
            self.has_errors = true;
            std.debug.print("Error: Failed to evaluate loop iterable at line {d}\n", .{node.line});
            std.debug.print("  Iterable: {s}\n", .{loop.iterable});
            std.debug.print("  Error: {}\n", .{err});
            std.debug.print("  Hint: Make sure the array variable is defined\n", .{});
            return;
        };
        defer self.allocator.free(iterable_result);

        // Check if it's an array by looking for array notation or getting length
        // We'll use JavaScript to iterate
        const length_expr = try std.fmt.allocPrint(self.allocator, "({s}).length", .{loop.iterable});
        defer self.allocator.free(length_expr);

        const length_str = self.runtime.eval(length_expr) catch {
            // Not an array or no length, try else branch
            if (loop.else_branch) |*else_branch| {
                for (else_branch.items) |child| {
                    try self.compileNode(child);
                }
            }
            return;
        };
        defer self.allocator.free(length_str);

        const length = std.fmt.parseInt(usize, length_str, 10) catch {
            // Invalid length, try else branch
            if (loop.else_branch) |*else_branch| {
                for (else_branch.items) |child| {
                    try self.compileNode(child);
                }
            }
            return;
        };

        // If empty array, execute else branch
        if (length == 0) {
            if (loop.else_branch) |*else_branch| {
                for (else_branch.items) |child| {
                    try self.compileNode(child);
                }
            }
            return;
        }

        // Iterate over array
        var i: usize = 0;
        while (i < length) : (i += 1) {
            // Set iterator variable: item = array[i]
            const set_item_expr = try std.fmt.allocPrint(
                self.allocator,
                "var {s} = ({s})[{d}]",
                .{ loop.iterator, loop.iterable, i },
            );
            defer self.allocator.free(set_item_expr);

            _ = self.runtime.eval(set_item_expr) catch |err| {
                std.debug.print("Error setting loop variable: {}\n", .{err});
                continue;
            };

            // Set index variable if specified
            if (loop.index) |index_name| {
                const set_index_expr = try std.fmt.allocPrint(
                    self.allocator,
                    "var {s} = {d}",
                    .{ index_name, i },
                );
                defer self.allocator.free(set_index_expr);

                _ = self.runtime.eval(set_index_expr) catch {};
            }

            // Compile loop body
            for (loop.body.items) |child| {
                try self.compileNode(child);
            }
        }
    }

    // ========================================================================
    // Include Compilation
    // ========================================================================

    fn compileInclude(self: *Self, node: *ast.AstNode) !void {
        const include = &node.data.Include;

        // Resolve path relative to base_path
        const full_path = if (self.base_path) |base| blk: {
            // Get directory from base path
            const dir = std.fs.path.dirname(base) orelse ".";
            break :blk try std.fs.path.join(self.allocator, &.{ dir, include.path });
        } else blk: {
            break :blk try self.allocator.dupe(u8, include.path);
        };
        defer self.allocator.free(full_path);

        // Read file content
        const file_content = std.fs.cwd().readFileAlloc(
            self.allocator,
            full_path,
            1024 * 1024, // 1MB max
        ) catch |err| {
            std.debug.print("Error reading include file '{s}': {}\n", .{ full_path, err });
            return error.IncludeFileNotFound;
        };
        defer self.allocator.free(file_content);

        // Check cache if available
        if (self.template_cache) |tmpl_cache| {
            const source_hash = cache.hashSource(file_content);
            if (tmpl_cache.getIfValid(full_path, source_hash)) |cached_html| {
                try self.output.appendSlice(self.allocator, cached_html);
                return;
            }
        }

        // Parse the included file
        var parser = Parser.init(self.allocator, file_content) catch |err| {
            std.debug.print("Error parsing include file '{s}': {}\n", .{ full_path, err });
            return error.IncludeParseError;
        };
        defer parser.deinit();

        const included_ast = parser.parse() catch |err| {
            std.debug.print("Error parsing include file '{s}': {}\n", .{ full_path, err });
            return error.IncludeParseError;
        };

        // Compile the included AST
        // Save current output position to extract just the include
        const start_pos = self.output.items.len;

        // Compile
        try self.compileNode(included_ast);

        // Cache the result if cache is available
        if (self.template_cache) |tmpl_cache| {
            const included_html = self.output.items[start_pos..];
            const source_hash = cache.hashSource(file_content);
            tmpl_cache.put(full_path, included_html, source_hash) catch {};
        }
    }

    // ========================================================================
    // Case Compilation
    // ========================================================================

    fn compileCase(self: *Self, node: *ast.AstNode) !void {
        const case_node = &node.data.Case;

        // Evaluate the case expression
        const case_value = self.runtime.eval(case_node.expression) catch |err| {
            self.has_errors = true;
            std.debug.print("Runtime error evaluating case '{s}': {}\n", .{ case_node.expression, err });
            return;
        };
        defer self.allocator.free(case_value);

        // Check each when clause
        for (case_node.cases.items) |when_node| {
            const when = &when_node.data.When;

            var matched = false;
            for (when.values.items) |value| {
                if (std.mem.eql(u8, case_value, value)) {
                    matched = true;
                    break;
                }
            }

            if (matched) {
                for (when.body.items) |child| {
                    try self.compileNode(child);
                }
                return; // Exit after first match
            }
        }

        // No match found, execute default if exists
        if (case_node.default) |*default_body| {
            for (default_body.items) |child| {
                try self.compileNode(child);
            }
        }
    }

    // ========================================================================
    // Mixin Compilation
    // ========================================================================

    fn registerMixin(self: *Self, node: *ast.AstNode) !void {
        const mixin = &node.data.MixinDef;
        try self.mixins.put(mixin.name, node);
    }

    fn compileMixinCall(self: *Self, node: *ast.AstNode) !void {
        const call = &node.data.MixinCall;

        // Find mixin definition
        const mixin_node = self.mixins.get(call.name) orelse {
            std.debug.print("Mixin '{s}' not found\n", .{call.name});
            return error.MixinNotFound;
        };

        const mixin_def = &mixin_node.data.MixinDef;

        // Bind parameters to arguments in runtime context
        for (mixin_def.params.items, 0..) |param, i| {
            if (i < call.args.items.len) {
                // Evaluate the argument and set as variable
                const arg_value = call.args.items[i];
                const set_var_expr = try std.fmt.allocPrint(
                    self.allocator,
                    "var {s} = {s}",
                    .{ param, arg_value },
                );
                defer self.allocator.free(set_var_expr);

                _ = self.runtime.eval(set_var_expr) catch |err| {
                    std.debug.print("Error setting mixin parameter '{s}': {}\n", .{ param, err });
                };
            } else {
                // Set undefined for missing arguments
                const set_undefined_expr = try std.fmt.allocPrint(
                    self.allocator,
                    "var {s} = undefined",
                    .{param},
                );
                defer self.allocator.free(set_undefined_expr);

                _ = self.runtime.eval(set_undefined_expr) catch {};
            }
        }

        // Handle rest parameter if present
        if (mixin_def.rest_param) |rest_param| {
            // Create array from remaining arguments
            var rest_args = std.ArrayList(u8){};
            defer rest_args.deinit(self.allocator);

            try rest_args.appendSlice(self.allocator, "var ");
            try rest_args.appendSlice(self.allocator, rest_param);
            try rest_args.appendSlice(self.allocator, " = [");

            const start_idx = mixin_def.params.items.len;
            for (call.args.items[start_idx..], 0..) |arg, j| {
                if (j > 0) {
                    try rest_args.appendSlice(self.allocator, ", ");
                }
                try rest_args.appendSlice(self.allocator, arg);
            }

            try rest_args.appendSlice(self.allocator, "]");

            const rest_expr = try rest_args.toOwnedSlice(self.allocator);
            defer self.allocator.free(rest_expr);

            _ = self.runtime.eval(rest_expr) catch |err| {
                std.debug.print("Error setting rest parameter '{s}': {}\n", .{ rest_param, err });
            };
        }

        // Compile the mixin body
        for (mixin_def.body.items) |child| {
            try self.compileNode(child);
        }
    }
};

// Helper function to compile a complete template
pub fn compileTemplate(
    allocator: std.mem.Allocator,
    node: *ast.AstNode,
    context: anytype,
) ![]const u8 {
    // Create runtime
    var js_runtime = try runtime.JsRuntime.init(allocator);
    defer js_runtime.deinit();

    // Set context variables
    // TODO: Convert context to JsValues and set in runtime
    _ = context;

    // Create compiler
    var compiler = try Compiler.init(allocator, js_runtime);
    defer compiler.deinit();

    // Compile
    return try compiler.compile(node);
}

// ============================================================================
// Tests
// ============================================================================

test "compiler - simple tag" {
    const source = "div Hello World";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<div>Hello World</div>", html);
}

test "compiler - tag with attributes" {
    const source = "a(href=\"/home\" title=\"Home\") Link";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<a href=\"/home\" title=\"Home\">Link</a>", html);
}

test "compiler - interpolation" {
    const source = "p Hello #{name}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    // Set context
    const name_val = try runtime.jsValueFromString(std.testing.allocator, "John");
    try js_runtime.setContext("name", name_val);
    // Free the original value after it's been cloned by setContext
    var name_copy = name_val;
    name_copy.deinit(std.testing.allocator);

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>HelloJohn</p>", html);
}

test "compiler - conditional true" {
    const source =
        \\if loggedIn
        \\  p Welcome back!
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    try js_runtime.setContext("loggedIn", runtime.jsValueFromBool(true));

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>Welcome back ! </p>", html);
}

test "compiler - conditional false" {
    const source =
        \\if loggedIn
        \\  p Welcome back!
        \\else
        \\  p Please log in
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    try js_runtime.setContext("loggedIn", runtime.jsValueFromBool(false));

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>Please log in </p>", html);
}

test "compiler - mixin call" {
    const source =
        \\mixin greeting
        \\  p Hello!
        \\+greeting
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>Hello !</p>", html);
}

test "compiler - html escaping" {
    const source = "p #{content}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    // Set XSS-like content
    const content_val = try runtime.jsValueFromString(std.testing.allocator, "<script>alert('xss')</script>");
    try js_runtime.setContext("content", content_val);
    var content_copy = content_val;
    content_copy.deinit(std.testing.allocator);

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    // Should escape HTML characters
    try std.testing.expectEqualStrings("<p>&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;</p>", html);
}

test "compiler - html escaping special chars" {
    const source = "p #{text}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    // Set content with all special chars
    const text_val = try runtime.jsValueFromString(std.testing.allocator, "A & B < C > D \"E\" 'F'");
    try js_runtime.setContext("text", text_val);
    var text_copy = text_val;
    text_copy.deinit(std.testing.allocator);

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>A &amp; B &lt; C &gt; D &quot;E&quot; &#39;F&#39;</p>", html);
}

test "compiler - unescaped interpolation" {
    const source = "p !{html}";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    // Set trusted HTML content
    const html_val = try runtime.jsValueFromString(std.testing.allocator, "<strong>Bold</strong>");
    try js_runtime.setContext("html", html_val);
    var html_copy = html_val;
    html_copy.deinit(std.testing.allocator);

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const result = try compiler.compile(tree);
    defer std.testing.allocator.free(result);

    // Should NOT escape - unescaped interpolation
    try std.testing.expectEqualStrings("<p><strong>Bold</strong></p>", result);
}

test "compiler - tag= buffered code" {
    const source =
        \\- var greeting = "Hello"
        \\p= greeting
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>Hello</p>", html);
}

test "compiler - tag!= unescaped code" {
    const source =
        \\- var html = "<em>italic</em>"
        \\div!= html
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<div><em>italic</em></div>", html);
}

test "compiler - attribute expressions" {
    const source =
        \\- var myClass = "primary"
        \\button(class=myClass) Click
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<button class=\"primary\">Click</button>", html);
}

test "compiler - unbuffered code" {
    const source =
        \\- var x = 10
        \\- var y = 20
        \\p Sum: #{x + y}
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>Sum :30</p>", html);
}

test "compiler - multiple classes" {
    const source = "div.box.highlight Content";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<div class=\"box highlight\">Content</div>", html);
}

test "compiler - mixin with arguments" {
    const source =
        \\mixin greet(name)
        \\  p Hello, #{name}
        \\+greet("World")
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expectEqualStrings("<p>Hello ,World</p>", html);
}

test "compiler - comment escaping" {
    const source = "// Comment with --> dangerous";
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    // Should escape "-->" to prevent injection
    try std.testing.expect(std.mem.indexOf(u8, html, "- ->") != null);
}

test "compiler - doctype html" {
    const source =
        \\doctype html
        \\html
        \\  head
        \\    title Test
        \\  body
        \\    p Hello
    ;
    var parser = try Parser.init(std.testing.allocator, source);
    defer parser.deinit();

    const tree = try parser.parse();

    var js_runtime = try runtime.JsRuntime.init(std.testing.allocator);
    defer js_runtime.deinit();

    var compiler = try Compiler.init(std.testing.allocator, js_runtime);
    defer compiler.deinit();

    const html = try compiler.compile(tree);
    defer std.testing.allocator.free(html);

    try std.testing.expect(std.mem.startsWith(u8, html, "<!DOCTYPE html>"));
    try std.testing.expect(std.mem.indexOf(u8, html, "<html>") != null);
}
