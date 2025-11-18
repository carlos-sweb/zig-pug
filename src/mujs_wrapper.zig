/// Wrapper de Zig para la API de mujs (lightweight JavaScript interpreter)
/// mujs documentation: https://mujs.com/reference.html
const std = @import("std");

// Opaque type para el estado de mujs
pub const MuJsState = opaque {};

// Tipos de callback para C functions
pub const CFunction = *const fn (*MuJsState) callconv(.C) void;

// ============================================================================
// State management
// ============================================================================

pub extern fn js_newstate(alloc: ?*anyopaque, actx: ?*anyopaque, flags: c_int) ?*MuJsState;
pub extern fn js_freestate(J: ?*MuJsState) void;
pub extern fn js_gc(J: ?*MuJsState, report: c_int) void;

// ============================================================================
// Code execution
// ============================================================================

pub extern fn js_loadstring(J: ?*MuJsState, filename: [*:0]const u8, source: [*:0]const u8) void;
pub extern fn js_dostring(J: ?*MuJsState, source: [*:0]const u8) c_int;

// Protected versions (return error code instead of throwing)
pub extern fn js_ploadstring(J: ?*MuJsState, filename: [*:0]const u8, source: [*:0]const u8) c_int;
pub extern fn js_pcall(J: ?*MuJsState, n: c_int) c_int;

// ============================================================================
// Stack operations
// ============================================================================

pub extern fn js_gettop(J: ?*MuJsState) c_int;
pub extern fn js_pop(J: ?*MuJsState, n: c_int) void;
pub extern fn js_copy(J: ?*MuJsState, idx: c_int) void;

// ============================================================================
// Push values onto stack
// ============================================================================

pub extern fn js_pushundefined(J: ?*MuJsState) void;
pub extern fn js_pushnull(J: ?*MuJsState) void;
pub extern fn js_pushboolean(J: ?*MuJsState, v: c_int) void;
pub extern fn js_pushnumber(J: ?*MuJsState, v: f64) void;
pub extern fn js_pushstring(J: ?*MuJsState, s: [*:0]const u8) void;
pub extern fn js_newobject(J: ?*MuJsState) void;
pub extern fn js_newcfunction(J: ?*MuJsState, fun: CFunction, name: [*:0]const u8, length: c_int) void;

// ============================================================================
// Convert stack values to C types
// ============================================================================

pub extern fn js_toboolean(J: ?*MuJsState, idx: c_int) c_int;
pub extern fn js_tonumber(J: ?*MuJsState, idx: c_int) f64;
pub extern fn js_tostring(J: ?*MuJsState, idx: c_int) [*:0]const u8;
pub extern fn js_trystring(J: ?*MuJsState, idx: c_int, error_msg: [*:0]const u8) [*:0]const u8;

// ============================================================================
// Type checking
// ============================================================================

pub extern fn js_isundefined(J: ?*MuJsState, idx: c_int) c_int;
pub extern fn js_isnull(J: ?*MuJsState, idx: c_int) c_int;
pub extern fn js_isboolean(J: ?*MuJsState, idx: c_int) c_int;
pub extern fn js_isnumber(J: ?*MuJsState, idx: c_int) c_int;
pub extern fn js_isstring(J: ?*MuJsState, idx: c_int) c_int;

// ============================================================================
// Global variable access
// ============================================================================

pub extern fn js_getglobal(J: ?*MuJsState, name: [*:0]const u8) void;
pub extern fn js_setglobal(J: ?*MuJsState, name: [*:0]const u8) void;

// ============================================================================
// Object property access
// ============================================================================

pub extern fn js_getproperty(J: ?*MuJsState, idx: c_int, name: [*:0]const u8) void;
pub extern fn js_setproperty(J: ?*MuJsState, idx: c_int, name: [*:0]const u8) void;

// ============================================================================
// High-level Zig wrapper for mujs
// ============================================================================

