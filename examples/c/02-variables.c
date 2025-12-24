/**
 * Variables Example
 *
 * Demonstrates all variable types:
 * - Strings
 * - Integers
 * - Booleans
 * - String interpolation
 * - JavaScript expressions
 */

#include <stdio.h>
#include <stdlib.h>
#include <zigpug.h>

int main(void) {
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "Failed to initialize zig-pug\n");
        return 1;
    }

    // Set different types of variables
    zigpug_set_string(ctx, "username", "Carlos");
    zigpug_set_string(ctx, "email", "carlos@example.com");
    zigpug_set_int(ctx, "age", 28);
    zigpug_set_int(ctx, "score", 1250);
    zigpug_set_bool(ctx, "admin", true);
    zigpug_set_bool(ctx, "verified", false);

    // Template using all variable types
    const char* template =
        "div.user-profile\n"
        "  h1= username\n"
        "  p.email Email: #{email}\n"
        "  p.age Age: #{age}\n"
        "  p.score Score: #{score}\n"
        "  p.status Status: #{admin ? 'Administrator' : 'User'}\n"
        "  p.verified #{verified ? '✓ Verified' : '✗ Not Verified'}\n"
        "  p.adult #{age >= 18 ? 'Adult' : 'Minor'}\n"
        "  p.high-score #{score > 1000 ? 'High Score!' : 'Keep trying'}";

    char* html = zigpug_compile(ctx, template);
    if (html) {
        printf("User Profile:\n%s\n", html);
        zigpug_free_string(html);
    } else {
        fprintf(stderr, "Compilation failed\n");
    }

    zigpug_free(ctx);
    return 0;
}
