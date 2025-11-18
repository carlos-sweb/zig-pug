// zig-pug library API
// C-compatible interface for using zig-pug from other languages

const std = @import("std");
const tokenizer = @import("tokenizer.zig");
const parser = @import("parser.zig");
const compiler = @import("compiler.zig");
const runtime = @import("runtime.zig");
const ast = @import("ast.zig");
const cache_mod = @import("cache.zig");

// Export all modules for Zig users
pub const Tokenizer = tokenizer.Tokenizer;
pub const Parser = parser.Parser;
pub const Compiler = compiler.Compiler;
pub const JsRuntime = runtime.JsRuntime;
pub const JsValue = runtime.JsValue;
pub const AstNode = ast.AstNode;
pub const TemplateCache = cache_mod.TemplateCache;
pub const hashSource = cache_mod.hashSource;

// Helper functions
pub const jsValueFromString = runtime.jsValueFromString;
pub const jsValueFromInt = runtime.jsValueFromInt;
pub const jsValueFromFloat = runtime.jsValueFromFloat;
pub const jsValueFromBool = runtime.jsValueFromBool;

// ============================================================================
// C API - For FFI from other languages
// ============================================================================

// Opaque context handles for C API
pub const ZigPugContext = opaque {};
pub const ZigPugRuntime = opaque {};

/// Initialize a new zig-pug context
/// Returns: Context handle or null on error
export fn zigpug_init() ?*ZigPugContext {
    const allocator = std.heap.c_allocator;
    const ctx = allocator.create(Context) catch return null;
    ctx.* = Context.init(allocator) catch {
        allocator.destroy(ctx);
        return null;
    };
    return @ptrCast(ctx);
}

/// Free a zig-pug context
export fn zigpug_free(ctx: ?*ZigPugContext) void {
    if (ctx) |c| {
        const context: *Context = @ptrCast(@alignCast(c));
        context.deinit();
        context.allocator.destroy(context);
    }
}

/// Compile a Pug template string to HTML
/// Returns: Allocated HTML string (must be freed with zigpug_free_string)
export fn zigpug_compile(ctx: ?*ZigPugContext, pug_source: [*:0]const u8) ?[*:0]u8 {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return null));
    const source = std.mem.span(pug_source);

    const html = context.compile(source) catch return null;

    // Allocate null-terminated string for C
    const result = context.allocator.dupeZ(u8, html) catch {
        context.allocator.free(html);
        return null;
    };
    context.allocator.free(html);

    return result.ptr;
}

/// Set a string variable in the context
export fn zigpug_set_string(ctx: ?*ZigPugContext, key: [*:0]const u8, value: [*:0]const u8) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    const key_str = std.mem.span(key);
    const value_str = std.mem.span(value);

    const js_value = runtime.jsValueFromString(context.allocator, value_str) catch return false;
    context.runtime.setContext(key_str, js_value) catch {
        var val_copy = js_value;
        val_copy.deinit(context.allocator);
        return false;
    };

    var val_copy = js_value;
    val_copy.deinit(context.allocator);
    return true;
}

/// Set an integer variable in the context
export fn zigpug_set_int(ctx: ?*ZigPugContext, key: [*:0]const u8, value: i64) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    const key_str = std.mem.span(key);

    const js_value = runtime.jsValueFromInt(value);
    context.runtime.setContext(key_str, js_value) catch return false;
    return true;
}

/// Set a boolean variable in the context
export fn zigpug_set_bool(ctx: ?*ZigPugContext, key: [*:0]const u8, value: bool) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    const key_str = std.mem.span(key);

    const js_value = runtime.jsValueFromBool(value);
    context.runtime.setContext(key_str, js_value) catch return false;
    return true;
}

/// Free a string returned by zig-pug
export fn zigpug_free_string(str: ?[*:0]u8) void {
    if (str) |s| {
        const slice = std.mem.span(s);
        std.heap.c_allocator.free(slice);
    }
}

/// Get version string
export fn zigpug_version() [*:0]const u8 {
    return "0.1.0";
}

// ============================================================================
// Internal Context (not exported to C)
// ============================================================================

const Context = struct {
    allocator: std.mem.Allocator,
    runtime: *runtime.JsRuntime,

    fn init(allocator: std.mem.Allocator) !Context {
        const rt = try runtime.JsRuntime.init(allocator);
        return Context{
            .allocator = allocator,
            .runtime = rt,
        };
    }

    fn deinit(self: *Context) void {
        self.runtime.deinit();
    }

    fn compile(self: *Context, source: []const u8) ![]const u8 {
        // Parse
        var pars = try parser.Parser.init(self.allocator, source);
        defer pars.deinit();

        const tree = try pars.parse();

        // Compile
        var comp = try compiler.Compiler.init(self.allocator, self.runtime);
        defer comp.deinit();

        return try comp.compile(tree);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "lib - C API basic usage" {
    const ctx = zigpug_init();
    defer zigpug_free(ctx);

    try std.testing.expect(ctx != null);

    const success = zigpug_set_string(ctx, "name", "World");
    try std.testing.expect(success);

    const html = zigpug_compile(ctx, "p Hello #{name}");
    defer zigpug_free_string(html);

    try std.testing.expect(html != null);

    if (html) |h| {
        const result = std.mem.span(h);
        try std.testing.expectEqualStrings("<p>HelloWorld</p>", result);
    }
}

test "lib - version" {
    const version = zigpug_version();
    const ver_str = std.mem.span(version);
    try std.testing.expectEqualStrings("0.1.0", ver_str);
}
