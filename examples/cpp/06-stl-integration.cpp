/**
 * Example 6: STL Integration
 *
 * Demonstrates:
 * - Using std::map for variables
 * - Setting multiple variables at once
 * - Integration with STL containers
 * - Modern C++ patterns
 */

#include <iostream>
#include <map>
#include <string>
#include "zigpug.hpp"

int main() {
    try {
        zigpug::Context ctx;

        // Use std::map for configuration
        std::map<std::string, std::string> vars = {
            {"title", "Dashboard"},
            {"username", "john_doe"},
            {"email", "john@example.com"},
            {"role", "administrator"}
        };

        // Set all variables at once
        ctx.setAll(vars)
           .set("year", 2025)
           .set("loggedIn", true);

        // Compile template
        std::string html = ctx.compile(R"(
doctype html
html
  head
    title #{title}
  body
    header
      h1 #{title}
      if loggedIn
        p Welcome, #{username}!

    main
      dl
        dt Username
        dd= username

        dt Email
        dd= email

        dt Role
        dd= role

    footer
      p © #{year}
)");

        std::cout << html << std::endl;
        return 0;

    } catch (const zigpug::Exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
