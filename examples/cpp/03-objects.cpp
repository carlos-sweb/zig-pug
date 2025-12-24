/**
 * Example 3: Objects in C++
 *
 * Demonstrates:
 * - Creating objects with the Builder API
 * - Setting different property types
 * - Nested object access in templates
 * - Multiple objects
 */

#include <iostream>
#include "zigpug.hpp"

int main() {
    try {
        zigpug::Context ctx;

        // Create a user object
        zigpug::Object user(ctx);
        user.set("name", "Alice Johnson")
            .set("email", "alice@example.com")
            .set("age", 30)
            .set("admin", true)
            .set("score", 95.5);

        // Create a config object
        zigpug::Object config(ctx);
        config.set("siteName", "My Website")
              .set("port", 8080)
              .set("debug", false)
              .set("version", "1.0.0");

        // Set objects in context
        ctx.set("user", user)
           .set("config", config);

        // Compile template
        std::string html = ctx.compile(R"(
doctype html
html
  head
    title #{config.siteName}
  body
    h1 User Profile
    dl
      dt Name
      dd= user.name

      dt Email
      dd= user.email

      dt Age
      dd= user.age

      dt Score
      dd= user.score

      dt Admin
      dd= user.admin ? 'Yes' : 'No'

    hr

    h2 Configuration
    ul
      li Site: #{config.siteName}
      li Port: #{config.port}
      li Version: #{config.version}
      li Debug: #{config.debug}
)");

        std::cout << html << std::endl;
        return 0;

    } catch (const zigpug::Exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
