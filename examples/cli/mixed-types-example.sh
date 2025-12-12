#!/bin/bash
# Example: Mixing --var, --array, and --json

echo "=== Mixed Types Example ==="
echo ""

# Create template
cat > /tmp/dashboard.pug << 'EOF'
doctype html
html
  head
    title= pageTitle
  body
    h1= pageTitle
    p Version: #{version}

    section.user
      h2 Current User
      p Name: #{user.name}
      p Role: #{user.role}

    section.tags
      h2 Active Tags
      ul
        each tag in tags
          li.tag= tag

    section.scores
      h2 Test Scores
      ul
        each score in scores
          li Score: #{score}
EOF

echo "Template created: /tmp/dashboard.pug"
echo ""

# Compile with mixed types
echo "Command:"
echo "  zpug /tmp/dashboard.pug \\"
echo "    --var pageTitle='Admin Dashboard' \\"
echo "    --var version=2.5 \\"
echo "    --json user='{\"name\":\"Carlos\",\"role\":\"Admin\"}' \\"
echo "    --array tags=production,stable,v2 \\"
echo "    --array scores=95,87,92,88.5 \\"
echo "    --pretty"
echo ""

zpug /tmp/dashboard.pug \
  --var pageTitle="Admin Dashboard" \
  --var version=2.5 \
  --json user='{"name":"Carlos","role":"Admin"}' \
  --array tags=production,stable,v2 \
  --array scores=95,87,92,88.5 \
  --pretty

echo ""
echo "✓ Success! Mixed types work perfectly"
