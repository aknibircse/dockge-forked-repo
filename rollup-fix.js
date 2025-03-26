#!/usr/bin/env node
// rollup-fix.js
// This script sets environment variables to prevent Rollup from trying to load native modules
// Specifically for Alpine Linux (musl) environments

// Disable Rollup's native module loading
process.env.ROLLUP_NATIVE_DISABLE = 'true';

// For other native modules
process.env.SKIP_NATIVE_BUILD = 'true';

// Get command line arguments to pass to Vite
const args = process.argv.slice(2);
console.log('Running Vite with Rollup native modules disabled');
console.log('Args:', args);

// Execute Vite with the arguments (using ES modules syntax)
import { spawn } from 'child_process';

const viteBin = './node_modules/.bin/vite';
const viteProcess = spawn(viteBin, args, {
  stdio: 'inherit',
  env: process.env
});

viteProcess.on('exit', (code) => {
  process.exit(code || 0);
});
