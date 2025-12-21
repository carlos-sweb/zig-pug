const std = @import("std");

pub fn isDigit(ch: u8) bool {
    return ch >= '0' and ch <= '9';
}

pub fn isAlpha(ch: u8) bool {
    return (ch >= 'a' and ch <= 'z') or (ch >= 'A' and ch <= 'Z');
}
pub fn isAlphanumeric(ch: u8) bool {
    return isAlpha(ch) or isDigit(ch);
}

pub fn main() !void {
    const input: []const u8 = "      div#main.class1.class2(some-attr='aaa')\n";
    var i: usize = 0;
    sw: switch (input[i]) {
        ' ' => {
            const start: usize = i;
            while (i < input.len and input[i] == ' ') {
                i += 1;
            }
            std.debug.print("Largo Sangria => {d}\n", .{input[start..i].len});
            continue :sw input[i];
        },
        'a'...'z' => {
            const start: usize = i;
            while (i < input.len and isAlpha(input[i])) {
                i += 1;
            }
            std.debug.print("{s}\n", .{input[start..i]});
            continue :sw input[i];
        },
        '#' => {
            i += 1;
            const start: usize = i;
            while (i < input.len and isAlpha(input[i])) {
                i += 1;
            }
            std.debug.print("id=>{s}\n", .{input[start..i]});
            continue :sw input[i];
        },
        '.' => {
            i += 1;
            const start: usize = i;
            while (i < input.len and isAlphanumeric(input[i])) {
                i += 1;
            }
            std.debug.print("class=>{s}\n", .{input[start..i]});
            continue :sw input[i];
        },
        '\n' => {
            break :sw;
        },
        else => {
            i += 1;
            continue :sw input[i];
        },
    }

    std.debug.print("{s}\n", .{input});
    std.debug.print("{d}\n", .{input.len});
    std.debug.print("{d}\n", .{i});
}
