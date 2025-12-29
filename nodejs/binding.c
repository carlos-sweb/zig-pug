/*
 * Node.js N-API binding for zig-pug
 * This file creates a native Node.js addon that exposes zig-pug functionality
 */

#include <node_api.h>
#include <string.h>
#include <stdlib.h>

// Forward declarations of zig-pug C API
// These are defined in src/lib.zig and exported via the C FFI
typedef struct ZigPugContext ZigPugContext;

extern ZigPugContext* zigpug_init(void);
extern void zigpug_free(ZigPugContext* ctx);
extern char* zigpug_compile(ZigPugContext* ctx, const char* pug_source);
extern int zigpug_set_string(ZigPugContext* ctx, const char* key, const char* value);
extern int zigpug_set_int(ZigPugContext* ctx, const char* key, long long value);
extern int zigpug_set_bool(ZigPugContext* ctx, const char* key, int value);
extern int zigpug_set_array_json(ZigPugContext* ctx, const char* key, const char* json_str);
extern int zigpug_set_object_json(ZigPugContext* ctx, const char* key, const char* json_str);
extern void zigpug_free_string(char* str);
extern const char* zigpug_version(void);
extern size_t zigpug_get_error_count(ZigPugContext* ctx);
extern int zigpug_get_error(ZigPugContext* ctx, size_t index, size_t* line_out, const char** message_out, const char** detail_out, const char** hint_out);
extern char* zigpug_pretty_print(const char* html, int include_comments);
extern char* zigpug_minify(const char* html);

// Wrapper for ZigPugContext to store in JavaScript
typedef struct {
    ZigPugContext* ctx;
} PugContextWrapper;

// Finalizer for context when garbage collected
static void context_finalizer(napi_env env, void* finalize_data, void* finalize_hint) {
    (void)env;
    (void)finalize_hint;

    PugContextWrapper* wrapper = (PugContextWrapper*)finalize_data;
    if (wrapper && wrapper->ctx) {
        zigpug_free(wrapper->ctx);
    }
    free(wrapper);
}

// Create a new Pug context
// JavaScript: const ctx = zigpug.createContext()
static napi_value CreateContext(napi_env env, napi_callback_info info) {
    (void)info;

    napi_status status;
    napi_value result;

    // Initialize zig-pug context
    ZigPugContext* ctx = zigpug_init();
    if (!ctx) {
        napi_throw_error(env, NULL, "Failed to initialize zig-pug context");
        return NULL;
    }

    // Wrap in our structure
    PugContextWrapper* wrapper = malloc(sizeof(PugContextWrapper));
    if (!wrapper) {
        zigpug_free(ctx);
        napi_throw_error(env, NULL, "Out of memory");
        return NULL;
    }
    wrapper->ctx = ctx;

    // Create JavaScript external object
    status = napi_create_external(env, wrapper, context_finalizer, NULL, &result);
    if (status != napi_ok) {
        zigpug_free(ctx);
        free(wrapper);
        napi_throw_error(env, NULL, "Failed to create external object");
        return NULL;
    }

    return result;
}

// Set a string variable
// JavaScript: zigpug.setString(ctx, 'name', 'Alice')
static napi_value SetString(napi_env env, napi_callback_info info) {
    napi_status status;
    size_t argc = 3;
    napi_value args[3];

    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    if (status != napi_ok || argc < 3) {
        napi_throw_error(env, NULL, "Expected 3 arguments: context, key, value");
        return NULL;
    }

    // Get context
    PugContextWrapper* wrapper;
    status = napi_get_value_external(env, args[0], (void**)&wrapper);
    if (status != napi_ok || !wrapper || !wrapper->ctx) {
        napi_throw_error(env, NULL, "Invalid context");
        return NULL;
    }

    // Get key string
    size_t key_len;
    status = napi_get_value_string_utf8(env, args[1], NULL, 0, &key_len);
    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Invalid key");
        return NULL;
    }

    char* key = malloc(key_len + 1);
    status = napi_get_value_string_utf8(env, args[1], key, key_len + 1, &key_len);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get key string");
        return NULL;
    }

    // Get value string
    size_t value_len;
    status = napi_get_value_string_utf8(env, args[2], NULL, 0, &value_len);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Invalid value");
        return NULL;
    }

    char* value = malloc(value_len + 1);
    status = napi_get_value_string_utf8(env, args[2], value, value_len + 1, &value_len);
    if (status != napi_ok) {
        free(key);
        free(value);
        napi_throw_error(env, NULL, "Failed to get value string");
        return NULL;
    }

    // Set in zig-pug
    int result = zigpug_set_string(wrapper->ctx, key, value);

    free(key);
    free(value);

    napi_value js_result;
    status = napi_get_boolean(env, result != 0, &js_result);
    return js_result;
}

