// zig-pug library API
// C-compatible interface for using zig-pug from other languages

const std = @import("std");
const tokenizer = @import("tokenizer/mod.zig");
const parser = @import("parser/mod.zig");
const compiler = @import("compiler/mod.zig");
const runtime = @import("runtime.zig");
const ast = @import("ast/mod.zig");
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
// HTML Formatting Utilities
// ============================================================================

/// Check if a tag name is a void element (self-closing HTML element)
fn isVoidElement(tag_name: []const u8) bool {
    const void_elements = [_][]const u8{
        "area",  "base", "br",   "col",   "embed",  "hr",    "img",
        "input", "link", "meta", "param", "source", "track", "wbr",
    };
    for (void_elements) |void_elem| {
        if (std.mem.eql(u8, tag_name, void_elem)) {
            return true;
        }
    }
    return false;
}

/// Minify HTML by removing unnecessary whitespace
fn minifyHtml(allocator: std.mem.Allocator, html: []const u8) ![]const u8 {
    var result = std.ArrayList(u8){};
    var in_tag = false;
    var last_was_space = false;

    for (html) |c| {
        if (c == '<') {
            in_tag = true;
            try result.append(allocator, c);
            last_was_space = false;
        } else if (c == '>') {
            in_tag = false;
            try result.append(allocator, c);
            last_was_space = false;
        } else if (c == ' ' or c == '\n' or c == '\r' or c == '\t') {
            if (!in_tag and !last_was_space) {
                try result.append(allocator, ' ');
                last_was_space = true;
            } else if (in_tag and c == ' ') {
                try result.append(allocator, ' ');
            }
        } else {
            try result.append(allocator, c);
            last_was_space = false;
        }
    }

    return result.toOwnedSlice(allocator);
}

/// Pretty-print HTML with indentation (simplified version for lib)
fn prettyPrintHtml(allocator: std.mem.Allocator, html: []const u8, include_comments: bool) ![]const u8 {
    var result = std.ArrayList(u8){};
    var indent: usize = 0;
    var i: usize = 0;
    var last_was_text = false;

    while (i < html.len) {
        if (html[i] == '<') {
            // Check if it's a comment
            const is_comment = i + 3 < html.len and
                html[i + 1] == '!' and
                html[i + 2] == '-' and
                html[i + 3] == '-';

            // Skip comments if not including them
            if (is_comment and !include_comments) {
                while (i < html.len) : (i += 1) {
                    if (i + 2 < html.len and html[i] == '-' and html[i + 1] == '-' and html[i + 2] == '>') {
                        i += 3;
                        break;
                    }
                }
                continue;
            }

            // Check if it's DOCTYPE
            const is_doctype = i + 8 < html.len and
                html[i + 1] == '!' and
                std.ascii.toUpper(html[i + 2]) == 'D' and
                std.ascii.toUpper(html[i + 3]) == 'O' and
                std.ascii.toUpper(html[i + 4]) == 'C' and
                std.ascii.toUpper(html[i + 5]) == 'T' and
                std.ascii.toUpper(html[i + 6]) == 'Y' and
                std.ascii.toUpper(html[i + 7]) == 'P' and
                std.ascii.toUpper(html[i + 8]) == 'E';

            // Check if closing tag
            const is_closing = i + 1 < html.len and html[i + 1] == '/';

            // Extract tag name to check if it's void/self-closing
            var tag_name_start: usize = i + 1;
            if (is_closing) tag_name_start += 1;
            var tag_name_end = tag_name_start;
            while (tag_name_end < html.len and
                   html[tag_name_end] != '>' and
                   html[tag_name_end] != ' ' and
                   html[tag_name_end] != '/') : (tag_name_end += 1) {}
            const tag_name = html[tag_name_start..tag_name_end];

            // Check if it's a void element
            const is_void = isVoidElement(tag_name);

            // Peek ahead to see if next content is text (for inline elements)
            var peek_i = i;
            while (peek_i < html.len and html[peek_i] != '>') : (peek_i += 1) {}
            if (peek_i < html.len) peek_i += 1; // skip '>'

            // Skip whitespace
            while (peek_i < html.len and std.ascii.isWhitespace(html[peek_i])) : (peek_i += 1) {}

            const next_is_text = peek_i < html.len and html[peek_i] != '<';
            const is_inline = next_is_text and !is_closing;

            // Decrease indent for closing tags (before printing)
            if (is_closing and indent > 0) {
                indent -= 1;
            }

            // Add newline and indentation (except for inline elements or text content)
            if (result.items.len > 0 and !last_was_text and !is_inline) {
                try result.append(allocator, '\n');
                var ind: usize = 0;
                while (ind < indent) : (ind += 1) {
                    try result.appendSlice(allocator, "  ");
                }
            }

            // Copy tag
            const tag_start = i;
            while (i < html.len and html[i] != '>') : (i += 1) {}
            if (i < html.len) i += 1;
            try result.appendSlice(allocator, html[tag_start..i]);

            // Increase indent for opening tags (after printing)
            if (!is_closing and !is_doctype and !is_comment and !is_void) {
                indent += 1;
            }

            last_was_text = false;
        } else {
            // Copy content between tags
            const content_start = i;
            while (i < html.len and html[i] != '<') : (i += 1) {}
            const content = html[content_start..i];

            // Only add non-whitespace content
            const trimmed = std.mem.trim(u8, content, &std.ascii.whitespace);
            if (trimmed.len > 0) {
                try result.appendSlice(allocator, trimmed);
                last_was_text = true;
            }
        }
    }

    return result.toOwnedSlice(allocator);
}

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

