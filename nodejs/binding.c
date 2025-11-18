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
extern void zigpug_free_string(char* str);
extern const char* zigpug_version(void);

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
        napi_throw_error(env, NULL, "Failed to compile template");
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

    return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
