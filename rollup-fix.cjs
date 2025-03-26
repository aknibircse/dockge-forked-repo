#!/usr/bin/env node
// rollup-fix.cjs
// This script sets environment variables to prevent Rollup from trying to load native modules
// Specifically for Alpine Linux (musl) environments
const { spawn } = require('child_process');
const fs = require('fs');
const path = require('path');

// Disable Rollup's native module loading
process.env.ROLLUP_NATIVE_DISABLE = 'true';

// For other native modules
process.env.SKIP_NATIVE_BUILD = 'true';

// Fix esbuild in Alpine Linux
process.env.ESBUILD_BINARY_PATH = path.join(process.cwd(), 'node_modules/esbuild/bin/esbuild');
process.env.NODE_OPTIONS = '--no-warnings';

// Get command line arguments to pass to Vite
const args = process.argv.slice(2);
console.log('Running Vite with Rollup native modules disabled');
console.log('Args:', args);

// Check if we're running in Alpine Linux
const isAlpine = fs.existsSync('/etc/alpine-release');

if (isAlpine) {
  console.log('Alpine Linux detected - using custom Vite configuration');
  
  // Create a minimal vite.config.js if it doesn't exist
  const tempConfigPath = path.join(process.cwd(), 'vite.config.alpine.js');
  
  // Create a simplified Vite config for Alpine
  fs.writeFileSync(tempConfigPath, `
// Temporary Vite config for Alpine Linux
export default {
  server: {
    port: 5000,
    host: '0.0.0.0',
    strictPort: true,
    hmr: {
      port: 5000,
      host: '0.0.0.0',
      protocol: 'ws',
    },
  },
  build: {
    target: 'esnext',
    minify: false,
    sourcemap: true,
  },
  optimizeDeps: {
    esbuildOptions: {
      target: 'esnext',
    },
  },
};
  `);
  
  // Spawn Vite with the Alpine-specific config
  const viteBin = './node_modules/.bin/vite';
  const viteProcess = spawn(viteBin, [
    '--config', tempConfigPath,
    ...args
  ], {
    stdio: 'inherit',
    env: {
      ...process.env,
      ROLLUP_NATIVE_DISABLE: 'true',
      ESBUILD_BINARY_PATH: process.env.ESBUILD_BINARY_PATH,
      NODE_OPTIONS: '--no-warnings'
    }
  });
  
  // Forward exit code
  viteProcess.on('exit', (code) => {
    // Clean up temporary file
    try {
      fs.unlinkSync(tempConfigPath);
    } catch (err) {
      console.error('Failed to clean up temporary Vite config:', err);
    }
    process.exit(code || 0);
  });
} else {
  // Regular environment - just spawn Vite with disabled Rollup native modules
  const viteBin = './node_modules/.bin/vite';
  const viteProcess = spawn(viteBin, args, {
    stdio: 'inherit',
    env: process.env
  });

  // Forward exit code
  viteProcess.on('exit', (code) => {
    process.exit(code || 0);
  });
}
