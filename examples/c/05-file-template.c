/**
 * File Template Example
 *
 * Demonstrates:
 * - Reading templates from files
 * - Compiling file-based templates
 * - Error handling with file I/O
 */

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <zigpug.h>

// Read entire file into a string
// Returns allocated string (must be freed) or NULL on error
char* read_file(const char* filename) {
    FILE* file = fopen(filename, "rb");
    if (!file) {
        return NULL;
    }

    // Get file size
    fseek(file, 0, SEEK_END);
    long size = ftell(file);
    fseek(file, 0, SEEK_SET);

    // Allocate buffer (+1 for null terminator)
    char* buffer = (char*)malloc(size + 1);
    if (!buffer) {
        fclose(file);
        return NULL;
    }

    // Read file
    size_t read_size = fread(buffer, 1, size, file);
    buffer[read_size] = '\0';

    fclose(file);
    return buffer;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        printf("Usage: %s <template.pug>\n", argv[0]);
        printf("\nExample:\n");
        printf("  echo 'p Hello #{name}' > template.pug\n");
        printf("  %s template.pug\n", argv[0]);
        return 1;
    }

    const char* filename = argv[1];

    // Read template file
    char* template = read_file(filename);
    if (!template) {
        fprintf(stderr, "Error: Could not read file '%s'\n", filename);
        return 1;
    }

    printf("Template from '%s':\n%s\n\n", filename, template);

    // Initialize zig-pug
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        fprintf(stderr, "Failed to initialize zig-pug\n");
        free(template);
        return 1;
    }

    // Set some variables
    zigpug_set_string(ctx, "name", "Carlos");
    zigpug_set_string(ctx, "title", "File Template Example");
    zigpug_set_int(ctx, "year", 2025);
    zigpug_set_bool(ctx, "production", true);

    // Compile template
    char* html = zigpug_compile(ctx, template);

    if (html) {
        printf("HTML output:\n%s\n", html);
        zigpug_free_string(html);
    } else {
        fprintf(stderr, "Compilation failed!\n");

        size_t error_count = zigpug_get_error_count(ctx);
        for (size_t i = 0; i < error_count; i++) {
            size_t line;
            const char* message;
            const char* detail;
            const char* hint;

            if (zigpug_get_error(ctx, i, &line, &message, &detail, &hint)) {
                fprintf(stderr, "Error at line %zu: %s\n", line, message);
                if (detail) fprintf(stderr, "  Detail: %s\n", detail);
                if (hint) fprintf(stderr, "  Hint: %s\n", hint);
            }
        }
    }

    // Cleanup
    free(template);
    zigpug_free(ctx);

    return 0;
}
