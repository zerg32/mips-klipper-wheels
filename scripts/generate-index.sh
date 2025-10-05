#!/bin/bash
# generate-index.sh
# Generates an HTML index for Python wheels

OUTPUT_DIR="$1"
INDEX_FILE="$OUTPUT_DIR/index.html"

cat > "$INDEX_FILE" << EOF
<!DOCTYPE html>
<html>
<head>
    <title>MIPS Python Wheels Index</title>
    <style>
        body { font-family: Arial, sans-serif; margin: 40px; }
        .wheel-list { list-style: none; padding: 0; }
        .wheel-list li { margin: 10px 0; }
        .wheel-list a { text-decoration: none; color: #0366d6; }
        .wheel-list a:hover { text-decoration: underline; }
    </style>
</head>
<body>
    <h1>MIPS Python Wheels</h1>
    <ul class="wheel-list">
EOF

# Add each wheel file to the index
find "$OUTPUT_DIR" -name "*.whl" | sort | while read wheel; do
    filename=$(basename "$wheel")
    echo "<li><a href=\"./$filename\">$filename</a></li>" >> "$INDEX_FILE"
done

# Close the HTML
cat >> "$INDEX_FILE" << EOF
    </ul>
    <p>Last updated: $(date)</p>
</body>
</html>
EOF