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

/* ============================================================================
 * BUILDER API - Advanced Array and Object Construction
 * ============================================================================
 *
 * The Builder API provides a powerful, type-safe way to construct complex
 * arrays and objects dynamically. Perfect for when you need to build data
 * structures programmatically from database results, API responses, or any
 * dynamic source.
 *
 * Why use Builder API instead of JSON strings?
 * - Type safety: No need to escape strings manually
 * - Dynamic construction: Build arrays/objects in loops
 * - Cleaner code: No string concatenation
 * - Performance: More efficient for complex structures
 *
 * When to use JSON strings vs Builder API:
 * - JSON strings: Simple, static data (e.g., ["a","b","c"])
 * - Builder API: Dynamic, complex data from program logic
 */

/**
 * Opaque array builder handle
 * Used for dynamic array construction
 */
typedef struct ZigPugArray ZigPugArray;

/**
 * Opaque object builder handle
 * Used for dynamic object construction
 */
typedef struct ZigPugObject ZigPugObject;

/* ========== Array Builder Functions ========== */

/**
 * Create a new array builder
 *
 * @param ctx Context handle
 * @return Array builder handle, or NULL on error
 *
 * Example:
 *   ZigPugArray* arr = zigpug_array_create(ctx);
 *   if (!arr) {
 *       fprintf(stderr, "Failed to create array\n");
 *       return 1;
 *   }
 *
 * Note: Must be freed with zigpug_array_free()
 */
ZigPugArray* zigpug_array_create(ZigPugContext* ctx);

/**
 * Free an array builder
 *
 * @param arr Array builder handle (can be NULL)
 *
 * Example:
 *   zigpug_array_free(arr);
 *
 * Note: Safe to call with NULL
 */
void zigpug_array_free(ZigPugArray* arr);

/**
 * Add a string to the array
 *
 * @param arr Array builder handle
 * @param value String value (null-terminated)
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_array_add_string(arr, "Hello");
 *   zigpug_array_add_string(arr, "World");
 */
bool zigpug_array_add_string(ZigPugArray* arr, const char* value);

/**
 * Add an integer to the array
 *
 * @param arr Array builder handle
 * @param value Integer value (64-bit)
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_array_add_int(arr, 42);
 *   zigpug_array_add_int(arr, -100);
 */
bool zigpug_array_add_int(ZigPugArray* arr, int64_t value);

/**
 * Add a double/float to the array
 *
 * @param arr Array builder handle
 * @param value Double value
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_array_add_double(arr, 3.14159);
 *   zigpug_array_add_double(arr, -2.5);
 */
bool zigpug_array_add_double(ZigPugArray* arr, double value);

/**
 * Add a boolean to the array
 *
 * @param arr Array builder handle
 * @param value Boolean value
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_array_add_bool(arr, true);
 *   zigpug_array_add_bool(arr, false);
 */
bool zigpug_array_add_bool(ZigPugArray* arr, bool value);

/**
 * Add null to the array
 *
 * @param arr Array builder handle
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_array_add_null(arr);
 */
bool zigpug_array_add_null(ZigPugArray* arr);

/**
 * Set an array variable in the context using a builder
 *
 * @param ctx Context handle
 * @param key Variable name (null-terminated)
 * @param arr Array builder handle
 * @return true on success, false on error
 *
 * Example:
 *   ZigPugArray* arr = zigpug_array_create(ctx);
 *   zigpug_array_add_string(arr, "Apple");
 *   zigpug_array_add_string(arr, "Banana");
 *   zigpug_set_array(ctx, "fruits", arr);
 *   zigpug_array_free(arr);  // Safe to free after set
 *
 * Note: The array is copied, so you can free the builder immediately
 */
bool zigpug_set_array(ZigPugContext* ctx, const char* key, ZigPugArray* arr);

/* ========== Object Builder Functions ========== */

/**
 * Create a new object builder
 *
 * @param ctx Context handle
 * @return Object builder handle, or NULL on error
 *
 * Example:
 *   ZigPugObject* obj = zigpug_object_create(ctx);
 *   if (!obj) {
 *       fprintf(stderr, "Failed to create object\n");
 *       return 1;
 *   }
 *
 * Note: Must be freed with zigpug_object_free()
 */
ZigPugObject* zigpug_object_create(ZigPugContext* ctx);

/**
 * Free an object builder
 *
 * @param obj Object builder handle (can be NULL)
 *
 * Example:
 *   zigpug_object_free(obj);
 *
 * Note: Safe to call with NULL
 */
void zigpug_object_free(ZigPugObject* obj);

/**
 * Set a string property in the object
 *
 * @param obj Object builder handle
 * @param key Property name (null-terminated)
 * @param value String value (null-terminated)
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_object_set_string(obj, "name", "Alice");
 *   zigpug_object_set_string(obj, "email", "alice@example.com");
 */
bool zigpug_object_set_string(ZigPugObject* obj, const char* key, const char* value);

/**
 * Set an integer property in the object
 *
 * @param obj Object builder handle
 * @param key Property name (null-terminated)
 * @param value Integer value (64-bit)
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_object_set_int(obj, "age", 30);
 *   zigpug_object_set_int(obj, "score", 9999);
 */
bool zigpug_object_set_int(ZigPugObject* obj, const char* key, int64_t value);

/**
 * Set a double/float property in the object
 *
 * @param obj Object builder handle
 * @param key Property name (null-terminated)
 * @param value Double value
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_object_set_double(obj, "price", 19.99);
 *   zigpug_object_set_double(obj, "rating", 4.5);
 */
bool zigpug_object_set_double(ZigPugObject* obj, const char* key, double value);

/**
 * Set a boolean property in the object
 *
 * @param obj Object builder handle
 * @param key Property name (null-terminated)
 * @param value Boolean value
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_object_set_bool(obj, "admin", true);
 *   zigpug_object_set_bool(obj, "verified", false);
 */
bool zigpug_object_set_bool(ZigPugObject* obj, const char* key, bool value);

/**
 * Set a null property in the object
 *
 * @param obj Object builder handle
 * @param key Property name (null-terminated)
 * @return true on success, false on error
 *
 * Example:
 *   zigpug_object_set_null(obj, "optional_field");
 */
bool zigpug_object_set_null(ZigPugObject* obj, const char* key);

/**
 * Set an object variable in the context using a builder
 *
 * @param ctx Context handle
 * @param key Variable name (null-terminated)
 * @param obj Object builder handle
 * @return true on success, false on error
 *
 * Example:
 *   ZigPugObject* user = zigpug_object_create(ctx);
 *   zigpug_object_set_string(user, "name", "Alice");
 *   zigpug_object_set_int(user, "age", 30);
 *   zigpug_set_object(ctx, "user", user);
 *   zigpug_object_free(user);  // Safe to free after set
 *
 * Note: The object is copied, so you can free the builder immediately
 */
bool zigpug_set_object(ZigPugContext* ctx, const char* key, ZigPugObject* obj);

#ifdef __cplusplus
}
#endif

#endif /* ZIGPUG_H */