/// Get the number of compilation errors from the last compile call
/// Returns: Number of errors, or 0 if no errors or no compilation has been done
export fn zigpug_get_error_count(ctx: ?*ZigPugContext) usize {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return 0));
    if (context.last_compiler) |comp| {
        return comp.errors.items.len;
    }
    return 0;
}

/// Get a specific compilation error by index
/// Parameters:
///   - ctx: Context handle
///   - index: Error index (0 to error_count-1)
///   - line_out: Output parameter for line number
///   - message_out: Output parameter for error message (do not free)
///   - detail_out: Output parameter for detail (do not free, may be null)
///   - hint_out: Output parameter for hint (do not free, may be null)
/// Returns: true if error exists at index, false otherwise
export fn zigpug_get_error(
    ctx: ?*ZigPugContext,
    index: usize,
    line_out: ?*usize,
    message_out: ?*[*:0]const u8,
    detail_out: ?*?[*:0]const u8,
    hint_out: ?*?[*:0]const u8,
) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    if (context.last_compiler) |comp| {
        if (index >= comp.errors.items.len) return false;

        const err = &comp.errors.items[index];
        if (line_out) |l| l.* = err.line;
        if (message_out) |m| m.* = err.message.ptr;
        if (detail_out) |d| d.* = if (err.detail) |detail| detail.ptr else null;
        if (hint_out) |h| h.* = if (err.hint) |hint| hint.ptr else null;
        return true;
    }
    return false;
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

    const js_value = runtime.jsValueFromNumber(context.allocator, @floatFromInt(value)) catch return false;
    context.runtime.setContext(key_str, js_value) catch {
        var val_copy = js_value;
        val_copy.deinit(context.allocator);
        return false;
    };

    var val_copy = js_value;
    val_copy.deinit(context.allocator);
    return true;
}

/// Set a boolean variable in the context
export fn zigpug_set_bool(ctx: ?*ZigPugContext, key: [*:0]const u8, value: bool) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    const key_str = std.mem.span(key);

    const js_value = runtime.jsValueFromBool(context.allocator, value) catch return false;
    context.runtime.setContext(key_str, js_value) catch {
        var val_copy = js_value;
        val_copy.deinit(context.allocator);
        return false;
    };

    var val_copy = js_value;
    val_copy.deinit(context.allocator);
    return true;
}

/// Set an array variable from JSON string
/// Parameters:
///   - ctx: Context handle
///   - key: Variable name (null-terminated C string)
///   - json_str: JSON array string (e.g., '["a","b","c"]')
/// Returns: true on success, false on error
export fn zigpug_set_array_json(ctx: ?*ZigPugContext, key: [*:0]const u8, json_str: [*:0]const u8) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    const key_string = std.mem.span(key);
    const json_string = std.mem.span(json_str);

    // Parse JSON array
    const parsed = std.json.parseFromSlice(std.json.Value, context.allocator, json_string, .{}) catch return false;
    defer parsed.deinit();

    // Verify it's an array
    if (parsed.value != .array) {
        return false;
    }

    // Set array in runtime
    context.runtime.setArrayFromJson(key_string, parsed.value.array.items) catch return false;

    return true;
}

