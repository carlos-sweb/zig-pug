================================================================================
ZIG-PUG CODEBASE ANALYSIS - PRIORITIZED ISSUES LIST
================================================================================

CRITICAL ISSUES (Blocks Core Functionality)
================================================================================

1. MULTIPLE CLASSES CREATE DUPLICATE ATTRIBUTES
   File: src/parser.zig
   Lines: 136-155 (parseTag function)
   Type: Bug
   Severity: CRITICAL
   ---
   Issue: div.box.highlight generates <div class="box" class="highlight">
          (invalid HTML with duplicate class attributes)
   
   Expected: <div class="box highlight">
   
   Fix: Concatenate classes with space instead of creating duplicate attributes
   Test Case: tests/cli/02-classes-ids.zpug lines 6-7

2. LOOP ITERATOR VARIABLE NOT PARSED
   File: src/parser.zig
   Lines: 641 (parseLoop function, marked with TODO)
   Type: Bug
   Severity: CRITICAL
   ---
   Issue: loop.iterator always set to "" (empty string)
          Loops cannot access variables: each item in items → item is undefined
   
   Expected: iterator="item", iterable="items"
   
   Fix: Parse expression to extract iterator before "in"/"of" keyword
   Test Case: tests/cli/06-loops.zpug

3. MIXIN ARGUMENTS NOT SUBSTITUTED IN BODY
   File: src/compiler.zig
   Lines: 590 (compileMixinCall function, marked with TODO)
   Type: Bug
   Severity: CRITICAL
   ---
   Issue: mixin greeting(name) + greeting("Alice") 
          renders <p>Hello undefined</p> instead of <p>Hello Alice</p>
   
   Expected: Parameter "name" should be set to "Alice" in runtime context
   
   Fix: Evaluate arguments and create variable assignments before compiling body
   Test Case: tests/cli/07-mixins.zpug

4. COMMENT CONTENT NOT ESCAPED (SECURITY)
   File: src/compiler.zig
   Lines: 333-341 (compileComment function)
   Type: Security Bug
   Severity: CRITICAL
   ---
   Issue: Comment: "foo --> <script>alert(1)</script> <!--"
          Renders as: <!-- foo --> <script>alert(1)</script> <!---->
          Script tag breaks out of comment!
   
   Expected: Comment content should escape or sanitize --> sequences
   
   Fix: Replace --> with - -> or similar sanitization
   Impact: XSS vulnerability - user input in comments can execute code


HIGH PRIORITY ISSUES (Major Features Not Working)
================================================================================

5. TEST CONFIGURATION POINTS TO WRONG FILE
   File: build.zig
   Lines: 180-186
   Type: Build Issue
   Severity: HIGH
   ---
   Issue: Test root is "src/main.zig" (demo/CLI file)
          All actual tests in compiler.zig, parser.zig, etc. aren't run
          "zig build test" only runs 1 basic test, missing 50+ tests
   
   Expected: Test harness should include all source modules
   
   Fix: Create src/test.zig that imports all modules, point build.zig to it
   Impact: Tests not being validated

6. BLOCK MODES (APPEND/PREPEND) NOT IMPLEMENTED
   File: src/compiler.zig
   Lines: 170-185 (compileBlock function)
   Type: Feature Gap
   Severity: HIGH
   ---
   Issue: Parser supports "block append" and "block prepend"
          but compiler ignores block.mode field, always uses Replace mode
   
   Expected: append mode → child content appended to parent
             prepend mode → child content prepended to parent
   
   Fix: Check block.mode enum and handle Append/Prepend cases
   Impact: Template inheritance (extends/block) broken for append/prepend

7. INCLUDE FILTERS NOT IMPLEMENTED
   File: src/compiler.zig
   Lines: 468-526 (compileInclude function)
   Type: Feature Gap
   Severity: HIGH
   ---
   Issue: Parser supports "include:markdown file.md"
          Compiler ignores filter field, always parses as .zpug
   
   Expected: Filter (markdown, html, stylus, etc.) preprocesses file content
   
   Fix: Check include.filter and apply appropriate transformation
   Impact: Include filters completely non-functional

8. ATTRIBUTE STRING CONCATENATION NOT SUPPORTED
   File: src/parser.zig
   Lines: 226-268 (parseAttributes function)
   Type: Feature Gap
   Severity: HIGH
   ---
   Issue: a(href="/user/" + userId) not supported
          Parser only supports literals, not expressions with operators
   
   Expected: Attributes support full JavaScript expressions
   
   Fix: Collect full JS expression as attribute value instead of single token
   Impact: Cannot use dynamic attribute concatenation


MEDIUM PRIORITY ISSUES (Quality/Correctness)
================================================================================

