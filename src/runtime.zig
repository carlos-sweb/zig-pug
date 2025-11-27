//! JavaScript Runtime using mujs
//!
//! This module provides a JavaScript ES5.1 runtime for evaluating expressions in Pug templates.
//! Uses mujs (https://mujs.com/) - a lightweight (590KB) JavaScript interpreter written in C.
//!
//! Key capabilities:
//! - Evaluate JavaScript expressions: `runtime.eval("name.toUpperCase()")`
//! - Set variables: `runtime.setString("name", "Alice")`
//! - Support for objects, arrays, functions
//! - ES5.1 standard (no ES6+ features like arrow functions, let/const, etc.)
//!
//! Example usage:
//! ```zig
//! var runtime = try JsRuntime.init(allocator);
//! defer runtime.deinit();
//!
//! // Set variables
//! try runtime.setString("name", "Alice");
//! try runtime.setNumber("age", 30);
//!
//! // Evaluate expressions
//! const result = try runtime.eval("name.toUpperCase()"); // "ALICE"
//! defer allocator.free(result);
//! ```
//!
//! Used by compiler.zig to evaluate:
//! - Interpolations: #{name}
//! - Buffered code: = expression
//! - Conditionals: if condition
//! - Loops: each item in items
//! - Attribute expressions: div(class=myClass)
const std = @import("std");
const mujs = @import("mujs_wrapper.zig");

/// Errors that can occur during JavaScript runtime operations
///
/// These are high-level errors that wrap mujs internal errors.
pub const RuntimeError = error{
    OutOfMemory,           // Allocation failed in mujs
    EvalFailed,            // JavaScript code failed to execute
    PropertyNotFound,      // Accessed undefined property
    InvalidExpression,     // Malformed JavaScript
    TypeConversionFailed,  // Could not convert type
    CompileError,          // JavaScript syntax error
    RuntimeError,          // JavaScript runtime error (null access, etc.)
};

/// JavaScript value wrapper for compatibility with template variables
///
/// Represents a JavaScript value as a string. With mujs, values are managed
/// internally by the JS state, so this is a simplified wrapper that holds
/// the string representation of any JavaScript value.
///
/// Fields:
/// - allocator: Memory allocator that owns the value string
/// - value: String representation of the JavaScript value
///
/// Example:
/// ```zig
/// var name = try jsValueFromString(allocator, "Alice");
/// defer name.deinit(allocator);
///
/// try runtime.setContext("username", name);
/// const result = try runtime.eval("username.toUpperCase()");
/// defer allocator.free(result);
/// // result = "ALICE"
/// ```
pub const JsValue = struct {
    allocator: std.mem.Allocator,
    value: []const u8, // String representation

    /// Free the memory used by this value
    ///
    /// Parameters:
    /// - self: The value to free
    /// - allocator: Unused parameter (kept for API compatibility)
    ///
    /// Note: Uses self.allocator internally to free the value string
    pub fn deinit(self: *JsValue, allocator: std.mem.Allocator) void {
        _ = allocator;
        self.allocator.free(self.value);
    }

    /// Create a copy of this value with a different allocator
    ///
    /// Parameters:
    /// - self: The value to clone
    /// - allocator: Allocator for the new copy
    ///
    /// Returns: A new JsValue with duplicated string data
    ///
    /// Example:
    /// ```zig
    /// var original = try jsValueFromString(allocator1, "test");
    /// defer original.deinit(allocator1);
    ///
    /// var copy = try original.clone(allocator2);
    /// defer copy.deinit(allocator2);
    /// ```
    pub fn clone(self: *const JsValue, allocator: std.mem.Allocator) !JsValue {
        return JsValue{
            .allocator = allocator,
            .value = try allocator.dupe(u8, self.value),
        };
    }

    /// Convert this value to a string
    ///
    /// Parameters:
    /// - self: The value to convert
    /// - allocator: Allocator for the returned string
    ///
    /// Returns: Newly allocated string containing the value
    ///
    /// Note: Caller must free the returned string
    ///
    /// Example:
    /// ```zig
    /// var val = try jsValueFromNumber(allocator, 42);
    /// defer val.deinit(allocator);
    ///
    /// const str = try val.toString(allocator);
    /// defer allocator.free(str);
    /// // str = "42"
    /// ```
    pub fn toString(self: *const JsValue, allocator: std.mem.Allocator) ![]const u8 {
        return try allocator.dupe(u8, self.value);
    }
};