/// Set an object variable from JSON string
/// Parameters:
///   - ctx: Context handle
///   - key: Variable name (null-terminated C string)
///   - json_str: JSON object string (e.g., '{"name":"Alice","age":30}')
/// Returns: true on success, false on error
export fn zigpug_set_object_json(ctx: ?*ZigPugContext, key: [*:0]const u8, json_str: [*:0]const u8) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    const key_string = std.mem.span(key);
    const json_string = std.mem.span(json_str);

    // Parse JSON object
    const parsed = std.json.parseFromSlice(std.json.Value, context.allocator, json_string, .{}) catch return false;
    defer parsed.deinit();

    // Verify it's an object
    if (parsed.value != .object) {
        return false;
    }

    // Set object in runtime
    context.runtime.setObjectFromJson(key_string, parsed.value.object) catch return false;

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
    return "4.0.0";
}

/// Pretty-print HTML with indentation
/// Parameters:
///   - html: HTML string to format
///   - include_comments: Whether to preserve HTML comments (0 = false, non-zero = true)
/// Returns: Formatted HTML string (must be freed with zigpug_free_string)
export fn zigpug_pretty_print(html: [*:0]const u8, include_comments: c_int) ?[*:0]u8 {
    const allocator = std.heap.c_allocator;
    const html_str = std.mem.span(html);

    const formatted = prettyPrintHtml(allocator, html_str, include_comments != 0) catch return null;

    const result = allocator.dupeZ(u8, formatted) catch {
        allocator.free(formatted);
        return null;
    };
    allocator.free(formatted);

    return result.ptr;
}

/// Minify HTML by removing unnecessary whitespace
/// Parameters:
///   - html: HTML string to minify
/// Returns: Minified HTML string (must be freed with zigpug_free_string)
export fn zigpug_minify(html: [*:0]const u8) ?[*:0]u8 {
    const allocator = std.heap.c_allocator;
    const html_str = std.mem.span(html);

    const minified = minifyHtml(allocator, html_str) catch return null;

    const result = allocator.dupeZ(u8, minified) catch {
        allocator.free(minified);
        return null;
    };
    allocator.free(minified);

    return result.ptr;
}

// ============================================================================
// Builder API - Arrays and Objects (Advanced)
// ============================================================================

/// Array builder for dynamic array construction
pub const ArrayBuilder = opaque {};

/// Object builder for dynamic object construction
pub const ObjectBuilder = opaque {};

/// Internal array builder implementation
const ArrayBuilderImpl = struct {
    allocator: std.mem.Allocator,
    items: std.ArrayList(std.json.Value),

    fn init(allocator: std.mem.Allocator) !*ArrayBuilderImpl {
        const builder = try allocator.create(ArrayBuilderImpl);
        builder.* = .{
            .allocator = allocator,
            .items = std.ArrayList(std.json.Value){},
        };
        return builder;
    }

    fn deinit(self: *ArrayBuilderImpl) void {
        // Free string values
        for (self.items.items) |item| {
            switch (item) {
                .string => |s| self.allocator.free(s),
                else => {},
            }
        }
        self.items.deinit(self.allocator);
        self.allocator.destroy(self);
    }

    fn addString(self: *ArrayBuilderImpl, value: []const u8) !void {
        const owned = try self.allocator.dupe(u8, value);
        try self.items.append(self.allocator, std.json.Value{ .string = owned });
    }

    fn addInt(self: *ArrayBuilderImpl, value: i64) !void {
        try self.items.append(self.allocator, std.json.Value{ .integer = value });
    }

    fn addFloat(self: *ArrayBuilderImpl, value: f64) !void {
        try self.items.append(self.allocator, std.json.Value{ .float = value });
    }

    fn addBool(self: *ArrayBuilderImpl, value: bool) !void {
        try self.items.append(self.allocator, std.json.Value{ .bool = value });
    }

    fn addNull(self: *ArrayBuilderImpl) !void {
        try self.items.append(self.allocator, std.json.Value.null);
    }

    fn toJsonValue(self: *ArrayBuilderImpl) !std.json.Value {
        const array = try std.json.Array.initCapacity(self.allocator, self.items.items.len);
        return std.json.Value{ .array = array };
    }
};

