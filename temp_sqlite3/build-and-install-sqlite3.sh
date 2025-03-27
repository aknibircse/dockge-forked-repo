#!/bin/bash
set -e

echo "🚀 Starting SQLite3 build process for Alpine Linux ARM64"

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
SQLITE_MODULE_DIR="$PROJECT_ROOT/node_modules/@louislam/sqlite3"
TARGET_DIR="$SQLITE_MODULE_DIR/lib/binding/napi-v6-linux-arm64"

# Build the Docker image for SQLite3 compilation
echo "🐳 Building Docker image for SQLite3 compilation..."
docker build -t sqlite3-alpine-builder -f "$SCRIPT_DIR/Dockerfile.alpine-sqlite3" "$SCRIPT_DIR"

# Run the container to build SQLite3
echo "🔨 Running container to build SQLite3..."
docker run --rm -v "$SCRIPT_DIR:/output" sqlite3-alpine-builder

# Check if the build was successful
if [ ! -f "$SCRIPT_DIR/sqlite3-linux-arm64-alpine.tar.gz" ]; then
    echo "❌ Build failed: SQLite3 binary not found!"
    exit 1
fi

# Create the target directory if it doesn't exist
mkdir -p "$TARGET_DIR"

# Extract the binary to the target directory
echo "📦 Installing SQLite3 binary to node_modules..."
tar -xzf "$SCRIPT_DIR/sqlite3-linux-arm64-alpine.tar.gz" -C "$TARGET_DIR"

# Verify the installation
if [ -f "$TARGET_DIR/node_sqlite3.node" ]; then
    echo "✅ SQLite3 binary successfully installed!"
    echo "📍 Location: $TARGET_DIR/node_sqlite3.node"
else
    echo "❌ Installation failed: SQLite3 binary not found in target directory!"
    exit 1
fi

echo "🎉 SQLite3 build and installation complete!"