9. ATTRIBUTE VALUE ESCAPING MISSING FOR DYNAMIC VALUES
   File: src/compiler.zig
   Lines: 232-242 (compileAttributes function)
   Type: Security Bug
   Severity: MEDIUM
   ---
   Issue: a(title=userInput) where userInput='x" onclick="alert(1)'
          renders <a title="x" onclick="alert(1)">
   
   Expected: Attribute values should be HTML-escaped
   
   Fix: Apply HTML escaping to attribute values
   Impact: XSS vulnerability in dynamic attributes

10. LOOP ELSE CLAUSE NOT IMPLEMENTED
    File: src/parser.zig
    Lines: 608-649 (parseLoop function)
    Type: Feature Gap
    Severity: MEDIUM
    ---
    Issue: each item in items doesn't support else clause for empty arrays
    
    Expected: each item in items / else p No items
    
    Fix: Add else parsing after loop body
    Impact: Cannot fallback render when array is empty

11. CASE COMPARISON TYPE MISMATCH
    File: src/compiler.zig
    Lines: 532-568 (compileCase function)
    Type: Bug
    Severity: MEDIUM
    ---
    Issue: case 1 / when 1 fails because string "1" !== number 1
           String comparison with case_value.eql(u8, ...)
    
    Expected: Type-aware comparison
    
    Fix: Convert both sides to string or implement type coercion
    Impact: Case statements fail on type mismatches

12. LOOP INDEX VARIABLE NEVER SET
    File: src/compiler.zig
    Lines: 383-462 (compileLoop function)
    Type: Bug
    Severity: MEDIUM
    ---
    Issue: even if loop.index is provided, loop.iterator is empty
           so variable access impossible anyway
    
    Expected: each item, index in items → index accessible
    
    Fix: Dependent on fixing issue #2 (loop iterator parsing)
    Impact: Cannot access array indices

13. INDEX VARIABLE NOT PARSED BY PARSER
    File: src/parser.zig
    Lines: 608-649 (parseLoop function)
    Type: Feature Gap
    Severity: MEDIUM
    ---
    Issue: "each item, index in items" → index variable name never extracted
    
    Expected: loop.index = "index"
    
    Fix: Parse loop expression to extract both iterator and optional index
    Impact: Array index access not supported


ARCHITECTURAL ISSUES (Design Limitations)
================================================================================

14. NO TYPE SYSTEM FOR RUNTIME VALUES
    Severity: MEDIUM
    ---
    Issue: All JS values stringified for comparison
           case 1, when 1 fails (string "1" vs number 1)
           if 0 always truthy (non-empty string)
    
    Expected: Proper type coercion like JavaScript
    
    Fix: Maintain type info or implement JS type coercion rules
    Impact: Edge cases in conditionals and case statements

15. MIXIN SCOPE ISOLATION MISSING
    File: src/compiler.zig
    Lines: 579-595 (compileMixinCall function)
    Severity: MEDIUM
    ---
    Issue: Mixin parameters pollute global runtime context
           Multiple mixin calls can have variable name conflicts
    
    Expected: Each mixin call should have isolated scope
    
    Fix: Create function-like scope wrapper for mixin compilation
    Impact: Variable collision bugs in templates with multiple mixins


SUMMARY BY SEVERITY
================================================================================

CRITICAL (4 issues - blocks core functionality):
  1. Multiple classes → duplicate attributes (parser.zig:136-155)
  2. Loop iterator not parsed (parser.zig:641)
  3. Mixin args not substituted (compiler.zig:590)
  4. Comment content not escaped (compiler.zig:333-341) [SECURITY]

HIGH (4 issues - major features not working):
  5. Test config wrong (build.zig:180-186)
  6. Block modes not implemented (compiler.zig:170-185)
  7. Include filters not implemented (compiler.zig:468-526)
  8. Attribute concatenation missing (parser.zig:226-268)

MEDIUM (6 issues - quality/correctness):
  9. Attribute escaping missing (compiler.zig:232-242) [SECURITY]
  10. Loop else missing (parser.zig:608-649)
  11. Case type mismatch (compiler.zig:532-568)
  12. Loop index not set (compiler.zig:383-462)
  13. Index variable not parsed (parser.zig:608-649)
  14. No type system (design issue)
  15. Mixin scope isolation (design issue)


RECOMMENDED FIX ORDER
================================================================================

Phase 1 - CRITICAL (Fix core functionality):
  1. src/parser.zig:136-155   → Multiple classes concatenation
  2. src/parser.zig:641       → Loop iterator parsing
  3. src/compiler.zig:590     → Mixin argument substitution
  4. src/compiler.zig:333-341 → Comment escaping (security)

Phase 2 - HIGH PRIORITY:
  5. build.zig:180-186        → Test configuration
  6. src/compiler.zig:170-185 → Block modes implementation
  7. src/compiler.zig:232-242 → Attribute value escaping
  8. src/compiler.zig:468-526 → Include filters

Phase 3 - MEDIUM PRIORITY:
  9. src/compiler.zig:532-568 → Case type comparison
  10. src/parser.zig:608-649  → Loop else clause
  11. Design improvements      → Type system, scope isolation

================================================================================
