const std = @import("std");
const ast = @import("ast.zig");
const runtime = @import("runtime.zig");

// Compiler module - Converts AST to HTML
// Takes the parsed AST and generates HTML output

pub const CompilerError = error{
    OutOfMemory,
    RuntimeError,
    InvalidNode,
    MixinNotFound,
};

pub const Compiler = struct {
    allocator: std.mem.Allocator,
    runtime: *runtime.JsRuntime,
    output: std.ArrayList(u8),
    indent_level: usize,
    pretty: bool, // Enable pretty printing with indentation
    mixins: std.StringHashMap(*ast.AstNode), // Store mixin definitions

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator, js_runtime: *runtime.JsRuntime) !*Self {
        const compiler = try allocator.create(Self);
        compiler.* = .{
            .allocator = allocator,
            .runtime = js_runtime,
            .output = .{},
            .indent_level = 0,
            .pretty = false,
            .mixins = std.StringHashMap(*ast.AstNode).init(allocator),
        };
        return compiler;
    }

    pub fn deinit(self: *Self) void {
        self.output.deinit(self.allocator);
        self.mixins.deinit();
        self.allocator.destroy(self);
    }

    /// Compile an AST to HTML
    pub fn compile(self: *Self, node: *ast.AstNode) ![]const u8 {
        try self.compileNode(node);
        return try self.output.toOwnedSlice(self.allocator);
    }

    fn compileNode(self: *Self, node: *ast.AstNode) anyerror!void {
        switch (node.data) {
            .Document => try self.compileDocument(node),
            .Tag => try self.compileTag(node),
            .Text => try self.compileText(node),
            .Interpolation => try self.compileInterpolation(node),
            .Code => {}, // TODO: Implement in future
            .Comment => try self.compileComment(node),
            .Conditional => try self.compileConditional(node),
            .Loop => try self.compileLoop(node),
            .MixinDef => try self.registerMixin(node),
            .MixinCall => try self.compileMixinCall(node),
            .Include => {}, // TODO: Implement includes
            .Block => {}, // TODO: Implement blocks
            .Extends => {}, // TODO: Implement extends
            .Case => try self.compileCase(node),
            .When => {}, // Handled by Case
        }
    }

    // ========================================================================
    // Document Compilation
    // ========================================================================

    fn compileDocument(self: *Self, node: *ast.AstNode) !void {
        const doc = &node.data.Document;

        // First pass: register all mixins
        for (doc.children.items) |child| {
            if (child.type == .MixinDef) {
                try self.registerMixin(child);
            }
        }

        // Second pass: compile everything else
        for (doc.children.items) |child| {
            if (child.type != .MixinDef) {
                try self.compileNode(child);
            }
        }
    }

    // ========================================================================
    // Tag Compilation
    // ========================================================================

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
                try self.output.appendSlice(self.allocator, value);
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

    fn compileText(self: *Self, node: *ast.AstNode) !void {
        const text = &node.data.Text;
        try self.output.appendSlice(self.allocator, text.content);
    }

    fn compileInterpolation(self: *Self, node: *ast.AstNode) !void {
        const interp = &node.data.Interpolation;

        // Evaluate the JavaScript expression using runtime
        const result = self.runtime.eval(interp.expression) catch |err| {
            std.debug.print("Runtime error evaluating '{s}': {}\n", .{ interp.expression, err });
            // On error, output the expression as-is for debugging
            try self.output.appendSlice(self.allocator, "#{");
            try self.output.appendSlice(self.allocator, interp.expression);
            try self.output.appendSlice(self.allocator, "}");
            return;
        };
        defer self.allocator.free(result);

        // TODO: Implement HTML escaping if not is_unescaped
        try self.output.appendSlice(self.allocator, result);
    }

    // ========================================================================
    // Comment Compilation
    // ========================================================================

    fn compileComment(self: *Self, node: *ast.AstNode) !void {
        const comment = &node.data.Comment;
        if (comment.is_buffered) {
            try self.output.appendSlice(self.allocator, "<!--");
            try self.output.appendSlice(self.allocator, comment.content);
            try self.output.appendSlice(self.allocator, "-->");
        }
        // Unbuffered comments are not rendered
    }

    // ========================================================================
    // Conditional Compilation
    // ========================================================================

    fn compileConditional(self: *Self, node: *ast.AstNode) !void {
        const cond = &node.data.Conditional;

        // Evaluate condition using runtime
        const result = self.runtime.eval(cond.condition) catch |err| {
            std.debug.print("Runtime error evaluating condition '{s}': {}\n", .{ cond.condition, err });
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
        _ = self;
        _ = node;
        // TODO: Implement loop compilation with runtime.eval() for iterable
        // For now, skip loops (will implement with JavaScript expressions support)
    }

    // ========================================================================
    // Case Compilation
    // ========================================================================

    fn compileCase(self: *Self, node: *ast.AstNode) !void {
        const case_node = &node.data.Case;

        // Evaluate the case expression
        const case_value = self.runtime.eval(case_node.expression) catch |err| {
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

        // TODO: Set mixin parameters in runtime context
        // For now, just compile the body
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

const Parser = @import("parser.zig").Parser;

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
