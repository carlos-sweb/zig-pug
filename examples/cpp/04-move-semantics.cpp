/**
 * Example 4: Move Semantics (C++11)
 *
 * Demonstrates:
 * - Efficient resource transfer with std::move
 * - Context move construction
 * - Returning contexts from functions
 * - RAII benefits
 */

#include <iostream>
#include <utility> // for std::move
#include "zigpug.hpp"

// Function that creates and returns a context
zigpug::Context createConfiguredContext() {
    zigpug::Context ctx;

    ctx.set("appName", "My Application")
       .set("version", "2.0.0")
       .set("year", 2025);

    // Return by value - move semantics automatically applied
    return ctx;
}

int main() {
    try {
        // Move construction - efficient transfer of resources
        zigpug::Context ctx = createConfiguredContext();

        // Compile template
        std::string html = ctx.compile(R"(
html
  body
    h1 #{appName}
    p Version: #{version}
    footer © #{year}
)");

        std::cout << html << std::endl;

        // Another example: explicitly moving a context
        zigpug::Context ctx2 = std::move(ctx);
        // ctx is now in a moved-from state (handle is nullptr)
        // ctx2 owns the resources

        std::string html2 = ctx2.compile("p Moved context!");
        std::cout << html2 << std::endl;

        return 0;

    } catch (const zigpug::Exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
