/**
 * zig-pug - Pug template engine written in Zig
 * C++ API Header
 *
 * Modern C++ wrapper with RAII, exceptions, STL containers, and type safety
 *
 * Features:
 * - RAII: Automatic resource management
 * - Exceptions: Type-safe error handling
 * - STL: std::string, std::vector, std::map support
 * - Builder API: Fluent interface for arrays and objects
 * - Move semantics: Efficient resource transfer (C++11)
 * - String view support: Zero-copy operations (C++17)
 */

#ifndef ZIGPUG_HPP
#define ZIGPUG_HPP

#include "zigpug.h"
#include <string>
#include <vector>
#include <map>
#include <stdexcept>
#include <memory>
#include <cstdint>

#if __cplusplus >= 201703L
#include <string_view>
#include <optional>
#endif

namespace zigpug {

// ============================================================================
// Exception Types
// ============================================================================

/**
 * Base exception for all zig-pug errors
 */
class Exception : public std::runtime_error {
public:
    explicit Exception(const std::string& message)
        : std::runtime_error(message) {}
};

/**
 * Thrown when context initialization fails
 */
class InitializationError : public Exception {
public:
    InitializationError()
        : Exception("Failed to initialize zig-pug context") {}
};

/**
 * Thrown when template compilation fails
 */
class CompilationError : public Exception {
public:
    struct Error {
        size_t line;
        std::string message;
        std::string detail;
        std::string hint;
    };

    explicit CompilationError(const std::string& message)
        : Exception(message) {}

    CompilationError(const std::string& message, std::vector<Error>&& errors)
        : Exception(message), errors_(std::move(errors)) {}

    const std::vector<Error>& errors() const { return errors_; }

private:
    std::vector<Error> errors_;
};

/**
 * Thrown when variable operations fail
 */
class VariableError : public Exception {
public:
    explicit VariableError(const std::string& message)
        : Exception(message) {}
};

// ============================================================================
// Forward Declarations
// ============================================================================

class Context;
class Array;
class Object;

// ============================================================================
// Array Builder
// ============================================================================

/**
 * RAII wrapper for ZigPugArray with fluent interface
 *
 * Example:
 *   Array arr(ctx);
 *   arr.add("Apple").add("Banana").add(42).add(true);
 *   ctx.set("items", arr);
 */
class Array {
public:
    /**
     * Create a new array builder
     * @throws InitializationError if creation fails
     */
    explicit Array(Context& ctx);

    /**
     * Destructor - automatically frees the array
     */
    ~Array();

    // Non-copyable
    Array(const Array&) = delete;
    Array& operator=(const Array&) = delete;

    // Move support
    Array(Array&& other) noexcept;
    Array& operator=(Array&& other) noexcept;

    /**
     * Add a string to the array
     * @return *this for chaining
     */
    Array& add(const std::string& value);
    Array& add(const char* value);

#if __cplusplus >= 201703L
    Array& add(std::string_view value);
#endif

    /**
     * Add an integer to the array
     * @return *this for chaining
     */
    Array& add(int64_t value);

    /**
     * Add a double to the array
     * @return *this for chaining
     */
    Array& add(double value);
    Array& add(float value) { return add(static_cast<double>(value)); }

    /**
     * Add a boolean to the array
     * @return *this for chaining
     */
    Array& add(bool value);

    /**
     * Add null to the array
     * @return *this for chaining
     */
    Array& addNull();

    /**
     * Get the underlying C handle (for internal use)
     */
    ZigPugArray* handle() const { return handle_; }

private:
    ZigPugArray* handle_;
};

// ============================================================================
// Object Builder
// ============================================================================

/**
 * RAII wrapper for ZigPugObject with fluent interface
 *
 * Example:
 *   Object user(ctx);
 *   user.set("name", "Alice")
 *       .set("age", 30)
 *       .set("admin", true);
 *   ctx.set("user", user);
 */
class Object {
public:
    /**
     * Create a new object builder
     * @throws InitializationError if creation fails
     */
    explicit Object(Context& ctx);

    /**
     * Destructor - automatically frees the object
     */
    ~Object();

    // Non-copyable
    Object(const Object&) = delete;
    Object& operator=(const Object&) = delete;

    // Move support
    Object(Object&& other) noexcept;
    Object& operator=(Object&& other) noexcept;

    /**
     * Set a string property
     * @return *this for chaining
     */
    Object& set(const std::string& key, const std::string& value);
    Object& set(const char* key, const char* value);

#if __cplusplus >= 201703L
    Object& set(std::string_view key, std::string_view value);
#endif

