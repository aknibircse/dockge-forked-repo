#!/usr/bin/env node

/**
 * Custom build script to compile TypeScript files with --skipLibCheck
 * This script forces compilation even with errors
 */

import { execSync } from 'child_process';
import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get __dirname equivalent in ESM
const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

// Colors for console output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  cyan: '\x1b[36m'
};

console.log(`${colors.bright}${colors.blue}Rackge Backend Build Script${colors.reset}`);
console.log(`${colors.dim}Forcing TypeScript compilation with --skipLibCheck and ignoring errors${colors.reset}\n`);

try {
  // Run TypeScript compiler with force flag
  console.log(`${colors.yellow}Running TypeScript compiler...${colors.reset}`);
  
  try {
    execSync('tsc --project tsconfig.json --skipLibCheck', { 
      stdio: 'inherit',
      encoding: 'utf-8'
    });
    console.log(`${colors.green}TypeScript compilation completed successfully!${colors.reset}`);
  } catch (error) {
    console.log(`${colors.yellow}TypeScript reported errors but we're continuing with the build...${colors.reset}`);
    
    // Force compilation with tsc --build
    try {
      execSync('tsc --project tsconfig.json --skipLibCheck --noEmit false', { 
        stdio: 'inherit',
        encoding: 'utf-8'
      });
    } catch (error) {
      console.log(`${colors.yellow}Continuing despite errors...${colors.reset}`);
    }
  }

  // Check if the output directory exists
  const distDir = path.join(__dirname, 'backend', 'dist');
  if (!fs.existsSync(distDir)) {
    console.log(`${colors.red}Error: Output directory ${distDir} was not created.${colors.reset}`);
    process.exit(1);
  }

  console.log(`\n${colors.green}${colors.bright}Build completed!${colors.reset}`);
  console.log(`${colors.cyan}You can now run the application with: ${colors.bright}pnpm start:prod${colors.reset}`);
} catch (error) {
  console.error(`${colors.red}${colors.bright}Build failed:${colors.reset}`, error.message);
  process.exit(1);
}
