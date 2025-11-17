/**
 * Example: Using zig-pug from C
 *
 * Compile:
 *   gcc example.c -I../include -L../zig-out/lib -lzig-pug -o example
 *
 * Run:
 *   LD_LIBRARY_PATH=../zig-out/lib ./example
 */

#include <stdio.h>
#include <stdlib.h>
#include "zigpug.h"

int main(void) {
    // Initialize context
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "Failed to initialize zig-pug\n");
        return 1;
    }

    printf("zig-pug version: %s\n\n", zigpug_version());

    // Example 1: Simple template
    printf("=== Example 1: Simple Template ===\n");
    const char* template1 = "div.container Hello World";
    char* html1 = zigpug_compile(ctx, template1);
    if (html1) {
        printf("Input:  %s\n", template1);
        printf("Output: %s\n\n", html1);
        zigpug_free_string(html1);
    }

    // Example 2: Template with interpolation
    printf("=== Example 2: Interpolation ===\n");
    zigpug_set_string(ctx, "name", "John Doe");
    zigpug_set_int(ctx, "age", 30);

    const char* template2 = "p Hello #{name}!";
    char* html2 = zigpug_compile(ctx, template2);
    if (html2) {
        printf("Input:  %s\n", template2);
        printf("Output: %s\n\n", html2);
        zigpug_free_string(html2);
    }

    // Example 3: Conditional rendering
    printf("=== Example 3: Conditionals ===\n");
    zigpug_set_bool(ctx, "loggedIn", true);

    const char* template3 =
        "if loggedIn\n"
        "  p Welcome back!\n"
        "else\n"
        "  p Please log in";

    char* html3 = zigpug_compile(ctx, template3);
    if (html3) {
        printf("Input:\n%s\n", template3);
        printf("Output: %s\n\n", html3);
        zigpug_free_string(html3);
    }

    // Example 4: Mixin
    printf("=== Example 4: Mixins ===\n");
    const char* template4 =
        "mixin button\n"
        "  button.btn Click me!\n"
        "+button";

    char* html4 = zigpug_compile(ctx, template4);
    if (html4) {
        printf("Input:\n%s\n", template4);
        printf("Output: %s\n\n", html4);
        zigpug_free_string(html4);
    }

    // Cleanup
    zigpug_free(ctx);

    return 0;
}
