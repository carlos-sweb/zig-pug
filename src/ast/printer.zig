//! AST Pretty Printer
//!
//! Debug utility para imprimir el árbol AST en formato indentado legible.
//! Usa std.debug.print — compatible con Zig 0.16.
//!
//! Uso:
//!   ast.printAst(root, 0);
//!   ast.printAstDebug(root, 0); // alias

const std = @import("std");
const AstNode = @import("AstNode.zig").AstNode;

fn writeIndent(indent: usize) void {
    var i: usize = 0;
    while (i < indent) : (i += 1) {
        std.debug.print("  ", .{});
    }
}

pub fn printAst(node: *AstNode, indent: usize) void {
    writeIndent(indent);
    std.debug.print("{s} (line {d}, col {d})\n", .{
        @tagName(node.type), node.line, node.column,
    });

    switch (node.data) {
        .Document => |*doc| {
            writeIndent(indent + 1);
            if (doc.doctype) |dt| {
                std.debug.print("doctype: {s}\n", .{dt});
            } else {
                std.debug.print("doctype: (none)\n", .{});
            }
            for (doc.children.items) |child| printAst(child, indent + 1);
        },

        .Tag => |*tag| {
            writeIndent(indent + 1);
            std.debug.print("name: {s}\n", .{tag.name});
            writeIndent(indent + 1);
            std.debug.print("self_closing: {}\n", .{tag.is_self_closing});
            writeIndent(indent + 1);
            if (tag.attributes.items.len > 0) {
                std.debug.print("attributes:\n", .{});
                for (tag.attributes.items) |attr| {
                    writeIndent(indent + 2);
                    if (attr.value) |val| {
                        const op: []const u8 = if (attr.is_unescaped) "!=" else "=";
                        const kind: []const u8 = if (attr.is_expression) " (expr)" else "";
                        std.debug.print("{s}{s}\"{s}\"{s}\n", .{ attr.name, op, val, kind });
                    } else {
                        std.debug.print("{s} (boolean)\n", .{attr.name});
                    }
                }
            } else {
                std.debug.print("attributes: (none)\n", .{});
            }
            for (tag.children.items) |child| printAst(child, indent + 1);
        },

        .Text => |*text| {
            writeIndent(indent + 1);
            std.debug.print("content: \"{s}\"\n", .{text.content});
            writeIndent(indent + 1);
            std.debug.print("raw: {}\n", .{text.is_raw});
        },

        .Interpolation => |*interp| {
            writeIndent(indent + 1);
            std.debug.print("expression: {s}\n", .{interp.expression});
            writeIndent(indent + 1);
            std.debug.print("unescaped: {}\n", .{interp.is_unescaped});
        },

        .Code => |*code| {
            writeIndent(indent + 1);
            std.debug.print("code: {s}\n", .{code.code});
            writeIndent(indent + 1);
            std.debug.print("buffered: {}\n", .{code.is_buffered});
            writeIndent(indent + 1);
            std.debug.print("unescaped: {}\n", .{code.is_unescaped});
        },

        .Comment => |*comment| {
            writeIndent(indent + 1);
            std.debug.print("content: {s}\n", .{comment.content});
            writeIndent(indent + 1);
            std.debug.print("buffered: {}\n", .{comment.is_buffered});
        },

        .Conditional => |*cond| {
            writeIndent(indent + 1);
            std.debug.print("condition: {s}\n", .{cond.condition});
            writeIndent(indent + 1);
            std.debug.print("unless: {}\n", .{cond.is_unless});
            writeIndent(indent + 1);
            std.debug.print("then:\n", .{});
            for (cond.then_branch.items) |child| printAst(child, indent + 2);
            writeIndent(indent + 1);
            if (cond.else_branch) |*else_br| {
                std.debug.print("else:\n", .{});
                for (else_br.items) |child| printAst(child, indent + 2);
            } else {
                std.debug.print("else: (none)\n", .{});
            }
        },

        .Loop => |*loop| {
            writeIndent(indent + 1);
            std.debug.print("while: {}\n", .{loop.is_while});
            writeIndent(indent + 1);
            std.debug.print("iterator: {s}\n", .{loop.iterator});
            writeIndent(indent + 1);
            if (loop.index) |idx| {
                std.debug.print("index: {s}\n", .{idx});
            } else {
                std.debug.print("index: (none)\n", .{});
            }
            writeIndent(indent + 1);
            std.debug.print("iterable: {s}\n", .{loop.iterable});
            writeIndent(indent + 1);
            std.debug.print("body:\n", .{});
            for (loop.body.items) |child| printAst(child, indent + 2);
            writeIndent(indent + 1);
            if (loop.else_branch) |*else_br| {
                std.debug.print("else:\n", .{});
                for (else_br.items) |child| printAst(child, indent + 2);
            } else {
                std.debug.print("else: (none)\n", .{});
            }
        },

        .MixinDef => |*mixin| {
            writeIndent(indent + 1);
            std.debug.print("name: {s}\n", .{mixin.name});
            writeIndent(indent + 1);
            if (mixin.params.items.len > 0) {
                std.debug.print("params:\n", .{});
                for (mixin.params.items) |param| {
                    writeIndent(indent + 2);
                    std.debug.print("- {s}\n", .{param});
                }
            } else {
                std.debug.print("params: (none)\n", .{});
            }
            writeIndent(indent + 1);
            if (mixin.rest_param) |rest| {
                std.debug.print("rest: ...{s}\n", .{rest});
            } else {
                std.debug.print("rest: (none)\n", .{});
            }
            for (mixin.body.items) |child| printAst(child, indent + 1);
        },

        .MixinCall => |*call| {
            writeIndent(indent + 1);
            std.debug.print("name: {s}\n", .{call.name});
            writeIndent(indent + 1);
            if (call.args.items.len > 0) {
                std.debug.print("args:\n", .{});
                for (call.args.items) |arg| {
                    writeIndent(indent + 2);
                    std.debug.print("- {s}\n", .{arg});
                }
            } else {
                std.debug.print("args: (none)\n", .{});
            }
            writeIndent(indent + 1);
            if (call.attributes.items.len > 0) {
                std.debug.print("attributes:\n", .{});
                for (call.attributes.items) |attr| {
                    writeIndent(indent + 2);
                    if (attr.value) |val| {
                        const op: []const u8 = if (attr.is_unescaped) "!=" else "=";
                        const kind: []const u8 = if (attr.is_expression) " (expr)" else "";
                        std.debug.print("{s}{s}\"{s}\"{s}\n", .{ attr.name, op, val, kind });
                    } else {
                        std.debug.print("{s} (boolean)\n", .{attr.name});
                    }
                }
            } else {
                std.debug.print("attributes: (none)\n", .{});
            }
            writeIndent(indent + 1);
            if (call.body) |*body| {
                std.debug.print("body:\n", .{});
                for (body.items) |child| printAst(child, indent + 2);
            } else {
                std.debug.print("body: (none)\n", .{});
            }
        },

        .Include => |*inc| {
            writeIndent(indent + 1);
            std.debug.print("path: {s}\n", .{inc.path});
            writeIndent(indent + 1);
            if (inc.filter) |filter| {
                std.debug.print("filter: {s}\n", .{filter});
            } else {
                std.debug.print("filter: (none)\n", .{});
            }
        },

        .Extends => |*ext| {
            writeIndent(indent + 1);
            std.debug.print("path: {s}\n", .{ext.path});
        },

        .Block => |*block| {
            writeIndent(indent + 1);
            std.debug.print("name: {s}\n", .{block.name});
            writeIndent(indent + 1);
            std.debug.print("mode: {s}\n", .{@tagName(block.mode)});
            if (block.body.items.len > 0) {
                for (block.body.items) |child| printAst(child, indent + 1);
            } else {
                writeIndent(indent + 1);
                std.debug.print("body: (empty)\n", .{});
            }
        },

        .Case => |*case_node| {
            writeIndent(indent + 1);
            std.debug.print("expression: {s}\n", .{case_node.expression});
            for (case_node.cases.items) |when_node| printAst(when_node, indent + 1);
            writeIndent(indent + 1);
            if (case_node.default) |*default| {
                std.debug.print("default:\n", .{});
                for (default.items) |child| printAst(child, indent + 2);
            } else {
                std.debug.print("default: (none)\n", .{});
            }
        },

        .When => |*when| {
            writeIndent(indent + 1);
            if (when.values.items.len > 0) {
                std.debug.print("values:\n", .{});
                for (when.values.items) |val| {
                    writeIndent(indent + 2);
                    std.debug.print("- {s}\n", .{val});
                }
            } else {
                std.debug.print("values: (none)\n", .{});
            }
            for (when.body.items) |child| printAst(child, indent + 1);
        },
    }
}

pub fn printAstDebug(node: *AstNode, indent: usize) void {
    printAst(node, indent);
}
