#!/bin/sh
set -e

echo "🔧 Building SQLite3 native module for Alpine Linux on ARM64"

# Set environment variables to help with the build process
export SKIP_NATIVE_BUILD=false
export npm_config_ignore_scripts=false
export npm_config_optional=true
export ROLLUP_NATIVE_DISABLE=false

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
NODE_SQLITE3_DIR="$SCRIPT_DIR/node-sqlite3"
OUTPUT_DIR="$SCRIPT_DIR/napi-v6-linux-arm64"

# Make sure output directory exists
mkdir -p "$OUTPUT_DIR"

echo "📂 Working in: $NODE_SQLITE3_DIR"

# Navigate to the node-sqlite3 directory
cd "$NODE_SQLITE3_DIR"

# Install dependencies
echo "📦 Installing dependencies..."
npm install --no-package-lock

# Build the native module
echo "🔨 Building native module..."
npm run rebuild

# Copy the built binary to the output directory
echo "📋 Copying built binary to output directory..."
find ./build -name "node_sqlite3.node" -type f -exec cp {} "$OUTPUT_DIR/" \;

# Create a tarball of the binary
echo "📦 Creating tarball of the binary..."
cd "$SCRIPT_DIR"
tar -czvf sqlite3-linux-arm64-alpine.tar.gz -C "$OUTPUT_DIR" .

echo "✅ SQLite3 native module built successfully!"
echo "📦 Binary tarball: $SCRIPT_DIR/sqlite3-linux-arm64-alpine.tar.gz"
