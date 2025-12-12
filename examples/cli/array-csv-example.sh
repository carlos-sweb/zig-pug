#!/bin/bash
# Example: Using --array flag with CSV values

echo "=== Array CSV Example ==="
echo ""

# Create template
cat > /tmp/fruits.pug << 'EOF'
doctype html
html
  head
    title Fruit List
  body
    h1 My Favorite Fruits
    ul.fruit-list
      each fruit in fruits
        li.fruit= fruit
EOF

echo "Template created: /tmp/fruits.pug"
echo ""

# Compile with array
echo "Command: zpug /tmp/fruits.pug --array fruits=apple,banana,orange,mango"
echo ""

zpug /tmp/fruits.pug --array fruits=apple,banana,orange,mango

echo ""
echo "✓ Success! Array from CSV works perfectly"
