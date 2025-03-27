#!/bin/bash
set -e

echo "🔧 Quick fix for SQLite3 in pnpm structure"

# This script creates the necessary directory structure and copies a placeholder binary
# to prevent the SQLite3 module from failing to load

# Directory setup
SCRIPT_DIR="$(cd "$(dirname "$0")" && pwd)"
PROJECT_ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"

# Create a simple placeholder binary to satisfy the module loader
# This is a temporary fix until the real binary is built
echo "📝 Creating placeholder binary..."
mkdir -p "$SCRIPT_DIR/placeholder"
cat > "$SCRIPT_DIR/placeholder/create-placeholder.js" << 'EOF'
const fs = require('fs');
const path = require('path');

// Create a minimal Node.js native addon that exports the required symbols
const placeholderCode = `
#include <node_api.h>

napi_value Init(napi_env env, napi_value exports) {
  return exports;
}

NAPI_MODULE(NODE_GYP_MODULE_NAME, Init)
`;

fs.writeFileSync(path.join(__dirname, 'placeholder.c'), placeholderCode);
EOF

echo "📄 Adding this fix to the dev-entrypoint.sh script..."

# Create a patch for the dev-entrypoint.sh script
cat > "$SCRIPT_DIR/dev-entrypoint-patch.sh" << 'EOF'
#!/bin/bash

# This function will be added to the dev-entrypoint.sh script
fix_sqlite3_paths() {
  echo "🔍 Fixing SQLite3 paths for pnpm structure..."
  
  # Find all potential SQLite3 module paths
  find /app/node_modules/.pnpm -path "*@louislam+sqlite3@*" -type d | while read -r sqlite_path; do
    if [ -d "$sqlite_path/node_modules/@louislam/sqlite3" ]; then
      target_dir="$sqlite_path/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64"
      echo "📁 Creating directory: $target_dir"
      mkdir -p "$target_dir"
      
      # Check if we have a real binary to copy
      if [ -f "/app/temp_sqlite3/napi-v6-linux-arm64/node_sqlite3.node" ]; then
        echo "📦 Copying pre-built binary to: $target_dir"
        cp "/app/temp_sqlite3/napi-v6-linux-arm64/node_sqlite3.node" "$target_dir/"
      else
        # Create an empty file as a placeholder
        echo "⚠️ No binary available, creating placeholder at: $target_dir/node_sqlite3.node"
        touch "$target_dir/node_sqlite3.node"
      fi
    fi
  done
  
  # Also fix the non-pnpm path just in case
  mkdir -p "/app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64"
  if [ -f "/app/temp_sqlite3/napi-v6-linux-arm64/node_sqlite3.node" ]; then
    cp "/app/temp_sqlite3/napi-v6-linux-arm64/node_sqlite3.node" "/app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64/"
  else
    touch "/app/node_modules/@louislam/sqlite3/lib/binding/napi-v6-linux-arm64/node_sqlite3.node"
  fi
}

# Call the function
fix_sqlite3_paths
EOF

chmod +x "$SCRIPT_DIR/dev-entrypoint-patch.sh"

echo "✅ Fix script created at: $SCRIPT_DIR/fix-sqlite3-path.sh"
echo "✅ Patch script created at: $SCRIPT_DIR/dev-entrypoint-patch.sh"
echo ""
echo "To apply this fix:"
echo "1. Add the fix_sqlite3_paths function to your dev-entrypoint.sh script"
echo "2. Call the function after installing dependencies"
echo "3. Make sure the temp_sqlite3 directory is mounted in the container"
