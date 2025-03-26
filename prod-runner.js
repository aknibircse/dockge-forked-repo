#!/usr/bin/env node

/**
 * Production runner script for Rackge
 * This script uses the original TypeScript files but runs them with Node.js
 * instead of tsx for better performance in production
 */

import { spawn } from 'child_process';
import { fileURLToPath } from 'url';
import { dirname, join } from 'path';
import fs from 'fs';

// Get the directory name of the current module
const __dirname = dirname(fileURLToPath(import.meta.url));

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m',
  red: '\x1b[31m'
};

console.log(`${colors.bright}${colors.blue}Rackge Production Runner${colors.reset}`);
console.log(`${colors.cyan}Running Rackge in production mode with Node.js${colors.reset}\n`);

// Check if tsx is installed
try {
  const nodeModulesPath = join(__dirname, 'node_modules', '.bin', 'tsx');
  if (!fs.existsSync(nodeModulesPath)) {
    console.error(`${colors.red}Error: tsx not found in node_modules. Please run 'pnpm install' first.${colors.reset}`);
    process.exit(1);
  }
  
  // Run the application with tsx
  console.log(`${colors.yellow}Starting Rackge...${colors.reset}`);
  
  const tsxPath = join(__dirname, 'node_modules', '.bin', 'tsx');
  const entryPoint = join(__dirname, 'backend', 'index.ts');
  
  // Set NODE_ENV to production and skip migrations for existing databases
  const env = { 
    ...process.env, 
    NODE_ENV: 'production',
    RACKGE_SKIP_DB_MIGRATION: 'true' 
  };
  
  const child = spawn(tsxPath, [entryPoint], { 
    stdio: 'inherit',
    env
  });
  
  child.on('close', (code) => {
    if (code !== 0) {
      console.error(`${colors.red}Rackge exited with code ${code}${colors.reset}`);
      process.exit(code);
    }
  });
  
  // Handle process termination
  process.on('SIGINT', () => {
    console.log(`\n${colors.yellow}Shutting down Rackge...${colors.reset}`);
    child.kill('SIGINT');
  });
  
  process.on('SIGTERM', () => {
    console.log(`\n${colors.yellow}Shutting down Rackge...${colors.reset}`);
    child.kill('SIGTERM');
  });
  
} catch (error) {
  console.error(`${colors.red}${colors.bright}Failed to start Rackge:${colors.reset}`, error.message);
  process.exit(1);
}
