/**
 * Arrays and Objects Example
 *
 * Demonstrates:
 * - Setting arrays from JSON
 * - Setting objects from JSON
 * - Using each loops
 * - Accessing object properties
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

    // Set array variable
    bool success = zigpug_set_array_json(ctx, "items", "[\"Apple\",\"Banana\",\"Orange\",\"Grape\"]");
    if (!success) {
        fprintf(stderr, "Failed to set array\n");
        zigpug_free(ctx);
        return 1;
    }

    // Set object variable
    success = zigpug_set_object_json(ctx, "user",
        "{\"name\":\"Alice\",\"age\":30,\"city\":\"San Francisco\",\"admin\":true}");
    if (!success) {
        fprintf(stderr, "Failed to set object\n");
        zigpug_free(ctx);
        return 1;
    }

    // Set array of numbers
    zigpug_set_array_json(ctx, "numbers", "[10,20,30,40,50]");

    // Template using arrays and objects
    const char* template =
        "div.container\n"
        "  section.user-info\n"
        "    h2 User Information\n"
        "    p Name: #{user.name}\n"
        "    p Age: #{user.age}\n"
        "    p City: #{user.city}\n"
        "    p Role: #{user.admin ? 'Admin' : 'User'}\n"
        "  section.fruits\n"
        "    h2 Fruits List\n"
        "    ul\n"
        "      each item in items\n"
        "        li= item\n"
        "  section.numbers\n"
        "    h2 Numbers (with index)\n"
        "    ul\n"
        "      each num, i in numbers\n"
        "        li Item #{i}: #{num}";

    char* html = zigpug_compile(ctx, template);
    if (html) {
        printf("Arrays and Objects:\n%s\n", html);
        zigpug_free_string(html);
    } else {
        fprintf(stderr, "Compilation failed\n");
    }

    zigpug_free(ctx);
    return 0;
}