/// JavaScript Runtime powered by mujs
///
/// Main interface for executing JavaScript code in Pug templates.
/// Wraps the mujs JavaScript interpreter and provides a simple API
/// for setting variables and evaluating expressions.
///
/// Fields:
/// - allocator: Memory allocator used to create this runtime
/// - mujs_runtime: Internal mujs interpreter instance
///
/// Lifecycle:
/// 1. Create with init()
/// 2. Set variables with setString(), setNumber(), etc.
/// 3. Evaluate expressions with eval()
/// 4. Clean up with deinit()
///
/// Example:
/// ```zig
/// const runtime = try JsRuntime.init(allocator);
/// defer runtime.deinit();
///
/// try runtime.setString("greeting", "Hello");
/// try runtime.setString("name", "World");
///
/// const result = try runtime.eval("greeting + ', ' + name + '!'");
/// defer allocator.free(result);
/// // result = "Hello, World!"
/// ```
pub const JsRuntime = struct {
    allocator: std.mem.Allocator,
    mujs_runtime: *mujs.JsRuntime,

    const Self = @This();

    /// Initialize a new JavaScript runtime
    ///
    /// Creates a new mujs interpreter instance with a clean global scope.
    ///
    /// Parameters:
    /// - allocator: Memory allocator for the runtime
    ///
    /// Returns: Pointer to the new runtime instance
    ///
    /// Errors:
    /// - OutOfMemory: Failed to allocate runtime or mujs state
    ///
    /// Example:
    /// ```zig
    /// const runtime = try JsRuntime.init(allocator);
    /// defer runtime.deinit();
    ///
    /// try runtime.setNumber("x", 10);
    /// const result = try runtime.eval("x * 2");
    /// defer allocator.free(result);
    /// // result = "20"
    /// ```
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
    ///
    /// Shuts down the mujs interpreter and frees all associated memory.
    /// All variables and state are lost after calling this.
    ///
    /// Parameters:
    /// - self: The runtime to destroy
    ///
    /// Example:
    /// ```zig
    /// const runtime = try JsRuntime.init(allocator);
    /// try runtime.setString("data", "important");
    /// runtime.deinit(); // All data is now lost
    /// ```
    pub fn deinit(self: *Self) void {
        self.mujs_runtime.deinit();
        self.allocator.destroy(self);
    }

    /// Evaluate a JavaScript expression and return the result as a string
    ///
    /// Executes JavaScript code in the runtime's global scope and converts
    /// the result to a string. Supports all ES5.1 features.
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - expr: JavaScript expression to evaluate
    ///
    /// Returns: String representation of the result
    ///
    /// Errors:
    /// - EvalFailed: Syntax error or runtime error in JavaScript
    /// - OutOfMemory: Failed to allocate result string
    ///
    /// Example:
    /// ```zig
    /// try runtime.setString("name", "alice");
    ///
    /// const upper = try runtime.eval("name.toUpperCase()");
    /// defer allocator.free(upper);
    /// // upper = "ALICE"
    ///
    /// const concat = try runtime.eval("'Hello ' + name");
    /// defer allocator.free(concat);
    /// // concat = "Hello alice"
    /// ```
    pub fn eval(self: *Self, expr: []const u8) ![]const u8 {
        return self.mujs_runtime.eval(expr) catch |err| {
            return switch (err) {
                error.CompileError => RuntimeError.EvalFailed,
                error.RuntimeError => RuntimeError.EvalFailed,
                error.OutOfMemory => RuntimeError.OutOfMemory,
            };
        };
    }

    /// Set a context variable from a JsValue
    ///
    /// Convenience method for setting variables from JsValue wrappers.
    /// Internally extracts the string value and calls setString().
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - key: Variable name in JavaScript scope
    /// - value: JsValue containing the value to set
    ///
    /// Example:
    /// ```zig
    /// var val = try jsValueFromString(allocator, "test");
    /// defer val.deinit(allocator);
    ///
    /// try runtime.setContext("myVar", val);
    /// const result = try runtime.eval("myVar");
    /// defer allocator.free(result);
    /// // result = "test"
    /// ```
    pub fn setContext(self: *Self, key: []const u8, value: JsValue) !void {
        try self.mujs_runtime.setString(key, value.value);
    }

    /// Set a string variable in the JavaScript scope
    ///
    /// Creates or updates a global variable with a string value.
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - key: Variable name
    /// - value: String value to assign
    ///
    /// Example:
    /// ```zig
    /// try runtime.setString("greeting", "Hello");
    /// try runtime.setString("name", "Bob");
    ///
    /// const result = try runtime.eval("greeting + ' ' + name");
    /// defer allocator.free(result);
    /// // result = "Hello Bob"
    /// ```
    pub fn setString(self: *Self, key: []const u8, value: []const u8) !void {
        try self.mujs_runtime.setString(key, value);
    }

    /// Set a number variable in the JavaScript scope
    ///
    /// Creates or updates a global variable with a numeric value.
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - key: Variable name
    /// - value: Number to assign (f64)
    ///
    /// Example:
    /// ```zig
    /// try runtime.setNumber("pi", 3.14159);
    /// try runtime.setNumber("radius", 10);
    ///
    /// const result = try runtime.eval("2 * pi * radius");
    /// defer allocator.free(result);
    /// // result = "62.8318"
    /// ```
    pub fn setNumber(self: *Self, key: []const u8, value: f64) !void {
        try self.mujs_runtime.setNumber(key, value);
    }

    /// Set a boolean variable in the JavaScript scope
    ///
    /// Creates or updates a global variable with a boolean value.
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - key: Variable name
    /// - value: Boolean to assign
    ///
    /// Example:
    /// ```zig
    /// try runtime.setBool("isActive", true);
    /// try runtime.setBool("isAdmin", false);
    ///
    /// const result = try runtime.eval("isActive && isAdmin");
    /// defer allocator.free(result);
    /// // result = "false"
    /// ```
    pub fn setBool(self: *Self, key: []const u8, value: bool) !void {
        try self.mujs_runtime.setBool(key, value);
    }

    /// Set an integer variable in the JavaScript scope
    ///
    /// Converts the integer to f64 and sets it as a number variable.
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - key: Variable name
    /// - value: Integer to assign (i64)
    ///
    /// Note: Large integers may lose precision when converted to f64
    ///
    /// Example:
    /// ```zig
    /// try runtime.setInt("count", 42);
    ///
    /// const result = try runtime.eval("count + 8");
    /// defer allocator.free(result);
    /// // result = "50"
    /// ```
    pub fn setInt(self: *Self, key: []const u8, value: i64) !void {
        try self.mujs_runtime.setNumber(key, @as(f64, @floatFromInt(value)));
    }

    /// Evaluate property access expression
    ///
    /// Legacy method for evaluating property paths. With mujs, this simply
    /// forwards to eval() since property access is handled natively.
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - root: Original root value (ignored)
    /// - path: Property path to evaluate (e.g., "user.name")
    ///
    /// Returns: String result of evaluating the path
    ///
    /// Note: This method exists for API compatibility. Prefer using eval() directly.
    ///
    /// Example:
    /// ```zig
    /// _ = try runtime.eval("var user = {name: 'Alice', age: 30}");
    ///
    /// const name = try runtime.evalPropertyAccess(undefined, "user.name");
    /// defer allocator.free(name);
    /// // name = "Alice"
    /// ```
    pub fn evalPropertyAccess(self: *Self, root: *const JsValue, path: []const u8) ![]const u8 {
        _ = root; // Not needed with mujs - just evaluate the full expression
        return try self.eval(path);
    }

    /// Set an array variable from JSON values
    ///
    /// Creates a JavaScript array from Zig JSON values.
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - key: Variable name for the array
    /// - values: Slice of JSON values to populate the array
    ///
    /// Example:
    /// ```zig
    /// const json_values = &[_]std.json.Value{
    ///     .{ .string = "apple" },
    ///     .{ .string = "banana" },
    ///     .{ .string = "cherry" },
    /// };
    ///
    /// try runtime.setArrayFromJson("fruits", json_values);
    ///
    /// const result = try runtime.eval("fruits[1]");
    /// defer allocator.free(result);
    /// // result = "banana"
    /// ```
    pub fn setArrayFromJson(self: *Self, key: []const u8, values: []const std.json.Value) !void {
        try self.mujs_runtime.setArrayFromJson(key, values);
    }

    /// Set an object variable from JSON object
    ///
    /// Creates a JavaScript object from a Zig JSON ObjectMap.
    ///
    /// Parameters:
    /// - self: The runtime instance
    /// - key: Variable name for the object
    /// - obj: JSON object map with properties
    ///
    /// Example:
    /// ```zig
    /// var obj = std.json.ObjectMap.init(allocator);
    /// try obj.put("name", .{ .string = "Alice" });
    /// try obj.put("age", .{ .integer = 30 });
    ///
    /// try runtime.setObjectFromJson("user", obj);
    ///
    /// const result = try runtime.eval("user.name + ' is ' + user.age");
    /// defer allocator.free(result);
    /// // result = "Alice is 30"
    /// ```
    pub fn setObjectFromJson(self: *Self, key: []const u8, obj: std.json.ObjectMap) !void {
        try self.mujs_runtime.setObjectFromJson(key, obj);
    }

    /// Run garbage collection
    ///
    /// Triggers mujs garbage collector to free unused JavaScript objects.
    /// Normally called automatically, but can be invoked manually for
    /// performance tuning in memory-constrained environments.
    ///
    /// Parameters:
    /// - self: The runtime instance
    ///
    /// Example:
    /// ```zig
    /// // Create lots of temporary objects
    /// for (0..1000) |i| {
    ///     _ = try runtime.eval("var temp = {data: 'value'}");
    /// }
    ///
    /// // Clean up unused objects
    /// runtime.gc();
    /// ```
    pub fn gc(self: *Self) void {
        self.mujs_runtime.gc();
    }
};

