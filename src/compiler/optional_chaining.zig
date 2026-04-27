//! Optional Chaining Transformer
//!
//! Transforms modern JavaScript optional chaining syntax (?.) into ES5.1 compatible code
//! that mujs can execute.
//!
//! Examples:
//! - "item?.tags" -> "item && item.hasOwnProperty('tags') ? item.tags : []"
//! - "obj?.prop?.nested" -> "obj && obj.hasOwnProperty('prop') && obj.prop.hasOwnProperty('nested') ? obj.prop.nested : []"
//! - "items" -> "items" (no change)

const std = @import("std");

/// Transform optional chaining (?.) syntax into ES5.1 compatible code
///
/// This function detects the optional chaining operator (?.) in JavaScript expressions
/// and transforms them into safe property access using hasOwnProperty checks.
///
/// Parameters:
/// - allocator: Memory allocator for the result
/// - expr: JavaScript expression that may contain ?.
///
/// Returns:
/// - Transformed expression compatible with ES5.1 (mujs)
///
/// Examples:
/// ```
/// transformOptionalChaining("item?.tags")
/// // Returns: "item && item.hasOwnProperty('tags') ? item.tags : []"
///
/// transformOptionalChaining("obj?.a?.b")
/// // Returns: "obj && obj.hasOwnProperty('a') && obj.a.hasOwnProperty('b') ? obj.a.b : []"
///
/// transformOptionalChaining("items")
/// // Returns: "items" (unchanged)
/// ```
pub fn transformOptionalChaining(
    allocator: std.mem.Allocator,
    expr: []const u8,
) ![]const u8 {
    // Quick check: if no "?." present, return unchanged
    if (std.mem.indexOf(u8, expr, "?.") == null) {
        return try allocator.dupe(u8, expr);
    }

    // Count how many parts we have
    var count: usize = 0;
    var count_iter = std.mem.splitSequence(u8, expr, "?.");
    while (count_iter.next()) |_| {
        count += 1;
    }

    // If only one part, no optional chaining was actually present
    if (count <= 1) {
        return try allocator.dupe(u8, expr);
    }

    // Allocate array for parts
    const parts = try allocator.alloc([]const u8, count);
    defer allocator.free(parts);

    // Fill parts array
    var iter = std.mem.splitSequence(u8, expr, "?.");
    var i: usize = 0;
    while (iter.next()) |part| {
        parts[i] = std.mem.trim(u8, part, " \t\r\n");
        i += 1;
    }

    // Build the transformed expression
    var result: std.ArrayList(u8) = .empty;

    // Build condition part: "obj && obj.hasOwnProperty('prop') && obj.prop.hasOwnProperty('nested')"
    // Build value part: "obj.prop.nested"

    // First part is the base object
    const base = parts[0];

    // Start with base check
    try result.appendSlice(allocator, base);

    // Build the chain of hasOwnProperty checks
    var current_path: std.ArrayList(u8) = .empty;
    defer current_path.deinit(allocator);
    try current_path.appendSlice(allocator, base);

    for (parts[1..]) |prop| {
        if (prop.len == 0) continue;

        // Add check: " && currentPath.hasOwnProperty('prop')"
        try result.appendSlice(allocator, " && ");
        try result.appendSlice(allocator, current_path.items);
        try result.appendSlice(allocator, ".hasOwnProperty('");
        try result.appendSlice(allocator, prop);
        try result.appendSlice(allocator, "')");

        // Update current path: currentPath.prop
        try current_path.append(allocator, '.');
        try current_path.appendSlice(allocator, prop);
    }

    // Add ternary operator
    try result.appendSlice(allocator, " ? ");

    // Add the full path as the value
    try result.appendSlice(allocator, current_path.items);

    // Add default value (empty array)
    try result.appendSlice(allocator, " : []");

    return try result.toOwnedSlice(allocator);
}

// Tests
test "optional chaining - simple case" {
    const allocator = std.testing.allocator;

    const input = "item?.tags";
    const result = try transformOptionalChaining(allocator, input);
    defer allocator.free(result);

    const expected = "item && item.hasOwnProperty('tags') ? item.tags : []";
    try std.testing.expectEqualStrings(expected, result);
}

test "optional chaining - nested case" {
    const allocator = std.testing.allocator;

    const input = "obj?.prop?.nested";
    const result = try transformOptionalChaining(allocator, input);
    defer allocator.free(result);

    const expected = "obj && obj.hasOwnProperty('prop') && obj.prop.hasOwnProperty('nested') ? obj.prop.nested : []";
    try std.testing.expectEqualStrings(expected, result);
}

test "optional chaining - no operator" {
    const allocator = std.testing.allocator;

    const input = "items";
    const result = try transformOptionalChaining(allocator, input);
    defer allocator.free(result);

    try std.testing.expectEqualStrings("items", result);
}

test "optional chaining - with regular dot" {
    const allocator = std.testing.allocator;

    const input = "obj.items";
    const result = try transformOptionalChaining(allocator, input);
    defer allocator.free(result);

    // Should return unchanged since no "?." present
    try std.testing.expectEqualStrings("obj.items", result);
}

test "optional chaining - three levels" {
    const allocator = std.testing.allocator;

    const input = "a?.b?.c?.d";
    const result = try transformOptionalChaining(allocator, input);
    defer allocator.free(result);

    const expected = "a && a.hasOwnProperty('b') && a.b.hasOwnProperty('c') && a.b.c.hasOwnProperty('d') ? a.b.c.d : []";
    try std.testing.expectEqualStrings(expected, result);
}
