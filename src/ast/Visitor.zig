//! AST Visitor Pattern
//!
//! Traversal generico del arbol AST usando el patron Visitor.
//!
//! Uso:
//!   const MyCtx = struct {
//!       fn visit(ctx: *anyopaque, node: *AstNode) anyerror!VisitAction {
//!           const self: *@This() = @ptrCast(@alignCast(ctx));
//!           _ = self;
//!           _ = node;
//!           return .Continue;
//!       }
//!   };
//!
//!   var ctx = MyCtx{};
//!   var visitor = Visitor{ .context = &ctx, .visitFn = MyCtx.visit };
//!   _ = try visitor.visit(root);

const std = @import("std");
const AstNode = @import("AstNode.zig").AstNode;

/// Accion que controla el traversal despues de visitar un nodo.
pub const VisitAction = enum {
    /// Continuar visitando hijos y hermanos normalmente.
    Continue,
    /// Visitar hermanos pero no bajar a los hijos de este nodo.
    SkipChildren,
    /// Detener el traversal completo inmediatamente.
    Stop,
};

/// Visitor generico — recorre el arbol AST en pre-order.
///
/// El campo `visitFn` es llamado antes de descender a los hijos.
/// El retorno `bool` indica si el traversal debe continuar (false = Stop).
pub const Visitor = struct {
    context: *anyopaque,
    visitFn: *const fn (ctx: *anyopaque, node: *AstNode) anyerror!VisitAction,

    /// Visita `node` y su subárbol.
    /// Retorna `false` si el traversal fue detenido con `.Stop`.
    pub fn visit(self: *Visitor, node: *AstNode) anyerror!bool {
        const action = try self.visitFn(self.context, node);

        switch (action) {
            .Stop        => return false,
            .SkipChildren => return true,
            .Continue    => {},
        }

        // Descender a hijos segun tipo de nodo
        switch (node.data) {
            .Document => |*doc| {
                for (doc.children.items) |child| {
                    if (!try self.visit(child)) return false;
                }
            },

            .Tag => |*tag| {
                for (tag.children.items) |child| {
                    if (!try self.visit(child)) return false;
                }
            },

            .Conditional => |*cond| {
                for (cond.then_branch.items) |child| {
                    if (!try self.visit(child)) return false;
                }
                if (cond.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        if (!try self.visit(child)) return false;
                    }
                }
            },

            .Loop => |*loop| {
                for (loop.body.items) |child| {
                    if (!try self.visit(child)) return false;
                }
                if (loop.else_branch) |*else_br| {
                    for (else_br.items) |child| {
                        if (!try self.visit(child)) return false;
                    }
                }
            },

            .MixinDef => |*mixin| {
                for (mixin.body.items) |child| {
                    if (!try self.visit(child)) return false;
                }
            },

            .MixinCall => |*call| {
                // Nota: call.attributes son Attribute structs, no AstNode.
                // El compiler los accede directamente via call.attributes.items.
                if (call.body) |*body| {
                    for (body.items) |child| {
                        if (!try self.visit(child)) return false;
                    }
                }
            },

            .Block => |*block| {
                for (block.body.items) |child| {
                    if (!try self.visit(child)) return false;
                }
            },

            .Case => |*case_node| {
                for (case_node.cases.items) |when_node| {
                    if (!try self.visit(when_node)) return false;
                }
                if (case_node.default) |*default| {
                    for (default.items) |child| {
                        if (!try self.visit(child)) return false;
                    }
                }
            },

            .When => |*when| {
                for (when.body.items) |child| {
                    if (!try self.visit(child)) return false;
                }
            },

            // Nodos hoja — sin hijos que visitar
            .Text, .Interpolation, .Code, .Comment, .Include, .Extends => {},
        }

        return true;
    }
};
