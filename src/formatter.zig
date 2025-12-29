// HTML Formatting Utilities
// Common module used by both CLI and library API

const std = @import("std");

/// Check if a tag name is a void element (self-closing HTML element)
pub fn isVoidElement(tag_name: []const u8) bool {
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

/// Pretty-print HTML with indentation
/// This is the canonical implementation used by both CLI and API
pub fn prettyPrintHtml(allocator: std.mem.Allocator, html: []const u8) ![]const u8 {
    var result = std.ArrayList(u8){};
    var indent: usize = 0;
    var i: usize = 0;

    while (i < html.len) {
        if (html[i] == '<') {
            // Check if it's a comment
            const is_comment = i + 3 < html.len and
                html[i + 1] == '!' and
                html[i + 2] == '-' and
                html[i + 3] == '-';

            // Check if it's DOCTYPE declaration (e.g., <!DOCTYPE html>)
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

            // Extract tag name to check if it's a void element
            const tag_name = blk: {
                if (is_closing or is_comment or is_doctype) break :blk "";

                var j = i + 1;
                // Skip whitespace after '<'
                while (j < html.len and html[j] == ' ') : (j += 1) {}

                const start = j;
                // Read tag name until space, '>', or '/'
                while (j < html.len and html[j] != ' ' and html[j] != '>' and html[j] != '/') : (j += 1) {}

                if (j > start) {
                    break :blk html[start..j];
                }
                break :blk "";
            };

            // Check if self-closing (either ends with /> or is a void element)
            const is_self_closing = blk: {
                var j = i;
                while (j < html.len and html[j] != '>') : (j += 1) {}
                const ends_with_slash = j > 0 and html[j - 1] == '/';
                const is_void = isVoidElement(tag_name);
                break :blk ends_with_slash or is_void;
            };

            // For closing tags: check if content before it is only text (no nested tags)
            const closing_has_only_text = blk: {
                if (!is_closing) break :blk false;

                // Look backwards to find the last '>' and check if:
                // 1. There's no '<' between that '>' and current position (no nested tags)
                // 2. The '>' belongs to an opening tag, not a closing tag like </p>
                var idx: usize = result.items.len;

                // Skip any whitespace/newlines at the end
                while (idx > 0 and (result.items[idx - 1] == ' ' or result.items[idx - 1] == '\n')) {
                    idx -= 1;
                }

                // Now look for '>' and check there's no '<' before it
                while (idx > 0) {
                    idx -= 1;
                    const c = result.items[idx];

                    if (c == '<') {
                        // Found a '<' before finding '>', means there are nested tags
                        break :blk false;
                    }

                    if (c == '>') {
                        // Found '>'. Now we need to find its corresponding '<' to check if it's a closing tag
                        // Look backwards from '>' to find '<'
                        var tag_start_idx = idx;
                        while (tag_start_idx > 0 and result.items[tag_start_idx] != '<') {
                            tag_start_idx -= 1;
                        }

                        // Check if this is a closing tag: the char after '<' should be '/'
                        if (tag_start_idx + 1 < result.items.len and result.items[tag_start_idx + 1] == '/') {
                            // This is a closing tag like </p>, so there are nested tags
                            break :blk false;
                        }

                        // This is an opening tag, and no '<' between it and current position
                        // So we have only text content
                        break :blk true;
                    }
                }

                break :blk false;
            };

            if (is_closing and indent > 0) {
                indent -= 1;
            }

            // Add indentation (newline + spaces)
            // Skip newline for: closing tags with only text, or the very first tag
            if (!closing_has_only_text and result.items.len > 0) {
                try result.append(allocator, '\n');
                var j: usize = 0;
                while (j < indent * 2) : (j += 1) {
                    try result.append(allocator, ' ');
                }
            }

            // Add tag
            while (i < html.len and html[i] != '>') : (i += 1) {
                try result.append(allocator, html[i]);
            }
            if (i < html.len) {
                try result.append(allocator, html[i]); // Add '>'
                i += 1;
            }

            // Don't increase indent for comments, doctype, or self-closing tags
            if (!is_closing and !is_self_closing and !is_comment and !is_doctype) {
                indent += 1;
            }
        } else {
            try result.append(allocator, html[i]);
            i += 1;
        }
    }

    try result.append(allocator, '\n');
    return result.toOwnedSlice(allocator);
}

/// Minify HTML by removing unnecessary whitespace
pub fn minifyHtml(allocator: std.mem.Allocator, html: []const u8) ![]const u8 {
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