// Set a number variable
// JavaScript: zigpug.setNumber(ctx, 'age', 25)
static napi_value SetNumber(napi_env env, napi_callback_info info) {
    napi_status status;
    size_t argc = 3;
    napi_value args[3];

    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    if (status != napi_ok || argc < 3) {
        napi_throw_error(env, NULL, "Expected 3 arguments: context, key, value");
        return NULL;
    }

    // Get context
    PugContextWrapper* wrapper;
    status = napi_get_value_external(env, args[0], (void**)&wrapper);
    if (status != napi_ok || !wrapper || !wrapper->ctx) {
        napi_throw_error(env, NULL, "Invalid context");
        return NULL;
    }

    // Get key string
    size_t key_len;
    status = napi_get_value_string_utf8(env, args[1], NULL, 0, &key_len);
    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Invalid key");
        return NULL;
    }

    char* key = malloc(key_len + 1);
    status = napi_get_value_string_utf8(env, args[1], key, key_len + 1, &key_len);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get key string");
        return NULL;
    }

    // Get number value
    int64_t value;
    status = napi_get_value_int64(env, args[2], &value);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Invalid number value");
        return NULL;
    }

    // Set in zig-pug
    int result = zigpug_set_int(wrapper->ctx, key, value);

    free(key);

    napi_value js_result;
    status = napi_get_boolean(env, result != 0, &js_result);
    return js_result;
}

// Set a boolean variable
// JavaScript: zigpug.setBool(ctx, 'active', true)
static napi_value SetBool(napi_env env, napi_callback_info info) {
    napi_status status;
    size_t argc = 3;
    napi_value args[3];

    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    if (status != napi_ok || argc < 3) {
        napi_throw_error(env, NULL, "Expected 3 arguments: context, key, value");
        return NULL;
    }

    // Get context
    PugContextWrapper* wrapper;
    status = napi_get_value_external(env, args[0], (void**)&wrapper);
    if (status != napi_ok || !wrapper || !wrapper->ctx) {
        napi_throw_error(env, NULL, "Invalid context");
        return NULL;
    }

    // Get key string
    size_t key_len;
    status = napi_get_value_string_utf8(env, args[1], NULL, 0, &key_len);
    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Invalid key");
        return NULL;
    }

    char* key = malloc(key_len + 1);
    status = napi_get_value_string_utf8(env, args[1], key, key_len + 1, &key_len);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get key string");
        return NULL;
    }

    // Get boolean value
    bool value;
    status = napi_get_value_bool(env, args[2], &value);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Invalid boolean value");
        return NULL;
    }

    // Set in zig-pug
    int result = zigpug_set_bool(wrapper->ctx, key, value ? 1 : 0);

    free(key);

    napi_value js_result;
    status = napi_get_boolean(env, result != 0, &js_result);
    return js_result;
}