/// Helper function to create a JsValue from a string
///
/// Wraps a string value in a JsValue for use with setContext().
///
/// Parameters:
/// - allocator: Memory allocator for the value
/// - value: String to wrap
///
/// Returns: JsValue containing a copy of the string
///
/// Example:
/// ```zig
/// var name = try jsValueFromString(allocator, "Alice");
/// defer name.deinit(allocator);
///
/// try runtime.setContext("user", name);
/// const result = try runtime.eval("user");
/// defer allocator.free(result);
/// // result = "Alice"
/// ```
pub fn jsValueFromString(allocator: std.mem.Allocator, value: []const u8) !JsValue {
    return JsValue{
        .allocator = allocator,
        .value = try allocator.dupe(u8, value),
    };
}

/// Helper function to create a JsValue from a number
///
/// Converts a number to string and wraps it in a JsValue.
///
/// Parameters:
/// - allocator: Memory allocator for the value
/// - value: Number to convert (f64)
///
/// Returns: JsValue containing the number as a string
///
/// Example:
/// ```zig
/// var age = try jsValueFromNumber(allocator, 42);
/// defer age.deinit(allocator);
///
/// try runtime.setContext("userAge", age);
/// const result = try runtime.eval("userAge * 2");
/// defer allocator.free(result);
/// // result = "84"
/// ```
pub fn jsValueFromNumber(allocator: std.mem.Allocator, value: f64) !JsValue {
    const str = try std.fmt.allocPrint(allocator, "{d}", .{value});
    return JsValue{
        .allocator = allocator,
        .value = str,
    };
}

/// Helper function to create a JsValue from a boolean
///
/// Converts a boolean to string ("true" or "false") and wraps it in a JsValue.
///
/// Parameters:
/// - allocator: Memory allocator for the value
/// - value: Boolean to convert
///
/// Returns: JsValue containing "true" or "false"
///
/// Example:
/// ```zig
/// var active = try jsValueFromBool(allocator, true);
/// defer active.deinit(allocator);
///
/// try runtime.setContext("isActive", active);
/// const result = try runtime.eval("isActive ? 'yes' : 'no'");
/// defer allocator.free(result);
/// // result = "yes"
/// ```
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
