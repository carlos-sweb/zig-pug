/**
 * Basic zig-pug C API Example
 *
 * Demonstrates:
 * - Initializing context
 * - Setting variables
 * - Compiling templates
 * - Memory management
 */

#include <stdio.h>
#include <stdlib.h>
#include <zigpug.h>

int main(void) {
    // Initialize zig-pug context
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "Failed to initialize zig-pug\n");
        return 1;
    }

    // Set variables
    zigpug_set_string(ctx, "name", "World");
    zigpug_set_int(ctx, "year", 2025);
    zigpug_set_bool(ctx, "isDev", false);

    // Simple template
    const char* template1 = "p Hello #{name}!";
    char* html1 = zigpug_compile(ctx, template1);
    if (html1) {
        printf("Example 1:\n%s\n\n", html1);
        zigpug_free_string(html1);
    }

    // Template with multiple variables
    const char* template2 =
        "doctype html\n"
        "html\n"
        "  head\n"
        "    title Welcome\n"
        "  body\n"
        "    h1 Hello #{name}!\n"
        "    p Year: #{year}\n"
        "    p Mode: #{isDev ? 'Development' : 'Production'}";

    char* html2 = zigpug_compile(ctx, template2);
    if (html2) {
        printf("Example 2:\n%s\n\n", html2);
        zigpug_free_string(html2);
    }

    // Template with conditional
    zigpug_set_bool(ctx, "loggedIn", true);
    const char* template3 =
        "div.container\n"
        "  if loggedIn\n"
        "    p Welcome back, #{name}!\n"
        "    button.logout Logout\n"
        "  else\n"
        "    p Please log in\n"
        "    button.login Login";

    char* html3 = zigpug_compile(ctx, template3);
    if (html3) {
        printf("Example 3:\n%s\n\n", html3);
        zigpug_free_string(html3);
    }

    // Cleanup
    zigpug_free(ctx);

    printf("zig-pug version: %s\n", zigpug_version());
    return 0;
}