    /**
     * Set an integer property
     * @return *this for chaining
     */
    Object& set(const std::string& key, int64_t value);
    Object& set(const char* key, int64_t value);

    /**
     * Set a double property
     * @return *this for chaining
     */
    Object& set(const std::string& key, double value);
    Object& set(const char* key, double value);

    /**
     * Set a boolean property
     * @return *this for chaining
     */
    Object& set(const std::string& key, bool value);
    Object& set(const char* key, bool value);

    /**
     * Set a null property
     * @return *this for chaining
     */
    Object& setNull(const std::string& key);
    Object& setNull(const char* key);

    /**
     * Get the underlying C handle (for internal use)
     */
    ZigPugObject* handle() const { return handle_; }

private:
    ZigPugObject* handle_;
};

// ============================================================================
// Context
// ============================================================================

/**
 * RAII wrapper for ZigPugContext with modern C++ API
 *
 * Example:
 *   try {
 *       Context ctx;
 *       ctx.set("name", "Alice")
 *          .set("age", 30)
 *          .set("active", true);
 *
 *       std::string html = ctx.compile("p Hello #{name}!");
 *       std::cout << html << std::endl;
 *   } catch (const zigpug::Exception& e) {
 *       std::cerr << "Error: " << e.what() << std::endl;
 *   }
 */
class Context {
public:
    /**
     * Initialize a new zig-pug context
     * @throws InitializationError if initialization fails
     */
    Context();

    /**
     * Destructor - automatically frees the context
     */
    ~Context();

    // Non-copyable
    Context(const Context&) = delete;
    Context& operator=(const Context&) = delete;

    // Move support
    Context(Context&& other) noexcept;
    Context& operator=(Context&& other) noexcept;

    /**
     * Compile a Pug template to HTML
     * @param pug_source Pug template string
     * @return HTML string
     * @throws CompilationError if compilation fails
     */
    std::string compile(const std::string& pug_source);
    std::string compile(const char* pug_source);

#if __cplusplus >= 201703L
    std::string compile(std::string_view pug_source);
#endif

    /**
     * Set a string variable
     * @return *this for chaining
     * @throws VariableError if setting fails
     */
    Context& set(const std::string& key, const std::string& value);
    Context& set(const char* key, const char* value);

#if __cplusplus >= 201703L
    Context& set(std::string_view key, std::string_view value);
#endif

    /**
     * Set an integer variable
     * @return *this for chaining
     * @throws VariableError if setting fails
     */
    Context& set(const std::string& key, int64_t value);
    Context& set(const char* key, int64_t value);

    /**
     * Set a boolean variable
     * @return *this for chaining
     * @throws VariableError if setting fails
     */
    Context& set(const std::string& key, bool value);
    Context& set(const char* key, bool value);

    /**
     * Set an array from JSON string
     * @return *this for chaining
     * @throws VariableError if setting fails
     */
    Context& setArrayJson(const std::string& key, const std::string& json);
    Context& setArrayJson(const char* key, const char* json);

    /**
     * Set an object from JSON string
     * @return *this for chaining
     * @throws VariableError if setting fails
     */
    Context& setObjectJson(const std::string& key, const std::string& json);
    Context& setObjectJson(const char* key, const char* json);

    /**
     * Set an array using Array builder
     * @return *this for chaining
     * @throws VariableError if setting fails
     */
    Context& set(const std::string& key, const Array& arr);
    Context& set(const char* key, const Array& arr);

    /**
     * Set an object using Object builder
     * @return *this for chaining
     * @throws VariableError if setting fails
     */
    Context& set(const std::string& key, const Object& obj);
    Context& set(const char* key, const Object& obj);

    /**
     * Set multiple variables from a map
     * @return *this for chaining
     * @throws VariableError if any setting fails
     */
    Context& setAll(const std::map<std::string, std::string>& vars);

    /**
     * Get the underlying C handle (for internal use)
     */
    ZigPugContext* handle() const { return handle_; }

