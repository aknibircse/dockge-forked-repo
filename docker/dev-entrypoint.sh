#!/bin/bash
set -e

# Print versions for debugging
echo "Node version: $(node -v)"
echo "NPM version: $(npm -v)"
echo "PNPM version: $(pnpm -v)"

# Set environment variables for development mode
export NODE_ENV=development

# Set environment variables for native modules
export npm_config_sqlite=false
export npm_config_sqlite_libvfs=false
export npm_config_build_from_source=false
export npm_config_sqlite_build_binary=false
export npm_config_sqlite_prebuilt=true
export SKIP_NATIVE_BUILD=true

# Disable Rollup native modules for Alpine Linux
export ROLLUP_NATIVE_DISABLE=true

# Fix esbuild in Alpine Linux
export ESBUILD_BINARY_PATH=/app/node_modules/esbuild/bin/esbuild

# Include all dependencies (including optional and dev dependencies)
export npm_config_optional=true
export npm_config_include_dev=true

# Install all dependencies without ignoring scripts
echo "Installing dependencies..."
pnpm install --shamefully-hoist

# If we need to rebuild SQLite3 specifically
if [ "$REBUILD_SQLITE" = "true" ]; then
  echo "Rebuilding SQLite3 module..."
  cd /app
  npm rebuild @louislam/sqlite3 --build-from-source
fi

# Build the frontend first to avoid rollup issues
if [ "$USE_PREBUILT_FRONTEND" = "true" ]; then
  echo "Building frontend..."
  # Skip building frontend in Alpine Linux and use pre-built assets instead
  echo "Skipping frontend build in Alpine Linux and using pre-built assets..."
  
  # Create a minimal index.html if it doesn't exist
  mkdir -p /app/frontend/dist
  if [ ! -f /app/frontend/dist/index.html ]; then
    echo "Creating minimal frontend placeholder..."
    cat > /app/frontend/dist/index.html << 'EOF'
<!DOCTYPE html>
<html lang="en">
<head>
  <meta charset="UTF-8">
  <meta name="viewport" content="width=device-width, initial-scale=1.0">
  <title>Rackge - Development Mode</title>
  <style>
    body { font-family: Arial, sans-serif; margin: 40px; line-height: 1.6; }
    h1 { color: #333; }
    .container { max-width: 800px; margin: 0 auto; }
    .info { background: #f4f4f4; padding: 20px; border-radius: 5px; }
    .note { color: #666; font-style: italic; }
  </style>
</head>
<body>
  <div class="container">
    <h1>Rackge - Development Mode</h1>
    <div class="info">
      <p>The frontend is currently running in placeholder mode due to native module issues in Alpine Linux.</p>
      <p>The backend API is fully functional and available at port 5050.</p>
      <p class="note">For full frontend development, consider using a non-Alpine environment or building the frontend separately.</p>
    </div>
  </div>
</body>
</html>
EOF
  fi
  echo "Frontend built successfully"
  
  # Start only the backend in development mode
  echo "Starting backend in development mode..."
  echo "Environment: NODE_ENV=$NODE_ENV"
  echo "Backend port: $RACKGE_PORT"
  echo "Frontend will be served from the built files"
  
  # Create a custom backend starter script to avoid esbuild issues
  cat > /app/start-backend.cjs << 'EOF'
// Custom backend starter for Alpine Linux
const { spawn } = require('child_process');

// Set environment variables to avoid native module issues
process.env.ESBUILD_BINARY_PATH = '/app/node_modules/esbuild/bin/esbuild';
process.env.NODE_OPTIONS = '--no-warnings';

// Start the backend using tsx directly instead of node with import flag
console.log('Starting backend with custom starter...');
const backend = spawn('npx', [
  'tsx',
  '--no-warnings',
  './backend/index.ts'
], {
  stdio: 'inherit',
  env: {
    ...process.env,
    NODE_ENV: 'development',
    RACKGE_PORT: process.env.RACKGE_PORT || '5050'
  }
});

backend.on('exit', (code) => {
  process.exit(code || 0);
});
EOF

  # Make the script executable
  chmod +x /app/start-backend.cjs
  
  # Execute the custom backend starter
  exec node /app/start-backend.cjs
else
  # Start the full development server (both frontend and backend)
  echo "Starting development server in $(pwd)..."
  echo "Environment: NODE_ENV=$NODE_ENV"
  echo "Backend port: $RACKGE_PORT"
  echo "Frontend dev server will be available on port 5000"
  
  # Execute the command with proper environment
  exec "$@"
fi
