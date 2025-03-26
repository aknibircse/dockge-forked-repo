#!/usr/bin/env node

/**
 * Simple script to extract and print the version from package.json
 * Used by the build:frontend:version script
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

// Get the directory name of the current module
const __dirname = path.dirname(fileURLToPath(import.meta.url));
const packageJsonPath = path.join(__dirname, '..', 'package.json');

try {
  const packageJson = JSON.parse(fs.readFileSync(packageJsonPath, 'utf8'));
  console.log(packageJson.version);
} catch (error) {
  console.error('Error reading package.json:', error.message);
  process.exit(1);
}
