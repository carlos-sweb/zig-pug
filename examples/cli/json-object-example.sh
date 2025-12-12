#!/bin/bash
# Example: Using --json flag for objects

echo "=== JSON Object Example ==="
echo ""

# Create template
cat > /tmp/user-profile.pug << 'EOF'
doctype html
html
  head
    title #{user.name} - Profile
  body
    div.profile
      h1= user.name
      p Email: #{user.email}
      p Age: #{user.age}
      p Role: #{user.role}
      p Location: #{user.location}
EOF

echo "Template created: /tmp/user-profile.pug"
echo ""

# Compile with JSON object
echo "Command: zpug /tmp/user-profile.pug --json user='{...}'"
echo ""

zpug /tmp/user-profile.pug --json user='{"name":"Alice Johnson","email":"alice@example.com","age":30,"role":"Senior Developer","location":"San Francisco"}' --pretty

echo ""
echo "✓ Success! JSON objects work perfectly"
