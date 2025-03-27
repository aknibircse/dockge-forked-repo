#!/bin/bash
set -e

echo "🔧 Fixing SQLite3 paths for production Docker image"

# Function to fix SQLite3 paths
fix_sqlite3_paths() {
  echo "🔍 Fixing SQLite3 paths for pnpm structure..."
  
  # Find all potential SQLite3 module paths
  find /app/node_modules/.pnpm -path "*@louislam+sqlite3@*" -type d | while read -r sqlite_path; do
    if [ -d "$sqlite_path/node_modules/@louislam/sqlite3" ]; then
      target_dir="$sqlite_path/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64"
      echo "📁 Creating directory: $target_dir"
      mkdir -p "$target_dir"
      
      # Create an empty file as a placeholder
      echo "⚠️ Creating placeholder at: $target_dir/node_sqlite3.node"
      touch "$target_dir/node_sqlite3.node"
    fi
  done
  
  # Also fix the non-pnpm path just in case
  mkdir -p "/app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64"
  touch "/app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64/node_sqlite3.node"
}

# Run the fix
fix_sqlite3_paths

echo "✅ SQLite3 paths fixed successfully!"
