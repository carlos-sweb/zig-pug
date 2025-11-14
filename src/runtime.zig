const std = @import("std");

// JavaScript Runtime - Stub Implementation for Termux/Android
// This is a simplified mock runtime that works without QuickJS
// Replace with real QuickJS implementation when running on standard Linux/Mac

// LIMITATIONS:
// - eval() only supports simple variable access (no methods, no operators)
// - No JavaScript libraries (voca.js, numeral.js, etc.)
// - No complex expressions
//
// FUTURE: When QuickJS is available, this will be replaced with full JS evaluation

pub const RuntimeError = error{
    OutOfMemory,
    EvalFailed,
    PropertyNotFound,
    InvalidExpression,
    TypeConversionFailed,
};

pub const JsValue = union(enum) {
    null_value,
    undefined,
    bool_value: bool,
    int_value: i64,
    float_value: f64,
    string_value: []const u8,
    object_value: std.StringHashMap(JsValue),
    array_value: std.ArrayList(JsValue),

    pub fn deinit(self: *JsValue, allocator: std.mem.Allocator) void {
        switch (self.*) {
            .string_value => |s| allocator.free(s),
            .object_value => |*obj| {
                var iter = obj.iterator();
                while (iter.next()) |entry| {
                    var val = entry.value_ptr.*;
                    val.deinit(allocator);
                }
                obj.deinit();
            },
            .array_value => |*arr| {
                for (arr.items) |*item| {
                    item.deinit(allocator);
                }
                arr.deinit(allocator);
            },
            else => {},
        }
    }

    pub fn clone(self: *const JsValue, allocator: std.mem.Allocator) !JsValue {
        return switch (self.*) {
            .null_value => .null_value,
            .undefined => .undefined,
            .bool_value => |b| .{ .bool_value = b },
            .int_value => |i| .{ .int_value = i },
            .float_value => |f| .{ .float_value = f },
            .string_value => |s| .{ .string_value = try allocator.dupe(u8, s) },
            .object_value => |obj| {
                var new_obj = std.StringHashMap(JsValue).init(allocator);
                var iter = obj.iterator();
                while (iter.next()) |entry| {
                    const cloned_value = try entry.value_ptr.clone(allocator);
                    try new_obj.put(entry.key_ptr.*, cloned_value);
                }
                return .{ .object_value = new_obj };
            },
            .array_value => |arr| {
                var new_arr: std.ArrayList(JsValue) = .{};
                for (arr.items) |*item| {
                    try new_arr.append(allocator, try item.clone(allocator));
                }
                return .{ .array_value = new_arr };
            },
        };
    }

    pub fn toString(self: *const JsValue, allocator: std.mem.Allocator) ![]const u8 {
        return switch (self.*) {
            .null_value => try allocator.dupe(u8, "null"),
            .undefined => try allocator.dupe(u8, "undefined"),
            .bool_value => |b| try allocator.dupe(u8, if (b) "true" else "false"),
            .int_value => |i| try std.fmt.allocPrint(allocator, "{d}", .{i}),
            .float_value => |f| try std.fmt.allocPrint(allocator, "{d}", .{f}),
            .string_value => |s| try allocator.dupe(u8, s),
            .object_value => try allocator.dupe(u8, "[object Object]"),
            .array_value => try allocator.dupe(u8, "[object Array]"),
        };
    }
};

