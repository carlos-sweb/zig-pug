# Paso 16: Sistema de Herencia de Templates

## Objetivo
Implementar herencia completa de templates con blocks, extends, append/prepend.

---

## Tareas

### 16.1 Sistema de Blocks

```zig
pub const BlockRegistry = struct {
    blocks: std.StringHashMap(Block),

    pub const Block = struct {
        name: []const u8,
        mode: BlockMode,
        nodes: std.ArrayList(*AstNode),
    };

    pub fn register(self: *BlockRegistry, block: Block) !void {
        try self.blocks.put(block.name, block);
    }

    pub fn resolve(self: *BlockRegistry, name: []const u8) ?Block {
        return self.blocks.get(name);
    }

    pub fn merge(self: *BlockRegistry, child: BlockRegistry) !void {
        var it = child.blocks.iterator();
        while (it.next()) |entry| {
            const existing = self.blocks.get(entry.key_ptr.*);
            if (existing) |parent_block| {
                // Merge según mode (replace/append/prepend)
                switch (entry.value_ptr.mode) {
                    .Replace => try self.blocks.put(entry.key_ptr.*, entry.value_ptr.*),
                    .Append => {
                        var merged = parent_block;
                        try merged.nodes.appendSlice(entry.value_ptr.nodes.items);
                        try self.blocks.put(entry.key_ptr.*, merged);
                    },
                    .Prepend => {
                        var merged = entry.value_ptr.*;
                        try merged.nodes.appendSlice(parent_block.nodes.items);
                        try self.blocks.put(entry.key_ptr.*, merged);
                    },
                }
            } else {
                try self.blocks.put(entry.key_ptr.*, entry.value_ptr.*);
            }
        }
    }
};
```

### 16.2 Resolución de Herencia

```zig
pub fn resolveInheritance(child_ast: *AstNode, parent_path: []const u8) !*AstNode {
    // 1. Parse parent template
    const parent_content = try loadFile(parent_path);
    var parent_parser = try Parser.init(allocator, parent_content);
    const parent_ast = try parent_parser.parse();

    // 2. Extract blocks from parent
    var parent_blocks = BlockRegistry.init(allocator);
    try extractBlocks(parent_ast, &parent_blocks);

    // 3. Extract blocks from child
    var child_blocks = BlockRegistry.init(allocator);
    try extractBlocks(child_ast, &child_blocks);

    // 4. Merge blocks
    try parent_blocks.merge(child_blocks);

    // 5. Replace blocks in parent AST
    try replaceBlocks(parent_ast, parent_blocks);

    return parent_ast;
}
```

### 16.3 Validación de Reglas

- Solo blocks y mixins en top-level de child templates
- No buffered comments en top-level
- Extends debe ser primera declaración

---

## Entregables
- Herencia de templates funcional
- Blocks con append/prepend
- Validación completa
- Tests exhaustivos

---

## Siguiente Paso
**17-cli-api.md** para CLI y API pública.