// Compile a Pug template to HTML
// JavaScript: const html = zigpug.compile(ctx, template)
static napi_value Compile(napi_env env, napi_callback_info info) {
    napi_status status;
    size_t argc = 2;
    napi_value args[2];

    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    if (status != napi_ok || argc < 2) {
        napi_throw_error(env, NULL, "Expected 2 arguments: context, template");
        return NULL;
    }

    // Get context
    PugContextWrapper* wrapper;
    status = napi_get_value_external(env, args[0], (void**)&wrapper);
    if (status != napi_ok || !wrapper || !wrapper->ctx) {
        napi_throw_error(env, NULL, "Invalid context");
        return NULL;
    }

    // Get template string
    size_t template_len;
    status = napi_get_value_string_utf8(env, args[1], NULL, 0, &template_len);
    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Invalid template");
        return NULL;
    }

    char* template = malloc(template_len + 1);
    status = napi_get_value_string_utf8(env, args[1], template, template_len + 1, &template_len);
    if (status != napi_ok) {
        free(template);
        napi_throw_error(env, NULL, "Failed to get template string");
        return NULL;
    }

    // Compile with zig-pug
    char* html = zigpug_compile(wrapper->ctx, template);
    free(template);

    if (!html) {
        // Get error information
        size_t error_count = zigpug_get_error_count(wrapper->ctx);

        if (error_count > 0) {
            // Create structured error object
            napi_value error_obj;
            napi_create_object(env, &error_obj);

            // Add error count
            napi_value count_value;
            napi_create_uint32(env, (uint32_t)error_count, &count_value);
            napi_set_named_property(env, error_obj, "errorCount", count_value);

            // Add errors array
            napi_value errors_array;
            napi_create_array_with_length(env, error_count, &errors_array);

            for (size_t i = 0; i < error_count; i++) {
                size_t line;
                const char* message;
                const char* detail;
                const char* hint;

                if (zigpug_get_error(wrapper->ctx, i, &line, &message, &detail, &hint)) {
                    napi_value err_obj;
                    napi_create_object(env, &err_obj);

                    // Add line number
                    napi_value line_value;
                    napi_create_uint32(env, (uint32_t)line, &line_value);
                    napi_set_named_property(env, err_obj, "line", line_value);

                    // Add message
                    napi_value message_value;
                    napi_create_string_utf8(env, message, NAPI_AUTO_LENGTH, &message_value);
                    napi_set_named_property(env, err_obj, "message", message_value);

                    // Add detail if present
                    if (detail) {
                        napi_value detail_value;
                        napi_create_string_utf8(env, detail, NAPI_AUTO_LENGTH, &detail_value);
                        napi_set_named_property(env, err_obj, "detail", detail_value);
                    }

                    // Add hint if present
                    if (hint) {
                        napi_value hint_value;
                        napi_create_string_utf8(env, hint, NAPI_AUTO_LENGTH, &hint_value);
                        napi_set_named_property(env, err_obj, "hint", hint_value);
                    }

                    napi_set_element(env, errors_array, (uint32_t)i, err_obj);
                }
            }

            napi_set_named_property(env, error_obj, "errors", errors_array);

            // Throw the structured error
            napi_throw_error(env, NULL, "Template compilation failed");
            napi_value error_instance;
            napi_get_and_clear_last_exception(env, &error_instance);

            // Add our structured error data to the error object
            napi_set_named_property(env, error_instance, "compilationErrors", error_obj);
            napi_throw(env, error_instance);
        } else {
            napi_throw_error(env, NULL, "Failed to compile template");
        }
        return NULL;
    }

    // Create JavaScript string
    napi_value result;
    status = napi_create_string_utf8(env, html, NAPI_AUTO_LENGTH, &result);
    zigpug_free_string(html);

    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Failed to create result string");
        return NULL;
    }

    return result;
}

// Set an array variable from JavaScript array
// JavaScript: zigpug.setArray(ctx, 'items', ['a', 'b', 'c'])
static napi_value SetArray(napi_env env, napi_callback_info info) {
    napi_status status;
    size_t argc = 3;
    napi_value args[3];

    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    if (status != napi_ok || argc < 3) {
        napi_throw_error(env, NULL, "Expected 3 arguments: context, key, array");
        return NULL;
    }

    // Get context
    PugContextWrapper* wrapper;
    status = napi_get_value_external(env, args[0], (void**)&wrapper);
    if (status != napi_ok || !wrapper || !wrapper->ctx) {
        napi_throw_error(env, NULL, "Invalid context");
        return NULL;
    }

    // Get key string
    size_t key_len;
    status = napi_get_value_string_utf8(env, args[1], NULL, 0, &key_len);
    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Invalid key");
        return NULL;
    }

    char* key = malloc(key_len + 1);
    status = napi_get_value_string_utf8(env, args[1], key, key_len + 1, &key_len);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get key string");
        return NULL;
    }

    // Convert JavaScript array to JSON string
    napi_value json_value;
    napi_value global;
    napi_value json_obj;
    napi_value stringify_fn;

    status = napi_get_global(env, &global);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get global object");
        return NULL;
    }

    status = napi_get_named_property(env, global, "JSON", &json_obj);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get JSON object");
        return NULL;
    }

    status = napi_get_named_property(env, json_obj, "stringify", &stringify_fn);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get JSON.stringify");
        return NULL;
    }

    napi_value argv[1] = { args[2] };
    status = napi_call_function(env, json_obj, stringify_fn, 1, argv, &json_value);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to stringify array");
        return NULL;
    }

    // Get JSON string
    size_t json_len;
    status = napi_get_value_string_utf8(env, json_value, NULL, 0, &json_len);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get JSON string length");
        return NULL;
    }

    char* json_str = malloc(json_len + 1);
    status = napi_get_value_string_utf8(env, json_value, json_str, json_len + 1, &json_len);
    if (status != napi_ok) {
        free(key);
        free(json_str);
        napi_throw_error(env, NULL, "Failed to get JSON string");
        return NULL;
    }

    // Set in zig-pug
    int result = zigpug_set_array_json(wrapper->ctx, key, json_str);

    free(key);
    free(json_str);

    napi_value js_result;
    status = napi_get_boolean(env, result != 0, &js_result);
    return js_result;
}

