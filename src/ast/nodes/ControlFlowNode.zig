//! Control Flow Nodes
//!
//! Represents conditional statements, loops, and case/when constructs.

const std = @import("std");
const AstNode = @import("../AstNode.zig").AstNode;

/// Conditional node for if/else/unless
///
/// Represents conditional branching in templates.
///
/// Fields:
/// - condition: JavaScript expression to evaluate
/// - then_branch: Nodes to execute if condition is true (or false for unless)
/// - else_branch: Optional nodes to execute if condition is false (or true for unless)
/// - is_unless: If true, inverts the condition logic
///
/// Examples:
/// ```zpug
/// if loggedIn              // {condition="loggedIn", is_unless=false}
///   p Welcome!
/// else
///   p Please log in
///
/// unless guest             // {condition="guest", is_unless=true}
///   p Admin panel
/// ```
pub const ConditionalNode = struct {
    condition: []const u8,
    then_branch: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_unless: bool,
};

/// Loop node for each/while
///
/// Represents iteration over arrays or while conditions.
///
/// Fields:
/// - iterator: Variable name for current item (e.g., "item")
/// - index: Optional variable name for current index (e.g., "i")
/// - iterable: Expression evaluating to array or condition
/// - body: Nodes to execute for each iteration
/// - else_branch: Optional nodes to execute if array is empty
/// - is_while: If true, while loop; if false, each loop
///
/// Examples:
/// ```zpug
/// each item in items       // {iterator="item", iterable="items", is_while=false}
///   li= item
///
/// each item, i in items    // {iterator="item", index="i", iterable="items"}
///   li #{i}: #{item}
///
/// while hasMore            // {iterator="", iterable="hasMore", is_while=true}
///   p Loading...
/// ```
pub const LoopNode = struct {
    iterator: []const u8,
    index: ?[]const u8,
    iterable: []const u8,
    body: std.ArrayListUnmanaged(*AstNode),
    else_branch: ?std.ArrayListUnmanaged(*AstNode),
    is_while: bool,
};

/// Case node for case/when statements
///
/// Represents switch-like case matching.
///
/// Fields:
/// - expression: JavaScript expression to evaluate and match against
/// - cases: List of when clause nodes
/// - default: Optional default clause if no cases match
///
/// Example:
/// ```zpug
/// case color
///   when 'red'
///     p Red color
///   when 'blue'
///     p Blue color
///   default
///     p Unknown color
/// ```
pub const CaseNode = struct {
    expression: []const u8,
    cases: std.ArrayListUnmanaged(*AstNode), // WhenNodes
    default: ?std.ArrayListUnmanaged(*AstNode),
};

/// When clause for case statements
///
/// Represents a single case clause within a case statement.
///
/// Fields:
/// - values: List of values to match against (as strings)
/// - body: Nodes to execute if this clause matches
///
/// Example:
/// ```zpug
/// when 'red', 'crimson'    // {values=["red", "crimson"]}
///   p Red-ish color
/// ```
pub const WhenNode = struct {
    values: std.ArrayListUnmanaged([]const u8),
    body: std.ArrayListUnmanaged(*AstNode),
};
