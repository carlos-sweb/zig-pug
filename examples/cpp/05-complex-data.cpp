/**
 * Example 5: Complex Data Structures
 *
 * Demonstrates:
 * - Building complex nested data
 * - Dynamic array construction in loops
 * - Combining arrays and objects
 * - Real-world scenario: Product catalog
 */

#include <iostream>
#include <vector>
#include <string>
#include "zigpug.hpp"

struct Product {
    std::string name;
    double price;
    int stock;
    bool available;
};

int main() {
    try {
        zigpug::Context ctx;

        // Simulate products from a database
        std::vector<Product> products = {
            {"Laptop", 999.99, 15, true},
            {"Mouse", 29.99, 50, true},
            {"Keyboard", 79.99, 0, false},
            {"Monitor", 299.99, 8, true}
        };

        // Build products array dynamically
        zigpug::Array productsArray(ctx);

        for (const auto& product : products) {
            zigpug::Object obj(ctx);
            obj.set("name", product.name)
               .set("price", product.price)
               .set("stock", product.stock)
               .set("available", product.available);

            // Note: We need to set the object in a temporary variable
            // because we can't add objects directly to arrays yet
            // This would require extending the Builder API
        }

        // Alternative: Use JSON for complex nested structures
        ctx.setArrayJson("products", R"([
            {"name": "Laptop", "price": 999.99, "stock": 15, "available": true},
            {"name": "Mouse", "price": 29.99, "stock": 50, "available": true},
            {"name": "Keyboard", "price": 79.99, "stock": 0, "available": false},
            {"name": "Monitor", "price": 299.99, "stock": 8, "available": true}
        ])");

        ctx.set("storeName", "Tech Store");

        // Compile template
        std::string html = ctx.compile(R"(
doctype html
html
  head
    title #{storeName} - Products
  body
    h1 #{storeName}
    h2 Product Catalog

    table
      thead
        tr
          th Product
          th Price
          th Stock
          th Status
      tbody
        each product in products
          tr
            td= product.name
            td $#{product.price}
            td= product.stock
            td
              if product.available
                span.badge.success Available
              else
                span.badge.danger Out of Stock
)");

        std::cout << html << std::endl;
        return 0;

    } catch (const zigpug::Exception& e) {
        std::cerr << "Error: " << e.what() << std::endl;
        return 1;
    }
}