pub const JsRuntime = struct {
    state: *MuJsState,
    allocator: std.mem.Allocator,

    const Self = @This();

    /// Initialize a new JavaScript runtime using mujs
    pub fn init(allocator: std.mem.Allocator) !*Self {
        const runtime = try allocator.create(Self);
        errdefer allocator.destroy(runtime);

        const state = js_newstate(null, null, 0) orelse {
            return error.InitFailed;
        };

        runtime.* = .{
            .state = state,
            .allocator = allocator,
        };

        // Setup basic console.log functionality
        try runtime.setupConsole();

        return runtime;
    }

    /// Free the JavaScript runtime and all associated resources
    pub fn deinit(self: *Self) void {
        js_freestate(self.state);
        self.allocator.destroy(self);
    }

    /// Setup console object with log function
    fn setupConsole(self: *Self) !void {
        // Create a simple console.log stub (no-op for now)
        _ = js_ploadstring(self.state, "[init]", "var console = {log: function(){}};");
        js_pushundefined(self.state);
        _ = js_pcall(self.state, 0);
        js_pop(self.state, 1);
    }

    /// Evaluate a JavaScript expression and return the result as a string
    pub fn eval(self: *Self, expr: []const u8) ![]const u8 {
        // Create null-terminated string
        const expr_z = try self.allocator.dupeZ(u8, expr);
        defer self.allocator.free(expr_z);

        // Load and compile the code
        if (js_ploadstring(self.state, "[eval]", expr_z) != 0) {
            const err_msg = js_trystring(self.state, -1, "unknown compile error");
            std.debug.print("mujs compile error: {s}\n", .{err_msg});
            js_pop(self.state, 1);
            return error.CompileError;
        }

        // Call with no arguments (pushundefined is 'this')
        js_pushundefined(self.state);
        if (js_pcall(self.state, 0) != 0) {
            const err_msg = js_trystring(self.state, -1, "unknown runtime error");
            std.debug.print("mujs runtime error in '{s}': {s}\n", .{ expr, err_msg });
            js_pop(self.state, 1);
            return error.RuntimeError;
        }

        // Get the result as string
        const result_cstr = js_tostring(self.state, -1);
        const result = try self.allocator.dupe(u8, std.mem.span(result_cstr));
        js_pop(self.state, 1);

        return result;
    }

    /// Set a string variable in the global scope
    pub fn setString(self: *Self, key: []const u8, value: []const u8) !void {
        const key_z = try self.allocator.dupeZ(u8, key);
        defer self.allocator.free(key_z);

        const value_z = try self.allocator.dupeZ(u8, value);
        defer self.allocator.free(value_z);

        js_pushstring(self.state, value_z);
        js_setglobal(self.state, key_z);
    }

    /// Set a number variable in the global scope
    pub fn setNumber(self: *Self, key: []const u8, value: f64) !void {
        const key_z = try self.allocator.dupeZ(u8, key);
        defer self.allocator.free(key_z);

        js_pushnumber(self.state, value);
        js_setglobal(self.state, key_z);
    }

    /// Set a boolean variable in the global scope
    pub fn setBool(self: *Self, key: []const u8, value: bool) !void {
        const key_z = try self.allocator.dupeZ(u8, key);
        defer self.allocator.free(key_z);

        js_pushboolean(self.state, if (value) 1 else 0);
        js_setglobal(self.state, key_z);
    }

    /// Set an object variable in the global scope
    pub fn setObject(self: *Self, key: []const u8, properties: anytype) !void {
        const key_z = try self.allocator.dupeZ(u8, key);
        defer self.allocator.free(key_z);

        // Create new object
        js_newobject(self.state);

        // Set properties
        const info = @typeInfo(@TypeOf(properties));
        if (info != .Struct) {
            @compileError("properties must be a struct");
        }

        inline for (info.Struct.fields) |field| {
            const prop_name_z = try self.allocator.dupeZ(u8, field.name);
            defer self.allocator.free(prop_name_z);

            const value = @field(properties, field.name);
            const ValueType = @TypeOf(value);

            if (ValueType == []const u8) {
                const value_z = try self.allocator.dupeZ(u8, value);
                defer self.allocator.free(value_z);
                js_pushstring(self.state, value_z);
            } else if (ValueType == f64 or ValueType == comptime_int or ValueType == comptime_float) {
                js_pushnumber(self.state, @as(f64, @floatCast(value)));
            } else if (ValueType == bool) {
                js_pushboolean(self.state, if (value) 1 else 0);
            } else {
                @compileError("Unsupported property type: " ++ @typeName(ValueType));
            }

            js_setproperty(self.state, -2, prop_name_z);
        }

        js_setglobal(self.state, key_z);
    }

    /// Run garbage collection
    pub fn gc(self: *Self) void {
        js_gc(self.state, 0);
    }
};

// ============================================================================
// Tests
// ============================================================================

test "mujs wrapper - basic operations" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    // Test setting and getting string
    try runtime.setString("name", "Alice");
    const result = try runtime.eval("name");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("Alice", result);
}

test "mujs wrapper - string methods" {
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

test "mujs wrapper - numbers" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.setNumber("age", 42);

    const result = try runtime.eval("age + 10");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("52", result);
}

test "mujs wrapper - booleans" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    try runtime.setBool("active", true);

    const result = try runtime.eval("active");
    defer allocator.free(result);
    try std.testing.expectEqualStrings("true", result);
}

test "mujs wrapper - object properties" {
    const allocator = std.testing.allocator;

    const runtime = try JsRuntime.init(allocator);
    defer runtime.deinit();

    // Set object using JavaScript
    _ = try runtime.eval("var user = {name: 'Bob', age: 30}");

    const name = try runtime.eval("user.name");
    defer allocator.free(name);
    try std.testing.expectEqualStrings("Bob", name);

    const age = try runtime.eval("user.age");
    defer allocator.free(age);
    try std.testing.expectEqualStrings("30", age);
}
