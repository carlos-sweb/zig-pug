/// JavaScript Runtime using mujs
/// This module provides a JavaScript runtime for evaluating expressions in Pug templates
/// Uses mujs (https://mujs.com/) - a lightweight ES5.1 JavaScript interpreter
const std = @import("std");
const mujs = @import("mujs_wrapper.zig");

pub const RuntimeError = error{
    OutOfMemory,
    EvalFailed,
    PropertyNotFound,
    InvalidExpression,
    TypeConversionFailed,
    CompileError,
    RuntimeError,
};

/// JsValue type - for compatibility with existing code
/// With mujs, values are managed internally by the JS state
/// This is a simplified placeholder that doesn't need to match the old complex union
pub const JsValue = struct {
    allocator: std.mem.Allocator,
    value: []const u8, // String representation

    pub fn deinit(self: *JsValue, allocator: std.mem.Allocator) void {
        _ = allocator;
        self.allocator.free(self.value);
    }

    pub fn clone(self: *const JsValue, allocator: std.mem.Allocator) !JsValue {
        return JsValue{
            .allocator = allocator,
            .value = try allocator.dupe(u8, self.value),
        };
    }

    pub fn toString(self: *const JsValue, allocator: std.mem.Allocator) ![]const u8 {
        return try allocator.dupe(u8, self.value);
    }
};

/// JavaScript Runtime powered by mujs
pub const JsRuntime = struct {
    allocator: std.mem.Allocator,
    mujs_runtime: *mujs.JsRuntime,

    const Self = @This();

    /// Initialize a new JavaScript runtime
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const runtime = try allocator.create(Self);
        errdefer allocator.destroy(runtime);

        const mujs_runtime = try mujs.JsRuntime.init(allocator);
        errdefer mujs_runtime.deinit();

        runtime.* = .{
            .allocator = allocator,
            .mujs_runtime = mujs_runtime,
        };

        return runtime;
    }

    /// Free the runtime and all resources
    pub fn deinit(self: *Self) void {
        self.mujs_runtime.deinit();
        self.allocator.destroy(self);
    }

    /// Evaluate a JavaScript expression and return the result as a string
    pub fn eval(self: *Self, expr: []const u8) ![]const u8 {
        return self.mujs_runtime.eval(expr) catch |err| {
            return switch (err) {
                error.CompileError => RuntimeError.EvalFailed,
                error.RuntimeError => RuntimeError.EvalFailed,
                error.OutOfMemory => RuntimeError.OutOfMemory,
            };
        };
    }

    /// Set a context variable (string value)
    pub fn setContext(self: *Self, key: []const u8, value: JsValue) !void {
        try self.mujs_runtime.setString(key, value.value);
    }

    /// Set a string variable
    pub fn setString(self: *Self, key: []const u8, value: []const u8) !void {
        try self.mujs_runtime.setString(key, value);
    }

    /// Set a number variable
    pub fn setNumber(self: *Self, key: []const u8, value: f64) !void {
        try self.mujs_runtime.setNumber(key, value);
    }

    /// Set a boolean variable
    pub fn setBool(self: *Self, key: []const u8, value: bool) !void {
        try self.mujs_runtime.setBool(key, value);
    }

    /// Set an integer variable
    pub fn setInt(self: *Self, key: []const u8, value: i64) !void {
        try self.mujs_runtime.setNumber(key, @as(f64, @floatFromInt(value)));
    }

    /// Evaluate property access (e.g., "user.name")
    /// This is now handled directly by mujs in eval()
    pub fn evalPropertyAccess(self: *Self, root: *const JsValue, path: []const u8) ![]const u8 {
        _ = root; // Not needed with mujs - just evaluate the full expression
        return try self.eval(path);
    }

    /// Set an array variable from JSON values
    pub fn setArrayFromJson(self: *Self, key: []const u8, values: []const std.json.Value) !void {
        try self.mujs_runtime.setArrayFromJson(key, values);
    }

    /// Set an object variable from JSON object
    pub fn setObjectFromJson(self: *Self, key: []const u8, obj: std.json.ObjectMap) !void {
        try self.mujs_runtime.setObjectFromJson(key, obj);
    }

    /// Run garbage collection
    pub fn gc(self: *Self) void {
        self.mujs_runtime.gc();
    }
};

/// Helper function to create a JsValue from a string
pub fn jsValueFromString(allocator: std.mem.Allocator, value: []const u8) !JsValue {
    return JsValue{
        .allocator = allocator,
        .value = try allocator.dupe(u8, value),
    };
}

/// Helper function to create a JsValue from a number
pub fn jsValueFromNumber(allocator: std.mem.Allocator, value: f64) !JsValue {
    const str = try std.fmt.allocPrint(allocator, "{d}", .{value});
    return JsValue{
        .allocator = allocator,
        .value = str,
    };
}

/// Helper function to create a JsValue from a boolean
pub fn jsValueFromBool(allocator: std.mem.Allocator, value: bool) !JsValue {
    const str = if (value) "true" else "false";
    return JsValue{
        .allocator = allocator,
        .value = try allocator.dupe(u8, str),
    };
}

// ============================================================================
// Tests
// ============================================================================

test "runtime - basic variable access" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.setString("name", "Alice");
    const result = try runtime.eval("name");
    defer allocator.free(result);

    try std.testing.expectEqualStrings("Alice", result);
}

test "runtime - string methods" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.setString("name", "World");

    const lower = try runtime.eval("name.toLowerCase()");
    defer allocator.free(lower);
    try std.testing.expectEqualStrings("world", lower);

    const upper = try runtime.eval("name.toUpperCase()");
    defer allocator.free(upper);
    try std.testing.expectEqualStrings("WORLD", upper);
}

test "runtime - numbers and arithmetic" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.setNumber("age", 42);

    const result = try runtime.eval("age + 10");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("52", result);
}

test "runtime - booleans" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.setBool("active", true);

    const result = try runtime.eval("active");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("true", result);
}

test "runtime - object property access" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    // Create object using JavaScript
    _ = try runtime.eval("var user = {name: 'Bob', age: 30}");

    const name = try runtime.eval("user.name");
    defer allocator.free(name);
    try std.testing.expectEqualStrings("Bob", name);

    const age = try runtime.eval("user.age");
    defer allocator.free(age);
    try std.testing.expectEqualStrings("30", age);
}

test "runtime - JsValue compatibility" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    // Test JsValue creation and usage
    var name_val = try jsValueFromString(allocator, "Alice");
    defer name_val.deinit(allocator);

    try runtime.setContext("name", name_val);

    const result = try runtime.eval("name");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("Alice", result);
}

test "runtime - array indexing" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    _ = try runtime.eval("var items = ['first', 'second', 'third']");

    const result = try runtime.eval("items[1]");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("second", result);
}

test "runtime - complex expressions" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.setString("firstName", "John");
    try runtime.setString("lastName", "Doe");

    const result = try runtime.eval("firstName + ' ' + lastName");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("John Doe", result);
}
