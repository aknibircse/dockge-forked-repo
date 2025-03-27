#!/bin/bash
set -e

echo "🔍 Downloading pre-built SQLite3 binary for Alpine Linux on ARM64"

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
OUTPUT_DIR="$SCRIPT_DIR/napi-v6-linux-arm64"

# Make sure output directory exists
mkdir -p "$OUTPUT_DIR"

# Create a simple Dockerfile to extract the binary
cat > "$SCRIPT_DIR/Dockerfile.extract" << 'EOF'
FROM node:18.12.0-alpine

# Install dependencies
RUN apk add --no-cache curl npm python3 make g++

# Create working directory
WORKDIR /build

# Install sqlite3 module
RUN npm init -y && \
    npm install @louislam/sqlite3@15.1.6 --build-from-source

# Find and extract the binary
RUN find /build/node_modules -name "node_sqlite3.node" -type f -exec cp {} /build/ \;

# Create a simple script to verify the binary
RUN echo "console.log('Testing SQLite3 binary...');" > test.js && \
    echo "const sqlite3 = require('@louislam/sqlite3');" >> test.js && \
    echo "console.log('SQLite3 version:', sqlite3.VERSION);" >> test.js && \
    node test.js

CMD ["sh", "-c", "cat /build/node_sqlite3.node"]
EOF

echo "🐳 Building Docker image to extract SQLite3 binary..."
docker build -t sqlite3-extract -f "$SCRIPT_DIR/Dockerfile.extract" "$SCRIPT_DIR"

echo "📥 Extracting SQLite3 binary from container..."
docker run --rm sqlite3-extract > "$OUTPUT_DIR/node_sqlite3.node"

# Verify the binary was extracted
if [ -f "$OUTPUT_DIR/node_sqlite3.node" ]; then
    echo "✅ SQLite3 binary extracted successfully!"
    echo "📍 Location: $OUTPUT_DIR/node_sqlite3.node"
    echo "📦 Size: $(ls -lh "$OUTPUT_DIR/node_sqlite3.node" | awk '{print $5}')"
else
    echo "❌ Failed to extract SQLite3 binary!"
    exit 1
fi

echo "🎉 SQLite3 binary download complete!"