/// Internal object builder implementation
const ObjectBuilderImpl = struct {
    allocator: std.mem.Allocator,
    map: std.json.ObjectMap,

    fn init(allocator: std.mem.Allocator) !*ObjectBuilderImpl {
        const builder = try allocator.create(ObjectBuilderImpl);
        builder.* = .{
            .allocator = allocator,
            .map = std.json.ObjectMap.init(allocator),
        };
        return builder;
    }

    fn deinit(self: *ObjectBuilderImpl) void {
        var it = self.map.iterator();
        while (it.next()) |entry| {
            self.allocator.free(entry.key_ptr.*);
            // Free string values
            switch (entry.value_ptr.*) {
                .string => |s| self.allocator.free(s),
                else => {},
            }
        }
        self.map.deinit();
        self.allocator.destroy(self);
    }

    fn setString(self: *ObjectBuilderImpl, key: []const u8, value: []const u8) !void {
        const owned_key = try self.allocator.dupe(u8, key);
        const owned_value = try self.allocator.dupe(u8, value);
        try self.map.put(owned_key, std.json.Value{ .string = owned_value });
    }

    fn setInt(self: *ObjectBuilderImpl, key: []const u8, value: i64) !void {
        const owned_key = try self.allocator.dupe(u8, key);
        try self.map.put(owned_key, std.json.Value{ .integer = value });
    }

    fn setFloat(self: *ObjectBuilderImpl, key: []const u8, value: f64) !void {
        const owned_key = try self.allocator.dupe(u8, key);
        try self.map.put(owned_key, std.json.Value{ .float = value });
    }

    fn setBool(self: *ObjectBuilderImpl, key: []const u8, value: bool) !void {
        const owned_key = try self.allocator.dupe(u8, key);
        try self.map.put(owned_key, std.json.Value{ .bool = value });
    }

    fn setNull(self: *ObjectBuilderImpl, key: []const u8) !void {
        const owned_key = try self.allocator.dupe(u8, key);
        try self.map.put(owned_key, std.json.Value.null);
    }
};

// ========== Array Builder Functions ==========

/// Create a new array builder
export fn zigpug_array_create(ctx: ?*ZigPugContext) ?*ArrayBuilder {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return null));
    const builder = ArrayBuilderImpl.init(context.allocator) catch return null;
    return @ptrCast(builder);
}

/// Free an array builder
export fn zigpug_array_free(arr: ?*ArrayBuilder) void {
    if (arr) |a| {
        const builder: *ArrayBuilderImpl = @ptrCast(@alignCast(a));
        builder.deinit();
    }
}

/// Add a string to the array
export fn zigpug_array_add_string(arr: ?*ArrayBuilder, value: [*:0]const u8) bool {
    const builder: *ArrayBuilderImpl = @ptrCast(@alignCast(arr orelse return false));
    const value_str = std.mem.span(value);
    builder.addString(value_str) catch return false;
    return true;
}

/// Add an integer to the array
export fn zigpug_array_add_int(arr: ?*ArrayBuilder, value: i64) bool {
    const builder: *ArrayBuilderImpl = @ptrCast(@alignCast(arr orelse return false));
    builder.addInt(value) catch return false;
    return true;
}

/// Add a float/double to the array
export fn zigpug_array_add_double(arr: ?*ArrayBuilder, value: f64) bool {
    const builder: *ArrayBuilderImpl = @ptrCast(@alignCast(arr orelse return false));
    builder.addFloat(value) catch return false;
    return true;
}

/// Add a boolean to the array
export fn zigpug_array_add_bool(arr: ?*ArrayBuilder, value: bool) bool {
    const builder: *ArrayBuilderImpl = @ptrCast(@alignCast(arr orelse return false));
    builder.addBool(value) catch return false;
    return true;
}

/// Add null to the array
export fn zigpug_array_add_null(arr: ?*ArrayBuilder) bool {
    const builder: *ArrayBuilderImpl = @ptrCast(@alignCast(arr orelse return false));
    builder.addNull() catch return false;
    return true;
}