// Set an object variable from JavaScript object
// JavaScript: zigpug.setObject(ctx, 'user', {name: 'Alice', age: 30})
static napi_value SetObject(napi_env env, napi_callback_info info) {
    napi_status status;
    size_t argc = 3;
    napi_value args[3];

    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    if (status != napi_ok || argc < 3) {
        napi_throw_error(env, NULL, "Expected 3 arguments: context, key, object");
        return NULL;
    }

    // Get context
    PugContextWrapper* wrapper;
    status = napi_get_value_external(env, args[0], (void**)&wrapper);
    if (status != napi_ok || !wrapper || !wrapper->ctx) {
        napi_throw_error(env, NULL, "Invalid context");
        return NULL;
    }

    // Get key string
    size_t key_len;
    status = napi_get_value_string_utf8(env, args[1], NULL, 0, &key_len);
    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Invalid key");
        return NULL;
    }

    char* key = malloc(key_len + 1);
    status = napi_get_value_string_utf8(env, args[1], key, key_len + 1, &key_len);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get key string");
        return NULL;
    }

    // Convert JavaScript object to JSON string
    napi_value json_value;
    napi_value global;
    napi_value json_obj;
    napi_value stringify_fn;

    status = napi_get_global(env, &global);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get global object");
        return NULL;
    }

    status = napi_get_named_property(env, global, "JSON", &json_obj);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get JSON object");
        return NULL;
    }

    status = napi_get_named_property(env, json_obj, "stringify", &stringify_fn);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get JSON.stringify");
        return NULL;
    }

    napi_value argv[1] = { args[2] };
    status = napi_call_function(env, json_obj, stringify_fn, 1, argv, &json_value);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to stringify object");
        return NULL;
    }

    // Get JSON string
    size_t json_len;
    status = napi_get_value_string_utf8(env, json_value, NULL, 0, &json_len);
    if (status != napi_ok) {
        free(key);
        napi_throw_error(env, NULL, "Failed to get JSON string length");
        return NULL;
    }

    char* json_str = malloc(json_len + 1);
    status = napi_get_value_string_utf8(env, json_value, json_str, json_len + 1, &json_len);
    if (status != napi_ok) {
        free(key);
        free(json_str);
        napi_throw_error(env, NULL, "Failed to get JSON string");
        return NULL;
    }

    // Set in zig-pug
    int result = zigpug_set_object_json(wrapper->ctx, key, json_str);

    free(key);
    free(json_str);

    napi_value js_result;
    status = napi_get_boolean(env, result != 0, &js_result);
    return js_result;
}

// Get zig-pug version
// JavaScript: const version = zigpug.version()
static napi_value Version(napi_env env, napi_callback_info info) {
    (void)info;

    const char* version = zigpug_version();

    napi_value result;
    napi_status status = napi_create_string_utf8(env, version, NAPI_AUTO_LENGTH, &result);

    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Failed to get version");
        return NULL;
    }

    return result;
}

