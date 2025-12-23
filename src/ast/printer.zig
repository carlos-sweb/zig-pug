//! AST Pretty Printer
//!
//! Debug utility for printing AST trees in a readable format.

const std = @import("std");
const AstNode = @import("AstNode.zig").AstNode;

/// Print indentation spaces
fn printIndent(indent: usize) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        std.debug.print("  ", .{});
    }
}

/// Pretty-print an AST node and its children
///
/// Recursively prints the AST tree structure with indentation
/// for debugging and visualization.
///
/// Parameters:
/// - node: AST node to print
/// - indent: Current indentation level (0 for root)
///
/// Example:
/// ```zig
/// printAst(root_node, 0);
/// // Output:
/// // Document (line 1)
/// //   Tag (line 1)
/// //     name: div
/// //     Tag (line 2)
/// //       name: p
/// //       Text (line 2)
/// //         content: "Hello"
/// ```
pub fn printAst(node: *AstNode, indent: usize) void {
    printIndent(indent);
    std.debug.print("{s} (line {d})\n", .{ @tagName(node.type), node.line });

    switch (node.data) {
        .Document => |*doc| {
            for (doc.children.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Tag => |*tag| {
            printIndent(indent + 1);
            std.debug.print("name: {s}\n", .{tag.name});

            // Print attributes if any
            if (tag.attributes.items.len > 0) {
                printIndent(indent + 1);
                std.debug.print("attributes:\n", .{});
                for (tag.attributes.items) |attr| {
                    printIndent(indent + 2);
                    if (attr.value) |val| {
                        std.debug.print("{s}=\"{s}\"\n", .{ attr.name, val });
                    } else {
                        std.debug.print("{s} (boolean)\n", .{attr.name});
                    }
                }
            }

            for (tag.children.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Text => |*text| {
            printIndent(indent + 1);
            std.debug.print("content: \"{s}\"\n", .{text.content});
        },
        .Interpolation => |*interp| {
            printIndent(indent + 1);
            std.debug.print("expr: {s}, unescaped: {}\n", .{ interp.expression, interp.is_unescaped });
        },
        .Code => |*code| {
            printIndent(indent + 1);
            std.debug.print("code: {s}\n", .{code.code});
        },
        .Comment => |*comment| {
            printIndent(indent + 1);
            std.debug.print("comment: {s}\n", .{comment.content});
        },
        .Conditional => |*cond| {
            printIndent(indent + 1);
            std.debug.print("condition: {s}\n", .{cond.condition});
            for (cond.then_branch.items) |child| {
                printAst(child, indent + 1);
            }
            if (cond.else_branch) |*else_br| {
                printIndent(indent + 1);
                std.debug.print("else:\n", .{});
                for (else_br.items) |child| {
                    printAst(child, indent + 1);
                }
            }
        },
        .Loop => |*loop| {
            printIndent(indent + 1);
            std.debug.print("iterator: {s}, iterable: {s}\n", .{ loop.iterator, loop.iterable });
            for (loop.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .MixinDef => |*mixin| {
            printIndent(indent + 1);
            std.debug.print("name: {s}, params: {d}\n", .{ mixin.name, mixin.params.items.len });
            if (mixin.rest_param) |rest| {
                printIndent(indent + 1);
                std.debug.print("rest: ...{s}\n", .{rest});
            }
            for (mixin.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .MixinCall => |*call| {
            printIndent(indent + 1);
            std.debug.print("name: {s}, args: {d}\n", .{ call.name, call.args.items.len });
            if (call.body) |*body| {
                for (body.items) |child| {
                    printAst(child, indent + 1);
                }
            }
        },
        .Include => |*inc| {
            printIndent(indent + 1);
            std.debug.print("path: {s}\n", .{inc.path});
            if (inc.filter) |filter| {
                printIndent(indent + 1);
                std.debug.print("filter: {s}\n", .{filter});
            }
        },
        .Extends => |*ext| {
            printIndent(indent + 1);
            std.debug.print("path: {s}\n", .{ext.path});
        },
        .Block => |*block| {
            printIndent(indent + 1);
            std.debug.print("name: {s}, mode: {s}\n", .{ block.name, @tagName(block.mode) });
            for (block.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
        .Case => |*case_node| {
            printIndent(indent + 1);
            std.debug.print("expression: {s}\n", .{case_node.expression});
            for (case_node.cases.items) |when_node| {
                printAst(when_node, indent + 1);
            }
            if (case_node.default) |*default| {
                printIndent(indent + 1);
                std.debug.print("default:\n", .{});
                for (default.items) |child| {
                    printAst(child, indent + 2);
                }
            }
        },
        .When => |*when| {
            printIndent(indent + 1);
            std.debug.print("values: {d}\n", .{when.values.items.len});
            for (when.body.items) |child| {
                printAst(child, indent + 1);
            }
        },
    }
}