pub const JsRuntime = struct {
    allocator: std.mem.Allocator,
    context: std.StringHashMap(JsValue),

    const Self = @This();

    pub fn init(allocator: std.mem.Allocator) !*Self {
        const runtime = try allocator.create(Self);
        runtime.* = .{
            .allocator = allocator,
            .context = std.StringHashMap(JsValue).init(allocator),
        };
        return runtime;
    }

    pub fn deinit(self: *Self) void {
        var iter = self.context.iterator();
        while (iter.next()) |entry| {
            var val = entry.value_ptr.*;
            val.deinit(self.allocator);
        }
        self.context.deinit();
        self.allocator.destroy(self);
    }

    /// Set a variable in the global context
    pub fn setContext(self: *Self, key: []const u8, value: JsValue) !void {
        // If key already exists, deinit old value
        if (self.context.get(key)) |*old_value| {
            var old = old_value.*;
            old.deinit(self.allocator);
        }

        const cloned_value = try value.clone(self.allocator);
        try self.context.put(key, cloned_value);
    }

    /// Evaluate a JavaScript expression (STUB VERSION - Limited functionality)
    /// Only supports:
    /// - Simple variable access: "name"
    /// - Property access: "user.name"
    /// - Array access: "items.0"
    ///
    /// Does NOT support (until QuickJS integration):
    /// - Methods: "name.toLowerCase()"
    /// - Operators: "price + tax"
    /// - Complex expressions
    pub fn eval(self: *Self, expr: []const u8) ![]const u8 {
        // Trim whitespace
        const trimmed = std.mem.trim(u8, expr, " \t\n\r");

        // Check if it's a property access (e.g., "user.name" or "items.0")
        if (std.mem.indexOf(u8, trimmed, ".")) |dot_index| {
            const root_var = trimmed[0..dot_index];
            const rest = trimmed[dot_index + 1 ..];

            // Get root object
            const root_value = self.context.get(root_var) orelse return error.PropertyNotFound;

            // Navigate property chain
            return try self.evalPropertyAccess(&root_value, rest);
        }

        // Simple variable access
        const value = self.context.get(trimmed) orelse return error.PropertyNotFound;
        return try value.toString(self.allocator);
    }

    fn evalPropertyAccess(self: *Self, obj: *const JsValue, path: []const u8) ![]const u8 {
        // For stub: only support one level of property access
        const trimmed_path = std.mem.trim(u8, path, " \t\n\r");

        switch (obj.*) {
            .object_value => |hash_map| {
                const prop_value = hash_map.get(trimmed_path) orelse return error.PropertyNotFound;
                return try prop_value.toString(self.allocator);
            },
            .array_value => |arr| {
                // Try to parse as array index
                const index = std.fmt.parseInt(usize, trimmed_path, 10) catch return error.InvalidExpression;
                if (index >= arr.items.len) return error.PropertyNotFound;
                return try arr.items[index].toString(self.allocator);
            },
            else => return error.InvalidExpression,
        }
    }

    /// Load a JavaScript library (STUB - Not implemented)
    /// In real QuickJS version, this would execute the library code
    pub fn loadLibrary(self: *Self, name: []const u8, code: []const u8) !void {
        _ = self;
        _ = name;
        _ = code;
        // Stub: libraries not supported without QuickJS
        // When QuickJS is integrated, this will execute the JS code
    }
};

// Helper functions to create JsValue from Zig types

pub fn jsValueFromString(allocator: std.mem.Allocator, s: []const u8) !JsValue {
    return .{ .string_value = try allocator.dupe(u8, s) };
}

pub fn jsValueFromInt(i: i64) JsValue {
    return .{ .int_value = i };
}

pub fn jsValueFromFloat(f: f64) JsValue {
    return .{ .float_value = f };
}

pub fn jsValueFromBool(b: bool) JsValue {
    return .{ .bool_value = b };
}

pub fn jsValueNull() JsValue {
    return .null_value;
}

pub fn jsValueUndefined() JsValue {
    return .undefined;
}

test "runtime - simple variable access" {
    const allocator = std.testing.allocator;
    var runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    const name_value = try jsValueFromString(allocator, "John");
    try runtime.setContext("name", name_value);
    // name_value is cloned in setContext, so we need to free original
    var name_copy = name_value;
    name_copy.deinit(allocator);

    const result = try runtime.eval("name");
    defer allocator.free(result);

    try std.testing.expectEqualStrings("John", result);
}

test "runtime - object property access" {
    const allocator = std.testing.allocator;
    var runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    var user_obj = std.StringHashMap(JsValue).init(allocator);
    const name_val = try jsValueFromString(allocator, "Alice");
    try user_obj.put("name", name_val);
    try user_obj.put("age", jsValueFromInt(30));

    const user_value = JsValue{ .object_value = user_obj };
    try runtime.setContext("user", user_value);

    // user_value is cloned in setContext, so free the original
    var user_copy = user_value;
    user_copy.deinit(allocator);

    const result = try runtime.eval("user.name");
    defer allocator.free(result);

    try std.testing.expectEqualStrings("Alice", result);
}
