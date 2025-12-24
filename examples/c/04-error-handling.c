/**
 * Error Handling Example
 *
 * Demonstrates:
 * - Detecting compilation errors
 * - Getting error count
 * - Iterating through errors
 * - Accessing error details (line, message, detail, hint)
 */

#include <stdio.h>
#include <stdlib.h>
#include <zigpug.h>

void compile_and_handle_errors(ZigPugContext* ctx, const char* template, const char* description) {
    printf("\n=== %s ===\n", description);
    printf("Template:\n%s\n\n", template);

    char* html = zigpug_compile(ctx, template);

    if (html) {
        printf("Success! HTML output:\n%s\n", html);
        zigpug_free_string(html);
    } else {
        printf("Compilation failed!\n");

        size_t error_count = zigpug_get_error_count(ctx);
        printf("Found %zu error(s):\n\n", error_count);

        for (size_t i = 0; i < error_count; i++) {
            size_t line;
            const char* message;
            const char* detail;
            const char* hint;

            if (zigpug_get_error(ctx, i, &line, &message, &detail, &hint)) {
                printf("Error #%zu:\n", i + 1);
                printf("  Line: %zu\n", line);
                printf("  Message: %s\n", message);

                if (detail) {
                    printf("  Detail: %s\n", detail);
                }

                if (hint) {
                    printf("  Hint: %s\n", hint);
                }

                printf("\n");
            }
        }
    }
}

int main(void) {
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "Failed to initialize zig-pug\n");
        return 1;
    }

    // Example 1: Valid template
    compile_and_handle_errors(ctx,
        "p Hello World",
        "Valid Template");

    // Example 2: Using undefined variable
    compile_and_handle_errors(ctx,
        "p Hello #{undefinedVar}",
        "Undefined Variable");

    // Example 3: Invalid loop syntax
    zigpug_set_string(ctx, "items", "not an array");
    compile_and_handle_errors(ctx,
        "each item in items\n  li= item",
        "Invalid Loop Iterable");

    // Example 4: Valid template with variables
    zigpug_set_string(ctx, "name", "Alice");
    zigpug_set_int(ctx, "age", 25);
    compile_and_handle_errors(ctx,
        "div\n  p Name: #{name}\n  p Age: #{age}",
        "Valid Template with Variables");

    zigpug_free(ctx);
    return 0;
}
