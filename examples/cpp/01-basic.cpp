/**
 * Example 1: Basic C++ Usage
 *
 * Demonstrates:
 * - Context initialization with RAII
 * - Setting variables with method chaining
 * - Template compilation
 * - Exception handling
 */

#include <iostream>
#include "zigpug.hpp"

int main() {
    try {
        // Create context (RAII - automatically cleaned up)
        zigpug::Context ctx;

        // Set variables using method chaining
        ctx.set("name", "Alice")
           .set("age", int64_t(30))
           .set("active", true);

        // Compile template
        std::string html = ctx.compile(R"(
doctype html
html
  head
    title Welcome
  body
    h1 Hello #{name}!
    p Age: #{age}
    if active
      p.status Active user
    else
      p.status Inactive user
)");

        // Output result
        std::cout << html << std::endl;

        return 0;

    } catch (const zigpug::CompilationError& e) {
        std::cerr << "Compilation error: " << e.what() << std::endl;

        // Print detailed error information
        for (const auto& err : e.errors()) {
            std::cerr << "  Line " << err.line << ": " << err.message << std::endl;
            if (!err.detail.empty()) {
                std::cerr << "    Detail: " << err.detail << std::endl;
            }
            if (!err.hint.empty()) {
                std::cerr << "    Hint: " << err.hint << std::endl;
            }
        }
        return 1;

    } catch (const zigpug::Exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