    /**
     * Get zig-pug version
     */
    static std::string version();

private:
    ZigPugContext* handle_;
};

// ============================================================================
// Implementation
// ============================================================================

// Array implementation

inline Array::Array(Context& ctx)
    : handle_(zigpug_array_create(ctx.handle()))
{
    if (!handle_) {
        throw InitializationError();
    }
}

inline Array::~Array() {
    if (handle_) {
        zigpug_array_free(handle_);
    }
}

inline Array::Array(Array&& other) noexcept
    : handle_(other.handle_)
{
    other.handle_ = nullptr;
}

inline Array& Array::operator=(Array&& other) noexcept {
    if (this != &other) {
        if (handle_) {
            zigpug_array_free(handle_);
        }
        handle_ = other.handle_;
        other.handle_ = nullptr;
    }
    return *this;
}

inline Array& Array::add(const std::string& value) {
    if (!zigpug_array_add_string(handle_, value.c_str())) {
        throw VariableError("Failed to add string to array");
    }
    return *this;
}

inline Array& Array::add(const char* value) {
    if (!zigpug_array_add_string(handle_, value)) {
        throw VariableError("Failed to add string to array");
    }
    return *this;
}

#if __cplusplus >= 201703L
inline Array& Array::add(std::string_view value) {
    return add(std::string(value));
}
#endif

inline Array& Array::add(int64_t value) {
    if (!zigpug_array_add_int(handle_, value)) {
        throw VariableError("Failed to add int to array");
    }
    return *this;
}

inline Array& Array::add(double value) {
    if (!zigpug_array_add_double(handle_, value)) {
        throw VariableError("Failed to add double to array");
    }
    return *this;
}

inline Array& Array::add(bool value) {
    if (!zigpug_array_add_bool(handle_, value)) {
        throw VariableError("Failed to add bool to array");
    }
    return *this;
}

inline Array& Array::addNull() {
    if (!zigpug_array_add_null(handle_)) {
        throw VariableError("Failed to add null to array");
    }
    return *this;
}

// Object implementation

inline Object::Object(Context& ctx)
    : handle_(zigpug_object_create(ctx.handle()))
{
    if (!handle_) {
        throw InitializationError();
    }
}

inline Object::~Object() {
    if (handle_) {
        zigpug_object_free(handle_);
    }
}

inline Object::Object(Object&& other) noexcept
    : handle_(other.handle_)
{
    other.handle_ = nullptr;
}

inline Object& Object::operator=(Object&& other) noexcept {
    if (this != &other) {
        if (handle_) {
            zigpug_object_free(handle_);
        }
        handle_ = other.handle_;
        other.handle_ = nullptr;
    }
    return *this;
}

inline Object& Object::set(const std::string& key, const std::string& value) {
    if (!zigpug_object_set_string(handle_, key.c_str(), value.c_str())) {
        throw VariableError("Failed to set string property in object");
    }
    return *this;
}

inline Object& Object::set(const char* key, const char* value) {
    if (!zigpug_object_set_string(handle_, key, value)) {
        throw VariableError("Failed to set string property in object");
    }
    return *this;
}

#if __cplusplus >= 201703L
inline Object& Object::set(std::string_view key, std::string_view value) {
    return set(std::string(key), std::string(value));
}
#endif

inline Object& Object::set(const std::string& key, int64_t value) {
    if (!zigpug_object_set_int(handle_, key.c_str(), value)) {
        throw VariableError("Failed to set int property in object");
    }
    return *this;
}

inline Object& Object::set(const char* key, int64_t value) {
    if (!zigpug_object_set_int(handle_, key, value)) {
        throw VariableError("Failed to set int property in object");
    }
    return *this;
}

inline Object& Object::set(const std::string& key, double value) {
    if (!zigpug_object_set_double(handle_, key.c_str(), value)) {
        throw VariableError("Failed to set double property in object");
    }
    return *this;
}

inline Object& Object::set(const char* key, double value) {
    if (!zigpug_object_set_double(handle_, key, value)) {
        throw VariableError("Failed to set double property in object");
    }
    return *this;
}

inline Object& Object::set(const std::string& key, bool value) {
    if (!zigpug_object_set_bool(handle_, key.c_str(), value)) {
        throw VariableError("Failed to set bool property in object");
    }
    return *this;
}

inline Object& Object::set(const char* key, bool value) {
    if (!zigpug_object_set_bool(handle_, key, value)) {
        throw VariableError("Failed to set bool property in object");
    }
    return *this;
}

inline Object& Object::setNull(const std::string& key) {
    if (!zigpug_object_set_null(handle_, key.c_str())) {
        throw VariableError("Failed to set null property in object");
    }
    return *this;
}

inline Object& Object::setNull(const char* key) {
    if (!zigpug_object_set_null(handle_, key)) {
        throw VariableError("Failed to set null property in object");
    }
    return *this;
}

// Context implementation

inline Context::Context()
    : handle_(zigpug_init())
{
    if (!handle_) {
        throw InitializationError();
    }
}

inline Context::~Context() {
    if (handle_) {
        zigpug_free(handle_);
    }
}

inline Context::Context(Context&& other) noexcept
    : handle_(other.handle_)
{
    other.handle_ = nullptr;
}

inline Context& Context::operator=(Context&& other) noexcept {
    if (this != &other) {
        if (handle_) {
            zigpug_free(handle_);
        }
        handle_ = other.handle_;
        other.handle_ = nullptr;
    }
    return *this;
}

inline std::string Context::compile(const std::string& pug_source) {
    return compile(pug_source.c_str());
}

inline std::string Context::compile(const char* pug_source) {
    char* html = zigpug_compile(handle_, pug_source);
    if (!html) {
        // Collect errors
        size_t error_count = zigpug_get_error_count(handle_);
        std::vector<CompilationError::Error> errors;
        errors.reserve(error_count);

        for (size_t i = 0; i < error_count; i++) {
            size_t line;
            const char* message;
            const char* detail;
            const char* hint;
            if (zigpug_get_error(handle_, i, &line, &message, &detail, &hint)) {
                CompilationError::Error err;
                err.line = line;
                err.message = message ? message : "";
                err.detail = detail ? detail : "";
                err.hint = hint ? hint : "";
                errors.push_back(std::move(err));
            }
        }

        throw CompilationError("Template compilation failed", std::move(errors));
    }

    std::string result(html);
    zigpug_free_string(html);
    return result;
}

#if __cplusplus >= 201703L
inline std::string Context::compile(std::string_view pug_source) {
    return compile(std::string(pug_source));
}
#endif

inline Context& Context::set(const std::string& key, const std::string& value) {
    return set(key.c_str(), value.c_str());
}

inline Context& Context::set(const char* key, const char* value) {
    if (!zigpug_set_string(handle_, key, value)) {
        throw VariableError("Failed to set string variable: " + std::string(key));
    }
    return *this;
}

#if __cplusplus >= 201703L
inline Context& Context::set(std::string_view key, std::string_view value) {
    return set(std::string(key), std::string(value));
}
#endif

inline Context& Context::set(const std::string& key, int64_t value) {
    return set(key.c_str(), value);
}

inline Context& Context::set(const char* key, int64_t value) {
    if (!zigpug_set_int(handle_, key, value)) {
        throw VariableError("Failed to set int variable: " + std::string(key));
    }
    return *this;
}

inline Context& Context::set(const std::string& key, bool value) {
    return set(key.c_str(), value);
}

inline Context& Context::set(const char* key, bool value) {
    if (!zigpug_set_bool(handle_, key, value)) {
        throw VariableError("Failed to set bool variable: " + std::string(key));
    }
    return *this;
}

inline Context& Context::setArrayJson(const std::string& key, const std::string& json) {
    return setArrayJson(key.c_str(), json.c_str());
}

inline Context& Context::setArrayJson(const char* key, const char* json) {
    if (!zigpug_set_array_json(handle_, key, json)) {
        throw VariableError("Failed to set array from JSON: " + std::string(key));
    }
    return *this;
}

inline Context& Context::setObjectJson(const std::string& key, const std::string& json) {
    return setObjectJson(key.c_str(), json.c_str());
}

inline Context& Context::setObjectJson(const char* key, const char* json) {
    if (!zigpug_set_object_json(handle_, key, json)) {
        throw VariableError("Failed to set object from JSON: " + std::string(key));
    }
    return *this;
}

inline Context& Context::set(const std::string& key, const Array& arr) {
    return set(key.c_str(), arr);
}

inline Context& Context::set(const char* key, const Array& arr) {
    if (!zigpug_set_array(handle_, key, arr.handle())) {
        throw VariableError("Failed to set array variable: " + std::string(key));
    }
    return *this;
}

inline Context& Context::set(const std::string& key, const Object& obj) {
    return set(key.c_str(), obj);
}

inline Context& Context::set(const char* key, const Object& obj) {
    if (!zigpug_set_object(handle_, key, obj.handle())) {
        throw VariableError("Failed to set object variable: " + std::string(key));
    }
    return *this;
}

inline Context& Context::setAll(const std::map<std::string, std::string>& vars) {
    for (const auto& pair : vars) {
        set(pair.first, pair.second);
    }
    return *this;
}

inline std::string Context::version() {
    return zigpug_version();
}

} // namespace zigpug

#endif /* ZIGPUG_HPP */
