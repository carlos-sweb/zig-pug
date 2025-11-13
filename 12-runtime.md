# Paso 12: Runtime de Ejecución

## Objetivo
Implementar runtime para evaluar expresiones, condicionales, loops y código JavaScript.

---

## Tareas

### 12.1 Contexto de Ejecución

```zig
pub const Context = struct {
    allocator: std.mem.Allocator,
    data: std.StringHashMap(Value),
    parent: ?*Context,

    pub fn get(self: *Context, key: []const u8) ?Value {
        if (self.data.get(key)) |val| return val;
        if (self.parent) |p| return p.get(key);
        return null;
    }

    pub fn set(self: *Context, key: []const u8, value: Value) !void {
        try self.data.put(key, value);
    }

    pub fn pushScope(self: *Context) !*Context {
        var child = try self.allocator.create(Context);
        child.* = Context.init(self.allocator);
        child.parent = self;
        return child;
    }
};
```

### 12.2 Evaluador de Expresiones

```zig
pub fn evaluateExpr(expr: *ExprNode, context: *Context) !Value {
    return switch (expr.type) {
        .Literal => expr.data.Literal,
        .Variable => context.get(expr.data.Variable) orelse Value.Null,
        .Binary => try evaluateBinary(expr.data.Binary, context),
        .Call => try evaluateCall(expr.data.Call, context),
        // ...
    };
}
```

### 12.3 Ejecución de Condicionales

```zig
fn executeConditional(node: *ConditionalNode, context: *Context, compiler: *Compiler) !void {
    const condition = try evaluateExpr(node.condition, context);

    const should_execute = if (node.is_unless)
        !condition.toBoolean()
    else
        condition.toBoolean();

    if (should_execute) {
        for (node.then_branch.items) |child| {
            try compiler.compileNode(child, context);
        }
    } else if (node.else_branch) |else_branch| {
        for (else_branch.items) |child| {
            try compiler.compileNode(child, context);
        }
    }
}
```

### 12.4 Ejecución de Loops

```zig
fn executeLoop(node: *LoopNode, context: *Context, compiler: *Compiler) !void {
    const iterable = try evaluateExpr(node.iterable, context);

    var child_ctx = try context.pushScope();
    defer child_ctx.deinit();

    switch (iterable) {
        .Array => |arr| {
            if (arr.items.len == 0 and node.else_branch != null) {
                // Execute else branch
            } else {
                for (arr.items, 0..) |item, idx| {
                    try child_ctx.set(node.iterator, item);
                    if (node.index) |index_name| {
                        try child_ctx.set(index_name, Value{ .Integer = @intCast(idx) });
                    }
                    for (node.body.items) |child| {
                        try compiler.compileNode(child, child_ctx);
                    }
                }
            }
        },
        // ... otros casos ...
    }
}
```

### 12.5 Sistema de Mixins

```zig
pub const MixinRegistry = struct {
    mixins: std.StringHashMap(*MixinDefNode),

    pub fn register(self: *MixinRegistry, mixin: *MixinDefNode) !void {
        try self.mixins.put(mixin.name, mixin);
    }

    pub fn call(self: *MixinRegistry, call: *MixinCallNode, context: *Context) !void {
        const mixin = self.mixins.get(call.name) orelse return error.UndefinedMixin;
        // Bind arguments to parameters
        // Execute mixin body
    }
};
```

### 12.6 Sistema de Caching

```zig
pub const TemplateCache = struct {
    cache: std.StringHashMap(*AstNode),

    pub fn get(self: *TemplateCache, path: []const u8) ?*AstNode {
        return self.cache.get(path);
    }

    pub fn put(self: *TemplateCache, path: []const u8, ast: *AstNode) !void {
        try self.cache.put(path, ast);
    }
};
```

---

## Entregables
- Runtime completo y funcional
- Evaluación de expresiones
- Ejecución de control flow
- Sistema de caching

---

## Siguiente Paso
**13-comptime.md** para compilación en tiempo de compilación.
