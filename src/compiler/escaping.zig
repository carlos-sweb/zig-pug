//! HTML and Comment Escaping
//!
//! Utilities for escaping HTML special characters and comment content
//! to prevent XSS attacks and injection vulnerabilities.

const std = @import("std");

/// Escape HTML special characters to prevent XSS attacks
///
/// Optimized version that pre-calculates size to avoid reallocations.
/// Escapes: &, <, >, ", '
///
/// Parameters:
/// - allocator: Memory allocator
/// - input: String to escape
///
/// Returns: Escaped string (caller owns memory)
///
/// Example:
/// ```zig
/// const escaped = try escapeHtml(allocator, "<script>alert('xss')</script>");
/// defer allocator.free(escaped);
/// // Result: "&lt;script&gt;alert(&#39;xss&#39;)&lt;/script&gt;"
/// ```
pub fn escapeHtml(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
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
        return try allocator.dupe(u8, input);
    }

    // Allocate exact size needed (no reallocations)
    var result: std.ArrayList(u8) = .empty;
    errdefer result.deinit(allocator);
    try result.ensureTotalCapacity(allocator, final_size);

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

    return try result.toOwnedSlice(allocator);
}

/// Escape HTML comment content to prevent XSS/injection attacks
///
/// Replaces "--" with "- -" to prevent premature comment closing
/// which could lead to injection vulnerabilities.
///
/// Parameters:
/// - allocator: Memory allocator
/// - input: Comment content to escape
///
/// Returns: Escaped comment (caller owns memory)
///
/// Example:
/// ```zig
/// const escaped = try escapeComment(allocator, "Comment with --> dangerous");
/// defer allocator.free(escaped);
/// // Result: "Comment with - -> dangerous"
/// ```
pub fn escapeComment(allocator: std.mem.Allocator, input: []const u8) ![]const u8 {
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
        return try allocator.dupe(u8, input);
    }

    // Escape "--" sequences
    var result: std.ArrayList(u8) = .empty;
    errdefer result.deinit(allocator);

    i = 0;
    while (i < input.len) {
        if (i + 1 < input.len and input[i] == '-' and input[i + 1] == '-') {
            try result.appendSlice(allocator, "- -");
            i += 2;
        } else {
            try result.append(allocator, input[i]);
            i += 1;
        }
    }

    return try result.toOwnedSlice(allocator);
}