// Pretty-print HTML with optional comments
// JavaScript: const formatted = zigpug.prettyPrint(html, includeComments)
static napi_value PrettyPrint(napi_env env, napi_callback_info info) {
    napi_status status;
    size_t argc = 2;
    napi_value args[2];

    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    if (status != napi_ok || argc < 2) {
        napi_throw_error(env, NULL, "Expected 2 arguments: html, includeComments");
        return NULL;
    }

    // Get HTML string
    size_t html_len;
    status = napi_get_value_string_utf8(env, args[0], NULL, 0, &html_len);
    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Invalid HTML string");
        return NULL;
    }

    char* html = malloc(html_len + 1);
    status = napi_get_value_string_utf8(env, args[0], html, html_len + 1, &html_len);
    if (status != napi_ok) {
        free(html);
        napi_throw_error(env, NULL, "Failed to get HTML string");
        return NULL;
    }

    // Get includeComments boolean
    bool include_comments;
    status = napi_get_value_bool(env, args[1], &include_comments);
    if (status != napi_ok) {
        free(html);
        napi_throw_error(env, NULL, "Invalid includeComments boolean");
        return NULL;
    }

    // Call zig-pug pretty print
    char* formatted = zigpug_pretty_print(html, include_comments ? 1 : 0);
    free(html);

    if (!formatted) {
        napi_throw_error(env, NULL, "Failed to format HTML");
        return NULL;
    }

    // Create JavaScript string
    napi_value result;
    status = napi_create_string_utf8(env, formatted, NAPI_AUTO_LENGTH, &result);
    zigpug_free_string(formatted);

    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Failed to create result string");
        return NULL;
    }

    return result;
}

// Minify HTML
// JavaScript: const minified = zigpug.minify(html)
static napi_value Minify(napi_env env, napi_callback_info info) {
    napi_status status;
    size_t argc = 1;
    napi_value args[1];

    status = napi_get_cb_info(env, info, &argc, args, NULL, NULL);
    if (status != napi_ok || argc < 1) {
        napi_throw_error(env, NULL, "Expected 1 argument: html");
        return NULL;
    }

    // Get HTML string
    size_t html_len;
    status = napi_get_value_string_utf8(env, args[0], NULL, 0, &html_len);
    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Invalid HTML string");
        return NULL;
    }

    char* html = malloc(html_len + 1);
    status = napi_get_value_string_utf8(env, args[0], html, html_len + 1, &html_len);
    if (status != napi_ok) {
        free(html);
        napi_throw_error(env, NULL, "Failed to get HTML string");
        return NULL;
    }

    // Call zig-pug minify
    char* minified = zigpug_minify(html);
    free(html);

    if (!minified) {
        napi_throw_error(env, NULL, "Failed to minify HTML");
        return NULL;
    }

    // Create JavaScript string
    napi_value result;
    status = napi_create_string_utf8(env, minified, NAPI_AUTO_LENGTH, &result);
    zigpug_free_string(minified);

    if (status != napi_ok) {
        napi_throw_error(env, NULL, "Failed to create result string");
        return NULL;
    }

    return result;
}

// Initialize the N-API module
static napi_value Init(napi_env env, napi_value exports) {
    napi_status status;
    napi_value fn;

    // createContext
    status = napi_create_function(env, NULL, 0, CreateContext, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "createContext", fn);
    if (status != napi_ok) return NULL;

    // setString
    status = napi_create_function(env, NULL, 0, SetString, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "setString", fn);
    if (status != napi_ok) return NULL;

    // setNumber
    status = napi_create_function(env, NULL, 0, SetNumber, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "setNumber", fn);
    if (status != napi_ok) return NULL;

    // setBool
    status = napi_create_function(env, NULL, 0, SetBool, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "setBool", fn);
    if (status != napi_ok) return NULL;

    // setArray
    status = napi_create_function(env, NULL, 0, SetArray, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "setArray", fn);
    if (status != napi_ok) return NULL;

    // setObject
    status = napi_create_function(env, NULL, 0, SetObject, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "setObject", fn);
    if (status != napi_ok) return NULL;

    // compile
    status = napi_create_function(env, NULL, 0, Compile, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "compile", fn);
    if (status != napi_ok) return NULL;

    // version
    status = napi_create_function(env, NULL, 0, Version, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "version", fn);
    if (status != napi_ok) return NULL;

    // prettyPrint
    status = napi_create_function(env, NULL, 0, PrettyPrint, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "prettyPrint", fn);
    if (status != napi_ok) return NULL;

    // minify
    status = napi_create_function(env, NULL, 0, Minify, NULL, &fn);
    if (status != napi_ok) return NULL;
    status = napi_set_named_property(env, exports, "minify", fn);
    if (status != napi_ok) return NULL;

    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
