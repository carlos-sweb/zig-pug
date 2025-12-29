#!/usr/bin/env bash
# Script to check for broken links in all markdown files

set -e

echo "🔍 Checking links in all markdown files..."
echo ""

# Create temp files for counters (to work around subshell issue)
tmpdir=$(mktemp -d)
trap "rm -rf $tmpdir" EXIT

echo "0" > "$tmpdir/total_links"
echo "0" > "$tmpdir/broken_links"
echo "0" > "$tmpdir/ok_links"
echo "0" > "$tmpdir/external_links"
echo "0" > "$tmpdir/anchor_links"

# Function to increment counter
inc_counter() {
    local file="$tmpdir/$1"
    local val=$(cat "$file")
    echo $((val + 1)) > "$file"
}

# Function to check links in a single markdown file
check_file() {
    local file="$1"
    local file_dir=$(dirname "$file")
    local has_broken=false

    echo "📄 Checking: $file"

    # Check if file has any links
    if ! grep -qE '\[.*\]\([^)]+\)' "$file" 2>/dev/null; then
        echo "  ℹ️  No links found"
        return 0
    fi

    # Extract and check all markdown links
    while IFS= read -r link; do
        inc_counter "total_links"

        # Extract the URL part
        url=$(echo "$link" | sed -E 's/.*\(([^)]+)\).*/\1/')

        # Skip anchors (internal links starting with #)
        if [[ "$url" =~ ^# ]]; then
            inc_counter "anchor_links"
            continue
        fi

        # Check if it's a file path (local link)
        if [[ ! "$url" =~ ^http ]]; then
            # Resolve relative path from the file's directory
            if [[ "$url" =~ ^/ ]]; then
                # Absolute path from repo root
                check_path="$url"
            else
                # Relative path from file's directory
                check_path="$file_dir/$url"
            fi

            # Check if file or directory exists
            if [ ! -f "$check_path" ] && [ ! -d "$check_path" ]; then
                echo "  ❌ BROKEN: $link"
                echo "     File not found: $url"
                echo "     Resolved to: $check_path"
                inc_counter "broken_links"
                has_broken=true
            else
                echo "  ✅ OK: $url"
                inc_counter "ok_links"
            fi
        else
            # It's an HTTP link
            echo "  🌐 EXTERNAL: $url"
            inc_counter "external_links"
        fi
    done < <(grep -oE '\[.*\]\([^)]+\)' "$file")

    if [ "$has_broken" = true ]; then
        return 1
    fi
    return 0
}

# Find all markdown files, excluding common directories
echo "🔎 Scanning for markdown files..."
mapfile -t md_files < <(find . -type f -name "*.md" \
    ! -path "*/node_modules/*" \
    ! -path "*/vendor/*" \
    ! -path "*/.git/*" \
    ! -path "*/zig-cache/*" \
    ! -path "*/zig-out/*" \
    ! -path "*/build/*" \
    2>/dev/null | sort)

echo "Found ${#md_files[@]} markdown files"
echo ""

# Check each file
failed_files=()
for file in "${md_files[@]}"; do
    total_files=$((total_files + 1))
    if ! check_file "$file"; then
        failed_files+=("$file")
    fi
    echo ""
done

# Read final counters
total_files=${#md_files[@]}
total_links=$(cat "$tmpdir/total_links")
broken_links=$(cat "$tmpdir/broken_links")
ok_links=$(cat "$tmpdir/ok_links")
external_links=$(cat "$tmpdir/external_links")
anchor_links=$(cat "$tmpdir/anchor_links")

# Print summary
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "📊 SUMMARY"
echo "━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━"
echo "Files checked:     $total_files"
echo "Total links found: $total_links"
echo "  ✅ Valid local:  $ok_links"
echo "  ❌ Broken:       $broken_links"
echo "  🌐 External:     $external_links"
echo "  ⚓ Anchors:       $anchor_links (skipped)"
echo ""

if [ ${#failed_files[@]} -gt 0 ]; then
    echo "❌ Files with broken links:"
    for file in "${failed_files[@]}"; do
        echo "   - $file"
    done
    echo ""
    echo "❌ Link check FAILED!"
    exit 1
else
    echo "✅ All links are valid!"
    exit 0
fi
