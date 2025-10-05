#!/bin/bash
# generate-index.sh
# Generates a PEP 503 compliant Python package index

OUTPUT_DIR="$1"
INDEX_FILE="$OUTPUT_DIR/index.html"
SIMPLE_DIR="$OUTPUT_DIR/simple"

# Create simple directory
mkdir -p "$SIMPLE_DIR"

# Create main index
cat > "$INDEX_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>MIPS Python Package Index</title>
    <meta name="api-version" value="2" />
</head>
<body>
    <h1>MIPS Python Package Index</h1>
    <p>This is a PEP 503 compliant Python package index for MIPS architecture.</p>
EOF

# Create simple index
cat > "$SIMPLE_DIR/index.html" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>Simple Index</title>
    <meta name="api-version" value="2" />
</head>
<body>
EOF

# Process wheels and create package directories
find "$OUTPUT_DIR" -name "*.whl" | sort | while read wheel; do
    filename=$(basename "$wheel")
    # Extract package name from wheel filename (package_name-version-etc.whl)
    package_name=$(echo "$filename" | cut -d'-' -f1 | tr '_' '-' | tr '[:upper:]' '[:lower:]')
    package_dir="$SIMPLE_DIR/$package_name"
    
    # Create package directory if it doesn't exist
    mkdir -p "$package_dir"
    
    # Create or update package index
    if [ ! -f "$package_dir/index.html" ]; then
        cat > "$package_dir/index.html" << EOF2
<!DOCTYPE html>
<html>
<head>
    <title>Links for $package_name</title>
    <meta name="api-version" value="2" />
</head>
<body>
    <h1>Links for $package_name</h1>
EOF2
    fi
    
    # Add wheel link to package index
    echo "    <a href=\"../../$filename#sha256=$(sha256sum "$wheel" | cut -d' ' -f1)\" data-requires-python=\"&gt;=3.7\">$filename</a><br/>" >> "$package_dir/index.html"
    
    # Add package to main simple index if not already there
    if ! grep -q "\"$package_name\"" "$SIMPLE_DIR/index.html"; then
        echo "    <a href=\"$package_name/\">$package_name</a><br/>" >> "$SIMPLE_DIR/index.html"
    fi
done

# Close all HTML files
echo "</body></html>" >> "$INDEX_FILE"
echo "</body></html>" >> "$SIMPLE_DIR/index.html"

# Close package-specific index files
find "$SIMPLE_DIR" -name "index.html" -mindepth 2 | while read idx; do
    echo "</body></html>" >> "$idx"
done

echo "Generated PEP 503 compliant package index in $OUTPUT_DIR"