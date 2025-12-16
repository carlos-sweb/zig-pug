#!/usr/bin/env bash
# Script to check for broken links in README files

set -e

echo "🔍 Checking links in README files..."
echo ""

# Extract all markdown links from README.md
echo "📄 Checking README.md..."
grep -oE '\[.*\]\([^)]+\)' README.md | while read -r link; do
    # Extract the URL part
    url=$(echo "$link" | sed -E 's/.*\(([^)]+)\).*/\1/')

    # Skip anchors (internal links starting with #)
    if [[ "$url" =~ ^# ]]; then
        continue
    fi

    # Check if it's a file path
    if [[ ! "$url" =~ ^http ]]; then
        # It's a local file path
        if [ ! -f "$url" ] && [ ! -d "$url" ]; then
            echo "  ❌ BROKEN: $link"
            echo "     File not found: $url"
        else
            echo "  ✅ OK: $url"
        fi
    else
        # It's an HTTP link - just list it (we can't check from Termux easily)
        echo "  🌐 EXTERNAL: $url"
    fi
done

echo ""
echo "📄 Checking README.es.md..."
grep -oE '\[.*\]\([^)]+\)' README.es.md | while read -r link; do
    url=$(echo "$link" | sed -E 's/.*\(([^)]+)\).*/\1/')

    if [[ "$url" =~ ^# ]]; then
        continue
    fi

    if [[ ! "$url" =~ ^http ]]; then
        if [ ! -f "$url" ] && [ ! -d "$url" ]; then
            echo "  ❌ BROKEN: $link"
            echo "     File not found: $url"
        else
            echo "  ✅ OK: $url"
        fi
    else
        echo "  🌐 EXTERNAL: $url"
    fi
done

echo ""
echo "✅ Link check complete!"