/// Set an array variable in the context using a builder
export fn zigpug_set_array(ctx: ?*ZigPugContext, key: [*:0]const u8, arr: ?*ArrayBuilder) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    const builder: *ArrayBuilderImpl = @ptrCast(@alignCast(arr orelse return false));
    const key_str = std.mem.span(key);

    // Convert builder items to JSON array
    var json_array = std.json.Array.init(context.allocator);
    for (builder.items.items) |item| {
        json_array.append(item) catch return false;
    }

    // Set array in runtime
    context.runtime.setArrayFromJson(key_str, json_array.items) catch return false;

    return true;
}

// ========== Object Builder Functions ==========

/// Create a new object builder
export fn zigpug_object_create(ctx: ?*ZigPugContext) ?*ObjectBuilder {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return null));
    const builder = ObjectBuilderImpl.init(context.allocator) catch return null;
    return @ptrCast(builder);
}

/// Free an object builder
export fn zigpug_object_free(obj: ?*ObjectBuilder) void {
    if (obj) |o| {
        const builder: *ObjectBuilderImpl = @ptrCast(@alignCast(o));
        builder.deinit();
    }
}

/// Set a string property in the object
export fn zigpug_object_set_string(obj: ?*ObjectBuilder, key: [*:0]const u8, value: [*:0]const u8) bool {
    const builder: *ObjectBuilderImpl = @ptrCast(@alignCast(obj orelse return false));
    const key_str = std.mem.span(key);
    const value_str = std.mem.span(value);
    builder.setString(key_str, value_str) catch return false;
    return true;
}

/// Set an integer property in the object
export fn zigpug_object_set_int(obj: ?*ObjectBuilder, key: [*:0]const u8, value: i64) bool {
    const builder: *ObjectBuilderImpl = @ptrCast(@alignCast(obj orelse return false));
    const key_str = std.mem.span(key);
    builder.setInt(key_str, value) catch return false;
    return true;
}

/// Set a float/double property in the object
export fn zigpug_object_set_double(obj: ?*ObjectBuilder, key: [*:0]const u8, value: f64) bool {
    const builder: *ObjectBuilderImpl = @ptrCast(@alignCast(obj orelse return false));
    const key_str = std.mem.span(key);
    builder.setFloat(key_str, value) catch return false;
    return true;
}

/// Set a boolean property in the object
export fn zigpug_object_set_bool(obj: ?*ObjectBuilder, key: [*:0]const u8, value: bool) bool {
    const builder: *ObjectBuilderImpl = @ptrCast(@alignCast(obj orelse return false));
    const key_str = std.mem.span(key);
    builder.setBool(key_str, value) catch return false;
    return true;
}

/// Set a null property in the object
export fn zigpug_object_set_null(obj: ?*ObjectBuilder, key: [*:0]const u8) bool {
    const builder: *ObjectBuilderImpl = @ptrCast(@alignCast(obj orelse return false));
    const key_str = std.mem.span(key);
    builder.setNull(key_str) catch return false;
    return true;
}

/// Set an object variable in the context using a builder
export fn zigpug_set_object(ctx: ?*ZigPugContext, key: [*:0]const u8, obj: ?*ObjectBuilder) bool {
    const context: *Context = @ptrCast(@alignCast(ctx orelse return false));
    const builder: *ObjectBuilderImpl = @ptrCast(@alignCast(obj orelse return false));
    const key_str = std.mem.span(key);

    // Set object in runtime
    context.runtime.setObjectFromJson(key_str, builder.map) catch return false;

    return true;
}

// ============================================================================
// Internal Context (not exported to C)
// ============================================================================

const Context = struct {
    allocator: std.mem.Allocator,
    runtime: *runtime.JsRuntime,
    last_compiler: ?*compiler.Compiler, // Store compiler to access errors

    fn init(allocator: std.mem.Allocator) !Context {
        const rt = try runtime.JsRuntime.init(allocator);
        return Context{
            .allocator = allocator,
            .runtime = rt,
            .last_compiler = null,
        };
    }

    fn deinit(self: *Context) void {
        self.runtime.deinit();
        // Note: last_compiler is not owned, it's just a reference
    }

    fn compile(self: *Context, source: []const u8) ![]const u8 {
        // Parse
        var pars = try parser.Parser.init(self.allocator, source);
        defer pars.deinit();

        const tree = try pars.parse();

        // Compile
        var comp = try compiler.Compiler.init(self.allocator, self.runtime);
        defer comp.deinit();

        // Store compiler reference for error access
        self.last_compiler = comp;
        defer self.last_compiler = null;

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
