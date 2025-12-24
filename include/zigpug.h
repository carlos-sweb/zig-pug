/**
 * zig-pug - Pug template engine written in Zig
 * C API Header
 *
 * This header provides a C-compatible interface for using zig-pug
 * from C, C++, Python (ctypes/cffi), Node.js (FFI), Rust (FFI), etc.
 */

#ifndef ZIGPUG_H
#define ZIGPUG_H

#include <stdint.h>
#include <stdbool.h>

#ifdef __cplusplus
extern "C" {
#endif

/**
 * Opaque context handle
 * Represents a zig-pug compilation context with runtime state
 */
typedef struct ZigPugContext ZigPugContext;

/**
 * Initialize a new zig-pug context
 *
 * @return Context handle, or NULL on error
 *
 * Example:
 *   ZigPugContext* ctx = zigpug_init();
 *   if (!ctx) {
 *       fprintf(stderr, "Failed to initialize zig-pug\n");
 *       return 1;
 *   }
 */
ZigPugContext* zigpug_init(void);

/**
 * Free a zig-pug context
 *
 * @param ctx Context handle (can be NULL)
 *
 * Example:
 *   zigpug_free(ctx);
 */
void zigpug_free(ZigPugContext* ctx);

/**
 * Compile a Pug template string to HTML
 *
 * @param ctx Context handle
 * @param pug_source Null-terminated Pug template string
 * @return Null-terminated HTML string (must be freed with zigpug_free_string),
 *         or NULL on error
 *
 * Example:
 *   const char* pug = "div.container\n  p Hello #{name}!";
 *   char* html = zigpug_compile(ctx, pug);
 *   if (html) {
 *       printf("%s\n", html);
 *       zigpug_free_string(html);
 *   }
 */
char* zigpug_compile(ZigPugContext* ctx, const char* pug_source);

/**
 * Set a string variable in the context
 *
 * @param ctx Context handle
 * @param key Variable name (null-terminated)
 * @param value String value (null-terminated)
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_set_string(ctx, "name", "John Doe");
 *   zigpug_set_string(ctx, "title", "Welcome Page");
 */
bool zigpug_set_string(ZigPugContext* ctx, const char* key, const char* value);

/**
 * Set an integer variable in the context
 *
 * @param ctx Context handle
 * @param key Variable name (null-terminated)
 * @param value Integer value
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_set_int(ctx, "count", 42);
 *   zigpug_set_int(ctx, "year", 2024);
 */
bool zigpug_set_int(ZigPugContext* ctx, const char* key, int64_t value);

/**
 * Set a boolean variable in the context
 *
 * @param ctx Context handle
 * @param key Variable name (null-terminated)
 * @param value Boolean value
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_set_bool(ctx, "loggedIn", true);
 *   zigpug_set_bool(ctx, "isAdmin", false);
 */
bool zigpug_set_bool(ZigPugContext* ctx, const char* key, bool value);

/**
 * Set an array variable from a JSON string
 *
 * @param ctx Context handle
 * @param key Variable name (null-terminated)
 * @param json_str JSON array string (e.g., "[\"a\",\"b\",\"c\"]")
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_set_array_json(ctx, "items", "[\"Apple\",\"Banana\",\"Orange\"]");
 *   zigpug_set_array_json(ctx, "numbers", "[1,2,3,4,5]");
 *
 * Note: The JSON must be a valid array. Mixed types are supported.
 */
bool zigpug_set_array_json(ZigPugContext* ctx, const char* key, const char* json_str);

/**
 * Set an object variable from a JSON string
 *
 * @param ctx Context handle
 * @param key Variable name (null-terminated)
 * @param json_str JSON object string (e.g., "{\"name\":\"Alice\",\"age\":30}")
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_set_object_json(ctx, "user", "{\"name\":\"John\",\"age\":25,\"admin\":true}");
 *   zigpug_set_object_json(ctx, "config", "{\"debug\":false,\"port\":8080}");
 *
 * Note: The JSON must be a valid object. Nested objects are supported.
 */
bool zigpug_set_object_json(ZigPugContext* ctx, const char* key, const char* json_str);

/**
 * Get the number of compilation errors from the last compile call
 *
 * @param ctx Context handle
 * @return Number of errors (0 if no errors or no compilation done)
 *
 * Example:
 *   char* html = zigpug_compile(ctx, pug_source);
 *   if (!html) {
 *       size_t error_count = zigpug_get_error_count(ctx);
 *       printf("Compilation failed with %zu errors\n", error_count);
 *   }
 */
size_t zigpug_get_error_count(ZigPugContext* ctx);

/**
 * Get a specific compilation error by index
 *
 * @param ctx Context handle
 * @param index Error index (0 to error_count-1)
 * @param line_out Output: line number where error occurred (can be NULL)
 * @param message_out Output: error message (do not free, can be NULL)
 * @param detail_out Output: detailed error info (do not free, can be NULL, may be NULL even on success)
 * @param hint_out Output: hint for fixing error (do not free, can be NULL, may be NULL even on success)
 * @return true if error exists at index, false otherwise
 *
 * Example:
 *   size_t count = zigpug_get_error_count(ctx);
 *   for (size_t i = 0; i < count; i++) {
 *       size_t line;
 *       const char* message;
 *       const char* detail;
 *       const char* hint;
 *       if (zigpug_get_error(ctx, i, &line, &message, &detail, &hint)) {
 *           printf("Error at line %zu: %s\n", line, message);
 *           if (detail) printf("  Detail: %s\n", detail);
 *           if (hint) printf("  Hint: %s\n", hint);
 *       }
 *   }
 */
bool zigpug_get_error(
    ZigPugContext* ctx,
    size_t index,
    size_t* line_out,
    const char** message_out,
    const char** detail_out,
    const char** hint_out
);

/**
 * Free a string returned by zig-pug
 *
 * @param str String to free (can be NULL)
 *
 * Example:
 *   char* html = zigpug_compile(ctx, pug_source);
 *   // ... use html ...
 *   zigpug_free_string(html);
 */
void zigpug_free_string(char* str);

/**
 * Get zig-pug version string
 *
 * @return Version string (do not free)
 *
 * Example:
 *   printf("zig-pug version: %s\n", zigpug_version());
 */
const char* zigpug_version(void);

#ifdef __cplusplus
}
#endif

#endif /* ZIGPUG_H */
