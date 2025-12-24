/**
 * Example 2: Arrays in C++
 *
 * Demonstrates:
 * - Creating arrays with the Builder API
 * - Fluent interface (method chaining)
 * - Mixed types in arrays
 * - Using arrays in templates
 */

#include <iostream>
#include "zigpug.hpp"

int main() {
    try {
        zigpug::Context ctx;

        // Create an array using fluent interface
        zigpug::Array fruits(ctx);
        fruits.add("Apple")
              .add("Banana")
              .add("Orange")
              .add("Mango");

        // Create an array with mixed types
        zigpug::Array mixed(ctx);
        mixed.add("Text")
             .add(42)
             .add(3.14)
             .add(true)
             .addNull();

        // Set arrays in context
        ctx.set("fruits", fruits)
           .set("mixed", mixed);

        // Compile template
        std::string html = ctx.compile(R"(
doctype html
html
  head
    title Array Example
  body
    h1 Fruits
    ul
      each fruit in fruits
        li= fruit

    h2 Mixed Types
    ul
      each item in mixed
        li= item
)");

        std::cout << html << std::endl;
        return 0;

    } catch (const zigpug::Exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
